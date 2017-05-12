package testlib;

use Test::More;

sub compare {
    my ($dtf,$dt,$name) = @_;

    my $dts = $dtf->format_datetime($dt);

    my $dtc = $dtf->parse_datetime($dts);

    my $timezone = $dt->time_zone->name;
    my $locale = $dt->locale->id;
    my $nanosecond = $dt->nanosecond();

    unless($dtc && ref $dtc && $dtc->isa('DateTime')) {

        fail(join ("\n",
            "Pattern: '$dtf->{pattern}'",
            "String: '$dts'",
            "Original: '$dt.$nanosecond $timezone'",
            "Computed: UNDEF",
            "Locale: '$locale'",
            "Error: ".$dtf->errmsg,
            )
        );

        return;
    }

    unless ( DateTime->compare_ignore_floating( $dtc, $dt ) == 0) {
        my $nanosecondc = $dtc->nanosecond;
        my $timezonec = $dtc->time_zone->name;
        fail(join ("\n",
            "Pattern: '$dtf->{pattern}'",
            "String: '$dts'",
            "Original: '$dt.$nanosecond $timezone'",
            "Computed: '$dtc.$nanosecondc $timezonec'",
            "Locale: '$locale'",
            #,"Pattern: ". Dumper $dtf->{_built_pattern}
            )
        );
    }  else {
        pass($name || 'Successfully compared datetime '.$dtc.' for '.$locale);
    }

    return $dtc;
}

1;