use v5.10.1;
package DBD::Neo4p;
use strict;
use warnings;
use REST::Neo4p 0.3010;
use JSON;
require DBI;
no warnings qw/once/;

BEGIN {
 $DBD::Neo4p::VERSION = '0.1004';
}

our $err = 0;               # holds error code   for DBI::err
our $errstr =  '';          # holds error string for DBI::errstr
our $drh = undef;           # holds driver handle once initialised
our $prefix = 'neo';

sub driver($$){
    return $drh if $drh;
    my($sClass, $rhAttr) = @_;
    $sClass .= '::dr';

# install methods if nec.

    DBD::Neo4p::db->install_method('neo_neo4j_version');

    $drh = DBI::_new_drh($sClass,  
        {   
            Name        => $sClass,
            Version     => $DBD::Neo4p::VERSION,
            Err         => \$DBD::Neo4p::err,
            Errstr      => \$DBD::Neo4p::errstr,
            State       => \$DBD::Neo4p::sqlstate,
            Attribution => 'DBD::Neo4p by Mark A. Jensen'
        }
    );
    return $drh;
}

package # hide from PAUSE
  DBD::Neo4p::dr;
$DBD::Neo4p::dr::imp_data_size = 0;

sub connect($$;$$$) {
    my($drh, $sDbName, $sUsr, $sAuth, $rhAttr)= @_;

#1. create database-handle
    my ($outer, $dbh) = DBI::_new_dbh($drh, {
        Name         => $sDbName,
        USER         => $sUsr,
        CURRENT_USER => $sUsr,
    });
    local $REST::Neo4p::HANDLE;
    $dbh->STORE("${prefix}_Handle", REST::Neo4p->create_and_set_handle);
    # default attributes
    $dbh->STORE("${prefix}_ResponseAsObjects",0);

#2. Parse extra strings in DSN(key1=val1;key2=val2;...)
    foreach my $sItem (split(/;/, $sDbName)) {
      my ($key, $value) = $sItem =~ /(.*?)=(.*)/;
      return $drh->set_err($DBI::stderr, "Can't parse DSN part '$sItem'")
            unless defined $value;
      $key = "${prefix}_$key" unless $key =~ /^${prefix}_/;
      $dbh->STORE($key, $value);
    }
    my $db = delete $rhAttr->{"${prefix}_database"} || delete $rhAttr->{"${prefix}_db"};
    my $host = $dbh->FETCH("${prefix}_host") || 'localhost';
    my $port = $dbh->FETCH("${prefix}_port") || 7474;
    my $protocol = $dbh->FETCH("${prefix}_protocol") || 'http';
    my $user =  delete $rhAttr->{Username} || $sUsr;
    my $pass = delete $rhAttr->{Password} || $sAuth;
    if (my $ssl_opts = delete $rhAttr->{SSL_OPTS}) {
      if (REST::Neo4p->agent->isa('LWP::UserAgent')) {
	while (my ($k,$v) = each %$ssl_opts) {
	  REST::Neo4p->agent->ssl_opts($k => $v);
	}
      }
    }
    # use db=<protocol>://<host>:<port> or host=<host>;port=<port>
    # db attribute trumps

    if ($db) {
      ($protocol, $host, $port) = $db =~ m|^(https?)?(?:://)?([^:]+):?([0-9]*)$|;
      $protocol //= 'http';
      return $drh->set_err($DBI::stderr, "DB host and/or port not specified correctly") unless ($host && $port);
    }

    # real connect...

    $db = "$protocol://$host:$port";
    eval {
      REST::Neo4p->connect($db,$user,$pass);
    };
    if (my $e = Exception::Class->caught()) {
      return
	ref $e ? $drh->set_err($DBI::stderr, "Can't connect to $sDbName: ".ref($e)." : ".$e->message.' ('.$e->code.')') :
	  $drh->set_err($DBI::stderr, $e);
    };

    foreach my $sKey (keys %$rhAttr) {
        $dbh->STORE($sKey, $rhAttr->{$sKey});
    }
    $dbh->STORE(Active => 1);
    $dbh->STORE(AutoCommit => 1);
    $dbh->{"${prefix}_agent"} = REST::Neo4p->agent;

    return $outer;
}

sub data_sources ($;$) {
    my($drh, $rhAttr) = @_;
    return;
}

sub disconnect_all($) { }

package #hide from PAUSE
  DBD::Neo4p::db;
$DBD::Neo4p::db::imp_data_size = 0;

sub prepare {
    my($dbh, $sStmt, $rhAttr) = @_;
#1. Create blank sth
    my ($outer, $sth) = DBI::_new_sth($dbh, { Statement   => $sStmt, });
    return $sth unless($sth);

# cypher query parameters are given as tokens surrounded by curly braces:
# crude count:
    my @parms = $sStmt =~ /\{\s*([^}[:space:]]*)\s*\}/g;
    $sth->STORE('NUM_OF_PARAMS', scalar @parms);
    $sth->{"${prefix}_param_names"} = \@parms;
    $sth->{"${prefix}_param_values"} = [];
    return $outer;
}

