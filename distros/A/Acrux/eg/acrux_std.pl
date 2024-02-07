#!/usr/bin/perl -w
use strict;

# perl -Ilib eg/acrux_std.pl ver
# perl -Ilib eg/acrux_std.pl test 1 2 3
# perl -Ilib eg/acrux_std.pl error
# perl -Ilib eg/acrux_std.pl noop

package MyApp;

use parent 'Acme::Crux';

use Acrux::Util qw/dumper color/;

our $VERSION = '1.00';

sub startup {
    my $self = shift;

    print color(green => "Start application"), "\n" ;

    return $self;
}

DESTROY {
    my $el = sprintf("%+.*f sec", 4, shift->elapsed);
    print color(green => "Finish application ($el)"), "\n" ;
}

__PACKAGE__->register_handler; # default

__PACKAGE__->register_handler( handler => "noop" );

__PACKAGE__->register_handler(
    handler     => "version",
    aliases     => "ver",
    description => "Prints version",
    code => sub {
### CODE:
    my ($self, $meta, @args) = @_;
    printf "%s (%s) Version %s\n", $self->project, $self->moniker, $self->VERSION;
    return 1;
});

__PACKAGE__->register_handler(
    handler     => "test",
    description => "Test handler",
    code => sub {
### CODE:
    my ($self, $meta, @args) = @_;
    print dumper({
            meta => $meta,
            args => \@args,
        });
    return 1;
});

__PACKAGE__->register_handler(
    handler     => "error",
    description => "Error test handler",
    code => sub {
### CODE:
    my ($self, $meta, @args) = @_;
    $self->error("My test error string");
    return 0;
});

1;

package main;

use Acrux::Util qw/dumper color/;

my $app = MyApp->new(
    project => 'MyApp',
    preload => [], # disable preloading all system plugins
);
#print dumper($app);

my $command = shift(@ARGV) // 'default';
my @arguments = @ARGV ? @ARGV : ();

# Check command
unless (grep {$_ eq $command} (@{ $app->handlers(1) })) {
    die color("bright_red" => "No handler $command found") . "\n";
}

# Run
my $exitval = $app->run($command, @arguments) ? 0 : 1;
warn color("bright_red" => $app->error) . "\n" and exit $exitval if $exitval;

1;

__END__
