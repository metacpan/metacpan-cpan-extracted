#!/usr/bin/env perl -wT
use strict;
use Test::More (tests => 55);
use Data::FormValidator;
use Data::FormValidator::Constraints qw/
    :closures
    FV_max_length
/;
use Scalar::Util 'tainted';

# A gift from Andy Lester, this trick shows me where eval's die.
use Carp;
$SIG{__WARN__} = \&carp;
$SIG{__DIE__} = \&confess;

$ENV{PATH} = "/bin/";

my $data1 = { 
    firstname  => $ARGV[0], #Jim
};

my $data2 = {
    lastname   => $ARGV[1], #Beam
    email1     => $ARGV[2], #jim@foo.bar
    email2     => $ARGV[3], #james@bar.foo
};

my $data3 = {
    ip_address => $ARGV[4], #132.10.10.2
    cats_name  => $ARGV[5], #Monroe
    dogs_name  => $ARGV[6], #Rufus
};

my $data4 = {
	zip_field1 => [$ARGV[7],$ARGV[7]],  #12345 , 12345
	zip_field2 => [$ARGV[7],$ARGV[8]],  #12345 , oops
};

my $data5 = {
	zip_field1 => [$ARGV[7],$ARGV[7]],  #12345 , 12345
	zip_field2 => [$ARGV[7],$ARGV[7]],  #12345 , oops
};

my $data6 = {
	zip_field1 => [$ARGV[7],$ARGV[7]],  #12345 , 12345
	zip_field2 => [$ARGV[7],$ARGV[7]],  #12345 , oops
    email1     => $ARGV[2], #jim@foo.bar
    email2     => $ARGV[3], #james@bar.foo
};

my $data7 = {
	zip_field1 => [$ARGV[7],$ARGV[7]],  #12345 , 12345
	zip_field2 => [$ARGV[7],$ARGV[7]],  #12345 , oops
    email1     => $ARGV[2], #jim@foo.bar
    email2     => $ARGV[3], #james@bar.foo
};


my $profile = 
{
    rules1 => {
		untaint_constraint_fields => "firstname",
		required => "firstname",
        # constraints => {
		# 	firstname => '/^\w{1,15}$/'
		# },
        constraint_methods => {
			firstname => FV_max_length(15),
        },
	},
    rules2 => {
		untaint_constraint_fields => [ qw( lastname email1 )],
		required     =>
		[ qw( lastname email1 email2) ],
		constraints  => {
			lastname => '/^\w{1,10}$/',
			email1 => "email",
			email2 => "email",
		}   
	},   
    rules2_closure => {
		untaint_constraint_fields => [ qw( email1  )],
		required     => [ qw( email1 email2) ],
		constraint_methods  => {
            email1 => email(),
			email2 => email(),
		}   
	},   
    rules3 => {
		untaint_all_constraints => 1,
		required => 
		[ qw(ip_address cats_name dogs_name) ],
		constraints => {
			ip_address => "ip_address",
			cats_name  => '/^Felix$/',
			dogs_name  => 'm/^rufus$/i',
	    }
    },
	rules4 => {
		untaint_constraint_fields=> ['zip_field1','zip_field2'],
		required=>[qw/zip_field1 zip_field2/],
		constraints=> {
			zip_field1=>'zip',
		},
	},
    rules5 => {
        untaint_regexp_map => qr/^zip_field\d/,
        required_regexp    => qr/^zip_field\d/,
        constraint_method_regexp_map => {
            qr/^zip_field\d/ => zip(),
        },
    },
    rules6 => {
        untaint_regexp_map => [qr/^zip_field\d/, qr/^email\d/],
        required_regexp    => qr/^(zip_field|email)\d/,
        constraint_method_regexp_map => {
            qr/^zip_field\d/ => zip(),
            qr/^email\d/ => email(),
        },
    },
    rules7 => {
        required_regexp    => qr/^zip_field\d/,
        required           => [qw(email1 email2)],
        untaint_regexp_map => [qr/^zip_field\d/, qr/^email\d/],
        untaint_constraint_fields => [qw(email1 email2)],
        constraint_method_regexp_map => {
            qr/^zip_field\d/ => zip(),
        },
        constraints        => {
            email1     => 'email',
            email2     => 'email',
        },
    },
};

my $validator = new Data::FormValidator($profile);

#Rules #1
my ( $valid, $missing, $invalid, $unknown );
eval {  ( $valid, $missing, $invalid, $unknown ) = $validator->validate(  $data1, "rules1"); };

is($@,'','avoided eval error');
ok($valid->{firstname}, 'found firstname'); 
ok(! tainted($valid->{firstname}), 'firstname is untainted');
is($valid->{firstname},$data1->{firstname}, 'firstname has expected value');




