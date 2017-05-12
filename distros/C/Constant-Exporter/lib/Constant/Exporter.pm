package Constant::Exporter;
use strict;
use warnings;
our $VERSION = '0.01';
require Exporter;

sub import {
    my ($class, %args) = @_;
    my (@export, @export_ok, %export_tags, %constants);

    for my $key (qw/ EXPORT_TAGS EXPORT_OK_TAGS /) {
        for my $tag (keys %{ $args{$key} || {} }) {
            $export_tags{$tag} ||= [];
            for my $name (keys %{ $args{$key}->{$tag} || {} }) {
                $constants{$name} = $args{$key}->{$tag}{$name};
                push @{$export_tags{$tag}}, $name;

                if ($key eq 'EXPORT_TAGS') {
                    push @export, $name;
                } elsif ($key eq 'EXPORT_OK_TAGS') {
                    push @export_ok, $name;
                }
            }
        }
    }

    for my $key (qw/ EXPORT EXPORT_OK /) {
        for my $name (keys %{ $args{$key} || {} }) {
            $constants{$name} = $args{$key}->{$name};
            if ($key eq 'EXPORT') {
                push @export, $name;
            } elsif ($key eq 'EXPORT_OK') {
                push @export_ok, $name;
            }
        }
    }

    my $pkg = caller;

    {
        no strict 'refs';
        for my $name (keys %constants) {
            my $value = $constants{$name};
            *{"${pkg}::${name}"} = sub () { $value };
        }

        push @{"${pkg}::ISA"}, 'Exporter';
        push @{"${pkg}::EXPORT"}, @export;
        push @{"${pkg}::EXPORT_OK"}, @export_ok;
        %{"${pkg}::EXPORT_TAGS"} = %export_tags;

        *{"${pkg}::import"} = sub {
            my $pkg = shift;
            $pkg->export_to_level(1, undef, @_)
        };
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Constant::Exporter - define and export constants easily

=head1 SYNOPSIS

    # define constants in your MyApp::Constants,

    package MyApp::Constants;
    use strict;
    use warnings;

    use Constant::Exporter (
        EXPORT => {
            FB_CLIENT_ID => 12345,
        },
        EXPORT_OK => {
            TITLE_MAX_LENGTH => 128,
        },
        EXPORT_TAGS => {
            user_status => {
                USER_STATUS_FB_ASSOCIATED     => 1,
                USER_STATUS_FB_NOT_ASSOCIATED => 0,
            },
        },
        EXPORT_OK_TAGS => {
            fb_api_error => {
                ERROR_OAUTH       => 190,
                ERROR_API_SESSION => 102,
                ERROR_API_USER_TOO_MANY_CALLS => 17,
            },
            fb_payment_error => {
                ERROR_PAYMENTS_ASSOCIATION_FAILURE   => 1176,
                ERROR_PAYMENTS_INSIDE_IOS_APP        => 1177,
                ERROR_PAYMENTS_NOT_ENABLED_ON_MOBILE => 1178,
            },
        },
    );

    1;

    # then use it like Exporter's `%EXPORT_TAGS` and `@EXPORT_OK`
    package main;
    use MyApp::Constants qw( TITLE_MAX_LENGTH :fb_api_error );

    sub foo {
        my ($title) = @_;
        if (length $title > TITLE_MAX_LENGTH) {
            ...
        }
    }

    sub bar {
        my ($response) = @_;

        if ($response->{error}{code} == ERROR_OAUTH) {
            ...
        }
    }


=head1 DESCRIPTION

Constant::Exporter is a module to define and export constants easily.

This module adopts L<Exporter>'s full functionality so you can import constants with default constants, tags or only selected constants.

=head1 KEYS AND MEANINGS

=head2 C<EXPORT>, C<EXPORT_TAGS>

Constant names in C<EXPORT> and C<EXPORT_TAGS> will be exported by default.

=head2 C<EXPORT_OK> C<EXPORT_OK_TAGS>

Constant names in C<EXPORT_OK> and C<EXPORT_OK_TAGS> will not be exported by default.
You can import these constants by feeding arguments to your constant class.

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013- punytan

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Exporter>

=cut
