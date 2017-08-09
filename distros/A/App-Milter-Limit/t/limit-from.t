#!perl

use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 8;
use Test::Warnings qw(:no_end_test had_no_warnings);
use Data::Section -setup;
use My::Test::Util;
use Net::Milter;
use Path::Tiny;

use_ok 'App::Milter::Limit' or exit 1;

my $tmpdir = Path::Tiny->tempdir;

my $config_file = __PACKAGE__->generate_config();

my $config = App::Milter::Limit::Config->instance($config_file);
isa_ok $config, 'App::Milter::Limit::Config';

my $milter = App::Milter::Limit->instance('Test');
isa_ok $milter, 'App::Milter::Limit';

my $socket = $tmpdir->child('milter-limit.sock')->stringify;

isa_ok $milter, 'App::Milter::Limit';

my $MILTER_PID;
my $MASTER_PID = $$;

END {
    if (defined $MILTER_PID and $MASTER_PID == $$) {
        had_no_warnings();
        My::Test::Util->stop_milter($MILTER_PID);
    }
}

$MILTER_PID = My::Test::Util->start_milter($milter, $socket);

my $client = Net::Milter->new;
$client->open($socket, 10, 'unix');
$client->protocol_negotiation;
$client->send_macros('{auth_authen}','auth-1@example.com');

# this should bass as the auth_authn value will be used
my ($result) = $client->send_mail_from('John Doe <100@example.com>');
is $$result{action}, 'continue';

$client->send_macros('{auth_authen}','auth-6@example.com');
($result) = $client->send_mail_from('John Doe <100@example.com>');
is $$result{action}, 'reject';

sub generate_config {
    my $self = shift;

    my $config = $self->section_data('config');

    my $filename = $tmpdir->child('milter-limit.conf')->stringify;

    My::Test::Util->generate_config($config, $filename, { state_dir => $tmpdir->stringify });

    return $filename;
}

__DATA__

__[ config ]__
name = milter-limit
state_dir = {{$state_dir}}
limit_from = \{auth_authen\}
driver = Test
max_children = 1
max_requests_per_child = 100
expire = 86400
limit = 5
reply = reject
connection = unix:{{$state_dir}}/milter-limit.sock
