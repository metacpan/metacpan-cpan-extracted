#!perl -T

use strict;
use warnings;
use Test::More tests => 7;
use Brannigan;

my $b = Brannigan->new(
	{
		name => 'post',
		ignore_missing => 1,
		params => {
			subject => {
				required => 1,
				length_between => [3, 40],
			},
			text => {
				required => 1,
				min_length => 10,
				validate => sub {
					my $value = shift;

					return undef unless $value;
					
					return $value =~ m/^lorem ipsum/ ? 1 : undef;
				}
			},
			day => {
				required => 0,
				integer => 1,
				value_between => [1, 31],
			},
			mon => {
				required => 0,
				integer => 1,
				value_between => [1, 12],
			},
			year => {
				required => 0,
				integer => 1,
				value_between => [1900, 2900],
			},
			section => {
				required => 1,
				integer => 1,
				value_between => [1, 3],
				parse => sub {
					my $val = shift;
					
					my $ret = $val == 1 ? 'reviews' :
						  $val == 2 ? 'receips' :
						  'general';
						  
					return { section => $ret };
				},
			},
			id => {
				required => 1,
				exact_length => 10,
				value_between => [1000000000, 2000000000],
			},
		},
		groups => {
			date => {
				params => [qw/year mon day/],
				parse => sub {
					my ($year, $mon, $day) = @_;
					return undef unless $year && $mon && $day;
					return { date => $year.'-'.$mon.'-'.$day };
				},
			},
		},
	}, {
		name => 'edit_post',
		inherits_from => 'post',
		params => {
			subject => {
				required => 0,
			},
			id => {
				forbidden => 1,
			},
		},
	});

ok($b, 'Got a proper Brannigan object');

my $data = $b->process('post', {
	subject		=> 'su',
	text		=> undef,
	day		=> 13,
	mon		=> 12,
	year		=> 2010,
	section		=> 2,
	thing		=> 3,
	id		=> 300000000,
});

is_deeply($data, {
	'date' => '2010-12-13',
	'subject' => 'su',
	'section' => 'receips',
	'_rejects' => {
		'text' => [
			'required(1)',
		],
		'subject' => [
			'length_between(3, 40)'
		],
		'id' => [
			'exact_length(10)',
			'value_between(1000000000, 2000000000)'
		]
	},
	'day' => 13,
	'mon' => 12,
	'id' => 300000000,
	'year' => 2010
	}, 'simple scheme with rejects');

my $data2 = $b->process('post', {
	subject		=> 'subject',
	text		=> 'lorem ipsum dolor sit amet',
	section		=> 2,
	thing		=> 3,
	id		=> 1515151515,
});

is_deeply($data2, {
	'subject' => 'subject',
	'text' => 'lorem ipsum dolor sit amet',
	'section' => 'receips',
	'id' => 1515151515
	}, 'simple scheme with no rejects');

my $data3 = $b->process('edit_post', {
	subject		=> 'subject edited',
	section		=> 3,
	id		=> 1515151515,
});

is_deeply($data3, {
		'_rejects' => {
			'id' => [
				'forbidden(1)'
			],
			'text' => [
				'required(1)'
			],
		},
		'subject' => 'subject edited',
		'section' => 'general',
		'id' => 1515151515
	}, 'inheriting scheme with rejects');

my $data4 = $b->process('edit_post', {
	id		=> undef,
	section		=> 1,
	text		=> 'lorem ipsum oh shit my parents are here',
});

is_deeply($data4, {
		'section' => 'reviews',
		'text' => 'lorem ipsum oh shit my parents are here',
	}, 'inheriting scheme with no rejects');

# add new scheme
$b->add_scheme({ name => 'fresh', params => { subject => { required => 1 } } });
is_deeply($b->process('fresh', { subject => 'test' }), { subject => 'test' }, 'new scheme');

# check the functional interface
is_deeply(Brannigan::process({ params => { subject => { required => 1 } } }, { subject => 'test' }), { subject => 'test' }, 'functional interface');

done_testing();
