#!perl
use strict;
use warnings;
use Cwd;
use File::Path;
use Test::More tests => 12;
use lib 'lib';
use_ok("CPAN::IndexPod");

my $unpacked   = cwd . "/t/unpacked";
my $kinosearch = cwd . "/t/kinosearch";

rmtree($kinosearch);
ok( !-d $kinosearch, "No $kinosearch at the start" );

my $i = CPAN::IndexPod->new(
    { unpacked => $unpacked, kinosearch => $kinosearch } );
$i->index;

ok( -d $kinosearch, "$kinosearch created" );

is_deeply( [ $i->search("orange") ], [], "orange" );

is_deeply(
    [ $i->search("xml") ],
    [   'GraphViz/lib/GraphViz/XML.pm', 'GraphViz/examples/redcarpet.pl',
        'GraphViz/examples/ppmgraph.pl'
    ],
    "xml"
);

is_deeply( [ $i->search("vampire") ],
    ['Acme-Buffy/lib/Acme/Buffy.pm'], "vampire" );

is_deeply( [ $i->search("encoding") ],
    ['Acme-Buffy/lib/Acme/Buffy.pm'], "encoding" );

is_deeply( [ $i->search("unsightly") ],
    ['Acme-Buffy/lib/Acme/Buffy.pm'], "unsightly" );

is_deeply(
    [ $i->search("first time") ],
    [   'Acme-Buffy/lib/Acme/Buffy.pm',
        'GraphViz/examples/redcarpet.pl',
        'GraphViz/lib/GraphViz/Parse/RecDescent.pm',
        'GraphViz/lib/GraphViz/Parse/Yacc.pm',
        'GraphViz/lib/GraphViz/Parse/Yapp.pm',
        'GraphViz/lib/GraphViz/Regex.pm',
    ],
    "first time"
);

is_deeply(
    [ $i->search("xml ximian") ],
    [   'GraphViz/examples/redcarpet.pl', 'GraphViz/lib/GraphViz/XML.pm',
        'GraphViz/examples/ppmgraph.pl'
    ],
    "xml ximian"
);

is_deeply(
    [ $i->search("+xml +ximian") ],
    [ 'GraphViz/examples/redcarpet.pl', ],
    "+xml +ximian"
);

is_deeply(
    [ $i->search('redcarpet') ],
    [   'GraphViz/examples/redcarpet.pl', 'GraphViz/examples/ppmgraph.pl',
        'GraphViz/lib/GraphViz.pm',
    ],
    "redcarpet.png"
);

#use YAML; die Dump [ $i->search('redcarpet.png') ];

