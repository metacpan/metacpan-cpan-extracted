#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015 -- leonerd@leonerd.org.uk

package App::perlsh;

use strict;
use warnings;

our $VERSION = '0.02';

use List::Util qw( reduce );
use Term::ReadLine;
use Term::Size;

use Lexical::Persistence 0.98;

my $COLS = Term::Size::chars \*STDOUT;

$SIG{WINCH} = sub {
   $COLS = Term::Size::chars \*STDOUT;
};

=head1 NAME

C<App::perlsh> - a simple F<perl> REPL based on C<Lexical::Persistence>

=head1 SYNOPSIS

 use App::perlsh;

 App::perlsh->run

=head1 DESCRIPTION

This module implements an application that provides a simple perl REPL
("read-execute-print loop"); that is, an interactive shell-like program that
repeatedly reads perl code from input, executes it, and prints the result in a
readable manner.

Being based on L<Lexical::Persistence> allows it to accumulate variables along
the session, letting the user reuse them in later lines.

  $ perlsh
  eval: my $one = 1;
  '1'

  eval: my $two = 2;
  '2'

  eval: $one + $two
  '3'

  eval:

=cut

sub new
{
   my $class = shift;
   return bless {}, $class;
}

# function
sub _longest { reduce { length $a > length $b ? $a : $b } @_ }

# function
sub _repr
{
   my ( $v, $leader, $leader2 ) = @_;

   $leader = "" if !defined $leader;
   $leader2 = $leader if !defined $leader2;

   if( !defined $v ) {
      return "${leader}undef";
   }
   elsif( !ref $v ) {
      if( $v =~ m/[^\x20-\x7e]/ ) {
         $v =~ s{(["\\])}{\\$1}g;
         $v =~ s{\e}{\\e}g;
         $v =~ s{\t}{\\t}g;
         $v =~ s{\n}{\\n}g;
         $v =~ s{\r}{\\r}g;
         $v =~ s{([^\x20-\x7e])}{"\\x" . sprintf( "%02x", ord $1 ) }eg;
         return $leader . qq{"$v"};
      }
      else {
         $v =~ s{(['\\])}{\\$1}g;
         return $leader . qq{'$v'};
      }
   }
   elsif( ref $v eq "SCALAR" ) {
      my $rv = $$v;
      return "\\" . _repr( $rv );
   }
   elsif( ref $v eq "ARRAY" ) {
      my @slots = map { _repr( $_ ) } @$v;

      # See if we're going to use oneline representation
      my $oneline = 1;
      $_ =~ m/\n/ and $oneline = 0, last foreach @slots;

      if( $oneline ) {
         my $ret = $leader . "[ " . join( ", ", @slots ) . " ]";
         return $ret if length $ret < $COLS;
      }

      my ( $first, @rest ) = @$v;
      return $leader . "[ " . 
             join( ",\n$leader2  ", _repr( $first, $leader, "$leader2  " ),
                                    map { _repr( $_, $leader2, "$leader2  " ) } @rest )
             . " ]";
   }
   elsif( ref $v eq "HASH" ) {
      my @keys = sort keys %$v;
      my @values = map { _repr( $v->{$_} ) } @keys;

      my $oneline = 1;
      $_ =~ m/\n/ and $oneline = 0, last foreach @values;

      if( $oneline ) {
         my $ret = "{ " . join( ", ", map { "$keys[$_] => $values[$_]" } ( 0 .. $#keys ) ) . " }";
         return $ret if length $ret < $COLS;
      }

      my $keylen = length _longest @keys;

      my $firstkey = shift @keys;
      return $leader . "{ " . 
             join( ",\n$leader2  ", sprintf( '%-*s => %s', $keylen, $firstkey, _repr( $v->{$firstkey} ) ),
                                    map { sprintf( '%-*s => %s', $keylen, $_, _repr( $v->{$_} ) ) } @keys )
             . " }";
   }
   else {
      return "(Cannot represent ref ".(ref $v).")";
   }
}

sub read
{
   my $self = shift;

   my $term = $self->{term} ||= Term::ReadLine->new("perlsh");

   return $term->readline( "eval: " );
}

sub print
{
   my $self = shift;
   print @_;
}

sub run
{
   my $self = ref $_[0] ? shift : shift->new;

   my $lp = Lexical::Persistence->new();

   while ( defined( my $line = $self->read ) ) {
      # Append a linefeed in case of trailing comment
      my $sub = $lp->compile( "$line\n" );
      if( !defined $sub ) {
         $self->print( "Compile error: $@\n" );
         next;
      }

      my $result = eval { $lp->call( $sub ) };

      if( $@ ) {
         $self->print( "ERR: $@\n" );
         next;
      }

      $self->print( _repr( $result ) . "\n\n" );
   }

   $self->print( "\n" ); # Final linefeed
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
