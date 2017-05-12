use Test::More qw(no_plan);

sub add_callback {} # needed to load a plugin into main::
BEGIN { use_ok('CGI::Application::Plugin::RateLimit') };

my $rate_limit = CGI::Application::Plugin::RateLimit->new();
isa_ok($rate_limit, 'CGI::Application::Plugin::RateLimit');
