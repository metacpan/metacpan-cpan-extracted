package Alzabo::Create::ColumnDefinition;

use strict;
use vars qw($VERSION);

use Alzabo::Create;
use Alzabo::Exceptions ( abbr => 'params_exception' );

use Params::Validate qw( :all );
Params::Validate::validation_options
    ( on_fail => sub { params_exception join '', @_ } );

use base qw(Alzabo::ColumnDefinition);

$VERSION = 2.0;

1;

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my $self = shift;

    validate( @_, { owner => { isa => 'Alzabo::Create::Column' },
                    type  => { type => SCALAR },
                    length => { type => UNDEF | SCALAR,
                                optional => 1 },
                    precision  => { type => UNDEF | SCALAR,
                                    optional => 1 },
                  } );
    my %p = @_;

    $p{type} =
        $p{owner}->table->schema->rules->validate_column_type( $p{type}, $p{owner}->table );
    foreach ( qw( owner type ) )
    {
        $self->{$_} = $p{$_} if exists $p{$_};
    }
}

sub alter
{
    my $self = shift;

    validate( @_, { type  => { type => SCALAR },
                    length => { type => UNDEF | SCALAR,
                                optional => 1 },
                    precision  => { type => UNDEF | SCALAR,
                                    optional => 1 },
                  } );
    my %p = @_;

    my $old_type = $self->{type};
    my $old_length = $self->{length};
    my $old_precision = $self->{precision};

    $self->{length} = $p{length} if exists $p{length};
    $self->{precision} = $p{precision} if exists $p{precision};

    eval
    {
        $self->{type} =
            $self->owner->table->schema->rules->validate_column_type($p{type}, $self->owner->table);
        $self->owner->table->schema->rules->validate_primary_key($self->owner)
            if $self->owner->is_primary_key;
        $self->owner->table->schema->rules->validate_column_length($self->owner);
    };
    if ($@)
    {
        $self->{type} = $old_type;
        $self->{length} = $old_length;
        $self->{precision} = $old_precision;

        rethrow_exception($@);
    }
}

sub set_type
{
    my $self = shift;

    validate_pos( @_, { type => SCALAR } );
    my $type = shift;

    my $old_type = $self->{type};
    eval
    {
        $self->{type} =
            $self->owner->table->schema->rules->validate_column_type($type, $self->owner->table);
        $self->owner->table->schema->rules->validate_primary_key($self->owner)
            if eval { $self->owner->is_primary_key };
        # eval ^^ cause if we're creating the column its not in the table yet
    };
    if ($@)
    {
        $self->{type} = $old_type;

        rethrow_exception($@);
    }
}

sub set_length
{
    my $self = shift;

    validate( @_, { length => { type => UNDEF | SCALAR },
                    precision => { type => UNDEF | SCALAR,
                                   optional => 1 } } );
    my %p = @_;

    my $old_length = $self->{length};
    my $old_precision = $self->{precision};
    $self->{length} = $p{length};
    $self->{precision} = $p{precision} if exists $p{precision};

    eval
    {
        $self->owner->table->schema->rules->validate_column_length($self->owner);
    };
    if ($@)
    {
        $self->{length} = $old_length;
        $self->{precision} = $old_precision;

        rethrow_exception($@);
    }
}

1;

__END__

=head1 NAME

Alzabo::Create::ColumnDefinition - Column definition object for schema
creation

=head1 SYNOPSIS

  use Alzabo::Create::ColumnDefinition;

=head1 DESCRIPTION

This object holds information on a column that might need to be shared
with another column.  The reason this class exists is that if a column
is a key in two or more tables, then some of the information related
to that column should change automatically in multiple places whenever
it changes at all.  Right now this is only type ('VARCHAR', 'NUMBER',
etc) and length/precision information.  This object also has an
'owner', which is the column which created it.

=head1 INHERITS FROM

C<Alzabo::ColumnDefinition>

=for pod_merge merged

=head1 METHODS

=head2 new

This method takes the following parameters:

=over 4

=item * owner => C<Alzabo::Create::ColumnDefinition> object

=item * type => $type

=back

It returns a new C<Alzabo::Create::ColumnDefinition> object.

=head2 alter

See the L<C<< Alzabo::Column->alter() >>|Alzabo::Column/alter> method
for details.

=for pod_merge type

=head2 set_type ($string)

Sets the object's type.

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::RDBMSRules>|Alzabo::Exceptions>

=for pod_merge length

=for pod_merge precision

=head2 set_length

This method takes the following parameters:

=over 4

=item * length => $length

=item * precision => $precision (optional)

=back

Sets the column's length and precision.  The precision parameter is
optional (though some column types may require it if the length is
set).

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::RDBMSRules>|Alzabo::Exceptions>

=for pod_merge owner

=cut
