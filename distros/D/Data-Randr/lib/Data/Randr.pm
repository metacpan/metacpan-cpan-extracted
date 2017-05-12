package Data::Randr;
use strict;
use warnings;
use Carp qw/croak/;
use Exporter 'import';
our @EXPORT_OK = qw/randr/;

our $VERSION = '0.04';

sub new {
    my ($class, %args) = @_;

    my $rate  = delete $args{rate};
    my $digit = delete $args{digit};

    bless {
        rate  => $rate,
        digit => $digit,
    }, $class;
}

sub rate  { $_[0]->{rate}  }
sub digit { $_[0]->{digit} }

sub randr {
    my ($self, $base, $rate, $digit);

    if (ref $_[0] eq __PACKAGE__) {
        ($self, $base, $rate, $digit) = @_;
        $rate  = $rate ? $rate : $self->rate;
        $digit = $digit ? $digit : $self->digit;
    }
    else {
        ($base, $rate, $digit) = @_;
    }

    $rate ||= 10;

    my $splash = int( $base * ($rate/100) );
    my $result = $base - $splash + rand($splash*2+1*($digit ? 0 : 1));

    if ($digit) {
        return sprintf("%0.${digit}f", $result);
    }

    return int($result);
}

1;

__END__

=encoding UTF-8

=head1 NAME

Data::Randr - numeral randomizer for a cache expires time


=head1 SYNOPSIS

    use Data::Randr qw/randr/;

    randr(10);        # 9 - 11
    randr(10, 20);    # 8 - 12
    randr(10, 20, 4); # 8.0000 - 11.9999 down to 4 decimal places, ex. 8.4321

or OOP style

    use Data::Randr;

    my $rdr = Data::Randr->new(rate => 20, digit => 2);
    $rdr->randr(10); # 8.00 - 11.99


=head1 DESCRIPTION

Data::Randr gives random number for a cache expires time to avoid the thundering herd problem.

=head1 METHOD

=head2 new(%args)

constructor

=head3 construct options

=head4 rate : int // 10

randomize rate(1 - 100)

=head4 digit : int // 0

decimal number

=head2 randr($number[, $rate, $digit])

response randomized number

Like below, C<$res> is 8.0000 - 11.9999.

    my $res = randr(
        10, # base number
        20, # randomize rate for base number
        4,  # decimal number
    );


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/Data-Randr"><img src="https://secure.travis-ci.org/bayashi/Data-Randr.png?_t=1452230512"/></a> <a href="https://coveralls.io/r/bayashi/Data-Randr"><img src="https://coveralls.io/repos/bayashi/Data-Randr/badge.png?_t=1452230512&branch=master"/></a>

=end html

Data::Randr is hosted on github: L<http://github.com/bayashi/Data-Randr>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
