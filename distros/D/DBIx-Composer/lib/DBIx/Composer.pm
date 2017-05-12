# Author: I.Plisco
# $Id: Composer.pm,v 1.2 2003/10/29 16:55:23 plisco Exp $

package DBIx::Composer;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = '1.00';
	@ISA         = qw (Exporter);
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

# Default global values
our $DEBUG = 0;
our $DBH;

########################################### main pod documentation begin ##
# Below is documentation for module.


=head1 NAME

DBIx::Composer - Composes and runs SQL statement.

=head1 SYNOPSIS

  use DBIx::Composer
  $cmd = new DBIx::Composer();
  $cmd->{table} = 'table1';
  $cmd->{fields} = 'name, email';
  $cmd->{where} = "where login = 'peter'";
  print $cmd->compose_select;
# Prints "select name, surname from table1 where login = 'peter'"

  $dbh = open_database();	# Open database yourself
  use DBIx::Composer
  $cmd = new DBIx::Composer(dbh=>$dbh, debug=> 1);
  $cmd->{table} = 'table1';
  $cmd->{fields} = 'login, name, email';
  $cmd->{values} = "'john', 'John Smith', 'john@smith.com'";
  $cmd->insert();
# Executes command "insert into table1 (login, name, email) values 
#    ('john', 'John Smith', 'john@smith.com')"
# Prints this command on STDERR before execution.

=head1 DESCRIPTION

This module helps you to compose and run SQL statements. First you
create new object and fill its hash for common parts of SQL
statements. Then you may either compose SQL statement from these parts
or both compose and execute it.

=head1 USAGE

You connect to database using your favorite
method of connection and supply DBIx::Composer object with standard database
handler $dbh. If you don't plan to execute statements, you may omit 
connection to database.

So, after creating new object you set its parameters, or SQL command parts.
Modifiers for command, such as "where ...", "order ...", "limit ..."
must be full modifiers like "where a=b", not only "a=b".

You don't need to prepare() SQL fetch statements - they are prepared
internally. You cant execute statements right after setting their parts - the
module checks whether command has been composed, prepared and executed. Because
of such behaviour don't try to reset command parts after executing, but better
create new DBIx::Composer object.

=head2 Command parts

Valid command parts are:

  table - table name.
  Examples:
  $cmd->{table} = 'table1'
  $cmd->{table} = 'db left join user using (host)';

  fields - fields to select, insert, update, etc.
  Examples:
  $cmd->{fields} = 'login, email, tries + 5';
  $cmd->{fields} = 'curdate(), now()';
  $cmd->{fields} = 'ip, traf_in+thaf_out as sum';

  where
  Examples:
  $cmd->{where} = 'login = peter';
  $cmd->{where} = 'tries > limit + 2';

  order
  Examples:
  $cmd->{order} = "order by ip desc";

  limit
  Examples:
  $cmd->{limit} = "limit 20";
  $cmd->{limit} = "limit 100, 20";

=head2 Opening database

DBIx::Composer doesn't touch opening database. You should open it 
yourself somewhere else in your program. As for me, I use special function
open_database() like this:

  #====================
  sub open_database {
  #====================
  
  # Read config from some file
    my ($db_db, $db_login, $db_passwd, $debug) = read_config();
    $driver_name = "dbi:mysql:$db_db";
    
  # Connect to database
    $dbh = DBI->connect
      ($driver_name, $db_login, $db_passwd)||
      die $DBI::errstr;
	
  # Initialize DBIx::Composer
    $DBIx::Composer::DBH = $dbh;
    $DBIx::Composer::DEBUG = $debug;

    return $dbh;	# returns true on success
  }

Then in your program you don't need to set $dbh anymore, so you can simply
write:

  $cmd = new $DBIx::Composer;

and $cmd knows yet about dbh handler and debug level.

You have to set $dbh in new() explicitly only if you want to make two or more
database connections in one program, e.g. on migrating from old database to new
one.

=head2 Debug levels

If debug level is set to 1 or more, the module prints SQL commands
to STDERR (for cgi scripts it's error_log of web server).

If debug level >= 1, it prints executed statements before executing them.

If debug level >= 2, it prints composed statements after composing them. So
usually (not always) on level 2 you have 2 lines in STDERR - of composing and
of executing.

Debug line starts from prefix ("SQL run" or "SQL debug") and program name (it's
convenient for cgi-bin's).

=head2 Things you must pay attention to

=item *

In order to avoid confusing, don't reuse DBIx::Composer objects after executing
them, but simply create new object. It's because the module remembers its state
and don't composes statement again. Probably such behaviour will change
partially in future.

=item *

Command parts 'where', 'limit', 'order' must be started from these words, that
is, 'where a=b', not 'a=b'; 'order by c desc', not 'c desc' or 'by c desc'. You
may have in your mind the string "select $fields from $table $where".

=head1 REQUIRES

  Perl 5.6.1 (for lvalue functions)
  ExtUtils::MakeMaker	- for installation
  Test::More	- for installation tests
  DBI etc.	- if you want to execute statements


=head1 BUGS

I have tested it only in environment with MySQL database and localhost as
database host.

Installation tests doesn't check that it works on real database - they only
check that the module composes statements.


=head1 AUTHOR

	Igor Plisco
	igor at plisco dot ru
	http://plisco.ru/soft

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=head1 FUNCTION DESCRIPTIONS


=cut

############################################# main pod documentation end ##


################################################ subroutine header begin ##

#============================================================
sub new {
#============================================================

=head2 new

 Purpose   : Creates new DBIx::Object object.
 Usage     : DBIx::Composer->new()
 Returns   : Object handler.
 Argument  : Nothing or dbh handler or config.
 Throws    : None.
 Comments  : No.

See Also   : N/A

=cut

#------------------------------------------------------------

#  my ($class, %parameters) = @_;
  my $class = shift;

  my $self = {
    '_config' => {
      debug => $DEBUG,	# default debug level
      dbh => $DBH	# default database handler
      }
  };
  
  $self->{'_config'}->{'dbh'} = shift if @_ == 1;
  %{ $self->{'_config'} } = @_ if @_ >= 2;

  bless ($self, ref ($class) || $class);
  return $self;

}

#============================================================
sub debug_level {
#============================================================

=head2 debug_level

 Usage     : DBIx::Composer->debug_level()
 Purpose   : Sets default debug level for all newly created objects.
 Returns   : current value of debug level
 Argument  : Debug level as integer.
 Throws    : None.
 Comments  : Warning: now returns global $dbh, not local for object.

See Also   : 

=cut

#------------------------------------------------------------
  my $self = shift;

# Set it
  $DEBUG = shift if(@_);
  return $DEBUG;

}

#============================================================
sub dbh {
#============================================================

=head2 dbh

 Usage     : DBIx::Composer->dbh()
 Purpose   : Sets default database handler for all newly created objects.
 Returns   : current value of $dbh
 Argument  : database handler
 Throws    : None.
 Comments  : Warning: now returns global $dbh, not local for object.

See Also   : 

=cut

#------------------------------------------------------------
  my $self = shift;

# Set it
  $DBH = shift if(@_);
  return $DBH;

}

#============================================================
sub quote {
#============================================================

=head2 quote

 Usage     : DBIx::Composer->quote()
 Purpose   : Quotes its value by calling $dbh->quote.
 Returns   : Quoted string
 Argument  : String or number to quote
 Throws    : None.
 Comments  : None.

See Also   : 

=cut

#------------------------------------------------------------
#  my ($self, $str) = @_;
#  my $dbh;
#
#  $dbh = $self->{_config}->{dbh};
#  return $dbh->quote($str);
  my $self = shift;
  return $self->{_config}->{dbh}->quote(shift);

}

#============================================================
sub compose_select {
#============================================================

=head2 compose_select

 Usage     : $cmd->compose_select()
 Purpose   : Composes select statement for given object.
 Returns   : Composed statement
 Argument  : None.
 Throws    : Returns undef, if required fields are missed.
 Comments  : Composes "select $fields from $table $where $order $limit"
  statement where $fields stands for $cmd->fields and so on.
  $where, $group, $order and $limit are optional.


See Also   : 

=cut

#------------------------------------------------------------
  my ($self, %parameters) = @_;

# Check required keys
  return undef unless ($self->{fields});

# Compose
  $self->{cmd} = "select $self->{fields}";
  $self->{cmd} .= " from $self->{table}" if $self->{table};
  $self->{cmd} .= " $self->{where}" if $self->{where};
  $self->{cmd} .= " $self->{group}" if $self->{group};
  $self->{cmd} .= " $self->{order}" if $self->{order};
  $self->{cmd} .= " $self->{limit}" if $self->{limit};

# Print debug, if needed
  $self->debug;
  
  return $self->{cmd};
}

#============================================================
sub compose_insert {
#============================================================

=head2 compose_insert

 Usage     : $cmd->compose_insert()
 Purpose   : Composes insert statement for given object.
 Returns   : Composed statement
 Argument  : None.
 Throws    : Returns undef, if required fields are missed.
 Comments  : Composes "insert into $table ($fields) values ($values)"
  or "insert into $table values ($values)" if $fields omitted.

See Also   : 

=cut

#------------------------------------------------------------
  my ($self, %parameters) = @_;

# Check required keys
  return undef unless ($self->{table});
  return undef unless ($self->{values});

# Compose
  $self->{cmd} = "insert into $self->{table}";
  $self->{cmd} .= " ($self->{fields})" if $self->{fields};
  $self->{cmd} .= " values ($self->{values})";
  
# Print debug, if needed
  $self->debug;

  return $self->{cmd};
}

#============================================================
sub compose_replace {
#============================================================

=head2 compose_replace

 Usage     : $cmd->compose_replace()
 Purpose   : Composes replace statement for given object.
 Returns   : Composed statement
 Argument  : None.
 Throws    : Returns undef, if required fields are missed.
 Comments  : Composes "replace into $table ($fields) values ($values)"
  or "replace into $table values ($values)" if $fields omitted.

See Also   : 

=cut

#------------------------------------------------------------
  my ($self, %parameters) = @_;

# Check required keys
  return undef unless ($self->{table});
  return undef unless ($self->{values} or $self->{set});

# Compose
  $self->{cmd} = "replace into $self->{table}";

# Insert-like syntax
  if($self->{values}) {
    $self->{cmd} .= " ($self->{fields})" if $self->{fields};
    $self->{cmd} .= " values ($self->{values})";

# Update-like syntax
  } else {
    $self->{cmd} .= " $self->{set}";
  }
  
# Print debug, if needed
  $self->debug;

  return $self->{cmd};
}


#============================================================
sub compose_delete {
#============================================================

=head2 compose_delete

 Usage     : $cmd->compose_delete()
 Purpose   : Composes delete statement for given object.
 Returns   : Composed statement
 Argument  : None.
 Throws    : Returns undef, if required fields are missed.
 Comments  : Composes "delete from $table $where"
  or "delete from $table" if $where omitted.


See Also   : 

=cut

#------------------------------------------------------------
  my ($self, %parameters) = @_;

# Check required keys
  return undef unless ($self->{table});

# Compose
  $self->{cmd} = "delete from $self->{table}";
  $self->{cmd} .= " $self->{where}" if $self->{where};
  
# Print debug, if needed
  $self->debug;
  
  return $self->{cmd};
}

#============================================================
sub compose_update {
#============================================================

=head2 compose_update

 Usage     : $cmd->compose_update()
 Purpose   : Composes update statement for given object.
 Returns   : Composed statement
 Argument  : None.
 Throws    : Returns undef, if required fields are missed.
 Comments  : Composes "update $table $set $where"
  or "update $table $set" if $where omitted.

See Also   : 

=cut

#------------------------------------------------------------
  my ($self, %parameters) = @_;

# Check required keys
  return undef unless ($self->{table});
  return undef unless ($self->{set});

# Compose
  $self->{cmd} = "update $self->{table} $self->{set}";
  $self->{cmd} .= " $self->{where}" if $self->{where};
  
# Print debug, if needed
  $self->debug;
  
  return $self->{cmd};
}

#============================================================
sub selectrow_array {
#============================================================

=head2 selectrow_array

 Usage     : $cmd->selectrow_array()
 Purpose   : Makes DBI call of selectrow_array
 Returns   : Array or scalar
 Argument  : None.
 Throws    : Returns undef, if required fields are missed.
 Comments  : 

See Also   : 

=cut

#------------------------------------------------------------
  my ($self, %parameters) = @_;

# Check required keys
  return undef unless ($self->{_config}->{dbh});

# Compose
  $self->compose_select unless $self->{cmd};
  return undef unless ($self->{cmd});

# Make DBI call
  $self->log;
#  return $self->{_config}->{dbh}->selectrow_array($self->{cmd});

#  if(wantarray()) {
#    my @arr = $self->{_config}->{dbh}->selectrow_array($self->{cmd});
#    return @arr;
#  } else {
#    return $self->{_config}->{dbh}->selectrow_array($self->{cmd});
#  }
  return $self->{_config}->{dbh}->selectrow_array($self->{cmd});

}

#============================================================
sub fetch {
#============================================================

=head2 fetch

 Usage     : $cmd->fetch()
 Purpose   : Makes DBI call of fetch
 Returns   : Array of data
 Argument  : None.
 Throws    : Returns undef, if error occured. See $dbh->errstr for errors. 
 Comments  : After last row returns undef too.

See Also   : 

=cut

#------------------------------------------------------------
  my ($self, %parameters) = @_;

# execute() called yet?
  unless($self->{_executed}) {

# Is $sth ready?
    unless($self->{sth}) {

# Was command prepared yet?
      unless ($self->{cmd}) {
        $self->compose_select unless $self->{cmd};
	return undef unless ($self->{cmd});
      }

# Prepare
      $self->{sth} = $self->{_config}->{dbh}->prepare($self->{cmd});
      return undef unless ($self->{sth});
    }

# Execute
    $self->log;
    $self->{sth}->execute || return undef;
    $self->{_executed} = 1;
  }

  return $self->{sth}->fetch();

}

#============================================================
sub fetchrow_hashref {
#============================================================

=head2 fetchrow_hashref

 Usage     : $cmd->fetchrow_hashref()
 Purpose   : Makes DBI call of fetchrow_hashref
 Returns   : Array of data
 Argument  : None.
 Throws    : Returns undef, if error occured. See $dbh->errstr for errors. 
 Comments  : After last row returns undef too.

See Also   : 

=cut

#------------------------------------------------------------
  my ($self, %parameters) = @_;

# execute() called yet?
  unless($self->{_executed}) {

# Is $sth ready?
    unless($self->{sth}) {

# Was command prepared yet?
      unless ($self->{cmd}) {
        $self->compose_select unless $self->{cmd};
	return undef unless ($self->{cmd});
      }

# Prepare
      $self->{sth} = $self->{_config}->{dbh}->prepare($self->{cmd});
      return undef unless ($self->{sth});
    }

# Execute
    $self->{sth}->execute || return undef;
    $self->{_executed} = 1;
  }

  return $self->{sth}->fetchrow_hashref();

}

#============================================================
sub insert {
#============================================================

=head2 insert

 Usage     : $cmd->insert()
 Purpose   : Makes DBI call of insert
 Returns   : ID of inserted row (as "last insert id").
 Argument  : None.
 Throws    : Returns undef, if required fields are missed.
 Comments  : 

See Also   : 

=cut

#------------------------------------------------------------
  my ($self, %parameters) = @_;

# Check required keys
  return undef unless ($self->{table});

# Compose
  $self->compose_insert unless $self->{cmd};
  return undef unless ($self->{cmd});

# Make DBI call
  $self->log;
  $self->{_config}->{dbh}->do($self->{cmd});

  return  $self->{_config}->{dbh}->{'mysql_insertid'};

}

#============================================================
sub replace {
#============================================================

=head2 replace

 Usage     : $cmd->replace()
 Purpose   : Makes DBI call of replace
 Returns   : ID of replaced row (as "last insert id").
 Argument  : None.
 Throws    : Returns undef, if required fields are missed.
 Comments  : 

See Also   : 

=cut

#------------------------------------------------------------
  my ($self, %parameters) = @_;

# Check required keys
  return undef unless ($self->{table});

# Compose
  $self->compose_replace unless $self->{cmd};
  return undef unless ($self->{cmd});

# Make DBI call
  $self->log;
  $self->{_config}->{dbh}->do($self->{cmd});

  return  $self->{_config}->{dbh}->{'mysql_insertid'};

}

#============================================================
sub delete {
#============================================================

=head2 delete

 Usage     : $cmd->delete()
 Purpose   : Makes DBI call of delete
 Returns   : 1 if OK, false otherwise.
 Argument  : None.
 Throws    : Returns undef, if required fields are missed.
 Comments  : 

See Also   : 

=cut

#------------------------------------------------------------
  my ($self, %parameters) = @_;

# Check required keys
  return undef unless ($self->{table});

# Compose
  $self->compose_delete unless $self->{cmd};
  return undef unless ($self->{cmd});

# Make DBI call
  $self->log;
  unless ($self->{_config}->{dbh}->do($self->{cmd})) {
    warn $self->{_config}->{dbh}->errstr;
    return 0;
  }

  return  1;

}

#============================================================
sub update {
#============================================================

=head2 update

 Usage     : $cmd->update()
 Purpose   : Makes DBI call of update
 Returns   : 1 if OK, false otherwise.
 Argument  : None.
 Throws    : Returns undef, if required fields are missed.
 Comments  : 

See Also   : 

=cut

#------------------------------------------------------------
  my ($self, %parameters) = @_;

# Check required keys
  return undef unless ($self->{table});

# Compose
  $self->compose_update unless $self->{cmd};
  return undef unless ($self->{cmd});

# Make DBI call
  $self->log;
  unless ($self->{_config}->{dbh}->do($self->{cmd})) {
    warn $self->{_config}->{dbh}->errstr;
    return 0;
  }

  return  1;

}

#============================================================
sub log_cmd {
#============================================================

=head2 log_cmd

 Usage     : $cmd->log_cmd()
 Purpose   : Logs SQL command to STDERR.
 Returns   : Nothing.
 Argument  : 1 - output format
 Throws    : Returns undef, if required fields are missed.
 Comments  : Should't be called directly. Set flag debug
 		instead when called new().

See Also   : 

=cut

#------------------------------------------------------------
  my ($self, $fmt) = @_;

# Check format
  $fmt = "%s\n" unless $fmt;
  printf STDERR $fmt, $self->{cmd};

# Log command into STDERR

}

#============================================================
sub debug {
#============================================================

=head2 debug

 Usage     : $cmd->debug()
 Purpose   : Logs SQL command to STDERR.
 Returns   : Nothing.
 Argument  : None.
 Throws    : Returns undef, if required fields are missed.
 Comments  : Should't be called directly. Set flag debug > 0
 		instead when called new().

See Also   : 

=cut

#------------------------------------------------------------
  my ($self, %parameters) = @_;

# If debug level < 1 - do nothing
  return unless($self->{_config}->{debug} > 1);

# Log command into STDERR
  $self->log_cmd("SQL debug: $0 -> [%s]\n");

}

#============================================================
sub log {
#============================================================

=head2 log

 Usage     : $cmd->log()
 Purpose   : Logs SQL command to STDERR.
 Returns   : Nothing.
 Argument  : None.
 Throws    : Returns undef, if required fields are missed.
 Comments  : Should't be called directly. Set flag debug > 1
 		instead when called new().

See Also   : 

=cut

#------------------------------------------------------------
  my ($self, %parameters) = @_;

# If debug level < 0 - do nothing
  return unless($self->{_config}->{debug} > 0);

# Log command into STDERR
  $self->log_cmd("SQL run: $0 -> [%s]\n");

}

=head2 Functions for access to inner object data as lvalue

 Usage     : $cmd->table = "users"; or: $table_sav = $cmd->table;
 Purpose   : Make access to inner variables without hash curlies.
 Comments  : Warning: don't work in Perl < 5.6. Use form $cmd->{table} instead.

 Currently supported functions:
	table()
	fields()
	values()
	where()
	set()
	order()
	group()
	limit()

=cut

# use 5.6.1;	# for lvalues

#============================================================
sub table : lvalue {
#------------------------------------------------------------
  shift()->{table};
}

#============================================================
sub fields : lvalue {
#------------------------------------------------------------
  shift()->{fields};
}

#============================================================
sub values : lvalue {
#------------------------------------------------------------
  shift()->{values};
}

#============================================================
sub where : lvalue {
#------------------------------------------------------------
  shift()->{where};
}

#============================================================
sub set : lvalue {
#------------------------------------------------------------
  shift()->{set};
}

#============================================================
sub order : lvalue {
#------------------------------------------------------------
  shift()->{order};
}

#============================================================
sub group : lvalue {
#------------------------------------------------------------
  shift()->{group};
}

#============================================================
sub limit : lvalue {
#------------------------------------------------------------
  shift()->{limit};
}


1; #this line is important and will help the module return a true value
__END__

