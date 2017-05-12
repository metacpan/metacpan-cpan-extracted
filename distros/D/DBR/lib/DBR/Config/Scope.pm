# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Config::Scope;

use strict;
use base 'DBR::Common';
use Digest::MD5 qw(md5_base64);

my %SCOPE_CACHE;
my %FIELD_CACHE;

sub new {
      my( $package ) = shift;
      my %params = @_;
      my $self = {
		  session   => $params{session},
		  instance => $params{conf_instance},
		  extra_ident => $params{extra_ident},
		 };

      bless( $self, $package );

      return $self->_error('session is required') unless $self->{session};
      return $self->_error('conf_instance is required')   unless $self->{instance};

      my $offset = $params{offset} || 1;
      my $scope_id = $self->_get_scope_id($offset + 1) or return $self->_error('failed to determine scope_id');

      $self->{scope_id} = $scope_id;

      return $self;
}


sub purge_all{
      %SCOPE_CACHE = ();
      %FIELD_CACHE = ();

      return 1;
}

sub _get_scope_id{
      my $self = shift;
      my $offset = shift;

      my @parts;
      while($offset < 100){
	    my (undef,$file,$line,$method) = caller($offset++);
	    if($file =~ /^\//){ # starts with Slash
		  $offset = 101; #everything is good
	    }else{
		  if ($file !~ /^\(eval/){ # If it's an eval, then we do another loop
			# Not an eval, just slap on the directory we are in and call it done
			$file = $ENV{'PWD'} . '/' . $file;
			$offset = 101;
		  }
	    }

	    push @parts, $file . '*' . $line;
      }

      my $ident = join('|',grep {$_} (@parts,$self->{extra_ident}));

      $self->_logDebug3("SCOPE: '$ident'");

      my $digest = md5_base64($ident);

      my $scope_id = $SCOPE_CACHE{$digest}; # Check the cache!
      if($scope_id){
	    $self->_logDebug2('Found cached scope');
	    return $scope_id;
      }

      my $instance = $self->{instance};
      my $dbrh = $instance->connect or return $self->_error("Failed to connect to ${\$instance->name}");

      # If the insert fails, that means someone else has won the race condition, try try again
      my $try;
      while(++$try < 3){
	    #Yeahhh... using the old way for now, Don't you like absurd recursion? perhaps change this?
	    my $record = $dbrh->select(
				       -table => 'cache_scopes',
				       -fields => 'scope_id',
				       -where => {digest => $digest},
				       -single => 1,
				      );

	    return $SCOPE_CACHE{$digest} = $record->{scope_id} if $record;

	    my $scope_id = $dbrh->insert(
					 -table => 'cache_scopes',
					 -fields => {
						     digest => $digest
						    },
					 -quiet => 1,
					);

	    return $SCOPE_CACHE{$digest} = $scope_id if $scope_id;
      }

      return $self->_error('Something failed');
}

sub fields{
      my $self  = shift;
      my $cache = $FIELD_CACHE{ $self->{scope_id} } ||= [undef,[]];

      my $fids;
      if ($cache->[0] && ($cache->[0] + 300 > time)){
	    $fids = $cache->[1];
      }

      if(!$fids){

	    my $instance = $self->{instance};
	    my $dbrh = $instance->connect or return $self->_error("Failed to connect to ${\$instance->name}");

	    my $fields = $dbrh->select(
				       -table => 'cache_fielduse',
				       -fields => 'field_id',
				       -where => { scope_id => ['d',$self->{scope_id}] },
				      ) or return $self->_error('Failed to select from cache_fielduse');
	    $fids = [map { $_->{field_id} } @$fields];
	    $cache->[0] = time;
	    $cache->[1] = $fids;
      }

      my @fields;
      foreach my $fid (@$fids){
	     my $field = DBR::Config::Field->new(
						 session   => $self->{session},
						 field_id => $fid,
					       ) or return $self->_error('failed to create table object');
	    push @fields, $field;
      }


      return \@fields;
}

sub addfield{
      my $self = shift;
      my $field = shift;

      my $fid = $field->field_id;

      return 1 if $self->{fcache}->{ $fid }++; # quick cache

      my $cache = $FIELD_CACHE{ $self->{scope_id} } ||= [undef,[]];

      return 1 if $self->_b_in($fid,$cache->[1]); # already have it

      $cache->[0] = time;
      push @{$cache->[1]}, $fid;

      my $instance = $self->{instance};
      my $dbrh = $instance->connect or return $self->_error("Failed to connect to ${\$instance->name}");

      # Don't check for failure, the unique index constraint will reject the insert in case of a race condition
      my $row_id = $dbrh->insert(
				 -table => 'cache_fielduse',
				 -fields => {
					     scope_id => ['d',$self->{scope_id}],
					     field_id => ['d',$fid]
					    },
				 -quiet => 1,
				);

      # $dbrh->minsert('cache_fielduse',
      # 	       scope_id => $self->{scope_id},
      # 	       field_id => $fid
      # 	      );

      return 1;
}

1;
