package LWP::UserAgent::Patch::FilterLcpan;

our $DATE = '2019-06-19'; # DATE
our $VERSION = '1.034'; # VERSION

use 5.010001;
use strict;
no warnings;

use HTTP::Response;
use Module::Patch qw();
use base qw(Module::Patch);

our %config;

my $p_mirror = sub {
    use experimental 'smartmatch';

    my $ctx  = shift;
    my $orig = $ctx->{orig};

    my ($self, $url, $file) = @_;

    state $include_author;
    state $exclude_author;

  FILTER:
    {
        if ($config{-include_author}) {
            if (!$include_author) {
                $include_author = [split /;/, $config{-include_author}];
            }
            if ($url =~ m!authors/id/./../(.+)/! && !($1 ~~ @$include_author)) {
                say "mirror($url, $file): author not included, skipping"
                    if $config{-verbose};
                return HTTP::Response->new(304);
            }
        }

        if ($config{-exclude_author}) {
            if (!$exclude_author) {
                $exclude_author = [split /;/, $config{-exclude_author}];
            }
            if ($url =~ m!authors/id/./../(.+)/! && $1 ~~ @$exclude_author) {
                say "mirror($url, $file): author excluded, skipping"
                    if $config{-verbose};
                return HTTP::Response->new(304);
            }
        }

        if (my $limit = $config{-size}) {
            my $size = (-s $file);
            if ($size && $size > $limit) {
                say "mirror($url, $file): local size ($size) > limit ($limit), skipping"
                    if $config{-verbose};
                return HTTP::Response->new(304);
            }

            # perform HEAD request to find out the size
            my $resp = $self->head($url);

            {
                last unless $resp->is_success;
                last unless defined(my $len = $resp->header("Content-Length"));
                if ($len > $limit) {
                    say "mirror($url, $file): remote size ($len) > limit ($limit), skipping"
                        if $config{-verbose};
                    return HTTP::Response->new(304);
                }
            }
        }
    }
    return $orig->(@_);
};

sub patch_data {
    return {
        v => 3,
        config => {
            -size => {
                schema => 'int*',
            },
            -exclude_author => {
                schema => 'str*',
            },
            -include_author => {
                schema => 'str*',
            },
            -verbose => {
                schema  => 'bool*',
                default => 0,
            },
        },
        patches => [
            {
                action => 'wrap',
                mod_version => qr/^6\./,
                sub_name => 'mirror',
                code => $p_mirror,
            },
        ],
    };
}

1;
# ABSTRACT: Filter mirror()

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::UserAgent::Patch::FilterLcpan - Filter mirror()

=head1 VERSION

This document describes version 1.034 of LWP::UserAgent::Patch::FilterLcpan (from Perl distribution App-lcpan), released on 2019-06-19.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
