#!perl
use strict;
use Test2::V0;

use App::PerlNitpick::Rule::RemoveEffectlessUTF8Pragma;

my $code = <<CODE;
use strict;use utf8;
print 42;
use  utf8;
CODE

my $doc = PPI::Document->new(\$code);
my $o = App::PerlNitpick::Rule::RemoveEffectlessUTF8Pragma->new();
my $doc2 = $o->rewrite($doc);
my $code2 = "$doc2";

ok $code2 !~ m/^\s?use\s+utf8\s+;/s;

done_testing;

