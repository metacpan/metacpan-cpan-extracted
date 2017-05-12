package DBIx::Class::Schema::PopulateMore::Command;

use Moo;
use MooX::HandlesVia;
use List::MoreUtils qw(pairwise);
use DBIx::Class::Schema::PopulateMore::Visitor;
use Module::Pluggable::Object;
use Type::Library -base;
use Types::Standard -types;
use namespace::clean;

=head1 NAME

DBIx::Class::Schema::PopulateMore::Command - Command Class to Populate a Schema

=head1 DESCRIPTION

This is a command pattern  class to manage the job of populating a
L<DBIx::Class::Schema> with information.  We break this out because the
actual job is a bit complex, is likely to grow more complex, and so that
we can more easily identify refactorable and reusable parts.

=head1 ATTRIBUTES

This class defines the following attributes.

=head2 schema

This is the Schema we are populating

=cut

has schema => (
    is=>'ro',
    required=>1,
    isa=>Object,
);

=head2 exception_cb

contains a callback to the exception method supplied by DBIC

=cut

has exception_cb => (
    is=>'ro',
    required=>1,
    isa=>CodeRef,
);

=head2 definitions

This is an arrayref of information used to populate tables in the database

=cut

has definitions => (
    is=>'ro',
    required=>1,
    isa=>ArrayRef[HashRef],
);


=head2 match_condition

How we know the value is really something to inflate or perform a substitution
on.  This get's the namespace of the substitution plugin and it's other data.

=cut

has match_condition => (
    is=>'ro',
    required=>1,
    isa=>RegexpRef, 
    default=>sub {qr/^!(\w+:.+)$/ },
);


=head2 visitor

We define a visitor so that we can perform the value inflations and or 
substitutions.  This is still a little work in progress, but it's getting 
neater

=cut

has visitor => (
    is=>'lazy',
    isa=>InstanceOf['DBIx::Class::Schema::PopulateMore::Visitor'],
    handles => [
        'callback',
        'visit', 
    ],
);


=head2 rs_index

The index of previously inflated resultsets.  Basically when we create a new
row in the table, we cache the result object so that it can be used as a 
dependency in creating another.

Eventually will be moved into the constructor for a plugin

=head2 set_rs_index

Set an index value to an inflated result

=head2 get_rs_index

given an index, returns the related inflated resultset

=cut

has rs_index => (
    is=>'rw',
    handles_via=>'Hash',
    isa=>HashRef[Object],
    default=>sub { +{} },
    handles=> {
        set_rs_index => 'set',
        get_rs_index => 'get',
    },
);


=head2 inflator_loader

Loads each of the available inflators, provider access to the objects

=cut

has inflator_loader => (
    is=>'lazy',
    isa=>InstanceOf['Module::Pluggable::Object'],
    handles=>{
        'inflators' => 'plugins',
    },
);


=head2 inflator_dispatcher

Holds an object that can perform dispatching to the inflators.

=cut

has inflator_dispatcher => (
    is=>'lazy',
    handles_via=>'Hash',
    isa=>HashRef[Object],
    handles=>{
        inflator_list => 'keys',
        get_inflator  => 'get',
    },
);


=head1 METHODS

This module defines the following methods.

=head2 _build_visitor

lazy build for the L</visitor> attribute.

=cut

sub _build_visitor
{
    my $self = shift @_;
    
    DBIx::Class::Schema::PopulateMore::Visitor->new({
        match_condition=>$self->match_condition
    });    
}


=head2 _build_inflator_loader

lazy build for the L</inflator_loader> attribute

=cut

sub _build_inflator_loader
{
    my $self = shift @_;
    
    return Module::Pluggable::Object->new(
        search_path => 'DBIx::Class::Schema::PopulateMore::Inflator',
        require => 1,
        except => 'DBIx::Class::Schema::PopulateMore::Inflator', 
    );    
}


=head2 _build_inflator_dispatcher

lazy build for the L</inflator_dispatcher> attribute

=cut

sub _build_inflator_dispatcher
{
    my $self = shift @_;
    
    my %inflators;
    for my $inflator ($self->inflators)
    {
        my $inflator_obj = $inflator->new;
        my $name = $inflator_obj->name;
        
        $inflators{$name} = $inflator_obj;
        
    }
    
    return \%inflators;
}


=head2 execute

The command classes main method.  Returns a Hash of the created result
rows, where each key is the named index and the value is the row object.

=cut

sub execute
{
    my ($self) = @_;

    foreach my $definition (@{$self->definitions})
    {
        my ($source => $info) = %$definition;
        my @fields = $self->coerce_to_array($info->{fields});
        
        my $data = $self
            ->callback(sub {
                $self->dispatch_inflator(shift);
            })
            ->visit($info->{data});
            
        while( my ($rs_key, $values) = each %{$data} )
        {
            my @values = $self->coerce_to_array($values);
            
            my $new = $self->create_fixture(
                $rs_key => $source,
                $self->merge_fields_values([@fields], [@values])
            );
        }
    }
    
    return %{$self->rs_index};
}


=head2 dispatch_inflator

Dispatch to the correct inflator

=cut

sub dispatch_inflator
{
    my ($self, $arg) = @_;
    my ($name, $command) =  ($arg =~m/^(\w+):(\w.+)$/); 
    
    if( my $inflator = $self->get_inflator($name) )
    {
        $inflator->inflate($self, $command);
    }
    else
    {
        my $available = join(', ', $self->inflator_list);
        $self->exception_cb->("Can't Handle $name, available are: $available");
    }
}


=head2 create_fixture({})

Given a hash suitable for a L<DBIx::Class::Resultset> create method, attempt to
update or create a row in the named source.

returns the newly created row or throws an exception if there is a failure

=cut

sub create_fixture
{
    my ($self, $rs_key => $source, @create) = @_;
    
    my $new = $self
        ->schema
        ->resultset($source)
        ->update_or_create({@create});    
        
    $self->set_rs_index("$source.$rs_key" => $new);
    
    return $new;
}


=head2 merge_fields_values

Given a fields and values, combine to a hash suitable for using in a create_fixture
row statement.

=cut

sub merge_fields_values
{
    my ($self, $fields, $values) = @_;
    
    return pairwise { 
        $self->field_value($a,$b)
    } (@$fields, @$values);    
}


=head2 field_value

Correctly create an array from the fields, values variables, skipping those
where the value is undefined.

=cut

sub field_value
{
    my ($self, $a, $b) = @_;
    
    if(defined $a && defined $b)
    {
        return $a => $b;
    }
    else
    {
        return;
    }
}


=head2 coerce_to_array

given a value that is either an arrayref or a scalar, put it into array context
and return that array.

=cut

sub coerce_to_array
{
    my ($self, $value) = @_;
    
    return ref $value eq 'ARRAY' ? @$value:($value);
}


=head1 AUTHOR

Please see L<DBIx::Class::Schema::PopulateMore> For authorship information

=head1 LICENSE

Please see L<DBIx::Class::Schema::PopulateMore> For licensing terms.

=cut


1;
