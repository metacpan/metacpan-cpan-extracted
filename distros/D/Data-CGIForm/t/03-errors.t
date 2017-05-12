# $Id: 03-errors.t 2 2010-06-25 14:41:40Z twilde $


use Test::More tests => 35;
use strict;

BEGIN { 
    use_ok('Data::CGIForm'); 
}

use t::FakeRequest;

my %good_data = (
	number => '1',
	letter => 'a',
	hex    => '1f',
);

my %undef_data = (
	number => undef,
	letter => undef,
	hex    => undef,
);

my %empty_data = (
	number => '',
	letter => '',
	hex    => '',
);

my %bad_data = (
	number => 'a',
	letter => 1,
	hex    => '0k',
);


my $good_data  = t::FakeRequest->new(\%good_data);
my $undef_data = t::FakeRequest->new(\%undef_data);
my $empty_data = t::FakeRequest->new(\%empty_data);
my $bad_data   = t::FakeRequest->new(\%bad_data);
my $no_data    = t::FakeRequest->new({});
my %spec = (
	number => qr/^(\d+)$/,
	hex => {
		regexp => qr/^([\da-f]+)$/i,
		errors => {
			empty   => 'enter hex',
			invalid => 'that is not hex',
		},
	},
	letter => {
		regexp => qr/^([a-z])$/,
		errors => {
			empty   => 'enter a [% key %]',
			invalid => 'enter a letter, not "[% value %]"',
		},
		optional => 1,
	},
);

my ($good, $undef, $empty, $bad, $no);

eval { $good = Data::CGIForm->new(datasource => $good_data, spec => \%spec); };

ok($good, 'good got made');
   diag("$@") unless $good;
   
eval { $undef = Data::CGIForm->new(datasource => $undef_data, spec => \%spec); };

ok($undef, 'empty got made');
   diag("$@") unless $undef;

eval { $empty = Data::CGIForm->new(datasource => $empty_data, spec => \%spec); };

ok($empty, 'empty got made');
   diag("$@") unless $empty;
   
eval { $bad = Data::CGIForm->new(datasource => $bad_data, spec => \%spec); };

ok($bad, 'bad got made');
   diag("$@") unless $bad;   
   
eval { $no = Data::CGIForm->new(datasource => $no_data, spec => \%spec); };

ok($no, 'no got made');
   diag("$@") unless $no;   



ok(!$good->error, 'good has no errors');

foreach my $form ($empty, $undef, $bad, $no) {
	ok($form->error);
	
	ok($form->error('number'), 'number has error');
	ok($form->error('hex'),    'hex has error');

}

foreach my $form ($empty, $undef, $no) {
	ok(!$form->error('letter'), 'letter has no error (optional skipped)');
}

ok($bad->error('letter'), 'letter has error');


#
# Test that undef produces sane errors
#
like($undef->error('number'), qr/number.*not/i, 'number error seems sane');
is($undef->error('hex'),      'enter hex',      'hex error messgage correct');
is($undef->error('letter'),   undef,            'optional params ignoed');

#
# Test empty data strings
#
like($empty->error('number'), qr/number.*not/i, 'number error seems sane');
is($empty->error('hex'),      'enter hex',      'hex error messgage correct');
is($empty->error('letter'),   undef,            'optional params ignoed');


#
# Test empty data strings
#
like($no->error('number'), qr/number.*not/i, 'number error seems sane');
is($no->error('hex'),      'enter hex',      'hex error messgage correct');
is($no->error('letter'),   undef,            'optional params ignoed');


#
# Test bad data strings
#
like($bad->error('number'), qr/number/i,               'number error seems sane');
is($bad->error('hex'),      'that is not hex',         'hex error messgage correct');
is($bad->error('letter'),   'enter a letter, not "1"', 'optional params ignoed');
