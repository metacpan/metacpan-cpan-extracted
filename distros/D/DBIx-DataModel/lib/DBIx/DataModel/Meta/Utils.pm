package DBIx::DataModel::Meta::Utils;
use strict;
use warnings;

use strict;
use warnings;

use Carp;
use Module::Load         qw/load/;
use Params::Validate     qw/validate SCALAR ARRAYREF CODEREF UNDEF BOOLEAN
                                     OBJECT HASHREF/;
use List::MoreUtils      qw/any/;
use mro 'c3';

use namespace::clean;

use DBIx::DataModel;
{no strict 'refs'; *CARP_NOT = \@DBIx::DataModel::CARP_NOT;}

sub define_class {
  my $self = shift;

  # check parameters
  my %params = validate(@_, {
      name    => {type => SCALAR  },
      isa     => {type => ARRAYREF},
      metadm  => {isa  => 'DBIx::DataModel::Meta'},
    }
  );

  # deactivate strict refs because we'll be playing with symbol tables
  no strict 'refs';

  # make sure that all parents are defined
  foreach my $parent (@{$params{isa}}) {

    # heuristics to decide if a class is loaded (can't rely on %INC)
    my $is_class_defined = any {! /::$/} keys %{$parent.'::'};
      # NOTE : we need to exclude symbols ending with '::' because
      # "require Foo::Bar::Buz" will define ${Foo::Bar::}{'Buz::'} at
      # compilation time, even if this statement is never executed.

    # try to load parent if needed
    load $parent unless $is_class_defined;
  };

  # inject parents into @ISA
  my $class_isa = $params{name}."::ISA";
  not @{$class_isa} or croak "won't overwrite \@$class_isa";
  @{$class_isa} = @{$params{isa}};

  # use mro 'c3' in that package
  mro::set_mro($params{name}, 'c3');

  # install an accessor to the metaclass object within the package
  $self->define_method(class          => $params{name},
                       name           => 'metadm', 
                       body           => sub {return $params{metadm}},
                       check_override => 0,                          );
}


sub define_method {
  my $self = shift;

  # check parameters
  my %params = validate(@_, {
      class          => {type => SCALAR               },
      name           => {type => SCALAR               },
      body           => {type => CODEREF              },
      check_override => {type => BOOLEAN, default => 1},
    }
  );

  # fully qualified name
  my $full_method_name = $params{class}.'::'.$params{name};

  # deactiveate strict refs because we'll be playing with symbol tables
  no strict 'refs';

  # check if method is already there
  not defined(&{$full_method_name})
    or croak "method $full_method_name is already defined";

  # check if there is a conflict with an inherited method
  !$params{check_override} or not $params{class}->can($params{name})
    or carp "method $params{name} in $params{class} will be overridden";

  # install the method
  *{$full_method_name} = $params{body};
}


sub define_readonly_accessors {
  my ($self, $target_class, @accessors) = @_;

  foreach my $accessor (@accessors) {
    $self->define_method(
      class => $target_class,
      name  => $accessor, 
      body  => sub { my $self = shift;
                     my $val  = $self->{$accessor}; 
                     for (ref $val) {
                       /^ARRAY$/ and return @$val;
                       /^HASH$/  and return %$val;
                       return $val; # otherwise
                     }
                    },
     );
  }
}


1;

__END__

=head1 NAME

DBIx::DataModel::Meta::Utils - Utility methods for DBIx::DataModel metaclasses

=head1 SYNOPSIS

  DBIx::DataModel::Meta::Utils->define_class(
    name    => $class_name,
    isa     => \@parents,
    metadm  => $meta_instance,
  );

  DBIx::DataModel::Meta::Utils->define_method(
    class          => $class_name,
    name           => $method_name,
    body           => $method_body,
    check_override => $toggle,
  );

  DBIx::DataModel::Meta::Utils->define_readonly_accessors(
    $class_name => @accessor_names
  );


=head1 DESCRIPTION

A few utility methods for convenience of other 
C<DBIx::DataModel::Meta::*> subclasses.

=head1 METHODS

=head2 define_class

  DBIx::DataModel::Meta::Utils->define_class(
    name    => $class_name,
    isa     => \@parents,
    metadm  => $meta_instance,
  );

Creates a Perl class of the given name, that inherits from classes
specified in C<@parents>, and injects into that class a C<metadm> 
accessor method that will return the given C<$meta_instance>.

=head2 define_method

  DBIx::DataModel::Meta::Utils->define_method(
    class          => $class_name,
    name           => $method_name,
    body           => $method_body,
    check_override => $toggle,
  );

Creates a method C<$method_name> within class C<$class_name>, with
C<$method_body> as implementation. If C<$check_override> is true, 
a warning is issued if the method name conflicts with an inherited
method in that class.


=head2 define_readonly_accessors


  DBIx::DataModel::Meta::Utils->define_readonly_accessors(
    $class_name => @accessor_names
  );

Creates a collection of accessor methods within C<$class_name>.  Each
accessor method returns the value stored in C<%$self> under the same
name, i.e. accessor C<foo> returns C<< $self->{foo} >>.  However, if
that value is a hashref or arrayref, a shallow copy is returned : for
example if C<< $self->{foo} >> is an arrayref, then the accessor
method returns C<< @{$self->{foo}} >>.
