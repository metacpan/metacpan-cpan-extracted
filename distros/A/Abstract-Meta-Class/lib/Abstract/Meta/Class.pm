package Abstract::Meta::Class;

use strict;
use warnings;

use base 'Exporter';
use vars qw(@EXPORT_OK %EXPORT_TAGS);
use Carp 'confess';
use vars qw($VERSION);

$VERSION = 0.11;

@EXPORT_OK = qw(has new apply_contructor_parameter install_meta_class abstract abstract_class storage_type);
%EXPORT_TAGS = (all => \@EXPORT_OK, has => ['has', 'install_meta_class', 'abstract', 'abstract_class', 'storage_type']);

use Abstract::Meta::Attribute;
use Abstract::Meta::Attribute::Method;

=head1 NAME

Abstract::Meta::Class - Simple meta object protocol implementation.

=head1 SYNOPSIS

    package Dummy;

    use Abstract::Meta::Class ':all';
    
    
    has '$.attr1' => (default => 0);
    has '%.attrs2' => (default => {a => 1, b => 3}, item_accessor => 'attr2');
    has '@.atts3' => (default => [1, 2, 3], required => 1, item_accessor => 'attr3');
    has '&.att3' => (required => 1);
    has '$.att4' => (default => sub { 'stuff' } , required => 1);


    my $dummt = Dummy->new(
        att3 => 3,
    );

    use Dummy;

    my $obj = Dummy->new(attr3 => sub {});
    my $attr1 = $obj->attr1; #0
    $obj->set_attr1(1);
    $obj->attr2('c', 4);
    $obj->attrs2 #{a => 1, b => 3. c => 4};
    my $val_a = $obj->attr2('a');
    my $item_1 = $obj->attr3(1);
    $obj->count_attrs3();
    $obj->push_attrs3(4);



=head1 DESCRIPTION

Meta object protocol implementation,

=head2 hash/array storage type

To speed up bless time as well optimise memory usage you can use Array storage type.
(Hash is the default storage type)

    package Dummy;

    use Abstract::Meta::Class ':all';
    storage_type 'Array';
    
    has '$.attr1' => (default => 0);
    has '%.attrs2' => (default => {a => 1, b => 3}, item_accessor => 'attr2');
    has '@.attrs3' => (default => [1, 2, 3], required => 1, item_accessor => 'attr3');
    has '&.attr4' => (required => 1);
    has '$.attr5';
    has '$.attr6' => (default => sub { 'stuff' } , required => 1);


    my $dummy = Dummy->new(
        attr4 => sub {},
    );
    
    use Data::Dumper;
    warn Dumper $dummy;
    # bless [0, {a =>1,b => 3}, [1,2,3],sub{},undef,sub {}], 'Dummy'

=head2 simple validation and default values

    package Dummy;

    use Abstract::Meta::Class ':all';

    has '$.attr1' => (default => 0);
    has '&.att3' => (required => 1);

    use Dummy;

    my $obj = Dummy->new; #dies - att3 required


=head2 utility methods for an array type

    While specyfing array type of attribute
    the following methods are added (count || push || pop || shift || unshift)_accessor.

    package Dummy;

    use Abstract::Meta::Class ':all';

    has '@.array' => (item_accessor => 'array_item');


    use Dummy;

    my $obj = Dummy->new;

    $obj->count_array();
    $obj->push_array(1);
    my $x = $obj->array_item(0);
    my $y = $obj->pop_array;

    #NOTE scalar, array context sensitive
    my $array_ref = $obj->array;
    my @array = $obj->array;


=head2 item accessor method for complex types

    While specyfing an array or a hash type of attribute then
    you may specify item_accessor for get/set value by hash key or array index.


    package Dummy;

    use Abstract::Meta::Class ':all';

    has '%.hash' => (item_accessor => 'hash_item');

    use Dummy;

    my $obj = Dummy->new;
    $obj->hash_item('key1', 'val1');
    $obj->hash_item('key2', 'val2');
    my $val = $obj->hash_item('key1');

    #NOTE scalar, array context sensitive
    my $hash_ref = $obj->hash;
    my %hash = $obj->hash;


