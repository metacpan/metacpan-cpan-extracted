use strict;
use warnings;
#use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 8;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::WWW::Mechanize::Catalyst 'TestAtompub';

use Atompub::MediaType qw(media_type);
use XML::Atom::Service;

my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('/service');

ok media_type( $mech->res->content_type )->is_a('service');

my $serv = XML::Atom::Service->new(\$mech->res->content);
isa_ok $serv, 'XML::Atom::Service';

my @work = $serv->workspaces;
is @work, 1;
is $work[0]->title, 'TestAtompub';

my @coll = $work[0]->collections;
is @coll, 1;

is $coll[0]->title, 'Collection';
is $coll[0]->href, 'http://localhost/collection';
