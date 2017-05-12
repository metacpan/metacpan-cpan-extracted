# $Id: 01-spec.t 2 2010-06-25 14:41:40Z twilde $

use Test::More tests => 25;
use strict;


BEGIN { 
    use_ok('Data::CGIForm'); 
}

use t::FakeRequest;

my $r = t::FakeRequest->new({ foo => '1' });

my %spec = (
	number => qr/^(\d+)$/,
	hex => {
		regexp => qr/^([\da-f]+)$/i,
		filter => [qw(strip_leading_ws strip_trailing_ws)],
	},
	letter => {
		regexp   => qr/^([a-z])$/,
		filter   => sub { $$_[0] =~ s/\s//g },
		optional => 1,
	},
	ws => {
		regexp  => qr/^(\s+)$/,
		errors  => {
			invalid => q|That's not whitespace: [% value %]|,
			empty   => q|No whitespace [% key %]|,
		}
	},
);


my $form;

eval { $form = Data::CGIForm->new(datasource => $r, spec => \%spec); };

ok($form, 'Form got made');

unless ($form) {
	eval { require Data::Dumper; };

	diag("$@: " . Data::Dumper::Dumper(\%spec)) unless $@;
}

my $spec = $form->{'spec'};

#
# Lets go though the spec that was created from our input and see if it
# is somewhat sane.
#

my $number = $spec->{'number'};

ok($number,                              'number exists');
is(ref $number, 'HASH',                  'and is hashref'); 
ok($number->{'regexp'},                  'regexp for number exists');
ok(!$number->{'filter'},                 'filter is empty');
ok(!$number->{'errors'},     			 'errors are empty');
is($number->{'optional'},                0,               'optional set to 0');

###############################################################################

my $hex = $spec->{'hex'};

ok($hex,                                'hex exists');
is(ref $hex, 'HASH',                    'and is hashref');
ok($hex->{'regexp'},                    'hex regexp exists');
#is(ref $hex->{'filter'}, 'ARRAY',       'filter is an array ref');

#my @pre = @{$hex->{'filter'}};
#is(scalar(@pre), 2,                     'filter contains two elements');
#is(ref @pre[0], 'CODE',                 'first element is a coderef');
#is(ref @pre[1], 'CODE',                 'second elements is a coderef');

ok(!$hex->{'errors'},     			    'errors are empty');

is($hex->{'optional'}, 0,               'optional set to 0');

################################################################################

my $letter = $spec->{'letter'};


ok($letter,                             'letter exists');
is(ref $letter, 'HASH',                 'and is hashref');
ok($letter->{'regexp'},                 'letter regexp exists');
#is(ref $letter->{'filter'}, 'ARRAY',    'filter is an array ref');

#my @pre = @{$letter->{'filter'}};
#is(scalar(@pre), 1,                     'filter contains two elements');
#is(ref @pre[0], 'CODE',                 'first element is a coderef');

ok(!$letter->{'errors'},     			'errors are empty');


is($letter->{'optional'}, 1,            'optional set to 1');

################################################################################

my $ws = $spec->{'ws'};

ok($ws,                                 'ws exists');
is(ref $ws, 'HASH',                     'and is hashref'); 
ok($ws->{'regexp'},                     'regexp for ws exists');
ok(!$ws->{'filter'},                    'filter is empty');
is($ws->{'errors'}->{'invalid'},        q|That's not whitespace: [% value %]|, 
											'custom errors exists'); 
is($ws->{'errors'}->{'empty'},          q|No whitespace [% key %]|,           
											 'custom errors exists'); 
is($ws->{'optional'}, 0,                'optional set to 0');

