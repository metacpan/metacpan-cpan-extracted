#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long qw<:config autohelp no_ignore_case>;
use App::EvalServer;
use Pod::Usage;
use POE;

my %args;
GetOptions(
    'h|host=s'    => \$args{host},
    'p|port=s'    => \$args{port},
    'u|user=s'    => \$args{user},
    'U|unsafe'    => \$args{unsafe},
    't|timeout=i' => \$args{timeout},
    'l|limit=i'   => \$args{limit},
    'd|daemonize' => \$args{daemonize},
    'v|version'   => sub {
        no strict 'vars';
        my $version = defined $App::EvalServer::VERSION
            ? $App::EvalServer::VERSION
            : 'dev-git';
        print "Version $version\n";
        exit;
    },
) or pod2usage();

my $procname = 'evalserver';
$0 = $procname;
if ($] < 5.013000 && $^O eq 'linux') {
    local $@; 
    eval {
        require Sys::Prctl;
        Sys::Prctl::prctl_name($procname);
    };  
}

App::EvalServer->new(%args)->run();
$poe_kernel->run();

=encoding utf8

=head1 NAME

evalserver - The App::EvalServer launcher

=head1 SYNOPSIS

B<evalserver> [options]

 Options:
   -h FOO, --host FOO       Listen on host FOO (default: localhost)
   -p FOO, --port FOO       Listen on port FOO (default: 14400)
   -u FOO, --user FOO       Eval code as user FOO (default: nobody)
   -t FOO, --timeout FOO    Kill code after FOO seconds (default: 10)
   -l FOO, --limit FOO      Resource limit in megabytes (default: 50)
   -d, --daemonize          Run in the background
   -U, --unsafe             Don't chroot or set limits (no root needed)
   -v, --version            Print version
   -h, --help               Print this usage message

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
