package Data::DNS;
# ABSTRACT: An interface to the DNS root zone database.
use Carp;
use Data::DNS::TLD;
use Data::Mirror qw(mirror_str);
use Data::Tranco;
use ICANN::gTLD;
use List::Util qw(any);
use Net::RDAP;
use constant TLD_LIST_URL => q{https://data.iana.org/TLD/tlds-alpha-by-domain.txt};
use vars qw($VERSION);
use common::sense;

$VERSION = q{0.01};

sub tlds {
    state @tlds = map { lc }
                    grep { /^([a-z]+|xn--[a-z0-9\-]+)$/i }
                    split(/\n/, mirror_str(TLD_LIST_URL));

    return @tlds;
}

sub exists  { any { lc($_[1]) eq $_ } $_[0]->tlds }
sub get     { Data::DNS::TLD->new(pop) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::DNS - An interface to the DNS root zone database.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Data::DNS;

    if (Data::DNS->exists("org")) {
        $org = Data::DNS->get("org");

        say ".org is operated by ".$org->rdap_record->registrant->jcard->first('org')->value;
    }

=head1 DESCRIPTION

Information about the DNS root zone is distributed across multiple data sources.
This module organises this information and provides a single entry point to it.

=head1 PACKAGE METHODS

=head2 exists($tld)

This method returns true if the TLD specified by C<$tld> exists in the root
zone.

=head2 get($tld)

This method returns a L<Data::DNS::TLD> object corresponding to the TLD
specified by C<$tld>. An exception will be thrown if the TLD does not exist.

=head1 AUTHOR

Gavin Brown <gavin.brown@icann.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation for Assigned Names and Numbers (ICANN).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
