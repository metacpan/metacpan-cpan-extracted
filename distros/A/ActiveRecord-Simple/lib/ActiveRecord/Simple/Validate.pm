package ActiveRecord::Simple::Validate;

use strict;
use warnings;


sub check {
	my ($fld, $val) = @_;

	my $check_result = _check($val, {
        data_type     => $fld->{data_type},
        is_nullable   => $fld->{is_nullable},
        size          => $fld->{size},
        default_value => $fld->{default_value},
    });

    return (0, $check_result->{error})
    	if $check_result->{error};

    return 1;
}

sub _check {
    my ($val, $fld) = @_;

    if (exists $fld->{is_nullable}) {
        _check_for_null(
            $val,
            $fld->{is_nullable},
            (exists $fld->{default_value} && defined $fld->{default_value})
        )
        or return { error => "Can't be null" };
    }

    if (exists $fld->{data_type}) {
        _check_for_data_type($val, $fld->{data_type}, $fld->{size})
            or return { error => "Invalid value for type " . $fld->{data_type} };
    }

    return { result => 1 };
}

sub _check_for_null {
    my ($val, $is_nullable, $has_default_value) = @_;

    if ($is_nullable == 0 && (not defined $val or $val eq '')) {
        return $has_default_value ? 1 : undef;
    }
    # else
    return 1;
}

sub _check_for_data_type {
    my ($val, $data_type, $size) = @_;

    return 1 unless $data_type;

    my %TYPE_CHECKS = (
        int      => \&_check_int,
        integer  => \&_check_int,
        tinyint  => \&_check_int,
        smallint => \&_check_int,
        bigint   => \&_check_int,

        double => \&_check_numeric,
       'double precision' => \&_check_numeric,

        decimal => \&_check_numeric,
        dec => \&_check_numeric,
        numeric => \&_check_numeric,

        real => \&_check_float,
        float => \&_check_float,

        bit => \&_check_bit,

        date => \&_check_DUMMY, # DUMMY
        datetime => \&_check_DUMMY, # DUMMY
        timestamp => \&_check_DUMMY, # DUMMY
        time => \&_check_DUMMY, # DUMMY

        char => \&_check_char,
        varchar => \&_check_varchar,

        binary => \&_check_DUMMY, # DUMMY
        varbinary => \&_check_DUMMY, # DUMMY
        tinyblob => \&_check_DUMMY, # DUMMY
        blob => \&_check_DUMMY, # DUMMY
        text => \&_check_DUMMY,
    );

    return (exists $TYPE_CHECKS{$data_type}) ? $TYPE_CHECKS{$data_type}->($val, $size) : 1;
}

sub _check_DUMMY { 1 }
sub _check_int {
    my ($int) = @_;
    no warnings 'numeric';
    return 0 unless ($int eq int($int));
    return 1;
}
sub _check_varchar {
    my ($val, $size) = @_;

    return length $val <= $size->[0];
}
sub _check_char {
    my ($val, $size) = @_;

    return length $val == $size->[0];
}
sub _check_float { shift =~ /^\d+\.\d+$/ }

sub _check_numeric {
    my ($val, $size) = @_;

    return 1 unless
        defined $size &&
        ref $size eq 'ARRAY' &&
        scalar @$size == 2;

    my ($first, $last) = $val =~ /^(\d+)\.(\d+)$/;

    $first && length $first <= $size->[0] or return;
    $last && length $last <= $size->[1] or return;

    return 1;
}

sub _check_bit {
    my ($val) = @_;

    return ($val == 0 || $val == 1) ? 1 : undef;
}


1;
