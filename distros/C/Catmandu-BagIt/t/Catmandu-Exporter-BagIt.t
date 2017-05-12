#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;
use File::Path qw(remove_tree);
use Test::LWP::UserAgent;
use Catmandu::Importer::BagIt;

my $pkg;
BEGIN {
	$pkg = 'Catmandu::Exporter::BagIt';
	use_ok $pkg;
};
require_ok $pkg;

my $exporter = $pkg->new(user_agent => user_agent());

isa_ok $exporter, $pkg;

throws_ok {
	$exporter->add({
		_id => 'bags/demo01'
	});
} 'Catmandu::Error' , qq|caught an error|;

ok $exporter->add({
	_id   => 't/my-bag' ,
	tags  => { 'Foo' => 'Bar' } ,
	fetch => [ { 'http://demo.org/' => 'data/poem.txt'} ] ,
}) , qq|created t/my-bag bag|;

ok $exporter->commit , 'commit';

ok -r 't/my-bag/data/poem.txt' , 'we got a poem.txt';

my $importer = Catmandu::Importer::BagIt->new( bags => ['t/my-bag'] , verify => 1 , include_manifests => 1);

ok $importer , 'created importer';

my $first = $importer->first;

ok $first , 'found the first bag';

is $first->{tags}->{'Foo'} , 'Bar' , 'a Foo is a Bar';

is $first->{is_valid} , 1 , 'the bag is valid';

ok $first->{version} , 'checking version bug';

ok exists $first->{manifest}->{'data/poem.txt'} , 'found a manifest';

done_testing 13;
 
sub user_agent  {
    my $ua = Test::LWP::UserAgent->new(agent => 'Test/1.0');

    my $text =<<EOF;
Roses are red,
Violets are blue,
Sugar is sweet,
And so are you.
EOF

    $ua->map_response(
        qr{^http://demo.org/$},
        HTTP::Response->new(
            '200' ,
            'OK' ,
            [ 'Content-Type' => 'text/plain'] ,
            $text
        )
    );

    $ua;
}

END {
	my $error = [];
	# Stupid chdir trick to make remove_tree work
	chdir("lib");
	remove_tree('../t/my-bag', { error => \$error });
	print STDERR join("\n",@$error) , "\n" if @$error > 0;;
};