sub begin_work {
  my ($dbh) = @_;
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($dbh->{"${prefix}_Handle"});
  unless ($dbh->{AutoCommit}) {
    $drh->set_err($DBI::stderr, "begin_work not effective, AutoCommit already off");
    return;
  }
  eval {
    REST::Neo4p->begin_work;
  };
  if ( my $e = REST::Neo4p::VersionMismatchException->caught()) {
    warn("Your neo4j server does not support transactions via REST API") if $dbh->FETCH('Warn');
    return;
  }
  elsif ($e = Exception::Class->caught()) {
    return
      ref $e ? $drh->set_err($DBI::stderr, "Can't begin transaction: ".ref($e)." : ".$e->message.' ('.$e->code.')') :
	$drh->set_err($DBI::stderr, $e);
  };
  $dbh->STORE('AutoCommit',0);
  return 1;
}

sub commit ($) {
    my($dbh) = @_;
    if ($dbh->FETCH('AutoCommit')) {
      warn("Commit ineffective while AutoCommit is on") if $dbh->FETCH('Warn');
      return;
    }
    else {
      local $REST::Neo4p::HANDLE;
      REST::Neo4p->set_handle($dbh->{"${prefix}_Handle"});
      eval {
	REST::Neo4p->commit;
      };
      if ( my $e = REST::Neo4p::VersionMismatchException->caught()) {
	warn("Your neo4j server does not support REST transactions") if $dbh->FETCH('Warn');
	return;
      }
      elsif ($e = Exception::Class->caught()) {
	return
	  ref $e ? $drh->set_err($DBI::stderr, "Can't commit: ".ref($e)." : ".$e->message.' ('.$e->code.')') :
	    $drh->set_err($DBI::stderr, $e);
      };
      return 1;
    }
}

sub rollback ($) {
    my($dbh) = @_;
    if ($dbh->FETCH('AutoCommit')) {
      warn("Rollback ineffective while AutoCommit is on") if $dbh->FETCH('Warn');
      return;
    }
    else {
      local $REST::Neo4p::HANDLE;
      REST::Neo4p->set_handle($dbh->{"${prefix}_Handle"});
      eval {
	REST::Neo4p->rollback;
      };
      if ( my $e = REST::Neo4p::VersionMismatchException->caught()) {
	warn("Your neo4j server does not support REST transactions") if $dbh->FETCH('Warn');
	return;
      }
      elsif ($e = Exception::Class->caught()) {
	return
	  ref $e ? $drh->set_err($DBI::stderr, "Can't rollback: ".ref($e)." : ".$e->message.' ('.$e->code.')') :
	    $drh->set_err($DBI::stderr, $e);
      };
      return 1;
    }
}

