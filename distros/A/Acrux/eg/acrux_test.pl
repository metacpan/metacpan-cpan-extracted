#!/usr/bin/perl -w
use strict;

# perl -Ilib eg/acrux_test.pl test 1 2 3

package MyApp;

use parent 'Acme::Crux';

use Acrux::Util qw/dumper color/;

our $VERSION = '1.00';

sub startup {
    my $self = shift;
    print sprintf(color(green => "Start application %s"), $self->project), "\n" ;

    # Set plugin 'Test'
    $self->plugin(Test => 'MyTestPlugin'); # $self->test;

    return $self;
}

DESTROY {
    my $el = sprintf("%+.*f sec", 4, $_[0]->elapsed);
    print sprintf(color(green => "Finish application %s ($el)"), $_[0]->project), "\n" ;
}

__PACKAGE__->register_handler; # default

__PACKAGE__->register_handler(
    handler     => "test",
    description => "Test handler",
    code => sub {
### CODE:
    my ($self, $meta, @args) = @_;
    $self->test; # Call created method

    #print dumper(
    #        "App:"  => $self,
    #        "Meta:" => $meta,
    #        "Args:" => \@args,
    #    );

    $self->log->debug(sprintf('Config value "/deep/foo/bar/test": >%s<',
        $self->config->get("/deep/foo/bar/test")));

    # Test log
    #$self->log->trace('Whatever');
    #$self->log->debug('You screwed up, but that is ok');
    #$self->log->info('You are bad, but you prolly know already');
    #$self->log->notice('Normal, but significant, condition...');
    #$self->log->warn('Dont do that Dave...');
    #$self->log->error('You really screwed up this time');
    #$self->log->fatal('Its over...');
    #$self->log->crit('Its over...');
    #$self->log->alert('Action must be taken immediately');
    #$self->log->emerg('System is unusable');

    return 1;
});

1;

package main;

use Getopt::Long;
use IO::Handle;
use Acrux::Util qw/dumper color/;

# Get options from command line
Getopt::Long::Configure("bundling");
GetOptions(my $options = {},
    "verbose|v",            # Verbose mode
    "debug|d",              # Debug mode
    "test|t",               # Test mode

    # Application
    "noload|n",             # NoLoad config file
    "config|conf|c=s",      # Config file
    "datadir|dir|D=s",      # DataDir

) || die color("bright_red" => 'Incorrect options'), "\n";
my $command = shift(@ARGV) // 'default';
my @arguments = @ARGV ? @ARGV : ();

# Create
my $app = MyApp->new(
    project     => 'MyApp',
    preload     => [qw/Config Log/], # disable preloading all system plugins
    options     => $options,
    root        => '.',
    configfile  => $options->{config} // 't/test.conf',
    verbose     => $options->{verbose},
    debug       => $options->{debug},
    test        => $options->{test},

    #config_noload => 1,
    loghandle   => IO::Handle->new_from_fd(fileno(STDOUT), "w"),
    logcolorize => 1

    # ($options->{datadir} ? (datadir => $options->{datadir}) : ()),

);

# Check command
unless (grep {$_ eq $command} (@{ $app->handlers(1) })) {
    die color("bright_red" => "No handler $command found") . "\n";
}

# Run
my $exitval = $app->run($command, @arguments) ? 0 : 1;
warn color("bright_red" => $app->error) . "\n" and exit $exitval if $exitval;

1;

package MyTestPlugin;
use warnings;
use strict;
use utf8;

our $VERSION = '0.01';

use parent 'Acme::Crux::Plugin';

use Acrux::Util qw/color/;

sub register {
    my ($self, $app, $args) = @_;
    print sprintf(color(bright_magenta => "Registered %s plugin"), $self->name), "\n";

    $app->register_method(test => sub { print color(red => "This test method created in plugin register"), "\n" });
    $app->log->debug(sprintf("Registered %s plugin", $self->name));

    return sprintf 'Ok! I am %s plugin!', $self->name;
}

1;

__END__
