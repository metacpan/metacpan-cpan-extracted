#!/usr/bin/perl -w
use strict;

use lib 'lib';
use Test::More tests => 25;
use IO::File;

use CPAN::Testers::Common::Article;

my @files = (
    't/nntp/bad-001.txt',
    't/nntp/bad-002.txt',
    't/nntp/bad-003.txt',
);

for my $file (@files) {
    my $article = readfile($file);
    $a = CPAN::Testers::Common::Article->new($article);
    isa_ok($a,'CPAN::Testers::Common::Article',"Article object created for file '$file'");
    ok(!$a->parse_report());
}

@files = (
    't/nntp/bad-004.txt',
    't/nntp/bad-005.txt',
    't/nntp/bad-006.txt',
    't/nntp/bad-007.txt',
    't/nntp/bad-008.txt',
);

for my $file (@files) {
    my $article = readfile($file);
    $a = CPAN::Testers::Common::Article->new($article);
    isa_ok($a,'CPAN::Testers::Common::Article',"Article object created for file '$file'");
    ok($a->parse_report());
    is($a->from, '');
}

@files = (
    't/nntp/bad-009.txt',   # broken email
    't/nntp/bad-010.txt',   # missing subject
    't/nntp/1805500.txt',   # In-Reply_to header found
    't/nntp/bad-011.txt',   # subject contains a module name, not a distribution
);

for my $file (@files) {
    my $article = readfile($file);
    $a = CPAN::Testers::Common::Article->new($article);
    is($a,undef,"no Article object created for file '$file'");
}

sub readfile {
    my $file = shift;
    my $text;
    my $fh = IO::File->new($file)   or return;
    while(<$fh>) { $text .= $_ }
    $fh->close;
    return $text;
}
