package App::MediaInfo;

our $DATE = '2016-04-06'; # DATE
our $VERSION = '0.11'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

our %SPEC;

$SPEC{media_info} = {
    v => 1.1,
    summary => 'Get information about media files/URLs',
    args => {
        media => {
            summary => 'Media files/URLs',
            schema => ['array*' => of => 'str*'],
            req => 1,
            pos => 0,
            greedy => 1,
            #'x.schema.entity' => 'filename_or_url',
            'x.schema.entity' => 'filename', # temp
        },
        backend => {
            summary => 'Choose a specific backend',
            schema  => ['str*', match => '\A\w+\z'],
            completion => sub {
                require Complete::Module;
                my %args = @_;
                Complete::Module::complete_module(
                    word => $args{word},
                    ns_prefix => "Media::Info",
                );
            },
        },
    },
};
sub media_info {
    require Media::Info;

    my %args = @_;

    my $media = $args{media};

    if (@$media == 1) {
        return Media::Info::get_media_info(
            media => $media->[0],
            (backend => $args{backend}) x !!(defined $args{backend}),
        );
    } else {
        my @res;
        for (@$media) {
            my $res = Media::Info::get_media_info(
                media => $_,
                (backend => $args{backend}) x !!(defined $args{backend}),
            );
            unless ($res->[0] == 200) {
                warn "Can't get media info for '$_': $res->[1] ($res->[0])\n";
                next;
            }
            push @res, { media => $_, %{$res->[2]} };
        }
        [200, "OK", \@res];
    }
}

1;
# ABSTRACT: Get information about media files/URLs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MediaInfo - Get information about media files/URLs

=head1 VERSION

This document describes version 0.11 of App::MediaInfo (from Perl distribution App-MediaInfo), released on 2016-04-06.

=head1 FUNCTIONS


=head2 media_info(%args) -> [status, msg, result, meta]

Get information about media files/URLs.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backend> => I<str>

Choose a specific backend.

=item * B<media>* => I<array[str]>

Media files/URLs.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-MediaInfo>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-MediaInfo>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-MediaInfo>

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
