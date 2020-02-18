package Calendar::DatesRoles::ReturnTimeMomentObjects;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-17'; # DATE
our $DIST = 'Calendar-DatesRoles-ReturnTimeMomentObjects'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Time::Moment;
use Role::Tiny;

around get_entries => sub {
    my $orig = shift;
    my $entries = $orig->(@_);

    for my $entry (@$entries) {
        if ($entry->{date} =~ m!\A(\d\d\d\d)-(\d\d)-(\d\d)
                                (?:
                                    T(\d\d):(\d\d)
                                    (?:
                                        /(\d\d):(\d\d)
                                    )?
                                )?\z!x) {
            my ($y, $m, $d, $H1, $M1, $H2, $M2) = ($1,$2,$3, $4,$5, $6,$7);

            if (defined $H2) {
                $entry->{date_end} = Time::Moment->new(
                    year=>$y, month=>$m, day=>$d, hour=>$H2, minute=>$M2, second=>0);
            }
            if (defined $H1) {
                $entry->{date} = Time::Moment->new(
                    year=>$y, month=>$m, day=>$d, hour=>$H1, minute=>$M1, second=>0);
            } else {
                $entry->{date} = Time::Moment->new(
                    year=>$y, month=>$m, day=>$d);
            }
        } else {
            die "Can't parse entry's 'date' field: $entry->{date}";
        }

    }

    $entries;
};

1;
# ABSTRACT: Return Time::Moment objects in get_entries()

__END__

=pod

=encoding UTF-8

=head1 NAME

Calendar::DatesRoles::ReturnTimeMomentObjects - Return Time::Moment objects in get_entries()

=head1 VERSION

This document describes version 0.002 of Calendar::DatesRoles::ReturnTimeMomentObjects (from Perl distribution Calendar-DatesRoles-ReturnTimeMomentObjects), released on 2020-02-17.

=head1 SYNOPSIS

 # apply the role to a Calendar::Dates::* class
 use Calendar::Dates::ID::Holiday;
 use Role::Tiny;
 Role::Tiny->apply_roles_to_package(
     'Calendar::Dates::ID::Holiday',
     'Calendar::DatesRoles::ReturnDateTimeObjects');

 # use the Calendar::Dates::* module as usual
 my $entries = Calendar::Dates::ID::Holiday->get_entries(2020);

 # now the 'date' field in each entry in $entries are Time::Moment objects
 # instead of 'YYYY-MM-DD' strings.

=head1 DESCRIPTION

This role is similar to L<Calendar::DatesRoles::ReturnDateTimeObjects> but
instead of returning L<DateTime> objects, this role returns L<Time::Moment>
objects instead.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Calendar-DatesRoles-ReturnTimeMomentObjects>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Calendar-DatesRoles-ReturnTimeMomentObjects>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-DatesRoles-ReturnTimeMomentObjects>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Calendar::Dates>

L<Calendar::DatesRoles::ReturnDateTimeObjects>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
