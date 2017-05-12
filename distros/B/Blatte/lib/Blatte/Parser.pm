package Blatte::Parser;

use strict;

use Blatte;
use Blatte::Syntax;
use Blatte::Ws;

use vars qw($identifier_regex);

$identifier_regex = qr/[A-Za-z][A-Za-z0-9_]*(?![A-Za-z0-9_])/;

sub new {
  my $type = shift;
  bless { special_forms => [\&define_expr,
                            \&set_expr,
                            \&lambda_expr,
                            \&any_let_expr,
                            \&if_expr,
                            \&cond_expr,
                            \&while_expr,
                            \&and_expr,
                            \&or_expr] }, $type;
}

sub add_special_form {
  my $self = shift;
  push(@{$self->{special_forms}}, @_);
}

sub parse {
  my($self, $input_arg) = @_;
  my $expr = $self->expr($input_arg);
  return undef unless defined($expr);
  sprintf("&Blatte::wrapws('%s',\n                %s)",
          &Blatte::wsof($expr), $expr->transform(16));
}

sub expr {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input;
  }

  my $ws = &consume_whitespace(\$input);

  return undef if ($input eq '');

  my $syntax;

  if (substr($input, 0, 1) eq '{') {
    $input = substr($input, 1);

    $syntax = $self->special_form(\$input);
    $syntax = new Blatte::Syntax::List($self->list_subexprs(\$input))
        unless defined $syntax;

    &consume_whitespace(\$input);
    return undef if ($input eq '');
    return undef if (substr($input, 0, 1) ne '}');
    $input = substr($input, 1);
  } elsif ($input =~ /^\\\"([^\\]+|\\[^\"])*\\\"/g) {
    my $str = substr($input, 0, pos($input));
    $input = substr($input, pos($input));
    $str = substr($str, 2, length($str) - 4);
    $str =~ s/\\(.)/$1/g;
    $syntax = new Blatte::Syntax::Literal($str);
  } elsif ($input =~ /^\\($identifier_regex)/go) {
    my $name = $1;
    $input = substr($input, pos($input));
    $syntax = new Blatte::Syntax::VarRef($name);
  } elsif ($input =~ /^([^\\{}\s]+|\\[\\{}])+/g) {
    my $atom = substr($input, 0, pos($input));
    $input = substr($input, pos($input));
    $atom =~ s/\\(.)/$1/g;
    $syntax = new Blatte::Syntax::Literal($atom);
  } else {
    return undef;
  }

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return &Blatte::wrapws($ws, $syntax);
}

sub list_subexprs {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  my @subexprs;
  while (1) {
    my $ws = &consume_whitespace(\$input);
    if ($input =~ /^\\($identifier_regex)=/go) {
      my $name = $1;
      $input = substr($input, pos($input));

      my $expr = $self->expr(\$input);
      return undef unless defined($expr);

      push(@subexprs,
           new Blatte::Syntax::Assignment($name, &Blatte::unwrapws($expr)));
    } else {
      $input = ($ws . $input);
      my $expr = $self->expr(\$input);
      last unless defined($expr);
      push(@subexprs, $expr);
    }
  }

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return @subexprs;
}

sub special_form {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  my $syntax;
  foreach my $formfn (@{$self->{special_forms}}) {
    $syntax = &$formfn($self, \$input);
    last if defined($syntax);
  }

  return undef unless defined($syntax);

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return $syntax;
}

sub define_expr {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input;
  }

  my $syntax = $self->define_var_expr(\$input);
  $syntax = $self->define_fn_expr(\$input) unless defined($syntax);

  return undef unless defined($syntax);

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return $syntax;
}

sub define_var_expr {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  &consume_whitespace(\$input);
  return undef unless ($input =~ /^\\define(?![A-Za-z0-9_])/);
  $input = substr($input, 7);

  &consume_whitespace(\$input);
  return undef unless ($input =~ /^\\($identifier_regex)/go);
  my $name = $1;
  $input = substr($input, pos($input));

  my $expr = $self->expr(\$input);
  return undef unless defined($expr);

  my $syntax = new Blatte::Syntax::DefineVar($name, $expr);

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return $syntax;
}

sub define_fn_expr {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  &consume_whitespace(\$input);
  return undef unless ($input =~ /^\\define(?![A-Za-z0-9_])/);
  $input = substr($input, 7);

  &consume_whitespace(\$input);
  if (($input eq '') || (substr($input, 0, 1) ne '{')) {
    return undef;
  }
  $input = substr($input, 1);

  &consume_whitespace(\$input);
  return undef unless ($input =~ /^\\($identifier_regex)/go);
  my $name = $1;
  $input = substr($input, pos($input));

  my @params = $self->params(\$input);

  &consume_whitespace(\$input);
  if (($input eq '') || (substr($input, 0, 1) ne '}')) {
    return undef;
  }
  $input = substr($input, 1);

  my @exprs = $self->exprs(\$input);

  my $syntax = new Blatte::Syntax::DefineFn($name, \@params, \@exprs);

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return $syntax;
}

