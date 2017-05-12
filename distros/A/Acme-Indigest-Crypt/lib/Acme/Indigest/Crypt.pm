package Acme::Indigest::Crypt;
BEGIN {
  $Acme::Indigest::Crypt::VERSION = '0.0011';
}
# ABSTRACT: Acme::Indigest::Crypt

use strict;
use warnings;

use Crypt::Passwd::XS;

sub digest {
    my $self = shift;
    my $passphrase = shift;
    my $salt_string = shift;
    my $rounds = shift || 0;
    die "--<<>>---+__-_-_---+<>\n" unless $rounds =~ m/^\d*$/;
    $rounds < $_ and $rounds = $_ for 10_000_000;

    $salt_string = '' unless defined $salt_string;
    my @salt;
    push @salt, '$6$';
    push @salt, "rounds=$rounds\$" if $rounds;
    push @salt, "$salt_string\$";

    return Crypt::Passwd::XS::unix_sha512_crypt( $passphrase, join '', @salt );
}

sub parse_salt_string_rounds {
    my $self = shift;
    my $salt_string = shift;
    my $rounds = shift;

    defined or $_ = '' for $salt_string;
    if      ( $salt_string eq '' )  { undef $salt_string }
    elsif   ( $salt_string eq '$' ) { $salt_string = '' }
    defined and $_ = eval "$_" for $rounds;

    return ( $salt_string, $rounds );
}

sub digest_multiple {
    my $self = shift;
    my $input = shift;
    my $output = "";
    for ( split m/\n+/, $input ) {
        chomp;
        next if m/^\s*#/;
        next unless m/\S/;
        my ( $identifier, $salt_string, $rounds, $passphrase ) = split ':', $_, 4;
        ( $salt_string, $rounds ) = Acme::Indigest::Crypt->parse_salt_string_rounds( $salt_string, $rounds );
        my $ciphertext = Acme::Indigest::Crypt->digest( $passphrase, $salt_string, $rounds );
        $output .= "$identifier => $ciphertext\n";
    }
    return $output;
}


1;

__END__
=pod

=head1 NAME

Acme::Indigest::Crypt - Acme::Indigest::Crypt

=head1 VERSION

version 0.0011

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

