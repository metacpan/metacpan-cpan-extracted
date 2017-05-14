#!perl -T

use Test::More tests => 13;
use Test::File;

use Conclave::OTK;
use File::Temp qw/tempfile tempdir/;

my $base_uri = 'http://local/example';
my $rdfxml = Conclave::OTK::empty_owl($base_uri);
my (undef, $filename) = tempfile('onto_test_XXXXXXXX', TMPDIR=>1, SUFFIX=>'.rdf', OPEN=>0, );

my $onto = Conclave::OTK->new($base_uri,
               backend => 'File',
               filename => $filename
             );
$onto->init($rdfxml);

my $onto2 = Conclave::OTK->new($base_uri, 
               backend => 'File',
               ignoreconfigfile => 1,
             );
is( $onto2->{backend}->{filename}, 'model.xml', 'default file name');

my @classes = sort $onto->get_classes;
is( scalar(@classes), 0, 'start with no classes' );

# add classes
$onto->add_class('Person','<http://www.w3.org/2002/07/owl#Thing>');

# add classes with parents
$onto->add_class('Female', 'Person');
$onto->add_class('Male', 'Person');

@classes = sort $onto->get_classes;
is_deeply( [@classes], ["$base_uri#Female","$base_uri#Male","$base_uri#Person"], 'classes' );

my @subs = sort $onto->get_subclasses('Person');
is_deeply( [@subs], ["$base_uri#Female","$base_uri#Male"], 'sub-classes' );

$onto->add_instance('Ann', 'Female');
$onto->add_instance('Peter', 'Male');

my @females = $onto->get_instances('Female');
is_deeply( [@females], ["$base_uri#Ann"], 'instances' );
my @males = $onto->get_instances('Male');
is_deeply( [@males], ["$base_uri#Peter"], 'instances' );

$onto->add_obj_prop('Ann', 'hasParent', 'Peter');

my @props = $onto->get_obj_props('Ann');
is_deeply( [@props], [["$base_uri#Ann","$base_uri#hasParent","$base_uri#Peter"]], 'object proprieties' );
my @props = $onto->get_obj_props('Peter');
is_deeply( [@props], [["$base_uri#Ann","$base_uri#hasParent","$base_uri#Peter"]], 'object proprieties' );

$onto->add_data_prop('Ann', 'hasAge', '4', 'int');
$onto->add_data_prop('Peter', 'hasAge', '28', 'int');

@props = $onto->get_data_props('Ann');
is_deeply( [@props], [["$base_uri#Ann","$base_uri#hasAge","4"]], 'data proprieties' );

@props = $onto->get_data_props('Peter');
is_deeply( [@props], [["$base_uri#Peter","$base_uri#hasAge","28"]], 'data proprieties' );

my $expect = { 'http://www.w3.org/2002/07/owl#Thing' => { "$base_uri#Person" => { "$base_uri#Female" => undef, "$base_uri#Male" => undef } } };
my $tree = $onto->get_class_tree;
is_deeply( $tree, $expect, 'class tree' );

@els = $onto->get_obj_props_for('hasParent', 'Peter');
is_deeply( [@els], ["$base_uri#Ann"], 'get obj props for' );

$onto->delete;
file_not_exists_ok($filename);

