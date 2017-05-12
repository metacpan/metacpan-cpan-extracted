package Amon2::DBI;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.33';

use parent qw/DBI/;

sub connect {
    my ($class, $dsn, $user, $pass, $attr) = @_;
    $attr->{RaiseError} = 1;
    $attr->{PrintError} = 0;
    $attr->{ShowErrorStatement} = 1;
    if ($DBI::VERSION >= 1.614) {
        $attr->{AutoInactiveDestroy} = 1 unless exists $attr->{AutoInactiveDestroy};
    }
    if ($dsn =~ /^dbi:SQLite:/i) {
        $attr->{sqlite_unicode} = 1 unless exists $attr->{sqlite_unicode};
    }
    elsif ($dsn =~ /^dbi:mysql:/i) {
        $attr->{mysql_enable_utf8} = 1 unless exists $attr->{mysql_enable_utf8};
    }
    elsif ($dsn =~ /^dbi:Pg:/i) {
        my $dbd_pg_version = eval { require DBD::Pg; (DBD::Pg->VERSION =~ /^([.0-9]+)\./)[0] };
        if ( !$@ and $dbd_pg_version < 2.99 ) { # less than DBD::Pg 2.99, pg_enable_utf8 must be set for utf8.
            $attr->{pg_enable_utf8} = 1 unless exists $attr->{pg_enable_utf8};
        }
    }
    my $self = $class->SUPER::connect($dsn, $user, $pass, $attr) or die "Cannot connect to server: $DBI::errstr";
    return $self;
}

package Amon2::DBI::dr;
our @ISA = qw(DBI::dr);

package Amon2::DBI::db; # database handler
our @ISA = qw(DBI::db);

use DBIx::TransactionManager;
use SQL::Interp ();
use Carp ();
use Scalar::Util ();

sub connected {
    my $dbh = shift;
    $dbh->{private_connect_info} = [@_];
    $dbh->SUPER::connected(@_);
}

sub connect_info { $_[0]->{private_connect_info} }

sub _txn_manager {
    my $self = shift;
    if (not defined $self->{private_txn_manager}) {
        $self->{private_txn_manager} = DBIx::TransactionManager->new($self);
        Scalar::Util::weaken($self->{private_txn_manager}->{dbh});
    }
    return $self->{private_txn_manager};
}

sub txn_scope { $_[0]->_txn_manager->txn_scope(caller => [caller(0)]) }

sub do_i {
    my $self = shift;
    my ($sql, @bind) = SQL::Interp::sql_interp(@_);
    $self->do($sql, {}, @bind);
}

sub insert {
    my ($self, $table, $vars) = @_;
    $self->do_i("INSERT INTO $table", $vars);
}

package Amon2::DBI::st; # statement handler
our @ISA = qw(DBI::st);

sub sql { $_[0]->{private_sql} }

1;
__END__

=encoding utf8

=head1 NAME

Amon2::DBI - Simple DBI wrapper

=head1 SYNOPSIS

    use Amon2::DBI;

    my $dbh = Amon2::DBI->connect(...);

=head1 DESCRIPTION

Amon2::DBI is a simple DBI wrapper. It provides better usability for you.

=head1 FEATURES

=over 4

=item Set AutoInactiveDestroy to true.

If your DBI version is higher than 1.614, Amon2::DBI set AutoInactiveDestroy as true.

=item Set sqlite_unicode and mysql_enable_utf8 and pg_enable_utf8 automatically

Amon2::DBI set sqlite_unicode and mysql_enable_utf8 automatically.
If using DBD::Pg version less than 2.99, pg_enable_utf8 too.

=item Nested transaction management.

Amon2::DBI supports nested transaction management based on RAII like DBIx::Class or DBIx::Skinny. It uses L<DBIx::TransactionManager> internally.

=item Raising error when you occurred.

Amon2::DBI raises exception if your $dbh occurred exception.

=back

=head1 ADDITIONAL METHODS

Amon2::DBI is-a DBI. And Amon2::DBI provides some additional methods.

=over 4

=item C<< $dbh->do_i(@args); >>

Amon2::DBI uses L<SQL::Interp> as a SQL generator. Amon2::DBI generate SQL using @args and do it.

=item C<< $dbh->insert($table, \%row); >>

It's equivalent to following statement:

    $dbh->do_i(qq{INSERT INTO $table }, \%row);

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
