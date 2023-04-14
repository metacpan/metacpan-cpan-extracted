package Business::IBAN::Validator;
use warnings;
use strict;

our $VERSION = '0.07';

use Hash::Util qw/unlock_hash lock_hash/;
use Business::IBAN::Database;

sub new {
    my $class = shift;

    my $db = iban_db();
    unlock_hash(%$db);
    my $self =  bless $db, $class;
    lock_hash(%$self);
    return $self;
}

sub validate {
    my $self = shift;
    my ($iban) = @_;

    (my $to_check = $iban) =~ s/\s+//g;
    my $iso3166a2 = uc(substr($to_check, 0, 2));

    if (not exists($self->{$iso3166a2})) {
        die "'$iso3166a2' is not an IBAN country code.\n";
    }

    my $iban_info = $self->{$iso3166a2};
    if (length($to_check) != $iban_info->{iban_length}) {
        die(
            sprintf(
                "'%s' has incorrect length %d (expected %d for %s).\n",
                $iban,
                length($to_check),
                $iban_info->{iban_length},
                $iban_info->{country}
            )
        );
    }

    if ($to_check !~ $iban_info->{iban_structure}) {
        die(
            sprintf(
                "'%s' does not match the pattern '%s'for %s.\n",
                $iban,
                $iban_info->{pattern},
                $iban_info->{country}
            )
        );
    }

    if ( mod97(numify_iban($to_check)) != 1) {
        die "'$iban' does not comply with the 97-check.\n";
    }

    return 1;
}

sub is_sepa {
    my $self = shift;
    my ($iban) = @_;
    (my $to_check = $iban) =~ s/\s+//g;
    my $iso3166a2 = uc(substr($to_check, 0, 2));

    if (not exists($self->{$iso3166a2})) {
        die "'$iso3166a2' is not an IBAN country code.\n";
    }

    return $self->{$iso3166a2}{is_sepa};
}

sub DESTROY { }

sub AUTOLOAD {
    my $self = shift;
    (my $cc =  our $AUTOLOAD) =~ s/.*:://;
    if (!exists $self->{uc $cc}) {
        require Carp;
        Carp::croak("'$cc' is not a valid IBAN country code.");
    }
    return $self->{uc $cc};
}

1;

=head1 NAME

Business::IBAN::Validator - A validator for the structure of IBANs.

=head1 SYNOPSIS

    use Business::IBAN::Validator;
    my $v = Business::IBAN::Validator->new;
    while (1) {
        print 'Enter IBAN: ';
        chomp(my $input = <>);
        last if !$input;
        eval { $v->validate($input) };
        if ($@) {
            print "Not ok: $@";
        }
        else {
            print "OK\n";
        }
    }

=head1 DESCRIPTION

This module does a series of checks on an IBAN:

=over

=item Country code

=item Length

=item Pattern

=item 97-Check

=back

=head2 $v = Business::IBAN::Validator->new()

Return an IBAN validator object.

=head2 $v->validate($iban)

Perform a series of checks, and die() as soon as one fails.

Return 1 on success.

=head2 $v->is_sepa($iban)

Return the SEPA status of the country (as denoted by the first two letters).

=head1 COPYRIGHT

E<copy> MMXIII-MMXV - Abe Timmerman <abeltje@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
