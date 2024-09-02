package DBIx::Fast;

=head1 NAME
 
DBIx::Fast - DBI fast & easy (another one...)
   
=cut

our $VERSION = '0.11';

use strict;
use warnings FATAL => 'all';

=head1 SYNOPSIS
 
use DBIx::Fast;

$DB = DBIx::Fast->new( dsn => 'dbi:MariaDB:database=test:host' , user => 'test' , passwd => 'test');
$DB = DBIx::Fast->new( db => 'test', user => 'test', passwd => 'test', driver => 'MariaDB' );
$DB = DBIx::Fast->new( db => 'test', user => 'test', passwd => 'test', driver => 'mysql', trace => '1' , profile => '!Statement:!MethodName' );

say $DB->last_error;
Dumper $DB->errors;

$DB->all('SELECT * FROM test WHERE 1');

$Results = $DB->results;
$Results = $DB->all('SELECT * FROM test WHERE expire > ?',$time);

$Hash = $DB->hash('SELECT * FROM test WHERE id = ?',$id);
$Hash = $DB->results;

$Value = $DB->val('SELECT name FROM test WHERE id = ?',1);

$DB->insert('table', { name => 'New Name', status  => 1 }, time => 'create_time');

$DB->update('table', { sen => { name => 'update t3st' }, where => { id => 1 } });
$DB->update('table', { sen => { name => 'update t3st' }, where => { id => 1 } }, time => 'mod_time');

