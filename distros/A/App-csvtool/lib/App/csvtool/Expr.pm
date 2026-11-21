#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2026 -- leonerd@leonerd.org.uk

package App::csvtool::Expr 0.05;

use v5.26;
use warnings;
use experimental 'signatures';

=head1 NAME

C<App::csvtool::Expr> - F<csvtool> commands that evaluate expressions

=head1 EXPRESSIONS

=for highlighter

Commands in this module operate on rows of data by evaluating expressions
given as part of the command's arguments. Expressions are built up from the
following forms:

=over 4

=item * Numerical constants

Integers (e.g. C<123>) or decimal floats (e.g. C<12.345>)

=item * Field references

C<F[nnn]>, where the C<nnn> part gives the field index. Note that fields are
indexed from 1 onwards.

=item * Parenthesized expressions

Any expression may be surrounded by parens (C<( expr... )>) to override
precedence order

=item * Numerical binary operators

Mathematical operators (C<+ - * />) in their usual precedence order

=item * Numerical comparison operators

Numerical comparisons (C<< == != < <= >= > >>)

=item * Logical binary operators

Operators that compare the truth of expressions (C<&& ||>)

=back

=cut

package App::csvtool::Expr::_Parser {
   # This is a lot of special-case logic that is only loosely built on top
   # of Parser::MGC; we're mostly using Parser::MGC as a tokenising lexer
   # to base our own rule-based grammar parser on top of.
   # However, it would be hard to migrate the underlying logic of this parser
   # into Parser::MGC itself and manage to keep it sufficiently generic and
   # powerful at the same time. We don't really want to turn it into a full
   # grammar parser engine.
   use base qw( Parser::MGC );

   my @binops = (
      [qw( * / )],
      [qw( + - )],
      [qw( == != < <= >= > )],
      [qw( && || )],
   );

   my $op_pattern = join "|",
      ( map { join "|", map { quotemeta } @$_ } @binops ),
      ( map { quotemeta } qw[ ( ) ] );
   $op_pattern = qr/$op_pattern/;

   sub _tail1 ( $x ) { [ @{$x}[1 .. $#$x] ] }

   my @rules = (
      # (TERM) reduces to just TERM
      [ '(', 'term', ')' ] => sub ( $, $term, $ ) { $term },
      # binary operators in precedence order
      ( map {
            [ 'term', $_, 'term' ] =>
               sub ( $lhs, $op, $rhs ) { [ term => binop => _tail1($lhs), @$op, _tail1($rhs) ] }
         } @binops ),
   );

   sub token ( $self )
   {
      return $self->any_of(
         sub ( $self ) { [ term => const => $self->token_number ] },
         sub ( $self ) { ( undef, my $index ) = $self->expect( qr/F\[(\d+)\]/ );
                         $index--; # because 1-based
                         [ term => expr => '$row->['.$index.']' ] },
         sub ( $self ) { [ $self->expect( $op_pattern ) ] },
         sub ( $self ) { $self->fail( "Expected term or operator" ) },
      );
   }

   sub parse ( $self )
   {
      my @stack = $self->token;

      while( !$self->at_eos ) {
         my $next = $self->token;

         1 while @stack and $self->try_reduce( \@stack, $next );

         push @stack, $next;
      }

      1 while @stack > 1 and $self->try_reduce( \@stack );
      my $top = pop @stack;

      !@stack and $top->[0] eq "term" or
         $self->fail( "Syntax error in expression" );

      return [ @{$top}[1..$#$top] ];
   }

   sub _matches ( $top, $match )
   {
      return 0 unless @$top == @$match;
      foreach my $i ( 0 .. $#$match ) {
         my $got = $top->[$i][0];
         my $want = $match->[$i];

         defined $got or next;

         my $ok = 0;

         if( ref $want eq "ARRAY" ) {
            $got eq $_ and $ok = 1, last for @$want;
         }
         else {
            $got eq $want and $ok = 1;
         }

         $ok or return 0;
      }

      return 1;
   }

   sub try_reduce ( $self, $stack, $next = undef )
   {
      # Reduce the entire top of the stack, unless $next is defined and the
      # addition of it might cause a higher-precedence rule to match
      my $have_partial;
      my $matchi;

      RULE: for ( my $i = 0; $i < @rules; $i += 2 ) {
         my $match = $rules[$i];
         my $len = @$match;

         if( @$stack >= $len ) {
            my @top = @{$stack}[-$len .. -1];
            $matchi = $i, last RULE
               if _matches( \@top, $match );
         }

         next RULE unless $next;

         foreach my $shortlen ( reverse 1 .. $len-1 ) {
            next unless @$stack >= $shortlen;
            my @top = ( @{$stack}[-$shortlen .. -1], $next, ( undef ) x ( $len - $shortlen - 1 ) );

            return 0
               if _matches( \@top, $match );
         }
      }

      # If we fell off this list without $matchi that means the next item
      # pushed to the stack cannot possibly ever match
      defined $matchi or
         $self->fail( "Syntax error in expression" );

      my $len = scalar @{$rules[$matchi]};
      my $reducer = $rules[$matchi + 1];
      my @top = splice @$stack, -$len, $len, ();

      push @$stack, $reducer->( @top );

      return 1;
   }
}

sub perl_code_for ( $pkg, $n )
{
   my ( $type, @args ) = @$n;

   if( $type eq "expr" ) {
      return $args[0];
   }
   if( $type eq "const" ) {
      # TODO: perlish un-qq strings but for now we know these are just numbers
      return "$args[0]";
   }
   if( $type eq "binop" ) {
      my ( $lhs, $rhs ) = map { $pkg->perl_code_for( $_ ) } @args[0, 2];
      my $op = $args[1];

      return "($lhs $op $rhs)";
   }

   die "TODO: perl code for type=$type";
}

sub compile ( $pkg, $expr )
{
   my $n = App::csvtool::Expr::_Parser->new->from_string( $expr );
   my $code = $pkg->perl_code_for( $n );

   # Silence numeric and uninitialized warnings during the filter code
   my $sub = eval <<'EOF'
      sub ( $row ) {
         no warnings qw( numeric uninitialized );
EOF
         . $code . '}' or
         die "Cannot compile filter code: $@";
   return $sub;
}

=head1 COMMANDS

=cut

package App::csvtool::extend
{

=head2 extend

   $ csvtool extend EXPR INPUT...

Appends an extra column to each row, containing the result of the evaluated
expression on that row.

=cut

   use constant COMMAND_DESC => "Evaluate an expression to append each row";

   use constant COMMAND_ARGS => (
      { name => "expression", description => "expression to calculate" },
   );

   use constant WANT_READER => 1;
   use constant WANT_OUTPUT => 1;

   sub run ( $pkg, $expr, $reader, $output )
   {
      my $EXPR = App::csvtool::Expr->compile( $expr );

      while( my $row = $reader->() ) {
         $output->( [ @$row, $EXPR->( $row ) ] );
      }
   }
}

package App::csvtool::filter
{

=head2 filter

   $ csvtool filter EXPR INPUT...

Filter rows by the given expression, which is evaluated for each row. Rows for
which the expression is true are emitted unchanged; rows for which it is false
are skipped.

=cut

   use constant COMMAND_DESC => "Filter rows by a given expression";

   use constant COMMAND_ARGS => (
      { name => "expression", description => "expression to select rows" },
   );

   use constant WANT_READER => 1;
   use constant WANT_OUTPUT => 1;

   sub run ( $pkg, $expr, $reader, $output )
   {
      my $FILTER = App::csvtool::Expr->compile( $expr );

      while( my $row = $reader->() ) {
         $output->( $row ) if $FILTER->( $row );
      }
   }
}

=head1 TODO

=over 4

=item *

Define many more operators. Functions. String operations. Allsorts...

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
