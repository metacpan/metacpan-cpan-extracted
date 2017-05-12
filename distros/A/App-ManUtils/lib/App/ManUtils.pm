package App::ManUtils;

our $DATE = '2016-10-27'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
#use Log::Any::IfLOG '$log';

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
            greedy => 1,
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

    require Filename::Compressed;

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
                my $chkres = Filename::Compressed::check_compressed_filename(
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

1;
# ABSTRACT: Utilities related to man(page)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ManUtils - Utilities related to man(page)

=head1 VERSION

This document describes version 0.001 of App::ManUtils (from Perl distribution App-ManUtils), released on 2016-10-27.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to man(page):

=over

=item * L<manwhich>

=back

=head1 FUNCTIONS


=head2 manwhich(%args) -> [status, msg, result, meta]

Get path to manpage.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<bool>

Return all found paths for each page instead of the first one.

=item * B<pages>* => I<array[str]>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-ManUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ManUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ManUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
