#!perl -T

use strict;
use warnings;
use Carp;
use Test::More tests => 17;
use App::Validation::Automation;
use English qw(-no_match_vars);

#Check if App::Validation::Automation is able to compile
open my $log_handle,">>", "/var/tmp/log.log"
    or croak "Could not create /var/tmp/log.log : $OS_ERROR";

my $obj = App::Validation::Automation->new(
    config          => {
        'COMMON.LINK'    => 'http://search.cpan.org',
        'COMMON.MAX_REQ' => 1,
        'COMMON.MIN_UNQ' => 0,
    },
    log_file_handle => $log_handle,
    user_name       => 'user',
#    password        => 'decrypted_using_pphrase',
    #secret_pphrase  => '28bH!G',
);

ok( defined $obj, 'App::Validation::Automation Object Creation');

#Check what all App::Validation::Automation can do
can_ok($obj, 'validate_urls');
can_ok($obj, 'test_dnsrr_lb');
can_ok($obj, 'validate_processes_mountpoints');

can_ok($obj, 'mail', 'page');
can_ok($obj, 'page');

can_ok($obj, 'log');

can_ok($obj, 'purge');

can_ok($obj, 'validate_url');
can_ok($obj, 'dnsrr');
can_ok($obj, 'lb');

can_ok($obj, 'connect');
can_ok($obj, 'validate_process');
can_ok($obj, 'validate_mountpoint');


#Check methods for functionality - App::Validation::Automation Features
is($obj->validate_urls(), 1, 'Testing validate_urls ');
is($obj->test_dnsrr_lb(), 1, 'Testing test_dnsrr_lb ');
is($obj->validate_processes_mountpoints(), 1,
    'Testing validate_processes and mountpoints ');

close $log_handle;

