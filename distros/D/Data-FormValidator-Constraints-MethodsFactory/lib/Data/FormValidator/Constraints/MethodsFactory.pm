package Data::FormValidator::Constraints::MethodsFactory;

###############################################################################
# Required inclusions.
###############################################################################
use strict;
use warnings;

###############################################################################
# Version number.
###############################################################################
our $VERSION = '0.02';

###############################################################################
# Allow our methods to be exported
###############################################################################
use Exporter;
use base qw( Exporter );
use vars qw( @EXPORT_OK %EXPORT_TAGS );
%EXPORT_TAGS = (
    'set'   => [qw( FV_set FV_set_num FV_set_word FV_set_cmp )],
    'num'   => [qw( FV_clamp FV_lt FV_gt FV_le FV_ge )],
    'bool'  => [qw( FV_not FV_or FV_and )],
    );
@EXPORT_OK = map { @{$_} } values %EXPORT_TAGS;

###############################################################################
# Subroutine:   FV_set($result, @set)
###############################################################################
# Creates a constraint closure that will return the provided '$result' if the
# value is a member of the given '@set', or the negation of '$result'
# otherwise.
#
# The 'eq' operator is used for comparison.
###############################################################################
sub FV_set {
    my ($result, @set) = @_;
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        foreach my $elem (@set) {
            return $result if ($val eq $elem);
        }
        return !$result;
    }
}

###############################################################################
# Subroutine:   FV_set_num($result, @set)
###############################################################################
# Creates a constraint closure that will return the provided '$result' if the
# value is a member of the given '@set', or the negation of '$result'
# otherwise.
#
# The '==' operator is used for comparison.
###############################################################################
sub FV_set_num {
    my ($result, @set) = @_;
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        foreach my $elem (@set) {
            return $result if ($val == $elem);
        }
        return !$result;
    }
}

###############################################################################
# Subroutine:   FV_set_word($result, $set)
###############################################################################
# Creates a constraint closure that will return the provided '$result' if the
# value is a word in the given '$set', or the negation of '$result' otherwise.
###############################################################################
sub FV_set_word {
    my ($result, $set) = @_;
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        return ($set =~ /\b$val\b/i) ? $result : !$result;
    }
}

###############################################################################
# Subroutine:   FV_set_cmp($result, $cmp, @set)
###############################################################################
# Creates a constraint closure that will return the provided '$result' if the
# value is a member of the given '@set', or the negation of '$result'
# otherwise.
#
# '$cmp' is a function which takes two arguments, and should return true if the
# two elements are considered equal, otherwise returning false.
###############################################################################
sub FV_set_cmp {
    my ($result, $cmp, @set) = @_;
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        foreach my $elem (@set) {
            return $result if ($cmp->($val,$elem));
        }
        return !$result;
    }
}

###############################################################################
# Subroutine:   FV_clamp($result, $low, $high)
###############################################################################
# Creates a constraint closure that will return the provided '$result' if the
# value is numerically between the given '$low' and '$high' bounds, or the
# negation of '$result' otherwise.
###############################################################################
sub FV_clamp {
    my ($result, $low, $high) = @_;
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        return (($val < $low) or ($val > $high)) ? !$result : $result;
    }
}

###############################################################################
# Subroutine:   FV_lt($result, $bound)
###############################################################################
# Creates a constraint closure that will return the provided '$result' if the
# value is numerically less than the given '$bound', or the negation of
# '$result' otherwise.
###############################################################################
sub FV_lt {
    my ($result, $bound) = @_;
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        return ($val < $bound) ? $result : !$result;
    }
}

###############################################################################
# Subroutine:   FV_gt($result, $bound)
###############################################################################
# Creates a constraint closure that will return the provided '$result' if the
# value is numerically greater than the given '$bound', or the negation of
# '$result' otherwise.
###############################################################################
sub FV_gt {
    my ($result, $bound) = @_;
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        return ($val > $bound) ? $result : !$result;
    }
}

###############################################################################
# Subroutine:   FV_le($result, $bound)
###############################################################################
# Creates a constraint closure that will return the provided '$result' if the
# value is numerically less than or equal to the given '$bound', or the
# negation of '$result' otherwise.
###############################################################################
sub FV_le {
    my ($result, $bound) = @_;
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        return ($val <= $bound) ? $result : !$result;
    }
}

###############################################################################
# Subroutine:   FV_ge($result, $bound)
###############################################################################
# Creates a constraint closure that will return the provided '$result' if the
# value is numerically greater than or equal to the given '$bound', or the
# negation of '$result' otherwise.
###############################################################################
sub FV_ge {
    my ($result, $bound) = @_;
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        return ($val >= $bound) ? $result : !$result;
    }
}

###############################################################################
# Subroutine:   FV_not($constraint)
###############################################################################
# Creates a constraint closure that will return the negation of the result of
# the given '$constraint'.
###############################################################################
sub FV_not {
    my $constraint = shift;
    return sub { !$constraint->(@_) };
}

###############################################################################
# Subroutine:   FV_or(@constraints)
###############################################################################
# Creates a constraint closure that will return the result of the first
# constraint that returns a non-false result.
###############################################################################
sub FV_or {
    my @closures = @_;
    return sub {
        foreach my $c (@closures) {
            my $res = $c->(@_);
            return $res if $res;
        }
        return;
    }
}

