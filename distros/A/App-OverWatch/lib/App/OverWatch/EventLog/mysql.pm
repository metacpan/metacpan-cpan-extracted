package App::OverWatch::EventLog::mysql;
# ABSTRACT: MySQL subclass for EventLog

use strict;
use warnings;
use utf8;

use base 'App::OverWatch::EventLog';

sub create_table {
    my $self = shift;

    my $sql =<<'CREATESQL';
CREATE TABLE `events` (
    `system`    VARCHAR(50) NOT NULL,
    `subsystem` VARCHAR(50) NOT NULL,

    `worker`    VARCHAR(50) DEFAULT NULL,

    `eventtype` ENUM('START', 'PROGRESS', 'END', 'POINT') NOT NULL,

    `ctime`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    `data`      BLOB

) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATESQL

    my $ret = $self->{DB}->dbix_run( $sql );
    return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OverWatch::EventLog::mysql - MySQL subclass for EventLog

=head1 VERSION

version 0.1

=head1 NAME

App::OverWatch::EventLog::mysql - MySQL backend for App::OverWatch::EventLog

=head1 METHODS

=head2 create_table

Create the 'events' table.

=head1 AUTHOR

Chris Hughes <chrisjh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Hughes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
