use lib 't';
use lib '.';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 7;
}
use Data::Stag qw(:all);
use Data::Stag::Arr2HTML;
use Data::Stag::null;
use FileHandle;
use strict;
use Data::Dumper;

eval {
    require "XML/Parser/PerlSAX.pm";
};
if ($@) {
    for (1..7) {
        skip("XML::Parser::PerlSAX not installed",1);
    }
    exit 0;
}
eval {
    require "XML/Handler/XMLWriter.pm";
};
if ($@) {
    for (1..7) {
        skip("XML::Handler::XMLWriter not installed",1);
    }
    exit 0;
}

my $tree =
  [top => [
           [
            personset => [
                         [person => [
                                     [ name => 'shuggy' ],
                                     [ job => 'bus driver' ],
                                     [ age => '55' ],
                                    ],
                         ],
                         [person => [
                                     [ name => 'tam' ],
                                     [ job  => 'forklift driver' ],
                                     [ favourite_food => 'chips' ],
                                    ],
                         ],
                         ],
           ],
          ],
  ];

my ($fh, $handler, $writer);
$fh = FileHandle->new(">t/z.xml");
$writer = XML::Handler::XMLWriter->new(Output=>$fh);
#my $writer = XML::Handler::XMLWriter->new();
stag_sax($tree, $writer);

$fh = FileHandle->new(">qq");
$writer = XML::Handler::XMLWriter->new();
#my $handler = Data::Stag::Base->new(Handler=>$writer2);
#my $handler = Data::Stag::Base->new(Handler=>$writer);
#print Dumper [stag_findnode($tree, "personset")];
my @p = stag_findnode($tree, "person");
map {stag_sax($_, $writer)} @p;
ok(@p==2);
#print Dumper $handler;
#die;

#my $null = Data::Stag::null->new();
#my $html = Data::Stag::Arr2HTML->new(Handler=>$null);
#$handler = Data::Stag::SAX2NestArray->new(Handler=>$html);
#tree2sax($tree, $handler);
#

my $na = stag_from("xml", "t/z.xml");
my %h = stag_hash($na);
print Dumper \%h;

print stag_xml($tree);

# test replacement
stag_findnode($tree, "age", [age_months=>100]);
print stag_xml($tree);
print "checking..\n";
@p = grep {stag_findval($_, "name") eq ("shuggy") } stag_findnode($tree, "person");
map {print stag_xml($_)} @p;
ok((stag_findval($p[0], "age_months")) == (100));

my @names = stag_findval($tree, "person/name");
ok("@names" eq "shuggy tam");

@p =
  stag_where($tree, 
             "person",
             sub {stag_tmatch(shift, "job", "forklift driver")});
print stag_xml(@p);
ok(stag_tmatch($p[0], "name", "tam"));
ok(stag_tmatch($p[0], "job", "forklift driver"));
ok(!stag_tmatch($p[0], "name", "jim"));

# replace bus driver with new node
stag_where($tree, 
           "person",
           sub {
               stag_tmatch(shift, "job", 'bus driver'),
           },
           [person=>[[name=>'yyy']]]);
print stag_xml($tree);
@p = stag_findnode($tree, "person");
ok(grep { stag_tmatch($_, "name", "yyy") } @p);
