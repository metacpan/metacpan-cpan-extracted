package App::cryp::Exchange::indodax;

our $DATE = '2018-05-10'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;
with 'App::cryp::Role::Exchange';

sub new {
    require Finance::Indodax;

    my ($class, %args) = @_;

    unless ($args{public_only}) {
        die "Please supply api_key and api_secret"
            unless $args{api_key} && $args{api_secret};
    }

    $args{_client} = Finance::Indodax->new(
        key => $args{api_key},
        secret => $args{api_secret},
    );

    bless \%args, $class;
}

sub data_native_pair_separator { '_' }

sub data_canonical_currencies {
    state $data = do {
        require App::indodax;
        my %hash = %App::indodax::Canonical_Currencies;
        for my $k (keys %hash) {
            $hash{uc $k} = uc(delete $hash{$k});
        }
        \%hash;
    };
    $data;
}

sub data_reverse_canonical_currencies {
    state $data = do {
        require App::indodax;
        my %hash = %App::indodax::Rev_Canonical_Currencies;
        for my $k (keys %hash) {
            $hash{uc $k} = uc(delete $hash{$k});
        }
        \%hash;
    };
    $data;
}

sub list_pairs {
    my ($self, %args) = @_;

    require App::indodax;
    # XXX in the future, we will put the master data here instead of in
    # App::indodax

    my $res = App::indodax::pairs();
    return $res unless $res->[0] == 200;

    my @res;
    for (@{ $res->[2] }) {
        if ($args{native}) {
            $_ = lc $self->to_native_pair($_);
        } else {
            $_ = $self->to_canonical_pair($_);
        }
        push @res, {
            pair => $_,
        };
    }

    unless ($args{detail}) {
        @res = map { $_->{pair} } @res;
    }

    [200, "OK", \@res];
}

sub get_order_book {
    my ($self, %args) = @_;

    my $pair = lc $self->to_native_pair($args{pair});

    my $res;
    eval { $res = $self->{_client}->get_depth(pair => $pair) };
    return [500, "Died: $@"] if $@;

    [200, "OK", $res];
}

1;
# ABSTRACT: Interact with Indodax

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::Exchange::indodax - Interact with Indodax

=head1 VERSION

This document describes version 0.003 of App::cryp::Exchange::indodax (from Perl distribution App-cryp-exchange), released on 2018-05-10.

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