#Rules #2
eval {  ( $valid, $missing, $invalid, $unknown ) = $validator->validate(  $data2, "rules2"); };   

is($@,'','avoided eval error');
ok($valid->{lastname});
ok(!tainted($valid->{lastname}));
is($valid->{lastname},$data2->{lastname});

ok($valid->{email1});
ok(!tainted($valid->{email1}));
is($valid->{email1},$data2->{email1});

ok($valid->{email2});
ok(tainted($valid->{email2}), 'email2 is tainted');
is($valid->{email2},$data2->{email2});

# Rules2 with closures 
{
    my ($result,$valid);
    eval { $result = $validator->check(  $data2, "rules2_closure"); };   
    is($@,'', 'survived eval');
    $valid = $result->valid();

    ok($valid->{email1}, "found email1 in \%valid") || warn Dumper ($data2,$result);
    ok(!tainted($valid->{email1}), "email one is not tainted");
    is($valid->{email1},$data2->{email1}, "email1 identity");
}


#Rules #3
eval {  ( $valid, $missing, $invalid, $unknown ) = $validator->validate(  $data3, "rules3"); };   

ok(!$@);

ok($valid->{ip_address});
ok(!tainted($valid->{ip_address}));
is($valid->{ip_address},$data3->{ip_address});

#in this case we're expecting no match
ok(!(exists $valid->{cats_name}), 'cats_name is not valid');
is($invalid->[0], 'cats_name', 'cats_name fails constraint');

ok($valid->{dogs_name});
ok(!tainted($valid->{dogs_name}));
is($valid->{dogs_name},$data3->{dogs_name});

# Rules # 4
eval {  ( $valid, $missing, $invalid, $unknown ) = $validator->validate(  $data4, "rules4"); };   
ok(!$@, 'avoided eval error');

ok(!tainted($valid->{zip_field1}->[0]),
        'zip_field1 should be untainted');

ok(tainted($valid->{zip_field2}->[0]),
    'zip_field2 should be tainted');


my $results = Data::FormValidator->check(
    {
    qr_re_no_parens => $ARGV[9], # 0
    qr_re_parens    => $ARGV[9], # 0

    },
    {
            required => [qw/qr_re_no_parens qr_re_parens/],
             constraints=>{
                 qr_re_no_parens => qr/^.*$/,
                 qr_re_parens    => qr/^(.*)$/,
             },
             untaint_all_constraints =>1
         });

is($results->valid('qr_re_no_parens'),0,'qr RE without parens in untainted');
is($results->valid('qr_re_parens')   ,0,'qr RE with    parens in untainted');

# Rules #5
eval {  ( $valid, $missing, $invalid, $unknown ) = $validator->validate(  $data5, "rules5"); };
ok(!$@, 'avoided eval error');
ok($valid->{zip_field1}, "zip_field1 should be valid");
ok(!tainted($valid->{zip_field1}->[0]), 'zip_field1 should be untainted');
ok($valid->{zip_field2}, "zip_field2 should be valid");
ok(!tainted($valid->{zip_field2}->[0]), 'zip_field2 should be untainted');

# Rules #6
eval {  ( $valid, $missing, $invalid, $unknown ) = $validator->validate(  $data6, "rules6"); };
ok(!$@, 'avoided eval error');
ok($valid->{zip_field1}, "zip_field1 should be valid");
ok(!tainted($valid->{zip_field1}->[0]), 'zip_field1 should be untainted');
ok($valid->{zip_field2}, "zip_field2 should be valid");
ok(!tainted($valid->{zip_field2}->[0]), 'zip_field2 should be untainted');
ok($valid->{email1}, "email1 should be valid");
ok(!tainted($valid->{email1}), 'email1 should be untainted');
ok($valid->{email2}, "email2 should be valid");
ok(!tainted($valid->{email2}), 'email2 should be untainted');

# Rules #7
eval {  ( $valid, $missing, $invalid, $unknown ) = $validator->validate(  $data7, "rules7"); };
ok(!$@, 'avoided eval error');
ok($valid->{zip_field1}, "zip_field1 should be valid");
ok(!tainted($valid->{zip_field1}->[0]), 'zip_field1 should be untainted');
ok($valid->{zip_field2}, "zip_field2 should be valid");
ok(!tainted($valid->{zip_field2}->[0]), 'zip_field2 should be untainted');
ok($valid->{email1}, "email1 should be valid");
ok(!tainted($valid->{email1}), 'email1 should be untainted');
ok($valid->{email2}, "email2 should be valid");
ok(!tainted($valid->{email2}), 'email2 should be untainted');
