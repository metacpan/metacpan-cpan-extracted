package Chart::OFC::Types;
$Chart::OFC::Types::VERSION = '0.12';
use strict;
use warnings;

use Graphics::ColorNames;
use List::MoreUtils qw( any );
use Moose::Util::TypeConstraints;

subtype 'Chart::OFC::Type::Color'
    => as 'Str',
    => where { ( uc $_ ) =~ /^\#[0-9A-F]{6}$/ }
    => message { "$_ is not a valid six-digit hex color" };

coerce 'Chart::OFC::Type::Color'
    => from 'Str'
    => via \&_name_to_hex_color;

{
    my $names = Graphics::ColorNames->new();
    sub _name_to_hex_color
    {
        no warnings 'uninitialized'; ## no critic ProhibitNoWarnings
        return uc $names->hex( $_, '#' );
    }
}

subtype 'Chart::OFC::Type::NonEmptyArrayRef'
    => as 'ArrayRef'
    => where { return scalar @{ $_ } > 0 };

{
    my $constraint = find_type_constraint('Num');

    subtype 'Chart::OFC::Type::NonEmptyArrayRefOfNums'
        => as 'Chart::OFC::Type::NonEmptyArrayRef',
        => where { return 0 if any { ! $constraint->check($_) } @{ $_ };
                   return 1; }
        => message { 'array reference must contain only numbers and cannot be empty' };

    subtype 'Chart::OFC::Type::NonEmptyArrayRefOfNumsOrUndefs'
        => as 'Chart::OFC::Type::NonEmptyArrayRef',
        => where { return 0 if any { defined && ! $constraint->check($_) } @{ $_ };
                   return 1; }
        => message { 'array reference cannot be empty and must contain numbers or undef' };
}

{
    my $constraint = find_type_constraint('Chart::OFC::Type::NonEmptyArrayRefOfNumsOrUndefs');

    subtype 'Chart::OFC::Type::NonEmptyArrayRefOfArrayRefsOfNumsOrUndefs'
        => as 'Chart::OFC::Type::NonEmptyArrayRef',
        => where { return 0 if any { defined && ! $constraint->check($_) } @{ $_ };
                   return 1; }
        => message { 'array reference cannot be empty and must contain more array references of numbers or undef' };
}

{
    my $constraint = find_type_constraint('Chart::OFC::Type::Color');

    subtype 'Chart::OFC::Type::NonEmptyArrayRefOfColors'
        => as 'Chart::OFC::Type::NonEmptyArrayRef',
        => where { return 0 unless @{ $_ } > 0;
                   return 0 if any { ! $constraint->check($_) } @{ $_ };
                   return 1; }
        => message { 'array reference cannot be empty and must be a list of colors' };

    coerce 'Chart::OFC::Type::NonEmptyArrayRefOfColors'
        => from 'ArrayRef'
        => via { [ map { $constraint->coerce($_) } @{ $_ } ] };
}

{
    my $constraint = find_type_constraint('Chart::OFC::Dataset') || class_type('Chart::OFC::Dataset');

    subtype 'Chart::OFC::Type::NonEmptyArrayRefOfTypedDatasets'
        => as 'Chart::OFC::Type::NonEmptyArrayRef',
        => where { return 0 unless @{ $_ } > 0;
                   return 0 if any { ! ( $constraint->check($_) && $_->can('type') ) } @{ $_ };
                   return 1; }
        => message { 'array reference cannot be must be a list of typed datasets' };
}

unless ( find_type_constraint('Chart::OFC::AxisLabel' ) )
{
    subtype 'Chart::OFC::AxisLabel'
        => as 'Object'
        => where { $_->isa('Chart::OFC::AxisLabel') };
}

coerce 'Chart::OFC::AxisLabel'
    => from 'HashRef'
    => via { Chart::OFC::AxisLabel->new( %{ $_ } ) }
    => from 'Str'
    => via { Chart::OFC::AxisLabel->new( label => $_ ) };

subtype 'Chart::OFC::Type::Angle'
    => as 'Int'
    => where  { $_ >= 0 && $_ <= 359 }
    => message { "$_ is not a number from 0-359" };

subtype 'Chart::OFC::Type::Opacity'
    => as 'Int'
    => where { $_ >= 0 && $_ <= 100 }
    => message { "$_ is not a number from 0-100" };

subtype 'Chart::OFC::Type::PosInt'
    => as 'Int'
    => where  { $_ > 0 }
    => message { 'must be a positive integer' };

subtype 'Chart::OFC::Type::PosOrZeroInt'
    => as 'Int'
    => where  { $_ >= 0 }
    => message { 'must be an integer greater than or equal to zero' };

subtype 'Chart::OFC::Type::Size'
    => as 'Chart::OFC::Type::PosInt';

enum 'Chart::OFC::Type::Orientation' => [qw( horizontal vertical diagonal )];


{
    # Monkey-patch to shut up an annoying warning!

    package                   ## no critic ProhibitMultiplePackages
        Graphics::ColorNames;

    no warnings 'redefine'; ## no critic ProhibitNoWarnings
    sub hex { ## no critic ProhibitBuiltinHomonyms
        my $self = shift;
        my $name = shift;
        my $rgb  = $self->FETCH($name);
        return unless defined $rgb; # this is the monkey line
        my $pre  = shift;
        unless (defined $pre) { $pre = ""; }
        return ($pre.$rgb);
    }
}

no Moose::Util::TypeConstraints;

1;


# ABSTRACT: type library for Chart::OFC

__END__

=pod

=head1 NAME

Chart::OFC::Types - type library for Chart::OFC

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    package Chart::OFC::Thingy;

    use Chart::OFC::Types;

    use Moose;

    has opacity => (
        is  => 'ro',
        isa => 'Chart::OFC::Type::Opacity',
    );

=head1 DESCRIPTION

This class provides a library of types for use by other Chart::OFC
classes.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
