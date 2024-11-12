package App::financeta::data::gemini;
use strict;
use warnings;
use 5.10.0;
use Try::Tiny;
use LWP::UserAgent;
use JSON::XS qw(decode_json);
use DateTime;
use App::financeta::utils qw(dumper log_filter);
use Log::Any '$log', filter => \&App::financeta::utils::log_filter;
use PDL::Lite;#for pdl

our $VERSION = '0.15';
$VERSION = eval $VERSION;
#our @EXPORT_OK = (qw(ohlcv));

sub ohlcv {
    my ($symbol, $start_date, $end_date) = @_;
    my $data;
    try {
        $log->info("Starting to download quotes for $symbol for date range: $start_date -> $end_date");
        my $start_time = (ref $start_date eq 'DateTime') ? $start_date->epoch() : DateTime->new($start_date)->set_time_zone('UTC')->epoch;
        my $end_time = (ref $end_date eq 'DateTime') ? $end_date->epoch() : DateTime->new($end_date)->set_time_zone('UTC')->epoch;
        my $difftime = abs($end_time - $start_time);
        $log->debug("Start Date $start_date is $start_time in UNIX time");
        $log->debug("End Date $end_date is $end_time in UNIX time");
        my $granularity;
        if ($difftime <= 86400) {
            $granularity = '1m';
        } elsif ($difftime <= 5 * 86400) {
            $granularity = '5m';
        } elsif ($difftime <= 30 * 86400) {
            $granularity = '15m';
        } elsif ($difftime <= 60 * 86400) {
            $granularity = '30m';
        } elsif ($difftime <= 90 * 86400) {
            $granularity = '1hr';
        } elsif ($difftime <= 180 * 86400) {
            $granularity = '6hr';
        } else {
            $granularity = '1day';
        }
        $log->debug("Granularity selected is $granularity");
        my $url = sprintf ('https://api.gemini.com/v2/candles/%s/%s', lc($symbol), $granularity);
        $log->debug("Performing GET request to $url");
        my $lwp = LWP::UserAgent->new(timeout => 60);
        $lwp->env_proxy;
        my $res = $lwp->get($url);
        if ($res->is_success) {
            my $content = $res->decoded_content;
            if (defined $content and length($content)) {
                my $jquotes = decode_json($content);
                if (ref $jquotes eq 'ARRAY' and scalar(@$jquotes)) {
                    ## sort quotes by timestamp
                    my @sorted = sort { $a->[0] <=> $b->[0] } @$jquotes;
                    $log->info("No. of rows downloaded: " . scalar(@sorted));
                    foreach my $q (@sorted) {
                        $q->[0] /= 1000;#remove millisecond scale
                        #push @quotes, pdl(@$q);
                    }
                    $data = pdl(@sorted);
                    $log->debug("Conversion of the data into a PDL object completed") if defined $data;
                    $data = $data->transpose;##why is this done ?
                    $log->debug("Transpose of the data into a PDL object completed") if defined $data;
                } else {
                    $log->error("No quotes were returned in the content from $url: $content");
                    $data = undef;
                }
            } else {
                $log->error("No content was returned from URL $url");
                $data = undef;
            }
        } else {
            $log->error("Error getting URL $url: " . $res->status_line);
            $data = undef;
        }
    } catch {
        $log->error(__PACKAGE__ . " Error: " . $_);
        $data = undef;
    };
    return $data;
}


1;
__END__
### COPYRIGHT: 2013-2023. Vikas N. Kumar. All Rights Reserved.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
### DATE: 22nd Mar 2023
### LICENSE: Refer LICENSE file
