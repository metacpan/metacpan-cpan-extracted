package App::cryp::Exchange::gdax;

our $DATE = '2018-05-10'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;
with 'App::cryp::Role::Exchange';

sub new {
    require Finance::GDAX::Lite;

    my ($class, %args) = @_;

    unless ($args{public_only}) {
        die "Please supply api_key, api_secret, api_passphrase"
            unless $args{api_key} && $args{api_secret}
            && defined $args{api_passphrase};
    }

    $args{_client} = Finance::GDAX::Lite->new(
        key => $args{api_key},
        secret => $args{api_secret},
        passphrase => $args{api_passphrase},
    );

    bless \%args, $class;
}

sub data_native_pair_separator { '-' }

sub data_canonical_currencies {
    state $data = {};
    $data;
}

sub data_reverse_canonical_currencies {
    state $data = {};
    $data;
}

sub list_pairs {
    my ($self, %args) = @_;

    my $res = $self->{_client}->public_request(GET => "/products");
    return $res unless $res->[0] == 200;

    my @res;
    for (@{ $res->[2] }) {
        my $pair;
        if ($args{native}) {
            $pair = $self->to_native_pair($_->{id});
        } else {
            $pair = $self->to_canonical_pair($_->{id});
        }
        push @res, {
            pair            => $pair,
            quote_increment => $_->{quote_increment},
            status          => $_->{status}, # online,
        };
    }

    unless ($args{detail}) {
        @res = map { $_->{pair} } @res;
    }

    [200, "OK", \@res];
}

sub get_order_book {
    my ($self, %args) = @_;

    my $pair = $self->to_native_pair($args{pair});

    my $res = $self->{_client}->public_request(GET => "/products/$pair/book?level=2");
    return $res unless $res->[0] == 200;

    $res->[2]{buy}  = delete $res->[2]{bids};
    $res->[2]{sell} = delete $res->[2]{asks};

    [200, "OK", $res->[2]];
}

1;
# ABSTRACT: Interact with Bitcoin Indonesia

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::Exchange::gdax - Interact with Bitcoin Indonesia

=head1 VERSION

This document describes version 0.003 of App::cryp::Exchange::gdax (from Perl distribution App-cryp-exchange), released on 2018-05-10.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-cryp-exchange>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cryp-exchange>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-cryp-exchange>

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
