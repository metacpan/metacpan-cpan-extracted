#!/usr/local/bin/perl
use Test::More tests=>4;
use Test::Differences;
use App::SimpleScan;
use IO::ScalarArray;

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan --gen <examples/ss_garbage1.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
use Test::More tests=>0;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
# This is a file of garbage.
# Possible syntax error in this test spec
# None of this is a valid test.
# Possible syntax error in this test spec
# All of it will be skipped.
# Possible syntax error in this test spec
# No tests will be generated.
# Possible syntax error in this test spec

EOF
push @expected, "\n";
eq_or_diff(\@output, \@expected, "working output as expected");

@ARGV=qw(examples/ss_garbage2.in);
$app = new App::SimpleScan;
@output = map {"$_\n"} (split /\n/, ($app->create_tests));
@expected = map {"$_\n"} split /\n/,<<EOF;
use Test::More tests=>1;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
# Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Nam vestibulum tortor
# Possible syntax error in this test spec
# sit amet ante. Maecenas lobortis, est a consectetuer molestie, est nulla 
# Possible syntax error in this test spec
# gravida justo, et pulvinar dolor sem eget turpis. In massa sem, mollis non, 
# Possible syntax error in this test spec
# pulvinar sed, venenatis in, elit. Curabitur odio nunc, feugiat quis, tristique 
# Possible syntax error in this test spec
# ac, volutpat eget, elit. In eu risus. Quisque placerat, augue a vehicula 
# Possible syntax error in this test spec
# accumsan, est arcu rhoncus ligula, sagittis mollis libero ante aliquet risus. 
# Possible syntax error in this test spec
# Aenean sollicitudin adipiscing dolor. Phasellus dictum elit sed neque. Donec 
# Possible syntax error in this test spec
# tincidunt elit sit amet dolor. Aenean placerat lorem. Praesent vehicula pede 
# Possible syntax error in this test spec
# ac tortor rutrum fermentum. Sed accumsan. Fusce id dui at nulla sodales 
# Possible syntax error in this test spec
# dignissim. Aliquam quam erat, porta sit amet, molestie a, laoreet id, ante. 
# Possible syntax error in this test spec
# Maecenas tempor lectus congue ligula. Curabitur lacinia diam. Aliquam erat 
# Possible syntax error in this test spec
# volutpat.
# Possible syntax error in this test spec
page_like "http://perl.org/",
          qr/perl/,
          qq(Garbage lines were ignored [http://perl.org/] [/perl/ should match]);
# Donec lorem libero, dictum eget, tempus id, fringilla adipiscing, dolor. Donec 
# Possible syntax error in this test spec
# massa. Cras ullamcorper massa sit amet wisi. Donec eleifend, risus non 
# Possible syntax error in this test spec
# eleifend ornare, orci libero fringilla orci, luctus auctor tellus tortor ut 
# Possible syntax error in this test spec
# odio. Aliquam sit amet magna. Sed tristique bibendum libero. Sed dignissim 
# Possible syntax error in this test spec
# lobortis magna. Mauris posuere consectetuer odio. Maecenas metus velit, 
# Possible syntax error in this test spec
# accumsan vitae, laoreet vel, porttitor at, purus. Phasellus consectetuer pede 
# Possible syntax error in this test spec
# id velit. Fusce lobortis nisl non nibh. Nam ipsum lacus, tincidunt sit amet, 
# Possible syntax error in this test spec
# bibendum at, sollicitudin mollis, elit. Nam sollicitudin porta massa. Fusce at 
# Possible syntax error in this test spec
# elit. Etiam convallis enim molestie erat. Aenean dapibus nunc quis lorem. 
# Possible syntax error in this test spec
# Curabitur ullamcorper arcu non mi porta sodales. Sed feugiat sagittis mauris. 
# Possible syntax error in this test spec
# Pellentesque ullamcorper. Sed id wisi.
# Possible syntax error in this test spec
EOF
eq_or_diff(\@output, \@expected, "output as expected");

@output = `bin/simple_scan<examples/ss_garbage2.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
1..1
ok 1 - Garbage lines were ignored [http://perl.org/] [/perl/ should match]
EOF
eq_or_diff(\@output, \@expected, "ran as expected");

@output = `bin/simple_scan --gen --warn<examples/ss_garbage3.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
use Test::More tests=>4;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
# line break in it'
# Possible syntax error in this test spec
page_unlike "http://perl.org",
            qr/'this/,
            qq(Demo the linebreak message [http://perl.org] [/'this/ shouldn't match]);
page_unlike "http://perl.org",
            qr/line/,
            qq(Demo the linebreak message [http://perl.org] [/line/ shouldn't match]);
page_unlike "http://perl.org",
            qr/has/,
            qq(Demo the linebreak message [http://perl.org] [/has/ shouldn't match]);
page_unlike "http://perl.org",
            qr/a/,
            qq(Demo the linebreak message [http://perl.org] [/a/ shouldn't match]);

EOF

push @expected, "\n";
eq_or_diff(\@output, \@expected, "output as expected");
