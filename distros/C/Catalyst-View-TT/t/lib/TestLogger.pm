package TestLogger;

use strict;
use warnings;

use List::Util ();

our @Logs;

sub new {
    return bless { }, __PACKAGE__;
}

sub debug { }

sub info { }

sub warn { }

sub error {
    my ($self, $message) = @_;
    push @Logs, { level => 'error', message => $message };
}

sub clear {
    @Logs = ();
}

sub is_empty {
    return scalar(@Logs) == 0;
}

sub contains {
    my ($self, $check) = @_;
    return List::Util::any { $check->( $_->{message} ) } @Logs;
}

1;
