package DBI::Mock;

use strict;
use warnings;

use Carp qw(carp confess);

sub _set_isa
{
    my ( $classes, $topclass ) = @_;
    foreach my $suffix ( '::db', '::st' )
    {
        my $previous = $topclass || 'DBI';    # trees are rooted here
        foreach my $class (@$classes)
        {
            my $base_class    = $previous . $suffix;
            my $sub_class     = $class . $suffix;
            my $sub_class_isa = "${sub_class}::ISA";
            no strict 'refs';
            @$sub_class_isa or @$sub_class_isa = ($base_class);
            $previous = $class;
        }
    }
}

sub _make_root_class
{
    my ( $ref, $root ) = @_;
    $root or return;

    (my $c = ref $ref) =~ s/::dr$//g;

    no strict 'refs';
    eval qq{
	package $c;
	require $root;
    };
    $@ and return;

    unless ( @{"$root\::db::ISA"} && @{"$root\::st::ISA"} )
    {
        carp("DBI subclasses '$root\::db' and ::st are not setup, RootClass ignored");
    }
    else
    {
        _set_isa( [$root], 'DBI::Mock' );
    }

    return;
}

my %default_attrs = (
                      Warn                => 1,
                      Active              => 1,
                      Executed            => 0,         # set on execute ...
                      Kids                => 0,
                      ActiveKids          => 0,
                      CachedKids          => 0,
                      Type                => "db",
                      ChildHandles        => undef,     # XXX improve to fake :/
                      CompatMode          => 0,
                      InactiveDestroy     => 0,
                      AutoInactiveDestroy => 0,
                      PrintWarn           => $^W,
                      PrintError          => 1,
                      RaiseError          => 0,
                      HandleError         => undef,     # XXX no default specified
                      HandleSetErr        => undef,     # XXX no default specified
                      ErrCount            => 0,
                      ShowErrorStatement  => undef,     # XXX no default specified
                      TraceLevel          => 0,         # XXX no default specified
                      FetchHashKeyName    => "NAME",    # XXX no default specified
                      ChopBlanks          => undef,     # XXX no default specified
                      LongReadLen         => 0,
                      LongTruncOk         => 0,
                      TaintIn             => 0,
                      TaintOut            => 0,
                      Taint               => 0,
                      Profile             => undef,     # XXX no default specified
                      ReadOnly            => 1,
                      Callbacks           => undef,
                    );

sub _make_handle
{
    my ( $ref, $name ) = @_;
    my $h = bless( { %default_attrs, %$ref }, $name );
    return $h;
}

my %drivers;

sub _get_drv
{
    my ( $self, $dsn, $attrs ) = @_;
    my $class = "DBI::dr";    # XXX maybe extract it from DSN? ...
    defined $drivers{$class} or $drivers{$class} = _make_handle( $attrs, $class );
    return $drivers{$class};
}

sub connect
{
    my ( $self, $dsn, $user, $pass, $attrs ) = @_;
    my $drh = $self->_get_drv( $dsn, $attrs );
    $drh->connect( $dsn, $user, $pass, $attrs );
}

sub installed_drivers { %drivers; }
sub available_drivers { 'NullP' }

our $stderr = 1;
our $err;
our $errstr;

sub err    { $err }
sub errstr { $errstr }

sub set_err
{
    my ( $ref, $_err, $_errstr ) = @_;
    $_err or do {
	$err = undef;
	$errstr = '';
	return;
    };
    $err    = $_err;
    $errstr = $_errstr;
    Test::More::diag("Raise: ", $ref->{RaiseError});
    $ref->{RaiseError} and $errstr and Carp::croak($errstr);
    Test::More::diag("Print: ", $ref->{PrintError});
    $ref->{PrintError} and $errstr and Carp::carp($errstr);
    return;
}

