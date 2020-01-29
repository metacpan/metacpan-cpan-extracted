package Data::Validate::Chemistry;

use strict;
use warnings;

# ABSTRACT: Validate common chemical identifiers
our $VERSION = '0.1.0'; # VERSION

use Exporter 'import';
our @EXPORT_OK = qw(
    is_CAS_number
    is_European_Community_number
);

sub is_CAS_number
{
    my( $CAS_number ) = shift;

    return unless $CAS_number =~ /^[0-9]{2,7}-[0-9]{2}-[0-9]$/;

    my @digits = $CAS_number =~ /([0-9])/g;
    my $checksum = pop @digits;

    return $checksum == _ISBN_like_checksum( 10, reverse @digits );
}

sub is_European_Community_number
{
    my( $EC_number ) = shift;

    return unless $EC_number =~ /^([0-9]{3}-){2}[0-9]$/;

    my @digits = $EC_number =~ /([0-9])/g;
    my $checksum = pop @digits;

    if( $digits[0] == 4 && $checksum == 1 ) {
        # There are 181 ELINCS numbers starting with 4 having checksum
        # of 10 and with a checksum digit of 1, as given in
        # https://en.wikipedia.org/w/index.php?title=European_Community_number&oldid=910557632
        return _ISBN_like_checksum( 11, @digits ) == $checksum ||
               _ISBN_like_checksum( 11, @digits ) == 10;
    } else {
        return _ISBN_like_checksum( 11, @digits ) == $checksum;
    }
}

sub _ISBN_like_checksum
{
    my $modulo = shift;

    my $checksum = 0;
    for (0..$#_) {
        $checksum = ($checksum + $_[$_] * ($_ + 1)) % $modulo;
    }
    return $checksum;
}

1;

__END__

=pod

=head1 NAME

Data::Validate::Chemistry - Validate common chemical identifiers

=head1 SYNOPSIS

    use Data::Validate::Chemistry qw( is_CAS_number is_European_Community_number );

    print "OK\n" if is_CAS_number( '7732-18-5' );
    print "OK\n" if is_European_Community_number( '200-003-9' );

=head1 DESCRIPTION

Data::Validate::Chemistry validates some of the common chemical
identifiers, namely, CAS and European Community numbers.

=head1 AUTHORS

Andrius Merkys, C<< merkys AT cpan DOT org >>

=head1 COPYRIGHT & LICENSE

Copyright 2020 Andrius Merkys

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
