package Calendar::DatesRoles::DataPreparer::CalendarVar::FromDATA::Simple;

our $DATE = '2019-06-19'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
no strict 'refs'; # Role::Tiny imports strict for us

sub prepare_data {
    my $mod = shift;

    my $fh  = \*{"$mod\::DATA"};
    ${"$mod\::CALENDAR"} = {entries=>[]};
    my $cal = ${"$mod\::CALENDAR"};

    my $i = 0;
    while (my $line0 = <$fh>) {
        my $line = $line0;
        $i++;
        chomp $line;
        next unless $line =~ /\S/;
        if ($line =~ s/^#!//) {
            my ($name, $val) = $line =~ /(\S+)\s*:\s*(.*)/
                or die "BUG: $mod:data line $i: Invalid directive syntax: $line0";
            if ($name =~ /\A(default_lang)\z/) {
                $cal->{$name} = $val;
            } else {
                die "BUG: $mod:data line $i: Unknown directive '$name'";
            }
            next;
        }
        next if $line =~ /^#/;
        my @fields = split /;/, $line;
        my $e = {};
        $e->{date} = $fields[0];
        $e->{date} =~ /\A(\d{4})-(\d{2})-(\d{2})(?:T|\z)/a
            or die "BUG: $mod:data #$i: Invalid date syntax '$e->{date}'";
        $e->{year}  = $1;
        $e->{month} = $2 + 0;
        $e->{day}   = $3 + 0;
        $e->{summary} = $fields[1];
        while ($e->{summary} =~ s/\s*\{(\w+):([^}]*)\}\s*//) {
            $e->{"summary.alt.lang.$1"} = $2;
        }
        $e->{tags} = [split /,/, $fields[2]] if defined $fields[2];
        $e->{default_lang} //= $cal->{default_lang} if $cal->{default_lang};
        push @{ $cal->{entries} }, $e;
    }
}

1;
# ABSTRACT: Populate $CALENDAR from data in __DATA__

__END__

=pod

=encoding UTF-8

=head1 NAME

Calendar::DatesRoles::DataPreparer::CalendarVar::FromDATA::Simple - Populate $CALENDAR from data in __DATA__

=head1 VERSION

This document describes version 0.003 of Calendar::DatesRoles::DataPreparer::CalendarVar::FromDATA::Simple (from Perl distribution Calendar-DatesRoles-DataPreparer-CalendarVar-FromDATA-Simple), released on 2019-06-19.

=head1 DESCRIPTION

This role will set consumer's C<$CALENDAR> package variable from consumer's
C<__DATA__> section. The format of data in C<__DATA__> section is simple.

Data in C<__DATA__> is line-based. Entries should be in the following format:

 YYYY-MM-DD;Summary;tag1,tag2

Lines that start with C<#!> are called directives. Known directives:

 #!default_lang: VALUE

to set default language.

Blank lines or lines that start with C<#> (other than directives) are ignored.

Example:

 2019-02-14;Valentine's day
 2019-06-01;Pancasila day;holiday

Another example:

 #!default_lang: id

 2019-02-14;Hari Valentine
 2019-06-01;Hari lahirnya Pancasila;holiday

Another example to provide translation:

Another example:

 #!default_lang: id

 2019-02-14;Hari Valentine {en:Valentine's day}
 2019-06-01;Hari lahirnya Pancasila {en:Pancasila day};holiday

For more complex stuffs, you can use
L<Calendar::DatesRoles::DataPreparer::CalendarVar::FromDATA::CSVJF> or construct
C<$CALENDAR> yourself. Please consult
L<Calendar::DatesRoles::DataUser::CalendarVar>.

=head1 METHODS

=head2 prepare_data

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Calendar-DatesRoles-DataPreparer-CalendarVar-FromDATA-Simple>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Calendar-DatesRoles-DataPreparer-CalendarVar-FromDATA-Simple>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-DatesRoles-DataPreparer-CalendarVar-FromDATA-Simple>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Calendar::DatesRoles::DataPreparer::CalendarVar::FromDATA::CSVJF>

L<Calendar::Dates>

L<Calendar::DatesRoles::DataUser::CalendarVar>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
