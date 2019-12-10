package DBIx::NamedParams;

use 5.008001;
use strict;
use warnings;
use utf8;
use Encode;
use Carp qw( croak );
use parent qw( DBI );
use DBI::Const::GetInfoType;
use Log::Dispatch;
use POSIX qw( strftime );
use Term::Encoding qw( term_encoding );

use version 0.77; our $VERSION = version->declare("v0.0.8");

our $KeepBindingIfNoKey = 0;

my $_default_log_filename = $ENV{'HOME'} || $ENV{'USERPROFILE'};
$_default_log_filename =~ s#\\#/#g;
$_default_log_filename .= '/DBIx-NamedParams.log';

my %_SQL_TypeRefs = ();
my %_SQL_TypeInvs = ();
my $_SQL_Types    = '';
my @_NamedParams  = ();
my $_index;
my $_log = undef;

sub import {
    DBI->import();
    *{DBI::db::driver_typename_map} = \&driver_typename_map;
    *{DBI::db::prepare_ex}          = \&prepare_ex;
    *{DBI::st::bind_param_ex}       = \&bind_param_ex;
    _init();
}

sub _init {
    foreach ( @{ $DBI::EXPORT_TAGS{sql_types} } ) {
        my $refFunc = \&{"DBI::$_"};
        if (/^SQL_(.*)$/i) {
            $_SQL_TypeRefs{$1} = &{$refFunc};
            $_SQL_TypeInvs{ &{$refFunc} } = $1;
        }
    }
    $_SQL_Types = all_sql_types();
}

sub _thisFuncName {
    ( caller(1) )[3] =~ /([^:]+)$/;
    return $1;
}

sub debug_log {
    my $filename = shift || $_default_log_filename;
    $_log = Log::Dispatch->new(
        outputs => [
            [   'File',
                min_level   => 'debug',
                filename    => encode( term_encoding, $filename ),
                binmode     => ":utf8",
                permissions => 0666,
                newline     => 1,
            ],
        ],
    );
    $_log->info( _thisFuncName(), strftime( "%Y-%m-%d %H:%M:%S", localtime ) );
}

sub all_sql_types {
    return wantarray
        ? sort( keys(%_SQL_TypeRefs) )
        : join( "|", sort( keys(%_SQL_TypeRefs) ) );
}

sub driver_typename_map {
    my $self = shift;
    my %map  = map {
        my $datatype = $_->{'SQL_DATA_TYPE'}    # MS SQL Server
            || $_->{'SQL_DATATYPE'}             # MySQL
            || $_->{'DATA_TYPE'};               # SQLite
        ( $_->{'TYPE_NAME'} || '' ) => $_SQL_TypeInvs{$datatype} || 'WVARCHAR';
    } $self->type_info();
    if ( $self->get_info( $GetInfoType{'SQL_DBMS_NAME'} ) eq 'Microsoft SQL Server' ) {
        $map{'datetime'}      = 'WVARCHAR';
        $map{'smalldatetime'} = 'WVARCHAR';
    }
    return %map;
}

sub prepare_ex {
    my ( $self, $sqlex, $refHash ) = @_;
    my $ret       = undef;
    my $validHash = defined($refHash) && ref($refHash) eq 'HASH';
    if ( $sqlex =~ /\:([\w]+)\+-($_SQL_Types)\b/ ) {
        if ($validHash) {
            $sqlex =~ s/\:([\w]+)\+-($_SQL_Types)\b/_parse_ex1($refHash,$1,$2);/ge;
        } else {
            croak("prepare_ex need a hash reference when SQL is variable length.");
        }
    }
    @_NamedParams = ();
    $_index       = 1;
    $sqlex =~ s/\:([\w]+)(?:\{(\d+)\})?-($_SQL_Types)\b/_parse_ex2($1,$2,$3);/ge;
    if ($_log) {
        $_log->info( _thisFuncName(), 'sql_raw', "{{$sqlex}}" );
    }
    $ret = $self->prepare($sqlex) or croak($DBI::errstr);
    if ($validHash) {
        $ret->bind_param_ex($refHash);
    }
    return $ret;
}

sub _parse_ex1 {
    my ( $refHash, $name, $type ) = @_;
    my $numOfArray = scalar( @{ $refHash->{$name} } );
    return ":${name}{${numOfArray}}-${type}";
}

sub _parse_ex2 {
    my $name   = shift || '';
    my $repeat = shift || 0;
    my $type   = shift || '';
    my $ret    = '';

    if ($_log) {
        $_log->info( _thisFuncName(), "[$_index]", "\"$name\"",
            ( !$repeat ) ? "scalar" : "array[$repeat]", $type );
    }
    if ( !$repeat ) {    # scalar
        $_NamedParams[ $_index++ ] = {
            Name  => $name,
            Type  => $_SQL_TypeRefs{$type},
            Array => -1,
        };
        $ret = '?';
    } else {             # array
        for ( my $i = 0; $i < $repeat; ++$i ) {
            $_NamedParams[ $_index++ ] = {
                Name  => $name,
                Type  => $_SQL_TypeRefs{$type},
                Array => $i,
            };
        }
        $ret = substr( '?,' x $repeat, 0, -1 );
    }
    return $ret;
}

