use strict;
use warnings;

use Test::More tests => 113;
use Data::Dumper;

BEGIN {
	use_ok('Apache::Voodoo::Validate');
};
require_ok('Apache::Voodoo::Validate');

my %u_int_old = (
	'type' => 'unsigned_int',
	'max' => 4294967295
);

my %u_int_new = (
	'type'  => 'unsigned_int',
	'bytes' => 4
);

my %s_int_old = (
	'type' => 'signed_int',
	'min'  => -4294967296,
	'max'  => 4294967295
);

my %s_int_new = (
	'type'  => 'signed_int',
	'bytes' => 4,
);

my %date = (
	'type' => 'date'
);

my %time = (
	'type' => 'time'
);

my %datetime = (
	'type' => 'datetime'
);

my %vchar = ( type => 'varchar', 'length' => 64  );
my %text  = ( type => 'text' );

my %email  = ( type => 'varchar', 'length' => 64, 'valid'  => 'email'   );
my %url    = ( type => 'varchar', 'length' => 64, 'valid'  => 'url'     );
my %regexp = ( type => 'varchar', 'length' => 64, 'regexp' => '^aab+a$' );

my $full_monty = {
	'u_int_old_r' => { %u_int_old, required => 1 },
	'u_int_new_r' => { %u_int_new, required => 1 },
	'u_int_old_o' => { %u_int_old, required => 0 },
	'u_int_new_o' => { %u_int_new, required => 0 },

	'varchar_req' => { %vchar, required => 1 },
	'varchar_opt' => { %vchar, required => 0 },

	'text' => { %text },

	'email_req' => { %email, required => 1 },
	'email_opt' => { %email, required => 0 },

	'url_req' => { %url, required => 1 },
	'url_opt' => { %url, required => 0 },

	'regexp_req' => { %regexp, required => 1 },
	'regexp_opt' => { %regexp, required => 0 },

	'valid' => {
		%vchar,
		'valid' => sub {
			my $v = shift;
			
			my %vals = (
				'ok' => 1,
				'notok' => 0,
				'bogus' => 'BOGUS'
			);
			return $vals{$v};
		}
	},
	'datetime' => { %datetime }
};

my $V;

eval {
  $V = Apache::Voodoo::Validate->new($full_monty);
};
if ($@) {
	fail("Config Syntax failed when it shouldn't have\n$@");
	BAIL_OUT("something is terribly wrong");
}
else {
	pass("Config Syntax");
}

eval {
  $V->set_valid_callback(sub {
	my ($p,$e) = @_;

	if (defined($p->{varchar_req}) and $p->{varchar_req} eq "docheck" and $p->{varchar_opt} ne 'checked') {
		return ['varchar_opt','BOGUS'],
		       ['varchar_req','BOGUS'];
	}
	return undef;
  });
};
if ($@) {
	fail("Adding a validation callback failed when it shouldn't have\n$@");
	BAIL_OUT("something is terribly wrong");
}
else {
	pass("Adding Callback");
}
my ($v,$e) = $V->validate({});

# Catches missing required params
ok(defined $e->{MISSING_u_int_old_r},'unsigned int required 1'); 
ok(defined $e->{MISSING_u_int_new_r},'unsigned int required 2'); 
ok(defined $e->{MISSING_url_req},    'url required'); 
ok(defined $e->{MISSING_varchar_req},'varchar required'); 
ok(defined $e->{MISSING_email_req},  'email required'); 
ok(defined $e->{MISSING_regexp_req}, 'regexp required'); 

# Doesn't yell about missing optional params
ok(!defined $e->{MISSING_u_int_old_o},'unsigned int optional 1'); 
ok(!defined $e->{MISSING_u_int_new_o},'unsigned int optional 2'); 
ok(!defined $e->{MISSING_url_opt},    'url optional'); 
ok(!defined $e->{MISSING_varchar_opt},'varchar optional'); 
ok(!defined $e->{MISSING_text},       'varchar text'); 
ok(!defined $e->{MISSING_email_opt},  'email optional'); 
ok(!defined $e->{MISSING_regexp_opt}, 'regexp optional'); 
ok(!defined $e->{MISSING_datetime},   'datetime optional'); 

