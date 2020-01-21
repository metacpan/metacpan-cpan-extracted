package MyTest;
use 5.012;
use POSIX qw(setlocale LC_ALL); setlocale(LC_ALL, 'en_US.UTF-8');
use Test::Catch;
use Config;

use Date qw/
    now date date_ymd rdate rdate_ymd rdate_const rdate_ymd_const today today_epoch :const
    tzset tzget gmtime localtime timegm timegmn timelocal timelocaln
/;

Date::use_embed_zones();
tzset('Europe/Moscow');

XS::Loader::load();

my $i64 = $Config{ivsize} >= 8;

sub subtest64 ($&;) {
    return unless $i64;
    return Test::More::subtest(@_);
}

sub import {
    no strict 'refs';
    my $stash = \%{MyTest::};
    my $caller = caller();
    *{"${caller}::$_"} = *{"MyTest::$_"} for keys %$stash;
}

sub get_dates {
    my $file = 't/time/data/'.shift().'.txt';
    open my $fh, '<', $file or die "Cannot open test data file '$file': $!";
    <$fh>; # skip stat line
    local $/ = undef;
    my $content = <$fh>;
    our $VAR1;
    my $ret = eval $content;
    die $@ unless $ret;

    unless ($i64) {
        while (my (undef, $list) = each %$ret) {
            @$list = grep { ($_->[0] >= -(2**31-1)) && ($_->[0] <= 2**31) } @$list;
        }
    }

    return $ret;
}

sub get_row_tl {
    my $row = shift;
    return lt2tl(@{$row->[1]});
}

sub lt2tl { return @_[0..5,8]; }

sub epoch_from {
    die "cant parse date" unless $_[0] =~ /^(-?\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)$/;
    my ($year, $mon, $mday, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
    return timegm($sec, $min, $hour, $mday, $mon-1, $year);
}

sub leap_zones_dir { return Date::tzdir().'/right' }

1;
