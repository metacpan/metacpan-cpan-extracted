package Alzabo::Runtime::Column;

use strict;
use vars qw($VERSION);

use Alzabo::Runtime;
use Params::Validate qw( :all );
Params::Validate::validation_options( on_fail => sub { Alzabo::Exception::Params->throw( error => join '', @_ ) } );

use base qw(Alzabo::Column);

$VERSION = 2.0;

sub alias_clone
{
    my $self = shift;

    my %p = validate( @_, { table => { isa => 'Alzabo::Runtime::Table' },
                          } );

    my $clone;

    %$clone = %$self;
    $clone->{table} = $p{table};

    bless $clone, ref $self;

    return $clone;
}

sub alias
{
    my $self = shift;
    my %p = validate( @_, { as => { type => SCALAR } } );

    my $clone;
    %$clone = %$self;

    bless $clone, ref $self;

    $clone->{alias_name} = $p{as};
    $clone->{real_column} = $self;

    return $clone;
}

sub alias_name
{
    return $_[0]->{alias_name} || $_[0]->{name};
}

1;

__END__

=head1 NAME

Alzabo::Runtime::Column - Column objects

=head1 SYNOPSIS

  use Alzabo::Runtime::Column;

=for pod_merge DESCRIPTION

=head1 INHERITS FROM

C<Alzabo::Column>

=for pod_merge merged

=for pod_merge METHODS

=head2 alias

Takes the following parameters:

=over 4

=item * as => $name

=back

This method returns an object that can be used in calls to the table
and schema C<select()> methods in order to change the name given to
the column if C<next_as_hash()> is called on the
L<C<Alzabo::DriverStatement>|Alzabo::Driver/Alzabo::DriverStatment>
returned by the aforementioned C<select()> method.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