sub ping {
  my $dbh = shift;
  my $s = ($dbh->neo_neo4j_version =~ /^3\.0/ ? 'match (a) return a limit 1' :
	     'return 1');
  my $sth = $dbh->prepare($s) or return 0;
  $sth->execute or return 0;
  $sth->finish;
  return 1;
}

# neo4j metadata -- needs thinking
# v2.0 : http://docs.neo4j.org/chunked/2.0.0-M06/rest-api-cypher.html#rest-api-retrieve-query-metadata

sub neo_neo4j_version {
  my $dbh = shift;
  return $dbh->{"${prefix}_agent"}->{_actions}{neo4j_version};
}


# table_info is a nop

sub table_info ($) {
    my($dbh) = @_;
# -->> Change
    my ($raTables, $raName) = (undef, undef);
# <<-- Change
    return undef unless $raTables;
# 2. create DBD::Sponge driver
    my $dbh2 = $dbh->{'_sponge_driver'};
    if (!$dbh2) {
        $dbh2 = $dbh->{'_sponge_driver'} = DBI->connect("DBI:Sponge:");
        if (!$dbh2) {
            $dbh->DBI::set_err( 1, $DBI::errstr);
            return undef;
            $DBI::errstr .= ''; #Just for IGNORE warning
        }
    }
#3. assign table info to the DBD::Sponge driver
    my $sth = $dbh2->prepare("TABLE_INFO",
            { 'rows' => $raTables, 'NAMES' => $raName });
    if (!$sth) {
        $dbh->DBI::set_err(1, $dbh2->errstr());
    }
    return  $sth;
}

sub type_info_all ($) {
    my ($dbh) = @_;
    return [];
}

sub disconnect ($) {
    my ($dbh) = @_;
    REST::Neo4p->disconnect_handle($dbh->{"${prefix}_Handle"});
    $dbh->STORE(Active => 0);
    1;
}

sub FETCH ($$) {
  my ($dbh, $sAttr) = @_;
  use experimental qw/smartmatch/;
  given ($sAttr) {
    when ('AutoCommit') { return $dbh->{$sAttr} }
    when (/^${prefix}_/) { return $dbh->{$sAttr} }
    default { return $dbh->SUPER::FETCH($sAttr) }
  }
}

sub STORE ($$$) {
  my ($dbh, $sAttr, $sValue) = @_;
  use experimental qw/smartmatch/;
  given ($sAttr) {
    when ('AutoCommit') {
      local $REST::Neo4p::HANDLE = $dbh->{"${prefix}_Handle"};
      if (!!$sValue) {
	REST::Neo4p->_set_autocommit;
	$dbh->{$sAttr} = 1;
      }
      else {
	$dbh->{$sAttr} = 0 if REST::Neo4p->_clear_autocommit;
      }
      return 1;
    }
    # private attributes (neo_)
    when (/^${prefix}_/) {
      $dbh->{$sAttr} = $sValue;
      return 1;
    }
    default {
      return $dbh->SUPER::STORE($sAttr => $sValue);
    }
  }
}

sub DESTROY($) {
  my($dbh) = @_;
  # deal with the REST::Neo4p object
}

package #hide from PAUSE
  DBD::Neo4p::st;
$DBD::Neo4p::st::imp_data_size = 0;

sub bind_param ($$$;$) {
  my($sth, $param, $value, $attribs) = @_;
  return $sth->DBI::set_err(2, "Can't bind_param $param, too big")
    if ($param > $sth->FETCH('NUM_OF_PARAMS'));
  $sth->{"${prefix}_param_values"}->[$param-1] = $value;
  return 1;
}

