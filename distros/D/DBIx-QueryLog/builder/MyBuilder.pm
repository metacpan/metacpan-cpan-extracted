package builder::MyBuilder;

use strict;
use warnings;
use parent 'Module::Build';

sub ACTION_test {
    my $self = shift;
    require t::Util;
    print STDERR '### starting mysqld...';
    print STDERR t::Util::setup_mysqld()     ? "done.\n" : "skip.\n";
    print STDERR '### starting postgresql...';
    print STDERR t::Util::setup_postgresql() ? "done.\n" : "skip.\n";

    $self->SUPER::ACTION_test(@_);
}

1;
