use strict;
use warnings;
use Test::More tests => 12;

BEGIN {
    use_ok('App::Sysadmin::Log::Simple');
    use_ok('App::Sysadmin::Log::Simple::File');
    use_ok('App::Sysadmin::Log::Simple::UDP');
    use_ok('App::Sysadmin::Log::Simple::Twitter');
}
my $logger = new_ok('App::Sysadmin::Log::Simple');
can_ok($logger, qw(new run run_command run_command_log run_command_view));

my $file_logger = new_ok('App::Sysadmin::Log::Simple::File');
can_ok($file_logger, qw(new log view));

my $udp_logger = new_ok('App::Sysadmin::Log::Simple::UDP');
can_ok($udp_logger, qw(new log));

my $twitter_logger = new_ok('App::Sysadmin::Log::Simple::Twitter');
can_ok($twitter_logger, qw(new log));