sub set_expr {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  &consume_whitespace(\$input);
  return undef unless ($input =~ /^\\set!(?![A-Za-z0-9_])/);
  $input = substr($input, 5);

  &consume_whitespace(\$input);
  return undef unless ($input =~ /^\\($identifier_regex)/go);
  my $name = $1;
  $input = substr($input, pos($input));

  my $expr = $self->expr(\$input);
  return undef unless defined($expr);

  my $syntax = new Blatte::Syntax::SetVar($name, $expr);

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return $syntax;
}

sub lambda_expr {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  &consume_whitespace(\$input);
  return undef unless ($input =~ /^\\lambda(?![A-Za-z0-9_])/);

  $input = substr($input, 7);

  &consume_whitespace(\$input);
  if (($input eq '') || (substr($input, 0, 1) ne '{')) {
    return undef;
  }
  $input = substr($input, 1);

  my @params = $self->params(\$input);

  &consume_whitespace(\$input);
  return undef if ($input eq '');
  return undef if (substr($input, 0, 1) ne '}');
  $input = substr($input, 1);

  my @exprs;
  while (defined(my $expr = $self->expr(\$input))) {
    push(@exprs, $expr);
  }

  my $syntax = new Blatte::Syntax::Lambda(\@params, \@exprs);

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return $syntax;
}

sub params {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  my @params;
  while (1) {
    &consume_whitespace(\$input);
    if ($input =~ /^\\($identifier_regex)/g) {
      my $name = $1;
      $input = substr($input, pos($input));
      push(@params, new Blatte::Syntax::Param::Positional($name));
    } elsif ($input =~ /^\\=($identifier_regex)/g) {
      my $name = $1;
      $input = substr($input, pos($input));
      push(@params, new Blatte::Syntax::Param::Named($name));
    } elsif ($input =~ /^\\&($identifier_regex)/g) {
      my $name = $1;
      $input = substr($input, pos($input));
      push(@params, new Blatte::Syntax::Param::Rest($name));
    } else {
      last;
    }
  }

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return @params;
}

sub any_let_expr {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  &consume_whitespace(\$input);
  return undef unless ($input =~ /^\\(letrec|let\*?)(?![A-Za-z0-9_])/g);
  my $keyword = $1;
  $input = substr($input, pos($input));

  &consume_whitespace(\$input);
  return undef if ($input eq '');
  return undef if (substr($input, 0, 1) ne '{');
  $input = substr($input, 1);

  my @clauses = $self->let_clauses(\$input);
  return undef unless @clauses;

  &consume_whitespace(\$input);
  return undef if ($input eq '');
  return undef if (substr($input, 0, 1) ne '}');
  $input = substr($input, 1);

  my @exprs = $self->exprs(\$input);

  my $syntax;
  if ($keyword eq 'let') {
    $syntax = new Blatte::Syntax::Let(\@clauses, \@exprs);
  } elsif ($keyword eq 'let*') {
    $syntax = new Blatte::Syntax::LetStar(\@clauses, \@exprs);
  } else {                      # letrec
    $syntax = new Blatte::Syntax::Letrec(\@clauses, \@exprs);
  }

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return $syntax;
}

sub let_clauses {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  my @clauses;
  while (1) {
    &consume_whitespace(\$input);
    last if ($input eq '');
    last if (substr($input, 0, 1) ne '{');
    $input = substr($input, 1);

    &consume_whitespace(\$input);
    return undef unless ($input =~ /^\\($identifier_regex)/go);
    my $name = $1;
    $input = substr($input, pos($input));

    my $expr = $self->expr(\$input);
    return undef unless defined($expr);

    &consume_whitespace(\$input);
    return undef if ($input eq '');
    return undef if (substr($input, 0, 1) ne '}');

    $input = substr($input, 1);

    push(@clauses, new Blatte::Syntax::LetClause($name, $expr));
  }

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return @clauses;
}

sub if_expr {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  &consume_whitespace(\$input);
  return undef unless ($input =~ /^\\if(?![A-Za-z0-9_])/);
  $input = substr($input, 3);

  my $test = $self->expr(\$input);
  return undef unless defined($test);

  my $then = $self->expr(\$input);
  return undef unless defined($then);

  my @else = $self->exprs(\$input);

  my $syntax = new Blatte::Syntax::If($test, $then, @else);

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return $syntax;
}

