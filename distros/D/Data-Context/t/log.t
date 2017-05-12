use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Data::Dumper qw/Dumper/;
use IO::String;

use Data::Context::Log;

test_debug();
test_info();
test_warn();
test_error();
test_fatal();
test_log();

done_testing;

sub test_debug {
    my $last;
    my $fh = IO::String->new($last);

    my $log = Data::Context::Log->new(
        level => 1,
        fh    => $fh,
    );

    $log->debug('debug');
    like $last, qr/DEBUG/, 'Can log debug';
    Data::Context::Log->debug('static');
    like $last, qr/static/, 'Can log debug';
    $log->level(2);
    my $length = length $last;
    $log->debug('debug');
    is length $last, $length, 'Can log debug turned off';
}

sub test_info {
    my $last;
    my $fh = IO::String->new($last);

    my $log = Data::Context::Log->new(
        level => 1,
        fh    => $fh,
    );

    $log->info ('info ');
    like $last, qr/INFO/ , 'Can log info ';
    Data::Context::Log->info('static');
    like $last, qr/static/, 'Can log info';
    $log->level(3);
    my $length = length $last;
    $log->info('info');
    is length $last, $length, 'Can log info turned off';
}

sub test_warn {
    my $last;
    my $fh = IO::String->new($last);

    my $log = Data::Context::Log->new(
        level => 1,
        fh    => $fh,
    );

    $log->warn ('warn ');
    like $last, qr/WARN/ , 'Can log warn ';
    Data::Context::Log->warn('static');
    like $last, qr/static/, 'Can log warn';
    $log->level(4);
    my $length = length $last;
    $log->warn('warn');
    is length $last, $length, 'Can log warn turned off';
}

sub test_error {
    my $last;
    my $fh = IO::String->new($last);

    my $log = Data::Context::Log->new(
        level => 1,
        fh    => $fh,
    );

    $log->error('error');
    like $last, qr/ERROR/, 'Can log error';
    Data::Context::Log->error('static');
    like $last, qr/static/, 'Can log error';
    $log->level(5);
    my $length = length $last;
    $log->error('error');
    is length $last, $length, 'Can log error turned off';
}

sub test_fatal {
    my $last;
    my $fh = IO::String->new($last);

    my $log = Data::Context::Log->new(
        level => 1,
        fh    => $fh,
    );

    $log->fatal('fatal');
    like $last, qr/FATAL/, 'Can log fatal';
    Data::Context::Log->fatal('static');
    like $last, qr/static/, 'Can log fatal';
    $log->level(6);
    my $length = length $last;
    $log->fatal('fatal');
    is length $last, $length, 'Can log fatal turned off';
}

sub test_log {
    my $last;
    my $fh = IO::String->new($last);

    my $log = Data::Context::Log->new(
        level => 1,
        fh    => $fh,
    );

    $log->_log('OWN', '_log');
    like $last, qr/OWN/, 'Can log _log';
    Data::Context::Log->_log('OWN', "static\n");
    like $last, qr/static/, 'Can log _log';
    $log->_log('OWN', {a=>1});
    like $last, qr/'a'\s*=>/, 'dump one argument _log';
    $log->_log('OWN', undef);
    like $last, qr/undef/, 'dump one undef argument _log';
    $log->_log('OWN', "More", "than", "one", "argument");
    like $last, qr/More than one argument/, '_log with more than one arg';
}
