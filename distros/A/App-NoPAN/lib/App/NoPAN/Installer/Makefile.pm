package App::NoPAN::Installer::Makefile;

use strict;
use warnings;

use base qw(App::NoPAN::Installer);
use List::Util qw(first);
use Config;

App::NoPAN->register(__PACKAGE__);

sub can_install {
    my ($klass, $nopan, $root_files) = @_;
    ! ! first { $_ eq 'Makefile' } @$root_files;
}

sub build {
    my ($self, $nopan) = @_;
    $self->shell_exec("$Config{make} all");
}

sub test {
    my ($self, $nopan) = @_;
    $self->shell_exec("$Config{make} test")
        if $nopan->opt_test;
}

sub install {
    my ($self, $nopan) = @_;
    $self->shell_exec("$Config{make} install");
}

1;