sub execute($@) {
  my ($sth, @bind_values) = @_;

  $sth->finish if $sth->{Active}; # DBI::DBD example, follow up...

  my $params = @bind_values ? \@bind_values : $sth->{"${prefix}_param_values"};
  unless (@$params == $sth->FETCH('NUM_OF_PARAMS')) {
    return $sth->set_err($DBI::stderr, "Wrong number of parameters");
  }
  # Execute
  # by this time, I know all my parameters
  # so create the Query obj here
  local $REST::Neo4p::HANDLE = $sth->{Database}->{"${prefix}_Handle"};

  # per DBI spec, begin work under the hood if AutoCommit is FALSE:
  unless ($sth->{Database}->FETCH('AutoCommit')) {
    unless (REST::Neo4p->_transaction) {
      REST::Neo4p->begin_work;
    }
  }

  my %params;
  @params{@{$sth->{"${prefix}_param_names"}}} = @$params;
  my $q = $sth->{"${prefix}_query_obj"} = REST::Neo4p::Query->new(
    $sth->{Statement}, \%params
   );
  $q->{ResponseAsObjects} = $sth->{Database}->{"${prefix}_ResponseAsObjects"};

  my $numrows = $q->execute;
  if ($q->err) {
    return $sth->set_err($DBI::stderr,$q->errstr.' ('.$q->err.')');
  }

  $sth->{"${prefix}_rows"} = $numrows;
  # don't know why I have to do the following, when the FETCH 
  # method delegates this to the query object and $sth->{NUM_OF_FIELDS}
  # thereby returns the correct number, but $sth->_set_bav($row) segfaults
  # if I don't:
  $sth->STORE(NAME => $q->{NAME});
  $sth->STORE(NUM_OF_FIELDS => 0);
  $sth->STORE(NUM_OF_FIELDS => $q ? $q->{NUM_OF_FIELDS} : undef);

  $sth->{Active} = 1;
  return $numrows || '0E0';
}

sub fetch ($) {
  my ($sth) = @_;
  my $q =$sth->{"${prefix}_query_obj"};
  unless ($q) {
    return $sth->set_err($DBI::stderr, "Query not yet executed");
  }
  my $row;
  eval {
    $row = $q->fetch;
  };
  if (my $e = Exception::Class->caught) {
    $sth->finish;
    return $sth->set_err($DBI::stderr, ref $e ? ref($e)." : ".$e->message : $e);
  }
  if ($q->err) {
    $sth->finish;
    return $sth->set_err($DBI::stderr,$q->errstr.' ('.$q->err.')');
  }
  
  unless ($row) {
    $sth->STORE(Active => 0);
    return undef;
  }
  $sth->STORE(NAME => $q->{NAME});
  $sth->STORE(NUM_OF_FIELDS => $q->{NUM_OF_FIELDS});
  $sth->_set_fbav($row);
}

*fetchrow_arrayref = \&fetch;

# override fetchall_hashref - create a sensible hash key from node, 
# relationship structures
sub fetchall_hashref {
  my ($sth, $key_field) = @_;
  my @keys;
  push @keys, ref $key_field ? @{$key_field} : $key_field;
  my @names = @{$sth->FETCH($sth->{Database}->{FetchHashKeyName})};
  for my $key (@keys) {
    my $qkey = quotemeta $key;
    unless (grep(/^$qkey$/, @names)) {
      return $sth->set_err($DBI::stderr, "'$key_field' not a column name");
    }

  }
  my $rows = $sth->fetchall_arrayref;
  my $ret = {};
  return unless $rows;
  use experimental qw/smartmatch/;
  for my $row (@$rows) {
    my %data;
    @data{@names} = @$row;
    my $h = $ret;
    for my $k (@keys) {
      my $key_from_data;
      given (ref $data{$k}) {
	when (!$_) {
	  $key_from_data = $data{$k};
	}
	when (/REST::Neo4p/) {
	  $key_from_data = ${$data{$k}}; # id
	}
	when (/HASH|ARRAY/) {
	  $key_from_data = $data{$k}{_node} || $data{$k}{_relationship};
	  $key_from_data = JSON->new->utf8->encode($data{$k}) unless $key_from_data;
	}
	default {
	  die "whaaa? (fetchall_hashref)";
	}
      }
      $h->{$key_from_data} = {};
      $h = $h->{$key_from_data};
    }
    for my $n (@names) {
      my $qn = quotemeta $n;
      next if grep /^$qn$/,@keys;
      $h->{$n} = $data{$n};
    }
  }

  return $ret;
}
sub rows ($) {
  my($sth) = @_;
  return $sth->{"${prefix}_rows"};
}

