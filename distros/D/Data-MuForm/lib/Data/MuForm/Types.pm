package Data::MuForm::Types;
# ABSTRACT: Type::Tiny types

use strict;
use warnings;

use Scalar::Util "looks_like_number";
use Type::Utils;

use Types::Standard -types;
use Type::Library -base;

our $class_messages = {
    PositiveNum => "Must be a positive number",
    PositiveInt => "Must be a positive integer",
    NegativeNum => "Must be a negative number",
    NegativeInt => "Must be a negative integer",
    SingleDigit => "Must be a single digit",
    SimpleStr => 'Must be a single line of no more than 255 chars',
    NonEmptySimpleStr => "Must be a non-empty single line of no more than 255 chars",
    Password => "Must be between 4 and 255 chars",
    StrongPassword =>"Must be between 8 and 255 chars, and contain a non-alpha char",
    NonEmptyStr => "Must not be empty",
    State => "Not a valid state",
    Email => "Email is not valid",
    Zip => "Zip is not valid",
    IPAddress => "Not a valid IP address",
    NoSpaces =>'Must not contain spaces',
    WordChars => 'Must be made up of letters, digits, and underscores',
    NotAllDigits => 'Must not be all digits',
    Printable => 'Field contains non-printable characters',
    PrintableAndNewline => 'Field contains non-printable characters',
    SingleWord => 'Field must contain a single word',
};


declare 'PositiveNum', as Num, where { $_ >= 0 }, message { "Must be a positive number" };

declare 'PositiveInt', as Int, where { $_ >= 0 }, message { "Must be a positive integer" };

declare 'NegativeNum', as Num, where { $_ <= 0 }, message { "Must be a negative number" };

declare 'NegativeInt', as Int, where { $_ <= 0 }, message { "Must be a negative integer" };

declare 'SingleDigit', as 'PositiveInt', where { $_ <= 9 }, message { "Must be a single digit" };

declare 'SimpleStr',
    as Str,
    where { ( length($_) <= 255 ) && ( $_ !~ m/\n/ ) },
    message { $class_messages->{SimpleStr} };

declare 'NonEmptySimpleStr',
    as 'SimpleStr',
    where { length($_) > 0 },
    message { $class_messages->{NonEmptySimpleStr} };

declare 'Password',
    as 'NonEmptySimpleStr',
    where { length($_) >= 4 && length($_) <= 255 },
    message { $class_messages->{Password} };

declare 'StrongPassword',
    as 'Password',
    where { ( length($_) >= 8 ) && length($_) <= 255 && (m/[^a-zA-Z]/) },
    message { $class_messages->{StrongPassword} };

declare 'NonEmptyStr', as Str, where { length($_) > 0 }, message { $class_messages->{NonEmptyStr} };

declare 'State', as Str, where {
    my $value = $_;
    my $state = <<EOF;
AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD
MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA PR RI
SC SD TN TX UT VT VA WA WV WI WY DC AP FP FPO APO GU VI
EOF
    return ( $state =~ /\b($value)\b/i );
}, message { $class_messages->{State} };

declare 'Email', as Str, where {
    my $value = shift;
    require Email::Valid;
    my $valid;
    return ( $valid = Email::Valid->address($value) ) &&
        ( $valid eq $value );
}, message { $class_messages->{Email} };

declare 'Zip',
    as Str,
    where { /^(\s*\d{5}(?:[-]\d{4})?\s*)$/ },
    message { $class_messages->{Zip} };

declare 'IPAddress', as Str, where {
    /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
}, message { $class_messages->{IPAddress} };

declare 'NoSpaces',
    as Str,
    where { ! /\s/ },
    message { $class_messages->{NoSpaces} };

declare 'WordChars',
    as Str,
    where { ! /\W/ },
    message { $class_messages->{WordChars} };

declare 'NotAllDigits',
    as Str,
    where { ! /^\d+$/ },
    message { $class_messages->{NotAllDigits} };

declare 'Printable',
    as Str,
    where { /^\p{IsPrint}*\z/ },
    message { $class_messages->{Printable} };

declare 'PrintableAndNewline',
    as Str,
    where { /^[\p{IsPrint}\n]*\z/ },
    message { $class_messages->{PrintableAndNewline} };

declare 'SingleWord',
    as Str,
    where { /^\w*\z/ },
    message { $class_messages->{SingleWord} };

declare 'Collapse',
   as Str,
   where{ ! /\s{2,}/ };

coerce 'Collapse',
   from Str,
   via { s/\s+/ /g; return $_; };

declare 'Lower',
   as Str,
   where { ! /[[:upper:]]/  };

coerce 'Lower',
   from Str,
   via { lc };

declare 'Upper',
   as Str,
   where { ! /[[:lower:]]/ };

coerce 'Upper',
   from Str,
   via { uc };

declare 'Trim',
   as Str,
   where  { ! /^\s+/ &&
            ! /\s+$/ };

coerce 'Trim',
   from Str,
   via { s/^\s+// &&
         s/\s+$//;
         return $_;  };
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Types - Type::Tiny types

=head1 VERSION

version 0.05

=head1 SYNOPSIS

These types are provided by Type::Tiny. These types must not be quoted
when they are used:

  has 'posint' => ( is => 'rw', isa => PositiveInt);
  has_field 'email' => ( apply => [ Email ] );

To import these types into your forms, you must either specify (':all')
or list the types you want to use:

   use Data::MuForm::Types (':all');

or:

   use Data::MuForm::Types ('Email', 'PositiveInt');

=head1 DESCRIPTION

=head1 Type Constraints

These types check the value and issue an error message.

=over

=item Email

Uses Email::Valid

=item State

Checks that the state is in a list of two uppercase letters.

=item Zip

=item IPAddress

Must be a valid IPv4 address.

=item NoSpaces

No spaces in string allowed.

=item WordChars

Must be made up of letters, digits, and underscores.

=item NotAllDigits

Might be useful for passwords.

=item Printable

Must not contain non-printable characters.

=item SingleWord

Contains a single word.

=back

=head2 Type Coercions

These types will transform the value without an error message;

=over

=item Collapse

Replaces multiple spaces with a single space

=item Upper

Makes the string all upper case

=item Lower

Makes the string all lower case

=item Trim

Trims the string of starting and ending spaces

=back

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
