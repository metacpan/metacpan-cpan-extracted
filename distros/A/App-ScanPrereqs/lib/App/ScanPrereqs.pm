package App::ScanPrereqs;

our $DATE = '2017-03-08'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any '$log';

our %SPEC;

$SPEC{scan_prereqs} = {
    v => 1.1,
    summary => 'Scan source code for prerequisites',
    description => <<'_',

This is an alternative CLI to <pm:scan_prereqs>. This CLI offers alternate
backends: aside from <pm:Perl::PrereqScanner> you can also use
<pm:Perl::PrereqScanner::Lite> and <pm:Perl::PrereqScanner::NotQuiteLite>. Some
other features: output in various formats (text table, JSON), filter only core
or non-core prerequisites.

_
    args => {
        files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            schema => ['array*', of=>'pathname*'],
            default => ['.'],
            req => 1,
            pos => 0,
            greedy => 1,
        },
        scanner => {
            schema => ['str*', in=>['regular','lite','nqlite']],
            default => 'regular',
            summary => 'Which scanner to use',
            description => <<'_',

`regular` means <pm:Perl::PrereqScanner> which is PPI-based and is the slowest
but has the most complete support for Perl syntax.

`lite` means <pm:Perl::PrereqScanner::Lite> uses an XS-based lexer and is the
fastest but might miss some Perl syntax (i.e. miss some prereqs) or crash if
given some weird code.

`nqlite` means <pm:Perl::PrereqScanner::NotQuiteLite> which is faster than
`regular` but not as fast as `lite`.

Read respective scanner's documentation for more details about the pro's and
con's for each scanner.

_
        },
        perlver => {
            summary => 'Perl version to use when determining core/non-core',
            description => <<'_',

The default is the current perl version.

_
            schema => 'str*',
        },
        show_core => {
            schema => ['bool*'],
            default => 1,
            summary => 'Whether or not to show core prerequisites',
        },
        show_noncore => {
            schema => ['bool*'],
            default => 1,
            summary => 'Whether or not to show non-core prerequisites',
        },
    },
    examples => [
        {
            summary => 'By default scan current directory',
            args => {},
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub scan_prereqs {
    require Filename::Backup;
    require File::Find;

    my %args = @_;

    my $perlver = version->parse($args{perlver} // $^V);

    my $scanner = do {
        if ($args{scanner} eq 'lite') {
            require Perl::PrereqScanner::Lite;
            my $scanner = Perl::PrereqScanner::Lite->new;
            $scanner->add_extra_scanner('Moose');
            $scanner->add_extra_scanner('Version');
            $scanner;
        } elsif ($args{scanner} eq 'nqlite') {
            require Perl::PrereqScanner::NotQuiteLite;
            my $scanner = Perl::PrereqScanner::NotQuiteLite->new(
                parsers  => [qw/:installed -UniversalVersion/],
                suggests => 1,
            );
            $scanner;
        } else {
            require Perl::PrereqScanner;
            Perl::PrereqScanner->new;
        }
    };

    my %mods;
    my %excluded_mods;

    require File::Find;
    File::Find::find(
        sub {
            no warnings 'once';

            return unless -f;
            my $path = "$File::Find::dir/$_";
            if (Filename::Backup::check_backup_filename(filename=>$_)) {
                $log->debugf("Skipping backup file %s ...", $path);
                return;
            }
            if (/\A(\.git)\z/) {
                $log->debugf("Skipping %s ...", $path);
                return;
            }
            $log->debugf("Scanning file %s ...", $path);
            my $scanres = $scanner->scan_file($_);

            # if we use PP::NotQuiteLite, it returns PPN::Context which supports
            # a 'requires' method to return a CM:Requirements like the other
            # scanners
            my $prereqs = $scanres->can("requires") ?
                $scanres->requires->as_string_hash : $scanres->as_string_hash;

            if ($scanres->can("suggests") && (my $sugs = $scanres->suggests)) {
                # currently it's not clear what makes PP:NotQuiteLite determine
                # something as a suggests requirement, so we include suggests as
                # a normal requires requirement.
                $sugs = $sugs->as_string_hash;
                for (keys %$sugs) {
                    $prereqs->{$_} ||= $sugs->{$_};
                }
            }

            for my $mod (keys %$prereqs) {
                next if $excluded_mods{$mod};
                my $v = $prereqs->{$mod};
                if ($mod eq 'perl') {
                } elsif (!$args{show_core} || $args{show_noncore}) {
                    require Module::CoreList;
                    my $ans = Module::CoreList->is_core(
                        $mod, $v, $perlver);
                    if ($ans && !$args{show_core}) {
                        $log->debugf("Skipped prereq %s %s (core)", $mod, $v);
                        $excluded_mods{$mod} = 1;
                        next;
                    } elsif (!$ans && !$args{show_noncore}) {
                        $log->debugf("Skipped prereq %s %s (non-core)", $mod, $v);
                        $excluded_mods{$mod} = 1;
                        next;
                    }
                }
                if (defined $mods{$mod}) {
                    $mods{$mod} = $v if
                        version->parse($v) > version->parse($mods{$mod});
                } else {
                    $log->infof("Added prereq %s (from %s)", $mod, $path);
                    $mods{$mod} = $v;
                }
            }

        },
        @{ $args{files} },
    );

    my @rows;
    my %resmeta = (
        'table.fields' => [qw/module version/],
    );
    for my $mod (sort {lc($a) cmp lc($b)} keys %mods) {
        push @rows, {module=>$mod, version=>$mods{$mod}};
    }

    [200, "OK", \@rows, \%resmeta];
}

1;
# ABSTRACT: Scan source code for prerequisites

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ScanPrereqs - Scan source code for prerequisites

=head1 VERSION

This document describes version 0.002 of App::ScanPrereqs (from Perl distribution App-ScanPrereqs), released on 2017-03-08.

=head1 SYNOPSIS

 # Use via lint-prereqs CLI script

=head1 FUNCTIONS


=head2 scan_prereqs

Usage:

 scan_prereqs(%args) -> [status, msg, result, meta]

Scan source code for prerequisites.

Examples:

=over

=item * By default scan current directory:

 scan_prereqs();

=back

This is an alternative CLI to L<scan_prereqs>. This CLI offers alternate
backends: aside from L<Perl::PrereqScanner> you can also use
L<Perl::PrereqScanner::Lite> and L<Perl::PrereqScanner::NotQuiteLite>. Some
other features: output in various formats (text table, JSON), filter only core
or non-core prerequisites.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[pathname]> (default: ["."])

=item * B<perlver> => I<str>

Perl version to use when determining core/non-core.

The default is the current perl version.

=item * B<scanner> => I<str> (default: "regular")

Which scanner to use.

C<regular> means L<Perl::PrereqScanner> which is PPI-based and is the slowest
but has the most complete support for Perl syntax.

C<lite> means L<Perl::PrereqScanner::Lite> uses an XS-based lexer and is the
fastest but might miss some Perl syntax (i.e. miss some prereqs) or crash if
given some weird code.

C<nqlite> means L<Perl::PrereqScanner::NotQuiteLite> which is faster than
C<regular> but not as fast as C<lite>.

Read respective scanner's documentation for more details about the pro's and
con's for each scanner.

=item * B<show_core> => I<bool> (default: 1)

Whether or not to show core prerequisites.

=item * B<show_noncore> => I<bool> (default: 1)

Whether or not to show non-core prerequisites.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ScanPrereqs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ScanPrereqs>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ScanPrereqs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
