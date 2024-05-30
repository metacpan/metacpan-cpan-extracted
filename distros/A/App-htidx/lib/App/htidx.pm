package App::htidx;
# ABSTRACT: generate static HTML directory listings.
use Carp;
use Cwd qw(abs_path);
use File::Basename qw(basename dirname);
use File::Spec;
use File::Temp;
use File::stat;
use HTML::Tiny;
use List::Util qw(any);
use POSIX qw(strftime ceil);
use constant {
    INDEX_FILE  => 'index.html',
    SIGNATURE   => '@~@ I was made by App::htidx @~@',
    TIMEFMT     => '%Y-%m-%d %H:%M:%S %Z',
};
use feature qw(say);
use open qw(:encoding(utf8));
use strict;
use utf8;
use vars qw($VERSION $H $CSS);
use warnings;


$VERSION = '0.01';

$H = HTML::Tiny->new(mode => 'html');

undef $/;
$CSS = <DATA>;

sub main {
    help() if (any { '-h' eq $_ || '--help' eq $_ } @_);

    my $dir = abs_path(shift(@_));

    croak("Error: $dir does not exist") unless (-e $dir);
    croak("Error: $dir is not a directory") unless (-d $dir);

    mkindex($dir, 1);

    say STDERR 'htidx: done';

    return 0;
}

sub help {
    say "Usage: $0 DIRECTORY";
    exit;
}

sub mkindex {
    my ($dir, $toplevel) = @_;

    printf STDERR "htidx: generating directory listing for %s...\n", $dir;

    my $index = File::Spec->catfile($dir, INDEX_FILE);

    opendir(my $dh, $dir);

    my @entries = sort grep { 0 != index($_, '.') } readdir($dh);

    closedir($dh);

    my (@dirs, @files);
    foreach my $entry (sort(@entries)) {
        my $path = File::Spec->catfile($dir, $entry);

        if (-d $path || (-l $path && -d readlink($path))) {
            push(@dirs, $entry);

        } elsif (lc($entry) ne lc(INDEX_FILE)) {
            push(@files, $entry);

        }
    }

    my $mkhtml = scalar(grep { /^index\./i } @files) < 1;

    if (-e $index) {
        open(my $fh, $index);

        while (!$fh->eof) {
            if (index($fh->getline, SIGNATURE) >= 0) {
                $mkhtml = 1;
                last;
            }
        }

        $fh->close;
    }

    mkhtml($index, $dir, $toplevel, \@dirs, \@files) if ($mkhtml);

    map { mkindex(File::Spec->catfile($dir, $_)) } @dirs;
}

sub mkhtml {
    my ($index, $dir, $toplevel, $dref, $fref) = @_;

    my $tmpfile = File::Temp::tempnam($dir, '.mkindex');

    open(my $fh, '>', $index) || die("$index: $!");

    my $title = sprintf('Directory listing of %s/', basename($dir));

    $fh->say('<!doctype html>');
    $fh->say(sprintf('<!-- %s -->', he(SIGNATURE)));
    $fh->say($H->open('html', {lang => 'en'}));

    $fh->say($H->head([
    $H->meta({charset => 'UTF-8'}),
        $H->title(he($title)),
        $H->meta({name => 'generator', content => sprintf('%s v%s', __PACKAGE__, $VERSION)}),
        $H->meta({name => 'viewport', content => 'width=device-width'}),
        $H->style(he($CSS)),
    ]));

    $fh->say($H->open('body', { class => 'htidx-body' }));

    $fh->say($H->h1($title));

    $fh->say($H->open('table'));

    $fh->say($H->thead($H->tr([map { $H->th($_) } ('Name', 'Last Modified', 'Size') ])));

    $fh->say($H->open('tbody'));

    $fh->say($H->tr(
        { class => 'htidx-directory' },
        [
            $H->td($H->a(
                { href => '..'},
                'Parent Directory'
            )),
            $H->td(strftime(TIMEFMT, localtime(stat(File::Spec->catfile(dirname($dir)))->mtime))),
            $H->td('-')
        ]
    )) unless ($toplevel);

    foreach my $entry (@{$dref}) {
        $fh->say($H->tr(
            { class => 'htidx-directory' },
            [ map { $H->td($_) } (
                $H->a(
                    { href => $entry},
                    he($entry.'/')
                ),
                strftime(TIMEFMT, localtime(stat(File::Spec->catfile($dir, $entry))->mtime)),
                '-',
            ) ]
        ));
    }

    foreach my $entry (@{$fref}) {
        my $stat = stat(File::Spec->catfile($dir, $entry));

        $fh->say($H->tr(
            { class => 'htidx-file' },
            [ map { $H->td($_) } (
                $H->a(
                    { href => $entry },
                    he($entry)
                ),
                strftime(TIMEFMT, localtime($stat->mtime)),
                fsize($stat->size),
            ) ]
        ));
    }

    map { $fh->say($H->close($_)) } qw(tbody table body html);

    $fh->close;

    rename($tmpfile, $index);
}

sub fsize {
    my $size = shift;
    if ($size < 1000) {
        return '1K';

    } elsif ($size < 1000 * 1000) {
        return sprintf('%uK', ceil($size / 1000));

    } elsif ($size < 1000 * 1000 * 1000) {
        return sprintf('%uM', ceil($size / (1000 * 1000)));
 
    } else {
        return sprintf('%uG', ceil($size / (1000 * 1000 * 1000)));

    }
}

sub he { $H->entity_encode(@_) }

1;

=pod

=encoding UTF-8

=head1 NAME

App::htidx - generate static HTML directory listings.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

Run C<htidx> on the command line:

    htidx DIRECTORY

Or in in your Perl scripts:

    use App::htidx;

    App::htidx::main($DIRECTORY);

=head1 INTRODUCTION

C<App::htidx> generates static HTML directory listings for a directory tree.
This is useful in scenarios where you are using a static hosting service (such
as GitHub Pages) which doesn't auto-index directories which don't contain an
C<index.html>.

=head1 DIRECTORY INDEX FILES

C<App::htidx> will create an C<index.html> file in each directory, unless one
or more files matching the pattern C<index.*> exist.

If C<index.html> exists and was previously created by C<App::htidx> then it will
be overwritten, otherwise it will be left as-is.

=head1 AUTHOR

Gavin Brown <gavin.brown@fastmail.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Gavin Brown.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
th {
    text-align:left;
}

td {
    white-space: nowrap;
}

th:nth-child(2), th:nth-child(3), td:nth-child(2), td:nth-child(3) {
    text-align:right;
}

table {
    border-spacing: 0;
}

td,th {
    margin: 0;
    padding: 0.25em 1em;
}

th {
    background-color: #e8e8e8;
}

tr:nth-child(even) {
    background-color: #f0f0f0;
}

tr:nth-child(odd) {
    background-color: #f8f8f8;
}
