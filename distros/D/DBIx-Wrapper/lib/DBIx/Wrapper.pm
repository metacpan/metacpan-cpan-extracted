# -*-perl-*-
# Creation date: 2003-03-30 12:17:42
# Authors: Don
# Change log:
# $Revision: 2043 $
#
# Copyright (c) 2003-2012 Don Owens (don@regexguy.com)
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# This program is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.

# TODO:
#     $db->not(); e.g., $db->select_from_hash($table, { val => $db->not(undef) });
#     $db->in();  e.g., $db->update($table, { val => $db->in([ 4, 5, 6]) })
#
#     * Take care of error caused by using DBD-mysql-2.1026
#       - It either gives the wrong quote for quoting
#         identifiers, or doesn't allow identifiers to be quoted

=pod

=head1 NAME

DBIx::Wrapper - A wrapper around the DBI

=head1 SYNOPSIS

 use DBIx::Wrapper;
 
 my $db = DBIx::Wrapper->connect($dsn, $user, $auth, \%attr);
 
 my $db = DBIx::Wrapper->connect($dsn, $user, $auth, \%attr,
          { error_handler => sub { print $DBI::errstr },
            debug_handler => sub { print $DBI::errstr },
          });
 
 my $db = DBIx::Wrapper->connect_from_config($db_key, $config_file,
          { error_handler => sub { print $DBI::errstr },
            debug_handler => sub { print $DBI::errstr },
          });
          
 
 my $dbi_obj = DBI->connect(...)
 my $db = DBIx::Wrapper->newFromDBI($dbi_obj);
 
 my $dbi_obj = $db->getDBI;
 
 my $rv = $db->insert($table, { id => 5, val => "myval",
                                the_date => \"NOW()",
                              });
 my $rv = $db->insert($table, { id => 5, val => "myval",
                                the_date => $db->command("NOW()"),
                              });
 
 my $rv = $db->replace($table, \%data);
 my $rv = $db->smartReplace($table, \%data)
 my $rv = $db->delete($table, \%keys);
 my $rv = $db->update($table, \%keys, \%data);
 my $rv = $db->smartUpdate($table, \%keys, \%data);
 
 my $row = $db->selectFromHash($table, \%keys, \@cols);
 my $row = $db->selectFromHashMulti($table, \%keys, \@cols);
 my $val = $db->selectValueFromHash($table, \%keys, $col);
 my $vals = $db->selectValueFromHashMulti($table, \%keys, \@cols);
 my $rows = $db->selectAll($table, \@cols);
 
 my $row = $db->nativeSelect($query, \@exec_args);
 
 my $loop = $db->nativeSelectExecLoop($query);
 foreach my $val (@vals) {
     my $row = $loop->next([ $val ]);
 }
 
 my $row = $db->nativeSelectWithArrayRef($query, \@exec_args);
 
 my $rows = $db->nativeSelectMulti($query, \@exec_args);
 my $rows = $db->nativeSelectMultiOrOne($query, \@exec_args);
 
 my $loop = $db->nativeSelectMultiExecLoop($query)
 foreach my $val (@vals) {
     my $rows = $loop->next([ $val ]);
 }
 
 my $rows = $db->nativeSelectMultiWithArrayRef($query, \@exec_args);
 
 my $hash = $db->nativeSelectMapping($query, \@exec_args);
 my $hash = $db->nativeSelectDynaMapping($query, \@cols, \@exec_args);
 
 my $hash = $db->nativeSelectRecordMapping($query, \@exec_args);
 my $hash = $db->nativeSelectRecordDynaMapping($query, $col, \@exec_args);
 
 my $val = $db->nativeSelectValue($query, \@exec_args);
 my $vals = $db->nativeSelectValuesArray($query, \@exec_args);
 
 my $row = $db->abstractSelect($table, \@fields, \%where, \@order);
 my $rows = $db->abstractSelectMulti($table, \@fields, \%where, \@order);
 
 my $loop = $db->nativeSelectLoop($query, \@exec_args);
 while (my $row = $loop->next) {
     my $id = $$row{id};
 }
 
 my $rv = $db->nativeQuery($query, \@exec_args);
 
 my $loop = $db->nativeQueryLoop("UPDATE my_table SET value=? WHERE id=?");
 $loop->next([ 'one', 1]);
 $loop->next([ 'two', 2]);
 
 my $id = $db->getLastInsertId;
 
 $db->debugOn(\*FILE_HANDLE);
 
 $db->setNameArg($arg)
 
 $db->commit();
 $db->ping();
 $db->err();
 
 my $str = $db->to_csv($rows);
 my $xml = $db->to_xml($rows);
 my $bencoded = $db->bencode($rows);


=head2 Attributes

Attributes accessed in C<DBIx::Wrapper> object via hash access are
passed on or retrieved from the underlying DBI object, e.g.,

 $dbi_obj->{RaiseError} = 1

=head2 Named Placeholders

All native* methods (except for C<nativeSelectExecLoop()>) support
named placeholders.  That is, instead of using ? as a
placeholder, you can use :name, where name is the name of a key
in the hash passed to the method.  To use named placeholders,
pass a hash reference containing the values in place of the
C<@exec_args> argument.  E.g.,

 my $row = $db->nativeSelect("SELECT * FROM test_table WHERE id=:id", { id => 1 });

:: in the query string gets converted to : so you can include
literal colons in the query.  :"var name" and :'var name' are
also supported so you can use variable names containing spaces.

The implementation uses ? as placeholders under the hood so that
quoting is done properly.  So if your database driver does not
support placeholders, named placeholders will not help you.

=head1 DESCRIPTION

C<DBIx::Wrapper> provides a wrapper around the DBI that makes it a
bit easier on the programmer.  This module allows you to execute
a query with a single method call as well as make inserts easier,
etc.  It also supports running hooks at various stages of
processing a query (see the section on L</Hooks>).

=cut

# =over

# =item * tries to maintain database independence

# =item * inserts, updates, and deletes using native Perl datastructures

# =item * combines prepare, execute, fetch of DBIx::Wrapper into a single call

# =item * convenience methods such as to_csv, to_xml, to_bencode, etc.

# =back

=pod

=head1 METHODS

Following are C<DBIx::Wrapper> methods.  Any undocumented methods
should be considered private.

=cut

use strict;
use Data::Dumper ();

package DBIx::Wrapper;

use 5.006_00; # should have at least Perl 5.6.0

use warnings;
no warnings 'once';

use Carp ();

our $AUTOLOAD;
our $Heavy = 0;

our $VERSION = '0.29';      # update below in POD as well

use DBI;
use DBIx::Wrapper::Request;
use DBIx::Wrapper::SQLCommand;
use DBIx::Wrapper::Statement;
use DBIx::Wrapper::SelectLoop;
use DBIx::Wrapper::SelectExecLoop;
use DBIx::Wrapper::StatementLoop;
use DBIx::Wrapper::Delegator;
use DBIx::Wrapper::DBIDelegator;

my %i_data;
my $have_config_general;

# adapted from refaddr in Scalar::Util
sub refaddr($) {
    my $obj = shift;
    my $pkg = ref($obj) or return undef;
    
    bless $obj, 'DBIx::Wrapper::Fake';
    
    my $i = int($obj);
    
    bless $obj, $pkg;
    
    return $i;
}

# taken verbatim from Scalar::Util
sub reftype ($) {
  local($@, $SIG{__DIE__}, $SIG{__WARN__});
  my $r = shift;
  my $t;

  length($t = ref($r)) or return undef;

  # This eval will fail if the reference is not blessed
  eval { $r->a_sub_not_likely_to_be_here; 1 }
    ? do {
      $t = eval {
	  # we have a GLOB or an IO. Stringify a GLOB gives it's name
	  my $q = *$r;
	  $q =~ /^\*/ ? "GLOB" : "IO";
	}
	or do {
	  # OK, if we don't have a GLOB what parts of
	  # a glob will it populate.
	  # NOTE: A glob always has a SCALAR
	  local *glob = $r;
	  defined *glob{ARRAY} && "ARRAY"
	  or defined *glob{HASH} && "HASH"
	  or defined *glob{CODE} && "CODE"
	  or length(ref(${$r})) ? "REF" : "SCALAR";
	}
    }
    : $t
}

sub _new {
    my ($proto) = @_;
    my $self = bless {}, ref($proto) || $proto;
    $i_data{ refaddr($self) } = {};

    tie %$self, 'DBIx::Wrapper::DBIDelegator', $self;

    return $self;
}

sub _get_i_data {
    my $self = shift;
    return $i_data{ refaddr($self) };
}

sub _get_i_val {
    my $self = shift;
    
    return $self->_get_i_data()->{ shift() };
}

sub _set_i_val {
    my $self = shift;
    my $name = shift;
    my $val = shift;

    $self->_get_i_data()->{$name} = $val;
}

sub _delete_i_val {
    my $self = shift;
    my $name = shift;
    delete $self->_get_i_data()->{$name};
}

sub import {
    my $class = shift;

    foreach my $e (@_) {
        if ($e eq ':heavy') {
            $Heavy = 1;
        }
    }
}

=pod

=head2 C<connect($data_source, $username, $auth, \%attr, \%params)>

Connects to the given database.  The first four parameters are
the same parameters you would pass to the connect call when
using DBI directly.  If $data_source is a hash, it will generate
the dsn for DBI using the values for the keys driver, database,
host, port.

The C<%params> hash is optional and contains extra parameters to
control the behaviour of C<DBIx::Wrapper> itself.  Following are
the valid parameters.

=over 4

=item error_handler and debug_handler

These values should either be a reference to a subroutine, or a
reference to an array whose first element is an object and whose
second element is a method name to call on that object.  The
parameters passed to the error_handler callback are the current
C<DBIx::Wrapper> object and an error string, usually the query if
appropriate.  The parameters passed to the debug_handler
callback are the current C<DBIx::Wrapper> object, an error string,
and the filehandle passed to the C<debugOn()> method (defaults to
C<STDERR>).  E.g.,

  sub do_error {
      my ($db, $str) = @_;
      print $DBI::errstr;
  }
  sub do_debug {
      my ($db, $str, $fh) = @_;
      print $fh "query was: $str\n";
  }
 
  my $db = DBIx::Wrapper->connect($ds, $un, $auth, \%attr,
                                  { error_handler => \&do_error,
                                    debug_handler => \&do_debug,
                                  });


=item db_style

Used to control some database specific logic.  The default value
is 'mysql'.  Currently, this is only used for the
C<getLastInsertId()> method.  MSSQL is supported with a value of
mssql for this parameter.

=item heavy

If set to a true value, any hashes returned will actually be
objects on which you can call methods to get the values back.
E.g.,

  my $row = $db->nativeSelect($query);
  my $id = $row->id;
  # or
  my $id = $row->{id};

=item no_placeholders

If you are unfortunate enough to be using a database that does
not support placeholders, you can set no_placeholders to a true
value here.  For non native* methods that generate SQL on their
own, placeholders are normally used to ensure proper quoting of
values.  If you set no_placeholders to a true value, DBI's
C<quote()> method will be used to quote the values instead of using
placeholders.

=back

=head2 C<new($data_source, $username, $auth, \%attr, \%params)>

 An alias for connect().

=cut

sub connect {
    my ($proto, $data_source, $username, $auth, $attr, $params) = @_;
    my $self = $proto->_new;

    $self->_set_i_val('_pre_prepare_hooks', []);
    $self->_set_i_val('_post_prepare_hooks', []);
    $self->_set_i_val('_pre_exec_hooks', []);
    $self->_set_i_val('_post_exec_hooks', []);
    $self->_set_i_val('_pre_fetch_hooks', []);
    $self->_set_i_val('_post_fetch_hooks', []);


    my $dsn = $data_source;
    $dsn = $self->_getDsnFromHash($data_source) if ref($data_source) eq 'HASH';

    my $dbh = DBI->connect($dsn, $username, $auth, $attr);
    unless (ref($attr) eq 'HASH' and defined($$attr{PrintError}) and not $$attr{PrintError}) {
        # FIXME: make a way to set debug level here
        # $self->addDebugLevel(2); # print on error
    }
    unless ($dbh) {
        if ($self->_isDebugOn) {
            $self->_printDebug(Carp::longmess($DBI::errstr));
        } else {
            $self->_printDbiError
                if not defined($$attr{PrintError}) or $$attr{PrintError};
        }
        return undef;
    }

    $params = {} unless UNIVERSAL::isa($params, 'HASH');
        
    $self->_setDatabaseHandle($dbh);
    $self->_setDataSource($data_source);
    $self->_setDataSourceStr($dsn);
    $self->_setUsername($username);
    $self->_setAuth($auth);
    $self->_setAttr($attr);
    $self->_setDisconnect(1);

    $self->_setErrorHandler($params->{error_handler}) if $params->{error_handler};
    $self->_setDebugHandler($params->{debug_handler}) if $params->{debug_handler};
    $self->_setDbStyle($params->{db_style}) if CORE::exists($params->{db_style});
    $self->_setHeavy(1) if $params->{heavy};
    $self->_setNoPlaceholders($params->{no_placeholders}) if CORE::exists($params->{no_placeholders});
        
    my ($junk, $dbd_driver, @rest) = split /:/, $dsn;
    $self->_setDbdDriver(lc($dbd_driver));

    return $self;
}
{   no warnings;
    *new = \&connect;
}


=pod

=head2 C<connect_from_config($db_key, $config_file, \%params)>

Like C<connect()>, but the parameters used to connect are taken
from the given configuration file.  The L<Config::General> module
must be present for this method to work (it is loaded as
needed).  C<$config_file> should be the path to a configuration
file in an Apache-style format.  C<$db_key> is the name of the
container with the database connection information you wish to
use.  The C<%params> hash is optional and contains extra parameters
to control the behaviour of C<DBIx::Wrapper> itself.

Following is an example configuration file.  Note that the dsn
can be specified either as a container with each piece named
separately, or as an option whose value is the full dsn that
should be based to the underlying DBI object.  Each db container
specifies one database connection.  Note that, unlike Apache,
the containers and option names are case-sensitive.

=for pod2rst next-code-block: apache

    <db test_db_key>
        <dsn>
            driver mysql
            database test_db
            host example.com
            port 3306
        </dsn>
 
        user test_user
        password test_pwd
 
        <attributes>
            RaiseError 0
            PrintError 1
        </attributes>
    </db>
 
    <db test_db_key2>
        dsn "dbi:mysql:database=test_db;host=example.com;port=3306"
 
        user test_user
        password test_pwd
    </db>


