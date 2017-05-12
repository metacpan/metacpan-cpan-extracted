
use Test;
BEGIN { $| = 1; plan tests => 46 }
END { ok(0) unless $loaded;}
use Audio::Ecasound qw(:simple :std :raw :raw_r :iam);
$loaded = 1;
ok(1);

use strict;

# die, warn, ''
# raw, raw_r, simple, oo
# float arg
# last_types

# raw interface
eci_command('cs-add c1');
eci_command('cs-selected');
ok eci_last_type() => 's'; 
ok eci_last_string() => 'c1';
eci_command('cs-is-valid');
ok eci_last_type() => 'i'; 
ok eci_last_integer() => 0;
eci_command('cs-list');
ok eci_last_type() => 'S'; 
my $n = eci_last_string_list_count();
ok $n >= 1; # gets 1 or 2
ok ((eci_last_string_list_item($n-1))[0] => 'c1');
eci_command('cs-get-length');
ok eci_last_type() => 'f'; 
ok eci_last_float() => 0;
eci_command_float_arg('cs-set-length', 2.0);
ok eci_last_type() => '-'; # once was ''
eci_command('start'); 
ok eci_error() => 1;
ok eci_last_error() => qr/chainsetup cannot be connected|No chainsetup connected/i;
ok eci_last_type() => 'e'; 

# raw_r interface (test 14)
# call with wrong $obj
eval { 
    no warnings 'uninitialized';
    eci_command_r(undef,'status');
};
ok $@ => qr/not of type eci_handle_t/;
my $eh = eci_init_r();
ok ref($eh) => 'eci_handle_t';
eci_command_r($eh,'status'); 
ok eci_last_type_r($eh) => 's';
ok eci_last_string_r($eh) => qr/Chainsetup status/i;
eci_cleanup_r($eh);

# simple (test 18)
ok eci('status') => qr/Chainsetup status/i;

ok on_error() => 'warn'; # default val
ok on_error('') => '';
ok !defined(eci('start')); # error
ok errmsg() => qr/chainsetup cannot be connected|No chainsetup connected/i;
ok errmsg('') => '';
eci('cs-set-length');  
ok errmsg() => qr/argument omitted/;
eci('cs-set-length', 4.0);  
ok eci('cs-get-length') => 4; # 4.000?

ok on_error('confess') => 'confess';
eval { eci('asyntaxerror'); };
ok $@ => qr/Unknown command/;
ok errmsg() => qr/Unknown command/;

ok on_error('die') => 'die';
eval { eci('asyntaxerror'); };
ok $@ => qr/Unknown command/;
ok errmsg() => qr/Unknown command/;


# OO interface (test 28)
my $e = new Audio::Ecasound;
ok ref($e) => 'Audio::Ecasound';
ok $e->on_error => 'die'; # set from class
on_error('warn');
ok $e->on_error() => 'die'; # diverge from class
$e->errmsg('');
eval { $e->eci('start') };
ok $@ => qr/chainsetup cannot be connected|No chainsetup connected/i;
eval { $e->eci('cs-set-length'); };
ok $@ => qr/argument omitted/;
ok $e->errmsg() => qr/argument omitted/;
ok $e->eci('status') => qr/Chainsetup status/i; #changed
$e->eci('cs-add c1');
$e->eci('cs-set-length', 5.0);
ok $e->eci('cs-get-length') => 5;

# comments added
ok eci('status # a comment') => qr/Chainsetup status/i; #changed
# multiline commands
ok eci("cs-set-length 6
        cs-get-length") => 6;

# :iam tests
on_error('');
ok((cs_set_length 7) => '');
ok((cs_get_length) => 7);
# Second time shouldn't redefine
ok((cs_get_length) => 7);
eval { an_unknown_function(); };
ok $@ => qr/Undefined subroutine .*an_unknown_function called/;

