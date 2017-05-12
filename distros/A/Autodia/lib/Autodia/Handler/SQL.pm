################################################################
# AutoDIA - Automatic Dia XML.   (C)Copyright 2003 A Trevena   #
#                                                              #
# AutoDIA comes with ABSOLUTELY NO WARRANTY; see COPYING file  #
# This is free software, and you are welcome to redistribute   #
# it under certain conditions; see COPYING file for details    #
################################################################
package Autodia::Handler::SQL;

require Exporter;

use strict;

use vars qw($VERSION @ISA @EXPORT);
use Autodia::Handler;

@ISA = qw(Autodia::Handler Exporter);

use Autodia::Diagram;
use Data::Dumper;

#---------------------------------------------------------------

my %data_types = (
		  varchar => [qw/varchar2 nvarchar varchar/],
		  char    => [qw/char nchar/],
		  integer => [qw/longint shortint int bigint smallint tinyint/],
		  text    => [qw/ntext text/],
		  blob    => [qw/blob binary varbinary image/],
		  float   => [qw/long curr currency doublef float decimal numeric real money smallmoney/],
		  date    => [qw/datetime smalldate smalldatetime time date/],
		  boolean => [qw/bool boolean bit/],
		  set     => [qw/enum set/],
		 );

#####################
# Constructor Methods

# new inherited from Autodia::Handler

#------------------------------------------------------------------------
# Access Methods

# parse_file inherited from Autodia::Handler

#-----------------------------------------------------------------------------
# Internal Methods

# _initialise inherited from Autodia::Handler

sub _parse {
  my $self     = shift;
  my $fh       = shift;
  my $filename = shift;
  my $Diagram  = $self->{Diagram};

  # process tables

  my %fields = ();
  my %primary_keys = ();

  my $in_table = 0;
  my ($Class,$table);
  foreach my $fileline (<$fh>) {
    next if ($self->_discard_line($fileline)); # discard comments and garbage
    # If we have a create line, then we need to finish off the
    # last table (if any) and start a new one.
    if ($fileline =~ /^\s*create\s+table\s+(?:\[\w+\]\.)?[\`\'\"\[]?([\w\s]+)[\`\'\"\]]? ?\(?/i) {
      $table = $1;
      # create new 'class' representing table
      $Class = Autodia::Diagram::Class->new($table);
      # add 'class' to diagram
      my $exists = $self->{Diagram}->add_class($Class);
      $Class = $exists if ($exists);
    } else {
      # recognise lines that define columns
      my $matched = 0;
      foreach my $type (keys %data_types) {
	my $pattern = join('|', ($type,@{$data_types{$type}}));
	if ($fileline =~ /\s*\[?(\S+?)\]?\s+\[?($pattern)\]?\s*([\w\s\(\)]*),?\s*/i) {
	  $matched = 1;
	  my ($field,$field_type,$extra_info) = ($1,$2,$3);
	  if ($extra_info =~ /^\s*(\([\d\s]+\))/) {
	    $field_type .= $1;
	  }
	  $Class->add_attribute({
				 name => $field,
				 visibility => 0,
				 type => $field_type,
				});

	  if (my $dep = $self->_is_foreign_key($table, $field)) {
	    my $Superclass = Autodia::Diagram::Superclass->new($dep);
	    my $exists_already = $self->{Diagram}->add_superclass($Superclass);
	    if (ref $exists_already) {
	      $Superclass = $exists_already;
	    }
	    # create new relationship
	    my $Relationship = Autodia::Diagram::Inheritance->new($Class, $Superclass);
	    # add Relationship to superclass
	    $Superclass->add_inheritance($Relationship);
	    # add Relationship to class
	    $Class->add_inheritance($Relationship);
	    # add Relationship to diagram
	    $self->{Diagram}->add_inheritance($Relationship);
	  } else {
	    push (@{$fields{$field}}, $Class);
	  }

	  if ($extra_info =~ m/(identity|primary[\s_-]key)\s*/i ) {
	    my $pk_fields = $field;
	    my $primary_key = { name=>'Primary Key', type=>'pk', Param=>[], visibility=>0, };
	    foreach my $pk_field (split(/\s*,\s*/,$pk_fields) ) {
	      push (@{$primary_key->{Param}}, { Name=>$pk_field, Type=>''});
	      $primary_keys{$pk_field}= $Class;
	    }
	    $Class->add_operation($primary_key);
	  }

	  last;
	}
      }
      unless ($matched) {
	# check for indexes and primary keys
	if ( $fileline =~ m/primary[\s_-]key\s*\((.*)\)\s*/i ) {
	  my $pk_fields = $1;
	  my $primary_key = { name=>'Primary Key', type=>'pk', Param=>[], visibility=>0, };
	  foreach my $pk_field (split(/\s*,\s*/,$pk_fields) ) {
	    push (@{$primary_key->{Param}}, { Name=>$pk_field, Type=>''});
	    $primary_keys{$pk_field} = $Class;
	  }
	  $Class->add_operation($primary_key);
	}
      }
    }
  }

  # build additional fk's

  foreach my $primary_key (keys %primary_keys) {
    my $Superclass = $primary_keys{$primary_key};
    foreach my $Class (@{$fields{$primary_key}}) {
      # create new relationship
      my $Relationship = Autodia::Diagram::Inheritance->new($Class, $Superclass);
      # add Relationship to superclass
      $Superclass->add_inheritance($Relationship);
      # add Relationship to class
      $Class->add_inheritance($Relationship);
      # add Relationship to diagram
      $self->{Diagram}->add_inheritance($Relationship);
    }
  }

}


sub _is_foreign_key {
  my ($self, $table, $field) = @_;
  my $is_fk = undef;
  if (($field !~ m/$table.u?id/i) && ($field =~ m/^(.*)[_-]u?id$/i)) {
    $is_fk = $1;
  }
  return $is_fk;
}

sub _discard_line
{
  my $self = shift;
  my $line = shift;
  my $return = 0;
  $return = 1 if ( $line =~ m/^(INSERT|DROP|LOCK|ALTER|EXEC|GO)/i );
  $return = 1 if ( $line =~ m/^\s*(#|--|\/\*|\d+|\))/);
  $return = 1 if ( $line =~ m/^\s*$/);
  return $return;
}


####-----

1;

###############################################################################

=head1 NAME

Autodia::Handler::SQL.pm - AutoDia handler for SQL

=head1 INTRODUCTION

Autodia::Handler::SQL parses files into a Diagram Object, which all handlers use. The role of the handler is to parse through the file extracting information such as table names, field names, relationships and keys.

SQL is registered in the Autodia.pm module, which contains a hash of language names and the name of their respective language - in this case:

%language_handlers = { .. , sql => "Autodia::Handler::SQL", .. };

=head1 CONSTRUCTION METHOD

use Autodia::Handler::SQL;

my $handler = Autodia::Handler::SQL->New(\%Config);
This creates a new handler using the Configuration hash to provide rules selected at the command line.

=head1 ACCESS METHODS

$handler->Parse(filename); # where filename includes full or relative path.

This parses the named file and returns 1 if successful or 0 if the file could not be opened.

$handler->output();

This outputs the Dia XML file according to the rules in the %Config hash passed at initialisation of the object. It also allows you to output VCG, Dot or images rendered through GraphViz and VCG.

=cut






