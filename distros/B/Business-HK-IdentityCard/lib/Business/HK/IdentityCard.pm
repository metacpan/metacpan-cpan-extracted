use strict;
use warnings;
package Business::HK::IdentityCard;
our $VERSION = '1.000'; # VERSION

# ABSTRACT: validate identity card numbers used in Hong Kong



sub new 
{
    my ($proto, $id) = @_; 
    my $class = ref($proto) || $proto;
    my $self = bless { }, $class;

    $self->_extract_and_validate($id);

    return $self;
}



sub is_valid
{
    my $self = shift;

    return $self->{valid};
}


sub as_string
{
    my $self = shift;
    
    return unless $self->is_valid();

    return "$self->{prefix}$self->{digits}($self->{checksum})";
}


sub as_string_no_checksum
{
    my $self = shift;
    
    return unless $self->is_valid();

    return "$self->{prefix}$self->{digits}";
}


# Private methods

sub _extract_and_validate
{
    my $self = shift;
    my ($raw_id) = @_;

    return unless defined $raw_id;

    $self->{raw_id} = $raw_id;

    $self->{valid} = $self->_extract_hkid() && $self->_validate_checksum();
}

sub _extract_hkid
{
    my $self = shift;

    if ($self->{raw_id} =~ qr
        {
            ([a-z]{1,2})        # One or two prefix characters
            (\d{6})             # Exactly six digits
            \(*                 # Optional bracket
            ([0-9a])            # Checksum, 0-9 or A for 10
            \)*                 # Optional bracket
        }ix)
    {
        ($self->{prefix}, $self->{digits}, $self->{checksum}) = 
            (uc($1), $2, uc($3));
        
        return 1;
    }

    return 0;
}

sub _validate_checksum
{
    my $self = shift;

    return $self->{checksum} eq $self->_calculate_checksum();
}

sub _calculate_checksum
{
    # Checksum is such that the weighted sum of prefix, digits and checksum 
    # mod 11 is 0. Prefix is converted to a number.
    # Checksum is encoded as A if value is 10.
    # eg to find the checksum c in A123456(c)
    # (1*8 + 1*7 + 2*6 + 3*5 + 4*4 + 5*3 + 6*2 + c*1) % 11 = 0
    # so c = 3

    my $self = shift;

    # Build a list of components from the prefix (converted to
    # numbers) and the digits
    my @components = $self->_prefix_as_numbers();
    push @components, split //, $self->{digits};

    # Sum of weights * components
    my $total = 0;
    foreach my $weight (reverse(2 .. 1 + scalar @components))
    {
        $total += $weight * shift @components;
    }

    # Now solve ($total + $check_digit) % 11 = 0
    my $check_digit = (11 - ($total % 11)) % 11;
    $check_digit = 'A' if $check_digit == 10;

    return $check_digit;
}

sub _prefix_as_numbers
{
    # Convert the prefix characters to a list of numbers
    # For a two char prefix, A=7, B=8 etc for the first char
    # For the remaining char or a one char prefix, A=1, B=2 etc

    my $self = shift;

    my @prefix_chars = split //, $self->{prefix};
    my @prefix_numbers;

    if (scalar @prefix_chars == 2)
    {
        push @prefix_numbers, 7 + ord(shift @prefix_chars) - ord('A');
    }

    push @prefix_numbers, 1 + ord(shift @prefix_chars) - ord('A');

    return @prefix_numbers;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::HK::IdentityCard - validate identity card numbers used in Hong Kong

=head1 VERSION

version 1.000

=head1 SYNOPSIS

    use Business::HK::IdentityCard;

    my $hkid = Business::HK::IdentityCard->new('A123456(3)');
    if ($hkid->is_valid())
    {
        print $hkid->as_string() . " is valid\n";
    }

=head1 DESCRIPTION

This module validates identity card numbers used in Hong Kong. See
L<http://en.wikipedia.org/wiki/Hong_Kong_Identity_Card> for further
details on the format.

=head1 METHODS

=head2 new

Accepts a scalar representing the ID. IDs look like C<A123456(3)>, ie
an alphabetic prefix, siz digits and a check digit. The prefix can be
one or two characters and the brackets are optional for the check
digit.

=head2 is_valid

Returns true if the ID provided is a correct HK ID. This will confirm
that the format is correct and the checksum is valid.

=head2 as_string

Returns the ID formatted as a string using the conventional format, ie
upper-case letters and checksum in brackets.

=head2 as_string_no_checksum

Returns the ID formatted as a string without the checksum. As the
checksum is not officially part of the ID, some systems may store IDs
in this format.

=head1 SOURCE AVAILABILITY

Source code can be found on Github. Pull requests for bug fixes welcome.

    http://github.com/rupertl/business-hk-identitycard/tree/master

=head1 THANKS

Thanks to David Webb for advice on how the checksum for double prefix
IDs should be calculated.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
