package Business::PL::NIP;

use strict;
use warnings;

use Exporter::Easy ( OK => [ qw(is_valid_nip) ] );
use Carp qw(croak);
use List::Util qw(sum);

our $VERSION = '0.03';

my @weights = qw(6 5 7 2 3 4 5 6 7);

sub is_valid_nip {

    my $nip = shift;

    croak "No NIP number provided" unless $nip;
    $nip =~ s/^PL//;
    return unless $nip =~ /^[0-9]{10}$/;

    my @nip       = split "", $nip;
    my $check_sum = pop @nip;

    my $verify_check_sum += sum( map { $nip[$_] * $weights[$_] } 0..$#nip );

    $verify_check_sum %= 11;

    return $verify_check_sum == $check_sum;
}



1;

__END__

=head1 NAME

Business::PL::NIP

=head1 SYNOPSIS

    # functional interface
    use Business::PL::NIP qw(is_valid_nip);

    my $is_valid = is_valid_nip(1234567890);

=head1 DESCRIPTION

NIP is a Polish tax identification number, assigned out to business entities by Polish Ministry of Finance.

This module provides a method for checking whether the given number is a valid NIP.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2014 by Tomasz Czepiel <tjmc@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.0 or,
at your option, any later version of Perl 5 you may have available.

