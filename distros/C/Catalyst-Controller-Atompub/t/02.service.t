use strict;
use warnings;
#use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 18;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::WWW::Mechanize::Catalyst 'TestAtompub';

use Atompub::MediaType qw(media_type);
use XML::Atom::Service;

TestAtompub->config->{'Controller::Service'} = {
    workspace => [{
        title => 'My Blog',
        collection => [qw(Controller::Collection)],
    }]
};

TestAtompub->config->{'Controller::Collection'} = {
    collection => {
        title => 'Diary',
        categories => [{
            fixed => 'yes',
            scheme => 'http://example.com/cats/big3',
            category => [
                { term => 'animal', label => 'animal' },
                { term => 'vegetable', label => 'vegetable' },
                { term => 'mineral', scheme => 'http://example.com/dogs/big3', label => 'mineral' },
            ],
        }],
    }
};

my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('/service');

ok media_type($mech->res->content_type)->is_a('service');

my $serv = XML::Atom::Service->new(\$mech->res->content);
isa_ok $serv, 'XML::Atom::Service';

my @work = $serv->workspaces;
is @work, 1;
is $work[0]->title, 'My Blog';

my @coll = $work[0]->collections;
is @coll, 1;

is $coll[0]->title, 'Diary';
is $coll[0]->href, 'http://localhost/collection';

my @cats = $coll[0]->categories;
is @cats, 1;

is $cats[0]->fixed, 'yes';
is $cats[0]->scheme, 'http://example.com/cats/big3';

my @cat = $cats[0]->category;
is @cat, 3;

is $cat[0]->term, 'animal';
is $cat[0]->label, 'animal';
is $cat[1]->term, 'vegetable';
is $cat[1]->label, 'vegetable';
is $cat[2]->term, 'mineral';
is $cat[2]->scheme, 'http://example.com/dogs/big3';
