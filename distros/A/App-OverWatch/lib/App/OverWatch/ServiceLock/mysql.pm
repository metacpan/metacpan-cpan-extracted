package App::OverWatch::ServiceLock::mysql;
# ABSTRACT: MySQL subclass for ServiceLock

use strict;
use warnings;
use utf8;

use base 'App::OverWatch::ServiceLock';

sub create_table {
    my $self = shift;

    my $sql =<<'CREATESQL';
CREATE TABLE `servicelocks` (
    `system`    VARCHAR(50) NOT NULL,

    `worker`    VARCHAR(50) NOT NULL,

    `status`    ENUM('UNLOCKED', 'LOCKED') NOT NULL,

    `mtime`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    /* Manager will reset lock after this time ... or we could just allow new locks to take it..? */
    `expiry`    TIMESTAMP NULL,

    `text`      VARCHAR(255) NOT NULL DEFAULT '',

    PRIMARY KEY ( `system` )

) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATESQL

    my $ret = $self->{DB}->dbix_run( $sql );
    return $ret == 0 ? 1 : 0;
}

sub timestamp_calculate_sql {
    my $self   = shift;
    my $expiry = shift;  # In minutes

    return 'NULL'
        if (!$expiry || $expiry !~ m/ ^ [0-9]+ $ /xms);

    return "TIMESTAMPADD(MINUTE, $expiry, NOW())"
}

sub generate_now_sql {
    my $self = shift;

    return "NOW()";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OverWatch::ServiceLock::mysql - MySQL subclass for ServiceLock

=head1 VERSION

version 0.1

=head1 NAME

App::OverWatch::ServiceLock::mysql - MySQL backend for App::OverWatch::ServiceLock

=head1 METHODS

=head2 create_table

Create the 'servicelocks' table.

=head2 timestamp_calculate_sql

Return SQL to allow calculation of expiry times.

=head2 generate_now_sql

Return SQL for 'NOW()'.

=head1 AUTHOR

Chris Hughes <chrisjh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Hughes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