sub bind_param_ex {
    no warnings 'uninitialized';
    my ( $self, $refHash ) = @_;
    if ( !defined($refHash) || ref($refHash) ne 'HASH' ) {
        croak("bind_param_ex need a hash reference.");
    }
    my $thisFunc = _thisFuncName();
    for ( my $i = 1; $i < @_NamedParams; ++$i ) {
        my $param = $_NamedParams[$i];
        if ( $KeepBindingIfNoKey && !exists( $refHash->{ $param->{'Name'} } ) ) {
            next;
        }
        my $idx    = $param->{'Array'};
        my $value1 = $refHash->{ $param->{'Name'} };
        my $value2
            = ( $idx < 0 || ref($value1) ne 'ARRAY' )
            ? $value1
            : $value1->[$idx];
        my $datatype = $param->{'Type'};
        if ($_log) {
            $_log->info( $thisFunc, "[$i]", "\"$value2\"", $_SQL_TypeInvs{$datatype} );
        }
        $self->bind_param( $i, $value2, { TYPE => $datatype } )
            or croak($DBI::errstr);
    }
    return $self;
}

1;
__END__

=encoding utf-8

=head1 NAME

DBIx::NamedParams - use named parameters instead of '?'

=head1 SYNOPSIS

This module allows you to use named parameters as the placeholders instead of '?'.

    use DBIx::NamedParams;

    # Connect DB
    my $dbh = DBI->connect( ... ) or die($DBI::errstr);

    # Bind scalar
    # :<Name>-<Type>
    my $sql_insert = qq{
        INSERT INTO `Users` ( `Name`, `Status` ) VALUES ( :Name-VARCHAR, :State-INTEGER );
    };
    my $sth_insert = $dbh->prepare_ex( $sql_insert ) or die($DBI::errstr);
    $sth_insert->bind_param_ex( { 'Name' => 'Rio', 'State' => 1, } ) or die($DBI::errstr);
    my $rv = $sth_insert->execute() or die($DBI::errstr);

    # Bind fixed array
    # :<Name>{Number}-<Type>
    my $sql_select1 = qq{
        SELECT `ID`, `Name`, `Status`
        FROM `Users`
        WHERE `Status` in ( :State{4}-INTEGER );
    };
    my $sth_select1 = $dbh->prepare_ex( $sql_select1 ) or die($DBI::errstr);
    $sth_select1->bind_param_ex( { 'State' => [ 1,2,4,8 ], } ) or die($DBI::errstr);
    my $rv = $sth_select1->execute() or die($DBI::errstr);

    # Bind variable array
    # :<Name>+-<Type>
    my $sql_select2 = qq{
        SELECT `ID`, `Name`, `Status`
        FROM `Users`
        WHERE `Status` in ( :State+-INTEGER );
    };
    my $sth_select2 = $dbh->prepare_ex( $sql_select2, { 'State' => [ 1,2,4,8 ], } ) 
        or die($DBI::errstr);
    my $rv = $sth_select2->execute() or die($DBI::errstr);

=head1 DESCRIPTION

DBIx::NamedParams helps binding SQL parameters.

=head1 FLAGS

=head2 $DBIx::NamedParams::KeepBindingIfNoKey

In C<bind_param_ex()>, this flag controls the behavior when the hash reference doesn't have the key 
in the SQL statement.

Defaults to false. The placeholders according to the missing keys are set to C<undef>. 
All of the placeholders have to be set at once.

Setting this to a true value, the placeholders according to the missing keys are kept. 
You can set some placeholders at first, and set other placeholders later.
If you want to set a placeholder to null, you have to set C<undef> explicitly.

=head1 METHODS

=head2 DBIx::NamedParams Class Methods

=head3 all_sql_types

Returns the all SQL data types defined in L<DBI> .

    my @types = DBIx::NamedParams::all_sql_types();

=head3 debug_log

Writes the parsed SQL statement and the values at the parameter positions into the log file.
When omitting the filename, creates the log file in the home directory.

    DBIx::NamedParams::debug_log( '/tmp/testNamedParams.log' );

=head2 Database Handle Methods

=head3 driver_typename_map

Returns the hash from the driver type names to the DBI typenames.

    my %map = $dbh->driver_typename_map();

=head3 prepare_ex

Prepares a statement for later execution by the database engine and returns a reference to a statement handle object.
When the SQL statement has the variable array C<:E<lt>NameE<gt>+-E<lt>TypeE<gt>>, the hash reference as the second argument is mandatory.
When the SQL statement doesn't have the variable array C<:E<lt>NameE<gt>+-E<lt>TypeE<gt>>, the hash reference as the second argument is optional.

    my $sth = $dbh->prepare_ex( $statement, $hashref ) or die($DBI::errstr);

=head2 Database Handle Methods

=head3 bind_param_ex

Binds each parameters at once according to the hash reference.
The hash reference should have the keys that are same names to the parameter names in the SQL statement.
When the hash reference doesn't have the key that is same to the parameter name, the parameter is not set. 

    $sth->bind_param_ex( $hashref ) or die($DBI::errstr);

=head1 SEE ALSO

=head2 Similar modules

L<Tao::DBI>

L<DBIx::NamedBinding>

=head2 DBD informations

L<SQLite Keywords|https://www.sqlite.org/lang_keywords.html> explains how to quote the identifier.

=head1 LICENSE

Copyright (C) TakeAsh.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

L<TakeAsh|https://github.com/TakeAsh/>

=cut