# bogus values
my $params = {
	u_int_new_r => 'abc',
	u_int_new_o => 'abc',
	u_int_old_r => 'abc',
	u_int_old_o => 'abc',
	email_req => 'abc!',
	email_opt => 'abc@abcabcabcabcabc.com',	# valid form, non-existant domain
	url_req => 'abc',
	url_opt => 'http://127.0.0.0.1/foo',	# too many dots.
	regexp_req => 'c',
	regexp_opt => 'aba',
	valid => 'notok',
	varchar_req => 'docheck',
	varchar_opt => 'bogus',
	datetime => '2009-01-01 asdfasdf'
};

($v,$e) = $V->validate($params);

ok(scalar keys %{$v} == 0,'$values is empty');
ok(defined $e->{BAD_u_int_new_r},'bad unsigned int 1');
ok(defined $e->{BAD_u_int_new_o},'bad unsigned int 2');
ok(defined $e->{BAD_u_int_old_r},'bad unsigned int 3');
ok(defined $e->{BAD_u_int_old_o},'bad unsigned int 4');
ok(defined $e->{BAD_email_req},  'bad email (format)');
ok(defined $e->{BAD_email_opt},  'bad email (no such domain)') || diag("using this email address: ".$params->{email_opt});
ok(defined $e->{BAD_url_req},    'bad url 1');
ok(defined $e->{BAD_url_opt},    'bad url 2');
ok(defined $e->{BAD_regexp_req}, 'bad regexp 1');
ok(defined $e->{BAD_regexp_opt}, 'bad regexp 2');
ok(defined $e->{BAD_valid},      'bad valid sub');

ok(defined $e->{BAD_datetime},   'bad datetime');

ok(defined $e->{BOGUS_varchar_req}, 'bad valid sub');
ok(defined $e->{BOGUS_varchar_opt}, 'bad valid sub');


# valid values
($v,$e) = $V->validate({
	varchar_req => ' abc ',		# also sneek in trim test
	varchar_opt => 'abcdef ',	# also sneek in trim test
	u_int_new_r => '1234',
	u_int_new_o => '1234',
	u_int_old_r => '1234',
	u_int_old_o => '1234',
	email_req => 'abc@mailinator.com',
	email_opt => 'abc@yahoo.com',
	url_req => 'http://www.google.com',
	url_opt => 'http://yahoo.com/foo',
	regexp_req => 'aabbbba',
	regexp_opt => 'aaba',
	valid => 'ok',
	datetime => '2009-01-01 12:00am'
});

ok(scalar keys %{$e} == 0,'$errors is empty');
ok($v->{varchar_req} eq 'abc',                  'good varchar 1');
ok($v->{varchar_opt} eq 'abcdef',               'good varchar 2');
ok($v->{u_int_new_r} == 1234,                   'good unsigned int 1');
ok($v->{u_int_new_o} == 1234,                   'good unsigned int 1');
ok($v->{u_int_old_r} == 1234,                   'good unsigned int 1');
ok($v->{u_int_old_o} == 1234,                   'good unsigned int 1');
ok($v->{email_req}   eq 'abc@mailinator.com',   'good email 1');
ok($v->{email_opt}   eq 'abc@yahoo.com',        'good email 2');
ok($v->{url_req}     eq 'http://www.google.com','good url 1');
ok($v->{url_opt}     eq 'http://yahoo.com/foo', 'good url 2');
ok($v->{regexp_req}  eq 'aabbbba',              'good regexp 1');
ok($v->{regexp_opt}  eq 'aaba',                 'good regexp 2');
ok($v->{valid}       eq 'ok',                   'good valid sub');
ok($v->{datetime}    eq '2009-01-01 00:00:00',  'good datetime');

# fence post values
($v,$e) = $V->validate({
	text        => 'a' x 500,	            # should not yell about length
	varchar_req => 'a' x 64,
	varchar_opt => '  '.('a' x 64).'   ',	# also sneek in trim test
	u_int_new_r => 4294967295,
	u_int_new_o => 4294967295,
	u_int_old_r => 4294967295,
	u_int_old_o => 4294967295,
	email_req => 'a' x 54 . '@yahoo.com',
	email_opt => 'a' x 54 . '@yahoo.com  ',
	url_req => 'http://www.google.com/'. ('a' x (64-22)),
	regexp_req => 'aa'. ('b'x 61) . 'a'
});

ok(scalar keys %{$e} == 0,'$errors is empty');

