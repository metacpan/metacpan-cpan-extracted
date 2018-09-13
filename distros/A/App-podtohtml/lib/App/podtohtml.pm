package App::podtohtml;

our $DATE = '2018-09-11'; # DATE
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use warnings;
use FindBin '$Bin';

use File::chdir;

our %SPEC;

sub _list_templates_or_get_template_tarball {
    require File::ShareDir;

    my $which = shift;

    my @dirs = (
        "$CWD/share",
        "$Bin/../share",
        File::ShareDir::dist_dir('App-podtohtml'),
    );
    my %templates;
    for my $dir (@dirs) {
        next unless -d "$dir/templates";
        local $CWD = "$dir/templates";
        for my $e (glob "*.tar") {
            my ($name) = $e =~ /(.+)\.tar$/;
            if ($which eq 'list_templates') {
                $templates{$name}++;
            } elsif ($which eq 'get_template_tarball') {
                if ($name eq $_[0]) {
                    return "$CWD/$e";
                }
            }
        }
    }

    if ($which eq 'list_templates') {
        return [sort keys %templates];
    } elsif ($which eq 'get_template_tarball') {
        return undef;
    }
    undef;
}

sub _list_templates {
    _list_templates_or_get_template_tarball('list_templates', @_);
}

sub _get_template_tarball {
    _list_templates_or_get_template_tarball('get_template_tarball', @_);
}

$SPEC{podtohtml} = {
    v => 1.1,
    summary => 'Convert POD to HTML',
    description => <<'_',

This is a thin wrapper for <pm:Pod::Html> and an alternative CLI to
<prog:pod2html> to remove some annoyances that I experience with `pod2html`,
e.g. the default cache directory being `.` (so it leaves `.tmp` files around).
This CLI also offers templates and tab completion.

It does not yet offer as many options as `pod2html`.

_
    args => {
        infile => {
            summary => 'Input file (POD)',
            description => <<'_',

If not found, will search in for .pod or .pm files in `@INC`.

_
            schema => 'perl::pod_or_pm_filename*',
            default => '-',
            pos => 0,
            cmdline_aliases => {i=>{}},
        },
        outfile => {
            schema => 'filename*',
            pos => 1,
            cmdline_aliases => {o=>{}},
        },
        browser => {
            summary => 'Instead of outputing HTML to STDOUT/file, '.
                'view it in browser',
            schema => ['bool*', is=>1],
            cmdline_aliases => {b=>{}},
        },
        list_templates => {
            summary => 'List available templates',
            schema => ['bool*', is=>1],
            cmdline_aliases => {l=>{}},
            tags => ['category:action', 'category:template'],
        },
        template => {
            summary => 'Pick a template to use, only relevant with --browser',
            schema => ['str*'],
            cmdline_aliases => {t=>{}},
            tags => ['category:template'],
            completion => sub {
                require App::podtohtml; # this weird thing is when we are run in _podtohtml
                require Complete::Util;
                my %args = @_;
                Complete::Util::complete_array_elem(
                    word => $args{word},
                    array => App::podtohtml::_list_templates(),
                );
            },
        },
    },
    args_rels => {
        choose_one => [qw/outfile browser/],
    },
    examples => [
        {
            argv => [qw/some.pod/],
            summary => 'Convert POD file to HTML, print result to STDOUT',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/some.pod -b/],
            summary => 'Convert POD file to HTML, show result in browser',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/some.pod -b -t metacpan-20180911/],
            summary => 'Convert POD file to HTML, show result in browser using the MetaCPAN template to give an idea how it will look on MetaCPAN',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/some.pod -b -t sco-20180123/],
            summary => 'Convert POD file to HTML, show result in browser using the sco template to give an idea how it will look on (now-dead) search.cpan.org',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/some.pod -b -t perldoc_perl_org-20180911/],
            summary => 'Convert POD file to HTML, show result in browser using the perldoc.perl.org template to give an idea how it will look on perldoc.perl.org',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/-l/],
            summary => 'List which templates are available',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub podtohtml {
    require File::Slurper;
    require File::Temp;
    require Pod::Html;

    my %args = @_;

    if ($args{list_templates}) {
        return [200, "OK", _list_templates()];
    }

    my $infile  = $args{infile} // '-';
    my $outfile = $args{outfile} // '-';
    my $browser = $args{browser};

    unless (-f $infile) {
        return [404, "No such file '$infile'"];
    }

    my $tempdir = File::Temp::tempdir();

    Pod::Html::pod2html(
        ($infile eq '-' ? () : ("--infile=$infile")),
        "--outfile=$tempdir/outfile.html",
        "--cachedir=$tempdir",
    );

    if ($browser) {
        require Browser::Open;

        my $url = "file:$tempdir/outfile.html";

      USE_TEMPLATE: {
            my $tmplname = $args{template};
            last unless defined $tmplname;
            my $tarball_path = _get_template_tarball($tmplname);
            unless ($tarball_path) {
                warn "podtohtml: Cannot find template '$tmplname', use -l to list available templates\n";
                last;
            }

            require Archive::Tar;
            my $tar = Archive::Tar->new;
            $tar->read($tarball_path);
            local $CWD = $tempdir;
            $tar->extract;

            my $content = File::Slurper::read_text("outfile.html");
            my ($rpod) = $content =~ m!(<ul.+)</body>!s
                or die "podtohtml: Cannot extract rendered POD from output file\n";

            my $tmplcontent = File::Slurper::read_text("$tmplname/$tmplname.html");
            $tmplcontent =~ s{<!--TEMPLATE:BEGIN_POD-->.+<!--TEMPLATE:END_POD-->}{$rpod}s
                or die "podtohtml: Cannot insert rendered POD to template\n";
            File::Slurper::write_text("$tmplname/$tmplname.html", $tmplcontent);

            $url = "file:$tempdir/$tmplname/$tmplname.html";
        } # USE_TEMPLATE

        my $err = Browser::Open::open_browser($url);
        return [500, "Can't open browser"] if $err;
        [200];
    } elsif ($outfile eq '-') {
        local $/;
        open my $ofh, "<", "$tempdir/outfile.html";
        my $content = <$ofh>;
        [200, "OK", $content, {'cmdline.skip_format'=>1}];
    } else {
        [200, "OK"];
    }
}