=head2 perl types validation

    Dy default all complex types are validated against its definition.

    package Dummy;
    use Abstract::Meta::Class ':all';

    has '%.hash' => (item_accessor => 'hash_item');
    has '@.array' => (item_accessor => 'array_item');


    use Dummy;

    my $obj = Dummy->new(array => {}, hash => []) #dies incompatible types.


=head2 associations

    This module handles different types of associations(to one, to many, to many ordered).
    You may also use bidirectional association by using the_other_end option,

    NOTE: When using the_other_end automatic association/deassociation happens,
    celanup method is installed.

    package Class;

    use Abstract::Meta::Class ':all';

    has '$.to_one'  => (associated_class => 'AssociatedClass');
    has '@.ordered' => (associated_class => 'AssociatedClass');
    has '%.to_many' => (associated_class => 'AssociatedClass', item_accessor => 'many', index_by => 'id');


    use Class;
    use AssociatedClass;

    my $obj1 = Class->new(to_one => AssociatedClass->new);

    my $obj2 = Class->new(ordered => [AssociatedClass->new]);

    # NOTE: context sensitive (scalar, array)
    my @association_objs = $obj2->ordered;
    my @array_ref = $obj2->ordered;

    my $obj3 = Class->new(to_many => [AssociatedClass->new(id =>'001'), AssociatedClass->new(id =>'002')]);
    my $association_obj = $obj3->many('002);

    # NOTE: context sensitive (scalar, array)
    my @association_objs = values %{$obj3->to_many};
    my $hash_ref = $obj3->to_many;


    - bidirectional associations (the_other_end attribute)

    package Master;

    use Abstract::Meta::Class ':all';

    has '$.name';
    has '%.details' => (associated_class => 'Detail', the_other_end => 'master', item_accessor => 'detail', index_by => 'id');


    package Detail;

    use Abstract::Meta::Class ':all';

    has '$.id'     => (required => 1);
    has '$.master' => (
        associated_class => 'Master',
        the_other_end    => 'details'
    );


    use Master;
    use Detail;

    my @details  = (
        Detail->new(id => 1),
        Detail->new(id => 2),
        Detail->new(id => 3),
    );

    my $master = Master->new(name => 'foo', details => [@details]);
    print $details[0]->master->name;

    - while using an array/hash association storage remove_<attribute_name> | add_<attribute_name> are added.
    $master->add_details(Detail->new(id => 4),);
    $master->remove_details($details[0]);
    #cleanup method is added to class, that deassociates all bidirectional associations


=head2 decorators

....- on_validate

    - on_change

    - on_read

    - initialise_method

    package Triggers;

    use Abstract::Meta::Class ':all';

    has '@.y' => (
        on_change => sub {
            my ($self, $attribute_name, $scope, $value_ref, $index) = @_;
            # scope -> mutator, item_accessor
            ... do some stuff

            # process further in standard way by returning true
            $self;
        },
        # replaces standard read
        on_read => sub {
            my ($self, $attr_name, $scope, $index)
            #scope can be: item_accessor, accessor
            ...
            #return requested value
        },
        item_accessor => 'y_item'
    );

    use Triggers;

    my $obj = Triggers->new(y => [1,2,3]);

    - add hoc decorators

    package Class;
    use Abstract::Meta::Class ':all';

    has '%.attrs' => (item_accessor => 'attr');

    my $attr = DynamicInterceptor->meta->attribute('attrs');
    my $obj = DynamicInterceptor->new(attrs => {a => 1, b => 2});
    my $a = $obj->attr('a');
    my %hook_access_log;
    my $ncode_ref = sub {
        my ($self, $attribute, $scope, $key) = @_;
        #do some stuff
        # or
       if ($scope eq 'accessor') {
            return $values;
        } else {
            return $values->{$key};
        }

    };


    $attr->set_on_read($ncode_ref);
    # from now it will apply to Class::attrs calls.

    my $a = $obj->attr('a');

=head2 abstract methods/classes

    package BaseClass;

    use Abstract::Meta::Class ':all';

    has '$.attr1';
    abstract => 'method1';


    package Class;

    use base 'BaseClass';
    sub method1 {};

    use Class;

    my $obj = BaseClass->new;


    # abstract classes

    package InterfaceA;

    use Abstract::Meta::Class ':all';

    abstract_class;
    abstract => 'method1';
    abstract => 'method2';


    package ClassA;

    use base 'InterfaceA';

    sub method1 {};
    sub method2 {};

    use Class;

    my $classA = Class->new;


    package Class;

    use Abstract::Meta::Class ':all';

    has 'attr1';
    has 'interface_attr' => (associated_class => 'InterfaceA', required => 1);


    use Class;

    my $obj =  Class->new(interface_attr => $classA);


=head2 external attributes storage

    You may want store attributes values outside the blessed reference, then you may
    use transistent keyword (Inside Out Objects)

    package Transistent;
    use Abstract::Meta::Class ':all';

    has '$.attr1';
    has '$.x' => (required => 1);
    has '$.t' => (transistent => 1);
    has '%.th' => (transistent => 1);
    has '@.ta' => (transistent => 1);

    use Transistent;

    my $obj = Transistent->new(attr1 => 1, x => 2, t => 3, th => {a =>1}, ta => [1,2,3]);
    use Data::Dumper;
    print  Dumper $obj;

    Cleanup and DESTORY methods are added to class, that delete externally stored attributes.


=head2 METHODS

=over

=item new

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    unshift @_, $self;
    &apply_contructor_parameters;
}


