#!perl

use t::ests;
use Log::Radis;
use Test::Mock::Redis;
use JSON qw(decode_json);
use FindBin qw($RealBin $RealScript);

my $BIN = "$RealBin/$RealScript";

my $mock = Test::Mock::Redis->new;
my $queue;

sub getlogr {
    decode_json($mock->rpop($queue//return)//return)
}

sub getlogl {
    decode_json($mock->lpop($queue//return)//return)
}

{
    package Webservice;
    use Dancer2 appname => 'RadisTest';

    set engines => { logger => { Radis => { __mock => $mock } } };
    set logger => 'Radis';
    my $engine = engine('logger');
    $queue = $engine->queue;
    debug('Debug', 'Scalar' => \'Scalar', 'Array' => ['Array'], 'Hash' => { 'Foo' => 'Bar' });
    info('Info');
    warning('Warning');
    error('Error');
    log(core => 'Core');

    get '/' => sub { info('Info'); return ref($engine); };
}

my $PT = init('Webservice');

my $log = getlogr();
eval { delete $log->{timestamp} };

note $@ if $@;

is_deeply $log => {
    _pid => $$,
    _bin => $BIN,
    _source => 'RadisTest',
    host => $Log::Radis::HOSTNAME,
    level => 8,
    short_message => 'Debug',
    version => $Log::Radis::GELF_SPEC_VERSION,
    _dancer_array => q"['Array']",
    _dancer_scalar => q"\'Scalar'",
    _dancer_hash => q"{'Foo' => 'Bar'}",
};

if ($log = getlogr()) {
    isa $log => 'HASH';
    is $log->{level} => 7;
    is $log->{short_message} => 'Info';
    pass('7/Info');
} else {
    fail('7/Info');
}

if ($log = getlogr()) {
    isa $log => 'HASH';
    is $log->{level} => 5;
    is $log->{short_message} => 'Warning';
    pass('5/Warning');
} else {
    fail('5/Warning');
}

if ($log = getlogr()) {
    isa $log => 'HASH';
    is $log->{level} => 4;
    is $log->{short_message} => 'Error';
    pass('4/Error');
} else {
    fail('4/Error');
}

if ($log = getlogr()) {
    isa $log => 'HASH';
    is $log->{level} => 9;
    is $log->{short_message} => 'Core';
    pass('9/Core');
} else {
    fail('9/Core');
}

my $R = $PT->request(GET('/'));
is $R->content => 'Dancer2::Logger::Radis';

if ($log = getlogr()) {
    while ($log->{short_message} =~ m{looking for|entering hook}i) {
        $log = getlogr();
    }
    isa $log => 'HASH';
    is $log->{level} => 7;
    is $log->{short_message} => 'Info';
    pass('10/Core with request');
} else {
    fail('10/Core with request');
}

done_testing;
