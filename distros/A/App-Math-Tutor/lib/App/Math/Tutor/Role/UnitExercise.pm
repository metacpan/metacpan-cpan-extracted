package App::Math::Tutor::Role::UnitExercise;

use warnings;
use strict;

=head1 NAME

App::Math::Tutor::Role::FracExercise - role for exercises in calculation with units

=cut

use Moo::Role;
use MooX::Options;

=head1 ATTRIBUTES

=head2 relevant_units

Specifies relevant units. Option argument can be either a list of units to take care, or
starting with an exclamation mark, a list of units to skip.

Known units contain time, length, weight, euro, pound, dollar.

=cut

option "relevant_units" => (
    is       => "lazy",
    doc      => "Specifies the units relevant for the exercise",
    long_doc => "Specifies the units relevant for the exercise using one or more of: "
      . "time, length, weight, euro, pound, dollar.",
    coerce     => \&_coerce_relevant_units,
    format     => "s@",
    autosplit  => ",",
    repeatable => 1,
    short      => "r",
);

my $single_inst;
my $single_redo;

around new => sub {
    my ( $orig, $class, %params ) = @_;
    my $self = $class->$orig(%params);
    $single_inst = $self;
    $single_redo and $self->{relevant_units} = _coerce_relevant_units($single_redo);
    $self;
};

sub _build_relevant_units
{
    [ keys %{ $_[0]->unit_definitions } ];
}

sub _coerce_relevant_units
{
    my ($val) = @_;
    $single_inst or return $single_redo = $val;
    defined $val or die "Missing argument for relevant_units";
    ref $val eq "ARRAY" or die "Invalid type for relevant_units";
    my $neg = $val->[0] eq "!" and shift @$val;
    @$val or die "Missing elements for relevant_units";

    $single_inst or return $val;

    my @brkn;
    foreach my $ru ( @{$val} )
    {
        $neg = $ru eq "!" and next unless defined $neg;
        exists $single_inst->unit_definitions->{$ru}
          or push @brkn, $ru;
    }
    @brkn and die "Non-existing unit type(s): " . join( ", ", @brkn );

    $neg or return $val;

    my @neg_list = grep {
        my $item = $_;
        grep { $_ ne "!" and $_ ne $item } @{$val}
    } keys %{ $single_inst->unit_definitions };
    \@neg_list;
}

=head2 unit_length

Allowes one to limit the "length" of a unit. While some unit categories have
many entries (e.g. I<time> - which can result in
C<${a} w ${b} d ${c} h ${d} min ${e} s ${f} ms>) - limiting the length would
result in not more than C<${unit_length}> elements per number.

=cut

option "unit_length" => (
    is        => "ro",
    doc       => "Allowes limitation of unit length",
    format    => "i",
    short     => "l",
    predicate => 1,
);

=head2 deviation

When more than one operand is involved, control I<deviation> using this
option. Best results with I<unit_length>.

=cut

option "deviation" => (
    is        => "ro",
    doc       => "Allowes limit deviation of unit elements by <einheit>",
    format    => "i",
    short     => "d",
    predicate => 1,
);

with "App::Math::Tutor::Role::Exercise", "App::Math::Tutor::Role::Unit";

our $VERSION = '0.005';

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
