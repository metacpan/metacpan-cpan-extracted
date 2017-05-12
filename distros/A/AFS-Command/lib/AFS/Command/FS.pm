#
# $Id$
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

package AFS::Command::FS;

require 5.6.0;

use strict;
use English;

use AFS::Command::Base;
use AFS::Object;
use AFS::Object::CacheManager;
use AFS::Object::Path;
use AFS::Object::Cell;
use AFS::Object::Server;
use AFS::Object::ACL;

our @ISA = qw(AFS::Command::Base);
our $VERSION = '1.99';

sub checkservers {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::CacheManager->new();

    $self->{operation} = "checkservers";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    my @servers = ();

    while ( defined($_ = $self->{handle}->getline()) ) {

	chomp;

	if ( /The current down server probe interval is (\d+) secs/ ) {
	    $result->_setAttribute( interval => $1 );
	}

	if ( /These servers are still down:/ ) {
	    while ( defined($_ = $self->{handle}->getline()) ) {
		s/^\s+//g;
		s/\s+$//g;
		push(@servers,$_);
	    }
	}
    }

    $result->_setAttribute( servers => \@servers );

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub diskfree {
    my $self = shift;
    return $self->_paths_method('diskfree',@_);
}

sub examine {
    my $self = shift;
    return $self->_paths_method('examine',@_);
}

sub listquota {
    my $self = shift;
    return $self->_paths_method('listquota',@_);
}

sub quota {
    my $self = shift;
    return $self->_paths_method('quota',@_);
}

sub storebehind {
    my $self = shift;
    return $self->_paths_method('storebehind',@_);
}

sub whereis {
    my $self = shift;
    return $self->_paths_method('whereis',@_);
}

sub whichcell {
    my $self = shift;
    return $self->_paths_method('whichcell',@_);
}

sub listacl {
    my $self = shift;
    return $self->_paths_method('listacl',@_);
}

sub _paths_method {

    my $self = shift;
    my $operation = shift;
    my (%args) = @_;

    my $result = AFS::Object::CacheManager->new();

    $self->{operation} = $operation;

    my $pathkey = $operation eq 'storebehind' ? 'files' : 'path';

    return unless $self->_parse_arguments(%args);

    my $errors = 0;

    $errors++ unless $self->_exec_cmds( stderr => 'stdout' );

    my @paths = ref $args{$pathkey} eq 'ARRAY' ? @{$args{$pathkey}} : ($args{$pathkey});
    my %paths = map { $_ => 1 } @paths;

    my $default = undef; # Used by storebehind

    while ( defined($_ = $self->{handle}->getline()) ) {

	next if /^Volume Name/;

	my $path = AFS::Object::Path->new();

	if ( /fs: Invalid argument; it is possible that (.*) is not in AFS./ ||
	     /fs: no such cell as \'(.*)\'/ ||
	     /fs: File \'(.*)\' doesn\'t exist/ ||
	     /fs: You don\'t have the required access rights on \'(.*)\'/ ) {

	    $path->_setAttribute
	      (
	       path 		=> $1,
	       error		=> $_,
	      );

	    delete $paths{$1};
	    @paths = grep($_ ne $1,@paths);

	} else {

	    if ( $operation eq 'listacl' ) {

		if ( /^Access list for (.*) is/ ) {

		    $path->_setAttribute( path => $1 );
		    delete $paths{$1};

		    my $normal 		= AFS::Object::ACL->new();
		    my $negative 	= AFS::Object::ACL->new();

		    my $type = 0;

		    while ( defined($_ = $self->{handle}->getline()) ) {

			s/^\s+//g;
			s/\s+$//g;
			last if /^\s*$/;

			$type = 1, next if /^Normal rights:/;
			$type = -1, next if /^Negative rights:/;

			my ($principal,$rights) 	= split;

			if ( $type == 1 ) {
			    $normal->_addEntry( $principal => $rights );
			} elsif ( $type == -1 ) {
			    $negative->_addEntry( $principal => $rights );
			}

		    }

		    $path->_setACLNormal($normal);
		    $path->_setACLNegative($negative);

		}

	    }

	    if ( $operation eq 'whichcell' ) {

		if ( /^File (\S+) lives in cell \'([^\']+)\'/ ) {

		    $path->_setAttribute
		      (
		       path	=> $1,
		       cell 	=> $2,
		      );
		    delete $paths{$1};

		}

	    }

	    if ( $operation eq 'whereis' ) {

		if ( /^File (.*) is on hosts? (.*)$/ ) {

		    $path->_setAttribute
		      (
		       path 			=> $1,
		       hosts			=> [split(/\s+/,$2)],
		      );
		    delete $paths{$1};

		}

	    }

	    if ( $operation eq 'storebehind' ) {

		if ( /Default store asynchrony is (\d+) kbytes/ ) {

		    $default = $1;
		    next;

		} elsif ( /Will store (.*?) according to default./ ) {

		    $path->_setAttribute
		      (
		       path 			=> $1,
		       asynchrony 		=> 'default',
		      );

		    delete $paths{$1};
		    @paths = grep($_ ne $1,@paths);

		} elsif ( /Will store up to (\d+) kbytes of (.*?) asynchronously/ ) {

		    $path->_setAttribute
		      (
		       path 			=> $2,
		       asynchrony 		=> $1,
		      );

		    delete $paths{$2};
		    @paths = grep($_ ne $2,@paths);

		}

	    }

	    if ( $operation eq 'quota' ) {

		if ( /^\s*(\d{1,2})%/ ) {

		    $path->_setAttribute
		      (
		       path 			=> $paths[0],
		       percent			=> $1,
		      );
		    delete $paths{$paths[0]};
		    shift @paths;

		}

	    }

	    if ( $operation eq 'listquota' ) {

		#
		# This is a bit lame.  We want to be lazy and split on white
		# space, so we get rid of this one annoying instance.
		#
		s/no limit/nolimit/g;

		my ($volname,$quota,$used,$percent,$partition) = split;

		$quota = 0 if $quota eq "nolimit";
		$percent =~ s/\D//g; # want numeric result
		$partition =~ s/\D//g; # want numeric result

		$path->_setAttribute
		  (
		   path				=> $paths[0],
		   volname			=> $volname,
		   quota			=> $quota,
		   used				=> $used,
		   percent			=> $percent,
		   partition			=> $partition,
		  );
		delete $paths{$paths[0]};
		shift @paths;

	    }

	    if ( $operation eq 'diskfree' ) {

		my ($volname,$total,$used,$avail,$percent) = split;
		$percent =~ s/%//g; # Don't need it -- want numeric result

		$path->_setAttribute
		  (
		   path				=> $paths[0],
		   volname			=> $volname,
		   total			=> $total,
		   used				=> $used,
		   avail			=> $avail,
		   percent			=> $percent,
		  );
		delete $paths{$paths[0]};
		shift @paths;

	    }

	    if ( $operation eq 'examine' ) {

		if ( /Volume status for vid = (\d+) named (\S+)/ ) {

		    $path->_setAttribute
		      (
		       path			=> $paths[0],
		       id			=> $1,
		       volname			=> $2,
		      );

		    #
		    # Looking at Transarc's code, we can safely assume we'll
		    # get this output in the order shown. Note we ignore the
		    # "Message of the day" and "Offline reason" output for
		    # now.  Read until we hit a blank line.
		    #
		    while ( defined($_ = $self->{handle}->getline()) ) {

			last if /^\s*$/;

			if ( /Current disk quota is (\d+|unlimited)/ ) {
			    $path->_setAttribute
			      (
			       quota		=>  $1 eq "unlimited" ? 0 : $1,
			      );
			}

			if ( /Current blocks used are (\d+)/ ) {
			    $path->_setAttribute( used => $1 );
			}

			if ( /The partition has (\d+) blocks available out of (\d+)/ ) {
			    $path->_setAttribute
			      (
			       avail		=> $1,
			       total		=> $2,
			      );
			}
		    }

		    delete $paths{$paths[0]};
		    shift @paths;

		}

	    }

	}

	$result->_addPath($path);

    }

    if ( $operation eq 'storebehind' ) {

	$result->_setAttribute( asynchrony => $default );

	#
	# This is ugly, but we get the default last, and it would be nice
	# to put this value into the Path objects as well, rather than the
	# string 'default'.
	#
	foreach my $path ( $result->getPaths() ) {
	    if ( defined($path->asynchrony()) && $path->asynchrony() eq 'default' ) {
		$path->_setAttribute( asynchrony => $default );
	    }
	}
    }

    foreach my $pathname ( keys %paths ) {

	my $path = AFS::Object::Path->new
	  (
	   path			=> $pathname,
	   error		=> "Unable to determine results",
	  );

	$result->_addPath($path);

    }

    $errors++ unless $self->_reap_cmds( allowstatus => 1 );

    return if $errors;
    return $result;

}

sub exportafs {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object->new();

    $self->{operation} = "exportafs";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {

	/translator is (currently )?enabled/ && do {
	    $result->_setAttribute( enabled => 1 );
	};

	/translator is disabled/ && do {
	    $result->_setAttribute( enabled => 0 );
	};

	/convert owner mode bits/ && do {
	    $result->_setAttribute( convert => 1 );
	};

	/strict unix/ && do {
	    $result->_setAttribute( convert => 0 );
	};

	/strict \'?passwd sync\'?/ && do {
	    $result->_setAttribute( uidcheck => 1 );
	};

	/no \'?passwd sync\'?/ && do {
	    $result->_setAttribute( uidcheck => 0 );
	};

	/allow mounts/i && do {
	    $result->_setAttribute( submounts => 1 );
	};

	/Only mounts/i && do {
	    $result->_setAttribute( submounts => 0 );
	};

    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub getcacheparms {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::CacheManager->new();

    $self->{operation} = "getcacheparms";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {
	if ( /using (\d+) of the cache.s available (\d+) 1K/ ) {
	    $result->_setAttribute
	      (
	       used			=> $1,
	       avail			=> $2,
	      );
	}
    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub getcellstatus {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::CacheManager->new();

    $self->{operation} = "getcellstatus";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {

	if ( /Cell (\S+) status: (no )?setuid allowed/ ) {
	    my $cell = AFS::Object::Cell->new
	      (
	       cell			=> $1,
	       status			=> $2 ? 0 : 1,
	      );
	    $result->_addCell($cell);
	}

    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub getclientaddrs {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::CacheManager->new();

    $self->{operation} = "getclientaddrs";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    my @addresses = ();

    while ( defined($_ = $self->{handle}->getline()) ) {
	chomp;
	s/^\s+//;
	s/\s+$//;
	push(@addresses,$_);
    }

    $result->_setAttribute( addresses => \@addresses );

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub getcrypt {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::CacheManager->new();

    $self->{operation} = "getcrypt";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {

	if ( /Security level is currently (crypt|clear)/ ) {
	    $result->_setAttribute( crypt => ($1 eq 'crypt' ? 1 : 0) );
	}

    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub getserverprefs {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::CacheManager->new();

    $self->{operation} = "getserverprefs";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {

	s/^\s+//g;
	s/\s+$//g;

	my ($name,$preference) = split;

	my $server = AFS::Object::Server->new
	  (
	   server		=> $name,
	   preference		=> $preference,
	  );

	$result->_addServer($server);

    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub listaliases {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::CacheManager->new();

    $self->{operation} = "listaliases";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {

	if ( /Alias (.*) for cell (.*)/ ) {
	    my $cell = AFS::Object::Cell->new
	      (
	       cell			=> $2,
	       alias			=> $1,
	      );
	    $result->_addCell($cell);
	}

    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub listcells {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::CacheManager->new();

    $self->{operation} = "listcells";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {

	if ( /^Cell (\S+) on hosts (.*)\.$/ ) {
	    my $cell = AFS::Object::Cell->new
	      (
	       cell			=> $1,
	       servers			=> [split(/\s+/,$2)],
	      );
	    $result->_addCell($cell);
	}

    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub lsmount {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::CacheManager->new();

    $self->{operation} = "lsmount";

    return unless $self->_parse_arguments(%args);

    my $errors = 0;

    $errors++ unless $self->_exec_cmds( stderr => 'stdout' );

    my @dirs = ref $args{dir} eq 'ARRAY' ? @{$args{dir}} : ($args{dir});
    my %dirs = map { $_ => 1 } @dirs;

    while ( defined($_ = $self->{handle}->getline()) ) {

	my $current = shift @dirs;
	delete $dirs{$current};

	my $path = AFS::Object::Path->new( path => $current );

	if ( /fs: Can.t read target name/ ) {
	    $path->_setAttribute( error => $_ );
	} elsif ( /fs: File '.*' doesn't exist/ ) {
	    $path->_setAttribute( error => $_ );
	} elsif ( /fs: you may not use \'.\'/ ) {
	    $_ .= $self->{handle}->getline();
	    $path->_setAttribute( error => $_ );
	} elsif ( /\'(.*?)\' is not a mount point/ ) {
	    $path->_setAttribute( error => $_ );
	} elsif ( /^\'(.*?)\'.*?\'(.*?)\'$/ ) {

	    my ($dir,$mount) = ($1,$2);

	    $path->_setAttribute( symlink => 1 ) if /symbolic link/;
	    $path->_setAttribute( readwrite => 1 ) if $mount =~ /^%/;
	    $mount =~ s/^(%|\#)//;

	    my ($volname,$cell) = reverse split(/:/,$mount);

	    $path->_setAttribute( volname => $volname );
	    $path->_setAttribute( cell => $cell) if $cell;

	} else {

	    $self->_Carp("fs lsmount: Unrecognized output: '$_'");
	    $errors++;
	    next;

	}

	$result->_addPath($path);

    }

    foreach my $dir ( keys %dirs ) {
        my $path = AFS::Object::Path->new
          (
           path			=> $dir,
           error		=> "Unable to determine results",
          );
        $result->_addPath($path);
    }

    $errors++ unless $self->_reap_cmds( allowstatus => 1 );

    return if $errors;
    return $result;

}

#
# This is deprecated in newer versions of OpenAFS
#
sub monitor {
    my $self = shift;
    $self->_Carp("fs monitor: This operation is deprecated and no longer supported");
    return;
}

sub sysname {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::CacheManager->new();

    $self->{operation} = "sysname";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    my @sysname = ();

    while ( defined($_ = $self->{handle}->getline()) ) {

	if ( /Current sysname is \'?([^\']+)\'?/ ) {
	    $result->_setAttribute( sysname => $1 );
	} elsif ( s/Current sysname list is // ) {
	    while ( s/\'([^\']+)\'\s*// ) {
		push(@sysname,$1);
	    }
	    $result->_setAttribute( sysnames => \@sysname );
	    $result->_setAttribute( sysname => $sysname[0] );
	}

    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub wscell {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::CacheManager->new();

    $self->{operation} = "wscell";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {
	next unless /belongs to cell\s+\'(.*)\'/;
	$result->_setAttribute( cell => $1 );
    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

1;