sub finish ($) {
  my ($sth) = @_;
  $sth->{"${prefix}_query_obj"}->finish()
    if (defined($sth->{"${prefix}_query_obj"}));
  $sth->{"${prefix}_query_obj"} = undef;
  $sth->STORE(Active => 0);
  $sth->SUPER::finish();
  return 1;
}

sub FETCH ($$) {
  my ($sth, $attrib) = @_;
  my $q =$sth->{"${prefix}_query_obj"};
  use experimental qw/smartmatch/;
  given ($attrib) {
    when ('TYPE') {
      return;
    }
    when ('PRECISION') {
      return;
    }
    when ('SCALE') {
      return;
    }
    when ('NULLABLE') {
      return;
    }
    when ('RowInCache') {
      return;
    }
    when ('CursorName') {
      return;
    }
    # Private driver attributes have neo_ prefix
    when (/^${prefix}_/) {
      return $sth->{$attrib}
    }
    default {
      return $sth->SUPER::FETCH($attrib)
    }
  }
}

sub STORE ($$$) {
  my ($sth, $attrib, $value) = @_;
  use experimental qw/smartmatch/;
  #1. Private driver attributes have neo_ prefix
  given ($attrib) {
    when (/^${prefix}_|(?:NAME$)/) { 
      $sth->{$attrib} = $value;
      return 1;
    }
    default {
      return $sth->SUPER::STORE($attrib, $value);
    }
  }
}

sub DESTROY {
  my ($sth) = @_;
  undef $sth->{"${prefix}_query_obj"};
}

#>> Just for no warning-----------------------------------------------
$DBD::Neo4p::dr::imp_data_size = 0;
$DBD::Neo4p::db::imp_data_size = 0;
$DBD::Neo4p::st::imp_data_size = 0;
*DBD::Neo4p::st::fetchrow_arrayref = \&DBD::Neo4p::st::fetch;
#<< Just for no warning------------------------------------------------
1;
__END__

=head1 NAME

DBD::Neo4p - A DBI driver for Neo4j via REST::Neo4p

=head1 SYNOPSIS

 use DBI;
 my $dbh = DBI->connect("dbi:Neo4p:http://127.0.0.1:7474;user=foo;pass=bar");
 my $q =<<CYPHER;
 START x = node:node_auto_index(name= { startName })
 MATCH path =(x-[r]-friend)
 WHERE friend.name = { name }
 RETURN TYPE(r)
 CYPHER
 my $sth = $dbh->prepare($q);
 $sth->execute("I", "you"); # startName => 'I', name => 'you'
 while (my $row = $sth->fetch) {
   print "I am a ".$row->[0]." friend of yours.\n";
 }

=head1 DESCRIPTION

L<DBD::Neo4p> is a L<DBI>-compliant wrapper for L<REST::Neo4p::Query>
that allows for the execution of Neo4j Cypher language queries against
a L<Neo4j|http://neo4j.org> graph database.

L<DBD::Neo4p> requires L<REST::Neo4p> v0.2220 or greater.

=head1 Functions

=head2 Driver Level

=over

