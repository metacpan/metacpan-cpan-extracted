package Date::QuarterOfYear;
$Date::QuarterOfYear::VERSION = '0.03';
use 5.006;
use strict;
use warnings;
use Scalar::Util qw/ reftype /;
use Carp;
use parent 'Exporter';

our @EXPORT_OK = qw/ quarter_of_year /;

sub quarter_of_year
{
    my $date = _dwim_date(@_);
    my $quarter_number = 1 + int(($date->{month}-1) / 3);

    return wantarray
           ? ($date->{year}, $quarter_number)
           : sprintf('%4d-Q%d', $date->{year}, $quarter_number)
           ;
}

sub _dwim_date
{
    if (@_ == 1) {
        my $param = shift;

        if (reftype($param) && reftype($param) eq 'HASH') {
            return $param if exists($param->{year})
                          && exists($param->{month})
                          && exists($param->{day});
            croak "you must specify year, month and day\n";
        }
        elsif (reftype($param)) {
            croak "you can't pass a reference of type ".reftype($param);
        }
        elsif ($param =~ /^([0-9][0-9][0-9][0-9])-([0-9][0-9])-([0-9][0-9])$/) {
            return { year => $1, month => $2, day => $3 };
        }

        my @tm = gmtime($param);
        return { year => $tm[5] + 1900, month => $tm[4]+1, day => $tm[3] };

    }
    elsif (@_ == 3) {
        my ($year, $month, $day) = @_;
        return { year => $year, month => $month, day => $day };
    }
    elsif (@_ == 6) {
        my $hashref = { @_ };

        return $hashref if exists($hashref->{year})
                        && exists($hashref->{month})
                        && exists($hashref->{day});
        croak "you must specify year, month and day\n";
    }
    else {
        croak "invalid arguments\n";
    }
}

1;

=head1 NAME

Date::QuarterOfYear - calculate what quarter a given date is in

=head1 SYNOPSIS

 use Date::QuarterOfYear qw/ quarter_of_year /;

 $q = quarter_of_year('2013-02-17');        # '2013-Q1'
 $q = quarter_of_year($epoch);              # '2013-Q1'
 $q = quarter_of_year({ year => 2012, month => 8, day => 9 });

 ($year, $quarter) = quarter_of_year($epoch);

=head1 DESCRIPTION

Date::QuarterOfYear provides a single function, C<quarter_of_year>,
which takes a date and returns what quarter that date is in.
The input date can be specified in various ways, and the result
will either be returned as a string of the form 'YYYY-QN' (eg '2014-Q2'),
or as a list C<($year, $quarter)>.

 $time             = time();
 $qstring          = quarter_of_year($time);
 ($year, $quarter) = quarter_of_year($time);

This is a very simple module, and there are other modules that can
calculate the quarter for you. But I have similar code in multiple places
where I don't want to load L<DateTime> just for this.

=head1 SEE ALSO

L<DateTime> has several features related to quarters:
given a C<DateTime> instance, the C<quarter> method returns a
number between 1 and 4.
The C<day_of_quarter> method returns a number between 1 and the number
of days in the quarter.
The C<quarter_name> method returns a locale-specific name for the quarter.

L<Date::Format> provides a C<time2str> function that will generate
the quarter number (1..4).

L<Time::Moment> also provides a C<quarter> method that returns the
quarter number for a given date.

=head1 REPOSITORY

L<https://github.com/neilb/Date-QuarterOfYear>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

