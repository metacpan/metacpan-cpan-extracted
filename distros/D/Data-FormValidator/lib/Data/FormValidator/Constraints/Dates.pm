package Data::FormValidator::Constraints::Dates;
use Exporter 'import';
use 5.005;
use strict;

our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = (
    'date_and_time',
    @{ $EXPORT_TAGS{'all'} }
);

our @EXPORT = qw(
    match_date_and_time
);

our $VERSION = 4.88;

sub date_and_time {
    my $fmt = shift;
    return sub {
        my $self = shift;
        $self->set_current_constraint_name('date_and_time');
        return match_date_and_time($self,\$fmt);
    }
}

sub match_date_and_time {
    my $self = shift;
    my $fmt_ref =  shift || die q!date_and_time: need format parameter. Be sure to pass it by reference, like this: \'MM/DD/YYYY'!;
    my $fmt = $$fmt_ref;

    require Date::Calc;
    import Date::Calc (qw/check_date check_time/);

    my $format = _prepare_date_format($fmt);
    my ($date,$Y,$M,$D,$h,$m,$s) = _parse_date_format($format,$self->get_current_constraint_value);
    return if not defined $date;


    # We need to check the date if we find any in the format string, otherwise, it succeeds
    my $date_test = 1;
       $date_test = check_date($Y,$M,$D) if ($fmt =~ /[YMD]/) ;

    # If we find a time, check that
    my $time_test = 1;
       $time_test = check_time($h,$m,$s) if ($fmt =~ /[hms]/) ;

    # If either the time or date fails, it all fails
    return ($date_test && $time_test) ? $date : undef;
}

sub _prepare_date_format {
    my $format = shift;

    # Originally by Jan Krynicky

    # TODO: check that only valid characters appear in the format
    # The logic should be: for any character A-Z in the format string,
    #   die if it's not one of: Y M D h m s p

    my ($i, @order) = 0;
    $format =~ s{(Y+|M+|D+|h+|m+|s+|pp)(\?)?}{
        my ($chr,$q) = ($1,$2);
        $chr = '' if not defined $chr;
        $q   = '' if not defined $chr;

        $order[$i++] = substr($chr,0,1);
        if ($chr eq 'pp') {
            "(AM|PM|am|pm)"
        } else {
            '(' . ('\d' x length($chr)) . ($q ? $q : "") . ")"
        }
    }ge;


    $format = qr/^((?:$format))$/;
    return [$format, \@order];
}

sub _parse_date_format {
    # Originally by Jan Krynicky

    my ($format, $date) = @_;
    my ($untainted_date,@data) = ($date =~ $format->[0])
        or return;
    my %result;
    for(my $i = 0; $i <= $#data; $i++) {
        $result{$format->[1]->[$i]} ||= $data[$i];
    }

    if (exists $result{p}) {
        $result{h} += 12 if ($result{p} eq 'PM' and $result{h} != 12);
        $result{h} = 0   if ($result{p} eq 'AM' and $result{h} == 12);
    }


    return $untainted_date, map {defined $result{$_} ? $result{$_} : 0} qw(Y M D h m s);
}

1;
__END__

=head1 NAME

Data::FormValidator::Constraints::Dates - Validate Dates and Times

=head1 SYNOPSIS

    use Data::FormValidator::Constraints::Dates qw(date_and_time);

    # In a DFV profile...
    constraint_methods => {
        # 'pp' denotes AM|PM for 12 hour representation
        my_time_field => date_and_time('MM/DD/YYYY hh:mm:ss pp'),
    }

=head1 DESCRIPTION

=head2 date_and_time

B<Note:> This is a new module is a new addition to Data::FormValidator and is
should be considered "Beta".

This constraint creates a regular expression based on the format string
passed in to validate your date against. It understands the following symbols:

    Y   year  (numeric)
    M   month (numeric)
    D   day   (numeric)
    h   hour
    m   minute
    s   second
    p   AM|PM

Other parts of the string become part of the regular expression, so you can
do perlish things like this to create more complex expressions:

    'MM?/DD?/YYYY|YYYY-MM?-DD?'

Internally L<Date::Calc> is used to test the functions.

=head1 BACKWARDS COMPATIBILITY

This older, more awkward interface is supported:

    # In a Data::FormValidator Profile:
    validator_packages => [qw(Data::FormValidator::Constraints::Dates)],
    constraints => {
        date_and_time_field       => {
            constraint_method => 'date_and_time',
            params=>[\'MM/DD/YYYY hh:mm:ss pp'], # 'pp' denotes AM|PM for 12 hour representation
        },
    }

=head1 SEE ALSO

=over

=item o

L<Data::FormValidator>

=item o

L<Data::FormValidator::Constraints::DateTime>  - This alternative features
returning dates as DateTime objects and validating against the date formats
required for the MySQL and PostgreSQL databases.

=back

=head1 AUTHOR

Mark Stosberg, E<lt>mark@summersault.comE<gt>

Featuring clever code by Jan Krynicky.

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2005 by Mark Stosberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



1;
