package App::sshwrap::hostcolor;

our $DATE = '2018-10-10'; # DATE
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

my $histname = ".sshwrap-hostcolor.history";

sub _history_path {
    require PERLANCAR::File::HomeDir;

    my $homedir = PERLANCAR::File::HomeDir::get_my_home_dir() or do {
        log_info "Couldn't get current user's homedir, bailing out";
        return;
    };
    return "$homedir/$histname";
}

sub read_history_file {
    my $histpath = _history_path or return {};

    log_trace "Reading history file $histpath ...";
    open my $fh, "<", $histpath or do {
        log_info "Couldn't read $histpath ($!), bailing out";
        return {};
    };
    my $hist = {};
    while (<$fh>) {
        /\S/ or next;
        /^\s*#/ and next;
        chomp;
        my @f = split /\s+/, $_;
        $hist->{$f[0]} = $f[1];
    }
    $hist;
}

sub write_history_file {
    my $hist = shift;

    my $histpath = _history_path or return;

    log_trace "Writing history file $histpath ...";
    open my $fh, ">", $histpath or do {
        log_info "Couldn't write $histpath ($!), bailing out";
        return;
    };

    for (sort keys %$hist) {
        print $fh "$_\t$hist->{$_}\n";
    }
    close $fh;
}

1;
# ABSTRACT: SSH wrapper script to remember the terminal background you use for each host

__END__

=pod

=encoding UTF-8

=head1 NAME

App::sshwrap::hostcolor - SSH wrapper script to remember the terminal background you use for each host

=head1 VERSION

This document describes version 0.006 of App::sshwrap::hostcolor (from Perl distribution App-sshwrap-hostcolor), released on 2018-10-10.

=head1 SYNOPSIS

See the included script L<sshwrap-hostcolor>.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-sshwrap-hostcolor>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-sshwrap-hostcolor>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-sshwrap-hostcolor>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
