#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009 -- leonerd@leonerd.org.uk

package CPS::Governor::IOAsync;

use strict;
use warnings;

use Carp;

use base qw( CPS::Governor::Deferred );

our $VERSION = '0.02';

=head1 NAME

C<CPS::Governor::IOAsync> - use L<IO::Async> with L<CPS>

=head1 SYNOPSIS

 use CPS qw( gkforeach );
 use CPS::Governor::IOAsync;

 use IO::Async::Loop;

 my $loop = IO::Async::Loop->new;

 my $gov = CPS::Governor::IOAsync->new( loop => $loop );

 gkforeach( $gov, [ 1 .. 10 ],
    sub {
       my ( $item, $knext ) = @_;

       $loop->do_something( on_done => $knext );
    },
    sub { $loop->loop_stop },
 );

 $loop->loop_forever;

=head1 DESCRIPTION

This L<CPS::Governor> allows functions using it to defer their re-execution
by using the L<IO::Async::Loop> C<later> method, meaning it will interleave
with other IO operations performed by C<IO::Async>.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $gov = CPS::Governor::IOAsync->new( %args )

Returns a new instance of a C<CPS::Governor::IOAsync> object. Requires the
following argument:

=over 8

=item loop => IO::Async::Loop

Reference to the C<IO::Async::Loop> object.

=back

Additionally may take any other arguments defined by the
L<CPS::Governor::Deferred> class.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $loop = delete $args{loop} or croak "Expected a 'loop'";

   my $self = $class->SUPER::new( %args );

   $self->{loop} = $loop;

   return $self;
}

sub later
{
   my $self = shift;
   $self->SUPER::later( @_ );

   return if $self->{later_queued};

   $self->{loop}->later( sub {
      undef $self->{later_queued};
      $self->prod;
   } );

   $self->{later_queued} = 1;
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
