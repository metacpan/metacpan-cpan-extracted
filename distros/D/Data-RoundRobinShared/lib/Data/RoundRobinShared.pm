package Data::RoundRobinShared;

use strict;
use warnings;
use IPC::Shareable (':lock');
use Carp;

our $VERSION = '0.11';

use overload
  'eq' => \&next,
  'ne' => \&next,
  '""' => \&next;

sub new
{
    my $class  = shift;
    my %params = @_;

    croak("odd number of arguments passed") if ( @_ % 2 );
    croak("data needs to be specified") unless ( exists( $params{data} ) );
    croak("data needs to be arrayref") unless ( ref $params{data} eq 'ARRAY' );

    my $self = {};

    $class = ref $class || $class;

    my %options = ( key => $params{key} || 'sharedRoundRoundRobin', create => 1, mode => 0644 );

    tie $self->{data}, 'IPC::Shareable', $params{key}, {%options} or croak("server: tie failed");

    if ( !$self->{data} || ( ref $self->{data} eq 'ARRAY' && scalar( @{ $self->{data} } ) != scalar( @{ $params{data} } ) && $params{simple_check} ) )
    {
        ( tied $self->{data} )->shlock(LOCK_EX);
        $self->{data} = [ @{ $params{data} } ];
        ( tied $self->{data} )->shlock(LOCK_UN);
    }

    return bless $self, $class;
}

sub next
{
    my $self = shift;

    ( tied $self->{data} )->shlock(LOCK_EX);

    my $val = shift( @{ $self->{data} } );
    push( @{ $self->{data} }, $val );

    ( tied $self->{data} )->shlock(LOCK_UN);

    return $val;
}

sub remove
{
    my $self = shift;

    ( tied $self->{data} )->remove;

    return 1;
}

1;

__END__

=head1 NAME

Data::RoundRobinShared - Serve data in a round robin manner, keeping the data in a shared memory so that it can be used by multiple processes and each get data in a roundrobin manner.

=head1 SYNOPSIS

	use Data::RoundRobinShared;

	my $sr = new Data::RoundRobinShared(key => 'DataForProcess1',data=> \@data, simple_check => 1);
	my $item = $sr->next;

=head1 DESCRIPTION

This module allows you to serve data in a round robin manner shared between processes using a namespace key to identify each data-set.

=head1 METHODS

=over 4

=item new

Constructor, an arrayref containing the data, a string as key should be provided to construct a C<Data::RoundRobinShared> object.

=item next

Retrieve next value.

=item remove

Release the shared memory.

=back

=head1 SEE ALSO

L<Data::RoundRobin>

=head1 COPYRIGHT

Copyright 2010 by S Pradeep E<lt>pradeep@pradeep.net.inE<gt>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut


