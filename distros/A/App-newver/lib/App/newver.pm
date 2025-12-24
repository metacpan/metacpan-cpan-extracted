package App::newver;
use 5.016;
use strict;
use warnings;
our $VERSION = '0.01';

use File::Basename;
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;

use Parallel::ForkManager;

use App::newver::INI qw(read_ini);
use App::newver::Scanner qw(scan_version);

my $PRGNAM = 'newver';
my $PRGVER = $VERSION;

my $USAGE = <<"HERE";
Usage:
  newver [options] file [program] ...

Options:
  -j|--json      Output report in JSON
  -s|--serial    Scan pages serially instead of in parallel
  -V|--verbose   Enable verbose output
  -h|--help      Print usage and exit
  -v|--version   Print version and exit
HERE

sub _scan_for_version {

    my ($file, $match) = @_;

    $match =~ s/\@VERSION\@/$App::newver::Scanner::MAYBE_VERSION_RX/g
        or die "'Match' missing '\@VERSION\@'\n";
    $match = qr/$match/;

    open my $fh, '<', $file or die "Failed to open $file for reading: $!\n";
    while (my $l = readline $fh) {
        chomp $l;
        $l =~ $match or next;
        return $+{ Version };
    }

    return undef;

}

sub _read_config {

    my ($self) = @_;

    my $ini = read_ini($self->{ ScanFile });
    for my $program (keys %$ini) {
        my $version;
        if (defined $ini->{ $program }{ Version }) {
            $version = $ini->{ $program }{ Version };
        } elsif (defined $ini->{ $program }{ VersionScan }) {
            my ($f, $m) = $ini->{ $program }{ VersionScan } =~ /^\s*(.+?)\s*--\s*(.+?)\s*$/;
            my $inidir = (fileparse($self->{ ScanFile }))[1];
            if (!File::Spec->file_name_is_absolute($f)) {
                $f = File::Spec->catfile($inidir, $f);
            }
            $version = _scan_for_version($f, $m)
                // die "Found no version matching /$m/ in $f\n";
        } else {
            die "[$program] missing required field 'Version' or 'VersionScan'\n";
        }
        my $page = $ini->{ $program }{ Page }
            // die "[$program] missing required field 'Page'\n";
        my $match = $ini->{ $program }{ Match }
            // die "[$program] missing required field 'Match'\n";
        my $return = $ini->{ $program }{ ReturnURL };
        push @{ $self->{ Programs } }, {
            Program   => $program,
            Version   => $version,
            Page      => $page,
            Match     => $match,
            ReturnURL => $return,
        };
    }

}

sub init {

    my ($class, @argv) = @_;

    my $self = {
        ScanFile => undef,
        ToDos    => undef,
        Programs => [],
        JSON     => 0,
        Parallel => 1,
        Verbose  => 0,
    };

    Getopt::Long::config("no_ignore_case");
    GetOptionsFromArray(\@argv,
        'j|json'    => \$self->{ JSON },
        's|serial'  => sub { $self->{ Parallel } = 0 },
        'V|verbose' => \$self->{ Verbose },
        'h|help'    => sub { print $USAGE; exit 0 },
        'v|version' => sub { say $PRGVER; exit 0 },
    ) or die $USAGE;

    $self->{ ScanFile } = shift @argv;
    if (not defined $self->{ ScanFile }) {
        die $USAGE;
    }

    if (@argv) {
        %{ $self->{ ToDos } } = map { $_ => 1 } @argv;
    }

    bless $self, $class;

    $self->_read_config;
    if (!@{ $self->{ Programs } }) {
        die "$self->{ ScanFile } does not contain any programs\n";
    }

    return $self;

}

sub log_msg {

    my ($self, @msg) = @_;

    if ($self->{ Verbose }) {
        say STDERR @msg;
    }

}

