package DBD::BlackHole;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.03";

use DBI;

our $drh    = undef;
our $err    = '';
our $errstr = '';

sub driver {
    my ($class, $attr) = @_;
    return $drh ||= DBI::_new_drh("${class}::dr", {
        Name        => 'BlackHole',
        Version     => $VERSION,
        Attribution => 'BlackHole DBD driver',
        Err         => \$err,
	Errstr      => \$errstr,
    });
}

sub CLONE {
    undef $drh;
}

package DBD::BlackHole::dr;
use strict;
use warnings;

our $imp_data_size = 0;

sub connect {
    my $dbh = shift->SUPER::connect(@_)
        or return;
    $dbh->STORE(Active => 1);
    return $dbh;
}

sub data_sources { qw/dbi:BlackHole:/ }

package DBD::BlackHole::db;
use strict;
use warnings;

use Carp qw/croak/;

use constant DEFAULT_IDENTIFIER => '`';

our $imp_data_size = 0;

sub get_info {
    my ($dbh, $type) = @_;
    # identifier quote
    return $dbh->FETCH('blackhole_identifier') || DEFAULT_IDENTIFIER if $type == 29;
    return;
}

sub prepare {
    my ($dbh, $statement) = @_;

    my $sth = DBI::_new_sth($dbh, {
        Statement     => $statement,
	NAME          => ['dummy'],
        NUM_OF_FIELDS => -1,
    });

    return $sth;
}

sub ping { shift->FETCH('Active') }

sub disconnect { shift->STORE(Active => 0) }

sub begin_work { 1 }
sub commit { 1 }
sub rollback { 1 }
sub tables {}

sub FETCH {
    my $dbh = shift;
    my $key = shift;
    return 1 if $key eq 'AutoCommit';
    return $dbh->SUPER::FETCH($key);
}

sub STORE {
    my $dbh = shift;
    my ($key, $value) = @_;

    if ($key eq 'AutoCommit') {
        croak 'Cannot disable AutoCommit' if !$value && $dbh->FETCH('AutoCommit');
        return $value;
    }
    return $dbh->SUPER::STORE($key, $value);
}

sub DESTROY { shift->disconnect }

package DBD::BlackHole::st;
use strict;
use warnings;

our $imp_data_size = 0;

sub bind_col { 1 }
sub bind_param { 1 }

sub execute {
    my $sth = shift;
    $sth->STORE(NUM_OF_FIELDS => 1);
    $sth->STORE(NUM_OF_PARAMS => 0);
    1;
}

sub rows { 0 }

sub fetch {}

sub fetchall_hashref { +{} }

1;
__END__

=encoding utf-8

=head1 NAME

DBD::BlackHole - NULL database driver for DBI

=head1 SYNOPSIS

    use DBI;

    my $dbh = DBI->connect('dbi:BlackHole:', undef, undef); # always successful

    $dbh->do('INSERT INTO my_table (val) VALUES (?)', undef, 'value'); # always successful

    my $rows = $dbh->selectall_arrayref('SELECT * FROM my_table'); # always returns empty arrayref

=head1 DESCRIPTION

DBD::BlackHole is a null database driver for DBI.

This module dosen't parse/execute any query, and it fetches a empty result always.

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
