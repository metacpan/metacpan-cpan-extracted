package Data::CSel;

our $DATE = '2019-07-26'; # DATE
our $VERSION = '0.121'; # VERSION

use 5.020000;
use strict;
use warnings;

use Code::Includable::Tree::NodeMethods;
#use List::Util qw(first);
use Scalar::Util qw(blessed refaddr looks_like_number);

use Exporter qw(import);
our @EXPORT_OK = qw(
                       csel
                       parse_csel
               );

our $_i1;

our $RE =
    qr{
          (?&SELECTORS) (?{ $_ = $^R->[1] })

          (?(DEFINE)
              (?<SELECTORS>
                  (?{ [$^R, []] })
                  (?&SELECTOR) # [[$^R, []], $selector]
                  (?{ [$^R->[0][0], [$^R->[1]]] })
                  (?:
                      \s*,\s*
                      (?&SELECTOR)
                      (?{
                          push @{$^R->[0][1]}, $^R->[1];
                          $^R->[0];
                      })
                  )*
                  \s*
              )

              (?<SELECTOR>
                  (?{ [$^R, []] })
                  (?&SIMPLE_SELECTOR) # [[$^R, []], $simple_selector]
                  (?{ [$^R->[0][0], [$^R->[1]]] })
                  (?:
                      (\s*>\s*|\s*\+\s*|\s*~\s*|\s+)
                      (?{
                          my $comb = $^N;
                          $comb =~ s/^\s+//; $comb =~ s/\s+$//;
                          $comb = " " if $comb eq '';
                          push @{$^R->[1]}, {combinator=>$comb};
                          $^R;
                      })

                      (?&SIMPLE_SELECTOR)
                      (?{
                          push @{$^R->[0][1]}, $^R->[1];
                          $^R->[0];
                      })
                  )*
              )

              (?<SIMPLE_SELECTOR>
                  (?:
                      (?:
                          # type selector + optional filters
                          ((?&TYPE_NAME))
                          (?{ [$^R, {type=>$^N}] })
                          (?:
                              (?&FILTER) # [[$^R, $simple_selector], $filter]
                              (?{
                                  push @{ $^R->[0][1]{filters} }, $^R->[1];
                                  $^R->[0];
                              })
                              (?:
                                  \s*
                                  (?&FILTER)
                                  (?{
                                      push @{ $^R->[0][1]{filters} }, $^R->[1];
                                      $^R->[0];
                                  })
                              )*
                          )?
                      )
                  |
                      (?:
                          # optional type selector + one or more filters
                          ((?&TYPE_NAME))?
                          (?{
                              # XXX sometimes $^N is ' '?
                              my $t = $^N // '*';
                              $t = '*' if $t eq ' ';
                              [$^R, {type=>$t}] })
                          (?&FILTER) # [[$^R, $simple_selector], $filter]
                          (?{
                              push @{ $^R->[0][1]{filters} }, $^R->[1];
                              $^R->[0];
                          })
                          (?:
                              \s*
                              (?&FILTER)
                              (?{
                                  push @{ $^R->[0][1]{filters} }, $^R->[1];
                                  $^R->[0];
                              })
                          )*
                      )
                  )
              )

              (?<TYPE_NAME>
                  [A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z0-9_]+)*|\*
              )

              (?<FILTER>
                  (?{ [$^R, {}] })
                  (
                      (?&ATTR_SELECTOR) # [[$^R0, {}], [$attr, $op, $val]]
                      (?{
                          $^R->[0][1]{type}  = 'attr_selector';
                          $^R->[0][1]{attr}  = $^R->[1][0];
                          $^R->[0][1]{op}    = $^R->[1][1] if defined $^R->[1][1];
                          $^R->[0][1]{value} = $^R->[1][2] if @{ $^R->[1] } > 2;
                          $^R->[0];
                      })
                  |
                      \.((?&TYPE_NAME))
                      (?{
                          $^R->[1]{type}  = 'class_selector';
                          $^R->[1]{class} = $^N;
                          $^R;
                      })
                  |
                      \#(\w+)
                      (?{
                          $^R->[1]{type} = 'id_selector';
                          $^R->[1]{id}   = $^N;
                          $^R;
                      })
                  |
                      (?&PSEUDOCLASS) # [[$^R, {}], [$pseudoclass, \@args]]
                      (?{
                          $^R->[0][1]{type}         = 'pseudoclass';
                          $^R->[0][1]{pseudoclass}  = $^R->[1][0];
                          $^R->[0][1]{args}         = $^R->[1][1] if @{ $^R->[1] } > 1;
                          $^R->[0];
                      })
                  )
              )

              (?<ATTR_SELECTOR>
                  \[\s*
                  (?{ [$^R, []] }) # [$^R, [$subjects, $op, $literal]]
                  (?&ATTR_SUBJECTS) # [[$^R, [{name=>$name, args=>$args}, ...]]
                  (?{
                      #use Data::Dmp; say "D:setting subjects: ", dmp $^R->[1];
                      push @{ $^R->[0][1] }, $^R->[1];
                      $^R->[0];
                  })

                  (?:
                      (
                          \s*(?:=~|!~)\s* |
                          \s*(?:!=|<>|>=?|<=?|==?)\s* |
                          \s++(?:eq|ne|lt|gt|le|ge)\s++ |
                          \s+(?:isnt|is)\s+
                      )
                      (?{
                          my $op = $^N;
                          $op =~ s/^\s+//; $op =~ s/\s+$//;
                          $^R->[1][1] = $op;
                          $^R;
                      })

                      (?:
                          (?&LITERAL) # [[$^R0, [$attr, $op]], $literal]
                          (?{
                              push @{ $^R->[0][1] }, $^R->[1];
                              $^R->[0];
                          })
                      |
                          (\w[^\s\]]*) # allow unquoted string
                          (?{
                              $^R->[1][2] = $^N;
                              $^R;
                          })
                      )
                  )?
                  \s*\]
              )

              (?<ATTR_NAME>
                  [A-Za-z_][A-Za-z0-9_]*
              )

              (?<ATTR_SUBJECT>
                  (?{ [$^R, []] }) # [$^R, [name, \@args]]
                  ((?&ATTR_NAME))
                  (?{
                      #say "D:pushing attribute subject: $^N";
                      push @{ $^R->[1] }, $^N;
                      $^R;
                  })
                  (?:
                      # attribute arguments
                      \s*\(\s* (*PRUNE)
                      (?{
                          $^R->[1][1] = [];
                          $^R;
                      })
                      (?:
                          (?&LITERAL)
                          (?{
                              #use Data::Dmp; say "D:pushing argument: ", dmp $^R->[1];
                              push @{ $^R->[0][1][1] }, $^R->[1];
                              $^R->[0];
                          })
                          (?:
                              \s*,\s*
                              (?&LITERAL)
                              (?{
                                  #use Data::Dmp; say "D:pushing argument: ", dmp $^R->[1];
                                  push @{ $^R->[0][1][1] }, $^R->[1];
                                  $^R->[0];
                              })
                          )*
                      )?
                      \s*\)\s*
                  )?
              )

              (?<ATTR_SUBJECTS>
                  (?{ $_i1 = 0; [$^R, []] })
                  (?&ATTR_SUBJECT) # [[$^R, [$name, \@args]]
                  (?{
                      $_i1++;
                      unless ($_i1 > 1) { # to prevent backtracking from executing tihs code block twice
                          #say "D:pushing subject(1)";
                          push @{ $^R->[0][1] }, {
                              name => $^R->[1][0],
                              (args => $^R->[1][1]) x !!defined($^R->[1][1]),
                          };
                      }
                      $^R->[0];
                  })
                  (?:
                      \s*\.\s*
                      (?{ $_i1 = 0; $^R })
                      (?&ATTR_SUBJECT) # [[$^R, $name, \@args]]
                      (?{
                          $_i1++;
                          unless ($_i1 > 1) { # to prevent backtracking from executing this code block twice
                              #say "D:pushing subject(2)";
                              push @{ $^R->[0][1] }, {
                                  name => $^R->[1][0],
                                  (args => $^R->[1][1]) x !!defined($^R->[1][1]),
                              };
                          }
                          $^R->[0];
                      })
                  )*
              )

              (?<LITERAL>
                  (?&LITERAL_NUMBER)
              |
                  (?&LITERAL_STRING_DQUOTE)
              |
                  (?&LITERAL_STRING_SQUOTE)
              |
                  (?&LITERAL_REGEX)
              |
                  true (?{ [$^R, 1] })
              |
                  false (?{ [$^R, 0] })
              |
                  null (?{ [$^R, undef] })
              )

              (?<LITERAL_NUMBER>
                  (
                      -?
                      (?: 0 | [1-9]\d* )
                      (?: \. \d+ )?
                      (?: [eE] [-+]? \d+ )?
                  )
                  (?{ [$^R, 0+$^N] })
              )

              (?<LITERAL_STRING_DQUOTE>
                  (
                      "
                      (?:
                          [^\\"]+
                      |
                          \\ [0-7]{1,3}
                      |
                          \\ x [0-9A-Fa-f]{1,2}
                      |
                          \\ ["\\'tnrfbae]
                      )*
                      "
                  )
                  (?{ [$^R, eval $^N] })
              )

              (?<LITERAL_STRING_SQUOTE>
                  (
                      '
                      (?:
                          [^\\']+
                      |
                          \\ .
                      )*
                      '
                  )
                  (?{ [$^R, eval $^N] })
              )

              (?<LITERAL_REGEX>
                  (
                      /
                      (?:
                          [^/\\]+
                      |
                          \\ .
                      )*
                      /
                      [ims]*
                  )
                  (?{ my $re = eval "qr$^N"; die if $@; [$^R, $re] })
              )

              (?<PSEUDOCLASS_NAME>
                  [A-Za-z_][A-Za-z0-9_]*(?:-[A-Za-z0-9_]+)*
              )

              (?<PSEUDOCLASS>
                  :
                  (?:
                      (?:
                          (has|not)
                          (?{ [$^R, [$^N]] })
                          \(\s*
                          (?:
                              (?&LITERAL)
                              (?{
                                  push @{ $^R->[0][1][1] }, $^R->[1];
                                  $^R->[0];
                              })
                          |
                              ((?&SELECTORS))
                              (?{
                                  push @{ $^R->[0][1][1] }, $^N;
                                  $^R->[0];
                              })
                          )
                          \s*\)
                      )
                  |
                      (?:
                          ((?&PSEUDOCLASS_NAME))
                          (?{ [$^R, [$^N]] })
                          (?:
                              \(\s*
                              (?&LITERAL)
                              (?{
                                  push @{ $^R->[0][1][1] }, $^R->[1];
                                  $^R->[0];
                              })
                              (?:
                                  \s*,\s*
                                  (?&LITERAL)
                                  (?{
                                      push @{ $^R->[0][1][1] }, $^R->[1];
                                      $^R->[0];
                                  })
                              )*
                              \s*\)
                          )?
                      )
                  )
              )
          ) # DEFINE
  }x;

sub parse_csel {
    state $re = qr{\A\s*$RE\s*\z};

    local $_ = shift;
    local $^R;
    eval { $_ =~ $re } and return $_;
    die $@ if $@;
    return undef;
}

sub _uniq_objects {
    my @uniq;
    my %mem;
    for (@_) {
        push @uniq, $_ unless $mem{refaddr($_)}++;
    }
    @uniq;
}

sub _simpsel {
    no warnings 'numeric', 'uninitialized';

    my ($opts, $simpsel, $is_recursive, @nodes) = @_;

    #use Data::Dmp; say "D: _simpsel(expr", dmp($simpsel), ", recursive=$is_recursive, nodes=[".join(",",map {$_->{id}} @nodes)."])";

    my @res;
    if ($is_recursive) {
        @res = (@nodes, map {Code::Includable::Tree::NodeMethods::descendants($_)} @nodes);
    } else {
        @res = @nodes;
    }
    #say "D:   intermediate result (after walk): [".join(",",map {$_->{id}} @res)."]";

    unless ($simpsel->{type} eq '*') {
        my @fres;

        my @types_to_match;
        for (@{ $opts->{class_prefixes} // [] }) {
            push @types_to_match, $_ . (/::$/ ? "" : "::") . $simpsel->{type};
        }
        push @types_to_match, $simpsel->{type};

      ELEM:
        for my $o (@res) {
            my $ref = ref($o);
            for (@types_to_match) {
                if ($ref eq $_) {
                    push @fres, $o;
                    next ELEM;
                }
            }
        }
        @res = @fres;
    }

    @res = _uniq_objects(@res);
    #say "D:   intermediate result (after type): [".join(",",map {$_->{id}} @res)."]";

    for my $f (@{ $simpsel->{filters} // [] }) {
        last unless @res;

        my $type = $f->{type};

        if ($type eq 'attr_selector') {

            my @attrs = @{ $f->{attr} };
            my $op    = $f->{op};
            my $opv   = $f->{value};

            my @newres;
          ITEM:
            for my $o0 (@res) {
                my $o = $o0;
                for my $i (0..$#attrs) {
                    my $attr_name = $attrs[$i]{name};
                    my $attr_args = $attrs[$i]{args};
                    next ITEM unless blessed($o) && $o->can($attr_name);
                    if ($attr_args && $i == $#attrs) {
                        # T[meth()] means T[meth() is true]
                        unless ($op) {
                            $op = 'is';
                            $opv = 1;
                        }
                        $o = $o->$attr_name(@$attr_args);
                    } else {
                        $o = $o->$attr_name;
                    }
                }
                goto PASS unless $op;
                my $val = $o;

                if ($op eq '=' || $op eq '==') {
                    if (looks_like_number($opv)) {
                        next ITEM unless $val == $opv;
                    } else {
                        next ITEM unless $val eq $opv;
                    }
                } elsif ($op eq 'eq') {
                    next ITEM unless $val eq $opv;
                } elsif ($op eq '!=' || $op eq '<>') {
                    if (looks_like_number($opv)) {
                        next ITEM unless $val != $opv;
                    } else {
                        next ITEM unless $val ne $opv;
                    }
                } elsif ($op eq 'ne') {
                    next ITEM unless $val ne $opv;
                } elsif ($op eq '>') {
                    if (looks_like_number($opv)) {
                        next ITEM unless $val >  $opv;
                    } else {
                        next ITEM unless $val gt $opv;
                    }
                } elsif ($op eq 'gt') {
                    next ITEM unless $val gt $opv;
                } elsif ($op eq '>=') {
                    if (looks_like_number($opv)) {
                        next ITEM unless $val >=  $opv;
                    } else {
                        next ITEM unless $val ge $opv;
                    }
                } elsif ($op eq 'ge') {
                    next ITEM unless $val ge $opv;
                } elsif ($op eq '<') {
                    if (looks_like_number($opv)) {
                        next ITEM unless $val <  $opv;
                    } else {
                        next ITEM unless $val lt $opv;
                    }
                } elsif ($op eq 'lt') {
                    next ITEM unless $val lt $opv;
                } elsif ($op eq '<=') {
                    if (looks_like_number($opv)) {
                        next ITEM unless $val <= $opv;
                    } else {
                        next ITEM unless $val le $opv;
                    }
                } elsif ($op eq 'le') {
                    next ITEM unless $val le $opv;
                } elsif ($op eq 'is') {
                    if (!defined($opv)) {
                        next ITEM unless !defined($val);
                    } elsif ($opv) {
                        next ITEM unless $val;
                    } else {
                        next ITEM unless !$val;
                    }
                } elsif ($op eq 'isnt') {
                    if (!defined($opv)) {
                        next ITEM unless defined($val);
                    } elsif ($opv) {
                        next ITEM unless !$val;
                    } else {
                        next ITEM unless $val;
                    }
                } elsif ($op eq '=~') {
                    next ITEM unless $val =~ $opv;
                } elsif ($op eq '!~') {
                    next ITEM unless $val !~ $opv;
                } else {
                    die "BUG: Unsupported operator '$op' in attr_selector";
                }

              PASS:
                # pass all attribute filters, add to new result
                #say "D:    adding to result: ".$o->{id};
                push @newres, $o0;
            } # for each item
            @res = @newres;

        } elsif ($type eq 'class_selector') {

            my $class = $f->{class};

            my @classes_to_match;
            for (@{ $opts->{class_prefixes} // [] }) {
                push @classes_to_match, $_ . (/::$/ ? "" : "::") . $class;
            }
            push @classes_to_match, $class;
            my @filtered_res;
          RES:
            for my $res (@res) {
                for (@classes_to_match) {
                    if ($res->isa($_)) {
                        push @filtered_res, $res;
                        next RES;
                    }
                }
            }
            @res = @filtered_res;

        } elsif ($type eq 'id_selector') {

            my $method = $opts->{id_method} // 'id';
            my $id     = $f->{id};

            @res = grep { $_->can($method) && $_->$method eq $id } @res;

        } elsif ($type eq 'pseudoclass') {

            my $pc = $f->{pseudoclass};

            if ($pc eq 'first') {
                @res = ($res[0]);
            } elsif ($pc eq 'last') {
                @res = ($res[-1]);
            } elsif ($pc eq 'first-child') {
                @res = grep { Code::Includable::Tree::NodeMethods::is_first_child($_) } @res;
            } elsif ($pc eq 'last-child') {
                @res = grep { Code::Includable::Tree::NodeMethods::is_last_child($_) } @res;
            } elsif ($pc eq 'only-child') {
                @res = grep { Code::Includable::Tree::NodeMethods::is_only_child($_) } @res;
            } elsif ($pc eq 'nth-child') {
                @res = grep { Code::Includable::Tree::NodeMethods::is_nth_child($_, $f->{args}[0]) } @res;
            } elsif ($pc eq 'nth-last-child') {
                @res = grep { Code::Includable::Tree::NodeMethods::is_nth_last_child($_, $f->{args}[0]) } @res;
            } elsif ($pc eq 'first-of-type') {
                @res = grep { Code::Includable::Tree::NodeMethods::is_first_child_of_type($_) } @res;
            } elsif ($pc eq 'last-of-type') {
                @res = grep { Code::Includable::Tree::NodeMethods::is_last_child_of_type($_) } @res;
            } elsif ($pc eq 'only-of-type') {
                @res = grep { Code::Includable::Tree::NodeMethods::is_only_child_of_type($_) } @res;
            } elsif ($pc eq 'nth-of-type') {
                @res = grep { Code::Includable::Tree::NodeMethods::is_nth_child_of_type($_, $f->{args}[0]) } @res;
            } elsif ($pc eq 'nth-last-of-type') {
                @res = grep { Code::Includable::Tree::NodeMethods::is_nth_last_child_of_type($_, $f->{args}[0]) } @res;
            } elsif ($pc eq 'root') {
                @res = grep { !$_->parent } @res;
            } elsif ($pc eq 'empty') {
                @res = grep { my @c = Code::Includable::Tree::NodeMethods::_children_as_list($_); !@c } @res;
            } elsif ($pc eq 'has') {
                @res = _uniq_objects(
                    map { reverse Code::Includable::Tree::NodeMethods::ancestors($_) }
                        csel($opts, $f->{args}[0], @res)
                    );
            } elsif ($pc eq 'not') {
                #say "D: res=(".join(",", map {$_->{id}} @res).")";
                my @matches = csel($opts, $f->{args}[0], @res);
                #say "D: all_matches=(".join(",", map {$_->{id}} @all_matches).")";
                my %matches_refaddrs;
                for (@matches) { $matches_refaddrs{refaddr($_)}++ }
                @res = grep { !$matches_refaddrs{refaddr($_)} } @res;
            } else {
                die "Unsupported pseudo-class '$pc'";
            }

        }

        #say "D:   intermediate result (after filter): [".join(",",map {$_->{id}} @res)."]";
    } # for each filter
    @res;
}

sub _sel {
    my ($opts, $sel, @nodes) = @_;

    my @simpsels = @$sel;
    my @res;

    my $i = 0;
    while (@simpsels) {
        if ($i++ == 0) {
            my $simpsel = shift @simpsels;
            @res = _simpsel($opts, $simpsel, 1, @nodes);
        } else {
            my $combinator = shift @simpsels;
            my $simpsel = shift @simpsels;
            last unless @res;
            if ($combinator->{combinator} eq ' ') { # descendant
                @res = _simpsel($opts, $simpsel, 1,
                                map { Code::Includable::Tree::NodeMethods::_children_as_list($_) } @res);
            } elsif ($combinator->{combinator} eq '>') { # child
                @res = _simpsel($opts, $simpsel, 0,
                                map { Code::Includable::Tree::NodeMethods::_children_as_list($_) } @res);
            } elsif ($combinator->{combinator} eq '~') { # sibling
                @res = _simpsel($opts, $simpsel, 0,
                                map { Code::Includable::Tree::NodeMethods::next_siblings($_) } @res);
            } elsif ($combinator->{combinator} eq '+') { # adjacent sibling
                @res = _simpsel($opts, $simpsel, 0,
                                grep {defined}
                                    map { Code::Includable::Tree::NodeMethods::next_sibling($_) }
                                    @res);
            } else {
                die "BUG: Unknown combinator '$combinator->{combinator}'";
            }
        }
    }

    @res;
}

sub csel {
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    my $expr = shift;
    my @nodes = @_;

    my $pexpr = parse_csel($expr);
    $pexpr or die "Invalid CSel expression '$expr'";

    local $Code::Includable::Tree::NodeMethods::GET_PARENT_METHOD   = $opts->{get_parent_method}   if $opts->{get_parent_method};
    local $Code::Includable::Tree::NodeMethods::SET_PARENT_METHOD   = $opts->{set_parent_method}   if $opts->{set_parent_method};
    local $Code::Includable::Tree::NodeMethods::GET_CHILDREN_METHOD = $opts->{get_children_method} if $opts->{get_children_method};
    local $Code::Includable::Tree::NodeMethods::SET_CHILDREN_METHOD = $opts->{set_children_method} if $opts->{set_children_method};

    my @res = _uniq_objects(map { _sel($opts, $_, @nodes) } @$pexpr );

    if ($opts->{wrap}) {
        require Data::CSel::Selection;
        return Data::CSel::Selection->new(\@res);
    } else {
        return @res;
    }
}

1;
# ABSTRACT: Select tree node objects using CSS Selector-like syntax

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::CSel - Select tree node objects using CSS Selector-like syntax

=head1 VERSION

This document describes version 0.121 of Data::CSel (from Perl distribution Data-CSel), released on 2019-07-26.

=head1 SYNOPSIS

 use Data::CSel qw(csel);

 my @cells = csel("Table[name=~/data/i] TCell[value != '']:first", $tree);

 # ditto, but wrap result using a Data::CSel::Selection
 my $res = csel({wrap=>1}, "Table ...", $tree);

 # call method 'foo' of each node object (works even when there are zero nodes
 # in the selection object, or when some nodes do not support the 'foo' method
 $res->foo;

=head1 DESCRIPTION

This module lets you use a query language (hereby named CSel) that is similar to
CSS Selector to select nodes from a tree of objects.

=head1 EXPRESSION SYNTAX

The following is description of the CSel query expression. It is modeled after
the CSS Selector syntax with some modification (see L</"Differences with CSS
selector">).

An I<expression> is a chain of one or more selectors separated by commas.

A I<selector> is a chain of one or more simple selectors separated by
combinators.

A I<combinator> is either: whitespace (descendant combinator), C<< > >> (child
combinator), C<~> (general sibling combinator), or C<+> (adjacent sibling
combinator). C<E F>, or two elements combined using descendant combinator, means
F element descendant of an E element. C<< E > F >> means F element child of E
element. C<E ~ F> means F element preceded by an E element. C<E + F> means F
element immediately preceded by an E element.

A I<simple selector> is either a type selector (see L</"Type selector">) or
universal selector (see L</"Universal selector">) followed immediately by zero
or more attribute selectors (see L</"Attribute selector"> or class selector (see
L<"/Class selector">) or ID selector (see L</"ID selector">) or pseudo-classes
(see L<"/Pseudo-class">), in any order. Type or universal selector is optional
if there is at least one attribute selector or pseudo-class.

=head2 Type selector

A I<type selector> is a Perl class/package name.

Example:

 My::Class

will match any C<My::Class> object. Subclasses of C<My::Class> will I<not> be
matched, use L<class selector|"/Class selector"> for that.

=head2 Universal selector

A I<universal selector> is C<*> and matches any class/package.

Example:

 *

will match any object.

=head2 Attribute selector

An I<attribute selector> filters objects based on the value of their attributes.
The syntax is:

 [ATTR]
 [ATTR OP LITERAL]

C<[ATTR]> means to only select objects that have an attribute named C<ATTR>, for
example:

 [length]

means to select objects that respond to (C<can()>) C<length()>.

Note: to select objects that do not have a specified attribute, you can use the
C<:not> pseudo-class (see L</"Pseudo-class">), for example:

 :not([length])

C<[ATTR OP LITERAL]> means to only select objects that have an attribute named
C<ATTR> that has value that matches the expression specified by operator C<OP>
and operand C<LITERAL>. For example:

 [length > 12]
 [is_done is true]
 [name =~ /foo/]

B<Calling methods> C<ATTR> can also be replaced by C<METH()> or C<METH(LITERAL,
...)> to allow passing arguments to methods. Note that this specific syntax:

 [METH()]

does not simply mean to select objects that respond to C<METH>, but actually:

 [METH() is true]

For example:

 # select objects that have non-zero length
 [length()]

 # while this means to select objects that have 'length' attribute
 [length]

 # select objects for which the method call returns true
 [has_key('foo')]

B<Experimental:> a chain of attributes is allowed for the attribute, for
example:

 [date.month = 12]

will select only objects that has an attribute C<date>, and the value of C<date>
is an object that has an attribute C<month>, and the value of C<month> is 12.

=head3 Literal

There are several kinds of literals supported.

B<Numbers>. Examples:

 1
 -2.3
 4.5e-6

B<Boolean>:

 true
 false

B<Null (undef)>:

 null

B<String>. Either single-quoted (only recognizes the escape sequences C<\\> and
C<\'>):

 'this is a string'
 'this isn\'t hard'

or double-quoted (currently recognizes the escape sequences C<\\>, C<\">, C<\'>,
C<\$> [literal $], C<\t> [tab character], C<\n> [newline], C<\r> [linefeed],
C<\f> [formfeed], C<\b> [backspace], C<\a> [bell], C<\e> [escape], C<\0> [null],
octal escape e.g. C<\033>, hexadecimal escape e.g. C<\x1b>):

 "This is a string"
 "This isn't hard"
 "Line 1\nLine 2"

For convenience, a word string can be unquoted in expression, e.g.:

 [name = ujang]

is equivalent to:

 [name = 'ujang']

B<Regex literal>. Must be delimited by C</> ... C</>, can be followed by zero of
more regex modifier characters m, s, i):

 //
 /ab(c|d)/i

=head3 Operators

The following are supported operators:

=over

=item * C<eq>

String equality using Perl's C<eq> operator.

Example:

 Table[title eq "TOC"]

selects all C<Table> objects that have C<title()> with the value of C<"TOC">.

=item * C<=> (or C<==>)

Numerical equality using Perl's C<==> operator.

Example:

 TableCell[length=3]

selects all C<TableCell> objects that have C<length()> with the value of 3.

To avoid common trap, will switch to using Perl's C<eq> operator when operand
does not look like number, e.g.:

 Table[title = 'foo']

is the same as:

 Table[title eq 'foo']

=item * C<ne>

String inequality using Perl's C<ne> operator.

Example:

 Table[title ne "TOC"]

selects all C<Table> objects that have C<title()> with the value not equal to
C<"TOC">.

=item * C<!=> (or C<< <> >>)

Numerical inequality using Perl's C<!=> operator.

Example:

 TableCell[length != 3]
 TableCell[length <> 3]

selects all C<TableCell> objects that have C<length()> with the value not equal
to 3.

To avoid common trap, will switch to using Perl's C<ne> operator when operand
does not look like number, e.g.:

 Table[title != 'foo']

is the same as:

 Table[title ne 'foo']

=item * C<gt>

String greater-than using Perl's C<gt> operator.

Example:

 Person[first_name gt "Albert"]

selects all C<Person> objects that have C<first_name()> with the value
asciibetically greater than C<"Albert">.

=item * C<< > >>

Numerical greater-than using Perl's C<< > >> operator.

Example:

 TableCell[length > 3]

selects all C<TableCell> objects that have C<length()> with the value greater
than 3.

To avoid common trap, will switch to using Perl's C<gt> operator when operand
does not look like number, e.g.:

 Person[first_name > 'Albert']

is the same as:

 Person[first_name gt "Albert"]

=item * C<ge>

String greater-than-or-equal-to using Perl's C<< ge >> operator.

Example:

 Person[first_name ge "Albert"]

selects all C<Person> objects that have C<first_name()> with the value
asciibetically greater than or equal to C<"Albert">.

=item * C<< >= >>

Numerical greater-than-or-equal-to using Perl's C<< >= >> operator.

Example:

 TableCell[length >= 3]

selects all C<TableCell> objects that have C<length()> with the value greater
than or equal to 3.

To avoid common trap, will switch to using Perl's C<ge> operator when operand
does not look like number, e.g.:

 Person[first_name >= 'Albert']

is the same as:

 Person[first_name ge "Albert"]

=item * C<lt>

String less-than using Perl's C<< lt >> operator.

Example:

 Person[first_name lt "Albert"]

selects all C<Person> objects that have C<first_name()> with the value
asciibetically less than C<"Albert">.

=item * C<< < >>

Numerical less-than using Perl's C<< < >> operator.

Example:

 TableCell[length < 3]

selects all C<TableCell> objects that have C<length()> with the value less
than 3.

To avoid common trap, will switch to using Perl's C<lt> operator when operand
does not look like number, e.g.:

 Person[first_name < 'Albert']

is the same as:

 Person[first_name lt "Albert"]

=item * C<le>

String less-than-or-equal-to using Perl's C<< le >> operator.

Example:

 Person[first_name le "Albert"]

selects all C<Person> objects that have C<first_name()> with the value
asciibetically less than or equal to C<"Albert">.

=item * C<< <= >>

Numerical less-than-or-equal-to using Perl's C<< <= >> operator.

Example:

 TableCell[length <= 3]

selects all C<TableCell> objects that have C<length()> with the value less
than or equal to 3.

To avoid common trap, will switch to using Perl's C<le> operator when operand
does not look like number, e.g.:

 Person[first_name <= 'Albert']

is the same as:

 Person[first_name le "Albert"]

=item * C<=~> and C<!~>

Filter only objects where the attribute named I<attr> has the value matching
regular expression I<value>. Operand should be a regex literal. Regex literal
must be delimited by C<//>.

Example:

 Person[first_name =~ /^Al/]

selects all C<Person> objects that have C<first_name()> with the value
matching the regex C</^Al/>.

 Person[first_name =~ /^al/i]

Same as previous example except the regex is case-insensitive.

C<!~> is the opposite of C<=~>, just like in Perl. It checks whether I<attr> has
value that does not match regular expression.

=item * C<is> and C<isnt>

Testing truth value or definedness. Value can be null or boolean literal.

Example:

 DateTime[is_leap_year is true]

will select all DateTime objects where its C<is_leap_year> attribute has a true
value.

 DateTime[is_leap_year is false]

will select all DateTime objects where its C<is_leap_year> attribute has a false
value.

 Person[age isnt null]

will select all Person objects where age is defined.

=back

=head2 Class selector

A I<class selector> is a C<.> (dot) followed by Perl class/package name.

 .CLASSNAME

It selects all objects that C<isa()> a certain class. The difference with type
selector is that inheritance is observed. So:

 .My::Class

will match instances of C<My::Class> as well as subclasses of it.

=head2 ID selector

An I<ID selector> is a C<#> (hash) followed by an identifier:

 #ID

It is a special/shortcut form of attribute selector where the attribute is
C<id> and the operator is C<=>:

 [id = ID]

The C<csel()> function allows you to configure which attribute to use as the ID
attribute, the default is C<id>.

=head2 Pseudo-class

A I<pseudo-class> is C<:> (colon) followed by pseudo-class name (a
dash-separated word list), and optionally a list of arguments enclosed in
parentheses.

 :PSEUDOCLASSNAME
 :PSEUDOCLASSNAME(ARG, ...)

It filters result set based on some criteria. Currently supported pseudo-classes
include:

=over

=item * C<:first>

Select only the first object from the result set.

Example:

 Person[name =~ /^a/i]:first

selects the first person whose name starts with the letter C<A>.

=item * C<:last>

Select only the last item from the result set.

Example:

 Person[name =~ /^a/i]:last

selects the last person whose name starts with the letter C<A>.

=item * C<:first-child>

Select only objects that are the first child of their parent.

=item * C<:last-child>

Select only objects that are the last child of their parent.

=item * C<:only-child>

Select only objects that is the only child of their parent.

=item * C<:nth-child(n)>

Select only objects that are the I<n>th child of their parent.

=item * C<:nth-last-child(n)>

Select only objects that are the I<n>th last child of their parent.

=item * C<:first-of-type>

Select only objects that are the first child of their parent of their type. So
if a parent's children is:

 id1(type=T1) id2(T2) id3(T2)

then both C<id1> and C<id2> are first children of their respective types.

=item * C<:last-of-type>

Select only objects that are the last child of their parent of their type.

=item * C<:only-of-type>

Select only objects that are the only child of their parent of their type.

=item * C<:nth-of-type(n)>

Select only objects that are the I<n>th child of their parent of their type.

=item * C<:nth-last-of-type(n)>

Select only objects that are the I<n>th last child of their parent of their
type.

=item * C<:root>

Select only root node(s).

=item * C<:empty>

Select only leaf node(s).

=item * C<:not(S)>

Select all objects not matching selector C<S>. C<S> can be a string or an
unquoted CSel expression.

Example:

 :not('.My::Class')
 :not(.My::Class)

will select all objects that are not of C<My::Class> type.

=item * C<:has(S)>

Select all objects that have a descendant matching selector C<S>. C<S> can be a
string or an unquoted CSel expression.

Example:

 :has('T')
 :not(T)

will select all objects that have a descendant of type C<T>.

=back

=head2 Differences with CSS selector

=head3 Type selector can contain double colon (C<::>)

Since Perl package names are separated by C<::>, CSel allows it in type
selector.

=head3 Syntax of attribute selector is a bit different

In CSel, the syntax of attribute selector is made simpler and more regular.

There are operators not supported by CSel, but CSel adds more operators from
Perl. In particular, the whole substring matching operations like
C<[attr^=val]>, C<[attr$=val]>, C<[attr*=val]>, C<[attr~=val]>, and
C<[attr|=val]> are replaced with the more flexible regex matching instead
C<[attr =~ /re/]>.

=head3 Different pseudo-classes supported

Some CSS pseudo-classes only make sense for a DOM or a visual browser, e.g.
C<:link>, C<:visited>, C<:hover>, so they are not supported.

=head3 There is no concept of CSS namespaces

CSS namespaces are used when there are foreign elements (e.g. SVG in addition to
HTML) and one wants to use the same stylesheet for both. There is no need for
something like this CSel, as we deal with only Perl objects.

=head1 FUNCTIONS

=head2 csel

Usage:

 $list_or_selection_obj = csel([ \%opts , ] $expr, @tree_nodes)

Select from tree node objects C<@tree_nodes> using CSel expression C<$expr>.
Will return a list of mattching node objects (unless when C<wrap> option is
true, in which case will return a L<Data::CSel::Selection> object instead). Will
die on errors (e.g. syntax error in expression, objects not having the required
methods, etc).

A tree node object is any regular Perl object satisfying the following criteria:
1) it supports a C<parent> method which should return a single parent node
object, or undef if object is the root node); 2) it supports a C<children>
method which should return a list (or an arrayref) of children node objects
(where the list/array will be empty for a leaf node). Note: you can use
L<Role::TinyCommons::Tree::Node> to enforce this requirement. Note: the
C<parent> and C<children> method names can actually be customized, see options.

Known options:

=over

=item * class_prefixes => array of str

Array of namespace to check when matching type in type selector as well as class
selector. This is like PATH environment variable in Unix shell. For example, if
C<class_prefixes> is C<< ["Foo::Bar", "Baz"] >>, then this expression:

 T

will match class C<Foo::Bar::T>, or C<Baz::T>, or C<T>.

=item * wrap => bool

If set to true, instead of returning a list of matching nodes, the function will
return a L<Data::CSel::Selection> object instead (which wraps the result, for
convenience). See the selection object's documentation for more details.

=item * get_parent_method => str

Example:

 get_parent_method => 'get_parent'

This option can be used if your node object uses method other than the default
C<parent> to get parent node.

=item * set_parent_method => str

Example:

 set_parent_method => 'set_parent'

This option can be used if your node object uses method other than the default
C<parent> to set parent node.

=item * get_children_method => str

Example:

 get_children_method => 'get_children'

This option can be used if your node object uses method other than the default
C<children> to get children nodes.

=item * set_children_method => str

Example:

 set_children_method => 'set_children'

This option can be used if your node object uses method other than the default
C<children> to set children nodes.

=back

=head2 parse_csel

Usage:

 $hash = parse_csel($expr);

Parse an expression. On success, will return a hash containing parsed
information. On failure, will return undef.

=head1 FAQ

=head2 Can I use csel() against a regular data structure (instead of a tree of objects)?

Use L<Data::CSel::WrapStruct> to create a tree of object from the data
structure, then perform C<csel()> on the resulting tree.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-CSel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-CSel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-CSel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head2 Related to CSS selector

CSS4 Selectors Specification, L<https://www.w3.org/TR/selectors4/>.

These modules let you use CSS selector syntax (or its subset) to select nodes of
an HTML document: L<Mojo::DOM> (or L<DOM::Tiny>), L<jQuery>, L<pQuery>,
L<HTML::Selector::XPath> (or via L<Web::Query>). The last two modules can also
handle XPath expression.

CLI to select HTML elements using CSS selector syntax: L<html-css-sel> (from
L<App::html::css::sel>).

=head2 Similar query languages

These modules let you use XPath (or XPath-like) syntax to select nodes of a data
structure: L<Data::DPath>. Like CSS selectors, XPath is another query language
to select nodes of a document. XPath specification:
L<https://www.w3.org/TR/xpath/>.

These modules let you use JSONPath syntax to select nodes of a data structure:
L<JSON::Path>. JSONPath is a query language to select nodes of a JSON document
(data structure). JSONPath specification:
L<http://goessner.net/articles/JsonPath>.

=head2 Related modules

L<Data::CSel::WrapStruct>

L<CSel::Examples>

=head2 Modules that use CSel

=over

=item * For data structure

CLI to select JSON nodes using CSel: L<jsonsel> (from L<App::jsonsel>).

CLI to select Perl data structure elements using CSel: L<ddsel> (from
L<App::CSelUtils>).

CLI to select YAML nodes using CSel: L<yamlsel> (from L<App::yamlsel>).

=item * For HTML document

L<htmlsel> (from L<App::htmlsel>).

=item * For Org document

L<orgsel> (from L<App::orgsel>).

=item * For POD document

CLI to select POD::Elemental nodes using CSel: L<podsel> (from L<App::podsel>).

=item * For PPI (Perl source code tree representation) document

CLI to select PPI nodes using CSel: L<ppisel> (from L<App::ppisel>).

=back

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