sub _print_scans_text {

    my (@scans) = @_;

    @scans = sort { $a->{ program } cmp $b->{ program } } @scans;

    for my $s (@scans) {
        print <<"HERE";
$s->{ program }
    Current: $s->{ current }
    New:     $s->{ version }
    URL:     $s->{ url }
HERE
    }

}

sub _print_scans_json {

    my (@scans) = @_;

    my $marshaler = {};
    for my $s (@scans) {
        # Force all values into strings
        for my $k (keys %$s) {
            $marshaler->{ $s->{ program } }{ $k } = "$s->{ $k }";
        }
    }

    my $json = JSON::PP->new->canonical->pretty;

    print $json->encode($marshaler);

}

sub run_parallel {

    my ($self) = @_;

    my @scanned;

    my $pm = Parallel::ForkManager->new(10);
    $pm->run_on_finish(sub {
        my ($code, $job) = @_[1, 5];
        if ($code == 0 and defined $job) {
            push @scanned, $job;
        }
    });

    SCAN:
    for my $j (@{ $self->{ Programs } }) {
        my $pid = $pm->start and next SCAN;
        if (defined $self->{ ToDos } and !$self->{ ToDos }{ $j->{ Program } }) {
            $pm->finish(0, undef);
        }
        my $scan = scan_version(
            program => $j->{ Program },
            version => $j->{ Version },
            match   => $j->{ Match },
            page    => $j->{ Page },
        );
        $self->log_msg("Scanned $j->{ Page }");
        if (defined $scan) {
            $scan->{ current } = $j->{ Version };
            if (defined $j->{ ReturnURL }) {
                $scan->{ url } = $j->{ ReturnURL } =~ s/\@VERSION\@/$scan->{ version }/gr;
            }
        }
        $pm->finish(0, $scan);
    }

    $pm->wait_all_children;

    if (!@scanned) {
        $self->log_msg("No new versions found");
    }

    if ($self->{ JSON }) {
        _print_scans_json(@scanned);
    } else {
        _print_scans_text(@scanned);
    }

}

sub run_serial {

    my ($self) = @_;

    my @scanned;
    for my $j (@{ $self->{ Programs } }) {
        if (defined $self->{ ToDos } and !$self->{ ToDos }{ $j->{ Program } }) {
            continue;
        }
        my $scan = scan_version(
            program => $j->{ Program },
            version => $j->{ Version },
            match   => $j->{ Match },
            page    => $j->{ Page },
        );
        $self->log_msg("Scanned $j->{ Page }");
        if (defined $scan) {
            $scan->{ current } = $j->{ Version };
            if (defined $j->{ ReturnURL }) {
                $scan->{ url } = $j->{ ReturnURL } =~ s/\@VERSION\@/$scan->{ version }/gr;
            }
            push @scanned, $scan;
        }
    }

    if (!@scanned) {
        $self->log_msg("No new versions found");
    }

    if ($self->{ JSON }) {
        _print_scans_json(@scanned);
    } else {
        _print_scans_text(@scanned);
    }

}


sub run {

    my ($self) = @_;

    if ($self->{ Parallel }) {
        $self->run_parallel;
    } else {
        $self->run_serial;
    }

}

1;

=head1 NAME

App::newver - Scan upstream for new software versions

=head1 SYNOPSIS

  use App::newver;

  my $newver = App::newver->init(@ARGV);
  $newver->run;

=head1 DESCRIPTION

B<App::newver> is the main backend module for L<newver>. This is a private
module, please consult the L<newver> manual for user documentation.

=head1 METHODS

=head2 $newver = App::newver->init(@argv)

Initializes B<App::newver> object, reading command-line arguments from
C<@argv>.

=head2 $new->run

Runs L<newver> based on the arguments processed during C<init()>.

=head1 AUTHOR

Written by L<Samuel Young|samyoung12788@gmail.com>

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/newver.git>. Comments and pull
requests are welcome.

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

=head1 SEE ALSO

L<newver>

=cut
