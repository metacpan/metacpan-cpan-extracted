#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use strict;
use warnings;
use utf8;
use Test::More;

my $syslogtest;

BEGIN {
    if (-d '.svn' || -d ".git") {
        $syslogtest = 1;
        plan tests => 9;
    } else {
        $syslogtest = 0;
        plan tests => 5;
    }
    use_ok('CTK::Log', qw/ :constants /)
};

# Create syslog logger (default)
if ($syslogtest) {
    my $logger = new_ok( 'CTK::Log' );
    ok($logger->status, "Status is true") or diag(explain($logger));
    note($logger->error) if $logger->error;
    ok($logger->log_info("Blah-Blah-Blah"), "Info message");
    ok($logger->log(LOG_CRIT, "Blah-Blah-Blah"), "Crit message");
    note($logger->error) if $logger->error;
}

# Create file logger
{
    my $logger = new_ok( 'CTK::Log', [
            file  => "10-test.log",
            level => LOG_ERROR,
            ident => "test",
        ]);
    #note(explain($logger));
    ok($logger->status, "Status is true") or diag(explain($logger));
    note($logger->error) if $logger->error;
    ok(!$logger->log_info("Blah-Blah-Blah"), "Info message");
    ok($logger->log(LOG_CRIT, "Blah-Blah-Blah"), "Crit message");
    note($logger->error) if $logger->error;
}

1;

__END__
