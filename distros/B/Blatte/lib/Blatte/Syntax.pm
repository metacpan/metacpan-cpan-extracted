use strict;

package Blatte::Syntax;

sub transform {
  my($obj, $column) = @_;
  return $obj unless ref($obj);
  $obj->transform($column);
}

sub make_sub {
  my($params, $exprs, $column) = @_;

  my @positional;
  my @named;
  my $rest;

  foreach my $param (@$params) {
    if ($param->isa('Blatte::Syntax::Param::Positional')) {
      push(@positional, $param->name());
    } elsif ($param->isa('Blatte::Syntax::Param::Named')) {
      push(@named, $param->name());
    } elsif ($param->isa('Blatte::Syntax::Param::Rest')) {
      $rest = $param->name();
    }
  }

  my $indent = (' ' x $column);

  my $result = "sub {\n";
  $result .= sprintf("%s  my \$_named = shift;\n", $indent);
  if (@positional) {
    $result .= sprintf("%s  my(%s) = map {\n",
                       $indent,
                       join(sprintf(",\n%s     ", $indent),
                            map { sprintf('$%s', $_) } @positional));
    $result .= sprintf("%s    &Blatte::unwrapws(\$_);\n",
                       $indent);
    $result .= sprintf("%s  } splice(\@_, 0, %d);\n",
                       $indent,
                       scalar(@positional));
  }
  foreach my $named (@named) {
    $result .= sprintf("%s  my \$%s = \$_named->{%s};\n",
                       $indent, $named, $named);
  }
  if (defined($rest)) {
    $result .= sprintf("%s  my \$%s = [\@_];\n", $indent, $rest);
  }
  $result .= sprintf("%s  %s;\n",
                     $indent,
                     join(sprintf(";\n%s  ", $indent),
                          map { &Blatte::Syntax::transform($_, $column + 2) } @$exprs));
  $result .= sprintf("%s}", $indent);

  $result;
}

############################################################

package Blatte::Syntax::List;

sub new {
  my $type = shift;
  bless [@_], $type;
}

sub transform {
  my($self, $column) = @_;

  return '[]' unless @$self;

  my @exprs;
  my @assignments;

  foreach my $subexpr (@$self) {
    if (UNIVERSAL::isa($subexpr, 'Blatte::Syntax::Assignment')) {
      push(@assignments, $subexpr);
    } else {
      push(@exprs, $subexpr);
    }
  }

  my $first = shift(@exprs);

  my $indent = (' ' x $column);
  my $result = "do {\n";
  $result .= sprintf("%s  my \$_first = %s;\n",
                     $indent,
                     &Blatte::Syntax::transform($first, $column + 15));
  $result .= sprintf("%s  my \@_rest = (%s);\n",
                     $indent,
                     join(sprintf(",\n%s               ", $indent),
                          map {
                            my $result =
                                sprintf("&Blatte::wrapws('%s',\n",
                                        &Blatte::wsof($_));
                            $result .=
                                sprintf("%s%s%s%s)",
                                        $indent,
                                        (' ' x 15),
                                        (' ' x 16),
                                        &Blatte::Syntax::transform($_,
                                                               $column + 31));
                            $result;
                          } @exprs));
  $result .= sprintf("%s  if (ref(\$_first) eq 'CODE') {\n", $indent);
  $result .= sprintf("%s    &\$_first({%s}",
                     $indent,
                     join(sprintf(",\n%s              ", $indent),
                          map {
                            sprintf('%s => %s',
                                    $_->name(),
                                    &Blatte::Syntax::transform($_->expr(),
                                                               $column + 16));
                          } @assignments));
  if (@exprs) {
    $result .= sprintf(",\n%s             &Blatte::unwrapws(\$_rest[0])",
                       $indent);
    if (@exprs > 1) {
      $result .= sprintf(",\n%s             \@_rest[1 .. \$#_rest]",
                         $indent);
    }
  }
  $result .= ");\n";
  $result .= sprintf("%s  } else {\n", $indent);
  $result .= sprintf("%s    [\$_first, \@_rest];\n", $indent);
  $result .= sprintf("%s  }\n", $indent);
  $result .= sprintf("%s}", $indent);

  $result;
}

############################################################

package Blatte::Syntax::Assignment;

sub new {
  my($type, $name, $expr) = @_;
  bless [$name, $expr], $type;
}

sub name { $_[0]->[0] }
sub expr { $_[0]->[1] }

############################################################

package Blatte::Syntax::VarRef;

sub new {
  my($type, $name) = @_;
  bless \$name, $type;
}

