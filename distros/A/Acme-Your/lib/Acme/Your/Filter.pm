package Acme::Your::Filter;
use strict;
use warnings;
use Filter::Simple;
use Parse::RecDescent;

FILTER_ONLY executable => \&_filter_code;

# it's also all on one line because I don't want to disturb the line
# numbers too much

use Data::Dumper;
sub _filter_code {
    s/\b((?:have|your)\b.*?;)/ _transform_statement( $1 ) /ge;
}

my $grammar = q
{
  list        :  identifier
              |  '(' plist ')'

  plist       : identifier ',' plist
              | identifier

  identifier  : /[@%\$]\w+/

  keyword     : 'your'
              | 'have'

  declaration : keyword list ';'
              | keyword list  '=' /[^;]+/ ';'
              | <error>
};

my $parse;

sub _transform_statement {
    my $statement = shift;

    $::RD_AUTOACTION = q{ [ @item ] };

    $parse ||= new Parse::RecDescent $grammar;
    my $tree = $parse->declaration($statement);

    my $pattern = $tree->[1][1] eq 'your' ? 'your' : 'have';

    my $assign;
    if ($tree->[-3] eq '=') {
        $assign = $tree->[-2];
    }

    my @ids = _walk_tree($tree);

    my $new_statement = join('', map { _variable_declaration($pattern, $_) } @ids );
    if ($assign) {
        $new_statement .= "(". join(', ', @ids) .") = $assign;";
    }
    #print $new_statement;
    return $new_statement;
}

sub _variable_declaration {
    my $keyword = shift;
    my $name    = shift;

    $name =~ s/^([\$@%])//;
    my $sigil = $1;

    if ($keyword eq 'your') {
        return
          join('',
               qq{ our $sigil$name; },
               qq{ local $sigil$Acme::Your::into\::$name  },
               qq{     = $sigil$Acme::Your::into\::$name; },
               qq{ *$name = \\$sigil$Acme::Your::into\::$name; },
              );
    }

    # have
    return join('',
                qq{ our $sigil$name; },
                qq{ local *$Acme::Your::into\::$name  = \\$sigil$name; },
               );
}

# extract identifiers from the parse tree
sub _walk_tree {
    my $tree = shift;

    my @id;
    push @id, $tree->[1] if $tree->[0] eq 'identifier';
    for (@$tree) {
        push @id, _walk_tree($_) if ref $_;

    }
    return @id;
}

1;
__END__

