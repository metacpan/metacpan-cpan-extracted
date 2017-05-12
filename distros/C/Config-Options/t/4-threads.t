#!/usr/bin/perl -w
use strict;

use Test::More;
use Config;

use 5.008;
BEGIN { 
   if ($Config{usethreads}) {
	   plan tests => 7;
   }
   else {
	   plan skip_all => "Perl ithreads required" unless $Config{usethreads};
   }
   use_ok('threads') ;
   use_ok('Config::Options') ;

};





sub set_options_a {
	my $opts = shift;
	$opts->deepmerge({ hash => { wine => { green => "weird" } } });
}

sub set_options_b {
	my $opts = shift;
	$opts->deepmerge({ hash => { wine => { pink => "silly" } } });
}

sub set_options_c {
	my $opts = shift;
	$opts->deepmerge({ mood => "happy" }); 
}

sub watch_options {
	my $opts = shift;
	while ($opts->{mood} eq "sardonic") {
		sleep 1;
	}
}

my $options = Config::Options->new(
	{ verbose => 1, 
		optionb => 2, 
		mood => "sardonic", 
		hash => { beer =>  "good", 
			whiskey => "bad", 
			wine => { 
				red => "good", 
				white => "bad" 
			}
		}
	});

ok (defined $options,                    'Object created');

my $thread1 = threads->new(\&set_options_a, $options);
my $thread2 = threads->new(\&set_options_b, $options);
my $thread3 = threads->new(\&watch_options, $options);
sleep 1;
my $thread4 = threads->new(\&set_options_c, $options);
$thread1->join;
$thread2->join;
$thread3->join;
$thread4->join;

ok ($options->isa('Config::Options::Threaded'),    'Correct Class');
is ($options->{hash}->{wine}->{green}, "weird",     'value test 1');
is ($options->{hash}->{wine}->{pink}, "silly",      'value test 2');
is ($options->{mood}, "happy",      'value test 2');




