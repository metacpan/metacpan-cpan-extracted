=head1 NAME

Cz::Time - Routines for printing dates in Czech

=head1 SYNOPSIS

	use Cz::Time;
	my $today = cz_wday() . " " . cz_date();
	my $new_year = " 1. " . cz_month_base(1); 

=head1 DESCRIPTION

Implements czech names of months and weekdays. The following functions
are exported:

=over 4

=item cz_date

Converts time (localtime if not specified) into Czech string, eg.
15. ledna 1997.

=item cz_month_base, cz_month

Czech names of months (1..12)

=item cz_wday, cz_ab_wday

Czech names of weekdays and weekdays' abreviation.

=back

By default they are returned in ISO-8859-2.

=head1 AUTHORS

(c) 1997 Jan Pazdziora <adelton@fi.muni.cz>,
    1997 Michael Mráka <michael@fi.muni.cz>

at Faculty of Informatics, Masaryk University, Brno

=head1 VERSION

0.02

=head1 SEE ALSO

perl(1), Cz::Cstocs(3).

=cut

package Cz::Time;

use strict;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK );

use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw( cz_date cz_month cz_wday cz_month_base cz_ab_wday );
@EXPORT_OK = qw( cz_date cz_month cz_wday cz_month_base cz_ab_wday );
	
$VERSION = '0.02';

my @CZ_MONTH_BASE = qw( leden únor bøezen duben kvìten èerven èervenec
        srpen záøí øíjen listopad prosinec );
my @CZ_WEEK_DAYS = qw( nedìle pondìlí úterý støeda ètvrtek pátek sobota );
my @CZ_AB_WEEK_DAYS = qw( Ne Po Út St Èt Pá So );

sub cz_month_base
        {
        my $month = shift;
        return $CZ_MONTH_BASE[$month-1];
        }
sub cz_month
        {
        my $month = shift;
        local $_ = $CZ_MONTH_BASE[$month-1];
        s!en$!na! or s!ec$!ce! or s!ad$!adu! or s!or$!ora!;
        $_;
        }
sub cz_date
        {
        my @t;
        if (@_) { @t = @_; } else { @t = localtime; }
        return $t[3] . '. ' . cz_month($t[4] + 1) . ' ' . ($t[5] + 1900);
        }
sub cz_wday
        {
        my @t;
        if (@_) { @t = @_; } else { @t = localtime; }
        $CZ_WEEK_DAYS[$t[6]];
        }
sub cz_ab_wday
        {
        my @t;
        if (@_) { @t = @_; } else { @t = localtime; }
        $CZ_AB_WEEK_DAYS[$t[6]];
        }

1;
__END__
