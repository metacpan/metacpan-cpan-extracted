package Date::Japanese::Era::Table::Builder;

use strict;
use vars qw($VERSION);
$VERSION = '0.02';

use vars qw(@ISA @EXPORT %ERA_TABLE %ERA_JA2ASCII %ERA_ASCII2JA);
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(%ERA_TABLE %ERA_JA2ASCII %ERA_ASCII2JA build_table);

use Carp;

sub build_table {
    my @eras;

    while (my $era = pop) {
        @$era == 5 or croak "Argument Error: Invalid era specification found: (@$era). 5 entries expected.";

        if (@eras) {
            use Date::Simple qw/ymd/;

            my $end_date = ymd($eras[0][2], $eras[0][3], $eras[0][4]) - 1;
            my $begin_date = ymd($era->[2], $era->[3], $era->[4]);

            $begin_date <= $end_date or croak "Argument error: The era ".$era->[1]." is later than ".$eras[0][1].", but specified before it.\n";

            push @$era, $end_date->year, $end_date->month, $end_date->day;
        } else {
            push @$era, 9999, 12, 31;
        }

        unshift @eras, $era;
    }

    for my $era (@eras) {
        my $kanji = shift @$era;

        $ERA_TABLE{$kanji} = $era;
    }

    %ERA_JA2ASCII = map { $_ => $ERA_TABLE{$_}->[0] } keys %ERA_TABLE;
    %ERA_ASCII2JA = reverse %ERA_JA2ASCII;
}

1;
__END__

=head1 NAME

Date::Japanese::Era::Table::Builder - conversion table builder for Date::Japanese::Era

=head1 SYNOPSIS

  use Date::Japanese::Era 'Builder';

  # Sets the table up as JIS_X0301
  Date::Japanese::Era::Table::Builder::build_table(
    ["\x{660E}\x{6CBB}", 'meiji',   1868,  9,  8],
    ["\x{5927}\x{6B63}", 'taishou', 1912,  7, 31],
    ["\x{662D}\x{548C}", 'shouwa',  1926, 12, 26],
    ["\x{5E73}\x{6210}", 'heisei',  1989,  1,  8],
    ["\x{4EE4}\x{548C}", 'reiwa',   2019,  5,  1],
  );

=head1 DESCRIPTION

This module is used to define the conversion table used by L<Date::Japanese::Era>, unfettered by concepts such as "post-gregorian-calender", "past eras only" and "factually correct".

The module has three primary uses: The (far) past, the (far) future, and the (alternate) present, and was written as a writing aid when dealing with stories relating to future eras of Japan, although it's equally useful for quick conversion of old eras in a selected range, or accessing the calendar as it would look with alternate era names.

=head1 METHODS

=over 4

=item build_table

The module has one subroutine: Date::Japanese::Era::Table::Builder::build_table(), which takes a list of eras in contiguous order of earliest to latest, each an array reference containing, in order, the proper era name, the ASCII era name, and the gregorian year, month and day that constitutes the first day of the era. (See example under SYNOPSIS.)

When using this module, it is critical that this subroutine is called before any calls to Date::Japanese::Era, unless you really know what you are doing.

=back

=head1 AUTHOR

Williham Totland E<lt>williham.totland@gmail.comE<gt>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 HISTORY

Developed as an extension to L<Date::Japanese::Era> by Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>.

=head1 SEE ALSO

L<Date::Japanese::Era>

=cut
