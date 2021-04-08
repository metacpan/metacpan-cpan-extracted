use 5.012;
use POSIX qw/ceil mktime/;
use Data::Dumper qw/Dumper/;
use FindBin;

my $output = "$FindBin::Bin/../tests/time/gendata.icc";

my %data;

while (my $line = <DATA>) {
    chomp($line);
    $line =~ s/#.+//;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    my ($name, $from_str, $till_str, $step, @zones) = split /\s*,\s*/, $line;
    next unless $name and $from_str and $till_str and $step;
    @zones = grep {$_} @zones;
    die "no zones in '$line'" unless @zones;

    my $subdata = $data{$name} ||= {};
    my $cnt;
    
    say "Generating $line";
    foreach my $tz (@zones) {
        $ENV{TZ} = $tz;
        POSIX::tzset();
        
        my $from = get_epoch($from_str);
        my $till = get_epoch($till_str);
        die "BAD from or till" if $from == -1 or $till == -1;
        my $list = $subdata->{$tz} ||= [];
        
        if ($step > 0) {
            $cnt = ceil(($till - $from) / $step);
            for (my $time = $from; $time <= $till; $time += $step) {
                my @date = localtime($time);
                $date[5] += 1900;
                push @$list, $time, @date;
            }
        } else {
            $cnt = -$step;
            my $range = $till - $from;
            for (my $i = 0; $i < $cnt; $i++) {
                my $time = int rand($range);
                my @date = localtime($time);
                $date[5] += 1900;
                push @$list, $time, @date;
            }
        }
    }
}

my $str = out_data(\%data);
open my $fh, '>', $output or die "Cannot open $output: $!";
print $fh $str, "\n";
close $fh;

sub out_data {
    my $data = shift;
    return
        "{\n".(join ",\n", map {
            "    {\"$_\", ".out_zones($data->{$_})."}"
        } keys %$data).
        "\n}";
}

sub out_zones {
    my $data = shift;
    return "{\n".(join ",\n", map {
            "        {\"$_\", ".out_list($data->{$_})."}"
        } keys %$data).
        "\n    }";
}

sub out_list {
    my $list = shift;
    return '"'.join(",", @$list).'"';
}

sub get_epoch {
    my $str = shift;
    die "cannot parse date '$str'" unless $str =~ m#^"?(-?\d+)[/-](-?\d+)[/-](-?\d+) (-?\d+):(-?\d+):(-?\d+)"?$#;
    my ($Y, $M, $D, $h, $m, $s) = ($1, $2, $3, $4, $5, $6);
    return mktime($s, $m, $h, $D, $M-1, $Y);
}

__DATA__
utc, 1500-01-01 00:00:00, 2500-01-01 00:00:00, 20000000, UTC
utc, -600-01-01 00:00:00,  100-01-01 00:00:00, 20000000, UTC
utc, 2004-12-31 23:00:00, 2005-01-01 01:00:00,      599, UTC # QUAD YEARS threshold
utc, 1900-12-31 23:00:00, 1901-01-01 01:00:00,      599, UTC # CENT YEARS threshold
utc, 2000-12-31 23:00:00, 2001-01-01 01:00:00,      599, UTC # QUAD CENT YEARS threshold
utc, -500-01-01 00:00:00, 4000-01-01 00:00:00,    -1000, UTC
utc, 1970-01-01 00:00:00, 2030-01-01 00:00:00,    -1000, UTC

local, 1800-01-01 00:00:00, 1806-01-01 00:00:00, 299999, Europe/Moscow, America/New_York, Australia/Melbourne
local, 1930-01-01 00:00:00, 1936-01-01 00:00:00, 299999, Europe/Moscow, America/New_York, Australia/Melbourne
local, 1950-01-01 00:00:00, 1956-01-01 00:00:00, 299999, Europe/Moscow, America/New_York, Australia/Melbourne
local, 1980-01-01 00:00:00, 1986-01-01 00:00:00, 299999, Europe/Moscow, America/New_York, Australia/Melbourne
local, 2000-01-01 00:00:00, 2006-01-01 00:00:00, 299999, Europe/Moscow, America/New_York, Australia/Melbourne
local, 2016-01-01 00:00:00, 2022-01-01 00:00:00, 299999, Europe/Moscow, America/New_York, Australia/Melbourne
local, 2060-01-01 00:00:00, 2066-01-01 00:00:00, 299999, Europe/Moscow, America/New_York, Australia/Melbourne
local, 1800-01-01 00:00:00, 2200-01-01 00:00:00,  -1000, Europe/Moscow, America/New_York, Australia/Melbourne
local, 1970-01-01 00:00:00, 2030-01-01 00:00:00,  -1000, Europe/Moscow, America/New_York, Australia/Melbourne

right, 1980-01-01 00:00:00, 1986-01-01 00:00:00, 999999, right/Europe/Moscow, right/America/New_York, right/Australia/Melbourne
right, 2000-01-01 00:00:00, 2006-01-01 00:00:00, 999999, right/Europe/Moscow, right/America/New_York, right/Australia/Melbourne
right, 2016-01-01 00:00:00, 2022-01-01 00:00:00, 999999, right/Europe/Moscow, right/America/New_York, right/Australia/Melbourne
right, 1800-01-01 00:00:00, 2035-01-01 00:00:00,   -500, right/UTC, right/Europe/Moscow, right/America/New_York, right/Australia/Melbourne
right, 1970-01-01 00:00:00, 2035-01-01 00:00:00,   -500, right/UTC, right/Europe/Moscow, right/America/New_York, right/Australia/Melbourne