=item install_cleanup

Install cleanup method

=cut

sub install_cleanup {
    my ($self) = @_;
    my $attributes;
    return if $self->has_cleanup_method;
    add_method($self->associated_class, 'cleanup' , sub {
        my $this = shift;
        my $has_transistent;
        my $attributes ||= $self ? $self->all_attributes : [];
        for my $attribute (@$attributes) {
            $attribute or next;
            $has_transistent = 1 if($attribute->transistent);
            if($attribute->the_other_end) {
                $attribute->deassociate($this);
                my $accessor = "set_" . $attribute->accessor;
                $this->$accessor(undef);
            }
        }
        Abstract::Meta::Attribute::Method::delete_object($this) if $has_transistent;
    });
    $self->set_cleanup_method(1);
}


=item install_destructor

Install destructor method

=cut

sub install_destructor {
    my ($self) = @_;
    return if $self->has_destory_method;
    add_method($self->associated_class, 'DESTROY' , sub {
        my $this = shift;
        $this->cleanup;
        $this;
    });
    $self->set_destroy_method(1);
}



=item install_constructor

Install constructor

=cut

sub install_constructor {
    my ($self) = @_;
    add_method($self->associated_class, 'new' ,
        $self->storage_type eq 'Array' ?
        sub {
            my $class = shift;
            my $this = bless [], $class;
            unshift @_, $this;
            &apply_contructor_parameters;
        }: sub {
            my $class = shift;
            my $this = bless {}, $class;
            unshift @_, $this;
            &apply_contructor_parameters;
        });
}


=item apply_contructor_parameters

Applies constructor parameters.

=cut

{
    sub apply_contructor_parameters {
        my ($self, @args) = @_;
        my $mutator;
        my $class = ref($self);
        eval {
            for (my $i = 0; $i < $#args; $i += 2) {
                    $mutator = "set_" . $args[$i];
                    $self->$mutator($args[$i + 1]);
            }
        };
        
        if ($@) {
            confess "unknown attribute " . ref($self) ."::" . $mutator
                unless $self->can($mutator);
            confess $@    
        }
        
        my $meta = $self->meta;
        return $self if $self eq $meta;
    
        for my $attribute ($meta->constructor_attributes) {
            if(! $attribute->get_value($self)) {
                my $can = $self->can($attribute->mutator) or next;
                $can->($self);
            }
        }
    
        my $initialise = $self->can($meta->initialise_method);
        $initialise->($self) if $initialise;
        $self;
    }
}

