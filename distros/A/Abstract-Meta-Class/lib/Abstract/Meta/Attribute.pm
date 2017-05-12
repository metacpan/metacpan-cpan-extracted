package Abstract::Meta::Attribute;

use strict;
use warnings;
use Carp 'confess';
use base 'Abstract::Meta::Attribute::Method';
use vars qw($VERSION);

$VERSION = 0.04;

=head1 NAME

Abstract::Meta::Attribute - Meta object attribute.

=head1 SYNOPSIS

    use Abstract::Meta::Class ':all';
    has '$.attr1' => (default => 0);    

=head1 DESCRIPTION

An object that describes an attribute.
It includes required, data type, association validation, default value, lazy retrieval.
Name of attribute must begin with one of the follwoing prefix:
    $. => Scalar,
    @. => Array,
    %. => Hash,
    &. => Code,


=head1 EXPORT

None.

=head2 METHODS

=over

=item new

=cut


sub new {
    my $class = shift;
    unshift @_, $class;
    bless {&initialise}, $class;
}


=item initialise

Initialises attribute

=cut

{
   my %supported_type = (
      '$' => 'Scalar',
      '@' => 'Array',
      '%' => 'Hash',
      '&' => 'Code',
    );

    sub initialise {
        my ($class, %args) = @_;
        foreach my $k (keys %args) {
            confess "unknown attribute $k"
            unless Abstract::Meta::Attribute->can($k);
        }
        my $name = $args{name} or confess "name is requried";
        my $storage_type = $args{storage_type} = $args{transistent} ? 'Hash' : $args{storage_type} || '';
        
        my $attribute_index = 0;
        if($storage_type  eq 'Array')  {
            my $meta_class= Abstract::Meta::Class::meta_class($args{class});
            $attribute_index = $#{$meta_class->all_attributes} + 1;
        }
        
        my ($type, $accessor_name) = ($name =~ /^([\$\@\%\&])\.(.*)$/);
        confess "invalid attribute defintion ${class}::" .($accessor_name || $name) .", supported prefixes are \$.,%.,\@.,&."
          if ! $type || ! $supported_type{$type};

        my %options;
        $args{data_type_validation} = 1
        if (! exists($args{data_type_validation})
            && ($type eq '@' || $type eq '%' || $args{associated_class}));

        $options{'&.' . $_ } = $args{$_}
            for grep {exists $args{$_}} (qw(on_read on_change on_validate));
        
        
        my $storage_key = $storage_type eq 'Array' ? $attribute_index : $args{storage_key} || $args{name};

        $options{'$.name'} = $accessor_name;
        $options{'$.storage_key'} = $storage_key;
        $options{'$.mutator'} = "set_$accessor_name";
        $options{'$.accessor'} = $accessor_name;
        $options{'$.' . $_ } = $args{$_}
          for grep {exists $args{$_}}
            (qw(class required default item_accessor associated_class data_type_validation index_by the_other_end transistent storage_type));
          
        $options{'$.perl_type'} = $supported_type{$type};
        unless  ($args{default}) {
            if($type eq '%') {
                $options{'$.default'} = sub{ {} };
            } elsif ($type eq '@') {
                $options{'$.default'} = sub { [] };
            }
        }        
        %options;
    }
}


=item name

Returns attribute name

=cut

sub name { shift()->{'$.name'} }


=item class

Attribute's class name.

=cut

sub class { shift()->{'$.class'} }


=item storage_key

Returns storage attribute key in object

=cut

sub storage_key { shift()->{'$.storage_key'} }



=item perl_type

Returns attribute type, Scalar, Hash, Array, Code

=cut

sub perl_type { shift()->{'$.perl_type'} }


=item accessor

Returns accessor name

=cut

sub accessor { shift()->{'$.accessor'} }


=item mutator

Returns mutator name

=cut

sub mutator { shift()->{'$.mutator'} }


=item required

Returns required flag

=cut

sub required { shift()->{'$.required'} }


=item default

Returns default value

=cut

sub default { shift()->{'$.default'} }


=item storage_type

Hash|Array

=cut

sub storage_type { shift()->{'$.storage_type'} ||= 'Hash' }


=item transistent

If this flag is set, than storage of that attribte, will be force outside the object,
so you cant serialize that attribute,
It is especially useful when using callback, that cant be serialised (Storable dclone)
This option will generate cleanup and DESTORY methods.

