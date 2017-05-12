# $Id: 06-filter.t 2 2010-06-25 14:41:40Z twilde $


use Test::More tests => 13;
use strict;

BEGIN { 
    use_ok('Data::CGIForm'); 
}

use t::FakeRequest;

my %input = (
	leading => [' 1', '1'],
	tailing => ['1 ', '1'],
	both    => ['1 ', ' 1', '1'],
	ws      => ['1 1', ' 1 ', '1'],
	lc      => [qw(LOWER CASE)],
	uc      => [qw(upper case)],
	mine    => [0, 1, 2],
);

my %should = (
	leading => [qw(1 1)],
	tailing => [qw(1 1)],
	both    => [qw(1 1 1)],
	ws      => [qw(11 1 1)],
	lc      => [qw(lower case)],
	uc      => [qw(UPPER CASE)],
	mine    => [qw(1 2 3)],
);	

my $r = t::FakeRequest->new(\%input);

my %spec = (
	leading => {
		regexp => qr/^(\d+)$/,
		filter => 'strip_leading_ws',
	},
	tailing => {
		regexp => qr/^(\d+)$/,
		filter => [qw(strip_trailing_ws)],
	},
	both => {
		regexp => qr/^(\d+)$/,
		filter => [qw(strip_leading_ws strip_trailing_ws)]
	},
	ws => {
		regexp => qr/^(\d+)$/,
		filter => 'strip_ws',
	},
	lc => {
		regexp => qr/^([\w\s]+)$/,
		filter => 'lc',
	},
	uc => {
		regexp => qr/^([\w\s]+)$/,
		filter => 'uc',
	},
	mine => {
		regexp => qr/^(\d+)$/,
		filter => sub { ${$_[0]} =~ s/(.)/$1 + 1/eg; },
	},
);

my $form;

eval { $form = Data::CGIForm->new(datasource => $r, spec => \%spec); };

ok($form, 'Form got made');
   diag("$@") unless $form;


foreach my $key (keys %should) {
	is_deeply([$form->param($key)], $should{$key}, "$key looks right");
}

#
# Make sure that filters can't create data for empty fields
# 
$r = t::FakeRequest->new({
	empty  => '',
	notdef => undef,
	# none => ... 
});

undef $form;
eval { 
	$form = Data::CGIForm->new(
		datasource => $r, 
		spec       => {
			empty  => {
				regexp   => qr/^(.+)$/,
				optional => 1,
				filter   => sub { my $ref = shift; $$ref = "filter:$$ref" },
			},
			notdef => {
				regexp   => qr/^(.+)$/,
				optional => 1,
				filter   => sub { my $ref = shift; $$ref = "filter:$$ref" },
			},
			none   => {
				regexp   => qr/^(.+)$/,
				optional => 1,
				filter   => sub { my $ref = shift; $$ref = "filter:$$ref" },
			},
		},
	); 
};


ok($form);
ok(!$form->empty,  'empty is empty');
ok(!$form->notdef, 'notdef is empty');
ok(!$form->none,   'none is empty');
 
