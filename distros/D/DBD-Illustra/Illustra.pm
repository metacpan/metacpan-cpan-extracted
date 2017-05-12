################################################################################
#
#   File name: Illustra.pm
#   Project: DBD::Illustra
#   Description: Perl-level DBI driver
#
#   Author: Peter Haworth
#   Date created: 17/07/1998
#
#   sccs version: 1.16    last changed: 10/13/99
#
#   Copyright (c) 1998 Institute of Physics Publishing
#   You may distribute under the terms of the Artistic License,
#   as distributed with Perl, with the exception that it cannot be placed
#   on a CD-ROM or similar media for commercial distribution without the
#   prior approval of the author.
#
################################################################################

use 5.004;
use strict;

{
  package DBD::Illustra;

  use DBI 1.0 ();
  use DynaLoader();
  use Exporter();
  use vars qw(
    $VERSION @ISA
    $err $errstr $sqlstate
    $drh
  );

  $VERSION='0.04';
  @ISA=qw(DynaLoader Exporter);
  bootstrap DBD::Illustra $VERSION;

  $err=0;		# holds error code for DBI::err
  $errstr='';		# holds error string for DBI::errstr
  $sqlstate='';		# hold SQL state for DBI::state
  undef $drh;		# holds driver handler once initialised

  # ->driver(\%attr)
  # Driver constructor
  sub driver{
    return $drh if $drh;
    my($class,$attr)=@_;

    $class.='::dr';

    $drh=DBI::_new_drh($class,{
      Name => 'Illustra',
      Version => $VERSION,
      Err => \$err,
      Errstr => \$errstr,
      State => \$sqlstate,
      Attribution => 'DBD::Illustra by Peter Haworth',
    });

    $drh;
  }
}

{
  package DBD::Illustra::dr; # ======= DRIVER ======
  use Symbol;

  # ->connect($dbname,$user,$auth)
  # Database handler constructor
  sub connect{
    my($drh,$dbname,$user,$auth)=@_;

    # Create 'blank' dbh
    my $dbh=DBI::_new_dbh($drh,{
      Name => $dbname,
      USER => $user,
      CURRENT_USER => $user,
#      Pass => $auth,
    });

    # Call XS function to connect to database
    DBD::Illustra::db::_login($dbh,$dbname,$user,$auth)
      or return;

    $dbh;
  }

  my %dbnames; # Holds list of available databases
  sub load_dbnames{
    my($drh)=@_;
    my($fh,$dir)=(Symbol::gensym,Symbol::gensym);

    foreach my $fname (
      exists $ENV{MI_SYSPARAMS} ? ($ENV{MI_SYSPARAMS}) : (),
      exists $ENV{MI_HOME} ? ("$ENV{MI_HOME}/MiParams") : (),
    ){
      next unless defined $fname;
      next unless open($fh,"< $fname\0");

      while(<$fh>){
	my($key,$value)=split;
	next unless defined($key) && defined($value);
	next unless $key eq 'MI_DATADIR' && $value ne '';
        next unless opendir($dir,"$value/data/base");

	while(defined(my $f=readdir $dir)){
	  (my($db)=$f=~/^(\w+)_\w+\.\w+$/) && -d "$value/data/base/$f"
	    or next;

	  ++$dbnames{$db};
	}
	closedir $dir;
      }
      close $fh;
    }
  }

  sub data_sources{
    my($drh)=@_;

    load_dbnames($drh) unless %dbnames;

    map { "dbi:Illustra:$_" } sort keys %dbnames;
  }
}

