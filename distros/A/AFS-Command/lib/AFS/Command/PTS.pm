#
# $Id$
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

package AFS::Command::PTS;

require 5.6.0;

use strict;
use English;

use AFS::Command::Base;
use AFS::Object;
use AFS::Object::PTServer;
use AFS::Object::Principal;
use AFS::Object::Group;
use AFS::Object::User;

our @ISA = qw(AFS::Command::Base);
our $VERSION = '1.99';

sub creategroup {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::PTServer->new();

    $self->{operation} = "creategroup";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {
	next unless /group (\S+) has id (-\d+)/;
	my $group = AFS::Object::Group->new
	  (
	   name 		=> $1,
	   id			=> $2,
	  );
	$result->_addGroup($group);
    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub createuser {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::PTServer->new();

    $self->{operation} = "createuser";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {
	next unless /User (\S+) has id (\d+)/;
	my $user = AFS::Object::User->new
	  (
	   name 		=> $1,
	   id			=> $2,
	  );
	$result->_addUser($user);
    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub examine {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::PTServer->new();

    $self->{operation} = "examine";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {

	chomp;

	while ( /,\s*$/ ) {
	    $_ .= $self->{handle}->getline();
	    chomp;
	}

	my %data = ();

	foreach my $field ( split(/,\s*/) ) {

	    my ($key,$value) = split(/:\s+/,$field,2);

	    $key =~ tr/A-Z/a-z/;
	    $key =~ s/\s+//g;	# group quota -> groupquota
	    $value =~ s/\.$//;

	    $data{$key} = $value;

	}

	unless ( $data{id} ) {
	    $self->_Carp("pts examine: Unrecognized output: '$_'");
	    $errors++;
	    next;
	}

	if ( $data{id} > 0 ) {
	    $result->_addUser( AFS::Object::User->new(%data) );
	} else {
	    $result->_addGroup( AFS::Object::Group->new(%data) );
	}

    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub listentries {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::PTServer->new();

    $self->{operation} = "listentries";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {

	next if /^Name/;

	my ($name,$id,$owner,$creator) = split;

	#
	# We seem to be getting this one bogus line of data, with no
	# name, and 0's for the IDs.  Probably a bug in pts...
	#
	next if ( ! $name && ! $id && ! $owner && ! $creator );

	if ( $id > 0 ) {
	    my $user = AFS::Object::User->new
	      (
	       name 			=> $name,
	       id			=> $id,
	       owner			=> $owner,
	       creator			=> $creator,
	      );
	    $result->_addUser($user);
	} else {
	    my $group = AFS::Object::Group->new
	      (
	       name 			=> $name,
	       id			=> $id,
	       owner			=> $owner,
	       creator			=> $creator,
	      );
	    $result->_addGroup($group);
	}

    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub listmax {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::PTServer->new();

    $self->{operation} = "listmax";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {
	next unless /Max user id is (\d+) and max group id is (-\d+)/;
	$result->_setAttribute
	  (
	   maxuserid		=> $1,
	   maxgroupid		=> $2,
	  );
    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub listowned {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::PTServer->new();

    $self->{operation} = "listowned";

    return unless $self->_parse_arguments(%args);

    my $errors = 0;

    $errors++ unless $self->_exec_cmds( stderr => 'stdout' );

    my $user = undef;
    my $group = undef;

    while ( defined($_ = $self->{handle}->getline()) ) {

	if ( /Groups owned by (\S+) \(id: (-?\d+)\)/ ) {

	    $result->_addUser($user) if $user;
	    $result->_addGroup($group) if $group;

	    my ($name,$id) = ($1,$2);

	    if ( $id > 0 ) {
		$user = AFS::Object::User->new
		  (
		   name 		=> $name,
		   id			=> $id,
		  );
		$group = undef;
	    } else {
		$group = AFS::Object::Group->new
		  (
		   name 		=> $name,
		   id			=> $id,
		  );
		$user = undef;
	    }

	} elsif ( /^\s+(\S+)\s*/ ) {

	    if ( $user ) {
		$user->_addOwned($1);
	    } else {
		$group->_addOwned($2);
	    }

	} elsif ( /unable to get owner list/ ) {

	    #
	    # pts still (as of OpenAFS 1.2.8) doesn't have proper exit codes.
	    # If we see this string, then let the command fail, even
	    # though we might have partial data.
	    #
	    $self->{errors} .= $_;
	    $errors++;

	}

    }

    $result->_addUser($user) if $user;
    $result->_addGroup($group) if $group;

    $errors++ unless $self->_reap_cmds();

    return if $errors;
    return $result;

}

sub membership {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::PTServer->new();

    $self->{operation} = "membership";

    return unless $self->_parse_arguments(%args);

    my $errors = 0;

    $errors++ unless $self->_exec_cmds( stderr => 'stdout' );

    my $user = undef;
    my $group = undef;

    while ( defined($_ = $self->{handle}->getline()) ) {

	if ( /(\S+) \(id: (-?\d+)\)/ ) {

	    $result->_addUser($user) if $user;
	    $result->_addGroup($group) if $group;

	    my ($name,$id) = ($1,$2);

	    if ( $id > 0 ) {
		$user = AFS::Object::User->new
		  (
		   name 		=> $name,
		   id			=> $id,
		  );
		$group = undef;
	    } else {
		$group = AFS::Object::Group->new
		  (
		   name 		=> $name,
		   id			=> $id,
		  );
		$user = undef;
	    }

	} elsif ( /^\s+(\S+)\s*/ ) {

	    if ( $user ) {
		$user->_addMembership($1);
	    } else {
		$group->_addMembership($1);
	    }

	} elsif ( /unable to get membership/ ||
		  /User or group doesn't exist/ ||
		  /membership list for id \d+ exceeds display limit/ ) {

	    #
	    # pts still (as of OpenAFS 1.2.8) doesn't have proper exit codes.
	    # If we see this string, then let the command fail, even
	    # though we might have partial data.
	    #
	    $self->{errors} .= $_;
	    $errors++;

	}

    }

    $result->_addUser($user) if $user;
    $result->_addGroup($group) if $group;

    $errors++ unless $self->_reap_cmds();

    return if $errors;
    return $result;

}

1;
