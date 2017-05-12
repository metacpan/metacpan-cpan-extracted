package DBQuery;

# $Id: DBQuery.pm,v 1.2.0-0 2014/12/28 12:02:21 Cnangel Exp $

use DBI;

$DBQuery::VERSION = "1.20";

sub new
{
    my $class = shift;
    my $DB = shift;
    my $self;
    if (defined $DB->{dsn})
    {
        $self = {
            'dsn' => $DB->{dsn},
            'user' => $DB->{db_user},
            'pass' => (defined $DB->{db_pass} ? $DB->{db_pass} : ''),
            'dbh' => undef,
            'sth' => undef,
        };
    }
    else
    {
        $DB->{driver_name} = 'mysql' unless (defined $DB->{driver_name});
        $DB->{driver_name} = ucfirst($DB->{driver_name}) if ($DB->{driver_name} eq "oracle");
        $self = {
            'driver' => $DB->{driver_name},
            'dsn' => $DB->{driver_name} eq 'mysql'
                ? 'dbi:' . $DB->{driver_name} . ':database=' . $DB->{db_name} .
                (defined $DB->{db_host} ? ';host=' . $DB->{db_host} : '') .
                (defined $DB->{db_sock} ? ';mysql_socket=' . $DB->{db_sock} : ';mysql_socket=/var/lib/mysql/mysql.sock') . 
                (defined $DB->{db_port} ? ';port=' . $DB->{db_port} : ';port=3306') 
                : ($DB->{driver_name} eq 'pgsql' 
                        ? 'dbi:' . $DB->{driver_name} . ':dbname=' . $DB->{db_name} . '' . 
                        (defined $DB->{db_host} ? ';host=' . $DB->{db_host} : '') . 
                        (defined $DB->{db_path} ? ';path=' . $DB->{db_path} : '') .
                        (defined $DB->{db_port} ? ';port=' . $DB->{db_port} : ';port=5432')
                        : ($DB->{driver_name} eq 'Oracle'
                            ? 'dbi:' . $DB->{driver_name} . 
                            (defined $DB->{db_host} ? ':host=' . $DB->{db_host} : ':host=localhost') . 
                            (defined $DB->{db_port} ? ';port=' . $DB->{db_port} : '') .
                            (defined $DB->{db_sid} ? ';sid=' . $DB->{db_sid} : '') .
                            (defined $DB->{db_name} && !defined $DB->{db_sid} ? ';sid=' . $DB->{db_name} : '')
                            : 'dbi:' . $DB->{driver_name} . (defined $DB->{db_host} ? ':' . $DB->{db_host} : '')
                          )
                  ),
            'user' => $DB->{db_user},
            'pass' => (defined $DB->{db_pass} ? $DB->{db_pass} : ''),
            'pconnect' => $DB->{db_pconnect},
            'utf8' => $DB->{db_enable_utf8},
            'autocommit' => (defined $DB->{db_autocommit} ? $DB->{db_autocommit} : 1),
            'LongReadLen' => $DB->{db_longreadlen},
            'LongTruncOk' => $DB->{db_longtruncok},
            'dbh' => undef,
            'sth' => undef,
        };
    }
    bless $self, $class;
    return $self;
}

sub connect
{
    my $self = shift;
    if ($_[0] && $self->{driver} eq 'mysql') {
        $self->{dbh} = DBI->connect($self->{dsn}, $self->{user}, $self->{pass}, {'RaiseError' => 1, 'mysql_enable_utf8' => 1});
    } else {
        $self->{dbh} = DBI->connect($self->{dsn}, $self->{user}, $self->{pass}, {'RaiseError' => 1});
    }

    if ($self->{driver} eq 'mysql') {
        $self->{dbh}->{mysql_auto_reconnect} = $self->{pconnect} ? 1 : 0;
        $self->{dbh}->{mysql_enable_utf8} = $self->{utf8} ? 1 : 0;
        $self->{dbh}->{mysql_no_autocommit_cmd} = $self->{autocommit} ? 0 : 1;
    } elsif ($self->{driver} eq 'Oracle') {
        $self->{dbh}->{LongReadLen} = $self->{LongReadLen};
        $self->{dbh}->{LongTruncOk} = $self->{LongTruncOk};
    }
    return;
}

sub query
{
    my $self = shift;
    $self->{sth} = $self->{dbh}->prepare($_[0]);
    $self->{sth}->execute();
    return $self->{sth};
}

sub quote
{
    my $self = shift;
    return $self->{dbh}->quote($_[0]);
}

sub insert_id
{
    my $self = shift;
    return $self->{dbh}->{'mysql_insertid'};
}

sub fetch_array
{
    my $self = shift;
    return ref($_[0]) eq 'DBI::st' ? $_[0]->fetchrow_array() : $self->{sth}->fetchrow_array();
}

sub fetch_arrayref
{
    my $self = shift;
    return ref($_[0]) eq 'DBI::st' ? $_[0]->fetchrow_arrayref() : $self->{sth}->fetchrow_arrayref();
}

sub fetch_hash
{
    my $self = shift;
    return ref($_[0]) eq 'DBI::st' ? $_[0]->fetchrow_hashref() : $self->{sth}->fetchrow_hashref();
}

sub close
{
    my $self = shift;
    $self->{sth}->finish() if (defined $self->{sth});
    $self->{dbh}->disconnect if (defined $self->{dbh});
    return;
}

