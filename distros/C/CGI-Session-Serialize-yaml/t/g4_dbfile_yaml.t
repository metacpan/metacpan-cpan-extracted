# $Id$

use strict;
use diagnostics;

use Test::More;
use File::Spec;
use CGI::Session::Test::Default;

our %serializers;

our %options = (
    'YAML'            =>  {   },
    'YAML::Syck'      =>  { skip    =>  [101]   },
);

plan skip_all => 'DB_File is NOT available' unless eval { require DB_File };

foreach my $i (keys(%options)) {
    $serializers{$i}++ if eval "use $i (); 1";
}

delete $serializers{YAML} if exists $serializers{YAML} && YAML->VERSION < 0.58;

unless(%serializers) {
    plan skip_all => "Neither YAML or YAML::Syck are available";
}

my @test_objects;

while(my($k, $v) = each(%serializers)) {
    push(@test_objects, CGI::Session::Test::Default->new(
        dsn => "d:DB_File;s:YAML;id:md5",
        args => {
            FileName => File::Spec->catfile('t', 'sessiondata', 'cgisess.db'),
        },
        %{$options{$k}},
        __testing_serializer => $k,
    ));
}

my $tests = 0;
$tests += $_->number_of_tests foreach @test_objects;
plan tests => $tests;

foreach my $to (@test_objects) {
    $CGI::Session::Serialize::yaml::Flavour = $to->{__testing_serializer};
    diag($CGI::Session::Serialize::yaml::Flavour);
    $to->run();
}