Configuration features from L<Config::General> supported:

=over 4

=item * Perl style comments

=item * C-style comments

=item * Here-documents

=item * Apache style Include directive

=item * Variable interpolation (see docs for L<Config::General::Interpolated>)

=back

=cut
sub connect_from_config {
    my ($self, $db_key, $conf_path, $wrapper_attrs) = @_;

    my $config = $self->_read_config_file($conf_path);

    # FIXME: need to set $DBI::errstr here or something
    unless ($config) {
        return;
    }

    my $dbs = $config->{db};
    my $this_db = $dbs->{$db_key};

    # FIXME: need to set $DBI::errstr here or something
    unless ($this_db) {
        # $DBI::errstr = "no entry for database key $db_key in $conf_path";
        return;
    }

    my $dsn = $this_db->{dsn};
    my $user = $this_db->{user};
    my $pwd = $this_db->{password};

    if (ref($dsn) eq 'HASH') {
        my @keys = grep { $_ ne 'driver' } sort keys %$dsn;
        $dsn = "dbi:$dsn->{driver}:" . join(';', map { "$_=$dsn->{$_}" } @keys);
    }

    my $attr_container = $this_db->{attributes};
    my $attrs = {};
    if ($attr_container and UNIVERSAL::isa($attr_container, 'HASH')) {
        $attrs = { %$attr_container };
    }

    return DBIx::Wrapper->connect($dsn, $user, $pwd, $attrs, $wrapper_attrs);    
}

sub _read_config_file {
    my $self = shift;
    my $config_file = shift;

    unless ($self->_load_config_general) {
        warn "cannot load config file '$config_file' -- Config::General not present";
        return;
    }
    
    my $config_obj = Config::General->new(-ConfigFile => $config_file,
                                          # -LowerCaseNames => 1,
                                          -UseApacheInclude => 1,
                                          -IncludeRelative => 1,
                                          -MergeDuplicateBlocks => 1,
                                          -AllowMultiOptions => 'yes',
                                          -SplitPolicy => 'whitespace',
                                          -InterPolateVars => 1,
                                          # -SplitPolicy => 'guess',
                                         );

    unless ($config_obj) {
        return;
    }
    
    my %config = $config_obj->getall;
    return \%config;
}

sub _load_config_general {
    if (defined($have_config_general)) {
        return $have_config_general;
    }

    local($SIG{__DIE__});
    eval 'use Config::General';
    if ($@) {
        $have_config_general = 0;
    }
    else {
        $have_config_general = 1;
    }
}

=pod

=head2 C<reconnect()>

Reconnect to the database using the same parameters that were
given to the C<connect()> method.  It does not try to disconnect
before attempting to connect again.

=cut
sub reconnect {
    my $self = shift;

    my $dsn = $self->_getDataSourceStr;

    my $dbh = DBI->connect($dsn, $self->_getUsername, $self->_getAuth,
                           $self->_getAttr);
    if ($dbh) {
        $self->_setDatabaseHandle($dbh);
        return $self;
    } else {
        return undef;
    }
}

=pod

=head2 C<disconnect()>

Disconnect from the database.  This disconnects and frees up the
underlying C<DBI> object.

=cut
sub disconnect {
    my $self = shift;
    my $dbi_obj = $self->_getDatabaseHandle;
    $dbi_obj->disconnect if $dbi_obj;
    $self->_deleteDatabaseHandle;

    return 1;
}

=pod

=head2 C<connectOne(\@cfg_list, \%attr)>

Connects to a random database out of the list.  This is useful
for connecting to a slave database out of a group for read-only
access.  Ths list should look similar to the following:

    my $cfg_list = [ { driver => 'mysql',
                       host => 'db0.example.com',
                       port => 3306,
                       database => 'MyDB',
                       user => 'dbuser',
                       auth => 'dbpwd',
                       attr => { RaiseError => 1 },
                       weight => 1,
                     },
                     { driver => 'mysql',
                       host => 'db1.example.com',
                       port => 3306,
                       database => 'MyDB',
                       user => 'dbuser',
                       auth => 'dbpwd',
                       attr => { RaiseError => 1 },
                       weight => 2,
                     },
                   ];

where the weight fields are optional (defaulting to 1).  The
attr field is also optional and corresponds to the 4th argument
to DBI's C<connect()> method.  The C<\%attr> passed to this method is
an optional parameter specifying the defaults for C<\%attr> to be
passed to the C<connect()> method.  The attr field in the config
for each database in the list overrides any in the C<\%attr>
parameter passed into the method.

You may also pass the DSN string for the connect() method as the
'dsn' field in each config instead of the separate driver, host,
port, and database fields, e.g.,

    my $cfg_list = [ { dsn => 'dbi:mysql:host=db0.example.com;database=MyDB;port=3306',
                       user => 'dbuser',
                       auth => 'dbpwd',
                       attr => { RaiseError => 1 },
                       weight => 1,
                     },
                   ];

Aliases: connect_one

=cut
sub connect_one {
    my $proto = shift;
    my $cfg_list = shift;
    my $attr = shift || {};

    return undef unless $cfg_list and @$cfg_list;

    # make copy so we don't distrub the original datastructure
    $cfg_list = [ @$cfg_list ];

    my $db = 0;
    while (not $db and scalar(@$cfg_list) > 0) {
        my ($cfg, $index) = $proto->_pick_one($cfg_list);
        my $this_attr = $cfg->{attr} || {};
        $this_attr = { %$attr, %$this_attr };

        eval {
            local($SIG{__DIE__});
            $db = $proto->connect($cfg->{dsn} || $cfg, $cfg->{user}, $cfg->{auth}, $this_attr);
        };

        splice(@$cfg_list, $index, 1) unless $db;
    }

    return $db;
}
*connectOne = \&connect_one;

sub _pick_one {
    my $proto = shift;
    my $cfg_list = shift;
    return undef unless $cfg_list and @$cfg_list;

    $cfg_list = [ grep { not defined($_->{weight}) or $_->{weight} != 0 } @$cfg_list ];
    my $total_weight = 0;
    foreach my $cfg (@$cfg_list) {
        $total_weight += $cfg->{weight} || 1;
    }

    my $target = rand($total_weight);
        
    my $accumulated = 0;
    my $pick;
    my $index = 0;
    foreach my $cfg (@$cfg_list) {
        $accumulated += $cfg->{weight} || 1;
        if ($target < $accumulated) {
            $pick = $cfg;
            last;
        }
        $index++;
    }

    return wantarray ? ($pick, $index) : $pick;
}
    
sub _getDsnFromHash {
    my $self = shift;
    my $data_source = shift;
    my @dsn;
        
    push @dsn, "database=$$data_source{database}" if $data_source->{database};
    push @dsn, "host=$$data_source{host}" if $data_source->{host};
    push @dsn, "port=$$data_source{port}" if $data_source->{port};

    push @dsn, "mysql_connect_timeout=$$data_source{mysql_connect_timeout}"
        if $data_source->{mysql_connect_timeout};

    my $driver = $data_source->{driver} || $data_source->{type};

    if ($data_source->{timeout}) {
        if ($driver eq 'mysql') {
            push @dsn, "mysql_connect_timeout=$$data_source{timeout}";
        }
    }
        
    return "dbi:$driver:" . join(';', @dsn);
}

sub addDebugLevel {
    my $self = shift;
    my $level = shift;
    my $cur_level = $self->_get_i_val('_debug_level');
    $cur_level |= $level;
    $self->_set_i_val('_debug_level', $cur_level);
}

sub getDebugLevel {
    return shift()->_get_i_data('_debug_level');
}

=pod

=head2 C<newFromDBI($dbh)>

Returns a new DBIx::Wrapper object from a DBI object that has
already been created.  Note that when created this way,
disconnect() will not be called automatically on the underlying
DBI object when the DBIx::Wrapper object goes out of scope.

Aliases: new_from_dbi

=cut
sub newFromDBI {
    my ($proto, $dbh) = @_;
    return unless $dbh;
    my $self = $proto->_new;
    $self->_setDatabaseHandle($dbh);
    return $self;
}

*new_from_dbi = \&newFromDBI;

=pod

=head2 C<getDBI()>

Return the underlying DBI object used to query the database.

Aliases: get_dbi, getDbi

=cut
sub getDBI {
    my ($self) = @_;
    return $self->_getDatabaseHandle;
}

*get_dbi = \&getDBI;
*getDbi = \&getDBI;

sub _insert_replace {
    my ($self, $operation, $table, $data) = @_;

    my @values;
    my @fields;
    my @place_holders;

    my $dbh = $self->_getDatabaseHandle;

    while (my ($field, $value) = each %$data) {
        push @fields, $field;

        if (UNIVERSAL::isa($value, 'DBIx::Wrapper::SQLCommand')) {
            push @place_holders, $value->asString;
        } elsif (ref($value) eq 'SCALAR') {
            push @place_holders, $$value;
        } else {
            if ($self->_getNoPlaceholders) {
                if (defined($value)) {
                    push @place_holders, $dbh->quote($value);
                }
                else {
                    push @place_holders, 'NULL';
                }
            }
            else {
                push @place_holders, '?';
                push @values, $value;
            }
        }
    }

    my $fields = join(",", map { $self->_quote_field_name($_) } @fields);
    my $place_holders = join(",", @place_holders);
    my $sf_table = $self->_quote_table($table);
    my $query = qq{$operation INTO $sf_table ($fields) values ($place_holders)};
    my ($sth, $rv) = $self->_getStatementHandleForQuery($query, \@values);
    return $sth unless $sth;
    $sth->finish;

    return $rv;
}

# FIXME: finish
sub _insert_replace_multi {
    my ($self, $operation, $table, $data_rows) = @_;

    my @values;
    my @fields;
    my @all_place_holders;

    my $dbh = $self->_getDatabaseHandle;

    foreach my $data (@$data_rows) {
        my @these_fields;
        my @place_holders;

        foreach my $field (keys %$data) {
            my $value = $data->{$field};

            push @these_fields, $field;

            if (UNIVERSAL::isa($value, 'DBIx::Wrapper::SQLCommand')) {
                push @place_holders, $value->asString;
            } elsif (ref($value) eq 'SCALAR') {
                push @place_holders, $$value;
            } else {
                if ($self->_getNoPlaceholders) {
                    if (defined($value)) {
                        push @place_holders, $dbh->quote($value);
                    } else {
                        push @place_holders, 'NULL';
                    }
                } else {
                    push @place_holders, '?';
                    push @values, $value;
                }
            }
        }

        push @all_place_holders, \@place_holders;

        if (@fields) {
            # FIXME: check that number of fields is same as @these_fields
            unless (scalar(@fields) == scalar(@these_fields)) {
                
            }
        }
        else {
            @fields = @these_fields;
        }
    }

    my $fields = join(",", map { $self->_quote_field_name($_) } @fields);
    # my $place_holders = join(",", @place_holders);
    my $groups = join(',', map { '(' . join(",", @$_) . ')' } @all_place_holders);
    my $sf_table = $self->_quote_table($table);
    my $query = qq{$operation INTO $sf_table ($fields) values $groups};
    my ($sth, $rv) = $self->_getStatementHandleForQuery($query, \@values);
    return $sth unless $sth;
    $sth->finish;
        
    return $rv;
}

=pod

=head2 C<insert($table, \%data)>

Insert the provided row into the database.  $table is the name
of the table you want to insert into.  %data is the data you
want to insert -- a hash with key/value pairs representing a row
to be insert into the database.

=cut
sub insert {
    my ($self, $table, $data) = @_;
    return $self->_insert_replace('INSERT', $table, $data);
}

=pod

=head2 C<replace($table, \%data)>

Same as C<insert()>, except does a C<REPLACE> instead of an C<INSERT> for
databases which support it.

=cut
sub replace {
    my ($self, $table, $data) = @_;
    my $style = lc($self->_getDbStyle);
    if ($style eq 'mssql') {
        # mssql doesn't support replace, so do an insert instead
        return $self->_insert_replace('INSERT', $table, $data);
    } else {
        return $self->_insert_replace('REPLACE', $table, $data);
    }
}

=pod

=head2 C<smartReplace($table, \%data)>

This method is MySQL specific.  If $table has an auto_increment
column, the return value will be the value of the auto_increment
column.  So if that column was specified in C<\%data>, that value
will be returned, otherwise, an insert will be performed and the
value of C<LAST_INSERT_ID()> will be returned.  If there is no
auto_increment column, but primary keys are provided, the row
containing the primary keys will be returned.  Otherwise, a true
value will be returned upon success.

Aliases: smart_replace

=cut
sub smartReplace {
    my ($self, $table, $data, $keys) = @_;

    if (0 and $keys) {
        # ignore $keys for now
            
    } else {
        my $dbh = $self->_getDatabaseHandle;
        my $query = qq{DESCRIBE $table};
        my $sth = $self->_getStatementHandleForQuery($query);
        return $sth unless $sth;
        my $auto_incr = undef;
        my $key_list = [];
        my $info_list = [];
        while (my $info = $sth->fetchrow_hashref('NAME_lc')) {
            push @$info_list, $info;
            push @$key_list, $$info{field} if lc($$info{key}) eq 'pri';
            if ($$info{extra} =~ /auto_increment/i) {
                $auto_incr = $$info{field};
            }
        }

        my $orig_auto_incr = $auto_incr;
        $auto_incr = lc($auto_incr);
        my $keys_provided = [];
        my $key_hash = { map { (lc($_) => 1) } @$key_list };
        my $auto_incr_provided = 0;
        foreach my $key (keys %$data) {
            push @$keys_provided, $key if CORE::exists($$key_hash{lc($key)});
            if (lc($key) eq $auto_incr) {
                $auto_incr_provided = 1;
                last;
            }
        }

        if (@$keys_provided) {
            # do replace and return the value of this field
            my $rv = $self->replace($table, $data);
            return $rv unless $rv;
            if (not defined($orig_auto_incr) or $orig_auto_incr eq '') {
                my %hash = map { ($_ => $$data{$_}) } @$keys_provided;
                my $row = $self->selectFromHash($table, \%hash);
                return $row if $row and %$row;
                return undef;
            } else {
                return $$data{$orig_auto_incr};
            }
        } else {
            # do insert and return last insert id
            my $rv = $self->insert($table, $data);
            return $rv unless $rv;
            if (not defined($orig_auto_incr) or $orig_auto_incr eq '') {
                # FIXME: what do we do here?
                return 1;
            } else {
                my $id = $self->getLastInsertId(undef, undef, $table, $orig_auto_incr);
                return $id;
            }
        }
    }
}

