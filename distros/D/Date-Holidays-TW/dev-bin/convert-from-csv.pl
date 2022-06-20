#!/usr/bin/env perl

=head1 CSV ?


The CSV can be downloaded from:

     https://data.gov.tw/dataset/14718

Download the one named: 111年中華民國政府行政機關辦公日曆表

After converting that from Big5 to UTF-8, feed it to this program.

    perl ./dev-bin/convert-from-csv.pl  <( piconf -f big5 -t utf8 ~/Downloads/111年 中華民國政府行政機關辦公日曆表.csv )

=cut

use v5.36;
use utf8;

use Text::CSV;

my %CAL;

my $csv = Text::CSV->new ({ binary => 1 });

open my $fh, '<:utf8', $ARGV[0] or die $!;

$_ = <$fh>; # throw away the header line with BOM.

while ( my $row = $csv->getline($fh) ) {
    # 西元日期,星期,是否放假,備註
    my ($date, $weekday, $is_holiday,$description) = @$row;
    my ($year, $month, $day) = $date =~ m{^(....)(..)(..)$};

    if ($is_holiday) {
        my $mmdd = sprintf '%02d%02d', $month, $day;

        $description = "星期六、星期日" if !$description && $is_holiday && ($weekday eq "六" || $weekday eq "日");
        $CAL{$year}{$mmdd} = $description;
    }
}
close($fh);

# Hand-written dumper.
binmode STDOUT, ":utf8";
say 'my %CAL = (';
for my $year (sort keys %CAL) {
    say "    $year => {";
    for my $mmdd (sort keys %{$CAL{$year}}) {
        say "        \"$mmdd\" => \"$CAL{$year}{$mmdd}\",";
    }
    say "    },";
}
say ');';
