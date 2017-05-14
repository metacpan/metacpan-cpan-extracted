package App::OverWatch::Notify::mysql;
# ABSTRACT: MySQL subclass for Notify

use strict;
use warnings;
use utf8;

use base 'App::OverWatch::Notify';

sub create_table {
    my $self = shift;

    my $sql =<<'CREATESQL';
CREATE TABLE `notifications` (
    `system`    VARCHAR(50) NOT NULL,
    `subsystem` VARCHAR(50) NOT NULL,

    `worker`    VARCHAR(50) NOT NULL,

    `ctime`     TIMESTAMP NOT NULL,
    `mtime`     TIMESTAMP NOT NULL,

    `fired`     TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,

    `text`   VARCHAR(100) NOT NULL DEFAULT '',

    PRIMARY KEY ( `system`, `subsystem`, `worker` )

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

App::OverWatch::Notify::mysql - MySQL subclass for Notify

=head1 VERSION

version 0.003

=head1 NAME

App::OverWatch::Notify::mysql - MySQL backend for App::OverWatch::Notify

=head1 METHODS

=head2 create_table

Create the 'notifications' table.

=head1 AUTHOR

Chris Hughes <chrisjh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Hughes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