*smart_replace = \&smartReplace;

=pod

=head2 C<delete($table, \%keys), delete($table, \@keys)>

Delete rows from table C<$table> using the key/value pairs in C<%keys>
to specify the C<WHERE> clause of the query.  Multiple key/value
pairs are joined with C<AND> in the C<WHERE> clause.  The C<cols>
parameter can optionally be an array ref instead of a hashref.
E.g.

     $db->delete($table, [ key1 => $val1, key2 => $val2 ])

This is so that the order of the parameters in the C<WHERE> clause
are kept in the same order.  This is required to use the correct
multi field indexes in some databases.

=cut
sub delete {
    my ($self, $table, $keys) = @_;

    unless ($keys and (UNIVERSAL::isa($keys, 'HASH') or UNIVERSAL::isa($keys, 'ARRAY'))) {
        return $self->setErr(-1, 'DBIx::Wrapper: No keys passed to update()');
    }

    my @keys;
    my @values;
    if (ref($keys) eq 'ARRAY') {
        # allow this to maintain order in the WHERE clause in
        # order to use the right indexes
        my @copy = @$keys;
        while (my $key = shift @copy) {
            push @keys, $key;
            my $val = shift @copy; # shift off the value
        }
        $keys = { @$keys };
    } else {
        @keys = keys %$keys;
    }

    my $sf_table = $self->_quote_table($table);

    my @where;
    my $dbh = $self->_getDatabaseHandle;
    foreach my $key (@keys) {
        my $sf_key = $self->_quote_field_name($key);
        my $val = $keys->{$key};

        if ($self->_getNoPlaceholders) {
            if (defined($val)) {
                push @where, "$sf_key=" . $dbh->quote($val);
            }
            else {
                push @where, "$sf_key IS NULL";
            }
        }
        else {
            if (defined($val)) {
                push @where, "$sf_key=?";
                push @values, $val;
            }
            else {
                push @where, "$sf_key IS NULL";
            }
        }
    }
    
    # my $where = join(" AND ", map { "$_=?" } map { $self->_quote_field_name($_) } @keys);
    
    my $where = join(" AND ", @where);
    my $query = qq{DELETE FROM $sf_table WHERE $where};

    my ($sth, $rv) = $self->_getStatementHandleForQuery($query, \@values);
    return $sth unless $sth;
    $sth->finish;
        
    return $rv;
}

sub _get_quote_chars {
    my $self = shift;
    my $quote_cache = $self->_get_i_val('_quote_cache');
    unless ($quote_cache) {
        my $dbi = $self->_getDatabaseHandle;
        $quote_cache = [ $dbi->get_info(29) || '"', # identifier quot char
                         $dbi->get_info(41) || '.', # catalog name separator
                         $dbi->get_info(114) || 1,  # catalog location
                       ];
        $self->_set_i_val('_quote_cache', $quote_cache);
    }

    return $quote_cache;
}

sub _get_identifier_quote_char {
    return shift()->_get_quote_chars()->[0];
}

sub _get_catalog_separator {
    return shift()->_get_quote_chars()->[1];
}

# don't quote if is a reference to a scalar
sub _maybe_quote_field_name {
    my ($self, $field) = @_;

    my $ref = ref($field);
    if ($ref and $ref eq 'SCALAR') {
        return $$field;
    }
    else {
        return $self->_quote_field_name($field);
    }
}

sub _quote_field_name {
    my $self = shift;
    my $field = shift;

    my $sep = $self->_get_catalog_separator;
    my $sf_sep = quotemeta($sep);
    my @parts = split(/$sf_sep/, $field);

    my $quote_char = $self->_get_identifier_quote_char;
    my $sf_quote_char = quotemeta($quote_char);

    foreach my $part (@parts) {
        $part =~ s/$sf_quote_char/$quote_char$quote_char/g;
        $part = $quote_char . $part . $quote_char;
    }

    return join($sep, @parts);
}

# E.g., turn test_db.test_table into `test_db`.`test_table`
sub _quote_table {
    my $self = shift;
    my $table = shift;

    my $sep = $self->_get_catalog_separator;

    my $parts;
    if (ref($table) eq 'ARRAY') {
        $parts = $table;
    }
    else {
        my $sf_sep = quotemeta($sep);
        $parts = [ split(/$sf_sep/, $table) ];
    }
    
    return join($sep, map { $self->_quote_field_name($_) } @$parts);
}

=pod

=head2 C<update($table, \%keys, \%data), update($table, \@keys, \%data)>

Update the table using the key/value pairs in C<%keys> to specify
the C<WHERE> clause of the query.  C<%data> contains the new values
for the row(s) in the database.  The keys parameter can
optionally be an array ref instead of a hashref.  E.g.,

     $db->update($table, [ key1 => $val1, key2 => $val2 ], \%data);

This is so that the order of the parameters in the C<WHERE> clause
are kept in the same order.  This is required to use the correct
multi field indexes in some databases.

=cut
sub update {
    my ($self, $table, $keys, $data) = @_;

    if (defined($keys)) {
        unless ((UNIVERSAL::isa($keys, 'HASH') or UNIVERSAL::isa($keys, 'ARRAY'))) {
            return $self->setErr(-1, 'DBIx::Wrapper: No keys passed to update()');
        }
        
    }

    unless ($data and UNIVERSAL::isa($data, 'HASH')) {
        return $self->setErr(-1, 'DBIx::Wrapper: No values passed to update()');
    }

    unless (%$data) {
        return "0E";
    }
        
    # my @fields;
    my @values;
    my @set;

    my $dbh = $self->_getDatabaseHandle;
    while (my ($field, $value) = each %$data) {
        # push @fields, $field;
        my $sf_field = $self->_quote_field_name($field);
        if (UNIVERSAL::isa($value, 'DBIx::Wrapper::SQLCommand')) {
            push @set, "$sf_field=" . $value->asString;
        } elsif (ref($value) eq 'SCALAR') {
            push @set, "$sf_field=" . $$value;
        } else {
            if ($self->_getNoPlaceholders) {
                if (defined($value)) {
                    push @set, "$sf_field=" . $dbh->quote($value);
                }
                else {
                    push @set, "$sf_field=NULL";
                }
            }
            else {
                push @set, "$sf_field=?";
                push @values, $value;
            }
        }
    }

    my @keys;
    if (ref($keys) eq 'ARRAY') {
        # allow this to maintain order in the WHERE clause in
        # order to use the right indexes
        my @copy = @$keys;
        while (my $key = shift @copy) {
            push @keys, $key;
            my $val = shift @copy; # shift off the value
        }
        $keys = { @$keys };
    }
    elsif (not defined($keys)) {
        # do nothing
    }
    else {
        @keys = keys %$keys;
    }

#     unless ($self->_getNoPlaceholders) {
#         if (defined($keys)) {
#             push @values, @$keys{@keys};
#         }
#     }

    my $set = join(",", @set);
    my $where;
    if (defined($keys)) {
        if ($self->_getNoPlaceholders) {
            my @where;
            foreach my $key (@keys) {
                my $val = $keys->{$key};
                if (UNIVERSAL::isa($val, 'DBIx::Wrapper::SQLCommand')) {
                    my $sf_field = $self->_quote_field_name($key);

                    if ($val->has_condition) {
                        my ($cond, $r_val) = $val->get_condition(not $self->_getNoPlaceholders);

                        if (defined($r_val)) {
                            push @where, "$sf_field $cond $r_val";
                        } else {
                            push @where, "$sf_field $cond";
                        }
                    }
                    
                }
                else {
                    push @where, $self->_equals_or_is_null($key, $val);
                }
            }
            $where = join(" AND ", @where);
            # $where = join(" AND ", map { $self->_equals_or_is_null($_, $keys->{$_}) } @keys);
        }
        else {
            my @where;
            foreach my $key (@keys) {
                my $sf_field = $self->_quote_field_name($key);
                my $val = $keys->{$key};
                if (defined($val)) {
                    if (UNIVERSAL::isa($val, 'DBIx::Wrapper::SQLCommand')) {
                        if ($val->has_condition) {
                            my ($cond, $r_val) = $val->get_condition(not $self->_getNoPlaceholders);
                            if (defined($r_val)) {
                                push @where, "$sf_field $cond $r_val";
                                push @values, $val->get_val;
                            } else {
                                push @where, "$sf_field $cond";
                            }
                        }

                    }
                    else {
                        push @values, $val;
                        push @where, "$sf_field=?";
                    }
            
                }
                else {
                    push @where, "$sf_field IS NULL";
                }
            }
            
            # $where = join(" AND ", map { "$_=?" } map { $self->_quote_field_name($_) } @keys);
            $where = join(" AND ", @where);
        }
    }
        
    # quote_identifier() method added to DBI in version 1.21 (Feb 2002)
    
    my $sf_table = $self->_quote_table($table);
    my $query;
    if (defined($where)) {
        $query = qq{UPDATE $sf_table SET $set WHERE $where};
    }
    else {
        $query = qq{UPDATE $sf_table SET $set};
    }
    
    my ($sth, $rv) = $self->_getStatementHandleForQuery($query, \@values);
    return $sth unless $sth;
    $sth->finish;
        
    return $rv;
}

sub _equals_or_is_null {
    my ($self, $field_name, $value, $dont_quote_val) = @_;

    my $str = '';
    if (defined($value)) {
        $str = $self->_quote_field_name($field_name) . '=';
        if ($dont_quote_val) {
            $str .= $value;
        }
        else {
            $str .= $self->_getDatabaseHandle()->quote($value);
        }
    }
    else {
        $str = $self->_quote_field_name($field_name) . ' IS NULL';
    }

    return $str;
}

=pod

=head2 C<exists($table, \%keys)>

Returns true if one or more records exist with the given column
values in C<%keys>.  C<%keys> can be recursive as in the
C<selectFromHash()> method.

=cut
sub exists {
    my $self = shift;
    my $table = shift;
    my $keys = shift;

    my $row = $self->select_from_hash($table, $keys, [ [ keys %$keys ]->[0] ]);
    # my $row = $self->select_from_hash($table, $keys);
    # print STDERR "\n\n=====> exists: " . Data::Dumper->Dump([ $row ], [ 'row' ]) . "\n\n";

    if ($row and %$row) {
        return 1;
    }
    return;
}

=pod

=head2 C<selectFromHash($table, \%keys, \@cols);>

Select from table C<$table> using the key/value pairs in C<%keys> to
specify the C<WHERE> clause of the query.  Multiple key/value pairs
are joined with C<AND> in the C<WHERE> clause.  Returns a single row
as a hashref.  If C<%keys> is empty or not passed, it is treated as
C<"SELECT * FROM $table"> with no C<WHERE> clause.  C<@cols> is a list of
columns you want back.  If nothing is passed in C<@cols>, all
columns will be returned.

If a value in the C<%keys> hash is an array ref, the resulting
query will search for records with any of those values. E.g.,

   my $row = $db->selectFromHash('the_table', { id => [ 5, 6, 7 ] });

will result in a query like

=for pod2rst next-code-block: sql

   SELECT * FROM the_table WHERE (id=5 OR id=6 OR id=7)

The call

   my $row = $db->selectFromHash('the_table', { id => [ 5, 6, 7 ], the_val => 'ten' });

will result in a query like

=for pod2rst next-code-block: sql

   SELECT * FROM the_table WHERE (id=5 OR id=6 OR id=7) AND the_val="ten"

or, if a value was passed in for C<\@cols>, e.g.,

   my $row = $db->selectFromHash('the_table', { id => [ 5, 6, 7 ], the_val => 'ten' }, [ 'id' ]);

the resulting query would be

=for pod2rst next-code-block: sql

   SELECT id FROM the_table WHERE (id=5 OR id=6 OR id=7) AND the_val="ten"


Aliases: select_from_hash, sfh

=cut
sub selectFromHash {
    my ($self, $table, $keys, $cols) = @_;
    my $sth = $self->_get_statement_handle_for_select_from_hash($table, $keys, $cols);
    return $sth unless $sth;
    my $info = $sth->fetchrow_hashref;
    my $rv;
    if ($info and %$info) {
        $rv = $info; 
    } else {
        $rv = wantarray ? () : undef;
    }
    $sth->finish;
    return $rv;
}

*select_from_hash = \&selectFromHash;
*sfh = \&selectFromHash;

sub _get_statement_handle_for_select_from_hash {
    my ($self, $table, $keys, $cols) = @_;

    my ($query, $exec_args) = $self->_get_query_for_select_from_hash($table, $keys, $cols);

    if ($exec_args) {
        return $self->_getStatementHandleForQuery($query, $exec_args);
    }
    else {
        return $self->_getStatementHandleForQuery($query);
    }
}

sub _get_query_for_select_from_hash {
    my ($self, $table, $keys, $cols) = @_;
    my $query;

    my $col_list = '*';
    if (ref($cols) eq 'ARRAY') {
        if (@$cols) {
            $col_list = join(',', map { $self->_maybe_quote_field_name($_) } @$cols);
        }
    } elsif (defined($cols) and $cols ne '') {
        $col_list = $self->_quote_field_name($cols);
    }

    my $sf_table = $self->_quote_table($table);
    if ($keys and ((ref($keys) eq 'HASH' and %$keys) or (ref($keys) eq 'ARRAY' and @$keys))) {
        my ($where, $exec_args) = $self->_get_clause_for_select_from_hash($keys);
        return (qq{SELECT $col_list FROM $sf_table WHERE $where}, $exec_args);
    } else {
        return (qq{SELECT $col_list FROM $sf_table});
    }
}