1;

__END__

=head1 NAME

DBQuery - Lib of DB Query

=head1 SYNOPSIS

The following lib are provided:

=over

=item B<import>

use DBQuery;

=item B<Struct Init>

Init mysql struct example:

    my %DB = (
        'db_host'            => 'web10.search.cnb.yahoo.com',
        'db_user'            => 'yahoo',
        'db_pass'            => 'yahoo',
        'db_name'            => 'ADCode',
        'db_port'            => 3306,
        'db_pconnect'            => 1,
        'db_autocommit'            => 1,
        'db_enable_utf8'        => 0,
        );
    my $db = new DBQuery(\%DB);

or postgresql:

    my %PQ = (
        'driver_name'        => 'PgPP',
        'db_host'        => 'tool2.search.cnb.yahoo.com',
        'db_name'        => 'cnedb',
        'db_user'        => 'cnedb',
        'db_pass'        => 'cnedb',
        );
    my $db = new DBQuery(\%PQ);

or oracle:

    my %OC = (
        'driver_name'            => 'oracle',
        'db_host'            => 'ocndb',
        'db_user'            => 'alibaba',
        'db_pass'            => 'ocndb',
        'db_port'            => 1521,
        'db_name'            => 'ctutest', // the same as db_sid
        'db_longreadlen'        => 33554432,
        'db_longtruncok'        => 1,
        );
    my $db = new DBQuery(\%OC);

over this, you can use dsn for init structure.

    my %DB = (
        'dsn'        => 'dbi:mysql:database=testinter;host=localhost;mysql_socket=/var/lib/mysql/mysql.sock;mysql_use_result=1',
        'db_user'       => 'pca',
        'db_pass'       => 'pca',
        );
    my $db = new DBQuery(\%DB);

it yet run.

=item B<Connect>

Connect resource from database.

    $db->connect();

You can unset the variable: %DB, %PQ or $OC, like this:

    undef %PQ;

or 

    undef %DB;

or

    undef %OC;


=item B<Query>

Simple query:

    $db->query("select url from edb.white_black_grey where spamtype=':demote2:' limit 10;");
    while (my @row = $db->fetch_array())
    {
        print Dumper @row, "\n";
    }

    $db->query("alter session set nls_date_format = 'yyyy-mm-dd hh24:mi:ss'");

Common:

    my $query = $db->query("select url from edb.white_black_grey where spamtype=':demote2:' limit 10;");
    while (my @row = $db->fetch_array($query))
    {
        print Dumper @row, "\n";
    }

=item B<Disconnect>

Release resource from database.

    $db->close();

=back

=head1 OPTIONS

Nothing because of no script.

=head1 DESCRIPTION

C<DBQuery> allows you to query some information from some different type databases, like mysql, postgresql and oracle, so our system need module which include L<DBD::mysql>, L<DBD::PgPP> and L<DBD::Oracle>.

In future, it'll support more and more database types if you want. You can use C<DBQuery> very expediently. so we use database easily.

B<This lib> can use dsn which contains all connection information or use all single items, like db_host, db_pass etc.

=head2 $self->new()

Construct.

=head2  $self->connect()

Create a connect.

=head2  $self->close()

Close this connection.

=head2 $self->query()

Send a query.

=head2 $self->fetch_array()

Fetch and return array.

=head2 $self->fetch_arrayref()

Fetch and return reference of array.

=head2 $self->fetch_hash()

Fetch and return reference of hash.

=head2 $self->quote()

Quote some characters.

=head2 $self->insert_id()

Return last insert id.

=head1 TIPS

There's some extra tips found in our own's everyday use:

=over

=item B<CUSTOM>

Like php-mysql

   $db->connect();
   $db->query();
   $db->fetch_array();

=item B<ABSTRACT>

One line description of the module. Will be included in PPD file.

=item B<ABSTRACT_FROM>

Name of the file that contains the package description. MakeMaker looks
for a line in the POD matching /^($package\s-\s)(.*)/. This is typically
the first line in the "=head1 NAME" section. $2 becomes the abstract.

=back

=head1 PREREQUISITES

This module uses L<DBI>.

=head1 INSTALLATION

If you are not sudoer or root, you need contact administrator.

    perl Makefile.PL
    make
    make test
    make install

Win32 users should replace "make" with "nmake".

=head1 SOURCE CONTROL

You can always get the latest SSH::Batch source from its
public Git repository:

    http://github.com/cnangel/DB/tree/master

If you have a branch for me to pull, please let me know ;)

=head1 TODO

To this:

=over

=item *

Sqlite2 and sqlite3 will be supported.

=item *

New engine for DBQuery.

=back

=head1 SEE ALSO

L<DBI>, L<DBD::mysql>, L<DBD::PgPP>, L<DBD::Oracle>

=head1 COPYRIGHT AND LICENSE

This module as well as its programs are licensed under the BSD License.

Copyright (c) 2007-2008, Yahoo! China Relevance Team, Alibaba Inc. All rights reserved.

Copyright (c) 2009, Alibaba Search Center, Alibaba Inc. All rights reserved.

Copyright (C) 2009, Cnangel Li (cnangel). All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

=over

=item *

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

=item *

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

=item *

Neither the name of the Alibaba Search Center, Alibaba Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

=back

=head1 AUTHOR 

B<Cnangel> (I<cnangel@gmail.com>)

=head1 HISTORY

see ChangeLog.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

