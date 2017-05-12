#!/usr/bin/perl -w
use strict;

use Test::More tests => 18;
use File::Temp;
use 5.006;


BEGIN { use_ok('Config::Options') };

my $options = Config::Options->new(
	{ verbose => 1, 
		optionb => 2, 
		mood => "sardonic", 
		hash => { beer =>  "good", 
			whiskey => "bad", 
			wine => { 
				red => "good", 
				white => "bad", 
			},
		}
	});

ok (defined $options,                    'Object created');
ok (($options->isa('Config::Options::Threaded') or ($options->isa('Config::Options'))),    'Correct Class');
is ($options->{mood},  "sardonic",		 'Value test');
ok ($options->deepmerge({hash => { soda => "fizzy", wine => { green => "weird"} }}), 'deepmerge test');
is ($options->{hash}->{beer}, "good",    'deepmerge value test 1');
is ($options->{hash}->{soda}, "fizzy",    'deepmerge value test 2');
is ($options->{hash}->{wine}->{red}, "good",    'deepmerge value test 3');
is ($options->{hash}->{wine}->{green}, "weird",    'deepmerge value test 4');
	$options->deepmerge({
			hash => { wine => 
				$options->{"hash"}
			}
		} );
is ($options->{hash}->{wine}->{green}, "weird",    'deepmerge anti-self ref test');
my ($d, $o);
ok ($d = $options->serialize,	         'Serializing Data');
ok ($o = $options->deserialize($d), 	 'Deserializing Data');
is ($o->{optionb}, 2,					 'Deserialized Test');
my ($fh, $tmpfile) = File::Temp::tempfile;
SKIP: {
	skip "Can't write to temp file", 4 unless (-w $fh);
	close $fh;
	$options->options({optionfile => [ $tmpfile ]});
	ok ($options->tofile_perl,			     'Save to tmpfile');
	$options->{mood} = "thrilled";
	ok ($options->fromfile_perl, 			 'Retrieve from tmpfile');
	is ($options->{mood}, "sardonic");
	ok ($options->fromfile_perl, 			 'Retrieve from tmpfile again');
	ok (unlink($options->{optionfile}->[0]), 'unlink tmpfile');
}