$DB->up('table, { name => 'Update Name' } , { id => 1 } );
$DB->up('table, { name => 'Update Name' } , { id => 1 } , time => 'mod_time');

say $DB->last_sql;
say $DB->last_id;

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=cut

use Carp;
use Moo;

use DBI;
use DBIx::Connector;
use SQL::Abstract;

=head2 SQL::Abstract
=cut
has SQL => ( is => 'rw' );

=head2 db
 Database
=cut
has db  => ( is => 'rw' );

=head2 dbd
 Database type
=cut
has dbd => ( is => 'rwp');

=head2 errors
 Array with all errors
=cut
has errors   => ( is => 'rwp');

=head2 last_error
 String with the last error
=cut
has last_error => ( is => 'rwp' );

=head2 last_sql
 Return last SQL sentence
=cut
has last_sql => ( is => 'rw');

=head2 last_id
 Return last insert id
=cut
has last_id  => ( is => 'rw');

=head2 sql
 SQL stmt
=cut
has sql => ( is => 'rw' );

=head2 p
=cut
has p   => ( is => 'rw' );

=head2 results
 Last fetch results
=cut
has results  => ( is => 'rw');

=head2 dsn
=cut
has dsn => ( is => 'rwp' );

=head2 dbi_args
=cut
has dbi_args => ( is => 'rwp' );

=head2 _build_sql
=cut

=head2 now
  NOW() - Timestamp
=cut
sub now {
    my $self = shift;

    my ($sec, $min, $hour, $mday, $mon , $year) = localtime;

    return sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year + 1900, $mon + 1, $mday, $hour, $min, $sec);
}

=head2 set_error
    Add error to the array
=cut
sub set_error {
    my $self = shift;
    
    my $error = {
	id    => shift,
	error => shift,
	time  => time()
    };

    my $Errors = $self->errors;
    push @{$Errors} ,$error;

    $self->_set_last_error(qq{$error->{time} - [$error->{id}] - $error->{error}});
    $self->_set_errors($Errors);
}

=head2 BUILD
    Build Moo
=cut
sub BUILD {
    my ($self,$args) = @_;
    my $DConf;

    $args->{host} = '127.0.0.1' unless $args->{host};

    $DConf->{args} = {
	RaiseError => $args->{Error} // 1,
	PrintError => $args->{PrintError} // 1,
	AutoCommit => $args->{AutoCommit} // 1,
    };

    $DConf->{quote} = $args->{quote} if $args->{quote};
    
    $self->_set_dsn($args->{dsn} ? $self->_check_dsn($args->{dsn}) : $self->_make_dsn($args));
    $self->_set_dbi_args($DConf);
    
    if ( $self->dbd eq 'mysql' ) {
	$DConf->{args}->{mysql_enable_utf8} = 1 if $args->{mysql_enable_utf8};
    }
    
    $self->_set_dbi_args($DConf);

    $self->SQL(SQL::Abstract->new);
    $self->db(DBIx::Connector->new( $self->dsn, 
				    $args->{user}, $args->{passwd},
				    $self->dbi_args->{args} ));

    $self->db->mode('ping');
    
    $self->db->dbh->quote($self->dbi_args->{quote}) if $self->dbi_args->{quote};
    
    $self->db->dbh->{HandleError} = sub {
	$self->set_error($DBI::err,$DBI::errstr);
    };

    $self->db->dbh->trace($args->{trace},'dbix-fast-trace') if $args->{trace};

    $self->_profile($args->{profile}) if $args->{profile};
}

=head2 _Driver_dbd
=cut
sub _Driver_dbd {
    my $self = shift;
    my $dbd  = shift;
    
    map { $self->_set_dbd($_) if lc($dbd) eq lc($_) } qw(SQLite Pg MariaDB mysql);

    $self->Exception("Error DBD Driver : $dbd") unless $self->dbd;
}

=head2 check_dsn
    Check DSN string
=cut
sub _check_dsn {
    my $self = shift;
    my $dsn  = shift;

    my ($dbi,$driver,$db,$host) = split ':', $dsn;
    
    $self->_Driver_dbd($driver);

    return $dsn;
}

=head2 make_dsn
    Make DSN string
=cut
sub _make_dsn {
    my $self = shift;
    my $args = shift;

    $self->Exception("DBD Driver : Not defined") unless $args->{driver};

    $self->_Driver_dbd($args->{driver});

    return 'dbi:SQLite:dbname='.$args->{db} if $args->{driver} eq 'SQLite';
    
    return 'dbi:'.$self->dbd.':database='.$args->{db}.':'.$args->{host};
}

=head2 profile
    Save profile log : dbix-fast--PID.log
=cut
sub _profile {
    my $self = shift;
    my $stat = shift."/DBI::ProfileDumper/";

    $stat .= qq{File:dbix-fast-$$.log};

    $self->db->dbh->{Profile} = $stat;
}

=head2 all
    Execute a SQL sentence and return all data in arrayref
=cut
sub all {
    my $self = shift;

    $self->q(@_);

    my $res = $self->db->dbh->selectall_arrayref($self->sql,
						 { Slice => {} },@{$self->p});

    $self->Exception("ERROR all()") if $DBI::err;
    
    $self->results($res);
}

=head2 hash
    Execute a SQL sentence and return one hash
=cut
sub hash {
    my $self = shift;

    $self->q(@_);

    my $sth = $self->db->dbh->prepare($self->sql);

    $sth->execute(@{$self->p});

    my $res = $sth->fetchrow_hashref;

    $self->Exception("hash()") if $DBI::err;
    
    $self->results($res);
}

=head2 val
    Return one value
=cut
sub val {
    my $self = shift;

    $self->q(@_);

    return $self->db->dbh->selectrow_array($self->sql, undef, @{$self->p});
}

=head2 array
    Execute a SQL sentence and return array
=cut
sub array {
    my $self = shift;

    $self->q(@_);

    my $sth = $self->db->dbh->prepare($self->sql);

    $sth->execute(@{$self->p});

    $self->Exception("array()") if $DBI::err;

    my @rows = @{ $self->db->dbh->selectcol_arrayref( $self->sql, undef, @{ $self->p } ) };
    
    $self->results(\@rows);
}

=head2 count
    Return count from a table
=cut
sub count {
    my $self  = shift;
    my $table = $self->TableName(shift);
    my $skeel = shift;

    $self->sql("SELECT COUNT(*) FROM $table");

    return $self->db->dbh->selectrow_array($self->sql) 
	unless $skeel;
    
    $self->_make_where($skeel);

    return $self->db->dbh->selectrow_array($self->sql, undef, @{$self->p});
}

=head2 make_where

=cut
sub _make_where {
    my $self  = shift;
    my $skeel = shift;
    my @p;

    my $sql = " WHERE ";

    for my $K ( keys %{$skeel} ) {
	my $key;

	if ( ref $skeel->{$K} eq 'HASH' ) {
	    $key = (keys %{$skeel->{$K}})[0];
	    push @p,$skeel->{$K}->{$key};
	} else {
	    $key = '=';
	    push @p,$skeel->{$K};
	}

	$sql .= qq{$K $key ? };
    }

    $sql =~ s/,$//;

    $self->sql($self->sql.$sql);
    $self->p(\@p);
}

=head2 execute
    Execute SQL
=cut
sub execute {
    my $self = shift;
    my $sql  = shift;
    my $extra = shift;
    my $type  = shift // 'arrayref';
    my $res;

    $self->sql($sql);

    ## Extra Arguments
    $self->make_sen($extra) if $extra;

    if ( $type eq 'hash' ) {
	my $sth = $self->db->dbh->prepare($self->sql);
	if ( $self->p ) {
	    $sth->execute(@{$self->p});
	} else {
	    $sth->execute;
	}
	$res = $sth->fetchrow_hashref;
    } else {
	if ($self->p ) {
	    $res = $self->db->dbh->selectall_arrayref($self->sql,
						      { Slice => {} },@{$self->p});
	} else {
	    $res = $self->db->dbh->selectall_arrayref($self->sql,
						      { Slice => {} } );
	}
    }

    $self->Exception("execute()") if $DBI::err;
    
    $self->results($res);
}

=head2 up
    Update statment : up( table , data , where )
=cut
sub up {
    my ($self,$table,$data,$where,$time) = @_;

    if ( $time ) {
	$self->update( $self->TableName($table) , { sen => $data , where => $where } , time => $time );
    } else {
	$self->update( $self->TableName($table) , { sen => $data , where => $where } );
    }
}

=head2 update
        $d->update('test', {
                           sen   => { uid => 1 , name => 'mrtest' ,status => 1 },
                           where => { id => 33 },
        }, time => 'update_time');
=cut
sub update {
    my $self  = shift;
    my $table = $self->TableName(shift);
    my $skeel = shift;

    $skeel->{sen} = $self->extra_args($skeel->{sen},@_) if scalar @_ > 0;

    my @p;
    my $sql = "UPDATE $table SET ";

    for ( keys %{$skeel->{sen}} ) {
	push @p,$skeel->{sen}->{$_};
	$sql .= $_.' = ? ,';
    }

    $sql =~ s/,$//;
    $sql .= 'WHERE ';

    for my $K ( keys %{$skeel->{where}} ) {
	push @p,$skeel->{where}->{$K};
	$sql .= $K.' = ? ,';
    }

    $sql =~ s/,$//;

    $self->sql($sql);
    $self->execute_prepare(@p);
}

=head2 insert
        $d->insert('test',
           {
               name => 'tester',
               status => 0
           }, time => 'date' );
=cut
sub insert {
    my $self  = shift;
    my $table = $self->TableName(shift);
    my $skeel = shift;

    $skeel = $self->extra_args($skeel,@_) if scalar @_ > 0;

    my @p;

    my $sql= "INSERT INTO $table ( ";

    for ( keys %{$skeel} ) {
       push @p,$skeel->{$_};
       $sql .= $_.',';
    }

    $sql =~ s/,$/ )/;
    $sql .= ' VALUES ( '.join(',', ('?') x @p).' )';

    $self->sql($sql);
    $self->execute_prepare(@p);

    if ( $self->dbd eq 'MariaDB' ) {
	$self->last_id($self->db->dbh->{mariadb_insertid});
    } elsif ( $self->dbd eq 'mysql' ) {
	$self->last_id($self->db->dbh->{mysql_insertid});
    } elsif ( $self->dbd eq 'SQLite' ) {
	$self->last_id($self->db->dbh->sqlite_last_insert_rowid());
    } elsif ( $self->dbd eq 'Pg' ) {
	$self->last_id($self->db->dbh->last_insert_id(undef,undef,$table,undef));
    }
}