sub name { $ {$_[0]} }

sub transform {
  my($self, $column) = @_;
  sprintf('$%s', $self->name());
}

############################################################

package Blatte::Syntax::Literal;

sub new {
  my($type, $str) = @_;
  bless \$str, $type;
}

sub str { $ {$_[0]} }

sub transform {
  my($self, $column) = @_;
  my $str = $self->str();
  $str =~ s/([\\\'])/\\$1/g;
  sprintf("'%s'", $str);
}

############################################################

package Blatte::Syntax::DefineVar;

sub new {
  my($type, $name, $expr) = @_;
  bless [$name, $expr], $type;
}

sub name { $_[0]->[0] }
sub expr { $_[0]->[1] }

sub transform {
  my($self, $column) = @_;

  my $indent = (' ' x $column);

  my $result = "do {\n";
  $result .= sprintf("%s  use vars '\$%s';\n", $indent, $self->name());
  $result .= sprintf("%s  \$%s = %s;\n",
                     $indent,
                     $self->name(),
                     &Blatte::Syntax::transform($self->expr(), $column + 4));
  $result .= sprintf("%s  [];\n", $indent);
  $result .= sprintf("%s}", $indent);

  $result;
}

############################################################

package Blatte::Syntax::DefineFn;

sub new {
  my($type, $name, $params, $exprs) = @_;
  bless [$name, $params, $exprs], $type;
}

sub name   { $_[0]->[0] }
sub params { $_[0]->[1] }
sub exprs  { $_[0]->[2] }

sub transform {
  my($self, $column) = @_;

  my $indent = (' ' x $column);

  my $result = "do {\n";
  $result .= sprintf("%s  use vars '\$%s';\n", $indent, $self->name());
  $result .= sprintf("%s  \$%s = %s;\n",
                     $indent,
                     $self->name(),
                     &Blatte::Syntax::make_sub($self->params(),
                                               $self->exprs(),
                                               $column + 4));
  $result .= sprintf("%s  [];\n", $indent);
  $result .= sprintf("%s}", $indent);

  $result;
}

############################################################

package Blatte::Syntax::SetVar;

sub new {
  my($type, $name, $expr) = @_;
  bless [$name, $expr], $type;
}

sub name { $_[0]->[0] }
sub expr { $_[0]->[1] }

sub transform {
  my($self, $column) = @_;

  sprintf("\$%s = %s",
          $self->name(),
          &Blatte::Syntax::transform($self->expr(), $column + 2));
}

############################################################

package Blatte::Syntax::Lambda;

sub new {
  my($type, $params, $exprs) = @_;
  bless [$params, $exprs], $type;
}

sub params { $_[0]->[0] }
sub exprs  { $_[0]->[1] }

sub transform {
  my($self, $column) = @_;
  &Blatte::Syntax::make_sub($self->params(), $self->exprs(), $column);
}

############################################################

package Blatte::Syntax::Param::Positional;

sub new {
  my($type, $name) = @_;
  bless \$name, $type;
}

sub name {
  $ {$_[0]};
}

############################################################

package Blatte::Syntax::Param::Named;

sub new {
  my($type, $name) = @_;
  bless \$name, $type;
}

sub name {
  $ {$_[0]};
}

############################################################

package Blatte::Syntax::Param::Rest;

sub new {
  my($type, $name) = @_;
  bless \$name, $type;
}

sub name {
  $ {$_[0]};
}

############################################################

package Blatte::Syntax::Let;

sub new {
  my($type, $clauses, $exprs) = @_;
  bless [$clauses, $exprs], $type;
}

sub clauses { @{$_[0]->[0]} }
sub exprs   { @{$_[0]->[1]} }

sub transform {
  my($self, $column) = @_;

  my $indent = (' ' x $column);

  my $result = "do {\n";
  $result .= sprintf("%s  my(%s) =\n",
                     $indent,
                     join(sprintf(",\n%s     ", $indent),
                          map {
                            sprintf('$%s', $_->name());
                          } $self->clauses()));
  $result .= sprintf("%s    (%s);\n",
                     $indent,
                     join(sprintf(",\n%s     ", $indent),
                          map {
                            sprintf('(%s)',
                                    &Blatte::Syntax::transform($_->expr(),
                                                               $column + 6));
                          } $self->clauses()));
  $result .= sprintf("%s  %s;\n",
                     $indent,
                     join(sprintf(";\n%s  ", $indent),
                          map {
                            &Blatte::Syntax::transform($_, $column + 2);
                          } $self->exprs()));
  $result .= sprintf("%s}", $indent);

  $result;
}

############################################################

package Blatte::Syntax::LetStar;

sub new {
  my($type, $clauses, $exprs) = @_;
  bless [$clauses, $exprs], $type;
}

sub clauses { @{$_[0]->[0]} }
sub exprs   { @{$_[0]->[1]} }

sub transform {
  my($self, $column) = @_;

  my $indent = (' ' x $column);

  my $result = "do {\n";
  $result .= sprintf("%s  %s;\n",
                     $indent,
                     join(sprintf(";\n%s  ", $indent),
                          map {
                            sprintf('my $%s = %s;',
                                    $_->name(),
                                    &Blatte::Syntax::transform($_->expr(),
                                                               $column + 7));
                          } $self->clauses()));
  $result .= sprintf("%s  %s;\n",
                     $indent,
                     join(sprintf(";\n%s  ", $indent),
                          map {
                            &Blatte::Syntax::transform($_, $column + 2);
                          } $self->exprs()));
  $result .= sprintf("%s}", $indent);

  $result;
}

############################################################

package Blatte::Syntax::Letrec;

sub new {
  my($type, $clauses, $exprs) = @_;
  bless [$clauses, $exprs], $type;
}

sub clauses { @{$_[0]->[0]} }
sub exprs   { @{$_[0]->[1]} }

sub transform {
  my($self, $column) = @_;

  my $indent = (' ' x $column);

  my $result = "do {\n";
  $result .= sprintf("%s  my(%s);\n",
                     $indent,
                     join(sprintf(",\n%s     ", $indent),
                          map {
                            sprintf('$%s', $_->name());
                          } $self->clauses()));
  $result .= sprintf("%s  %s;\n",
                     $indent,
                     join(sprintf(";\n%s  ", $indent),
                          map {
                            sprintf('$%s = %s;',
                                    $_->name(),
                                    &Blatte::Syntax::transform($_->expr(),
                                                               $column + 4));
                          } $self->clauses()));
  $result .= sprintf("%s  %s;\n",
                     $indent,
                     join(sprintf(";\n%s  ", $indent),
                          map {
                            &Blatte::Syntax::transform($_, $column + 2);
                          } $self->exprs()));
  $result .= sprintf("%s}", $indent);

  $result;
}

############################################################

package Blatte::Syntax::LetClause;

sub new {
  my($type, $name, $expr) = @_;
  bless [$name, $expr], $type;
}

sub name { $_[0]->[0] }
sub expr { $_[0]->[1] }

############################################################

package Blatte::Syntax::If;

sub new {
  my($type, $test, $consequent, @alternates) = @_;
  bless [$test, $consequent, @alternates], $type;
}

sub test       { $_[0]->[0] }
sub consequent { $_[0]->[1] }
sub alternates { @{$_[0]}[2 .. $#{$_[0]}] }

sub transform {
  my($self, $column) = @_;

  my $indent = (' ' x $column);

  my $result = "do {\n";
  $result .= sprintf("%s  if (&Blatte::true(%s)) {\n",
                     $indent,
                     &Blatte::Syntax::transform($self->test(),
                                                $column + 20));
  $result .= sprintf("%s    %s;\n",
                     $indent,
                     &Blatte::Syntax::transform($self->consequent(),
                                                $column + 4));
  $result .= sprintf("%s  } else {\n",
                     $indent);
  $result .= sprintf("%s    %s;\n",
                     $indent,
                     ($self->alternates() ?
                      join(sprintf(";\n%s    ", $indent),
                           map {
                             &Blatte::Syntax::transform($_, $column + 4);
                           } $self->alternates()) :
                      'undef'));
  $result .= sprintf("%s  }\n", $indent);
  $result .= sprintf("%s}", $indent);

  $result;
}

############################################################

package Blatte::Syntax::Cond;

sub new {
  my $type = shift;
  bless [@_], $type;
}

sub clauses { @{$_[0]} }

sub transform {
  my($self, $column) = @_;

  my $indent = (' ' x $column);

  my $result = "do {\n";

  my @clauses = $self->clauses();
  my $first_clause = shift(@clauses);

  $result .= sprintf("%s  if (&Blatte::true(%s)) {\n",
                     $indent,
                     &Blatte::Syntax::transform($first_clause->test(),
                                                $column + 20));
  $result .= sprintf("%s    %s;\n",
                     $indent,
                     ($first_clause->actions() ?
                      join(sprintf(";\n%s    ", $indent),
                           $indent,
                           map {
                             &Blatte::Syntax::transform($_, $column + 4);
                           } $first_clause->actions()) :
                      'undef'));
  foreach my $clause (@clauses) {
    $result .= sprintf("%s  } elsif (&Blatte::true(%s)) {\n",
                       $indent,
                       &Blatte::Syntax::transform($clause->test(),
                                                  $column + 25));
    $result .= sprintf("%s    %s;\n",
                       $indent,
                       ($clause->actions() ?
                        join(sprintf(";\n%s    ", $indent),
                             $indent,
                             map {
                               &Blatte::Syntax::transform($_, $column + 4);
                             } $clause->actions()) :
                        'undef'));
  }
  $result .= sprintf("%s  }\n", $indent);
  $result .= sprintf("%s}", $indent);

  $result;
}

############################################################

package Blatte::Syntax::CondClause;

sub new {
  my($type, $test, @actions) = @_;
  bless [$test, @actions], $type;
}

sub test { $_[0]->[0] }
sub actions { @{$_[0]}[1 .. $#{$_[0]}] }

############################################################

package Blatte::Syntax::While;

sub new {
  my($type, $test, @exprs) = @_;
  bless [$test, @exprs], $type;
}

sub test  { $_[0]->[0] }
sub exprs { @{$_[0]}[1 .. $#{$_[0]}] }

sub transform {
  my($self, $column) = @_;

  my $indent = (' ' x $column);

  my $result = "do {\n";
  $result .= sprintf("%s  while (&Blatte::true(%s)) {\n",
                     $indent,
                     &Blatte::Syntax::transform($self->test(), $column + 23));
  $result .= sprintf("%s    %s;\n",
                     $indent,
                     join(sprintf(";\n%s    ",
                                  map {
                                    &Blatte::Syntax::transform($_,
                                                               $column + 4);
                                  } $self->exprs())));
  $result .= sprintf("%s  }\n", $indent);
  $result .= sprintf("%s}", $indent);

  $result;
}

############################################################

package Blatte::Syntax::And;

sub new {
  my $type = shift;
  bless [@_], $type;
}

sub exprs { @{$_[0]} }

sub transform {
  my($self, $column) = @_;

  my $indent = (' ' x $column);

  sprintf('(%s)',
          join(sprintf("\n%s && ", $indent),
               map {
                 sprintf('&Blatte::true(%s)',
                         &Blatte::Syntax::transform($_, $column + 18));
               } $self->exprs()));
}

############################################################

package Blatte::Syntax::Or;

sub new {
  my $type = shift;
  bless [@_], $type;
}

sub exprs { @{$_[0]} }

sub transform {
  my($self, $column) = @_;

  my $indent = (' ' x $column);

  sprintf('(%s)',
          join(sprintf("\n%s || ", $indent),
               map {
                 sprintf('&Blatte::true(%s)',
                         &Blatte::Syntax::transform($_, $column + 18));
               } $self->exprs()));
}

1;

__END__

=head1 NAME

Blatte::Syntax - parse tree structure for Blatte documents

=head1 SYNOPSIS

  package MySyntax;

  use Blatte::Syntax;

  @ISA = qw(Blatte::Syntax);

  sub transform {
    my($self, $column) = @_;

    ...return a string containing a Perl expression...
  }

  ...

  use Blatte::Parser;
  use MySyntax;

  $parser = new Blatte::Parser();
  $parser->add_special_form(\&my_special_form);

  sub my_special_form {
    my($self, $input_arg) = @_;
    my $input = $input_arg;
    if (ref($input)) {
      $input = $$input_arg;
    }

    ...examine $input...
    ...return undef if no match...
    ...else consume matching text from beginning of $input...

    if (ref($input_arg)) {
      $$input_arg = $input;
    }

    return new MySyntax(...);
  }

=head1 DESCRIPTION

Blatte::Syntax is the base class of a family of objects used to
represent a Blatte parse tree.  A tree of Blatte::Syntax objects is
returned by C<expr()> and other parsing methods of Blatte::Parser.
All Blatte::Syntax objects have a C<transform()> method that converts
them to strings of Perl code.

=head1 AUTHOR

Bob Glickstein <bobg@zanshin.com>.

Visit the Blatte website, <http://www.blatte.org/>.

=head1 LICENSE

Copyright 2001 Bob Glickstein.  All rights reserved.

Blatte is distributed under the terms of the GNU General Public
License, version 2.  See the file LICENSE that accompanies the Blatte
distribution.

=head1 SEE ALSO

L<Blatte::Parser(3)>.
