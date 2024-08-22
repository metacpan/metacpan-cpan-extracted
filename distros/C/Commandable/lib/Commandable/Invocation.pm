#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018-2024 -- leonerd@leonerd.org.uk

package Commandable::Invocation 0.12;

use v5.26;
use warnings;
use experimental qw( signatures );

=head1 NAME

C<Commandable::Invocation> - represents one invocation of a CLI command

=head1 SYNOPSIS

   my %commands = (
      exit  => sub { exit },
      print => sub { print $_[0]->peek_remaining },
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

sub new ( $class, $text )
{
   $text =~ s/^\s+//;

   return bless {
      text => $text,
   }, $class;
}

=head2 new_from_tokens

   $inv = Commandable::Invocation->new_from_tokens( @tokens )

I<Since version 0.03.>

Constructs a new instance, initialised to contain text from the given tokens,
such that subsequent calls to L</pull_token> will yield the given list of
tokens. This may be handy for constructing instances from C<@ARGV> or similar
cases where text has already been parsed and split into tokens.

=cut

sub new_from_tokens ( $class, @tokens )
{
   my $self = $class->new( "" );
   $self->putback_tokens( @tokens );

   return $self;
}

=head1 METHODS

=cut

sub _next_token ( $self )
{
   if( $self->{text} =~ m/^"/ ) {
      $self->{text} =~ m/^"((?:\\.|[^"])*)"\s*/ and
         $self->{trim_pos} = $+[0], return $self->_unescape( $1 );
   }
   else {
      $self->{text} =~ m/^(\S+)\s*/ and
         $self->{trim_pos} = $+[0], return $self->_unescape( $1 );
   }

   return undef;
}

sub _escape ( $self, $s )
{
   return $s =~ s/(["\\])/\\$1/gr;
}

sub _unescape ( $self, $s )
{
   return $s =~ s/\\(["\\])/$1/gr;
}

=head2 peek_token

   $token = $inv->peek_token;

Looks at, but does not remove, the next token in the text string. Subsequent
calls to this method will yield the same string, as will the next call to
L</pull_token>.

=cut

sub peek_token ( $self )
{
   return $self->{next_token} //= $self->_next_token;
}

=head2 pull_token

   $token = $inv->pull_token;

Removes the next token from the text string and returns it.

=cut

sub pull_token ( $self )
{
   my $token = $self->{next_token} //= $self->_next_token;

   substr $self->{text}, 0, $self->{trim_pos}, "" if defined $token;
   undef $self->{next_token};

   return $token;
}

=head2 peek_remaining

   $text = $inv->peek_remaining;

I<Since version 0.04.>

Returns the entire unparsed content of the rest of the text string.

=cut

sub peek_remaining ( $self )
{
   return $self->{text};
}

=head2 putback_tokens

   $inv->putback_tokens( @tokens );

I<Since version 0.02.>

Prepends text back onto the stored text string such that subsequent calls to
L</pull_token> will yield the given list of tokens once more. This takes care
to quote tokens with spaces inside, and escape any embedded backslashes or
quote marks.

This method is intended to be used, for example, around a commandline option
parser which handles mixed options and arguments, to put back the non-option
positional arguments after the options have been parsed and removed from it.

=cut

sub putback_tokens ( $self, @tokens )
{
   $self->{text} = join " ",
      ( map {
         my $s = $self->_escape( $_ );
         $s =~ m/ / ? qq("$s") : $s
      } @tokens ),
      ( length $self->{text} ? $self->{text} : () );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
