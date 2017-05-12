#######################################################################
# This package validates ISINs and calculates the check digit
#######################################################################

package Business::ISIN;
use Carp;
require 5.005;

use strict;
use vars qw($VERSION %country_code);
$VERSION = '0.20';

use subs qw(check_digit);
use overload '""' => \&get; # "$isin" shows value


# Get list of valid two-letter country codes.
use Locale::Country;
$country_code{$_} = 1 for map {uc} Locale::Country::all_country_codes();

# Also include the non-country "country codes", used for bonds issued
# in multiple countries, etc..
$country_code{$_} = 1 for qw(XS XA XB XC XD);
#######################################################################
# Class Methods
#######################################################################

sub new {
    my $proto = shift;
    my $initializer = shift;

    my $class = ref($proto) || $proto;
    my $self = {value => undef, error => undef};
    bless ($self, $class);

    $self->set($initializer) if defined $initializer;
    return $self;
}

#######################################################################
# Object Methods
#######################################################################

sub set {
    my ($self, $isin) = @_;
    $self->{value} = $isin;
    return $self;
}

sub get {
    my $self = shift;
    return undef unless $self->is_valid;
    return $self->{value};
}

sub is_valid { # checks if self is a valid ISIN
    my $self = shift;
    
    # return not defined $self->error; # or for speed, do this instead
    return (
        $self->{value} =~ /^(([A-Za-z]{2})([A-Za-z0-9]{9}))([0-9]) $/x
        and exists $country_code{uc $2}
        and $4 == check_digit($1)
    );
}

sub error {
    # returns the error string resulting from failure of is_valid
    my $self = shift;
    local $_ = $self->{value};

    /^([A-Za-z]{2})? ([A-Za-z0-9]{9})? ([0-9])? (.*)?$/x;

    return "'$_' does not start with a 2-letter country code"
        unless length $1 > 0 and exists $country_code{uc $1};

    return "'$_' does not have characters 3-11 in [A-Za-z0-9]"
        unless length $2 > 0;

    return "'$_' character 12 should be a digit"
        unless length $3 > 0;

    return "'$_' has too many characters"
        unless length $4 == 0;

    return "'$_' has an inconsistent check digit"
    	unless $3 == check_digit($1.$2);

    return undef;
}


#######################################################################
# Subroutines
#######################################################################

sub check_digit {
    # takes a 9 digit string, returns the "double-add-double" check digit
    my $data = uc shift;

    $data =~ /^[A-Z]{2}[A-Z0-9]{9}$/ or croak "Invalid data: $data";

    $data =~ s/([A-Z])/ord($1) - 55/ge; # A->10, ..., Z->35.

    my @n = split //, $data; # take individual digits

    my $max = scalar @n - 1;
    for my $i (0 .. $max) { if ($i % 2 == 0) { $n[$max - $i] *= 2 } }
    # double every second digit, starting from the RIGHT hand side.

    for my $i (@n) { $i = $i % 10 + int $i / 10 } # add digits if >=10

    my $sum = 0; for my $i (@n) { $sum += $i } # get the sum of the digits

    return (10 - $sum) % 10; # tens complement, number between 0 and 9
}

1;



__END__

=head1 NAME

Business::ISIN - validate International Securities Identification Numbers

=head1 VERSION

0.20

=head1 SYNOPSIS

    use Business::ISIN;

    my $isin = new Business::ISIN 'US459056DG91';

    if ( $isin->is_valid ) {
	print "$isin is valid!\n";
	# or: print $isin->get() . " is valid!\n";
    } else {
	print "Invalid ISIN: " . $isin->error() . "\n";
	print "The check digit I was expecting is ";
	print Business::ISIN::check_digit('US459056DG9') . "\n";
    }

=head1 REQUIRES

Perl5, Locale::Country, Carp

=head1 DESCRIPTION

C<Business::ISIN> is a class which validates ISINs (International Securities
Identification Numbers), the codes which identify shares in much the same
way as ISBNs identify books.  An ISIN consists of two letters, identifying
the country of origin of the security according to ISO 3166, followed by
nine characters in [A-Z0-9], followed by a decimal check digit.

The C<new()> method constructs a new ISIN object.  If you give it a scalar
argument, it will use the argument to initialize the object's value.  Here,
no attempt will be made to check that the argument is valid.

The C<set()> method sets the ISIN's value to a scalar argument which you
give.  Here, no attempt will be made to check that the argument is valid.
The method returns the object, to allow you to do things like
C<$isin-E<gt>set("GB0004005475")-E<gt>is_valid>.

The C<get()> method returns a string, which will be the ISIN's value if it
is syntactically valid, and undef otherwise.  Interpolating the object
reference in double quotes has the same effect (see the synopsis).

The C<is_valid()> method returns true if the object contains a syntactically
valid ISIN.  (Note: this does B<not> guarantee that a security actually
exists which has that ISIN.) It will return false otherwise.

If an object does contain an invalid ISIN, then the C<error()> method will
return a string explaining what is wrong, like any of the following:

=over 4

=item * 'xxx' does not start with a 2-letter country code

=item * 'xxx' does not have characters 3-11 in [A-Za-z0-9]

=item * 'xxx' character 12 should be a digit

=item * 'xxx' has too many characters

=item * 'xxx' has an inconsistent check digit

=back

Otherwise, C<error()> will return C<undef>.

C<check_digit()> is an ordinary subroutine and B<not> a class method.  It
takes a string of the first eleven characters of an ISIN as an argument (e.g.
"US459056DG9"), and returns the corresponding check digit, calculated using
the so-called 'double-add-double' algorithm.

=head1 DIAGNOSTICS

C<check_digit()> will croak with the message 'Invalid data' if you pass it
an unsuitable argument.

=head1 ACKNOWLEDGEMENTS

Thanks to Peter Dintelmann (Peter.Dintelmann@Dresdner-Bank.com) and Tim
Ayers (tim.ayers@reuters.com) for suggestions and help debugging this
module.

=head1 AUTHOR

David Chan <david@sheetmusic.org.uk>

=head1 COPYRIGHT

Copyright (C) 2002, David Chan. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.
