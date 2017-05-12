
use strict;
use warnings FATAL => 'all';

use Test::More;

use CGI::Application::Plugin::DevPopup::Log ();
eval "use Log::Dispatch::Handle";
plan skip_all => "Log::Dispatch::Handle required for this test" if $@;
eval "use Test::NoWarnings";
plan skip_all => "Test::NoWarnings required for this test" if $@;
plan tests => 2;

my $log = bless {}, 'CGI::Application::Plugin::DevPopup::Log';

like eval
{
    my $fh = $log->devpopup_log_handle;
    my $handle = Log::Dispatch::Handle->new(
        name      => 'test RT53100',
        min_level => 'debug',
        handle    => $fh,
    );
    $handle->log(level => "debug", message => "we live!");

    my $report = $log->_log_report;
}, qr/we live!/, "no fatal warnings";

__END__
1..2
ok 1 - no fatal warnings
ok 2 - no warnings
