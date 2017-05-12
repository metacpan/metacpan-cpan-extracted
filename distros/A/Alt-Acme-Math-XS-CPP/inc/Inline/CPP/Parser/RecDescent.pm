use strict; use warnings;
package Inline::CPP::Parser::RecDescent;

# Dev versions will have a _0xx suffix.
# We eval the $VERSION to accommodate dev version numbering as described in
# perldoc perlmodstyle
our $VERSION = '0.68';
#$VERSION = eval $VERSION;  ## no critic (eval)

use Carp;

sub register {
    {
     extends => [qw(CPP)],
     overrides => [qw(get_parser)],
    }
}

sub get_parser {
    my $o = shift;
    return Inline::CPP::Parser::RecDescent::get_parser_recdescent($o);
}

sub get_parser_recdescent {
    my $o = shift;
    eval { require Parse::RecDescent };
    croak <<END if $@;
This invocation of Inline requires the Parse::RecDescent module.
$@
END
    no warnings qw/ once /;    ## no critic (warnings)
    $::RD_HINT = 1;    # Turns on Parse::RecDescent's warnings/diagnostics.
    my $parser = Parse::RecDescent->new(grammar());
    $parser->{data}{typeconv} = $o->{ILSM}{typeconv};
    $parser->{ILSM} = $o->{ILSM};    # give parser access to config options
    return $parser;
}

use vars qw($TYPEMAP_KIND $class_part $class_decl $star);

# Parse::RecDescent 1.90 and later have an incompatible change
# 'The key of an %item entry for a repeated subrule now includes
# the repetition specifier.'
# Hence various hash keys may or may not need trailing '(s?)' depending on
# the version of Parse::RecDescent we are using.

require Parse::RecDescent;

# Deal with Parse::RecDescent's version numbers for development
# releases (eg, '1.96_000') resulting in a warning about non-numeric in >
# comparison.
{    # Lexical scope.
      # Eval away the underscore.  "1.96_000" => "1.96000".
      # Use that "stable release" version number as the basis for our numeric
      # comparison.
  my $stable_version = eval $Parse::RecDescent::VERSION;    ## no critic (eval)
  ($class_part, $class_decl, $star)
    = map { ($stable_version > 1.89) ? "$_(s?)" : $_ }
    qw ( class_part class_decl star );
}    # End lexical scope.


#============================================================================
# Regular expressions to match code blocks, numbers, strings, parenthesized
# expressions, function calls, and macros. The more complex regexes are only
# implemented in 5.6.0 and above, so they're in eval-blocks.
#
# These are all adapted from the output of Damian Conway's excellent
# Regexp::Common module. In future, Inline::CPP may depend directly on it,
# but for now I'll just duplicate the code.
use vars qw( $code_block $string $number $parens $funccall );

#============================================================================

# $RE{balanced}{-parens=>q|{}()[]"'|}
eval <<'END';    ## no critic (eval)
$code_block = qr'(?-xism:(?-xism:(?:[{](?:(?>[^][)(}{]+)|(??{$Inline::CPP::Parser::RecDescent::code_block}))*[}]))|(?-xism:(?-xism:(?:[(](?:(?>[^][)(}{]+)|(??{$Inline::CPP::Parser::RecDescent::code_block}))*[)]))|(?-xism:(?-xism:(?:[[](?:(?>[^][)(}{]+)|(??{$Inline::CPP::Parser::RecDescent::code_block}))*[]]))|(?-xism:(?!)))))';
END
$code_block = qr'{[^}]*}' if $@;    # For the stragglers: here's a lame regexp.

# $RE{balanced}{-parens=>q|()"'|}
eval <<'END';                       ## no critic (eval)
$parens = qr'(?-xism:(?-xism:(?:[(](?:(?>[^)(]+)|(??{$Inline::CPP::Parser::RecDescent::parens}))*[)]))|(?-xism:(?!)))';
END
$parens = qr'\([^)]*\)' if $@;      # For the stragglers: here's another

# $RE{quoted}
$string
  = qr'(?:(?:\")(?:[^\\\"]*(?:\\.[^\\\"]*)*)(?:\")|(?:\')(?:[^\\\']*(?:\\.[^\\\']*)*)(?:\')|(?:\`)(?:[^\\\`]*(?:\\.[^\\\`]*)*)(?:\`))';

