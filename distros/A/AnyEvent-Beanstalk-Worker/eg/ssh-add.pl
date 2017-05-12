#!/usr/bin/env perl
use strict;
use warnings;
use AnyEvent::Beanstalk;
use JSON;
use Data::Dumper;
use feature 'say';

my $bs = AnyEvent::Beanstalk->new
  (server => 'localhost',
   encoder => sub { encode_json(shift) });

$bs->use('ssh-jobs')->recv;

my @scripts = ();
push @scripts, {interpreter => "/bin/sh",
                script => <<_SCRIPT_};
#!/bin/sh

date
uptime
df
_SCRIPT_

push @scripts, {interpreter => "/usr/bin/perl",
                script => <<_SCRIPT_};
#!/usr/bin/perl
use strict;
use warnings;
use Config;

print Config::config_vars(qw/osname osvers archname/);

die "This goes to STDERR";
_SCRIPT_

my $job = $bs->put({ priority => 100,
                     ttr      => 10,
                     delay    => 1,
                     encode   => { target => 'localhost',
                                   scripts => \@scripts }})->recv;

say STDERR "job added to queue: " . Dumper($job->id);

exit;
