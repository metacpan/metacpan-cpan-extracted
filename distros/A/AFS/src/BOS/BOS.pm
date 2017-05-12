package AFS::BOS;
#------------------------------------------------------------------------------
# RCS-Id: "@(#)$RCS-Id: src/BOS/BOS.pm 7a64d4d Wed May 1 22:05:49 2013 +0200 Norbert E Gruener$"
#
# © 2005-2010 Norbert E. Gruener <nog@MPA-Garching.MPG.de>
# © 2003-2004 Alf Wachsmann <alfw@slac.stanford.edu> and
#             Norbert E. Gruener <nog@MPA-Garching.MPG.de>
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#------------------------------------------------------------------------------

use Carp;
use AFS ();

use vars qw(@ISA $VERSION);

@ISA     = qw(AFS);
$VERSION = 'v2.6.4';

sub DESTROY {
    my (undef, undef, undef, $subroutine) = caller(1);
    if (! defined $subroutine or $subroutine !~ /eval/) { undef $_[0]; }  # self->DESTROY
    else { AFS::BOS::_DESTROY($_[0]); }                                   # undef self
}

sub create {
    my $self     = shift;
    my $process  = shift;
    my $type     = shift;
    my $command  = shift;
    my $notifier = shift;

    if (! defined $process ||
        ! defined $type    ||
        ! defined $command) {
        carp "AFS::BOS->create: incomplete arguements specified ...\n";
        return 0;
    }

    if (ref($command) eq 'ARRAY') {
        if ($notifier) { $self->_create($process, $type, $command, $notifier); }
        else           { $self->_create($process, $type, $command); }
    }
    elsif (ref($command) eq '' ) {
        my @commands;
        $commands[0] = $command;
        if ($notifier) { $self->_create($process, $type, \@commands, $notifier); }
        else           { $self->_create($process, $type, \@commands); }
    }
    else {
        carp "AFS::BOS->create: not a valid COMMAND input ...\n";
        return 0;
    }
}

sub restart {
    my $self = shift;


    if ($#_ == 0 and ref($_[0]) eq 'ARRAY') {            # SERVER is array ref
        $self->_restart(0, 0, @_);
    }
    elsif ($#_ == 0 and ref($_[0]) eq '') {              # SERVER is scalar
        my @server;
        $server[0] = shift;
        $self->_restart(0, 0, \@server);
    }
    else {
        carp "AFS::BOS->restart: not a valid input ...\n";
        return undef;
    }
}

sub restart_all {
    my $self = shift;

    $self->_restart(0, 1);
}

sub restart_bos {
    my $self = shift;

    $self->_restart(1);
}

sub start {
    my $self = shift;

    if ($#_ == 0 and ref($_[0]) eq 'ARRAY') {            # SERVER is array ref
        $self->_start(@_);
    }
    elsif ($#_ == 0 and ref($_[0]) eq '') {              # SERVER is scalar
        my @server;
        $server[0] = shift;
        $self->_start(\@server);
    }
    else {
        carp "AFS::BOS->start: not a valid input ...\n";
        return undef;
    }
}

sub startup {
    my $self = shift;

    if ($#_ == -1) {                                     # no input given
        $self->_startup();
    }
    elsif ($#_ == 0 and ref($_[0]) eq 'ARRAY') {         # SERVER is array ref
        $self->_startup(@_);
    }
    elsif ($#_ == 0 and ref($_[0]) eq '') {              # SERVER is scalar
        my @server;
        $server[0] = shift;
        $self->_startup(\@server);
    }
    else {
        carp "AFS::BOS->startup: not a valid input ...\n";
        return undef;
    }
}

sub status {
    my $self = shift;

    if ($#_ > 0 and ! defined $_[1]) { $_[1] = ''; } # INSTANCE is not defined

    if (ref($_[1]) eq 'ARRAY' or $#_ <= 0) {         # INSTANCE is array ref
        $self->_status(@_);
    }
    elsif ($_[1] eq '') {                            # INSTANCE is not defined
        $self->_status($_[0]);
    }
    elsif (ref($_[1]) eq '') {                       # INSTANCE is scalar
        my @server;
        my @args = @_;
        $server[0] = $args[1];
        $args[1] = \@server;
        $self->_status(@args);
    }
    else {
        carp "AFS::BOS->status: not a valid input ...\n";
        return undef;
    }
}

sub stop {
    my $self = shift;

    if ($#_ == -1 or ($#_ > -1 and ! defined $_[0])) {
        carp "AFS::BOS->stop: not a valid input ...\n";
        return undef;
    }

    if (ref($_[0]) eq 'ARRAY') {                      # SERVER is array ref
        $self->_stop(@_);
    }
    elsif (ref($_[0]) eq '') {                        # SERVER is scalar
        my @server;
        $server[0] = shift;
        $self->_stop(\@server, @_);
    }
    else {
        carp "AFS::BOS->stop: not a valid input ...\n";
        return undef;
    }
}

sub shutdown {
    my $self = shift;

    if ($#_ == 1 and ref($_[0]) eq 'ARRAY') {            # SERVER is array ref
        $self->_shutdown(@_);
    }
    elsif ($#_ == 1 and ref($_[0]) eq '') {              # SERVER is scalar
        my @server;
        $server[0] = shift;
        $self->_shutdown(\@server, @_);
    }
    elsif ($#_ == 0 and ref($_[0]) eq 'ARRAY') {         # SERVER is array ref
        $self->_shutdown(@_);
    }
    elsif ($#_ == 0 and $_[0] =~ /^\d$/ && $_[0] == 1) { # SERVER is undefined
        $self->_shutdown(undef, @_);
    }
    elsif ($#_ == 0 and $_[0] =~ /^\d$/ && $_[0] == 0) { # SERVER is undefined
        $self->_shutdown(undef, @_);
    }
    elsif ($#_ == 0 and ref($_[0]) eq '') {              # SERVER is scalar
        my @server;
        $server[0] = shift;
        $self->_shutdown(\@server);
    }
    elsif ($#_ == -1) {                                  # no input given
        $self->_shutdown();
    }
    else {
        carp "AFS::BOS->shutdown: not a valid input ...\n";
        return undef;
    }
}

1;
