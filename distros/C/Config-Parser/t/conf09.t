# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use ConfigSpec2;
use ConfigSpec3;

plan(tests => 2);

my $c2 = new ConfigSpec2;
my $c3 = new ConfigSpec3;

ok($c2->canonical_lexicon,
   q{{"core" => {"section" => {"base" => {"default" => "null","mandatory" => 1}}},"load" => {"section" => {"*" => {"section" => {"param" => {"mandatory" => 1,"section" => {"mode" => {"re" => "^[0-7]+\$"},"owner" => {}}}}}}}}});

ok($c3->canonical_lexicon,
   q{{"core" => {"section" => {"root" => {"mandatory" => 1}}},"dir" => {"section" => {"diag" => {},"store" => {},"temp" => {}}}}});



