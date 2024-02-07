#!/usr/bin/perl -w
use strict;
use utf8;

use Acrux::Log;
use IO::Handle;

my $log = Acrux::Log->new(
    handle => IO::Handle->new_from_fd(fileno(STDOUT), "w"),
    level  => 'trace',
    #short  => 1,
    color  => 1,
    #format => sub {
    #    my ($time, $level, @lines) = @_;
    #    return "[$time] [$level] " . join (' ', @lines) . "\n";
    #}
);

$log->trace('Whatever');
$log->debug('You screwed up, but that is ok');
$log->info('You are bad, but you prolly know already');
$log->notice('Normal, but significant, condition...');
$log->warn('Dont do that Dave...');
$log->error('You really screwed up this time');
$log->fatal('Its over...');
$log->crit('Its over...');
$log->alert('Action must be taken immediately');
$log->emerg('System is unusable');

__END__
