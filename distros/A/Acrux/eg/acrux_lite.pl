#!/usr/bin/perl -w
use strict;

# perl -Ilib eg/acrux_lite.pl ver
# perl -Ilib eg/acrux_lite.pl test 1 2 3
# perl -Ilib eg/acrux_lite.pl error

use Acme::Crux;
use Acrux::Util qw/dumper color/;

my $app = Acme::Crux->new(
    project => 'MyApp',
    preload => [], # disable preloading all system plugins
);
#print Acrux::Util::dumper($app);

$app->register_handler; # default

$app->register_handler(
    handler     => "version",
    aliases     => "ver",
    description => "Prints version",
    code => sub {
### CODE:
    my ($self, $meta, @args) = @_;
    printf "%s (%s) Version %s\n", $self->project, $self->moniker, $self->VERSION;
    return 1;
});

$app->register_handler(
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

$app->register_handler(
    handler     => "error",
    description => "Error test handler",
    code => sub {
### CODE:
    my ($self, $meta, @args) = @_;
    $self->error("My test error string");
    return 0;
});

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
