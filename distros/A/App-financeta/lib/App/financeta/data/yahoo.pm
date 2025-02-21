package App::financeta::data::yahoo;
use strict;
use warnings;
use 5.10.0;
use Try::Tiny;
use Finance::QuoteHist;
use DateTime;
use App::financeta::utils qw(dumper log_filter);
use Log::Any '$log', filter => \&App::financeta::utils::log_filter;
use PDL::Lite;#for pdl

our $VERSION = '0.16';
$VERSION = eval $VERSION;
#our @EXPORT_OK = (qw(ohlcv));

sub ohlcv {
    my ($symbol, $start_date, $end_date) = @_;
    my $data;
    try {
        my @quotes = ();
        my $fq = Finance::QuoteHist->new(
            symbols => [ $symbol ],
            start_date => (ref $start_date eq 'DateTime') ? $start_date->mdy('/') : DateTime->new($start_date)->mdy('/'),
            end_date => (ref $end_date eq 'DateTime') ? $end_date->mdy('/') : DateTime->new($end_date)->mdy('/'),
            auto_proxy => 1,
        );
        $log->info("Starting to download quotes for $symbol for date range: $start_date -> $end_date");
        ## daily data not hourly or minute
        foreach my $row ($fq->quotes) {
            my ($sym, $date, $o, $h, $l, $c, $vol) = @$row;
            my ($yy, $mm, $dd) = split /\//, $date;
            my $epoch = DateTime->new(
                year => $yy,
                month => $mm,
                day => $dd,
                hour => 16, minute => 0, second => 0,
                time_zone => 'America/New_York',
            )->epoch;
            push @quotes, pdl($epoch, $o, $h, $l, $c, $vol);
        }
        $log->info("No. of rows downloaded: " . scalar(@quotes));
        $fq->clear_cache;
        $data = pdl(@quotes);
        $log->debug("Conversion of the data into a PDL object completed") if defined $data;
        $data = $data->transpose;##why is this done ?
        $log->debug("Transpose of the data into a PDL object completed") if defined $data;
    } catch {
        $log->error(__PACKAGE__ . " Error: " . $_);
        $data = undef;
    };
    return $data;
}


1;
__END__
### COPYRIGHT: 2013-2025. Vikas N. Kumar. All Rights Reserved.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
### DATE: 3rd Jan 2014
### LICENSE: Refer LICENSE file
