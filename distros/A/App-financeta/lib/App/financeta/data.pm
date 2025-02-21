package App::financeta::data;
use strict;
use warnings;
use 5.10.0;
use App::financeta::data::yahoo;
use App::financeta::data::gemini;
use App::financeta::utils qw(log_filter);
use Log::Any '$log', filter => \&App::financeta::utils::log_filter;

our $VERSION = '0.16';
$VERSION = eval $VERSION;
#our @EXPORT_OK = (qw(ohlcv));

sub ohlcv {
    my $src = shift;
    return App::financeta::data::yahoo::ohlcv(@_) if lc($src) eq 'yahoo';
    return App::financeta::data::gemini::ohlcv(@_) if lc($src) eq 'gemini';
    $log->error("Input source not supported: $src");
    return undef;
}


1;
__END__
### COPYRIGHT: 2013-2025. Vikas N. Kumar. All Rights Reserved.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
### DATE: 3rd Jan 2014
### LICENSE: Refer LICENSE file
