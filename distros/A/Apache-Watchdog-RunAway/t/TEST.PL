#!perl

use strict;
use warnings FATAL => 'all';

MyTest->new->run(@ARGV);




# sub-class Apache::TestRunPerl
package MyTest;

# 5.005-compat
BEGIN {
    require Apache::TestRunPerl;
    @MyTest::ISA = qw(Apache::TestRunPerl);
}

# so we get a nice view of procs/threads
use constant MIN_MAXCLIENTS => 5;

# subclass new_test_config to add some config vars which will be
# replaced in generated httpd.conf
sub new_test_config {
    my $self = shift;

    $self->{conf_opts}->{maxclients} ||= MIN_MAXCLIENTS;

    return $self->SUPER::new_test_config;
}
