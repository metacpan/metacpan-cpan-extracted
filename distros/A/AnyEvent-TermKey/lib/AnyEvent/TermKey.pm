#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk

package AnyEvent::TermKey;

use strict;
use warnings;

our $VERSION = '0.02';

use Carp;

use AnyEvent;
use Term::TermKey qw( RES_KEY RES_AGAIN );

=head1 NAME

C<AnyEvent::TermKey> - terminal key input using C<libtermkey> with C<AnyEvent>

=head1 SYNOPSIS

 use AnyEvent::TermKey qw( FORMAT_VIM KEYMOD_CTRL );
 use AnyEvent;
 
 my $cv = AnyEvent->condvar;
 
 my $aetk = AnyEvent::TermKey->new(
    term => \*STDIN,
 
    on_key => sub {
       my ( $key ) = @_;
 
       print "Got key: ".$key->termkey->format_key( $key, FORMAT_VIM )."\n";
 
       $cv->send if $key->type_is_unicode and
                    $key->utf8 eq "C" and
                    $key->modifiers & KEYMOD_CTRL;
    },
 );
 
 $cv->recv;

=head1 DESCRIPTION

This class implements an asynchronous perl wrapper around the C<libtermkey>
library, which provides an abstract way to read keypress events in
terminal-based programs. It yields structures that describe keys, rather than
simply returning raw bytes as read from the TTY device.

It internally uses an instance of L<Term::TermKey> to access the underlying C
library. For details on general operation, including the representation of
keypress events as objects, see the documentation on that class.

Proxy methods exist for normal accessors of C<Term::TermKey>, and the usual
behaviour of the C<getkey> or other methods is instead replaced by the
C<on_key> event.

=cut

# Forward any requests for symbol imports on to Term::TermKey
sub import
{
   shift; unshift @_, "Term::TermKey";
   my $import = $_[0]->can( "import" );
   goto &$import; # So as not to have to fiddle with Sub::UpLevel
}

=head1 CONSTRUCTOR

=cut

=head2 $aetk = AnyEvent::TermKey->new( %args )

This function returns a new instance of a C<AnyEvent::TermKey> object. It
takes the following named arguments:

=over 8

=item term => IO or INT

Optional. File handle or POSIX file descriptor number for the file handle to
use as the connection to the terminal. If not supplied C<STDIN> will be used.

=item on_key => CODE

CODE reference to the key-event handling callback. Will be passed an instance
of a C<Term::TermKey::Key> structure:

 $on_key->( $key )

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   # TODO: Find a better algorithm to hunt my terminal
   my $term = delete $args{term} || \*STDIN;

   my $on_key = $args{on_key};

   my $termkey = Term::TermKey->new( $term, delete $args{flags} || 0 );
   if( !defined $termkey ) {
      croak "Cannot construct a termkey instance\n";
   }

   my $timeout;
   my $iowatch = AnyEvent->io(
      fh => $term,
      poll => "r",
      cb => sub {
         undef $timeout;

         return unless $termkey->advisereadable == RES_AGAIN;

         my $ret;
         while( ( $ret = $termkey->getkey( my $key ) ) == RES_KEY ) {
            $on_key->( $key );
         }

         if( $ret == RES_AGAIN ) {
            $timeout = AnyEvent->timer(
               after => $termkey->get_waittime / 1000,
               cb => sub {
                  if( $termkey->getkey_force( my $key ) == RES_KEY ) {
                     $on_key->( $key );
                  }
               },
            );
         }
      },
   );

   return bless {
      termkey => $termkey,
      iowatch => $iowatch,
      on_key  => $args{on_key},
   }, $class;
}

=head1 METHODS

=cut

=head2 $tk = $aetk->termkey

Returns the C<Term::TermKey> object being used to access the C<libtermkey>
library. Normally should not be required; the proxy methods should be used
instead. See below.

=cut

sub termkey
{
   my $self = shift;
   return $self->{termkey};
}

=head2 $flags = $aetk->get_flags

=head2 $aetk->set_flags( $flags )

=head2 $canonflags = $aetk->get_canonflags

=head2 $aetk->set_canonflags( $canonflags )

=head2 $msec = $aetk->get_waittime

=head2 $aetk->set_waittime( $msec )

=head2 $str = $aetk->get_keyname( $sym )

=head2 $sym = $aetk->keyname2sym( $keyname )

=head2 ( $ev, $button, $line, $col ) = $aetk->interpret_mouse( $key )

=head2 $str = $aetk->format_key( $key, $format )

=head2 $key = $aetk->parse_key( $str, $format )

=head2 $key = $aetk->parse_key_at_pos( $str, $format )

=head2 $cmp = $aetk->keycmp( $key1, $key2 )

These methods all proxy to the C<Term::TermKey> object, and allow transparent
use of the C<AnyEvent::TermKey> object as if it was a subclass. Their
arguments, behaviour and return value are therefore those provided by that
class. For more detail, see the L<Term::TermKey> documentation.

=cut

# Proxy methods for normal Term::TermKey access
foreach my $method (qw(
   get_flags
   set_flags
   get_canonflags
   set_canonflags
   get_waittime
   set_waittime
   get_keyname
   keyname2sym
   interpret_mouse
   format_key
   parse_key
   parse_key_at_pos
   keycmp
)) {
   no strict 'refs';
   *{$method} = sub {
      my $self = shift;
      $self->termkey->$method( @_ );
   };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
