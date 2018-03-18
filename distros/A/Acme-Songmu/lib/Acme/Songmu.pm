package Acme::Songmu;
use 5.010;
use strict;
use warnings;
use utf8;
use Encode;

use version 0.77; our $VERSION = version->declare("v0.1.0");

use Time::Piece ();
use Class::Accessor::Lite::Lazy 0.03 (
    ro      => [qw/birthday first_name last_name/],
    ro_lazy => {
        age => sub {
            int(
                (Time::Piece->localtime->strftime('%Y%m%d') -
                    shift->birthday->strftime('%Y%m%d')
                ) / 10000)
        },
    },
);

sub instance {
    state $_instance = bless {
        birthday   => Time::Piece->strptime('1980-06-05', '%Y-%m-%d'),
        first_name => 'Masayuki',
        last_name  => 'Matsuki',
    }, __PACKAGE__;
}

sub name {
    my $self = shift;
    sprintf '%s %s', $self->first_name, $self->last_name;
}

sub gmu {
    say encode_utf8 'ぐむー';
}

1;
__END__

=encoding utf-8

=for stopwords sandboxing

=head1 NAME

Acme::Songmu - Songmu's sample module

=head1 SYNOPSIS

    use Acme::Songmu;
    my $songmu = Acme::Songmu->instance;
    say $songmu->name; # => 'Masayuki Matsuki'
    say $songmu->age;  # => 37
    $songmu->gmu;      # => 'ぐむー'

=head1 DESCRIPTION

Acme::Songmu is Songmu's sample CPAN module for sandboxing.

=head1 CONSTRUCTOR

=head2 C<< my $sonmgu = Acme::Songmu->instance >>

The C<instance> class method returns an instance of Songmu as a singleton.

=head1 METHODS

=over

=item C<< $songmu->name >>

=item C<< $songmu->gmu >>

=back

=head1 METHODS

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