{
    package    #
      DBI::Mock::dr;

    our @ISA;

    my %default_db_attrs = (
                             AutoCommit   => 1,
                             Driver       => undef,    # set to the driver itself ...
                             Name         => "",
                             Statement    => "",
                             RowCacheSize => 0,
                             Username     => "",
                           );

    sub connect
    {
        my ( $drh, $dbname, $user, $auth, $attrs ) = @_;
	exists $drh->{RootClass}
	  and DBI::Mock::_make_root_class( $drh, $drh->{RootClass} );
	my $class = $drh->{RootClass} ? $drh->{RootClass} . "::db" : "DBI::db";
        my $dbh = DBI::Mock::_make_handle(
                                   {
                                      %default_db_attrs,
                                      %$attrs,
				      drh => $drh
                                   },
                                   $class
                                 );

	return $dbh;
    }

    our $err;
    our $errstr;

    sub err    { $err }
    sub errstr { $errstr }

    sub set_err
    {
        my ( $ref, $_err, $_errstr ) = @_;
	$_err or do {
	    $err = undef;
	    $errstr = '';
	    return;
	};
        $err    = $_err;
        $errstr = $_errstr;
	$ref->{RaiseError} and $errstr and Carp::croak($errstr);
	$ref->{PrintError} and $errstr and Carp::carp($errstr);
        return;
    }

    sub FETCH
    {
        my ( $dbh, $attr ) = @_;
        return $dbh->{$attr};
    }

    sub STORE
    {
        my ( $dbh, $attr, $val ) = @_;
        return $dbh->{$attr} = $val;
    }
}
{
    package    #
      DBI::Mock::db;

    our @ISA;

    my %default_st_attrs = (
                             NUM_OF_FIELDS => undef,
                             NUM_OF_PARAMS => undef,
                             NAME          => undef,
                             NAME_lc       => undef,
                             NAME_uc       => undef,
                             NAME_hash     => undef,
                             NAME_lc_hash  => undef,
                             NAME_uc_hash  => undef,
                             TYPE          => undef,
                             PRECISION     => undef,
                             SCALE         => undef,
                             NULLABLE      => undef,
                             CursorName    => undef,
                             Database      => undef,
                             Statement     => undef,
                             ParamValues   => undef,
                             ParamTypes    => undef,
                             ParamArrays   => undef,
                             RowsInCache   => undef,
                           );

    sub _valid_stmt
    {
        1;
    }

    sub disconnect
    {
        $_[0]->STORE( Active => 0 );
        return 1;
    }

    sub prepare
    {
        my ( $dbh, $stmt, $attrs ) = @_;
        _valid_stmt( $stmt, $attrs ) or return;    # error already set by _valid_stmt
        defined $attrs or $attrs = {};
        ref $attrs eq "HASH" or $attrs = {};
	my $class = $dbh->{drh}->{RootClass} ? $dbh->{drh}->{RootClass} . "::st" : "DBI::st";
        my $sth = DBI::Mock::_make_handle(
                                   {
                                      %default_st_attrs,
                                      %$attrs,
                                      Statement => $stmt,
                                      dbh => $dbh,
                                   },
                                  $class
                                 );

	return $sth;
    }

    # I don't had a clue how to implement that better
    # finally - they are reduce to the max and don't interfer with anything around ...

    sub do
    {
        my ( $dbh, $statement, $attr, @params ) = @_;
        my $sth = $dbh->prepare( $statement, $attr ) or return undef;
        $sth->execute(@params) or return $dbh->set_err( $sth->err, $sth->errstr );
        my $rows = $sth->rows;
        ( $rows == 0 ) ? "0E0" : $rows;
    }

    sub _do_selectrow
    {
        my ( $method, $dbh, $stmt, $attr, @bind ) = @_;
        my $sth = ( ( ref $stmt ) ? $stmt : $dbh->prepare( $stmt, $attr ) )
          or return;
        $sth->execute(@bind)
          or return;
        my $row = $sth->$method()
          and $sth->finish;
        return $row;
    }

    sub selectrow_hashref { return _do_selectrow( 'fetchrow_hashref', @_ ); }

    sub selectrow_arrayref { return _do_selectrow( 'fetchrow_arrayref', @_ ); }

    sub selectrow_array
    {
        my $row = _do_selectrow( 'fetchrow_arrayref', @_ ) or return;
        return $row->[0] unless wantarray;
        return @$row;
    }

    sub selectall_arrayref
    {
        my ( $dbh, $stmt, $attr, @bind ) = @_;
        my $sth = ( ref $stmt ) ? $stmt : $dbh->prepare( $stmt, $attr )
          or return;
        $sth->execute(@bind) || return;
        my $slice = $attr->{Slice};    # typically undef, else hash or array ref
        if ( !$slice and $slice = $attr->{Columns} )
        {
            if ( ref $slice eq 'ARRAY' )
            {                          # map col idx to perl array idx
                $slice = [ @{ $attr->{Columns} } ];    # take a copy
                for (@$slice) { $_-- }
            }
        }
        my $rows = $sth->fetchall_arrayref( $slice, my $MaxRows = $attr->{MaxRows} );
        $sth->finish if defined $MaxRows;
        return $rows;
    }

    sub selectall_hashref
    {
        my ( $dbh, $stmt, $key_field, $attr, @bind ) = @_;
        my $sth = ( ref $stmt ) ? $stmt : $dbh->prepare( $stmt, $attr );
        return unless $sth;
        $sth->execute(@bind) || return;
        return $sth->fetchall_hashref($key_field);
    }

    sub selectcol_arrayref
    {
        my ( $dbh, $stmt, $attr, @bind ) = @_;
        my $sth = ( ref $stmt ) ? $stmt : $dbh->prepare( $stmt, $attr );
        return unless $sth;
        $sth->execute(@bind) || return;
        my @columns = ( $attr->{Columns} ) ? @{ $attr->{Columns} } : (1);
        my @values  = (undef) x @columns;
        my $idx     = 0;
        for (@columns)
        {
            $sth->bind_col( $_, \$values[ $idx++ ] ) || return;
        }
        my @col;
        if ( my $max = $attr->{MaxRows} )
        {
            push @col, @values while 0 < $max-- && $sth->fetch;
        }
        else
        {
            push @col, @values while $sth->fetch;
        }
        return \@col;
    }

    our $err;
    our $errstr;

    sub err    { $err }
    sub errstr { $errstr }

    sub set_err
    {
        my ( $ref, $_err, $_errstr ) = @_;
	$_err or do {
	    $err = undef;
	    $errstr = '';
	    return;
	};
        $err    = $_err;
        $errstr = $_errstr;
	defined $errstr or Carp::croak("Undefined \$errstr");
	$ref->{RaiseError} and $errstr and Carp::croak($errstr);
	Test::More::diag("Print: ", $ref->{PrintError});
	$ref->{PrintError} and $errstr and Carp::carp($errstr);
        return;
    }

    sub FETCH
    {
        my ( $dbh, $attr ) = @_;
        return $dbh->{$attr};
    }

    sub STORE
    {
        my ( $dbh, $attr, $val ) = @_;
        return $dbh->{$attr} = $val;
    }
}

