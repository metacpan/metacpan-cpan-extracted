#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk

package Commandable::Invocation;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

C<Commandable::Invocation> - represents one invocation of a CLI command

=head1 SYNOPSIS

   my %commands = (
      exit  => sub { exit },
      print => sub { print $_[0]->remaining },
      ...
   );

   while(1) {
      my $inv = Commmandable::Invocation->new( scalar <STDIN> );

      $commands{ $inv->pull_token }->( $inv );
   }

=head1 DESCRIPTION

Instances of this class represent the text of a single invocation of a CLI
command, allowing it to be incrementally parsed and broken into individual
tokens during dispatch and invocation.

=head2 Tokens

When parsing for the next token, strings quoted using quote marks (C<"">) will
be retained as a single token. Otherwise, tokens are split on (non-preserved)
whitespace.

Quote marks and backslashes may be escaped using C<\> characters.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $inv = Commandable::Invocation->new( $text )

Constructs a new instance, initialised to contain the given text string.

=cut

sub new
{
   my $class = shift;
   my ( $text ) = @_;

   $text =~ s/^\s+//;

   return bless {
      text => $text,
   }, $class;
}

=head1 METHODS

=cut

sub _next_token
{
   my $self = shift;

   if( $self->{text} =~ m/^"/ ) {
      $self->{text} =~ m/^"(.*)"\s*/ and
         $self->{trim_pos} = $+[0], return $self->_unescape( $1 );
   }
   else {
      $self->{text} =~ m/^(\S+)\s*/ and
         $self->{trim_pos} = $+[0], return $self->_unescape( $1 );
   }

   return undef;
}

sub _unescape
{
   my $self = shift;
   my ( $s ) = @_;

   $s =~ s/\\(["\\])/$1/g;

   return $s;
}

=head2 peek_token

   $token = $inv->peek_token

Looks at, but does not remove, the next token in the text string. Subsequent
calls to this method will yield the same string, as will the next call to
L</pull_token>.

=cut

sub peek_token
{
   my $self = shift;

   return $self->{next_token} //= $self->_next_token;
}

=head2 pull_token

   $token = $inv->pull_token

Removes the next token from the text string and returns it.

=cut

sub pull_token
{
   my $self = shift;

   my $token = $self->{next_token} //= $self->_next_token;

   substr $self->{text}, 0, $self->{trim_pos}, "" if defined $token;
   undef $self->{next_token};

   return $token;
}

=head2 remaining

   $text = $inv->remaining

Returns the entire unparsed content of the rest of the text string.

=cut

sub remaining
{
   my $self = shift;
   return $self->{text};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
