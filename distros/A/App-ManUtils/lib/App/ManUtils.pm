package App::ManUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
#use Log::Any::IfLOG '$log';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-21'; # DATE
our $DIST = 'App-ManUtils'; # DIST
our $VERSION = '0.003'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to man(page)',
};

$SPEC{manwhich} = {
    v => 1.1,
    summary => "Get path to manpage",
    args => {
        pages => {
            'x.name.is_plural' => 1,
            schema => ['array*' => of=>'str*', min_len=>1],
            req    => 1,
            pos    => 0,
            slurpy => 1,
            element_completion => sub {
                require Complete::Man;

                my %args = @_;

                # XXX restrict only certain section
                Complete::Man::complete_manpage(
                    word => $args{word},
                );
            },
        },
        all => {
            summary => 'Return all found paths for each page instead of the first one',
            schema => 'bool',
            cmdline_aliases => {a=>{}},
        },
        #section => {
        #},
    },
};
sub manwhich {
    my %args = @_;

    my $pages = $args{pages};
    my $all   = $args{all};

    #my $sect = $args{section};
    #if (defined $sect) {
    #    $sect = [map {/\Aman/ ? $_ : "man$_"} split /\s*,\s*/, $sect];
    #}

    require Filename::Type::Compressed;

    my @res;
    for my $dir (split /:/, ($ENV{MANPATH} // '')) {
        next unless -d $dir;
        opendir my($dh), $dir or next;
        for my $sectdir (readdir $dh) {
            next unless $sectdir =~ /\Aman/;
            #next if $sect && !grep {$sectdir eq $_} @$sect;
            opendir my($dh), "$dir/$sectdir" or next;
            my @files = readdir($dh);
            for my $file (@files) {
                next if $file eq '.' || $file eq '..';
                my $chkres = Filename::Type::Compressed::check_compressed_filename(
                    filename => $file,
                );
                my $name = $chkres ? $chkres->{uncompressed_filename} : $file;
                $name =~ s/\.\w+\z//; # strip section name
                for my $page (@$pages) {
                    if ($page eq $name) {
                        push @res, {
                            page => $page,
                            path => "$dir/$sectdir/$file",
                        };
                        last unless $all;
                    }
                }
            }
        }
    }

    my $res;
    if (@$pages > 1 || $all) {
        $res = \@res;
    } else {
        $res = $res[0]{path};
    }

    [200, "OK", $res];
}

$SPEC{manlist} = {
    v => 1.1,
    summary => "List manpages",
    description => <<'_',

This utility is like `apropos` (and indeed it uses `apropos` mostly) but
returned structured results.

_
    args => {
        use_mandb => {
            schema => 'bool*',
            default => 1,
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub manlist {
    require File::Which;

    my %args = @_;
    my $use_mandb = $args{use_mandb} // 1;

    return [200, "Empty, no MANPATH", []] unless $ENV{MANPATH};

    my @rows;

    if ($use_mandb && File::Which::which("apropos")) {
        # it's simpler to just use 'apropos' to read mandb, instead of directly
        # reading dbm file and the screwed up situation of the availability of
        # *DBM_File.
        for my $line (`apropos -r .`) {
            $line =~ /^(\S+?) \(([^)]+)\)\s*-/ or next;
            push @rows, {
                page => $1,
                section => $2,
            };
        }
    } else {
        # in the absence of 'apropos', list the man files. slooow.
        require Filename::Type::Compressed;

        for my $dir (split /:/, $ENV{MANPATH}) {
            next unless -d $dir;
            opendir my($dh), $dir or next;
            for my $sectdir (readdir $dh) {
                next unless $sectdir =~ /\Aman/;
                opendir my($dh), "$dir/$sectdir" or next;
                my @files = readdir($dh);
                for my $file (@files) {
                    next if $file eq '.' || $file eq '..';
                    my $chkres =
                        Filename::Type::Compressed::check_compressed_filename(
                            filename => $file,
                        );
                    my $name = $chkres ?
                        $chkres->{uncompressed_filename} : $file;
                    $name =~ s/\.(\w+)\z//;
                    push @rows, {
                        page => $name,
                        section => $1,
                        file => "$sectdir/$file",
                    };
                }
            }
        }
    }

    unless ($args{detail}) {
        @rows = map { $_->{page} } @rows;
    }

    [200, "OK", \@rows];
}

$SPEC{manlistsect} = {
    v => 1.1,
    summary => "List manpage sections",
    description => <<'_',


_
    args => {
    },
};
sub manlistsect {
    my %args = @_;

    my $res = manlist(%args, detail=>1);
    return $res unless $res->[0] == 200;

    my %seen_sections;
    for my $row (@{ $res->[2] }) {
        $seen_sections{ $row->{section} }++;
    }

    [200, "OK", [sort keys %seen_sections]];
}

1;
# ABSTRACT: Utilities related to man(page)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ManUtils - Utilities related to man(page)

=head1 VERSION

This document describes version 0.003 of App::ManUtils (from Perl distribution App-ManUtils), released on 2024-12-21.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to man(page):

=over

=item * L<list-manpage-sections>

=item * L<list-manpages>

=item * L<manlist>

=item * L<manlistsect>

=item * L<manwhich>

=back

=head1 FUNCTIONS


=head2 manlist

Usage:

 manlist(%args) -> [$status_code, $reason, $payload, \%result_meta]

List manpages.

This utility is like C<apropos> (and indeed it uses C<apropos> mostly) but
returned structured results.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)

=item * B<use_mandb> => I<bool> (default: 1)

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 manlistsect

Usage:

 manlistsect() -> [$status_code, $reason, $payload, \%result_meta]

List manpage sections.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 manwhich

Usage:

 manwhich(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get path to manpage.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<bool>

Return all found paths for each page instead of the first one.

=item * B<pages>* => I<array[str]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ManUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ManUtils>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ManUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
