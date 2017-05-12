use strict;
use warnings;
use Test::Base;
use File::Spec;

use Data::CodeRepos::CommitPing;

plan tests => 1*blocks;

filters {
    input    => [qw/get_revision/],
};

sub get_revision {
    my $path = File::Spec->catfile('t', 'revs', shift);
    open my $fh, '<', $path or die $!;
    Data::CodeRepos::CommitPing->new(do { local $/; <$fh> })->changes_base;
}

run_is input => 'expected';

__END__

===
--- input: 9734.txt
--- expected: lang/perl/Attribute-TieClasses

===
--- input: 9741.txt
--- expected: lang/perl/Class-Accessor-Bundle

===
--- input: 9749.txt
--- expected: lang/perl/Class-Value-SemanticAdapter

===
--- input: 9754.txt
--- expected: lang/perl/Data-Comparable

===
--- input: 9879.txt
--- expected: lang/perl/Jipotter

===
--- input: 9895.txt
--- expected: lang/perl/Moxy

===
--- input: 9906.txt
--- expected: websites/coderepos.org

===
--- input: dumy1.txt
--- expected: lang/perl/misc/dumy.pl

===
--- input: dumy2.txt
--- expected: lang/php/ARGF

===
--- input: userscripts1.txt
--- expected: lang/javascript/userscripts/hatena.bookmark.button-search-now.user.js