1;
# ABSTRACT: Convert POD to HTML

__END__

=pod

=encoding UTF-8

=head1 NAME

App::podtohtml - Convert POD to HTML

=head1 VERSION

This document describes version 0.006 of App::podtohtml (from Perl distribution App-podtohtml), released on 2018-09-11.

=head1 FUNCTIONS


=head2 podtohtml

Usage:

 podtohtml(%args) -> [status, msg, result, meta]

Convert POD to HTML.

Examples:

=over

=item * Convert POD file to HTML, print result to STDOUT:

 podtohtml( infile => "some.pod");

=item * Convert POD file to HTML, show result in browser:

 podtohtml( infile => "some.pod", browser => 1);

=item * Convert POD file to HTML, show result in browser using the MetaCPAN template to give an idea how it will look on MetaCPAN:

 podtohtml( infile => "some.pod", browser => 1, template => "metacpan-20180911");

=item * Convert POD file to HTML, show result in browser using the sco template to give an idea how it will look on (now-dead) search.cpan.org:

 podtohtml( infile => "some.pod", browser => 1, template => "sco-20180123");

=item * Convert POD file to HTML, show result in browser using the perldoc.perl.org template to give an idea how it will look on perldoc.perl.org:

 podtohtml(
   infile   => "some.pod",
   browser  => 1,
   template => "perldoc_perl_org-20180911"
 );

=item * List which templates are available:

 podtohtml( list_templates => 1);

=back

This is a thin wrapper for L<Pod::Html> and an alternative CLI to
L<pod2html> to remove some annoyances that I experience with C<pod2html>,
e.g. the default cache directory being C<.> (so it leaves C<.tmp> files around).
This CLI also offers templates and tab completion.

It does not yet offer as many options as C<pod2html>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<browser> => I<bool>

Instead of outputing HTML to STDOUT/file, view it in browser.

=item * B<infile> => I<perl::pod_or_pm_filename> (default: "-")

Input file (POD).

If not found, will search in for .pod or .pm files in C<@INC>.

=item * B<list_templates> => I<bool>

List available templates.

=item * B<outfile> => I<filename>

=item * B<template> => I<str>

Pick a template to use, only relevant with --browser.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-podtohtml>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-podtohtml>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-podtohtml>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<pod2html>, L<Pod::Html>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
