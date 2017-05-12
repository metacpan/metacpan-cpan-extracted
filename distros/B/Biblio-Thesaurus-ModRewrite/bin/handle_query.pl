#!/usr/bin/perl -w

use FindBin qw($Bin);
use lib "$Bin/../lib";

$ARGV[0] ~~ m/select ([\w,]+) FROM ([^\s]+) WHERE ([^;]+);/i;
my @vars = split /,/, $1;
my $ont = $2;
my $code = $3;

foreach (@vars) { $code =~ s/(\b$_\b)/\$$_/g; }

my $str = '';
foreach (@vars) {
    $str .= "$_=\$$_ ";
}

$code .= " => sub{{print \"$str\\n\";}}.";
print STDERR "\n-----\n$code\n-----\n";

use Biblio::Thesaurus;
use Biblio::Thesaurus::ModRewrite;

my $obj = thesaurusLoad("examples/$ont");
$t = Biblio::Thesaurus::ModRewrite->new($obj);
$t->process($code)