{
    package    #
      DBI::Mock::st;

    our @ISA;

    my %default_attrs = ();

    sub execute
    {
        "0E0";
    }

    our $err;
    our $errstr;

    sub err    { $err }
    sub errstr { $errstr }

    sub set_err
    {
        my ( $ref, $_err, $_errstr ) = @_;
	$_err or do {
	    $err = undef;
	    $errstr = '';
	    return;
	};
        $err    = $_err;
        $errstr = $_errstr;
	defined $errstr or Carp::croak("Undefined \$errstr");
	$ref->{RaiseError} and $errstr and Carp::croak($errstr);
	Test::More::diag("Print: ", $ref->{PrintError});
	$ref->{PrintError} and $errstr and Carp::carp($errstr);
    }

    sub bind_col
    {
        my ( $h, $col, $value_ref, $from_bind_columns ) = @_;
        my $fbav = $h->{'_fbav'} ||= dbih_setup_fbav($h);    # from _get_fbav()
        my $num_of_fields = @$fbav;
        Carp::croak("bind_col: column $col is not a valid column (1..$num_of_fields)")
          if $col < 1
          or $col > $num_of_fields;
        return 1 if not defined $value_ref;                  # ie caller is just trying to set TYPE
        Carp::croak("bind_col($col,$value_ref) needs a reference to a scalar")
          unless ref $value_ref eq 'SCALAR';
        $h->{'_bound_cols'}->[ $col - 1 ] = $value_ref;
        return 1;
    }

    sub FETCH
    {
        my ( $dbh, $attr ) = @_;
        return $dbh->{$attr};
    }

    sub STORE
    {
        my ( $dbh, $attr, $val ) = @_;
        return $dbh->{$attr} = $val;
    }
}

sub _inject_mock_dbi
{
    eval qq{
	package #
	    DBI;

	our \@ISA = qw(DBI::Mock);

	our \$VERSION = "1.625";

	package #
	    DBI::dr;

	our \@ISA = qw(DBI::Mock::dr);

	package #
	    DBI::db;

	our \@ISA = qw(DBI::Mock::db);

	package #
	    DBI::st;

	our \@ISA = qw(DBI::Mock::st);

	1;
    };
    $@ and die $@;
    $INC{'DBI.pm'} = 'mocked';
}

my $_have_dbi;

sub _miss_dbi
{
    defined $_have_dbi and return !$_have_dbi;
    $_have_dbi = 0;
    eval qq{
	\$ENV{DBI_PUREPERL} = 2; # we only want to know if it's there ...
	require DBI;
	\$_have_dbi = 1;
    };
    return !($_have_dbi = exists $INC{'DBI.pm'}); # XXX maybe riba can help to unload ...
}

BEGIN
{
    if ( $ENV{DBI_MOCK} || _miss_dbi() )
    {
        _inject_mock_dbi();
    }
}

1;

=head1 NAME

DBI::Mock - mock a DBI if we can't find the real one

=head1 SYNOPSIS

  use DBI::Mock;

  my $dbh = DBI::Mock->connect($data_source, $user, $pass, \%attr) or die $DBI::Mock::errstr;
  my $sth = $dbh->prepare();
  $sth->execute();

  ... copy some from DBI SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

This module is a team-effort. The current team members are

  H.Merijn Brand   (Tux)
  Jens Rehsack     (Sno)
  Peter Rabbitson  (ribasushi)
  Joakim TE<0x00f8>rmoen   (trmjoa)

=head1 COPYRIGHT AND LICENSE

Copyright (C)2013 - The DBI development team

You may distribute this module under the terms of either the GNU
General Public License or the Artistic License, as specified in
the Perl README file.

=cut