sub _get_clause_for_select_from_hash {
    my $self = shift;
    my $data = shift;
    my $parent_key = shift;
    my @values;
    my @where;

    my $dbh = $self->_getDatabaseHandle;
    if (ref($data) eq 'HASH') {
        my @keys = sort keys %$data;
        foreach my $key (@keys) {
            my $val = $data->{$key};
            if (ref($val)) {
                my ($clause, $exec_args) = $self->_get_clause_for_select_from_hash($val, $key);
                push @where, "($clause)";
                push @values, @$exec_args if $exec_args;
            } else {
                my $sf_key = $self->_quote_field_name($key);
                if ($self->_getNoPlaceholders) {
                    if (defined($val)) {
                        push @where, "$sf_key=" . $dbh->quote($val);
                    }
                    else {
                        push @where, "$sf_key IS NULL";
                    }
                }
                else {
                    if (defined($val)) {
                        push @where, "$sf_key=?";
                        push @values, $val;
                    }
                    else {
                        push @where, "$sf_key IS NULL";
                    }
                }
            }
        }
        my $where = join(" AND ", @where);
        return wantarray ? ($where, \@values) : $where;
    } elsif (ref($data) eq 'ARRAY') {
        foreach my $val (@$data) {
            if (ref($val)) {
                my ($clause, $exec_args) =
                    $self->_get_clause_for_select_from_hash($val, $parent_key);
                push @where, "($clause)";
                push @values, @$exec_args if $exec_args;
            } else {
                my $sf_parent_key = $self->_quote_field_name($parent_key);
                if ($self->_getNoPlaceholders) {
                    if (defined($val)) {
                        push @where, "$sf_parent_key=" . $dbh->quote($val);
                    }
                    else {
                        push @where, "$sf_parent_key IS NULL";
                    }
                }
                else {
                    if (defined($val)) {
                        push @where, "$sf_parent_key=?";
                        push @values, $val;
                    }
                    else {
                        push @where, "$sf_parent_key IS NULL";                        
                    }
                }
            }
        }
        my $where = join(" OR ", @where);
        return wantarray ? ($where, \@values) : $where;
    } else {
        return wantarray ? ($data, []) : $data;
    }
}
    

=pod

=head2 C<selectFromHashMulti($table, \%keys, \@cols)>

Like C<selectFromHash()>, but returns all rows in the result.
Returns a reference to an array of hashrefs.

Aliases: select_from_hash_multi, sfhm

=cut
sub selectFromHashMulti {
    my ($self, $table, $keys, $cols) = @_;
    my $sth = $self->_get_statement_handle_for_select_from_hash($table, $keys, $cols);
    return $sth unless $sth;
    my $results = [];
    while (my $info = $sth->fetchrow_hashref) {
        push @$results, $info;
    }
    $sth->finish;
    return $results;
}

*select_from_hash_multi = \&selectFromHashMulti;
*sfhm = \&selectFromHashMulti;

=pod

=head2 C<selectAll($table, \@cols)>

Selects every row in the given table.  Equivalent to leaving out
C<%keys> when calling C<selectFromHashMulti()>, e.g.,
C<$dbh-E<gt>selectFromHashMulti($table, undef, \@cols)>.  The simplest
case of C<$dbh-E<gt>selectAll($table)> gets turned into something like
C<SELECT * FROM '$table'>

Aliases: select_from_all

=cut
# version 0.22
sub selectAll {
    my $self = shift;
    my $table = shift;
    my $cols = shift;

    return $self->select_from_hash_multi($table, undef, $cols);
}

*select_all = \&selectAll;

=pod

=head2 C<selectValueFromHash($table, \%keys, $col)>

Combination of C<nativeSelectValue()> and C<selectFromHash()>.
Returns the first column from the result of a query given by
C<$table> and C<%keys>, as in C<selectFromHash()>.  C<$col> is the column to
return.

Aliases: select_value_from_hash, svfh

=cut
sub selectValueFromHash {
    my ($self, $table, $keys, $col) = @_;

    my $sth = $self->_get_statement_handle_for_select_from_hash($table, $keys, $col);
    return $sth unless $sth;
    my $info = $sth->fetchrow_arrayref;
    $sth->finish;

    my $rv;
    if ($info and @$info) {
        return $info->[0];
    } else {
        return wantarray ? () : undef;
    }
}

*select_value_from_hash = \&selectValueFromHash;
*svfh = \&selectValueFromHash;

=pod

=head2 C<selectValueFromHashMulti($table, \%keys, \@cols)>

Like C<selectValueFromHash()>, but returns the first column of all
rows in the result.

Aliases: select_value_from_hash_multi, svfhm

=cut

sub selectValueFromHashMulti {
    my ($self, $table, $keys, $col) = @_;

    my $sth = $self->_get_statement_handle_for_select_from_hash($table, $keys, $col);
    return $sth unless $sth;
    my $results = [];
    while (my $info = $sth->fetchrow_arrayref) {
        push @$results, $info->[0];
    }
    $sth->finish;
    return $results;
}

*select_value_from_hash_multi = \&selectValueFromHashMulti;
*svfhm = \&selectValueFromHashMulti;

=pod

=head2 C<smartUpdate($table, \%keys, \%data)>

Same as C<update()>, except that a check is first made to see if
there are any rows matching the data in C<%keys>.  If so, C<update()>
is called, otherwise, C<insert()> is called.

Aliases: smart_update

=cut
sub smartUpdate {
    my ($self, $table, $keys, $data) = @_;
    unless (ref($data) eq 'HASH' and %$data) {
        return "0E";
    }

    # print STDERR "\n\n=====> calling exists: " . Data::Dumper->Dump([ $keys ], [ 'keys' ]) . "\n\n";

    if ($self->exists($table, $keys)) {
        # print STDERR "\n\n====> calling update()\n\n";
        return $self->update($table, $keys, $data);
    } else {
        my %new_data = %$data;
        while (my ($key, $value) = each %$keys) {
            $new_data{$key} = $value unless CORE::exists $new_data{$key};
        }
        return $self->insert($table, \%new_data);
    }
        
}

*smart_update = \&smartUpdate;

sub _runHandler {
    my ($self, $handler_info, @args) = @_;
    return undef unless ref($handler_info);

    my ($handler, $custom_args) = @$handler_info;
    $custom_args = [] unless $custom_args;
        
    unshift @args, $self;
    if (ref($handler) eq 'ARRAY') {
        my $method = $handler->[1];
        $handler->[0]->$method(@args, @$custom_args);
    } else {
        $handler->(@args, @$custom_args);
    }

    return 1;
}

sub _runHandlers {
    my ($self, $handlers, $r) = @_;
    return undef unless $handlers;

    my $rv = $r->OK;
    foreach my $handler_info (reverse @$handlers) {
        my ($handler, $custom_args) = @$handler_info;
        $custom_args = [] unless $custom_args;
            
        if (ref($handler) eq 'ARRAY') {
            my $method = $handler->[1];
            $rv = $handler->[0]->$method($r);
        } else {
            $rv = $handler->($r);
        }
        last unless $rv == $r->DECLINED;
    }

    return $rv;
}



sub _defaultPrePrepareHandler {
    my $r = shift;
    return $r->OK;
}

sub _defaultPostPrepareHandler {
    my $r = shift;
    return $r->OK;
}

sub _defaultPreExecHandler {
    my $r = shift;
    return $r->OK;
}

sub _defaultPostExecHandler {
    my $r = shift;
    return $r->OK;
}

sub _defaultPreFetchHandler {
    my $r = shift;
    return $r->OK;
}
    
sub _defaultPostFetchHandler {
    my $r = shift;
    return $r->OK;
}

sub _runGenericHook {
    my ($self, $r, $default_handler, $custom_handler_field) = @_;
    my $handlers = [ $default_handler ];
        
    if ($self->shouldBeHeavy) {
        if ($custom_handler_field eq '_post_fetch_hooks') {
            push @$handlers, [ \&_heavyPostFetchHook ];
        }
    }
        
    my $custom_handlers = $self->_get_i_val($custom_handler_field);
    push @$handlers, @$custom_handlers if $custom_handlers;

    return $self->_runHandlers($handlers, $r);
}

sub _runPrePrepareHook {
    my $self = shift;
    my $r = shift;
    my $handlers = [ [ \&_defaultPrePrepareHandler ] ];
    my $custom_handlers = $self->_get_i_val('_pre_prepare_hooks');
    push @$handlers, @$custom_handlers if $custom_handlers;
                
    return $self->_runHandlers($handlers, $r);
}

sub _runPostPrepareHook {
    my $self = shift;
    my $r = shift;
    my $handlers = [ [ \&_defaultPostPrepareHandler ] ];
    my $custom_handlers = $self->_get_i_val('_post_prepare_hooks');
    push @$handlers, @$custom_handlers if $custom_handlers;
                
    return $self->_runHandlers($handlers, $r);
}

sub _runPreExecHook {
    my $self = shift;
    my $r = shift;
    my $handlers = [ [ \&_defaultPreExecHandler ] ];
    my $custom_handlers = $self->_get_i_val('_pre_exec_hooks');
    push @$handlers, @$custom_handlers if $custom_handlers;
                
    return $self->_runHandlers($handlers, $r);
}

sub _runPostExecHook {
    my $self = shift;
    my $r = shift;
    return $self->_runGenericHook($r, [ \&_defaultPostExecHandler ], '_post_exec_hooks');
}

sub _runPreFetchHook {
    my $self = shift;
    my $r = shift;
    return $self->_runGenericHook($r, [ \&_defaultPreFetchHandler ], '_pre_fetch_hooks');
}

sub _runPostFetchHook {
    my $self = shift;
    my $r = shift;
    return $self->_runGenericHook($r, [ \&_defaultPostFetchHandler ],
                                  '_post_fetch_hooks');
}

sub _heavyPostFetchHook {
    my $r = shift;
    my $row = $r->getReturnVal;

    if (ref($row) eq 'HASH') {
        $r->setReturnVal(bless($row, 'DBIx::Wrapper::Delegator'));
    } elsif (ref($row) eq 'ARRAY') {
        # do nothing for now
    }
}