=item meta

=cut

sub meta { shift(); }


=item attributes

Returns attributes for meta class

=cut

sub attributes { shift()->{'@.attributes'} || {};}


=item set_attributes

Mutator sets attributes for the meta class

=cut

sub set_attributes { $_[0]->{'@.attributes'} = $_[1]; }



=item has_cleanup_method

Returns true if cleanup method was generated

=cut

sub has_cleanup_method { shift()->{'$.cleanup'};}


=item set_cleanup_method

Sets clean up

=cut

sub set_cleanup_method { $_[0]->{'$.cleanup'} = $_[1]; }


=item has_destory_method

Returns true is destroy method was generated

=cut

sub has_destory_method { shift()->{'$.destructor'};}


=item set_destroy_method

Sets set_destructor flag.

=cut

sub set_destroy_method { $_[0]->{'$.destructor'} = $_[1]; }


=item initialise_method

Returns initialise method's name default is 'initialise'


=cut

sub initialise_method { shift()->{'$.initialise_method'};}


=item is_abstract

Returns is class is an abstract class.

=cut

sub is_abstract{ shift()->{'$.abstract'};}



=item set_abstract

Set an abstract class flag.

=cut

sub set_abstract{ shift()->{'$.abstract'} = 1;}


=item set_initialise_method

Mutator sets initialise_method for the meta class

=cut

sub set_initialise_method { $_[0]->{'$.initialise_method'} = $_[1]; }


=item associated_class

Returns associated class name

=cut

sub associated_class { shift()->{'$.associated_class'} }


=item set_associated_class

Mutator sets associated class name

=cut

sub set_associated_class { $_[0]->{'$.associated_class'} = $_[1]; }



=item all_attributes

Returns all_attributes for all inherited meta classes

=cut

sub all_attributes {
    my $self = shift;
    if(my @super_classes = $self->super_classes) {
        my %attributes;
        foreach my $super (@super_classes) {
            my $meta_class = meta_class($super) or next;
            $attributes{$_->name} = $_ for @{$meta_class->all_attributes}; 
        }
        $attributes{$_->name} = $_ for @{$self->attributes};
        return [values %attributes];
    }
    $self->attributes;
}


=item attribute

Returns attribute object

=cut

sub attribute {
    my ($self, $name) = @_;
    my $attributes = $self->all_attributes;
    my @result = (grep {$_->accessor eq $name} @$attributes);
    @result ? $result[0] : undef;
}





=item super_classes

=cut

sub super_classes {
    my $self = shift;
    no strict 'refs';
    my $class = $self->associated_class;
    @{"${class}::ISA"};
}


{
   my %meta;

=item install_meta_class

Adds class to meta repository.

=cut

    sub install_meta_class {
        my ($class) = @_;
        $meta{$class} = __PACKAGE__->new(
            associated_class  => $class,
            attributes        => [],
            initialise_method => 'initialise'
        );
        add_method($class, 'meta', sub{$meta{$class}});
    }


=item meta_class

Returns meta class object for passed in class name.

=cut

    sub meta_class {
        my ($class) = @_;
        install_meta_class($class)unless $meta{$class};
        $meta{$class};
    }
}


=item add_attribute

=cut

sub add_attribute {
    my ($self, $attribute) = @_;
    $self->install_attribute_methods($attribute);
    push @{$self->attributes}, $attribute;
}


=item attribute_class

Returns meta attribute class

=cut

sub attribute_class { 'Abstract::Meta::Attribute' }


=item has

Creates a meta attribute.

Takes attribute name, and the following attribute options:
see also L<Abstract::Meta::Attribute>

=cut

