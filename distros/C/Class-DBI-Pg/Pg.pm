package Class::DBI::Pg;

use strict;
require Class::DBI;
use base 'Class::DBI';
use vars qw($VERSION);

$VERSION = '0.08';

sub set_up_table {
    my ( $class, $table ) = @_;
    my $dbh     = $class->db_Main;
    my $catalog = "";
    if ( $class->pg_version >= 7.3 ) {
        $catalog = 'pg_catalog.';
    }

    # find primary key
    my $sth = $dbh->prepare(<<"SQL");
SELECT indkey FROM ${catalog}pg_index
WHERE indisprimary=true AND indrelid=(
SELECT oid FROM ${catalog}pg_class
WHERE relname = ?)
SQL
    $sth->execute($table);
    my %prinum = map { $_ => 1 } split ' ', $sth->fetchrow_array;
    $sth->finish;

    # find all columns
    $sth = $dbh->prepare(<<"SQL");
SELECT a.attname, a.attnum
FROM ${catalog}pg_class c, ${catalog}pg_attribute a
WHERE c.relname = ?
  AND a.attnum > 0 AND a.attrelid = c.oid
ORDER BY a.attnum
SQL
    $sth->execute($table);
    my $columns = $sth->fetchall_arrayref;
    $sth->finish;

    # find SERIAL type.
    # nextval('"table_id_seq"'::text)
    $sth = $dbh->prepare(<<"SQL");
SELECT adsrc FROM ${catalog}pg_attrdef 
WHERE 
adrelid=(SELECT oid FROM ${catalog}pg_class WHERE relname=?)
SQL
    $sth->execute($table);
    my ($nextval_str) = $sth->fetchrow_array;
    $sth->finish;

    # the text representation for nextval() changed between 7.x and 8.x
    my $sequence;
    if ($nextval_str) {
        if ($class->pg_version() >= 8.1) {
            # hackish, but oh well...
            ($sequence) = 
                $nextval_str =~ m!^nextval\('"?([^"']+)"?'::regclass\)!i ?
                    $1 :
                $nextval_str =~ m!^nextval\(\("?([^"']+)"?'::text\)?::regclass\)!i ?
                    $1 :
                undef;
        } else {
            ($sequence) = $nextval_str =~ m!^nextval\('"?([^"']+)"?'::text\)!;
        }
    }

    my ( @cols, @primary );
    foreach my $col (@$columns) {
        # skip dropped column.
        next if $col->[0] =~ /^\.+pg\.dropped\.\d+\.+$/;
        push @cols, $col->[0];
        next unless $prinum{ $col->[1] };
        push @primary, $col->[0];
    }
    if (!@primary) {
        require Carp;
        Carp::croak("$table has no primary key");
    }
    $class->table($table);
    $class->columns( Primary => @primary );
    $class->columns( All     => @cols );
    $class->sequence($sequence) if $sequence;
}

sub pg_version {
    my $class = shift;
    my %args  = @_;

    my $dbh   = $class->db_Main;
    my $sth   = $dbh->prepare("SELECT version()");
    $sth->execute;
    my ($ver_str) = $sth->fetchrow_array;
    $sth->finish;
    my ($ver) = 
        $args{full_version} ?
            $ver_str =~ m/^PostgreSQL ([\d\.]{5})/ :
            $ver_str =~ m/^PostgreSQL ([\d\.]{3})/;
    return $ver;
}

__END__

=head1 NAME

Class::DBI::Pg - Class::DBI extension for Postgres

=head1 SYNOPSIS

  use strict;
  use base qw(Class::DBI::Pg);

  __PACKAGE__->set_db(Main => 'dbi:Pg:dbname=dbname', 'user', 'password');
  __PACKAGE__->set_up_table('film');

=head1 DESCRIPTION

Class::DBI::Pg automate the setup of Class::DBI columns and primary key
for Postgres.

select Postgres system catalog and find out all columns, primary key and
SERIAL type column.

create table.

 CREATE TABLE cd (
     id SERIAL NOT NULL PRIMARY KEY,
     title TEXT,
     artist TEXT,
     release_date DATE
 );

setup your class.

 package CD;
 use strict;
 use base qw(Class::DBI::Pg);

 __PACKAGE__->set_db(Main => 'dbi:Pg:dbname=db', 'user', 'password');
 __PACKAGE__->set_up_table('cd');
 
This is almost the same as the following way.

 package CD;

 use strict;
 use base qw(Class::DBI);

 __PACKAGE__->set_db(Main => 'dbi:Pg:dbname=db', 'user', 'password');
 __PACKAGE__->table('cd');
 __PACKAGE__->columns(Primary => 'id');
 __PACKAGE__->columns(All => qw(id title artist release_date));
 __PACKAGE__->sequence('cd_id_seq');

=head1 METHODS

=head2 set_up_table TABLENAME

Declares the Class::DBI class specified by TABLENAME

=head2 pg_version

Returns the postgres version that you are currently using.

=head1 AUTHOR

Daisuke Maki C<dmaki@cpan.org>

=head1 AUTHOR EMERITUS

Sebastian Riedel, C<sri@oook.de>
IKEBE Tomohiro, C<ikebe@edge.co.jp>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI> L<Class::DBI::mysql> L<DBD::Pg>

=cut

1;