sub _bind_named_place_holders {
    my $self = shift;
    my $query = shift;
    my $exec_args = shift;

    my $dbh = $self->_getDatabaseHandle;
    
#     $query =~ s/(?<!:):([\'\"]?)(\w+)\1/$self->quote($exec_args->{$2})/eg;
#     return wantarray ? ($query, []) : $query;

    my @new_args;
    # $query =~ s/(?<!:):([\'\"]?)(\w+)\1/push(@new_args, $exec_args->{$2}); '?'/eg;

    # Convert :: to : instead of treating it as a placeholder
    $query =~ s{(::)|:([\'\"]?)(\w+)\2}{
        if (defined($1) and $1 eq '::' ) {
            ':' . (defined $2 ? $2 : '') . (defined $3 ? $3 : '') . (defined $2 ? $2 : '')
        }
        else {
            my $val = '?';
            if ($self->_getNoPlaceholders) {
                $val = $dbh->quote($exec_args->{$3});
            } else {
                push(@new_args, $exec_args->{$3});
            }
            $val;
        }
    }eg;
    
    return wantarray ? ($query, \@new_args) : $query;

}

sub _getStatementHandleForQuery {
    my ($self, $query, $exec_args, $attr) = @_;
        
    if (scalar(@_) >= 3) {
        my $type = ref($exec_args);
        if ($type eq 'HASH') {
            # okay
            ($query, $exec_args) = $self->_bind_named_place_holders($query, $exec_args);
        }
        elsif ($type eq 'ARRAY') {
            # okay -- leave as is
        }
        else {
            $exec_args = [ $exec_args ];
        }
    }
    
    $exec_args = [] unless $exec_args;

    $self->_printDebug($query);

    my $r = DBIx::Wrapper::Request->new($self);
    $r->setQuery($query);
    $r->setExecArgs($exec_args);
        
    $self->_runPrePrepareHook($r);
    $query = $r->getQuery;
    $exec_args = $r->getExecArgs;
        
    my $dbh = $self->_getDatabaseHandle;
    my $sth;

    if (ref($attr) eq 'HASH') {
        $sth = $dbh->prepare($query, $attr);
    }
    else {
        $sth = $dbh->prepare($query);
    }

    $r->setStatementHandle($sth);
    $r->setErrorStr($sth ? $dbh->errstr : '');
    $self->_runPostPrepareHook($r);
        
    unless ($sth) {
        if ($self->_isDebugOn) {
            $self->_printDebug(Carp::longmess($dbh->errstr) . "\nQuery was '$query'\n");
        } else {
            $self->_printDbiError("\nQuery was '$query'\n");
        }
        return wantarray ? ($self->setErr(0, $dbh->errstr), undef)
            : $self->setErr(0, $dbh->errstr);
    }

    $r->setQuery($query);
    $r->setExecArgs($exec_args);

    $self->_runPreExecHook($r);

    $exec_args = $r->getExecArgs;

    my $rv = $sth->execute(@$exec_args);
        
    $r->setExecReturnValue($rv);
    $r->setErrorStr($rv ? '' : $dbh->errstr);
    $self->_runPostExecHook($r);
    $rv = $r->getExecReturnValue;
    $sth = $r->getStatementHandle;
        
    unless ($rv) {
        if ($self->_isDebugOn) {
            $self->_printDebug(Carp::longmess($dbh->errstr) . "\nQuery was '$query'\n");
        } else {
            $self->_printDbiError("\nQuery was '$query'\n");
        }
        return wantarray ? ($self->setErr(1, $dbh->errstr), undef)
            : $self->setErr(1, $dbh->errstr);
    }

    return wantarray ? ($sth, $rv, $r) : $sth;
}

sub prepare_no_hooks {
    my $self = shift;
    my $query = shift;

    my $dbi_obj = $self->getDBI;
    my $sth = $dbi_obj->prepare($query);

    return $sth;
}

*prepare_no_handlers = \&prepare_no_hooks;


=pod

=head2 C<nativeSelect($query, \@exec_args)>

Executes the query in $query and returns a single row result (as
a hash ref).  If there are multiple rows in the result, the rest
get silently dropped.  C<@exec_args> are the same arguments you
would pass to an C<execute()> called on a DBI object.  Returns
undef on error.

Aliases: native_select

=cut
sub nativeSelect {
    my ($self, $query, $exec_args) = @_;

    my ($sth, $rv, $r);
    if (scalar(@_) == 3) {
        ($sth, $rv, $r) = $self->_getStatementHandleForQuery($query, $exec_args);
    } else {
        ($sth, $rv, $r) = $self->_getStatementHandleForQuery($query);
    }
        
    return $sth unless $sth;

    $self->_runPreFetchHook($r);
    $sth = $r->getStatementHandle;
        
    my $result = $sth->fetchrow_hashref($self->getNameArg);
        
    $r->setReturnVal($result);
    $self->_runPostFetchHook($r);
    $result = $r->getReturnVal;
        
    $sth->finish;

    return $result; 
}

*read = \&nativeSelect;
*selectNative = \&nativeSelect;
*native_select = \&nativeSelect;
*select_native = \&nativeSelect;

=pod

=head2 C<nativeSelectExecLoop($query)>

Like C<nativeSelect()>, but returns a loop object that can be used
to execute the same query over and over with different bind
parameters.  This does a single DBI C<prepare()> instead of a new
C<prepare()> for select.

E.g.,

     my $loop = $db->nativeSelectExecLoop("SELECT * FROM mytable WHERE id=?");
     foreach my $id (@ids) {
         my $row = $loop->next([ $id ]);
     }

To get the column names in the order returned from your query:

 # returns the names with their character case the same as when
 # calling $loop->next, i.e., the case set with $db->setNameArg
 my $cols = $loop->get_field_names;
 
 # returns the names with their character case unmodified
 my $cols = $loop->get_names;
 
 # returns the names in all upper-case
 my $cols = $loop->get_names_uc;
 
 # returns the names in all lower-case
 my $cols = $loop->get_names_lc;

Aliases: native_select_exec_loop

=cut    
# added for v 0.08
sub nativeSelectExecLoop {
    my ($self, $query) = @_;
    return DBIx::Wrapper::SelectExecLoop->new($self, $query);
}

*native_select_exec_loop = \&nativeSelectExecLoop;
*select_native_exec_loop = \&nativeSelectExecLoop;
*selectNativeExecLoop = \&nativeSelectExecLoop;

=pod

=head2 C<nativeSelectWithArrayRef($query, \@exec_args)>

Like C<nativeSelect()>, but return a reference to an array instead
of a hash.  Returns undef on error.  If there are no results
from the query, a reference to an empty array is returned.

Aliases: native_select_with_array_ref, nswar

=cut
sub nativeSelectWithArrayRef {
    my ($self, $query, $exec_args) = @_;

    my ($sth, $rv, $r);
    if (scalar(@_) == 3) {
        ($sth, $rv, $r) = $self->_getStatementHandleForQuery($query, $exec_args);
    } else {
        ($sth, $rv, $r) = $self->_getStatementHandleForQuery($query);
    }
        
    return $sth unless $sth;

    $self->_runPreFetchHook($r);
    $sth = $r->getStatementHandle;

    my $result = $sth->fetchrow_arrayref;

    $r->setReturnVal($result);
    $self->_runPostFetchHook($r);

    $result = $r->getReturnVal;

    $sth->finish;

    return [] unless $result and ref($result) =~ /ARRAY/;
        
    # have to make copy because recent version of DBI now
    # return the same array reference each time
    return [ @$result ];
}

*native_select_with_array_ref = \&nativeSelectArrayWithArrayRef;
*select_native_with_array_ref = \&nativeSelectArrayWithArrayRef;
*selectNativeArrayWithArrayRef = \&nativeSelectArrayWithArrayRef;
*nswar = \&nativeSelectArrayWithArrayRef;

=pod

=head2 C<nativeSelectMulti($query, \@exec_args)>

Executes the query in C<$query> and returns an array of rows, where
each row is a hash representing a row of the result.  Returns
C<undef> on error.  If there are no results for the query, an empty
array ref is returned.

Aliases: native_select_multi

=cut
sub nativeSelectMulti {
    my ($self, $query, $exec_args) = @_;

    my ($sth, $rv, $r);
    if (scalar(@_) == 3) {
        ($sth, $rv, $r) = $self->_getStatementHandleForQuery($query, $exec_args);
    } else {
        ($sth, $rv, $r) = $self->_getStatementHandleForQuery($query);
    }
    return $sth unless $sth;

    $self->_runPreFetchHook($r);
    $sth = $r->getStatementHandle;

    my $rows = [];
    my $row = $sth->fetchrow_hashref($self->getNameArg);
    while ($row) {
        $r->setReturnVal($row);
        $self->_runPostFetchHook($r);

        $row = $r->getReturnVal;
        push @$rows, $row;
            
        $self->_runPreFetchHook($r);
        $sth = $r->getStatementHandle;

        $row = $sth->fetchrow_hashref($self->getNameArg)
    }
    my $col_names = $sth->{$self->getNameArg};
    $self->_set_i_val('_last_col_names', $col_names);
    $sth->finish;

    return $rows;
}

*readArray = \&nativeSelectMulti;
*native_select_multi = \&nativeSelectMulti;
*select_native_multi = \&nativeSelectMulti;
*selectNativeMulti = \&nativeSelectMulti;

=pod

=head2 C<nativeSelectMultiOrOne($query, \@exec_args)>

Like C<nativeSelectMulti()>, but if there is only one row in the
result, that row (a hash ref) is returned.  If there are zero
rows, undef is returned. Otherwise, an array ref is returned.

Aliases: native_select_multi_or_one

=cut
# version 0.22
sub nativeSelectMultiOrOne {
    my $self = shift;

    my $rows = $self->nativeSelectMulti(@_);
    if ($rows) {
        if (scalar(@$rows) == 0) {
            return;
        }
        elsif (scalar(@$rows) == 1) {
            return $rows->[0];
        }
        else {
            return $rows;
        }
    }
    else {
        return $rows;
    }

}
*native_select_multi_or_one = \&nativeSelectMultiOrOne;

=pod

=head2 C<nativeSelectMultiExecLoop($query)>

Like C<nativeSelectExecLoop()>, but returns an array of rows, where
each row is a hash representing a row of the result.

Aliases: native_select_multi_exec_loop

=cut
sub nativeSelectMultiExecLoop {
    my ($self, $query) = @_;
    return DBIx::Wrapper::SelectExecLoop->new($self, $query, 1);
}

*native_select_multi_exec_loop = \&nativeSelectMultiExecLoop;
*select_native_multi_exec_loop = \&nativeSelectMultiExecLoop;
*selectNativeMultiExecLoop = \&nativeSelectMultiExecLoop;

=pod

=head2 C<nativeSelectMultiWithArrayRef($query, \@exec_args)>

Like C<nativeSelectMulti()>, but return a reference to an array of
arrays instead of to an array of hashes.  Returns undef on error.

Aliases: native_select_multi_with_array_ref

=cut    
sub nativeSelectMultiWithArrayRef {
    my ($self, $query, $exec_args, $attr) = @_;

    my ($sth, $rv, $r);
    if (scalar(@_) >= 3) {
        ($sth, $rv, $r) = $self->_getStatementHandleForQuery($query, $exec_args, $attr);
    } else {
        ($sth, $rv, $r) = $self->_getStatementHandleForQuery($query);
    }
        
    return $sth unless $sth;

    $self->_runPreFetchHook($r);
    $sth = $r->getStatementHandle;

    my $list = [];

    my $result = $sth->fetchrow_arrayref;
    while ($result) {
        $r->setReturnVal($result);
        $self->_runPostFetchHook($r);
        $result = $r->getReturnVal;
            
        # have to make copy because recent versions of DBI now
        # return the same array reference each time
        push @$list, [ @$result ];
        $result = $sth->fetchrow_arrayref;
    }
    $sth->finish;

    return $list;
}

*native_select_multi_with_array_ref = \&nativeSelectMultiWithArrayRef;
*select_native_multi_with_array_ref = \&nativeSelectMultiWithArrayRef;
*selectNativeMultiWithArrayRef = \&nativeSelectMultiWithArrayRef;

=pod

=head2 C<nativeSelectMapping($query, \@exec_args)>

Executes the given query and returns a reference to a hash
containing the first and second columns of the results as
key/value pairs.

Aliases: native_select_mapping, nsm

=cut
sub nativeSelectMapping {
    my ($self, $query, $exec_args) = @_;
    if (scalar(@_) == 3) {
        $self->nativeSelectDynaMapping($query, [ 0, 1 ], $exec_args);
    } else {
        $self->nativeSelectDynaMapping($query, [ 0, 1 ]);
    }
}

*native_select_mapping = \&nativeSelectMapping;
*select_native_mapping = \&nativeSelectMapping;
*selectNativeMapping = \&nativeSelectMapping;
*nsm = \&nativeSelectMapping;

=pod

=head2 C<nativeSelectDynaMapping($query, \@cols, \@exec_args)>

Similar to C<nativeSelectMapping()> except you specify which
columns to use for the key/value pairs in the return hash.  If
the first element of C<@cols> starts with a digit, then C<@cols> is
assumed to contain indexes for the two columns you wish to use.
Otherwise, C<@cols> is assumed to contain the field names for the
two columns you wish to use.

For example,

     nativeSelectMapping($query, \@exec_args) is

equivalent (and in fact calls) to

     nativeSelectDynaMapping($query, [ 0, 1 ], $exec_args).

Aliases: native_select_dyna_mapping, nsdm

=cut
# FIXME: return undef on error
sub nativeSelectDynaMapping {
    my ($self, $query, $cols, $exec_args) = @_;

    my ($first, $second) = @$cols;
    my $key;
    my $map = {};
    if ($first =~ /^\d/) {
        my $rows;
        if (scalar(@_) == 4) {
            $rows = $self->nativeSelectMultiWithArrayRef($query, $exec_args);
        } else {
            $rows = $self->nativeSelectMultiWithArrayRef($query);
        }
        foreach my $row (@$rows) {
            $key = $row->[$first];
            unless (defined($key)) {
                $key = '';
            }
            $map->{$key} = $row->[$second];
        }

    } else {
        my $rows;
        if (scalar(@_) == 4) {
            $rows = $self->nativeSelectMulti($query, $exec_args);
        } else {
            $rows = $self->nativeSelectMulti($query);
        }
        foreach my $row (@$rows) {
            $key = $row->{$first};
            unless (defined($key)) {
                $key = '';
            }
            $map->{$key} = $row->{$second};
        }
    }
        
    return $map;
}

*native_select_dyna_mapping = \&nativeSelectDynaMapping;
*select_native_dyna_mapping = \&nativeSelectDynaMapping;
*selectNativeDynaMapping = \&nativeSelectDynaMapping;
*nsdm = \&nativeSelectDynaMapping;

=pod

=head2 C<nativeSelectRecordMapping($query, \@exec_args)>

Similar to C<nativeSelectMapping()>, except the values in the hash
are references to the corresponding record (as a hash).

Aliases: native_select_record_mapping

=cut
sub nativeSelectRecordMapping {
    my ($self, $query, $exec_args) = @_;

    if (scalar(@_) == 3) {
        return $self->nativeSelectRecordDynaMapping($query, 0, $exec_args);
    } else {
        return $self->nativeSelectRecordDynaMapping($query, 0);
    }
}

*native_select_record_mapping = \&nativeSelectRecordMapping;
*select_native_record_mapping = \&nativeSelectRecordMapping;
*selectNativeRecordMapping = \&nativeSelectRecordMapping;

=pod

=head2 C<nativeSelectRecordDynaMapping($query, $col, \@exec_args)>

Similar to C<nativeSelectRecordMapping()>, except you specify
which column is the key in each key/value pair in the hash.  If
C<$col> starts with a digit, then it is assumed to contain the
index for the column you wish to use.  Otherwise, C<$col> is
assumed to contain the field name for the two columns you wish
to use.

=cut
# FIXME: return undef on error
sub nativeSelectRecordDynaMapping {
    my ($self, $query, $col, $exec_args) = @_;

    my $map = {};
    if ($col =~ /^\d/) {
        my $rows;
        if (scalar(@_) == 4) {
            $rows = $self->nativeSelectMulti($query, $exec_args);
        } else {
            $rows = $self->nativeSelectMulti($query);
        }
        my $names = $self->_get_i_val('_last_col_names');
        my $col_name = $$names[$col];
        foreach my $row (@$rows) {
            $$map{$$row{$col_name}} = $row;
        }

    } else {
        my $rows;
        if (scalar(@_) == 4) {
            $rows = $self->nativeSelectMulti($query, $exec_args);
        } else {
            $rows = $self->nativeSelectMulti($query);
        }
        foreach my $row (@$rows) {
            $$map{$$row{$col}} = $row;
        }
    }

    return $map;
}

*native_select_record_dyna_mapping = \&nativeSelectRecordDynaMapping;
*select_native_record_dyna_mapping = \&nativeSelectRecordDynaMapping;
*selectNativeRecordDynaMapping = \&nativeSelectRecordDynaMapping;
    
sub _getSqlObj {
    # return SQL::Abstract->new(case => 'textbook', cmp => '=', logic => 'and');
    require SQL::Abstract;
    return SQL::Abstract->new(case => 'textbook', cmp => '=');
}

=pod

=head2 C<nativeSelectValue($query, \@exec_args)>

Returns a single value, the first column from the first row of
the result.  Returns undef on error or if there are no rows in
the result.  Note this may be the same value returned for a C<NULL> 
value in the result.

Aliases: native_select_value

=cut        
sub nativeSelectValue {
    my ($self, $query, $exec_args) = @_;
    my $row;
    
    if (scalar(@_) == 3) {
        $row = $self->nativeSelectWithArrayRef($query, $exec_args);
    } else {
        $row = $self->nativeSelectWithArrayRef($query);
    }
    if ($row and @$row) {
        return $row->[0];
    }

    return undef;
}

*native_select_value = \&nativeSelectValue;
*select_native_value = \&nativeSelectValue;
*selectNativeValue = \&nativeSelectValue;

=pod

=head2 C<nativeSelectValuesArray($query, \@exec_args)>

Like C<nativeSelectValue()>, but return multiple values, e.g.,
return an array of ids for the query

=for pod2rst next-code-block: sql

 SELECT id FROM WHERE color_pref='red'

Aliases: native_select_values_array

=cut
sub nativeSelectValuesArray {
    my ($self, $query, $exec_args) = @_;

    my $rows;
    if (scalar(@_) == 3) {
        $rows = $self->nativeSelectMultiWithArrayRef($query, $exec_args);
    } else {
        $rows = $self->nativeSelectMultiWithArrayRef($query);
    }

    return undef unless $rows;
    return [ map { $_->[0] } @$rows ];
}

*native_select_values_array = \&nativeSelectValuesArray;
*select_native_values_array = \&nativeSelectValuesArray;
*selectNativeValuesArray = \&nativeSelectValuesArray;

=pod

=head2 C<abstractSelect($table, \@fields, \%where, \@order)>

Same as C<nativeSelect()> except uses L<SQL::Abstract> to generate the
SQL.  See the POD for L<SQL::Abstract> for usage.  You must have L<SQL::Abstract> installed for this method to work.

Aliases: abstract_select

=cut
sub abstractSelect {
    my ($self, $table, $fields, $where, $order) = @_;
    my $sql_obj = $self->_getSqlObj;
    my ($query, @bind) = $sql_obj->select($table, $fields, $where, $order);

    if (@bind) {
        return $self->nativeSelect($query, \@bind);
    } else {
        return $self->nativeSelect($query);
    }
}

*abstract_select = \&abstractSelect;

=pod

=head2 C<abstractSelectMulti($table, \@fields, \%where, \@order)>

Same as C<nativeSelectMulti()> except uses L<SQL::Abstract> to
generate the SQL.  See the POD for L<SQL::Abstract> for usage.  You
must have L<SQL::Abstract> installed for this method to work.

Aliases: abstract_select_multi

=cut
sub abstractSelectMulti {
    my ($self, $table, $fields, $where, $order) = @_;
    my $sql_obj = $self->_getSqlObj;
    my ($query, @bind) = $sql_obj->select($table, $fields, $where, $order);

    if (@bind) {
        return $self->nativeSelectMulti($query, \@bind);
    } else {
        return $self->nativeSelectMulti($query);
    }
}

*abstract_select_multi = \&abstractSelectMulti;

=pod

=head2 C<nativeSelectLoop($query, @exec_args)>

Executes the query in C<$query>, then returns an object that allows
you to loop through one result at a time, e.g.,

    my $loop = $db->nativeSelectLoop("SELECT * FROM my_table");
    while (my $row = $loop->next) {
        my $id = $$row{id};
    }

To get the number of rows selected, you can call the
C<rowCountCurrent()> method on the loop object, e.g.,

    my $loop = $db->nativeSelectLoop("SELECT * FROM my_table");
    my $rows_in_result = $loop->rowCountCurrent;

The C<count()> method is an alias for C<rowCountCurrent()>.

To get the number of rows returned by C<next()> so far, use the
C<rowCountTotal()> method.

To get the column names in the order returned from your query:

 # returns the names with their character case the same as when
 # calling $loop->next, i.e., the case set with $db->setNameArg
 my $cols = $loop->get_field_names;
 
 # returns the names with their character case unmodified
 my $cols = $loop->get_names;
 
 # returns the names in all upper-case
 my $cols = $loop->get_names_uc;
 
 # returns the names in all lower-case
 my $cols = $loop->get_names_lc;

Aliases: native_select_loop

=cut
sub nativeSelectLoop {
    my ($self, $query, $exec_args) = @_;
    $self->_printDebug($query);

    if (scalar(@_) == 3) {
        return DBIx::Wrapper::SelectLoop->new($self, $query, $exec_args);
    } else {
        return DBIx::Wrapper::SelectLoop->new($self, $query);
    }
}

*readLoop = \&nativeSelectLoop;
*native_select_loop = \&nativeSelectLoop;
*select_native_loop = \&nativeSelectLoop;
*selectNativeLoop = \&nativeSelectLoop;

=pod

=head2 C<nativeQuery($query, \@exec_args, \%attr)>

Executes the query in $query and returns true if successful.
This is typically used for deletes and is a catchall for
anything the methods provided by this module don't take into
account.

Aliases: native_query

=cut
sub nativeQuery {
    my ($self, $query, $exec_args, $attr) = @_;

    my ($sth, $rv, $r);
    if (scalar(@_) >= 3) {
        ($sth, $rv, $r) = $self->_getStatementHandleForQuery($query, $exec_args, $attr);
    } else {
        ($sth, $rv, $r) = $self->_getStatementHandleForQuery($query);
    }
    return $sth unless $sth;
    return $rv;
}

*doQuery = \&nativeQuery;
*native_query = \&nativeQuery;

=pod

=head2 C<nativeQueryLoop($query)>

A loop on nativeQuery, where any placeholders you have put in
your query are bound each time you call C<next()>.  E.g.,

    my $loop = $db->nativeQueryLoop("UPDATE my_table SET value=? WHERE id=?");
    $loop->next([ 'one', 1]);
    $loop->next([ 'two', 2]);

Aliases: native_query_loop

=cut
sub nativeQueryLoop {
    my ($self, $query) = @_;
    $self->_printDebug($query);

    return DBIx::Wrapper::StatementLoop->new($self, $query);
}

*native_query_loop = \&nativeQueryLoop;

# =pod

# =head2 newCommand($cmd)

# This method is deprecated.  Use $db->command($cmd_str) instead.

# This creates a literal SQL command for use in insert(), update(),
# and related methods, since if you simply put something like
# "CUR_DATE()" as a value in the %data parameter passed to insert,
# the function will get quoted, and so will not work as expected.
# Instead, do something like this:

#     my $data = { file => 'my_document.txt',
#                  the_date => $db->newCommand('CUR_DATE()')
#                };
#     $db->insert('my_doc_table', $data);

# This can also be done by passing a reference to a string with the
# SQL command, e.g.,

#     my $data = { file => 'my_document.txt',
#                  the_date => \'CUR_DATE()'
#                };
#     $db->insert('my_doc_table', $data);


# =cut
sub newCommand {
    my ($self, $contents) = @_;
    return DBIx::Wrapper::SQLCommand->new($contents);
}

*new_command = \&newCommand;

=pod

=head2 C<command($cmd_string)>

This creates a literal SQL command for use in C<insert()>,
C<update()>, and related methods, since if you simply put something
like C<"CUR_DATE()"> as a value in the C<%data> parameter passed to
insert, the function will get quoted, and so will not work as
expected.  Instead, do something like this:

    my $data = { file => 'my_document.txt',
                 the_date => $db->command('CUR_DATE()')
               };
    $db->insert('my_doc_table', $data);

This can also be done by passing a reference to a string with
the SQL command, e.g.,

    my $data = { file => 'my_document.txt',
                 the_date => \'CUR_DATE()'
               };
    $db->insert('my_doc_table', $data);

This is currently how C<command()> is implemented.

Aliases: literal, sql_literal

=cut
sub command {
    my ($self, $str) = @_;
    return \$str;
}

*sql_literal = \&command;
*literal = \&command;

sub not {
    my $self = shift;
    my $val = shift;

    return DBIx::Wrapper::SQLCommand->new_cond($self, 'not', $val);
}

=pod

=head2 C<debugOn(\*FILE_HANDLE)>

Turns on debugging output.  Debugging information will be printed
to the given filehandle.

=cut
# expects a reference to a filehandle to print debug info to
sub debugOn {
    my $self = shift;
    my $fh = shift;
    $self->_set_i_val('_debug', 1);
    $self->_set_i_val('_debug_fh', $fh);

    return 1;
}

*debug_on = \&debugOn;

=pod

=head2 C<debugOff()>

Turns off debugging output.

=cut
sub debugOff {
    my $self = shift;
    $self->_delete_i_val('_debug');
    $self->_delete_i_val('_debug_fh');

    return 1;
}

*debug_off = \&debugOff;

sub _isDebugOn {
    my ($self) = @_;
    if (($self->_get_i_val('_debug') and $self->_get_i_val('_debug_fh'))
        or $ENV{'DBIX_WRAPPER_DEBUG'}) {
        return 1;
    }
    return undef;
}

sub _printDbiError {
    my ($self, $extra) = @_;

    my $handler = $self->_getErrorHandler;
    $handler = [ $self, \&_default_error_handler ] unless $handler;
    if ($handler) {
        if (UNIVERSAL::isa($handler, 'ARRAY')) {
            my ($obj, $meth) = @$handler;
            return $obj->$meth($self, $extra);
        } else {
            return $handler->($self, $extra);
        }
    }

    return undef;
}

sub _default_error_handler {
    my ($self, $db, $extra) = @_;

    my $dbi_obj = $self->getDBI;
    return undef unless $dbi_obj->{PrintError};
    
    return undef unless ($self->getDebugLevel | 2);
        
    my $fh = $self->_get_i_val('_debug_fh');
    $fh = \*STDERR unless $fh;
        
    my $time = $self->_getCurDateTime;

    my ($package, $filename, $line, $subroutine, $hasargs,
        $wantarray, $evaltext, $is_require, $hints, $bitmask);

    my $frame = 1;
    my $this_pkg = __PACKAGE__;

    ($package, $filename, $line, $subroutine, $hasargs,
     $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($frame);
    while ($package eq $this_pkg) {
        $frame++;
        ($package, $filename, $line, $subroutine, $hasargs,
         $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($frame);

        # if we get more than 10 something must be wrong
        last if $frame >= 10;
    }

    local($Carp::CarpLevel) = $frame;
    my $str = Carp::longmess($DBI::errstr);

    $str .= $extra if defined($extra);

    my @one_more = caller($frame + 1);
    $subroutine = $one_more[3];
    $subroutine = '' unless defined($subroutine);
    $subroutine .= '()' if $subroutine ne '';
        
    print $fh '*' x 60, "\n", "$time:$filename:$line:$subroutine\n", $str, "\n";
}

sub _default_debug_handler {
    my ($self, $db, $str, $fh) = @_;

    my $time = $self->_getCurDateTime;

    my ($package, $filename, $line, $subroutine, $hasargs,
        $wantarray, $evaltext, $is_require, $hints, $bitmask);

    my $frame = 1;
    my $this_pkg = __PACKAGE__;

    ($package, $filename, $line, $subroutine, $hasargs,
     $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($frame);
    while ($package eq $this_pkg) {
        $frame++;
        ($package, $filename, $line, $subroutine, $hasargs,
         $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($frame);

        # if we get more than 10 something must be wrong
        last if $frame >= 10;
    }

    my @one_more = caller($frame + 1);
    $subroutine = $one_more[3];
    $subroutine = '' unless defined($subroutine);
    $subroutine .= '()' if $subroutine ne '';
        
    print $fh '*' x 60, "\n", "$time:$filename:$line:$subroutine\n", $str, "\n";
}
    
sub _printDebug {
    my ($self, $str) = @_;
    unless ($self->_isDebugOn) {
        return undef;
    }

    # FIXME: check perl version to see if should use \*STDERR or *STDERR
    my $fh = $self->_get_i_val('_debug_fh');
    $fh = \*STDERR unless $fh;

    my $handler = $self->_getDebugHandler;
    $handler = [ $self, \&_default_debug_handler ] unless $handler;
    if ($handler) {
        if (UNIVERSAL::isa($handler, 'ARRAY')) {
            my ($obj, $meth) = @$handler;
            return $obj->$meth($self, $str, $fh);
        } else {
            return $handler->($self, $str, $fh);
        }
    }

    return undef;
}

sub _getCurDateTime {
    my ($self) = @_;
        
    my $time = time();
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
    $mon += 1;
    $year += 1900;
    my $date = sprintf "%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday,
        $hour, $min, $sec;
        
    return $date;
}

    
sub escapeString {
    my ($self, $value) = @_;
        
    $value = "" unless defined($value);
    $value =~ s|\\|\\\\|g;
    $value =~ s|\'|''|g;
    $value =~ s|\?|\\\?|g;
    $value =~ s|\000|\\0|g;
    $value =~ s|\"|""|g;
    $value =~ s|\n|\\n|g;
    $value =~ s|\r|\\r|g;
    $value =~ s|\t|\\t|g;

    return $value;
}

*escape_string = \&escapeString;

sub _moduleHasSub {
    my ($self, $module, $sub_name) = @_;
}
    
sub DESTROY {
    my ($self) = @_;
    return undef unless $self->_getDisconnect;
    my $dbh = $self->_getDatabaseHandle;
    $dbh->disconnect if $dbh;
    delete $i_data{ refaddr($self) }; # free up private data
}

#################
# getters/setters

sub getNameArg {
    my ($self) = @_;
    my $arg = $self->_get_i_val('_name_arg');
    $arg = 'NAME_lc' unless defined($arg) and $arg ne '';

    return $arg;
}

=pod

=head2 C<setNameArg($arg)>

This is the argument to pass to the C<fetchrow_hashref()> call on
the underlying DBI object.  By default, this is 'NAME_lc', so
that all field names returned are all lowercase to provide for
portable code.  If you want to make all the field names return
be uppercase, call C<$db-E<gt>setNameArg('NAME_uc')> after the
C<connect()> call.  And if you really want the case of the field
names to be what the underlying database driver returns them
as, call C<$db-E<gt>setNameArg('NAME')>.

Aliases: set_name_arg

=cut
sub setNameArg {
    my $self = shift;
    $self->_set_i_val('_name_arg', shift());
}
*set_name_arg = \&setNameArg;

sub setErr {
    my ($self, $num, $str) = @_;
    $self->_set_i_val('_err_num', $num);
    $self->_set_i_val('_err_str', $str);
    return undef;
}

sub getErrorString {
    my $self = shift;
    return $self->_get_i_val('_err_str');
}

sub getErrorNum {
    my $self = shift;
    return $self->_get_i_val('_err_num');
}

=pod

=head2 C<err()>

Calls C<err()> on the underlying DBI object, which returns the
native database engine error code from the last driver method
called.

=cut
sub err {
    my ($self) = @_;
    my $dbh = $self->_getDatabaseHandle;
    return $dbh->err if $dbh;
    return 0;
}

=pod

=head2 C<errstr()>

Calls C<errstr()> on the underlying DBI object, which returns the
native database engine error message from the last driver method
called.

=cut
sub errstr {
    my $self = shift;
    my $dbh = $self->_getDatabaseHandle;
    return $dbh ? $dbh->errstr : undef;
}
    
sub _getAttr {
    my $self = shift;
    return $self->_get_i_val('_attr');
}

sub _setAttr {
    my $self = shift;
    $self->_set_i_val('_attr', shift());
}

sub _getAuth {
    my $self = shift;
    return $self->_get_i_val('_auth');
}

sub _setAuth {
    my $self = shift;
    $self->_set_i_val('_auth', shift());
}

sub _getUsername {
    my ($self) = @_;
    return $self->_get_i_val('_username');
}

sub _setUsername {
    my $self = shift;
    my $username = shift;
    $self->_set_i_val('_username', $username);
}

sub _getDatabaseHandle {
    my $self = shift;
    return $self->_get_i_val('_dbh');
}

sub _setDatabaseHandle {
    my $self = shift;
    my $dbh = shift;
    $self->_set_i_val('_dbh', $dbh);
}

sub _deleteDatabaseHandle {
    my $self = shift;
    my $data = $self->_get_i_data();
    delete $data->{_dbh};
}

sub getDataSourceAsString {
    return shift()->_getDataSourceStr;
}

sub _getDataSourceStr {
    my $self = shift;
    return $self->_get_i_val('_data_source_str');
}

sub _setDataSourceStr {
    my $self = shift;
    $self->_set_i_val('_data_source_str', shift());
}

sub _getDataSource {
    my $self = shift;
    return $self->_get_i_val('_data_source');
}

sub _setDataSource {
    my $self = shift;
    $self->_set_i_val('_data_source', shift());
}

sub _getDisconnect {
    my $self = shift;
    return $self->_get_i_val('_should_disconnect');
}

sub _setErrorHandler {
    my $self = shift;
    $self->_set_i_val('_error_handler', shift());
}

sub _getErrorHandler {
    return shift()->_get_i_val('_error_handler');
}

sub _setDebugHandler {
    my $self = shift;
    $self->_set_i_val('_debug_handler', shift());
}
    
sub _getDebugHandler {
    return shift()->_get_i_val('_debug_handler');
}

sub _setDbStyle {
    my $self = shift;
    $self->_set_i_val('_db_style', shift());
}

sub _getDbStyle {
    return shift()->_get_i_val('_db_style');
}

sub _setDbdDriver {
    my $self = shift;
    $self->_set_i_val('_dbd_driver', shift());
}

sub _getDbdDriver {
    return shift()->_get_i_val('_dbd_driver');
}

# whether or not to disconnect when the Wrapper object is
# DESTROYed
sub _setDisconnect {
    my ($self, $val) = @_;
    $self->_set_i_val('_should_disconnect', 1);
}

sub _setNoPlaceholders {
    my $self = shift;
    $self->_set_i_val('_no_placeholders', shift());
}

sub _getNoPlaceholders {
    my $self = shift;
    return $self->_get_i_val('_no_placeholders');
}

sub _setHeavy {
    my $self = shift;
    $self->_set_i_val('_heavy', shift());
}

sub _getHeavy {
    my $self = shift;
    return $self->_get_i_val('_heavy');
}

sub shouldBeHeavy {
    my $self = shift;
    return 1 if $Heavy or $self->_getHeavy;
    return undef;
}

# sub get_info {
#     my ($self, $name) = @_;
#     require DBI::Const::GetInfoType;
#     my $dbh = $self->_getDatabaseHandle;
#     return $dbh->get_info($DBI::Const::GetInfoType::GetInfoType{$name});
# }

sub get_info {
    my $self = shift;
    my $name = shift;
    my $dbh = $self->_getDatabaseHandle;
    return $dbh->get_info($name);
}

=pod

=head2 DBI-compatible methods

The following method calls use the same interface as the DBI
method.  However, these are not simply passed through to DBI
(see DBI methods below), so any hooks you have defined for
C<DBIx::Wrapper> will be called.

=over 4

=item C<do>

=back

=cut
sub do {
    my ($self, $statement, $attr, @bind_values) = @_;
    return $self->nativeQuery($statement, \@bind_values, $attr);
}

=pod

=head2 DBI methods

The following method calls are just passed through to the
underlying DBI object for convenience.  See the documentation
for DBI for details.

=over 4

=item C<prepare>

This method may call hooks in the future.  Use
C<prepare_no_hooks()> if you want to ensure that it will be a
simple DBI call.

=back

=cut
sub prepare {
    my $self = shift;
    my $query = shift;

    my $dbi_obj = $self->getDBI;
    my $sth = $dbi_obj->prepare($query);

    return $sth;
}

=pod

=over 4

=item C<selectrow_arrayref>

=back

=cut
sub selectrow_arrayref {
    my $self = shift;
    my $dbh = $self->_getDatabaseHandle;
    return $dbh->selectrow_arrayref(@_);
}

=pod

=over 4

=item C<selectrow_hashref>

=back

=cut
sub selectrow_hashref {
    my $self = shift;
    my $dbh = $self->_getDatabaseHandle;
    return $dbh->selectrow_hashref(@_);
}

=pod

=over 4

=item C<selectall_arrayref>

=back

=cut
sub selectall_arrayref {
    my ($self, @args) = @_;
    my $dbh = $self->_getDatabaseHandle;
    return $dbh->selectall_arrayref(@args);
}

=pod

=over 4

=item C<selectall_hashref>

=back

=cut
sub selectall_hashref {
    my ($self, @args) = @_;
    my $dbh = $self->_getDatabaseHandle;
    return $dbh->selectall_hashref(@args);
}

=pod

=over 4

=item C<selectcol_arrayref>

=back

=cut
sub selectcol_arrayref {
    my ($self, @args) = @_;
    my $dbh = $self->_getDatabaseHandle;
    return $dbh->selectcol_arrayref(@args);
}

=pod

=over 4

=item C<quote>

=back

=cut
sub quote {
    my ($self, @args) = @_;
    my $dbh = $self->_getDatabaseHandle;
    return $dbh->quote(@args);
}

=pod

=over 4

=item C<commit>

=back

=cut
sub commit {
    my ($self) = @_;
    my $dbh = $self->_getDatabaseHandle;
    if ($dbh) {
        return $dbh->commit;
    }
    return undef;
}

=pod

=over 4

=item C<begin_work>

=back

=cut
sub begin_work {
    my $self = shift;
    my $dbh = $self->_getDatabaseHandle;
    if ($dbh) {
        return $dbh->begin_work;
    }
    return undef;        
}

=pod

=over 4

=item C<rollback>

=back

=cut
sub rollback {
    my $self = shift;
    my $dbh = $self->_getDatabaseHandle;
    if ($dbh) {
        return $dbh->rollback;
    }
    return undef;        
}

=pod

=over 4

=item C<ping>

=back

=cut
sub ping {
    my ($self) =@_;
    my $dbh = $self->_getDatabaseHandle;
    return undef unless $dbh;

    return $dbh->ping;
}

# =pod

# =head2 getLastInsertId($catalog, $schema, $table, $field, \%attr)

# Returns a value identifying the row just inserted, if possible.
# If using DBI version 1.38 or later, this method calls
# last_insert_id() on the underlying DBI object.  Otherwise, does a
# "SELECT LAST_INSERT_ID()", which is MySQL specific.  The
# parameters passed to this method are driver-specific.  See the
# documentation on DBI for details.

# get_last_insert_id() and last_insert_id() are aliases for this
# method.

# =cut

# bah, DBI's last_insert_id is not working for me, so for
# now this will be MySQL only

=pod

=head2 C<getLastInsertId()>, C<get_last_insert_id()>, C<last_insert_id()>

Returns the last_insert_id.  The default is to be MySQL
specific.  It just runs the query C<"SELECT LAST_INSERT_ID()">.
However, it will also work with MSSQL with the right parameters
(see the db_style parameter in the section explaining the
C<connect()> method).

=cut
sub getLastInsertId {
    my ($self, $catalog, $schema, $table, $field, $attr) = @_;
    if (0 and DBI->VERSION >= 1.38) {
        my $dbh = $self->_getDatabaseHandle;
        return $dbh->last_insert_id($catalog, $schema, $table, $field, $attr);
    } else {
        my $query;
        my $db_style = $self->_getDbStyle;
        my $dbd_driver = $self->_getDbdDriver;
        if (defined($db_style) and $db_style ne '') {
            $query = $self->_get_query_for_last_insert_id($db_style);
        } elsif (defined($dbd_driver) and $dbd_driver ne '') {
            $query = $self->_get_query_for_last_insert_id($dbd_driver);
        } else {
            $query = qq{SELECT LAST_INSERT_ID()};
        }
            
        my $row = $self->nativeSelectWithArrayRef($query);
        if ($row and @$row) {
            return $$row[0];
        }

        return undef;
    }
}

*get_last_insert_id = \&getLastInsertId;
*last_insert_id = \&getLastInsertId;

sub _get_query_for_last_insert_id {
    my ($self, $db_style) = @_;
    my $query;

    $db_style = lc($db_style);
    if ($db_style eq 'mssql' or $db_style eq 'sybase' or $db_style eq 'asa'
        or $db_style eq 'asany') {
        $query = q{select @@IDENTITY};
    } elsif ($db_style eq 'mysql') {
        $query = qq{SELECT LAST_INSERT_ID()};
    } elsif ($db_style eq 'sqlite') {
        $query = qq{SELECT last_insert_rowid()};
    } else {
        $query = qq{SELECT LAST_INSERT_ID()};
    }

    return $query;
}

sub debug_dump {
    my $self = shift;
    my $var = shift;
    my $data = $self->_get_i_data;
    require Data::Dumper;
    if (defined($var)) {
        return Data::Dumper->Dump([ $data ], [ $var ]);
    } else {
        return Data::Dumper::Dumper($data);
    }
}
*debugDump = \&debug_dump;

# version 0.22
sub unix_to_mysql_timestamp {
    my $self = shift;
    my $unix_ts = shift;

    $unix_ts = time() unless defined $unix_ts;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($unix_ts);
    $mon++;
    $year += 1900 unless $year > 1000;

    return sprintf "%04d%02d%02d%02d%02d%02d", $year, $mon, $mday, $hour, $min, $sec;
}

# version 0.22
sub unix_to_mysql_date_time {
    my $self = shift;
    my $unix_ts = shift;

    $unix_ts = time() unless defined $unix_ts;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($unix_ts);
    $mon++;
    $year += 1900 unless $year > 1000;

    return sprintf "%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec;
    
}

# version 0.22
sub query_oracle_date_as_mysql_timestamp {
    my $self = shift;
    my $field = shift;
    my $as = shift;

    my $sf_field = $self->_quote_field_name($field);
    my $sf_as = $self->_quote_field_name($as);
    my $query = qq{TO_CHAR($sf_field,'YYYYMMDDHH24MISS') AS $sf_as};
    return \$query;
}

=pod

=head2 Hooks

C<DBIx::Wrapper> supports hooks that get called just before and just
after various query operations.  The add*Hook methods take a
single argument that is either a code reference (e.g., anonymous
subroutine reference), or an array whose first element is an
object and whose second element is the name of a method to call
on that object.

The hooks will be called with a request object as the first
argument.  See L<DBIx::Wrapper::Request>.

The two expected return values are C<$request-E<gt>OK> and
C<$request-E<gt>DECLINED>.  The first tells C<DBIx::Wrapper> that the
current hook has done everything that needs to be done and
doesn't call any other hooks in the stack for the current
request.  C<DECLINED> tells C<DBIx::Wrapper> to continue down the
hook stack as if the current handler was never invoked.

See L<DBIx::Wrapper::Request> for example hooks.

=cut

=pod

=head3 C<addPrePrepareHook($hook)>

Specifies a hook to be called just before any SQL statement is
prepare()'d.

=cut
sub addPrePrepareHook {
    my $self = shift;
    my $handler = shift;
    push @{ $self->_get_i_val('_pre_prepare_hooks') }, [ $handler ];
}

*add_pre_prepare_handler = \&addPrePrepareHook;
*addPrePrepareHandler = \&addPrePrepareHook;
*add_pre_prepare_hook = \&addPrePrepareHook;

=pod

=head3 C<addPostPrepareHook($hook)>

Specifies a hook to be called just after any SQL statement is
prepare()'d.

=cut
sub addPostPrepareHook {
    my $self = shift;
    my $handler = shift;
    push @{ $self->_get_i_val('_post_prepare_hooks') }, [ $handler ];
}

*add_post_prepare_hook = \&addPostPrepareHook;

=pod

=head3 C<addPreExecHook($hook)>

Specifies a hook to be called just before any SQL statement is
execute()'d.

=cut
sub addPreExecHook {
    my $self = shift;
    my $handler = shift;
    push @{ $self->_get_i_val('_pre_exec_hooks') }, [ $handler ];
}

*add_pre_exec_hook = \&addPreExecHook;

=pod

=head3 C<addPostExecHook($hook)>

Adds a hook to be called just after a statement is execute()'d.

=cut
sub addPostExecHook {
    my $self = shift;
    my $handler = shift;
    push @{ $self->_get_i_val('_post_exec_hooks') }, [ $handler ];
}

*add_post_exec_handler = \&addPostExecHook;
*addPostExecHandler = \&addPostExecHook;
*add_post_exec_hook = \&addPostExecHook;

=pod

=head3 C<addPreFetchHook($hook)>

Adds a hook to be called just before data is fetch()'d from the server.

=cut
sub addPreFetchHook {
    my $self = shift;
    my $handler = shift;
    push @{ $self->_get_i_val('_pre_fetch_hooks') }, [ $handler ];
}

*add_pre_fetch_hook = \&addPreFetchHook;
*addPreFetchHandler = \&addPreFetchHook;

=pod

=head3 C<addPostFetchHook($hook)>

Adds a hook to be called just after data is fetch()'d from the server.

=cut
sub addPostFetchHook {
    my $self = shift;
    my $handler = shift;
    push @{ $self->_get_i_val('_post_fetch_hooks') }, [ $handler ];
}

*addPostFetchHandler = \&addPostFetchHook;

sub _to_csv_line {
    my $cols = shift;
    my $sep = shift;
    my $quote = shift;
    
    $sep = "," unless defined($sep);
    $quote = "\"" unless defined($quote);

    my $sf_sep = quotemeta($sep);
    my $sf_quote = quotemeta($quote);

    my @sf_cols;
    foreach my $col (@$cols) {
        if (index($col, $sep) >= 0 or index($col, $quote) >= 0) {
            $col =~ s/$sf_quote/$quote$quote/g;
            $col = $quote . $col . $quote;
        }
        push @sf_cols, $col;
    }

    return join($sep, @sf_cols);
}

=pod

=head2 Convenience methods

=cut

=pod

=head3 C<to_csv($rows, \%params);>

Convert the given query result rows in C<@rows> to a CSV string.
If each row is a hash, a header row will be included by the
default giving the column names.  This method also supports rows
as arrays, as well as C<$rows> itself being a hash ref.

Valid parameters in C<%params>:

=over 4

=item C<sep>

The separator to use between columns.

=item C<quote>

The quote to use in cases where values contain the separator.
If a quote is found in a value, it is converted to two quotes
and then the whole value is quoted.

=item C<no_header>

If set to a true value, do not output the header row containing
the column names.

=back


Aliases: toCsv()

=cut
sub to_csv {
    my $self = shift;
    my $rows = shift;
    my $params = shift || {};

    my $sep = $params->{sep};
    my $quote = $params->{quote};
    my $no_header = $params->{no_header};

    my $csv = '';
    
    if (reftype($rows) eq 'ARRAY') {
        return '' unless @$rows;

        my $first_row = $rows->[0];
        
        if (reftype($first_row) eq 'HASH') {
            my @fields = sort keys %$first_row;
            
            unless ($no_header) {
                $csv .= _to_csv_line(\@fields, $sep, $quote) . "\n";
            }
            
            foreach my $row (@$rows) {
                $csv .= _to_csv_line([ map { $row->{$_} } @fields ], $sep, $quote) . "\n";
            }
        } elsif (reftype($first_row) eq 'ARRAY') {
            foreach my $row (@$rows) {
                $csv .= _to_csv_line($row, $sep, $quote) . "\n";
            }
        }
    }
    elsif (reftype($rows) eq 'HASH') {
        my $row = $rows;
        my @fields = sort keys %$row;
        unless ($no_header) {
            $csv .= _to_csv_line(\@fields, $sep, $quote) . "\n";
        }
        
        $csv .= _to_csv_line([ map { $row->{$_} } @fields ], $sep, $quote) . "\n";
    }
    else {
        # error
        return;
    }

    return $csv;
}
*toCsv = \&to_csv;

sub _hash_to_xml {
    my $self = shift;
    my $hash = shift;
    my $indent = shift;

    my $xml = '';
    my @keys = sort keys %$hash;
    foreach my $key (@keys) {
        $xml .= ' ' x 4 if $indent;
        $xml .= '<' . $key . '>' . $self->escape_xml($hash->{$key}) . '</' . $key . '>';
        $xml .= "\n" if $indent;
    }
    
    return $xml;
}

=pod

=head3 C<to_xml($data, \%params)>

Converts C<$data> to xml.  $data is expected to be either a hash
ref or a reference to an array of hash refs.  If C<$data> is an
array ref, enclosing tags are put around each record.  The tags
are named "record" by default but can be changed by specifying
record_tag in C<%params>.  If C<$params{indent}> is set to a true
value, tags will be indented and unix newlines inserted.  This
method does not output an encoding specification, e.g.,

=for pod2rst next-code-block: xml

     <?xml version="1.0" encoding="utf-8"?>

Aliases: toXml()

=cut
sub to_xml {
    my $self = shift;
    my $rows = shift;
    my $params = shift || {};

    my $indent = $params->{indent};
    my $record_tag_name = $params->{record_tag};
    unless (defined($record_tag_name)) {
        $record_tag_name = 'record';
    }

    if (reftype($rows) eq 'ARRAY') {
        return '' unless @$rows;

        my $xml = '';
        foreach my $row (@$rows) {
            $xml .= '<' . $record_tag_name . '>';
            $xml .= "\n" if $indent;
            $xml .= _hash_to_xml($self, $row, $indent);
            $xml .= '</' . $record_tag_name . '>';
            $xml .= "\n" if $indent;

        }

        return $xml;
    } elsif (reftype($rows) eq 'HASH') {
        return _hash_to_xml($self, $rows);
    }

    return;
}

sub escape_xml {
    my $self = shift;
    my $text = shift;
    return '' unless defined $text;
        
    $text =~ s/\&/\&amp;/g;
    $text =~ s/</\&lt;/g;
    $text =~ s/>/\&gt;/g;
    # $text =~ s/\"/\&quot;/g;

    return $text;
}

*toXml = \&to_xml;

=pod

=head3 C<bencode($data)>

Returns the bencoded representation of C<$data> (arbitrary
datastructure -- but not objects).  This module extends the
bencode scheme to support undef.  See
L<http://en.wikipedia.org/wiki/Bencode> for details on the bencode
encoding.

Aliases: bEncode()

=cut
sub bencode {
    my $self = shift;
    my $to_encode = shift;

    unless (defined($to_encode)) {
        return 'n';
    }

    my $encoded = '';
    my $type = reftype($to_encode);

    unless ($type) {
        $encoded .= length($to_encode) . ':' . $to_encode;
        return $encoded;
    }
    
    if ($type eq 'HASH') {
        $encoded .= 'd';
        foreach my $key (sort keys %$to_encode) {
            $encoded .= $self->bencode($key);
            $encoded .= $self->bencode($to_encode->{$key});
        }
        $encoded .= 'e';
    }
    elsif ($type eq 'ARRAY') {
        $encoded .= 'l';
        foreach my $element (@$to_encode) {
            $encoded .= $self->bencode($element);
        }
        $encoded .= 'e';
    }
    elsif ($to_encode =~ /\A\d+\Z/) {
        $encoded .= 'i' . $to_encode . 'e';
    }

    return $encoded;
}

*bEncode = \&bencode;

=pod

=head3 C<bdecode($encoded_str)>

The opposite of C<bencode()>.  Returns the deserialized data from
the bencoded string.

Aliases: bDecode()

=cut
sub bdecode {
    my $self = shift;
    my $to_decode = shift;

    return $self->_bdecode(\$to_decode);
}

*bDecode = \&bdecode;

sub _bdecode {
    my $self = shift;
    my $str_ref = shift;
    
    if ($$str_ref =~ m/\A(\d+):/) {
        my $length = $1;
        my $val = substr($$str_ref, length($1) + 1, $length);
        substr($$str_ref, 0, length($1) + 1 + $length) = '';

        return $val;
    }
    elsif ($$str_ref =~ s/\A(.)//) {
        my $letter = $1;
        if ($letter eq 'n') {
            return undef;
        }
        elsif ($letter eq 'i') {
            $$str_ref =~ s/\A(\d+)e//;
            return $1;
        }
        elsif ($letter eq 'l') {
            my @list;
            while ($$str_ref !~ m/\Ae/ and $$str_ref ne '') {
                push @list, $self->_bdecode($str_ref);
            }
            $$str_ref =~ s/\Ae//;

            return \@list;
        }
        elsif ($letter eq 'd') {
            my %hash;
            while ($$str_ref !~ m/\Ae/ and $$str_ref ne '') {
                my $key = $self->_bdecode($str_ref);
                $hash{$key} = $self->_bdecode($str_ref);
            }
            $$str_ref =~ s/\Ae//;

            return \%hash;
        }
    }
    
    return;
}

=pod

=head3 C<to_json($data)>

Returns the JSON representation of C<$data> (arbitrary
datastructure -- but not objects).  See http://www.json.org/ or
http://en.wikipedia.org/wiki/JSON for details.  In this
implementation, hash keys are sorted so that the output is
consistent.

=cut
sub to_json {
    my $self = shift;
    my $data = shift;

    return 'null' unless defined $data;
    
    my $type = reftype($data);
    unless (defined($type)) {
        return $self->_escape_json_str($data);
    }
    
    if ($type eq 'ARRAY') {
        return '[' . join(',', map { $self->to_json($_) } @$data) . ']';
    }
    elsif ($type eq 'HASH') {
        my @keys = sort keys %$data;
        return '{' . join(',', map { $self->_escape_json_str($_) . ':'
                                         . $self->to_json($data->{$_}) } @keys ) . '}';
    }
    else {
        return $self->_escape_json_str($data);
    }
}
*toJson = \&to_json;

sub _escape_json_str {
    my $self = shift;
    my $str = shift;

    return 'null' unless defined $str;

    # \b means word boundary in a regex, so create it here in a
    # string, then interpolate
    my $backspace = quotemeta("\b");

    $str =~ s{([\"\\/])}{\\$1}g;
    $str =~ s{$backspace}{\\b}g;
    $str =~ s{\f}{\\f}g;
    $str =~ s{\x0a}{\\n}g;
    $str =~ s{\x0d}{\\r}g;
    $str =~ s{\t}{\\t}g;
    $str =~ s{([^\x00-\xff])}{sprintf "\\u%04x", ord($1)}eg;

    return '"' . $str . '"';
}

sub from_json {
    my $self = shift;

    return _parse_json($_[0]);
}

{
    my $to_parse;
    my $len;
    my $char;
    my $pos;
    my $looking_at;
    my $json_warn = 1;

    my $json_escape_map = { b => "\b",
                            t => "\t",
                            n => "\x0a",
                            r => "\x0d",
                            f => "\x0c",
                            '\\' => '\\',
                          };

    my $json_bareword_map = { true => 1,
                              false => 0,
                              null => undef,
                            };
    
    sub _parse_json {
        $to_parse = shift;
        $len = length($to_parse);
        $char = '';
        $pos = 0;
        $looking_at = -1;

        return _parse_json_parse_value();
    }

    sub _parse_json_next_char {
        return $char = undef if ($pos >= $len);
        $char = substr($to_parse, $pos, 1);
        $looking_at = $pos;
        $pos++;
        
        return $char;
    }

    sub _parse_json_peek {
        my $count = shift;
        if ($count > $len - $pos) {
            return $char = substr($to_parse, $pos, $len - $pos);
        }
        return $char = substr($to_parse, $pos + 1, $count);
    }

    # eat whitespace and comments
    sub _parse_json_eat_whitespace {
        while (defined($char)) {
            if ($char =~ /\s/ or $char eq '') {
                _parse_json_next_char();
            }
            elsif ($char eq '/') {
                _parse_json_next_char();
                if ($char eq '/') {
                    # single line comment
                    1 while (defined(_parse_json_next_char()) and $char ne "\n" and $char ne "\r");
                }
                elsif ($char eq '*') {
                    # multiple line comment
                    _parse_json_next_char();
                    while (1) {
                        unless (defined($char)) {
                            # error - unterminated comment
                            last;
                        }

                        if ($char eq '*') {
                            if (defined(_parse_json_next_char()) and $char eq '/') {
                                _parse_json_next_char();
                                last;
                            }
                        }
                        else {
                            _parse_json_next_char();
                        }
                        
                    }
                    next;
                }
                else {
                    # error -- syntax error with comment -- can't have '/' by itself
                }
            }
            else {
                last;
            }
        }
    }
    
    sub _parse_json_parse_string {
        unless ($char eq '"' or $char eq "'") {
            warn "bad string at pos $looking_at, char=$char";
            return;
        }

        my $boundary = $char;
        my $str = '';
        my $start_pos = $looking_at;

        while ( defined(_parse_json_next_char()) ) {
            if ($char eq $boundary) {
                _parse_json_next_char();
                return $str;
            }
            elsif ($char eq '\\') {
                _parse_json_next_char();
                if (exists($json_escape_map->{$char})) {
                    $str .= $json_escape_map->{$char};
                }
                elsif ($char eq 'u') {
                    my $u = '';

                    for (1 .. 4) {
                        _parse_json_next_char();

                        if ($char !~ /[0-9A-Fa-f]/) {
                            # error -- bad unicode specifier
                            if ($json_warn) {
                                warn "bad unicode specifier at pos $looking_at, char=$char";
                            }
                            last;
                        }
                        $u .= $char;
                    }

                    my $full_char = chr(hex($u));
                    $str .= $full_char;
                }
                else {
                    $str .= $char;
                }
            }
            else {
                $str .= $char;
            }
        }

        # error -- unterminated string
        warn "unterminated string starting at $start_pos";
    }

    sub _parse_json_parse_object {
        return unless $char eq '{';

        my $obj = {};
        my $key;
        
        _parse_json_next_char();
        _parse_json_eat_whitespace();
        if ($char eq '}') {
            _parse_json_next_char();
            return $obj;
        }

        while (defined($char)) {
            $key = _parse_json_parse_string();
            _parse_json_eat_whitespace();
            
            unless ($char eq ':') {
                last;
            }

            _parse_json_next_char();
            _parse_json_eat_whitespace();
            $obj->{$key} = _parse_json_parse_value();
            _parse_json_eat_whitespace();

            if ($char eq '}') {
                _parse_json_next_char();
                return $obj;
            }
            elsif ($char eq ',') {
                _parse_json_next_char();
                _parse_json_eat_whitespace();
            }
            else {
                last;
            }
        }

        warn "bad object at pos $looking_at, char=$char" if $json_warn;
    }

    sub _parse_json_parse_array {
        return unless $char eq '[';
        my @array;
        my $val;

        _parse_json_next_char();
        _parse_json_eat_whitespace();
        if ($char eq ']') {
            return \@array;
        }

        while (defined($char)) {
            $val = _parse_json_parse_value();
            push @array, $val;
            _parse_json_eat_whitespace();
            if ($char eq ']') {
                _parse_json_next_char();
                return \@array;
            }
            elsif ($char eq ',') {
                _parse_json_next_char();
                _parse_json_eat_whitespace();
            }
            else {
                last;
            }
        }

        warn "bad array: pos $looking_at, char=$char" if $json_warn;
        return;
    }

    sub _parse_json_parse_number {
        my $num = '';

        if ($char eq '0') {
            $num .= $char;
            my $hex = _parse_json_peek(1) =~ /[Xx]/;
            _parse_json_next_char();
            
            while (defined($char) and $char !~ /[[:space:],\}\]:]/) {
                $num .= $char;
                _parse_json_next_char();
            }

            return $hex ? hex($num) : oct($num);
        }

        while (defined($char) and $char !~ /[[:space:],\}\]:]/) {
            $num .= $char;
            _parse_json_next_char();
        }

        return 0 + $num;
    }

    sub _parse_json_parse_word {
        my $word = '';
        while ($char !~ /[[:space:]\]\},:]/) {
            $word .= $char;
            _parse_json_next_char();
        }

        if (exists($json_bareword_map->{$word})) {
            return $json_bareword_map->{$word};
        }

        warn "syntax error at char $looking_at: char='$char', word='$word'" if $json_warn;
        return;
    }

    sub _parse_json_parse_value {
        _parse_json_eat_whitespace();
        return unless defined($char);
        return _parse_json_parse_object() if $char eq '{';
        return _parse_json_parse_array() if $char eq '[';
        return _parse_json_parse_string() if $char eq '"' or $char eq "'";
        return _parse_json_parse_number() if $char eq '-';
        return $char =~ /\d/ ? _parse_json_parse_number() : _parse_json_parse_word();
    }

}

sub _do_benchmark {
    my $self = shift;
    
    require Benchmark;
    my $data = { _dbh => 'dummy' };
    
    my $results = Benchmark::cmpthese(1000000, {
                                'Plain hash' => sub { my $val = $data->{_dbh} },
                                'Indirect hash' => sub { my $val = $i_data{ refaddr($self) }{_dbh} },
                               }
                                      );

}

sub AUTOLOAD {
    my $self = shift;

    (my $func = $AUTOLOAD) =~ s/^.*::([^:]+)$/$1/;
        
    no strict 'refs';

    if (ref($self)) {
        my $dbh = $self->_getDatabaseHandle;
        return $dbh->$func(@_);
    } else {
        return DBI->$func(@_);
    }
}

=pod

=head2 There are also underscore_separated versions of these methods.

E.g., C<nativeSelectLoop()> becomes C<native_select_loop()>

=head1 DEPENDENCIES

DBI

=head1 ACKNOWLEDGEMENTS

Others who have contributed ideas and/or code for this module:

=over 4

=item Kevin Wilson

=item Mark Stosberg

=item David Bushong

=back

=head1 AUTHOR

Don Owens <don@regexguy.com>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2012 Don Owens (don@regexguy.com).  All rights reserved.

This free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See perlartistic.

This program is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.

=head1 SEE ALSO

L<DBI>, perl

=head1 VERSION

0.29

=cut

1;

