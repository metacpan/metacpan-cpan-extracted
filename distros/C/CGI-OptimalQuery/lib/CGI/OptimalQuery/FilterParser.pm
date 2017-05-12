package CGI::OptimalQuery::FilterParser;

use strict;
use warnings;
no warnings qw( uninitialized );

# arguments: ($CgiOptimalQueryObjecto, $filterString)
# return value: is an arrayref contain zero or more components that look like:
#       # logic operator
#  'AND'|'OR',      # logic operator
#       # type 1 - (selectalias operator literal)
#  [1,$numLeftParen,$leftExpSelectAlias,$op,$rightExpLiteral,$numRightParen],
#       # type 2 - (namedfilter, arguments)
#  [2,$numLeftParen,$namedFilter,$argArray,$numRightParen]
#       # type 3 - (selectalias operator selectalias)
#  [3,$numLeftParen,$leftExpSelectAlias,$op,$rightExpSelectAlias,$numRightParen],
# dies on bad filter string
sub parseFilter {
  # $o is optimalquery object, $f is the filter string
  my ($o, $f) = @_;
  $f =~ /\G\s+/gc; # match all leading whitespace

  # initialize the return value which is an array of components
  my @rv;
  return \@rv if $f eq '';
  
  while (1) {
    my $numLeftParenthesis  = 0;
    my $numRightParenthesis = 0;

    # parse opening parenthesis
    while ($f =~ /\G\(\s*/gc) { $numLeftParenthesis++; }

    # if this looks like a named filter
    if ($f=~/\G(\w+)\s*\(\s*/gc) { 
      my $namedFilter = $1;
      die "Invalid named filter $namedFilter at: ".substr($f, 0, pos($f)).' <*> '.substr($f,pos($f))
        unless exists $$o{schema}{named_filters}{$namedFilter};

      # parse named filter arguments
      my @args;
      while (1) {
        # closing paren so end
        if ($f=~/\G\)\s*/gc) {
          last;
        }

        # single quoted value OR double quoted value OR no whitespace literal
        elsif ($f=~/\G\'([^\']*)\'\s*/gc || $f=~/\G\"([^\"]*)\"\s*/gc || $f=~/\G(\w+)\s*/gc) {
          push @args, $1;
        }

        # , => : separator so do nothing
        elsif ($f =~ /\G(\,|\=\>|\:)\s*/gc) {
          # noop
        }
        else {
          die "Invalid named filter $namedFilter - missing right paren at: ".substr($f, 0, pos($f)).' <*> '.substr($f,pos($f));
        }
      }

      # parse closing parenthesis
      while ($f =~ /\G\)\s*/gc) { $numRightParenthesis++; }
      push @rv, [2,$numLeftParenthesis,$namedFilter,\@args,$numRightParenthesis];
    }

    # else this is an expression
    else {
      my $lexp;
      my $typeNum = 1;

      # grab select alias used on the left side of the expression
      if ($f=~/\G\[([^\]]+)\]\s*/gc || $f=~/\G(\w+)\s*/gc) { $lexp = $1; }
      else { die 'Missing left expression: '.substr($f, 0, pos($f)).' <*> '.substr($f,pos($f)); }

      # make sure the select alias is valid
      die "Invalid field $lexp at: ".substr($f, 0, pos($f)).' <*> '.substr($f,pos($f))
        unless exists $$o{schema}{select}{$lexp};

      # parse the operator
      my $op;
      if ($f =~ /\G(\!\=|\=|\<\=|\>\=|\<|\>|like|not\ like|contains|not\ contains)\s*/igc) { $op = $1; }
      else { die 'Missing operator: '.substr($f, 0, pos($f)).' <*> '.substr($f,pos($f)); }

      # parse the right side of expression
      my $rexp;

      # if rexp is a select alias
      if ($f=~/\G\[([^\]]+)\]\s*/gc) {
        $rexp = $1;
        $typeNum = 3;
      }

      # else if rexp is a literal
      elsif ($f=~/\G\'([^\']*)\'\s*/gc || $f=~/\G\"([^\"]*)\"\s*/gc || $f=~/\G(\w+)\s*/gc) {
        $rexp = $1;
      }

      else { die 'Missing right expression: '.substr($f, 0, pos($f)).' <*> '.substr($f,pos($f)); }

      # parse closing parenthesis
      while ($f =~ /\G\)\s*/gc) { $numRightParenthesis++; }

      push @rv, [$typeNum, $numLeftParenthesis, $lexp, $op, $rexp, $numRightParenthesis];
    }

    # parse logic operator
    if ($f =~ /(AND|OR)\s*/gci) { push @rv, uc($1); }
    else { last; }
  }
  return \@rv;
}

1;