=head2 delete
   $d->delete('test', { id => $d->last_id });
   $d->delete('test', { id => 1 });
=cut
sub delete {
    my $self  = shift;
    my $table = $self->TableName(shift);
    my $skeel = shift;

    $self->sql("DELETE FROM $table");

    #unless ( $skeel ) {
    #    return $self->db->dbh->selectrow_array($self->sql);
    #}

    $self->_make_where($skeel);

    my $sth = $self->db->dbh->prepare($self->sql);
    
    $sth->execute(@{$self->p});
}

=head2 extra_args
    time : now time in mysql format
=cut
sub extra_args {
    my $self  = shift;
    my $skeel = shift;
    my %args  = @_;

    $skeel->{$args{time}} = $self->now() if $args{time};
    
    return $skeel;
}

=head2 make_sen
    FIXME : Hacer con execute_prepare
=cut
sub make_sen {
    my $self  = shift;
    my $skeel = shift;
    my $sql   = $self->sql();
    my @p;

    ## Ha de encontrar resultados por el orden de entrada parsear debidamente
    for ( keys %{$skeel} ) {
	my $arg = ':'.$_;
	push @p,$skeel->{$_};
	$sql =~ s/$arg/\?/;
    }

    $sql =~ s/,$//;

    $self->sql($sql);
    $self->p(\@p);
}

=head2
    Make query   
=cut
sub q {
    my $self = shift;
    my $sql  = shift;
    my @p;

    map { push @p,$_ } @_;

    $self->sql($sql);
    $self->p(\@p);
}

=head2
    Exute and prepare
=cut
sub execute_prepare {
    my $self = shift;
    my @p    = @_;

    my $sth = $self->db->dbh->prepare($self->sql);

    $sth->execute(@p);

    $self->last_sql($self->sql);
}

=head2
    Table name any character or _
=cut
sub TableName {
    my $self  = shift;
    my $table = shift;

    return $table unless $table =~ /\W/;

    $self->Exception("TableName not valid: $table");
}

=head2
    Excepcion
=cut
sub Exception {
    my $self = shift;
    my $msg  = shift;

    return unless $self->dbi_args->{args}->{PrintError};
    
    my $out  = "Exception: $msg - ";

    $out .= $self->last_error if $self->last_error;
    
    carp $out;
}

=head1 AUTHOR


=head1 BUGS

Please report any bugs or feature requests to C<bug-business-es-nif at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Fast>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Fast

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Fast>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Fast>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Fast>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Fast/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
