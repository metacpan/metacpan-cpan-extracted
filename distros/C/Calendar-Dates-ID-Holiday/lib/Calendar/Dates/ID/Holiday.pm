package Calendar::Dates::ID::Holiday;

our $DATE = '2019-02-13'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Calendar::Indonesia::Holiday;
use Role::Tiny::With;

with 'Calendar::DatesRoles::FromData';

our @ENTRIES;
my $res = Calendar::Indonesia::Holiday::list_id_holidays(detail=>1);
die "Cannot get list of holidays from Calendar::Indonesia::Holiday: $res->[0] - $res->[1]"
    unless $res->[0] == 200;
for my $e (@{ $res->[2] }) {
    $e->{summary} = delete $e->{eng_name};
    $e->{"summary.alt.lang.id"} = delete $e->{ind_name};
    if ($e->{eng_aliases} && @{ $e->{eng_aliases} }) {
        $e->{description} = "Also known as ".
            join(", ", @{ delete $e->{eng_aliases} });
    }
    if ($e->{ind_aliases} && @{ $e->{ind_aliases} }) {
        $e->{"description.alt.lang.id"} = "Juga dikenal dengan ".
            join(", ", @{ delete $e->{ind_aliases} });
    }
    push @ENTRIES, $e;
}

1;
# ABSTRACT: Indonesian holiday calendar

__END__

=pod

=encoding UTF-8

=head1 NAME

Calendar::Dates::ID::Holiday - Indonesian holiday calendar

=head1 VERSION

This document describes version 0.002 of Calendar::Dates::ID::Holiday (from Perl distribution Calendar-Dates-ID-Holiday), released on 2019-02-13.

=head1 DESCRIPTION

This module provides Indonesian holiday calendar using the L<Calendar::Dates>
interface.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Calendar-Dates-ID-Holiday>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Calendar-Dates-ID-Holiday>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-Dates-ID-Holiday>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Calendar::Dates>

L<Calendar::Indonesia::Holiday>, the backend

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
