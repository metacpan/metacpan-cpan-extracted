package Chart::Clicker::Data::Range;
$Chart::Clicker::Data::Range::VERSION = '2.90';
use Moose;
use Moose::Util::TypeConstraints;

use constant EPSILON => 0.0001;

# ABSTRACT: A range of Data


subtype 'Lower'
    => as 'Num|Undef'
    => where { defined($_) };

coerce 'Lower'
    => from 'Undef'
    => via { - EPSILON };

has 'lower' => ( is => 'rw', isa => 'Lower', coerce => 1);


has 'max' => ( is => 'rw', isa => 'Num' );


has 'min' => ( is => 'rw', isa => 'Num' );


subtype 'Upper'
    => as 'Num|Undef'
    => where { defined($_) };

coerce 'Upper'
    => from 'Num|Undef'
    => via { EPSILON };

has 'upper' => ( is => 'rw', isa => 'Upper', coerce => 1);



has 'ticks' => ( is => 'rw', isa => 'Int', default    => 5 );


after 'lower' => sub {
    my $self = shift;

    if(defined($self->{'min'})) {
        $self->{'lower'} = $self->{'min'};
    }

    $self->{'lower'} = $self->{'min'} unless (defined($self->{'lower'}));
    $self->{'upper'} = $self->{'max'} unless (defined($self->{'upper'}));

    if(defined($self->{'lower'}) && defined($self->{'upper'}) && $self->{'lower'} == $self->{'upper'}) {
        $self->{'lower'} = $self->{'lower'} - EPSILON;
        $self->{'lower'} = $self->{'lower'} + EPSILON;
    }

};

after 'upper' => sub {
    my $self = shift;

    if(defined($self->{'max'})) {
        $self->{'upper'} = $self->{'max'};
    }

    $self->{'lower'} = $self->{'min'} unless (defined($self->{'lower'}));
    $self->{'upper'} = $self->{'max'} unless (defined($self->{'upper'}));

    if(defined($self->{'lower'}) && defined($self->{'upper'}) && $self->{'lower'} == $self->{'upper'}) {
        $self->{'upper'} = $self->{'upper'} - EPSILON;
        $self->{'upper'} = $self->{'upper'} + EPSILON;
    }

};

after 'min' => sub {
    my $self = shift;

    if(defined($self->{'min'})) {
        $self->{'lower'} = $self->{'min'};
    }
};

after 'max' => sub {
    my $self = shift;

    if(defined($self->{'max'})) {
        $self->{'upper'} = $self->{'max'};
    }
};


sub add {
    my ($self, $range) = @_;

    if(defined($self->upper)) {
        $self->upper($self->upper + $range->upper);
    } else {
        $self->upper($range->upper);
    }

    if(!defined($self->lower) || ($range->lower < $self->lower)) {
        $self->lower($range->lower);
    }
}


sub combine {
    my ($self, $range) = @_;

    unless(defined($self->min)) {
        if(!defined($self->lower) || ($range->lower < $self->lower)) {
            $self->lower($range->lower);
        }
    }

    unless(defined($self->max)) {
        if(!defined($self->upper) || ($range->upper > $self->upper)) {
            $self->upper($range->upper);
        }
    }

    return 1;
}


sub contains {
    my ($self, $value) = @_;

    return 1 if $value >= $self->lower && $value <= $self->upper;
    return 0;
}


sub span {
    my ($self) = @_;

    my $span = $self->upper - $self->lower;

    #we still want to be able to see flat lines!
    if ($span <= EPSILON) {
        $self->upper($self->upper() + EPSILON);
        $self->lower($self->lower() - EPSILON);
        $span = $self->upper - $self->lower;
    }
    return $span;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=pod

=head1 NAME

Chart::Clicker::Data::Range - A range of Data

=head1 VERSION

version 2.90

=head1 SYNOPSIS

  use Chart::Clicker::Data::Range;

  my $range = Chart::Clicker::Data::Range->new({
    lower => 1,
    upper => 10
  });

=head1 DESCRIPTION

Chart::Clicker::Data::Range implements a range of values.

=head1 ATTRIBUTES

=head2 lower

Set/Get the lower bound for this Range

=head2 max

Set/Get the maximum value allowed for this Range.  This value should only be
set if you want to EXPLICITLY set the upper value.

=head2 min

Set/Get the minimum value allowed for this Range.  This value should only be
set if you want to EXPLICITLY set the lower value.

=head2 upper

Set/Get the upper bound for this Range

=head2 ticks

The number of ticks to be displayed for this range.

=head1 METHODS

=head2 add

Adds the specified range to this one.  The lower is reduced to that of the
provided one if it is lower, and the upper is ADDED to this range's upper.

=head2 combine

Combine this range with the specified so that this range encompasses the
values specified.  For example, adding a range with an upper-lower of 1-10
with one of 5-20 will result in a combined range of 1-20.

=head2 contains ($value)

Returns true if supplied value falls within this range (inclusive).  Otherwise
returns false.

=head2 span

Returns the span of this range, or UPPER - LOWER.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