=item connect

 my $dbh = DBI->connect("dbi:Neo4p:db=http://127.0.0.1:7474");
 $dbh = DBI->connect("dbi:Neo4p:host=127.0.0.1;port=7474");
 $dbh = DBI->connect("dbi:Neo4p:db=http://127.0.0.1:7474",$user,$pass);
 $dbh = DBI->connect("dbi:Neo4p:db=http://127.0.0.1:7474",
                      { Username => 'me', Password => 's3kr1t'};

=back

=head2 Database Level

=over 

=item prepare, prepare_cached

 $sth = $dbh->prepare("START n = node(0) RETURN n");
 $sth = $dbh->prepare("START n = node(0) MATCH n-()->m".
                      "WHERE m.name = { name } RETURN m");

Prepare a Cypher language statement. In Cypher, parameters are named
and surrounded by curly brackets.

The driver captures the parameters and treats them as numbered in the
order they appear in the statement (per L<DBI> spec). An array of
parameter names in order can be obtained from the statement handle:

 @param_names = @{$sth->{neo_param_names}};

=item begin_work

=item commit

=item rollback

Transaction support requires L<Neo4j|http://neo4j.org> server version
2.0.0 or greater. The driver will return with error set if your server
can't handle transactions (per L<DBI> spec).

=item disconnect

 $dbh->disconnect

=item table_info

=item type_info

Not currently implemented. Neo4j is basically typeless, and does not
have tables. In Neo4j version 2.0 servers, node labels and indexes
allow a schema-like constraint system (see
L<http://docs.neo4j.org/chunked/2.0.0-RC1/cypher-schema.html>).

=item neo_neo4j_version

 say "Neo4j Server Version ".$dbh->neo_neo4j_version;

Get the neo4j server version.

=back

=head2 Statement Level

=over

=item execute

 $sth->execute;
 $sth->execute($param_value,...);

All L<DBI> C<bind_param> and C<execute> variants are meant to
work. Please file a bug in L<RT|http://rt.cpan.org/> if there are
problems.

=item fetch

C<fetch> and C<fetch_rowarray> retrieve the next row from the response.

The fields returned in Cypher query rows can include nodes and
relationships, as well as scalar values. Nodes and relationships are
returned as simple Perl structures (hashrefs) by default (see
L<REST::Neo4p::Node/as_simple()> and
L<REST::Neo4p::Relationship/as_simple()> for
format). L<REST::Neo4p::Node> and L<REST::Neo4p::Relationship> objects
themselves can be retrieved by setting

 $dbh->{neo_ResponseAsObjects} = 1

on the database handle.

=item fetchall_hashref

See L<DBI/fetchall_hashref>. In L<DBD::Neo4p>, C<fetchall_hashref> is
reimplemented so that the node or relationship IDs become the hash
keys for key fields:

  $sth = $dbh->prepare("START n = node:nameidx(name = 'Ed')".
                       "MATCH n-[:friend]-m return m, m.name");
  $sth->execute;
  my $hash = $sth->fetchall_hashref('m');
  my @friend_ids = keys %$hash;
  say "One friend of Ed's is ".$hash->{$friend_ids[0]}->{'m.name'};

=back

=head1 ATTRIBUTES

=head2 Database Handle Attributes

=over

=item ResponseAsObjects

 $dbh->{neo_ResponseAsObjects}

If set, columns that are nodes, relationships or paths are returned 
as L<REST::Neo4p> objects of the appropriate type.

If clear (default), these entities are returned as hash or array refs,
as appropriate.  For descriptions of these, see
L<REST::Neo4p::Node/as_simple()>,
L<REST::Neo4p::Relationship/as_simple()>, and
L<REST::Neo4p::Path/as_simple()>.

=back

=head2 Statement Handle Attributes

=over

=item neo_param_names

 @param_names = @{ $sth->{neo_param_names} };

Arrayref of named parameters in statement.

=item neo_param_values
 
 @param_values = @{ $sth->{neo_param_values} };

Arrayref of bound parameter values.

=back

=head1 SEE ALSO

L<REST::Neo4p>, L<REST::Neo4p::Query>, L<DBI>, L<DBI::DBD>

=head1 AUTHOR

 Mark A. Jensen
 CPAN ID : MAJENSEN
 majensen -at- cpan -dot- org

=head1 COPYRIGHT

 (c) 2013-2015 by Mark A. Jensen

=head1 LICENSE

Copyright (c) 2013-2015 Mark A. Jensen. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut
