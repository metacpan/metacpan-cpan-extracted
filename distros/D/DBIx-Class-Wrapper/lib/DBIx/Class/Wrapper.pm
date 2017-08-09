package DBIx::Class::Wrapper;
$DBIx::Class::Wrapper::VERSION = '0.009';
use Moose::Role;
use Moose::Meta::Class;
use Module::Pluggable::Object;
use Class::Load;

=head1 NAME

DBIx::Class::Wrapper - A Moose role to allow your business model to wrap business code around a dbic model.

=head1 BUILD STATUS

=begin html

<a href="https://travis-ci.org/jeteve/DBIx-Class-Wrapper"><img src="https://travis-ci.org/jeteve/DBIx-Class-Wrapper.svg?branch=master"></a>

=end html

=head1 SYNOPSIS

This package allows you to easily extend your DBIC Schema by Optionally wrapping its resultsets and result objects
in your own business classes.

=head2 Basic usage with no specific wrapping at all

 package My::Model;
 use Moose;
 with qw/DBIx::Class::Wrapper/;
 1

Later

 my $schema = instance of DBIx schema
 my $app = My::Model->new( { dbic_schema => $schema } );
 ## And use the dbic resultsets-ish methods.
 my $products = $app->dbic_factory('Product'); ## Get a new instance of the Product resultset.

 ## Use classic DBIC methods as usual.
 my $p = $products->find(2);
 my $blue_ps = $products->search({ colour => blue });


=head2 Implement your own product class with business methods.

First you need a DBIC factory that will wrap the raw dbic object into your own class of product

 package My::Model::Wrapper::Factory::Product;
 use Moose; extends  qw/DBIx::Class::Wrapper::Factory/ ;
 sub wrap{
   my ($self , $o) = @_;
   return My::Model::O::Product->new({o => $o , factory => $self });
 }
 1;

Then your Product business object class

 package My::Model::O::Product;
 use Moose;
 has 'o' => ( isa => 'My::Schema::Product', ## The raw DBIC object class.
              is => 'ro' , required => 1,
              handles => [ 'id' , 'name', 'active' ] ## handles standard properties
            );
 ## A business method
 sub activate{
    my ($self) = @_;
    $self->o->update({ active => 1 });
 }

Then from your main code, continue using the Product resultset as normal.

 my $product = $app->dbic_factory('Product')->find(1);
 ## But you can do
 $product->activate();
 ## so now
 $product->active() == 1;


=head2 Your own specialised resultset

Let's say you decide that from now, the bulk of your application should access only active products,
leaving unlimited access to all product to a limited set of places.

 package My::Model::Wrapper::Factory::Product;
 use Moose;
 extends qw/DBIx::Class::Wrapper::Factory/;
 sub build_dbic_rs{
     my ($self) = @_;
     ## Note that you can always access your original business model
     ## from a factory (method bm).
     return $self->bm->dbic_schema->resultset('Product')->search_rs({ active => 1});
     ## This is a simple example. You can restrict your products set
     ## according to any current property of your business model for instance.
 }
 sub wrap{ .. same .. }
 1;

Everywhere your application uses $app->dbic_factory('Product') is now
restricted to active products only.

Surely you want admin parts of your application to access all products.
So here's a very basic AllProducts:

 package My::Model::Wrapper::Factory::AllProduct;
 use Moose; extends qw/My::Model::Wrapper::Factory::Product/;
 sub build_dbic_rs{
   my ($self) = @_;
   ## Some extra security.
   unless( $self->bm->current_user()->is_admin() ){ confess "Sorry you cant access that"; }

   return $self->bm()->dbic_schema->resultset('Product')->search_rs();
 }


=head2 Changing the factory base class.

Until now, all your custom factories were named My::Model::Wrapper::Factory::<something>.

If you want to customise the base class of those custom factories, you can do so by overriding
the method _build_dbic_factory_baseclass in your model:

 package My::Model;

 use Moose;
 with qw/DBIx::Class::Wrapper/;

 sub _build_dbic_factory_baseclass{
    return 'My::Model::DBICFactory'; # for instance.
 }

Then implement your factories as subpackages of My::Model::DBICFactory

=cut

has 'dbic_schema' => ( is => 'rw' , isa => 'DBIx::Class::Schema' , required => 1 );
has 'dbic_factory_baseclass' => ( is => 'ro' , isa => 'Str' , lazy_build => 1);

has '_dbic_dbic_fact_classes' => ( is => 'ro' , isa => 'HashRef[Bool]' , lazy_build => 1); 

sub _build_dbic_factory_baseclass{
    my ($self) = @_;
    return ref ($self).'::Wrapper::Factory';
}

sub _build__dbic_dbic_fact_classes{
    my ($self) = @_;
    my $baseclass = $self->dbic_factory_baseclass();
    my $res = {};
    my $mp = Module::Pluggable::Object->new( search_path => [ $baseclass ]);
    foreach my $candidate_class ( $mp->plugins() ){
	Class::Load::load_class( $candidate_class );
	# Code is loaded
	unless( $candidate_class->isa('DBIx::Class::Wrapper::Factory') ){
	    warn "Class $candidate_class does not extend DBIx::Class::Wrapper::Factory.";
	    next;
	}
	# And inherit from the right class.
	$res->{$candidate_class} = 1;
    }
    return $res;
}

=head1 METHODS

=head2 dbic_factory

Returns a new instance of L<DBIx::Class::Wrapper::Factory> that wraps around the given DBIC ResultSet name
if such a resultset exists. Dies otherwise.

Additionaly, you can set a ad-hoc resulset if you want to locally restrict your original resultset.

usage:

    my $f = $this->dbic_factory('Article');

    my $f = $this->dbic_factory('Article' , { dbic_rs => $schema->resultset('Article')->search_rs({ is_active => 1 }) });

=cut

sub dbic_factory{
  my ($self , $name , $init_args ) = @_;
  unless( defined $init_args ){
      $init_args = {};
  }
  unless( $name ){
    confess("Missing name in call to dbic_factory");
  }
  my $class_name = $self->dbic_factory_baseclass().'::'.$name;

  ## Build a class dynamically if necessary
  unless( $self->_dbic_dbic_fact_classes->{$class_name} ){
    ## We need to build such a class.
    Moose::Meta::Class->create($class_name => ( superclasses => [ 'DBIx::Class::Wrapper::Factory' ] ));
    $self->_dbic_dbic_fact_classes->{$class_name} = 1;
  }
  ## Ok, $class_name is now there

  ## Note that the factory will built its own resultset from this model and the name
  my $instance = $class_name->new({  bm => $self , name => $name , %$init_args });
  ## This will die instantly if cannot find a dbic_rs
  my $dbic_rs = $instance->dbic_rs();
  return $instance;
}

1;
