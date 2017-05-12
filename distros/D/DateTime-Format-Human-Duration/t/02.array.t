use Test::More;
use lib 't/lib';
use DateTime::Format::Human::Duration;
use FindBin qw($Bin);
use File::Spec;
BEGIN { push @INC, File::Spec->catfile($Bin, 'lib'); }


my $fmt = DateTime::Format::Human::Duration->new;

SKIP: {
    eval 'use DateTime';
    skip 'DateTime required for creating DateTime object and durations', 2 if $@;

    my $dta = DateTime->now( locale => 'nb' );
    my $dtb = $dta->clone->add( minutes => 1 );
    my $dtc = $dta->clone->subtract( minutes => 1 );

    is($fmt->format_duration_between($dta, $dtb, past => '%s ago', future => 'in %s'), '1mi ago');
    is($fmt->format_duration_between($dta, $dtc, past => '%s ago', future => 'in %s'), 'in 1mi');
};

done_testing();
