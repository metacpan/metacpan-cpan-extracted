# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Config;

use strict;
use base 'DBR::Common';
use DBR::Config::Instance;
use DBR::Config::Schema;
use Carp;

my %LOADED_FILES;
sub new {
  my( $package ) = shift;
  my %params = @_;
  my $self = {session => $params{session}};

  croak( 'session is required'  ) unless $self->{session};

  bless( $self, $package );

  return( $self );
}


sub load_file{
      my $self = shift;
      my %params = @_;

      my $dbr   = $params{'dbr'}   or return $self->_error( 'dbr parameter is required'  );
      my $file  = $params{'file'}  or return $self->_error( 'file parameter is required' );
      if ($LOADED_FILES{$file}){
	    $self->_logDebug2("skipping already loaded config file '$file'");
	    return 1;
      }

      $self->_logDebug2("loading config file '$file'");
      my @conf;
      my $setcount = 0;
      open (my $fh, '<', $file) || return $self->_error("Failed to open '$file'");

      while (my $row = <$fh>) {
	    if ($row =~ /^(.*?)\#/){ # strip everything after the first comment
		  $row = $1;
	    }

	    $row =~ s/(^\s*|\s*$)//g;# strip leading and trailing spaces
	    next unless length($row);

	    $conf[$setcount] ||= {};
	    if($row =~ /^---/){ # section divider. increment the count and skip this iteration
		  $setcount++;
		  next;
	    }

	    foreach my $part (split(/\s*\;\s*/,$row)){ # Semicolons are ok in lieu of newline cus I'm arbitrary like that.
		  my ($key,$val) = $part =~ /^(.*?)\s*=\s*(.*)$/;

		  $conf[$setcount]->{lc($key)} = $val;
	    }
      }
      close $fh;

      # Filter blank sections
      @conf = grep { scalar ( %{$_} ) } @conf;

      my $count;
      foreach my $instspec (@conf){
	    $count++;

	    my $instance = DBR::Config::Instance->register(
							   dbr    => $dbr,
							   session => $self->{session},
							   spec   => $instspec
							  ) or $self->_error("failed to load DBR conf file '$file' (stanza #$count)") && next;
	    if($instance->dbr_bootstrap){
		  #don't bail out here on error
		  $self->load_dbconf(
				     dbr      => $dbr,
				     instance => $instance
				    ) || $self->_error("failed to load DBR config tables") && next;
	    }
      }

      $LOADED_FILES{$file} = 1;

      return 1;

}

sub load_dbconf{
      my $self  = shift;
      my %params = @_;



      my $dbr         = $params{'dbr'}      or return $self->_error( 'dbr parameter is required'    );
      my $parent_inst = $params{'instance'} or return $self->_error( 'instance parameter is required' );



      $self->_error("failed to create instance handles") unless
	my $instances = DBR::Config::Instance->load_from_db(
							    session   => $self->{session},
							    dbr      => $dbr,
							    parent_inst => $parent_inst
							   );

      my %schema_ids;
      map {$schema_ids{ $_->schema_id } = 1 } @$instances;

      if(%schema_ids){
	    $self->_error("failed to create schema handles") unless
	      my $schemas = DBR::Config::Schema->load(
						      session    => $self->{session},
						      schema_id => [keys %schema_ids],
						      instance  => $parent_inst,
						     );
      }

      return 1;
}

1;
