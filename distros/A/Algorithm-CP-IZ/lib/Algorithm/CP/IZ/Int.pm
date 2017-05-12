package Algorithm::CP::IZ::Int;

use strict;
use warnings;

use UNIVERSAL;

use overload '""' => \&stringify;

sub stringify {
    my $self = shift;
    my @list;


    my $cur = $self->min;
    my $head = $cur;
    my $max = $self->max;

    while ($cur != $max) {
	my $next = $self->get_next_value($cur);
	if ($next != $cur + 1) {
	    if ($head == $cur) {
		push(@list, $cur);
	    }
	    else {
		push(@list, "$head..$cur");
	    }

	    $head = $next;
	}
	$cur = $next;
    }

    # $cur == $max
    if ($head == $max) {
	push(@list, $max);
    }
    else {
	push(@list, "$head..$cur");
    }

    my $vals;
    if ($self->is_instantiated) {
	$vals = $list[0];
    }
    else {
	$vals = join("", "{" . join(", ", @list) . "}");
    }

    if ($self->{_name}) {
	return $self->{_name} . ": " . $vals;
    }
    else {
	return $vals;
    }
}

sub key {
    my $self = shift;

    # reference to element of hash
    # (pointer is hidden from usr)
    my $ret = \$self->{_ptr};

    return "$ret";
}

sub new {
    my $class = shift;
    my $ptr = shift;

    bless {
	_ptr => $ptr,
    }, $class;
}

sub name {
    my $self = $_[0];
    if (@_ == 1) {
	return $self->{_name};
    }

    $self->{_name} = $_[1];
}

sub nb_elements {
    my $self = shift;
    return Algorithm::CP::IZ::cs_getNbElements($self->{_ptr});
}

sub min {
    my $self = shift;
    return Algorithm::CP::IZ::cs_getMin($self->{_ptr});
}

sub max {
    my $self = shift;
    return Algorithm::CP::IZ::cs_getMax($self->{_ptr});
}

sub value {
    my $self = shift;
    return Algorithm::CP::IZ::cs_getValue($self->{_ptr});
}

sub is_free {
    my $self = shift;
    return Algorithm::CP::IZ::cs_isFree($self->{_ptr});
}

sub is_instantiated {
    my $self = shift;
    return Algorithm::CP::IZ::cs_isInstantiated($self->{_ptr});
}

sub domain {
    my $self = shift;
    my @ret;

    my $val = $self->min;
    my $max = $self->max;

    do {
	push(@ret, $val);
	$val = Algorithm::CP::IZ::cs_getNextValue($self->{_ptr}, $val);
    } while ($val <= $max);

    return \@ret;
}

sub get_next_value {
    my $self = shift;
    my $val = shift;
    
    return Algorithm::CP::IZ::cs_getNextValue($self->{_ptr}, int($val));
}

sub get_previous_value {
    my $self = shift;
    my $val = shift;

    return Algorithm::CP::IZ::cs_getPreviousValue($self->{_ptr}, int($val));
}

sub is_in {
    my $self = shift;
    my $val = shift;

    return Algorithm::CP::IZ::cs_is_in($self->{_ptr}, int($val));
}

sub Eq {
    my $self = shift;
    my $val = shift;
    if (ref $val && $val->isa(__PACKAGE__)) {
	return Algorithm::CP::IZ::cs_Eq($self->{_ptr}, $val->{_ptr});
    }

    return Algorithm::CP::IZ::cs_EQ($self->{_ptr}, int($val));
}

sub Neq {
    my $self = shift;
    my $val = shift;
    if (ref $val && $val->isa(__PACKAGE__)) {
	return Algorithm::CP::IZ::cs_Neq($self->{_ptr}, $val->{_ptr});
    }

    return Algorithm::CP::IZ::cs_NEQ($self->{_ptr}, int($val));
}

sub Le {
    my $self = shift;
    my $val = shift;
    if (ref $val && $val->isa(__PACKAGE__)) {
	return Algorithm::CP::IZ::cs_Le($self->{_ptr}, $val->{_ptr});
    }

    return Algorithm::CP::IZ::cs_LE($self->{_ptr}, int($val));
}

sub Lt {
    my $self = shift;
    my $val = shift;
    if (ref $val && $val->isa(__PACKAGE__)) {
	return Algorithm::CP::IZ::cs_Lt($self->{_ptr}, $val->{_ptr});
    }

    return Algorithm::CP::IZ::cs_LT($self->{_ptr}, int($val));
}

sub Ge {
    my $self = shift;
    my $val = shift;
    if (ref $val && $val->isa(__PACKAGE__)) {
	return Algorithm::CP::IZ::cs_Ge($self->{_ptr}, $val->{_ptr});
    }

    return Algorithm::CP::IZ::cs_GE($self->{_ptr}, int($val));
}

sub Gt {
    my $self = shift;
    my $val = shift;
    if (ref $val && $val->isa(__PACKAGE__)) {
	return Algorithm::CP::IZ::cs_Gt($self->{_ptr}, $val->{_ptr});
    }

    return Algorithm::CP::IZ::cs_GT($self->{_ptr}, int($val));
}

sub InArray {
    my $self = shift;
    my $int_array = shift;
    unless (ref $int_array && ref $int_array eq 'ARRAY') {
	croak('InArray: usage: $v->InArray([array_ref]');
    }

    my $parray = Algorithm::CP::IZ::alloc_int_array([map { int($_) } @$int_array]);
    my $ret = Algorithm::CP::IZ::cs_InArray($self->{_ptr}, $parray, scalar @$int_array);

    Algorithm::CP::IZ::free_array($parray);

    return $ret;
}