# and over the line values
($v,$e) = $V->validate({
	varchar_req => 'a' x 65,
	varchar_opt => '  '.('a' x 100).'   ',	# also sneek in trim test
	u_int_new_r => 4294967296,
	u_int_new_o => 4294967296,
	u_int_old_r => 4294967296,
	u_int_old_o => 4294967296,
	email_req => 'a' x 100 . '@yahoo.com',
	email_opt => 'a' x 100 . '@yahoo.com  ',
	url_req => 'http://www.google.com/'. ('a' x 100),
	url_opt => 'http://www.google.com/'. ('a' x 100),
	regexp_req => 'aa'. ('b'x 100) . 'a',
	regexp_opt => 'aa'. ('b'x 200) . 'a',
	valid => 'a' x 65,
});

ok(scalar keys %{$v} == 0,'$values is empty');
ok(defined $e->{BIG_varchar_req},'big varchar 1');
ok(defined $e->{BIG_varchar_req},'big varchar 2');
ok(defined $e->{MAX_u_int_new_r},'big unsigned int 1');
ok(defined $e->{MAX_u_int_new_o},'big unsigned int 2');
ok(defined $e->{MAX_u_int_old_r},'big unsigned int 3');
ok(defined $e->{MAX_u_int_old_o},'big unsigned int 4');
ok(defined $e->{BIG_email_req},  'big email 1');
ok(defined $e->{BIG_email_opt},  'big email 2');
ok(defined $e->{BIG_url_req},    'big url 1');
ok(defined $e->{BIG_url_opt},    'big url 2');
ok(defined $e->{BIG_regexp_req}, 'big regexp 1');
ok(defined $e->{BIG_regexp_opt}, 'big regexp 2');
ok(defined $e->{BIG_valid},      'big valid sub');

# de-array-ification of non-multiple values
($v,$e) = $V->validate({
	varchar_req => [' abc ','def','ghi']
});

ok($v->{varchar_req} eq 'abc','de-array-ification');

my $M = Apache::Voodoo::Validate->new({
	'mult' => {
		'type' => 'varchar',
		'multiple' => 1,
		'required' => 1,
	}
});

($v,$e) = $M->validate({ mult => 'abc'});
is_deeply($v->{mult},['abc'],'array-ification of scalar');

($v,$e) = $M->validate({ mult => ['abc ',' def ',' ghi']});
is_deeply($v->{mult},['abc','def','ghi'],'array passthrough');

my $P = Apache::Voodoo::Validate->new({
	'prime' => {
		%u_int_new,
		multiple => 1,
		valid => sub {
			my $v = shift;

			return 1 if ($v eq 1 or $v eq 2);
			for (my $i=2; $i < $v; $i++) {
				unless ($v % $i) {
					return 0;
				}
			}
			return 1;
		}
	}
});

($v,$e) = $P->validate({ prime => 4});
ok($e->{'BAD_prime'},'valid sub 1');

($v,$e) = $P->validate({ prime => [13,14]});
ok(scalar keys %{$v} == 0,'$values is empty');
ok($e->{'BAD_prime'},'valid sub 2');

($v,$e) = $P->validate({ prime => [1, 13]});
is_deeply($v->{'prime'},[1,13],'valid sub 2');


my $D = Apache::Voodoo::Validate->new({
	'date_past' => {
		type => 'date',
		valid => 'past'
	},
	'date_future' => {
		type => 'date',
		valid => 'future'
	},
	'date_past_now' => {
		type => 'date',
		valid => 'past',
		now => sub { return '2000-01-01' }
	},
	'date_future_now' => {
		type => 'date',
		valid => 'future',
		now => sub { return '2000-01-01' }
	}
});

($v,$e) = $D->validate({
	date_past   => '1/1/1900',
	date_future => '12/31/9999',	# December 31, 9999 should be far enough in the future
	date_past_now   => '1/1/1900 ',
	date_future_now => '1/1/2009',
});
ok(scalar keys %{$e} == 0,'$errors is empty');
is($v->{date_past},      '1900-01-01','date past 1');
is($v->{date_past_now},  '1900-01-01','date past 2');
is($v->{date_future},    '9999-12-31','date future 1');
is($v->{date_future_now},'2009-01-01','date future 2');

($v,$e) = $D->validate({
	date_past   => 'a/1/1900',	    # bogus
	date_future => '13/31/9999',	# bogus
	date_past_now   => '1/2/2000',	# fence post
	date_future_now => '1/1/2000',	# fence post
});
ok(scalar keys %{$v} == 0,'$values is empty');
ok(defined($e->{BAD_date_past})     ,'bad date past 1');
ok(defined($e->{PAST_date_past_now}),'bad date past 2');
ok(defined($e->{BAD_date_future}),   'bad date future 1');
ok(defined($e->{FUTURE_date_future_now}),'bad date future 2');

