#
#    ConstraintsFactory.pm - Module to create constraints for Data::FormValidator.
#
#    This file is part of Data::FormValidator.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#    Maintainer: Mark Stosberg <mark@summersault.com>
#
#    Copyright (C) 2000 iNsu Innovations Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms as perl itself.
#
use strict;

package Data::FormValidator::ConstraintsFactory;
use Exporter 'import';

=pod

=head1 NAME

Data::FormValidator::ConstraintsFactory - Module to create constraints for HTML::FormValidator.

=head1 DESCRIPTION

This module contains functions to help generate complex constraints.

If you are writing new code, take a look at L<Data::FormValidator::Constraints::MethodsFactory>
instead. It's a modern alternative to what's here, offering improved names and syntax.

=head1 SYNOPSIS

    use Data::FormValidator::ConstraintsFactory qw( :set :bool );

    constraints => {
    param1 => make_or_constraint(
            make_num_set_constraint( -1, ( 1 .. 10 ) ),
            make_set_constraint( 1, ( 20 .. 30 ) ),
          ),
    province => make_word_set_constraint( 1, "AB QC ON TN NU" ),
    bid  => make_range_constraint( 1, 1, 10 ),
    }

=cut

BEGIN {
    our $VERSION = 4.88;
    our @EXPORT = ();
    our @EXPORT_OK = (qw/make_length_constraint/);

    our %EXPORT_TAGS =
      (
       bool => [ qw( make_not_constraint make_or_constraint
             make_and_constraint ) ],
       set  => [ qw( make_set_constraint make_num_set_constraint
             make_word_set_constraint make_cmp_set_constraint ) ],
       num  => [ qw( make_clamp_constraint make_lt_constraint
             make_le_constraint make_gt_constraint
             make_ge_constraint ) ],
      );

    Exporter::export_ok_tags( 'bool' );
    Exporter::export_ok_tags( 'set' );
    Exporter::export_ok_tags( 'num' );

}

=pod

=head1 BOOLEAN CONSTRAINTS

Those constraints are available by using the C<:bool> tag.

=head2 make_not_constraint( $c1 )

This will create a constraint that will return the negation of the
result of constraint $c1.

=cut

sub make_not_constraint {
    my $c1 = $_[0];
    # Closure
    return sub { ! $c1->( @_ ) };
}

=head2 make_or_constraint( @constraints )

This will create a constraint that will return the result of the first
constraint that return an non false result.

=cut

sub make_or_constraint {
    my @c = @_;
    # Closure
    return sub {
    my $res;
    for my $c ( @c ) {
        $res = $c->( @_ );
        return $res if $res;
    }
    return $res;
    };
}

=head2 make_and_constraint( @constraints )

This will create a constraint that will return the result of the first
constraint that return an non false result only if all constraints
returns a non-false results.

=cut

sub make_and_constraint {
    my @c = @_;

    # Closure
    return sub {
    my $res;
    for my $c ( @c ) {
        $res = $c->( @_ );
        return $res if ! $res;

        $res ||= $res;
    }
    return $res;
    };
}

=pod

=head1 SET CONSTRAINTS

Those constraints are available by using the C<:set> tag.

=head2 make_set_constraint( $res, @elements )

This will create a constraint that will return $res if the value
is one of the @elements set, or the negation of $res otherwise.

The C<eq> operator is used for comparison.

=cut

sub make_set_constraint {
    my $res = shift;
    my @values = @_;

    # Closure
    return sub {
    my $v = $_[0];
    for my $t ( @values ) {
        return $res if $t eq $v;
    }
    return ! $res;
    }
}

=head2 make_num_set_constraint( $res, @elements )

This will create a constraint that will return $res if the value
is one of the @elements set, or the negation of $res otherwise.

The C<==> operator is used for comparison.

=cut

sub make_num_set_constraint {
    my $res = shift;
    my @values = @_;

    # Closure
    return sub {
    my $v = $_[0];
    for my $t ( @values ) {
        return $res if $t == $v;
    }
    return ! $res;
    }
}

=head2 make_word_set_constraint( $res, $set )

This will create a constraint that will return $res if the value is
a word in $set, or the negation of $res otherwise.

=cut

sub make_word_set_constraint {
    my ($res,$set) = @_;

    # Closure
    return sub {
    my $v = $_[0];
    if ( $set =~ /\b$v\b/i ) {
        return $res;
    } else {
        return ! $res;
    }
    }
}

=head2 make_cmp_set_constraint( $res, $cmp, @elements )

This will create a constraint that will return $res if the value
is one of the @elements set, or the negation of $res otherwise.

$cmp is a function which takes two argument and should return true or false depending if the two elements are equal.

=cut

sub make_match_set_constraint {
    my $res = shift;
    my $cmp = shift;
    my @values = @_;

    # Closure
    return sub {
    my $v = $_[0];
    for my $t ( @values ) {
        return $res if $cmp->($v, $t );
    }
    return ! $res;
    }
}

=pod

=head1 NUMERICAL LOGICAL CONSTRAINTS

Those constraints are available by using the C<:num> tag.

=head2 make_clamp_constraint( $res, $low, $high )

This will create a constraint that will return $res if the value
is between $low and $high bounds included or its negation otherwise.

=cut

sub make_clamp_constraint {
    my ( $res, $low, $high ) = @_;

    return sub {
    my $v = $_[0];
    $v < $low || $v > $high ? ! $res : $res;
    }
}

=head2 make_lt_constraint( $res, $bound )

This will create a constraint that will return $res if the value
is lower than $bound, or the negation of $res otherwise.

=cut

sub make_lt_constraint {
    my ( $res, $bound ) = @_;

    return sub {
    $_[0] < $bound ? $res : ! $res;
    }
}

=head2 make_le_constraint( $res, $bound )

This will create a constraint that will return $res if the value
is lower or equal than $bound, or the negation of $res otherwise.

=cut

sub make_le_constraint {
    my ( $res, $bound ) = @_;

    return sub {
    $_[0] <= $bound ? $res : ! $res;
    }
}

=head2 make_gt_constraint( $res, $bound )

This will create a constraint that will return $res if the value
is greater than $bound, or the negation of $res otherwise.

=cut

sub make_gt_constraint {
    my ( $res, $bound ) = @_;

    return sub {
    $_[0] >= $bound ? $res : ! $res;
    }
}

=head2 make_ge_constraint( $res, $bound )

This will create a constraint that will return $res if the value
is greater or equal than $bound, or the negation of $res otherwise.

=cut

sub make_ge_constraint {
    my ( $res, $bound ) = @_;

    return sub {
    $_[0] >= $bound ? $res : ! $res;
    }
}

=head1 OTHER CONSTRAINTS

=head2 make_length_constraint($max_length)

This will create a constraint that will return true if the value
has a length of less than or equal to $max_length

=cut

sub make_length_constraint {
    my $max_length = shift;
    return sub { length(shift) <= $max_length };
}

1;


__END__

=pod

=head1 SEE ALSO

Data::FormValidator(3)

=head1 AUTHOR

Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
Maintainer: Mark Stosberg <mark@summersault.com>

=head1 COPYRIGHT

Copyright (c) 2000 iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=cut