sub cond_expr {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  &consume_whitespace(\$input);
  return undef unless ($input =~ /^\\cond(?![A-Za-z0-9_])/);
  $input = substr($input, 5);

  my @clauses;
  while (1) {
    &consume_whitespace(\$input);
    last if ($input eq '');
    last if (substr($input, 0, 1) ne '{');
    $input = substr($input, 1);

    my $test = $self->expr(\$input);
    return undef unless defined($test);

    my @actions = $self->exprs(\$input);

    &consume_whitespace(\$input);
    return undef if ($input eq '');
    return undef if (substr($input, 0, 1) ne '}');
    $input = substr($input, 1);

    push(@clauses, new Blatte::Syntax::CondClause($test, @actions));
  }

  my $syntax = new Blatte::Syntax::Cond(@clauses);

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return $syntax;
}

sub while_expr {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  &consume_whitespace(\$input);
  return undef unless ($input =~ /^\\while(?![A-Za-z0-9_])/);
  $input = substr($input, 6);

  my $test = $self->expr(\$input);
  return undef unless defined($test);

  my @body = $self->exprs(\$input);

  my $syntax = new Blatte::Syntax::While($test, @body);

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return $syntax;
}

sub and_expr {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  &consume_whitespace(\$input);
  return undef unless ($input =~ /^\\and(?![A-Za-z0-9_])/);
  $input = substr($input, 4);

  my @exprs = $self->exprs(\$input);
  return undef unless @exprs;

  my $syntax = new Blatte::Syntax::And(@exprs);

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return $syntax;
}

sub or_expr {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  &consume_whitespace(\$input);
  return undef unless ($input =~ /^\\or(?![A-Za-z0-9_])/);
  $input = substr($input, 4);

  my @exprs = $self->exprs(\$input);
  return undef unless @exprs;

  my $syntax = new Blatte::Syntax::Or(@exprs);

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return $syntax;
}

sub exprs {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  my @exprs;
  while (1) {
    my $expr = $self->expr(\$input);
    last unless defined($expr);
    push(@exprs, $expr);
  }

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return @exprs;
}

sub consume_whitespace {
  my $ref = shift;
  my $str = $$ref;
  my $ws = '';

  while (1) {
    if ($str =~ /^\s+/g) {
      $ws .= substr($str, 0, pos($str));
      $str = substr($str, pos($str));
    } elsif ($str =~ /^\\;.*/g) {
      $str = substr($str, pos($str));
    } elsif ($str =~ /^\\\//) {
      $ws = '';
      $str = substr($str, 2);
    } else {
      $$ref = $str;
      return $ws;
    }
  }
}

sub eof {
  my($self, $input_arg) = @_;

  my $input = $input_arg;
  if (ref($input)) {
    $input = $$input_arg;
  }

  &consume_whitespace(\$input);
  return undef unless ($input eq '');

  if (ref($input_arg)) {
    $$input_arg = $input;
  }

  return 1;
}

1;

__END__

=head1 NAME

Blatte::Parser - parser for Blatte syntax

=head1 SYNOPSIS

  use Blatte::Parser;

  $parser = new Blatte::Parser();

  $perl_expr = $parser->parse(INPUT);

    or

  $parsed_expr = $parser->expr(INPUT);
  if (defined($parsed_expr)) {
    $perl_expr = $parsed_expr->transform();
  }

=head1 DESCRIPTION

A parser for turning written Blatte expressions into their Perl
equivalents or into Blatte's syntax-tree representation.

=head1 METHODS

=over 4

=item $parser->parse(INPUT)

Parses the first Blatte expression in INPUT and returns the
corresponding Perl string, or undef if an error occurred.

INPUT may be a string or a reference to a string.  If it's the latter,
then after a successful parse, the parsed expression will be removed
from the beginning of the string.

=item $parser->expr(INPUT)

Like parse(), except the result is not converted to Perl; it's left in
Blatte's internal parse-tree format, which uses the Blatte::Syntax
family of objects.

=item $parser->eof(INPUT)

Tests INPUT for end-of-file.  Leading whitespace is removed from INPUT
with consume_whitespace and, if nothing remains, true is returned,
else undef.

=back

=head1 OTHER FUNCTIONS

=over 4

=item consume_whitespace(STRING_REF)

Given a reference to a string containing Blatte code, this function
modifies the string to remove all leading whitespace, comments, and
forget-whitespace operators.  It discards any comments from, and
applies any forget-whitespace operators to the consumed whitespace and
returns the resulting whitespace.

This function is called internally by the parser prior to matching
each token of the input.

=back

=head1 AUTHOR

Bob Glickstein <bobg@zanshin.com>.

Visit the Blatte website, <http://www.blatte.org/>.

=head1 LICENSE

Copyright 2001 Bob Glickstein.  All rights reserved.

Blatte is distributed under the terms of the GNU General Public
License, version 2.  See the file LICENSE that accompanies the Blatte
distribution.

=head1 SEE ALSO

L<Blatte(3)>, L<Blatte::Compiler(3)>, L<Blatte::Syntax(3)>.