($v,$e) = $D->validate({
	date_past_now   => '1/1/2000',	# fence post again
	date_future_now => '1/2/2000',	# fence post again
});

ok(scalar keys %{$e} == 0,'$errors is empty');
is($v->{date_past_now},   '2000-01-01','fence post date 1');
is($v->{date_future_now}, '2000-01-02','fence post date 2');


$D = Apache::Voodoo::Validate->new({
	'time' => {
		type => 'time'
	},
	'time_min' => {
		type => 'time',
		min => '9:00 am'
	},
	'time_max' => {
		type => 'time',
		max => '5:00 pm'
	},
	'time_range' => {
		type => 'time',
		min => '9:00',
		max => '17:00'
	},
	'time_valid' => {
		type => 'time',
		valid => sub { return $_[0] eq "13:14:15" }
	}
});

($v,$e) = $D->validate({
	time => ' 9:15:04 pm',
	time_min => '9:00',
	time_max => '17:00',
	time_range => '12:00',
	time_valid => '1:14:15 pm'
});

ok(scalar keys %{$e} == 0,'$errors is empty');
is($v->{time},      '21:15:04','good time 1');
is($v->{time_min},  '09:00:00','good time 2');
is($v->{time_max},  '17:00:00','good time 3');
is($v->{time_range},'12:00:00','good time 4');
is($v->{time_valid},'13:14:15','good time 5');

($v,$e) = $D->validate({
	time => ' 19:15:04 pm',
	time_min => '8:59:59',
	time_max => '17:00:01',
	time_range => '23:00',
	time_valid => '12:14:15'
});

ok(scalar keys %{$v} == 0,'$values is empty');
ok(defined($e->{BAD_time}),         'bad time 1');
ok(defined($e->{MIN_time_min}),     'bad time 2');
ok(defined($e->{MAX_time_max}),     'bad time 3');
ok(defined($e->{MAX_time_range}),   'bad time 4');
ok(defined($e->{BAD_time_valid}),   'bad time 5');

my $B = Apache::Voodoo::Validate->new({
	bit => {
		type => 'bit',
		required => 1
	}
});

($v,$e) = $B->validate({ bit => ' 1'  }); is($v->{bit},1,'good bit 1');
($v,$e) = $B->validate({ bit => '11'  }); is($v->{bit},1,'good bit 2');
($v,$e) = $B->validate({ bit => 'y'   }); is($v->{bit},1,'good bit 3');
($v,$e) = $B->validate({ bit => 'yEs' }); is($v->{bit},1,'good bit 4');
($v,$e) = $B->validate({ bit => 't'   }); is($v->{bit},1,'good bit 5');
($v,$e) = $B->validate({ bit => 'tRuE'}); is($v->{bit},1,'good bit 6');

($v,$e) = $B->validate({ bit => ' 0'   }); is($v->{bit},0,'good bit 7');
($v,$e) = $B->validate({ bit => '00'   }); is($v->{bit},0,'good bit 8');
($v,$e) = $B->validate({ bit => 'n'    }); is($v->{bit},0,'good bit 9');
($v,$e) = $B->validate({ bit => 'nO'   }); is($v->{bit},0,'good bit a');
($v,$e) = $B->validate({ bit => 'f'    }); is($v->{bit},0,'good bit b');
($v,$e) = $B->validate({ bit => 'fAlSe'}); is($v->{bit},0,'good bit c');


($v,$e) = $B->validate({bit => ''});    ok($e->{MISSING_bit},'bad bit 1');
($v,$e) = $B->validate({bit => undef}); ok($e->{MISSING_bit},'bad bit 2');
($v,$e) = $B->validate({bit => -1});    ok($e->{MISSING_bit},'bad bit 3');
($v,$e) = $B->validate({bit => 'a'});   ok($e->{MISSING_bit},'bad bit 4');

my $E;
eval {
	$E = Apache::Voodoo::Validate->new({});
};
ok(ref($@) eq "Apache::Voodoo::Exception::RunTime::BadConfig",'Empty configuration throws exception 1 ');

eval {
	$E = Apache::Voodoo::Validate->new();
};
ok(ref($@) eq "Apache::Voodoo::Exception::RunTime::BadConfig",'Empty configuration throws exception 2 ');