=cut

sub transistent { shift()->{'$.transistent'} }


=item item_accessor

Returns name that will be used to construct the hash or array item accessor.
It will be used to retrieve or set array  or hash item item


has '%.items' => (item_accessor => 'item');
...
my $item_ref = $obj->items;
$obj->item(x => 3);
my $value = $obj->item('y')'


=cut

sub item_accessor { shift()->{'$.item_accessor'} }



=item associated_class

Return name of the associated class.

=cut

sub associated_class { shift()->{'$.associated_class'} }


=item index_by

Name of the asscessor theat will return unique attribute for associated objects.
Only for toMany associaion, by deault uses objecy reference as index.

package Class;
use Abstract::Meta::Class ':all';
has '$.name' => (required => 1);
has '%.details' => (
    index_by         => 'id',
    item_accessor    => 'detail',
);
my $obj = Class->




=cut

sub index_by { shift()->{'$.index_by'} }


=item the_other_end

Name of the asscessor/mutator on associated class to keep bideriectional association
This option will generate cleanup method.

=cut

sub the_other_end { shift()->{'$.the_other_end'} }


=item data_type_validation

Flag that turn on/off data type validation.
Data type validation happens when using association_class or Array or Hash data type 
unless you explicitly disable it by seting data_type_validation => 0.

=cut

sub data_type_validation { shift()->{'$.data_type_validation'} }


=item on_read

Returns code reference that will be replace data read routine

    has '%.attrs.' => (
        item_accessor => 'attr'
        on_read => sub {
            my ($self, $attribute, $scope, $key) = @_;
            my $values = $attribute->get_values($self);
            if ($scope eq 'accessor') {
                return $values;
            } else {
                return $values->{$key};
            }
        },
    );
    has '@.array_attrs.' => (
        item_accessor => 'array_item'
        on_read => sub {
            my ($self, $attribute, $scope, $index) = @_;
            my $values = $attribute->get_values($self);
            if ($scope eq 'accessor') {
                return $values;
            } else {
                return $values->[$index];
            }
        },
    );

=cut

sub on_read { shift()->{'&.on_read'} }


=item set_on_read

Sets  code reference that will be replace data read routine

   my $attr = MyClass->meta->attribute('attrs'); 
    $attr->set_on_read(sub {
        my ($self, $attribute, $scope, $key) = @_;
        #do some stuff
    });

=cut

sub set_on_read {
    my ($attr, $value) = @_;
    $attr->{'&.on_read'} = $value;
    my $meta= $attr->class->meta;
    $meta->install_attribute_methods($attr, 1);
}


=item on_change

Code reference that will be executed when data is set,
Takes reference to the variable to be set.

=cut

sub on_change { shift()->{'&.on_change'} }



=item set_on_change

Sets code reference that will be executed when data is set,

   my $attr = MyClass->meta->attribute('attrs'); 
   $attr->set_on_change(sub {
           my ($self, $attribute, $scope, $value, $key) = @_;
            if($scope eq 'mutator') {
                my $hash = $$value;
                foreach my $k (keys %$hash) {
                    #  do some stuff
                    #$self->validate_trigger($k, $hash->{$k});
                }
            } else {
                # do some stuff
                $self->validate_trigger($key. $$value);
            }
            $self;      
    });

=cut

sub set_on_change {
    my ($attr, $value) = @_;               
    $attr->{'&.on_change'} = $value;
    my $meta= $attr->class->meta;
    $meta->install_attribute_methods($attr, 1);
}





=item on_validate

Returns on validate code reference.
It is executed before the data type validation happens.

=cut

sub on_validate { shift()->{'&.on_validate'} }


=item set_on_validate

Sets  code reference that will be replace data read routine

   my $attr = MyClass->meta->attribute('attrs'); 
    $attr->set_on_read(sub {
        my ($self, $attribute, $scope, $key) = @_;
        #do some stuff
    });

=cut

sub set_on_validate {
    my ($attr, $value) = @_;
    $attr->{'&.on_validate'} = $value;
    my $meta= $attr->class->meta;
    $meta->install_attribute_methods($attr, 1);
}




1;    

__END__

=back

=head1 SEE ALSO

L<Abstract::Meta::Class>.

=head1 COPYRIGHT AND LICENSE

The Abstract::Meta::Attribute module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut