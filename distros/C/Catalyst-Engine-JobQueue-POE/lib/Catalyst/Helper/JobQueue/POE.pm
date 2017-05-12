package Catalyst::Helper::JobQueue::POE;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.1');

our $CATALYST_SCRIPT_GEN = 30;

=head1 NAME

Catalyst::Helper::JobQueue::POE - create files for running a job queue

=head1 SYNOPSIS

  script/create.pl JobQueue::POE

=head1 DESCRIPTION

This helper creates the required files for a job queue. It creates a JobQueue
runner script in your application's F<script> directory and a F<crontab>
configuration file in your applications root directory. 

After editing your configuration file, you can start the job queue by
executing the runner script.

=head1 METHODS

=head2 mk_stuff

Generates a JobQueue runner script and a sample crontab file.

=head1 AUTHOR

Gruen Christian-Rolf <kiki@bdsro.org>

=head1 SEE ALSO

L<Catalyst>,L<Catalyst::Engine::JobQueue::POE>

=cut

sub mk_stuff
{
    my ( $self, $helper, @args ) = @_;

    $self->_mk_jobqueue($helper, @args);
    $self->_mk_crontab($helper, @args);
}

sub _mk_jobqueue
{
    my ( $self, $helper, @args ) = @_;

    my $base    = $helper->{base};
    my $app     = $helper->{app};
    my $appprefix = lc($app);
    $appprefix =~ s/::/_/;
    my $filename  = File::Spec->catfile( $base, 'script', "${appprefix}_jobqueue.pl");
    $helper->render_file( 'jobqueue', $filename, { appprefix => $appprefix, scriptgen => $CATALYST_SCRIPT_GEN } );
    chmod 0700, $filename; 
}

sub _mk_crontab
{
    my ( $self, $helper, @args ) = @_;

    my $base = $helper->{base};
    my $filename = File::Spec->catfile( $base, "crontab" );
    $helper->render_file( 'crontab', $filename );
}

return 1;
__DATA__

__jobqueue__
#!/usr/bin/env perl -w

BEGIN {
    $ENV{CATALYST_ENGINE} = 'JobQueue::POE';
    $ENV{CATALYST_SCRIPT_GEN} = [% scriptgen %];
}

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";

$ENV{CATALYST_HOME} = "$FindBin::Bin/..";

my $debug             = 0;
my $fork              = 0;
my $help              = 0;
my $crontab           = "$FindBin::Bin/crontab";

my @argv = @ARGV;

GetOptions(
    'debug|d'       => \$debug,
    'fork'          => \$fork,
    'help|?'        => \$help,
    'crontab|c'     => \$crontab,
);

pod2usage(1) if $help;

if ( $debug ) {
    $ENV{CATALYST_DEBUG} = 1;
    $ENV{CATALYST_POE_DEBUG} = 1;
}

# This is require instead of use so that the above environment
# variables can be set at runtime.

require [% app %];

[% app %]->run( {
    argv        => \@argv,
    'fork'      => $fork,
    crontab     => $crontab,
} );

1;

=head1 NAME

[% appprefix %]_jobqueue.pl - Catalyst JobQueue

=head1 SYNOPSIS

[% appprefix %]_jobqueue.pl [options]

 Options:
   -d -debug          force debug mode
   -f -fork           handle each request in a new process
                      (defaults to false)
   -c -crontab        name of the crontab file
   -? -help           display this help and exits

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Run a Catalyst JobQueue for this application.

=head1 AUTHOR

Gruen Christian-Rolf, C<kiki@bsdro.org>

=head1 COPYRIGHT

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__crontab__
# JobQueue crontab
#
#minute hour    mday    month   wday    who     command
#
#*       *       *       *       *       root    /test/job
