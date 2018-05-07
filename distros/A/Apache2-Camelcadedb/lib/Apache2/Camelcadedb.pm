package Apache2::Camelcadedb;

use strict;
use warnings;

=head1 NAME

Apache2::Camelcadedb - mod_perl2 integration for Devel::Camelcadedb

=head1 SYNOPSIS

In mod_perl2 startup code:

    use Apache2::Camelcadedb remote_host => 'localhost:12345';

In apache.conf

    # they don't have to be PostReadRequest and Cleanup, as long
    # as they are early and late in the request lifecycle
    PerlPostReadRequestHandler Apache2::Camelcadedb::start_debug_handler
    PerlCleanupHandler Apache2::Camelcadedb::stop_debug_handler

=cut

our $VERSION = '0.01';

use constant {
    DEBUG_SINGLE_STEP_ON        =>  0x20,
    DEBUG_USE_SUB_ADDRESS       =>  0x40,
    DEBUG_REPORT_GOTO           =>  0x80,
    DEBUG_ALL                   => 0x7ff,
};

use constant {
    DEBUG_OFF                   => 0x0,
    DEBUG_PREPARE_FLAGS         => # 0x73c
        DEBUG_ALL & ~(DEBUG_USE_SUB_ADDRESS|DEBUG_REPORT_GOTO|DEBUG_SINGLE_STEP_ON),
};

sub import {
    my ($class, %args) = @_;

    die "Specify 'remote_host'"
        unless $args{remote_host};
    my ($host, $port) = split /:/, $args{remote_host}, 2;

    $ENV{PERL5_DEBUG_HOST} = $host;
    $ENV{PERL5_DEBUG_PORT} = $port;
    $ENV{PERL5_DEBUG_ROLE} = 'client';
    $ENV{PERL5_DEBUG_AUTOSTART} = 0;

    if ($args{enbugger}) {
        require Enbugger;

        Enbugger->VERSION(2.014);
        Enbugger->load_source;
    }

    my $inc_path = $args{debug_client_path};
    unshift @INC, ref $inc_path ? @$inc_path : $inc_path
        if $inc_path;
    require Devel::Camelcadedb;

    $^P = DEBUG_PREPARE_FLAGS;

    require Apache2::RequestRec;
    require Apache2::Const;

    Apache2::Const->import('-compile' => 'OK');
}

sub reopen_camelcadedb_connection {
    DB::connect_or_reconnect();
    DB::enable() if DB::is_connected();
}

sub close_camelcadedb_connection {
    DB::disconnect();
    DB::disable();
}

sub start_debug_handler {
    my $r = shift;
    reopen_camelcadedb_connection();
    return Apache2::Const::OK();
}

sub stop_debug_handler {
    my $r = shift;
    close_camelcadedb_connection()
        if DB::is_connected();
    return Apache2::Const::OK();
}

1;

__END__

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

Copyright (c) 2015-2016 Mattia Barbon. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
