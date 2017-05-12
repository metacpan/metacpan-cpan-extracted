package Class::DBI::SQLite;

use strict;
use vars qw($VERSION);
$VERSION = "0.11";

require Class::DBI;
use base qw(Class::DBI);

sub _auto_increment_value {
    my $self = shift;
    return $self->db_Main->func("last_insert_rowid");
}

sub set_up_table {
    my($class, $table) = @_;

    # find all columns.
    my $sth = $class->db_Main->prepare("PRAGMA table_info('$table')");
    $sth->execute();
    my @columns;
    while (my $row = $sth->fetchrow_hashref) {
	push @columns, $row->{name};
    }
    $sth->finish;

    # find primary key. so complex ;-(
    $sth = $class->db_Main->prepare(<<'SQL');
SELECT sql FROM sqlite_master WHERE tbl_name = ?
SQL
    $sth->execute($table);
    my($sql) = $sth->fetchrow_array;
    $sth->finish;
    my ($primary) = $sql =~ m/
    (?:\(|\,) # either a ( to start the definition or a , for next
    \s*       # maybe some whitespace
    (\w+)     # the col name
    [^,]*     # anything but the end or a ',' for next column
    PRIMARY\sKEY/sxi;
    my @pks;
    if ($primary) {
        @pks = ($primary);
    } else {
        my ($pks)= $sql =~ m/PRIMARY\s+KEY\s*\(\s*([^)]+)\s*\)/;
        @pks = split(m/\s*\,\s*/, $pks) if $pks;
    }
    $class->table($table);
    $class->columns(Primary => @pks);
    $class->columns(All => @columns);
}

1;

__END__

=head1 NAME

Class::DBI::SQLite - Extension to Class::DBI for sqlite

=head1 SYNOPSIS

  package Film;
  use base qw(Class::DBI::SQLite);
  __PACKAGE__->set_db('Main', 'dbi:SQLite:dbname=dbfile', '', '');
  __PACKAGE__->set_up_table('Movies');

  package main;
  my $film = Film->create({
     name  => 'Bad Taste',
     title => 'Peter Jackson',
  });
  my $id = $film->id;		# auto-incremented

=head1 DESCRIPTION

Class::DBI::SQLite is an extension to Class::DBI for DBD::SQLite.
It allows you to populate an auto-incremented row id after insert.

The C<set_up_table> method automates the setup of columns and
primary key(s) via the SQLite PRAGMA statement.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

C<set_up_table> implementation by Tomohiro Ikebe E<lt>ikebe@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>, L<DBD::SQLite> 

=cut