###############################################################################
# Subroutine:   FV_and(@constraints)
###############################################################################
# Creates a constraint closure that will return the result of the first
# constraint to return a non-false result, -IF- ALL of the constraints return
# non-false results.
###############################################################################
sub FV_and {
    my @closures = @_;
    my $results;
    return sub {
        foreach my $c (@closures) {
            my $res = $c->(@_);
            return $res if (!$res);
            $results ||= $res;
        }
        return $results;
    }
}

1;

=head1 NAME

Data::FormValidator::Constraints::MethodsFactory - Create constraints for Data::FormValidator

=head1 SYNOPSIS

  use Data::FormValidator::Constraints::MethodsFactory qw(:set :num :bool);

  # SET constraints (:set)
  constraint_methods => {
      status        => FV_set(1, qw(new active disabled)),
      how_many      => FV_set_num(1, (1 .. 20)),
      province      => FV_set_word(1, "AB QC ON TN NU"),
      seen_before   => FV_set_cmp(1, sub { $seen{$_[0]} }, qw(foo bar)),
  }

  # NUMERIC constraints (:num)
  constraint_methods => {
      how_many      => FV_clamp(1, 1, 10),
      small_amount  => FV_lt(1, 3),
      large_amount  => FV_gt(1, 10),
      small_again   => FV_le(1, 3),
      large_again   => FV_ge(1, 10),
  }

  # BOOLEAN constraints (:bool)
  constraint_methods => {
      bad_status    => FV_not(
                            FV_set(1, qw(new active disabled))
                            ),
      email         => FV_or(
                            FV_set(1,$current_value),
                            Data::FormValidator::Constraints::email(),
                            ),
      password      => FV_and(
                            FV_length_between(6,32),
                            my_password_validation_constraint(),
                            ),
  }


=head1 DESCRIPTION

C<Data::FormValidator::Constraints::MethodsFactory> provides a variety of
functions that can be used to generate constraint closures for use with
C<Data::FormValidator>.

The functions/constraints provided are based on those from
C<Data::FormValidator::ConstraintsFactory>, B<BUT> are designed to be used as
"new-style" constraints (while C<Data::FormValidator::ConstraintsFactory> was
designed for use with "old-style" constraints).  Functionally, this module
provides equivalents for all of the constraints that were in
C<Data::FormValidator::ConstraintsFactory>, but if you're trying to do things
with the new-style you'll want to use the versions from this module instead.

The constraints provided by this module are broken up into three main
categories/sections:

=over

=item Set constraints (:set)

Constraint methods for working with "sets" of data.  Useful for when you want
to check and make sure that the provided value is from a list of valid choices.

The following constraints are exported via the C<:set> tag:

    FV_set
    FV_set_num
    FV_set_word
    FV_set_cmp

=item Numeric constraints (:num)

Constraint methods for working with numbers.  Useful when you want to check and
make sure that the provided value is within a specified range.

The following constraints are exported via the C<:num> tag:

    FV_clamp
    FV_lt
    FV_gt
    FV_le
    FV_ge

=item Boolean constraints (:bool)

Constraint methods for working with boolean conditions.  Useful when you want
to combine constraints together to create much more powerful constraints (e.g.
validating an e-mail address to make sure that it looks valid and has an
associated MX record, BUT only if the value actually changed from what we had
in the record previously).

The following constraints are exported via the C<:bool> tag:

    FV_not
    FV_or
    FV_and

=back

=head1 METHODS

=over

=item FV_set($result, @set)

Creates a constraint closure that will return the provided C<$result> if
the value is a member of the given C<@set>, or the negation of C<$result>
otherwise. 

The C<eq> operator is used for comparison. 

=item FV_set_num($result, @set)

Creates a constraint closure that will return the provided C<$result> if
the value is a member of the given C<@set>, or the negation of C<$result>
otherwise. 

The C<==> operator is used for comparison. 

=item FV_set_word($result, $set)

Creates a constraint closure that will return the provided C<$result> if
the value is a word in the given C<$set>, or the negation of C<$result>
otherwise. 

=item FV_set_cmp($result, $cmp, @set)

Creates a constraint closure that will return the provided C<$result> if
the value is a member of the given C<@set>, or the negation of C<$result>
otherwise. 

C<$cmp> is a function which takes two arguments, and should return true if
the two elements are considered equal, otherwise returning false. 

=item FV_clamp($result, $low, $high)

Creates a constraint closure that will return the provided C<$result> if
the value is numerically between the given C<$low> and C<$high> bounds, or
the negation of C<$result> otherwise. 

=item FV_lt($result, $bound)

Creates a constraint closure that will return the provided C<$result> if
the value is numerically less than the given C<$bound>, or the negation of
C<$result> otherwise. 

=item FV_gt($result, $bound)

Creates a constraint closure that will return the provided C<$result> if
the value is numerically greater than the given C<$bound>, or the negation
of C<$result> otherwise. 

=item FV_le($result, $bound)

Creates a constraint closure that will return the provided C<$result> if
the value is numerically less than or equal to the given C<$bound>, or the
negation of C<$result> otherwise. 

=item FV_ge($result, $bound)

Creates a constraint closure that will return the provided C<$result> if
the value is numerically greater than or equal to the given C<$bound>, or
the negation of C<$result> otherwise. 

=item FV_not($constraint)

Creates a constraint closure that will return the negation of the result of
the given C<$constraint>. 

=item FV_or(@constraints)

Creates a constraint closure that will return the result of the first
constraint that returns a non-false result. 

=item FV_and(@constraints)

Creates a constraint closure that will return the result of the first
constraint to return a non-false result, -IF- ALL of the constraints return
non-false results. 

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2007, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
license as Perl itself.

=head1 SEE ALSO

L<Data::FormValidator>.

=cut