{
  package DBD::Illustra::db; # ====== DATABASE ======

  # ->prepare($statement,@attribs)
  # Statement handler constructor
  sub prepare{
    my($dbh,$statement,@attribs)=@_;

    # Make sure the statement has a terminating semicolon
    $statement=~s/\s+$//s;
    $statement=~s/([^;])$/$1;/s;

    # Create a 'blank' sth
    my $sth=DBI::_new_sth($dbh,{
      Statement => $statement,
    });

    DBD::Illustra::st::_prepare($sth,$statement,@attribs)
      or return undef;

    $sth;
  }

  # ->ping
  sub ping{
    my($dbh)=@_;

    # Use eval to prevent RaiseError from killing the caller
    eval{
      local $SIG{__DIE__};
      local $SIG{__WARN__}=sub{};

      my $sth=$dbh->prepare('return 1')
	or return 0;
      $sth->execute
	or return 0;
      $sth->finish
	or return 0;
    };
    return 1;
  }

  # ->table_info
  # Return statement handle to get available table info
  sub table_info{
    my($dbh)=@_;

    my $sth=$dbh->prepare(q(
      select
	null::text TABLE_QUALIFIER,
	table_owner TABLE_OWNER,
	table_name TABLE_NAME,
	'TABLE' TABLE_TYPE,
	null::text REMARKS
      from tables
      where not table_issystem
	and table_kind<>'i'
    )) or return undef;

    $sth->execute or return undef;
    $sth;
  }

  # ->type_info_all
  # Return information about types returned by $sth->{TYPE}
  my @type_info=(
    {
      TYPE_NAME => 0,
      DATA_TYPE => 1,
      COLUMN_SIZE => 2,
      CREATE_PARAMS => 3,
      NULLABLE => 4,
      CASE_SENSITIVE => 5,
      SEARCHABLE => 6,
      FIXED_PREC_SCALE => 7,
      MINIMUM_SCALE => 8,
      MAXIMUM_SCALE => 9,
      NUM_PREC_RADIX => 10,
    },
    [varchar => DBI::SQL_VARCHAR,undef,'max length',1,1,3,0,1,255,undef],
    [vchar => DBI::SQL_VARCHAR,undef,'max length',1,1,3,0,1,255,undef],
    [char => DBI::SQL_CHAR,undef,'max length',1,1,3,0,1,255,undef],
    [character => DBI::SQL_CHAR,undef,'max length',1,1,3,0,1,255,undef],
    [numeric => DBI::SQL_NUMERIC,undef,'precision,scale',1,0,2,0,0,10],
    [decimal => DBI::SQL_DECIMAL,undef,'precision,scale',1,0,2,0,0,10],
    [int => DBI::SQL_INTEGER,32,undef,1,0,2,1,32,32,2],
    [integer => DBI::SQL_INTEGER,32,undef,1,0,2,1,32,32,2],
    [smallint => DBI::SQL_INTEGER,16,undef,1,0,2,1,16,16,2],
    [int1 => DBI::SQL_INTEGER,8,undef,1,0,2,1,8,8,2],
    [real => DBI::SQL_REAL,undef,undef,1,0,2,1,undef,undef,10],
    ['double precision' => DBI::SQL_REAL,undef,undef,1,0,2,1,undef,undef,10],
    # XXX [date => DBI::SQL_DATE, ???],
    # XXX [time => DBI::SQL_TIME, ???],
    # XXX [timestamp => DBI::SQL_TIMESTAMP, ???],
    # XXX [abstime => DBI::SQL_TIMESTAMP, ???],
  );
  sub type_info_all{
    return \@type_info;
  }
}

{
  package DBD::Illustra::st; # ====== STATEMENT ======

}


# Return true to require
1;

__END__


=head1 NAME

DBD::Illustra - DBI driver for Illustra Databases

=head1 DESCRIPTION

This document describes DBD::Illustra version 0.04.

You should also read the documentation for DBI as this document only contains
information specific to DBD::Illustra.

=head1 USE OF DBD::Illustra

=head2 Loading DBD::Illustra

To use the DBD::Illustra software, you need to load the DBI software.

    use DBI;

Under normal circumstances, you should then connect to your database using the
notation in the section "CONNECTING TO A DATABASE" which calls DBI->connect().

You can find out which databases are available using the function:

    @dbnames=DBI->data_sources('Illustra');

Note that you may be able to connect to other databases not returned by this
method. Also some databases returned by this method may be unavailable due
to access rights or other reasons.

=head2 CONNECTING TO A DATABASE

    $dbh = DBI->connect("dbi:Illustra:$database",$user,$pass);
    $dbh = DBI->connect("dbi:Illustra:$database",$user,$pass,\%attr);

The $database part of the first argument specifies the name of the database
to connect to. Currently, only databases served by the default server may
be connected.

=head2 DISCONNECTING FROM A DATABASE

You can also disconnect from the database:

    $dbh->disconnect;

This will rollback any uncommitted work. Note that this does not destroy
the database handle. Any statements prepared using this handle are finished
and cannot be used again.

=head2 LARGE OBJECTS

Illustra supports values known as large objects, which may be larger than
a database page, and are stored as separate files outside the database.
DBD::Illustra provides support for reading large objects through the
non-DBI C<read_large_object> method.
Illustra will not allow large objects to be read while a
query is active, and also doesn't provide enough information for the driver
to determine which columns returned contain large objects. This means that
the user of DBD::Illustra must go through more work to read large objects.
When a large object column is selected from, instead of returning the contents
of the column, Illustra returns a "large object handle," which may be used to
retrieve the contents of the large object, once the query is finished:

    $sth=$dbh->prepare('some query returning large objects');
    $sth->execute;
    my($lohandle)=$sth->fetchrow_array;
    # Query MUST be finished for this to work
    $sth->finish;

    # Read large object
    $offset=0;
    $blob='';
    while(defined($frag=$dbh->func($lohandle,$offset,4096,'read_large_object'))){
      $len=length $flag or last;
      $blob.=$frag;
      $offset+=$len;
    }

Due to the limitations in the Illustra API, it is not
possible to support reading large objects from each row, as they are fetched.
This means that future versions of DBD::Illustra will never be able to
transparently return large objects with normal column data. However, you can
cast large object values to large_text, in which case they will be returned
as normal values.

=head1 AUTHOR

Peter Haworth (pmh@edison.ioppublishing.com)

=head1 SEE ALSO

L<DBI>

=cut
