package App::Ordo::Command::Help;
use Moo;
use feature qw(say);
use utf8;
use open ':std', ':utf8';
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);

has 'commands' => (is => 'ro', required => 0);

sub name    { "help" }
sub summary { "Show help information" }
sub usage   { "[topic]" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, @topic_parts) = @_;
    shift @topic_parts;
    my $topic = join ' ', @topic_parts;

    if (!$topic) {
        $self->_help_overview;
        return;
    }

    $self->_help_topic($topic);
}

sub _help_topic {
    my ($self, $topic) = @_;
    $topic =~ s/^\s+|\s+$//g;

    my @parts = split /\s+/, $topic;
    my $cmd_class = "App::Ordo::Command::" . join('::', map { ucfirst lc } @parts);

    if (eval "require $cmd_class; 1") {
        $cmd_class->new(api => $self->api)->show_help;
    } else {
        say colored(["bold red"], "No help available for '$topic'");
        say "Try 'help' for a list of commands";
    }
}

sub _help_overview {
    my ($self) = @_;

    say colored(["bold cyan"],   "Usage:");
    say "  ordo                                 # interactive shell";
    say "  ordo <command> [args]                # one-shot mode\n";

    say colored(["bold yellow"], "Commands:\n");

    my %groups = (
        Navigation => [],
        Jobs       => [],
        Clusters   => [],
        Calendars  => [],
        Servers    => [],
        User       => [],
        System     => [],
    );

    $self->_walk_tree($self->commands, \%groups, []);

    for my $group (qw(Navigation Jobs Clusters Calendars Servers User System)) {
        say colored(["bold green"], "  $group:");
        if (@{$groups{$group}}) {
            my $max = 0;
            $max = length($_->[0]) > $max ? length($_->[0]) : $max for @{$groups{$group}};
            printf "    %-*s  %s\n", $max + 4, $_->[0], $_->[1] for @{$groups{$group}};
        } else {
            say "    (no commands)";
        }
        say "";
    }

    say colored(["bold magenta"], "Examples:");
    say "  server add myserver --host 192.168.1.100 --user alice";
    say "  cluster create mycluster";
    say "  job create mycluster/myjob --server myserver --script 'ls -ltr'";

    say "\nType 'help <command>' for detailed help";
}

sub _walk_tree {
    my ($self, $node, $groups, $path) = @_;

    if (ref $node eq 'HASH') {
        for my $key (keys %$node) {
            $self->_walk_tree($node->{$key}, $groups, [@$path, $key]);
        }
    } else {
        my $class = $node;
        my $name = join ' ', @$path;

        my $summary = "no description";
        if (eval "require $class; 1") {
            $summary = eval { $class->new(api => $self->api)->summary } || "no description";
        }

        if ($name =~ /^job /i) {
            push @{$groups->{Jobs}}, [$name, $summary];
        }
        elsif ($name =~ /^cluster /i) {
            push @{$groups->{Clusters}}, [$name, $summary];
        }
        elsif ($name =~ /^cal /i) {
            push @{$groups->{Calendars}}, [$name, $summary];
        }
        elsif ($name =~ /^server /i) {
            push @{$groups->{Servers}}, [$name, $summary];
        }
        elsif ($name =~ /^(ls|cd|pwd)$/i) {
            push @{$groups->{Navigation}}, [$name, $summary];
        }
        elsif ($name =~ /^user /i) {
            push @{$groups->{User}}, [$name, $summary];
        }
        else {
            push @{$groups->{System}}, [$name, $summary];
        }
    }
}

1;