sub has {
    my $name = shift;
    my $package = caller();
    my $meta_class = meta_class($package);
    my $attribute = $meta_class->attribute_class->new(name => $name, @_, class => $package, storage_type => $meta_class->storage_type);
    $meta_class->add_attribute($attribute);
    $meta_class->install_cleanup
        if($attribute->transistent || $attribute->index_by);
    $meta_class->install_destructor
        if $attribute->transistent;
    $attribute;
}


=item storage_type

Sets storage type for the attributes.
allowed values are Array/Hash

=cut

sub storage_type {
    my ($param) = @_;
    return $param->{'$.storage_type'} ||= 'Hash'
        if (ref($param));
    my $type = $param;
    confess "unknown storage type $type - should be Array or Hash"
        unless($type =~ /Array|Hash/);
    my $package = caller();
    my $meta_class = meta_class($package);
    $meta_class->{'$.storage_type'} = $type;
    remove_method($meta_class->associated_class, 'new');
    $meta_class->install_constructor();
   
}


=item abstract

Creates an abstract method

=cut

sub abstract {
    my $name = shift;
    my $package = caller();
    my $meta_class = meta_class($package);
    $meta_class->install_abstract_methods($name);
}



=item abstract_class

Creates an abstract method

=cut

sub abstract_class {
    my $name = shift;
    my $package = caller();
    my $meta_class = meta_class($package);
    $meta_class->set_abstract(1);
    no warnings 'redefine';
    no strict 'refs';
    *{"${package}::new"} = sub {
        confess "Can't instantiate abstract class " . $package;
    };
}

=item install_abstract_methods

=cut

sub install_abstract_methods {
    my ($self, $method_name) = @_;
    add_method($self->associated_class, $method_name, sub {
       confess $method_name . " is an abstract method"; 
    });
}


=item install_attribute_methods

Installs attribute methods.

=cut

sub install_attribute_methods {
    my ($self, $attribute, $remove_existing_method) = @_;
    my $accessor = $attribute->accessor;
    foreach (qw(accessor mutator)) {
        add_method($self->associated_class, $attribute->$_, $attribute->generate($_), $remove_existing_method); 
    }

    my $perl_type = $attribute->perl_type ;
    if ($perl_type eq 'Array') {
        add_method($self->associated_class, "${_}_$accessor", $attribute->generate("$_"), $remove_existing_method)
        for qw(count push pop shift unshift);
    }

    if (my $item_accessor = $attribute->item_accessor) {
        add_method($self->associated_class, $item_accessor, $attribute->generate('item_accessor'), $remove_existing_method);
    }
    
    if (($perl_type eq 'Array' || $perl_type eq 'Hash') && $attribute->associated_class) {
        add_method($self->associated_class, "add_${accessor}", $attribute->generate('add'), $remove_existing_method);
        add_method($self->associated_class, "remove_${accessor}", $attribute->generate('remove'), $remove_existing_method);
    }
    
    if($attribute->associated_class) {
        add_method($self->associated_class, "reset_${accessor}", $attribute->generate('reset'), $remove_existing_method);
        add_method($self->associated_class, "has_${accessor}", $attribute->generate('has'), $remove_existing_method);
    }
}


=item add_method

Adds code reference to the class symbol table.
Takes a class name, method name and CODE reference.

=cut

sub add_method {
    my ($class, $name, $code, $remove_existing_method) = @_;
    remove_method($class, $name) if $remove_existing_method;
    no strict 'refs';
    *{"${class}::$name"} = $code;
}


=item remove_method

Adds code reference to the class symbol table.
Takes a class name, method name and CODE reference.

=cut

sub remove_method {
    my ($class, $name) = @_;
    no strict 'refs';
    delete ${"${class}::"}{"$name"};
}



=item constructor_attributes

Returns a list of attributes that need be validated and all that have default value

=cut

sub constructor_attributes {
    my ($self) = @_;
    my $all_attributes = $self->all_attributes || [];
    grep  {$_->required || defined $_->default}  @$all_attributes;
}

1

__END__

=back

=head1 SEE ALSO

L<Abstract::Meta::Attribute>

=head1 COPYRIGHT AND LICENSE

The Abstract::Meta::Class module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut