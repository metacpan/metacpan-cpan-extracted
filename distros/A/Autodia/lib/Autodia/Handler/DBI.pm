################################################################
# AutoDIA - Automatic Dia XML.   (C)Copyright 2001 A Trevena   #
#                                                              #
# AutoDIA comes with ABSOLUTELY NO WARRANTY; see COPYING file  #
# This is free software, and you are welcome to redistribute   #
# it under certain conditions; see COPYING file for details    #
################################################################
package Autodia::Handler::DBI;

require Exporter;

use strict;

use warnings;
use warnings::register;

use vars qw($VERSION @ISA @EXPORT);
use Autodia::Handler;

@ISA = qw(Autodia::Handler Exporter);

use Autodia::Diagram;
use Data::Dumper;
use DBI;

#---------------------------------------------------------------

#####################
# Constructor Methods

# new inherited from Autodia::Handler

#------------------------------------------------------------------------
# Access Methods

# parse_file inherited from Autodia::Handler

#-----------------------------------------------------------------------------
# Internal Methods

# _initialise inherited from Autodia::Handler

sub _parse_file { # parses dbi-connection string
  my $self     = shift();
  my $filename = shift();
  my %config   = %{$self->{Config}};
  $self->{Diagram}->directed(0);

  # new dbi connection
  my $dbh = DBI->connect("DBI:$filename", $config{username}, $config{password});

  my $escape_tablenames = 0;
  my $unescape_tablenames=0;
  my $database_type =  $dbh->get_info( 17 );
  warn "database_type : $database_type\n";
  my ($scheme, $driver, $attr_string, $attr_hash, $driver_dsn) = DBI->parse_dsn("DBI:$filename") or die "Can't parse DBI DSN '$filename'";
  my $dbname;
  if ($driver_dsn =~ m/(?:db|dbname)=([^\:]+)/) {
    $dbname = $1;
  } else {
    ( $dbname = $driver_dsn) =~ s/([^\:]+)/$1/;
  }

  my $schema = '' ;
  # only keep tables in schema public for PostgreSQL
  # could be given as a parameter... (+ a list of tables...)
  $schema = 'public' if (lc($database_type) =~ m/(oracle|postgres)/);

  # Manage database tablenames that need to be escaped before calling DBI
  # and those that need to be unescaped before calling DBI 
  $escape_tablenames = 1 if (lc($database_type) =~ m/(oracle|postgres)/);
  $unescape_tablenames = 1 if (lc($database_type) =~ m/(mysql)/);

  # pre-process tables

  foreach my $table ($dbh->tables(undef, $schema, '%', '')) {
      $table =~ s/['`"]//g;
      $table =~ s/.*\.(.*)$/$1/;
      my $esc_table = $table;
      $esc_table = qq{"$esc_table"} if ($escape_tablenames);
      my $sth = $dbh->prepare("select * from $esc_table where 1 = 0");
      $sth->execute;
      $self->{tables}{$table}{fields} = $sth->{NAME};
      $sth->finish;
  }


  # got to about here applying dbi datatypes patch
  foreach my $table (keys %{$self->{tables}}) {
    # create new 'class' representing table
    my $Class = Autodia::Diagram::Class->new($table);
    # add 'class' to diagram
    $self->{Diagram}->add_class($Class);

    # get fields
    my $esc_table = $table;
    $esc_table = qq{"${dbname}.$esc_table"} if ($escape_tablenames);

    warn "using dbname $dbname / table $esc_table\n";

    my @key_columns;
    my $primary_key = { name=>'Key', type=>'Primary', Params=>[], visibility=>0, };
    my $sth = $dbh->primary_key_info( $schema || undef, $dbname,  $esc_table );
    if (defined $sth) {
	@key_columns = keys %{$sth->fetchall_hashref('COLUMN_NAME')};
    } else {
	warn "trying dbh -> primary key method using schema $schema, dbname : $dbname, table $esc_table\n";
	# from DBIx::Class::Schema::Loader::DBI / Rose::DBI
	@key_columns = map { lc } $dbh->primary_key($schema || undef, $dbname, $esc_table);

    }
    warn "got key columns for table $esc_table : @key_columns\n";

    if (@key_columns) {
	push (@{$primary_key->{Params}}, map ({ Name=>$_, Type=>''}, @key_columns));
	$Class->add_operation($primary_key);
    }

    # FIXME : need to subclass db's that don't work
    # try using DBD, then use subclass to do horrid hacks

    my $guess_foreign_keys = 1;

    # get foreign keys
    $sth = $dbh->foreign_key_info( $schema || undef, $dbname, '', $schema || undef, $dbname, $esc_table );
    if ($sth) {
	my %rels;

	my $i = 1; # for unnamed rels, which hopefully have only 1 column ...
	while(my $raw_rel = $sth->fetchrow_arrayref) {
	    $guess_foreign_keys = 0 if ($guess_foreign_keys);
	    warn "got relation $raw_rel\n";
	    my $pk_tbl  = $raw_rel->[2];
	    my $pk_col  = lc $raw_rel->[3];
	    my $fk_col  = lc $raw_rel->[7];
	    my $relid   = ($raw_rel->[11] || ( "__dcsld__" . $i++ ));
	    $rels{$relid}->{tbl} = $pk_tbl;
	    $rels{$relid}->{cols}->{$pk_col} = $fk_col;

	    push(@{$self->{foreign_tables}{$pk_tbl}}, {field => $pk_col, table => $esc_table, class => $Class });
	    $Class->add_operation( { name=>'Key', type=>'Foreign', Params=>[ { Name => $pk_col }], visibility=>0, } );
	}
	$sth->finish;
    }


    for my $field (@{$self->{tables}{$table}{fields}}) {
      my $sth = $dbh->column_info( $schema || undef, $dbname,  $esc_table, $field );
      my $field_info = $sth->fetchrow_hashref;
      $Class->add_attribute({
			     name => $field,
			     visibility => 0,
			     type => $field_info->{TYPE_NAME},
			    });

      if ($guess_foreign_keys) {
	  if (my $dep = $self->_guess_foreign_key($table, $field)) {
	      # fix - need to handle multiple relations per table
	      push(@{$self->{foreign_tables}{$dep}}, {field => $field, table => $esc_table, class => $Class });
	      $Class->add_operation( { name=>'Key', type=>'Foreign', Params=>[ { Name => $field, Type => $field_info->{TYPE_NAME}, }], visibility=>0, } );
	  }
      }
    }
  }

  # fix - need to handle multiple relations per table
  foreach my $fk_table (keys %{$self->{foreign_tables}} ) {
      foreach my $relation ( @{$self->{foreign_tables}{$fk_table}}) {
	  $self->_add_foreign_keytable($relation->{table},
				 $relation->{field},
				 $relation->{class},
				 $fk_table);
      }
  }

  $dbh->disconnect;
}


sub _add_foreign_keytable {
  my ($self,$table,$field,$Class,$dep) = @_;

  my $Superclass = Autodia::Diagram::Superclass->new($dep);
  my $exists_already = $self->{Diagram}->add_superclass($Superclass);
  $Superclass = $exists_already if (ref $exists_already);

  # create new relationship
  my $Relationship = Autodia::Diagram::Relation->new($Class, $Superclass);
  # add Relationship to superclass
  $Superclass->add_relation($Relationship);
  # add Relationship to class
  $Class->add_relation($Relationship);
  # add Relationship to diagram
  $self->{Diagram}->add_relation($Relationship);

  return;
}

sub _guess_foreign_key {
  my ($self, $table, $field) = @_;
  my $is_fk = undef;
  $field =~ s/'"`//g;

  if ($field =~ m/^(.*)_u?id$/i) {
      my $foreign_table = $1;
      unless ($foreign_table eq $table) {
	  $is_fk = $foreign_table if ($self->{tables}{$foreign_table});
      }
  } elsif (($field ne $table ) && ($self->{tables}{$field})) {
      $is_fk = $field;
  }
  return $is_fk;
}

sub _discard_line
{
  warn "not implemented\n";
  return 0;
}

1;

###############################################################################

=head1 NAME

Autodia::Handler::DBI.pm - AutoDia handler for DBI connections

=head1 INTRODUCTION

This module parses the contents of a database through a dbi connection and builds a diagram

%language_handlers = { .. , dbi => "Autodia::Handler::DBI", .. };

=head1 CONSTRUCTION METHOD

use Autodia::Handler::DBI;

my $handler = Autodia::Handler::DBI->New(\%Config);
This creates a new handler using the Configuration hash to provide rules selected at the command line.

=head1 ACCESS METHODS

$handler->Parse($connection); # where connection includes full or dbi connection string

$handler->output(); # any arguments are ignored.

=cut