sub NotInArray {
    my $self = shift;
    my $int_array = shift;
    unless (ref $int_array && ref $int_array eq 'ARRAY') {
	croak('InArray: usage: $v->NotInArray([array_ref]');
    }

    my $parray = Algorithm::CP::IZ::alloc_int_array([map { int($_) } @$int_array]);
    my $ret = Algorithm::CP::IZ::cs_NotInArray($self->{_ptr}, $parray, scalar @$int_array);

    Algorithm::CP::IZ::free_array($parray);

    return $ret;
}

sub InInterval {
    my $self = shift;
    my ($min, $max) = @_;

    return Algorithm::CP::IZ::cs_InInterval($self->{_ptr}, int($min), int($max));
}

sub NotInInterval {
    my $self = shift;
    my ($min, $max) = @_;

    return Algorithm::CP::IZ::cs_NotInInterval($self->{_ptr}, int($min), int($max));
}

sub _invalidate {
    my $self = shift;
    bless $self, __PACKAGE__ . "::InvalidInt";
}

1;

__END__

=head1 NAME

Algorithm::CP::IZ::Int - Domain variable for Algorithm::CP::IZ

=head1 SYNOPSIS

  use Algorithm::CP::IZ;

  my $iz = Algorithm::CP::IZ->new();

  # create instances of Algorithm::CP::IZ::Int
  # contains domain {0..9}
  my $v1 = $iz->create_int(1, 9);
  my $v2 = $iz->create_int(1, 9);

  # add constraint
  $iz->Add($v1, $v2)->Eq(12);

  # get current status
  print $v1->nb_elements, "\n2;

  # print domain
  print "$v1\n";

=head1 DESCRIPTION

Algorithm::CP::IZ::Int is perl representation of CSint object in iZ-C library.
This class is called also 'domain variable'.

=head2 DOMAIN

Domain is a set of candidate values of solution which can satisfy current
constraint setting.

You can declare range of domain (which integer is in domain) when
creating variable.
Variable can take values 1..9 (1..9 is in domain) in following example.

  my $var = $iz->create_int(1, 9);

Values will be removed by applying constraint.
For example, After applying constraint $var->Le(3) to above example variable,
domain of $var is 1..3.

  $var->Le(3);     # $var <= 3 (6..9 is removed from domain)
  print "$var\n";  # Output will be "{1..3}".

=head2 FREE AND INSTANTIATED

If domain variable has more than one value, it is calld 'free'.

  my $rc = $var->is_free;  # $rc is 1

If domain has just one value, it is calld 'instantiated'.

  $rc = $var->is_instantiated;  # $rc is 1

If all domain variables are instantiated satisfing constraints,
variables represent solution of input problem.

=head2 FAIL

If All values are removed from domain, it is assumed as "fail".
(no solution is found under current constraint setting)

All constraint method returns 1 (OK) or 0 (fail).

  $rc = $var->Le(0); # fail
  print "$rc\n";        # Output will be 0.


=head1 METHODS

=over 2

=item stringify

Create string representation of this variable.
('""' operator has overloaded to call this method.)

=item keys

Returns string to use hash key.
Don't use following code. (stringify-ed string is not unique!)

  %hash{$v} = "something";

Use this:

  %hash{$v->key} = "something";

=item name

Get name of this variable.

=item name(NAME)

Set name of this variable.

=item nb_elements

Returns count of values in domain.

=item min

Returns minimum value of domain.

=item max

Returns maximum value of domain.

=item value

Returns instantiated value of this variable.

If this method called for not instancited variable, exception will be thrown.

=item is_free

Returns 1 (domain has more than 1 value) or 0 (domain has 1 only value).

=item is_instantiated

Returns 1 (instantiated, it means domain has only 1 value)
or 0 (domain has more than 1 value).

=item domain

Returns array reference of domain values.

=item get_next_value(X)

Returns a value next value of X in domain. (If domain is {0, 1, 2, 3} and
X is 1, next value is 2)

X is an integer value.

=item get_previous_value

Returns a value previous value of X in domain. (If domain is {0, 1, 2, 3} and
X is 2, next value is 1)

X is an integer value.

=item is_in(X)

Returns 1 (X is in domain) or 0 (X is not in domain)

X is an integer value.

=item Eq(X)

Constraints this variable "equal to X".
X is an integer or an instance of Algorithm::CP::IZ::Int.

=item Neq(X)

Constraints this variable "not equal to X".
X is an integer or an instance of Algorithm::CP::IZ::Int.

=item Le(X)

Constraints this variable "less or equal to X".
X is an integer or an instance of Algorithm::CP::IZ::Int.

=item Lt(X)

Constraints this variable "less than X".
X is an integer or instance of Algorithm::CP::IZ::Int.

=item Ge(X)

Constraints this variable "greater or equal to X".
X is an integer or instance of Algorithm::CP::IZ::Int.

=item Gt(X)

Constraints this variable "greater than X".
X is an integer or an instance of Algorithm::CP::IZ::Int.

=item InArray(ARRAYREF_OF_INT)

Constraints this variable to be element of arrayref.

=item NotInArray(ARRAYREF_OF_INT)

Constraints this variable not to be element of arrayref.

=item InInterval(MIN, MAX)

Constraints this variable to be range MIN to MAX.

=item NotInInterval(MIN, MAX)

Constraints this variable not to be range MIN to MAX.


=back

=head1 SEE ALSO

L<Algorithm::CP::IZ>

=head1 AUTHOR

Toshimitsu FUJIWARA, E<lt>tttfjw at gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Toshimitsu FUJIWARA

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
