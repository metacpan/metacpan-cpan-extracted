#!/usr/bin/perl -w
use strict;

use Data::FormValidator 4.00;
use Data::FormValidator::Constraints::Words;
use Test::More tests => 42;

my %rules = (
		validator_packages => [qw(  Data::FormValidator::Constraints::Words )],
		msgs => {prefix=> 'err_'},		# set a custom error prefix
		missing_optional_valid => 1,
		constraint_methods => {
			realname    => realname(),
			basicwords  => basicwords(),
			simplewords => simplewords(),
			printsafe   => printsafe(),
			paragraph   => paragraph(),
			username    => username(),
			password    => password()
		},
		constraints => {
			realname    => { constraint_method => realname      },
			basicwords  => { constraint_method => basicwords    },
			simplewords => { constraint_method => simplewords   },
			printsafe   => { constraint_method => printsafe     },
			paragraph   => { constraint_method => paragraph     },
			username    => { constraint_method => username      },
			password    => { constraint_method => password      }
		},
        optional => [qw(realname simplewords basicwords printsafe paragraph username password)]
	);

my @tests = ( undef, '', 'safe', 'Pr;n+.5afe', 'Pr1nt 5afe' );

my %results = (
	realname    => [ undef, undef, 'safe', undef,         'Pr1nt 5afe' ],
	basicwords  => [ undef, undef, 'safe', undef,         'Pr1nt 5afe' ],
	simplewords => [ undef, undef, 'safe', 'Pr;n+.5afe',  'Pr1nt 5afe' ],
	printsafe   => [ undef, undef, 'safe', 'Pr;n+.5afe',  'Pr1nt 5afe' ],
	paragraph   => [ undef, undef, 'safe', 'Pr;n+.5afe',  'Pr1nt 5afe' ],
	username    => [ undef, undef, 'safe', undef,         undef        ],
	password    => [ undef, undef, 'safe', 'Pr;n+.5afe',  undef        ],
);

for my $method (keys %results) {
    for my $test (0 .. scalar(@tests)) {
        my $results = Data::FormValidator->check({ $method => $tests[$test] }, \%rules);
        my $values = $results->valid;
        is($values->{$method}, $results{$method}->[$test], "'$method' value '$tests[$test]' matches expected result");
    }
}