# $RE{num}{real}|$RE{num}{real}{-base=>16}|$RE{num}{int}
$number
  = qr'(?:(?i)(?:[+-]?)(?:(?=[0123456789]|[.])(?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?)(?:(?:[E])(?:(?:[+-]?)(?:[0123456789]+))|))|(?:(?i)(?:[+-]?)(?:(?=[0123456789ABCDEF]|[.])(?:[0123456789ABCDEF]*)(?:(?:[.])(?:[0123456789ABCDEF]{0,}))?)(?:(?:[G])(?:(?:[+-]?)(?:[0123456789ABCDEF]+))|))|(?:(?:[+-]?)(?:\d+))';
$funccall
  = qr/(?:[_a-zA-Z][_a-zA-Z0-9]*::)*[_a-zA-Z][_a-zA-Z0-9]*(?:$Inline::CPP::Parser::RecDescent::parens)?/;

#============================================================================
# Inline::CPP's grammar
#============================================================================
sub grammar {
  return <<'END';

{ use Data::Dumper; }

{
    sub handle_class_def {
        my ($thisparser, $def) = @_;
#         print "Found a class: $def->[0]\n";
        my $class = $def->[0];
        my @parts;
        for my $part (@{$def->[1]}) { push @parts, @$_ for @$part }
        push @{$thisparser->{data}{classes}}, $class
            unless defined $thisparser->{data}{class}{$class};
        $thisparser->{data}{class}{$class} = \@parts;
#   print "Class $class:\n", Dumper \@parts;
        Inline::CPP::Parser::RecDescent::typemap($thisparser, $class);
        [$class, \@parts];
    }
    sub handle_typedef {
        my ($thisparser, $t) = @_;
        my ($name, $type) = @{$t}{qw(name type)};
#   print "found a typedef: $name => $type\n";

        # XXX: this doesn't handle non-class typedefs that we could handle,
        # e.g. "typedef int my_int_t"

        if ($thisparser->{data}{class}{$type}
            && !exists($thisparser->{data}{class}{$name})) {
            push @{$thisparser->{data}{classes}}, $name;
            $thisparser->{data}{class}{$name} = $thisparser->{data}{class}{$type};
            Inline::CPP::Parser::RecDescent::typemap($thisparser, $name);
        }
        $t;
    }
    sub handle_enum {
        my ($thisparser, $t) = @_;
        $t;
    }
}

code: part(s) {1}

part: comment
    | typedef
      {
        handle_typedef($thisparser, $item[1]);
        1;
      }
    | enum
      {
        my $t = handle_enum($thisparser, $item[1]);
        push @{$thisparser->{data}{enums}}, $t;
        1;
      }
    | class_def
      {
         handle_class_def($thisparser, $item[1]);
     1;
      }
    | function_def
      {
#         print "found a function: $item[1]->{name}\n";
         my $name = $item[1]->{name};
     my $i=0;
     for my $arg (@{$item[1]->{args}}) {
        $arg->{name} = 'dummy' . ++$i unless defined $arg->{name};
     }
     Inline::CPP::Parser::RecDescent::strip_ellipsis($thisparser,
                          $item[1]->{args});
     push @{$thisparser->{data}{functions}}, $name
           unless defined $thisparser->{data}{function}{$name};
     $thisparser->{data}{function}{$name} = $item[1];
#    print Dumper $item[1];
     1;
      }
    | all

typedef: 'typedef' class IDENTIFIER(?) '{' <commit> class_part(s?) '}' IDENTIFIER ';'
       {
     my ($class, $parts);
         $class = $item[3][0] || 'anon_class'.($thisparser->{data}{anonclass}++);
         ($class, $parts)= handle_class_def($thisparser, [$class, $item{$Inline::CPP::Parser::RecDescent::class_part}]);
     { thing => 'typedef', name => $item[8], type => $class, body => $parts }
       }
       | 'typedef' IDENTIFIER IDENTIFIER ';'
       { { thing => 'typedef', name => $item[3], type => $item[2] } }
       | 'typedef' /[^;]*/ ';'
       {
#         dprint "Typedef $item{__DIRECTIVE1__} is too heinous\n";
         { thing => 'comment'}
       }

enum: 'enum' IDENTIFIER(?) '{' <leftop: enum_item ',' enum_item> '}' ';'
       {
    { thing => 'enum', name => $item{IDENTIFIER}[0],
          body => $item{__DIRECTIVE1__} }
       }

enum_item: IDENTIFIER '=' <commit> /[0-9]+/
         { [$item{IDENTIFIER}, $item{__PATTERN1__}] }
         | IDENTIFIER
         { [$item{IDENTIFIER}, undef] }

class_def: class IDENTIFIER '{' <commit> class_part(s?) '}' ';'
           {
              [@item{'IDENTIFIER',$Inline::CPP::Parser::RecDescent::class_part}]
       }
     | class IDENTIFIER ':' <commit> <leftop: inherit ',' inherit>
            '{' class_part(s?) '}' ';'
       {
          push @{$item{$Inline::CPP::Parser::RecDescent::class_part}}, [$item{__DIRECTIVE2__}];
          [@item{'IDENTIFIER',$Inline::CPP::Parser::RecDescent::class_part}]
       }

inherit: scope IDENTIFIER
    { {thing => 'inherits', name => $item[2], scope => $item[1]} }

class_part: comment { [ {thing => 'comment'} ] }
      | scope ':' <commit> class_decl(s?)
            {
          for my $part (@{$item{$Inline::CPP::Parser::RecDescent::class_decl}}) {
                  $_->{scope} = $item[1] for @$part;
          }
          $item{$Inline::CPP::Parser::RecDescent::class_decl}
        }
      | class_decl(s)
            {
          for my $part (@{$item[1]}) {
                  $_->{scope} = $thisparser->{data}{defaultscope}
            for @$part;
          }
          $item[1]
        }

class_decl: comment { [{thing => 'comment'}] }
          | typedef { [ handle_typedef($thisparser, $item[1]) ] }
          | enum { [ handle_enum($thisparser, $item[1]) ] }
          | class_def
            {
               my ($class, $parts) = handle_class_def($thisparser, $item[1]);
               [{ thing => 'class', name => $class, body => $parts }];
            }
          | method_def
        {
              $item[1]->{thing} = 'method';
#         print "class_decl found a method: $item[1]->{name}\n";
          my $i=0;
          for my $arg (@{$item[1]->{args}}) {
        $arg->{name} = 'dummy' . ++$i unless defined $arg->{name};
          }
          Inline::CPP::Parser::RecDescent::strip_ellipsis($thisparser,
                           $item[1]->{args});
          [$item[1]];
        }
          | member_def
        {
#         print "class_decl found one or more members:\n", Dumper(\@item);
              $_->{thing} = 'member' for @{$item[1]};
          $item[1];
        }

function_def: operator <commit> ';'
              {
                   $item[1]
              }
            | operator <commit> smod(?) code_block
              {
                  $item[1]
              }
            | IDENTIFIER '(' <commit> <leftop: arg ',' arg>(s?) ')' smod(?) code_block
              {
                {name => $item{IDENTIFIER}, args => $item{__DIRECTIVE2__}, rtype => '' }
              }
            | rtype IDENTIFIER '(' <leftop: arg ',' arg>(s?) ')' ';'
              {
                {rtype => $item[1], name => $item[2], args => $item{__DIRECTIVE1__} }
              }
            | rtype IDENTIFIER '(' <leftop: arg ',' arg>(s?) ')' smod(?) code_block
              {
                {rtype => $item{rtype}, name => $item[2], args => $item{__DIRECTIVE1__} }
              }

method_def: operator <commit> method_imp
            {
#               print "method operator:\n", Dumper $item[1];
               $item[1];
            }

          | IDENTIFIER '(' <commit> <leftop: arg ',' arg>(s?) ')' method_imp
            {
#         print "con-/de-structor found: $item[1]\n";
              {name => $item[1], args => $item{__DIRECTIVE2__}, abstract => ${$item{method_imp}} };
            }
          | rtype IDENTIFIER '(' <leftop: arg ',' arg>(s?) ')' method_imp
            {
#         print "method found: $item[2]\n";
          $return =
                {name => $item[2], rtype => $item[1], args => $item[4],
             abstract => ${$item[6]},
                 rconst => $thisparser->{data}{smod}{const},
                };
          $thisparser->{data}{smod}{const} = 0;
            }

operator: rtype(?) 'operator' /\(\)|[^()]+/ '(' <leftop: arg ',' arg>(s?) ')'
          {
#            print "Found operator: $item[1][0] operator $item[3]\n";
            {name=> "operator $item[3]", args => $item[5], ret => $item[1][0]}
          }

# By adding smod, we allow 'const' member functions. This would also bind to
# incorrect C++ with the word 'static' after the argument list, but we don't
# care at all because such code would never be compiled successfully.

# By adding init, we allow constructors to initialize references. Again, we'll
# allow them anywhere, but our goal is not to enforce c++ standards -- that's
# the compiler's job.
method_imp: smod(?) ';' { \0 }
          | smod(?) '=' <commit> '0' ';' { \1 }
          | smod(?) initlist(?) code_block { \0 }
          | smod(?) '=' '0' code_block { \0 }

initlist: ':' <leftop: subexpr ',' subexpr>

member_def: anytype <leftop: var ',' var> ';'
            {
          my @retval;
          for my $def (@{$item[2]}) {
              my $type = join '', $item[1], @{$def->[0]};
          my $name = $def->[1];
#             print "member found: type=$type, name=$name\n";
          push @retval, { name => $name, type => $type };
          }
          \@retval;
            }

var: star(s?) IDENTIFIER '=' expr { [@item[1,2]] }
   | star(s?) IDENTIFIER '[' expr ']' { [@item[1,2]] }
   | star(s?) IDENTIFIER          { [@item[1,2]] }

arg: type IDENTIFIER '=' expr
     {
#       print "argument $item{IDENTIFIER} found\n";
#       print "expression: $item{expr}\n";
    {type => $item[1], name => $item{IDENTIFIER}, optional => 1,
     offset => $thisoffset}
     }
   | type IDENTIFIER
     {
#       print "argument $item{IDENTIFIER} found\n";
       {type => $item[1], name => $item{IDENTIFIER}, offset => $thisoffset}
     }
   | type { {type => $item[1]} }
   | '...'
     { {name => '...', type => '...', offset => $thisoffset} }

ident_part: /[~_a-z]\w*/i '<' <commit> <leftop: IDENTIFIER ',' IDENTIFIER>(s?) '>'
        {
       $item[1].'<'.join('', @{$item[4]}).'>'
        }

      | /[~_a-z]\w*/i
        {
           $item[1]
        }

IDENTIFIER: <leftop: ident_part '::' ident_part>
        {
              my $x = join '::', @{$item[1]};
#              print "IDENTIFIER: $x\n";
              $x
        }

# Parse::RecDescent is retarded in this one case: if a subrule fails, it
# gives up the entire rule. This is a stupid way to get around that.
rtype: rtype2 | rtype1
rtype1: TYPE star(s?)
        {
         $return = $item[1];
         $return .= join '',' ',@{$item[2]} if @{$item[2]};
#    print "rtype1: $return\n";
#          return undef
#            unless(defined$thisparser->{data}{typeconv}{valid_rtypes}{$return});
        }
rtype2: modifier(s) TYPE star(s?)
    {
         $return = $item[2];
         $return = join ' ',grep{$_}@{$item[1]},$return
           if @{$item[1]};
         $return .= join '',' ',@{$item[3]} if @{$item[3]};
#    print "rtype2: $return\n";
#          return undef
#            unless(defined$thisparser->{data}{typeconv}{valid_rtypes}{$return});
     $return = 'static ' . $return
       if $thisparser->{data}{smod}{static};
         $thisparser->{data}{smod}{static} = 0;
    }

type: type2 | type1
type1: TYPE star(s?)
        {
         $return = $item[1];
         $return .= join '',' ',@{$item{$Inline::CPP::Parser::RecDescent::star}} if @{$item{$Inline::CPP::Parser::RecDescent::star}};
#    print "type1: $return\n";
#          return undef
#            unless(defined$thisparser->{data}{typeconv}{valid_types}{$return});
        }
type2: modifier(s) TYPE star(s?)
    {
         $return = $item{TYPE};
         $return = join ' ',grep{$_}@{$item[1]},$return if @{$item[1]};
         $return .= join '',' ',@{$item{$Inline::CPP::Parser::RecDescent::star}} if @{$item{$Inline::CPP::Parser::RecDescent::star}};
#    print "type2: $return\n";
#          return undef
#            unless(defined$thisparser->{data}{typeconv}{valid_types}{$return});
    }

anytype: anytype2 | anytype1
anytype1: TYPE star(s?)
         {
           $return = $item[1];
           $return .= join '',' ',@{$item[2]} if @{$item[2]};
         }
anytype2: modifier(s) TYPE star(s?)
         {
           $return = $item[2];
           $return = join ' ',grep{$_}@{$item[1]},$return if @{$item[1]};
           $return .= join '',' ',@{$item[3]} if @{$item[3]};
         }

comment: m{\s* // [^\n]* \n }x
       | m{\s* /\* (?:[^*]+|\*(?!/))* \*/  ([ \t]*)? }x

# long and short aren't recognized as modifiers because they break when used
# as regular types. Another Parse::RecDescent problem is greedy matching; I
# need tmodifier to "give back" long or short in cases where keeping them would
# cause the modifier rule to fail. One side-effect is 'long long' can never
# be parsed correctly here.
modifier: tmod
        | smod { ++$thisparser->{data}{smod}{$item[1]}; ''}
    | nmod { '' }
tmod: 'unsigned' # | 'long' | 'short'
smod: 'const' | 'static'
nmod: 'extern' | 'virtual' | 'mutable' | 'volatile' | 'inline'

scope: 'public' | 'private' | 'protected'

class: 'class' { $thisparser->{data}{defaultscope} = 'private'; $item[1] }
     | 'struct' { $thisparser->{data}{defaultscope} = 'public'; $item[1] }

star: '*' | '&'

code_block: /$Inline::CPP::Parser::RecDescent::code_block/

# Consume expressions
expr: <leftop: subexpr OP subexpr> {
    my $o = join '', @{$item[1]};
#   print "expr: $o\n";
    $o;
}
subexpr: /$Inline::CPP::Parser::RecDescent::funccall/ # Matches a macro, too
       | /$Inline::CPP::Parser::RecDescent::string/
       | /$Inline::CPP::Parser::RecDescent::number/
       | UOP subexpr
OP: '+' | '-' | '*' | '/' | '^' | '&' | '|' | '%' | '||' | '&&'
UOP: '~' | '!' | '-' | '*' | '&'

TYPE: IDENTIFIER

all: /.*/

END
}

#============================================================================
# Generate typemap code for the classes and structs we bind to. This allows
# functions declared after a class to return or accept class objects as
# parameters.
#============================================================================
$TYPEMAP_KIND = 'O_Inline_CPP_Class';

sub typemap {
  my ($parser, $typename) = @_;

#    print "Inline::CPP::Parser::RecDescent::typemap(): typename=$typename\n";

  my ($TYPEMAP, $INPUT, $OUTPUT);
  $TYPEMAP = "$typename *\t\t$TYPEMAP_KIND\n";
  $INPUT   = <<"END";
    if (sv_isobject(\$arg) && (SvTYPE(SvRV(\$arg)) == SVt_PVMG)) {
        \$var = (\$type)SvIV((SV*)SvRV( \$arg ));
    }
    else {
        warn ( \\"\${Package}::\$func_name() -- \$var is not a blessed reference\\" );
        XSRETURN_UNDEF;
    }
END
  $OUTPUT = <<"END";
    sv_setref_pv( \$arg, CLASS, (void*)\$var );
END

  my $ctypename = $typename . ' *';
  $parser->{data}{typeconv}{input_expr}{$TYPEMAP_KIND}  ||= $INPUT;
  $parser->{data}{typeconv}{output_expr}{$TYPEMAP_KIND} ||= $OUTPUT;
  $parser->{data}{typeconv}{type_kind}{$ctypename} = $TYPEMAP_KIND;
  $parser->{data}{typeconv}{valid_types}{$ctypename}++;
  $parser->{data}{typeconv}{valid_rtypes}{$ctypename}++;
  return;
}

#============================================================================
# Default action is to strip ellipses from the C++ code. This allows having
# _only_ a '...' in the code, just like XS. It is the default.
#============================================================================
sub strip_ellipsis {
  my ($parser, $args) = @_;
  return if $parser->{ILSM}{PRESERVE_ELLIPSIS};
  for (my $i = 0; $i < @$args; $i++) {
    next unless $args->[$i]{name} eq '...';

    # if it's the first one, just strip it
    if ($i == 0) {
      substr($parser->{ILSM}{code}, $args->[$i]{offset} - 3, 3, '   ');
    }
    else {
      my $prev        = $i - 1;
      my $prev_offset = $args->[$prev]{offset};
      my $length      = $args->[$i]{offset} - $prev_offset;
      substr($parser->{ILSM}{code}, $prev_offset, $length) =~ s/\S/ /g;
    }
  }
  return;
}

my $hack = sub { # Appease -w using Inline::Files
    print Parse::RecDescent::IN '';
    print Parse::RecDescent::IN '';
    print Parse::RecDescent::TRACE_FILE '';
    print Parse::RecDescent::TRACE_FILE '';
};

1;

=head1 Inline::CPP::Parser::RecDescent

All functions are internal.  No documentation necessary.

=cut
