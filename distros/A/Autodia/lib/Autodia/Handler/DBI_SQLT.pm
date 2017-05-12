################################################################
# AutoDIA - Automatic Dia XML.   (C)Copyright 2001 A Trevena   #
#                                                              #
# AutoDIA comes with ABSOLUTELY NO WARRANTY; see COPYING file  #
# This is free software, and you are welcome to redistribute   #
# it under certain conditions; see COPYING file for details    #
################################################################
package Autodia::Handler::DBI_SQLT;

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

use SQL::Translator;
use SQL::Translator::Schema::Constants;


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
  my $dbh = DBI->connect("DBI:$filename", $config{username}, $config{password},
			 {
			     RaiseError       => 1,
			     FetchHashKeyName => 'NAME_lc',
			 }
			);

  warn "got dbh : $dbh\n";

  my $translator  =  SQL::Translator->new(
					  parser      => 'DBI',
					  dbh         => $dbh,
					  parser_args     => {
							      dsn         => "dbi:$filename",
							      db_user     => $config{username},
							      db_password => $config{password},
							     }

					 );


  my $parser      = $translator->parser;
  my $parser_type = $translator->parser_type;
  my $data;
  my $parser_output;
  eval { $parser_output = $parser->($translator, $$data) };
  if ($@ || ! $parser_output) {
      my $msg = sprintf "translate: Error with parser '%s': %s",
	$parser_type, ($@) ? $@ : " no results";
      die $translator->error($msg);
  }

  warn "parser : $parser, parser_type : $parser_type, parser_output : $parser_output\n";

  my $schema = $translator->schema;

  warn "got schema : $schema\n";

  # got to about here applying dbi datatypes patch
  foreach my $table ($schema->get_tables) {
      warn "got table : $table name\n";
      my $table_name = $table->name;
      # create new 'class' representing table
      my $Class = Autodia::Diagram::Class->new($table);
      # add 'class' to diagram
      $self->{Diagram}->add_class($Class);

      # get primary key fields.
      my %pkey_fields = map { $_ => 1 } $schema->pkey_fields;

      # get foreign key fields.
      my %fkey_fields = map { $_ => 1 } $schema->fkey_fields;

      for my $field ($table->get_fields) {
	  my $field_name = $field->name;
	  $Class->add_attribute({
				 name => $field_name,
				 visibility => 0,
				 type => $field->data_type,
				});

	  if ($fkey_fields{$field_name}) {
	      $Class->add_operation( { name=>'Key', type=>'Foreign', Params=>[ { Name => $field_name, Type => $field->data_type, }], visibility=>0, } );
	  }
	  if ($pkey_fields{$field_name}) {
	      $Class->add_operation( { name=>'Key', type=>'Primary', Params=>[ { Name => $field_name, Type => $field->data_type, }], visibility=>0, } );
	  }
      }
      
      for my $c ( $table->get_constraints ) {
	  next unless $c->type eq FOREIGN_KEY;
	  my $fk_table = $c->reference_table or next;
	  next unless defined $schema->get_table( $fk_table );
	  for my $fk_field ( $c->reference_fields ) {
	      $self->{foreign_tables}{$fk_table} = {
						    table => $table,
						    field => $fk_field,
						    class => $Class,
						   };
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
  return 1;
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

