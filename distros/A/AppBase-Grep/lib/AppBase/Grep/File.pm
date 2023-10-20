package AppBase::Grep::File;

use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-22'; # DATE
our $DIST = 'AppBase-Grep'; # DIST
our $VERSION = '0.011'; # VERSION

our %argspecs_files = (
    files => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'file',
        schema => ['array*', of=>'filename*'],
        pos => 1,
        slurpy => 1,
    },
    recursive => {
        summary => 'Read all files under each directory, recursively, following symbolic links only if they are on the command line',
        schema => 'true*',
        cmdline_aliases => {r => {}},
    },
    dereference_recursive => {
        summary => 'Read all files under each directory, recursively, following all symbolic links, unlike -r',
        schema => 'true*',
        cmdline_aliases => {R => {}},
    },
);

sub _find_files {
    my ($dir, $ary, $follow) = @_;

    require File::Find;
    File::Find::find({
        follow => $follow,
        wanted => sub {
            if (-f $_) {
                no warnings 'once';
                my $path = "$File::Find::dir/$_";
                push @$ary, $path;
            }
        },
    }, $dir);
}

# will set $args->{_source}
sub set_source_arg {
    my $args = shift;

    my @files = @{ $args->{files} // [] };

    # pattern (arg0) can actually be a file or regexp
    if (defined $args->{pattern}) {
        if ($args->{regexps} && @{ $args->{regexps} }) {
            unshift @files, delete $args->{pattern};
        } else {
            unshift @{ $args->{regexps} }, delete $args->{pattern};
        }
    }

    if ($args->{recursive} || $args->{dereference_recursive}) {
        my $i = -1;
        while (++$i < @files) {
            if (-d $files[$i]) {
                my $more_files = [];
                my $follow = $args->{dereference_recursive} ? 1:0;
                _find_files($files[$i], $more_files, $follow);
                splice @files, $i, 1, @$more_files;
                $i += @$more_files-1;
            }
        }
    }

    my ($fh, $file);
    my $show_label = 0;
    if (!@files) {
        $file = "(stdin)";
        $fh = \*STDIN;
    } elsif (@files > 1) {
        $show_label = 1;
    }

    $args->{_source} = sub {
      READ_LINE:
        {
            if (!defined $fh) {
                return unless @files;
                $file = shift @files;
                log_trace "Opening $file ...";
                open $fh, "<", $file or do {
                    warn "abgrep: Can't open '$file': $!, skipped\n";
                    undef $fh;
                };
                redo READ_LINE;
            }

            my $line = <$fh>;
            if (defined $line) {
                return ($line, $show_label ? $file : undef);
            } else {
                undef $fh;
                redo READ_LINE;
            }
        }
    };
}

1;
# ABSTRACT: Resources for AppBase::Grep-based scripts that use file sources

__END__

=pod

=encoding UTF-8

=head1 NAME

AppBase::Grep::File - Resources for AppBase::Grep-based scripts that use file sources

=head1 VERSION

This document describes version 0.011 of AppBase::Grep::File (from Perl distribution AppBase-Grep), released on 2023-07-22.

=head1 FUNCTIONS

=head2 set_source_arg

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/AppBase-Grep>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-AppBase-Grep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=AppBase-Grep>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
