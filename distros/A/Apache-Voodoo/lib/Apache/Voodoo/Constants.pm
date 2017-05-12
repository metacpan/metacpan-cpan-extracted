################################################################################
#
# Apache::Voodoo::Constants
#
# This package provide an OO interface to retrive the various paths and config
# settings used by Apache Voodoo.
#
################################################################################
package Apache::Voodoo::Constants;

$VERSION = "3.0200";

use strict;
use warnings;

my $self;

sub new {
	my $class       = shift;
	my $config_file = shift;

	if (ref($self)) {
		if ($config_file) {
			$self->{_conf_package} = $config_file;
			$self->_init();
		}
		return $self;
	}

	$self = {
		_conf_package => $config_file || 'Apache::Voodoo::MyConfig'
	};

	bless($self,$class);

	$self->_init();

	return $self;
}

sub _init {
	my $self = shift;

	my $p = $self->{_conf_package};
	my $f = $self->{_conf_package};
	$f =~ s/::/\//g;
	$f .= '.pm';

	eval {
		require $f;
	};
	if ($@) {
		die "$@\n".
		    "Can't find $p.  This probably means that Apache Voodoo hasn't been configured yet.\n".
		    "Please do so by running \"voodoo-control setconfig\"\n";
	}

	unless (ref(eval '$'.$p."::CONFIG") eq "HASH") {
		die "There was an error loading $p.  Please run \"voodoo-control setconfig\"\n";
	}

	# copy the config.
	my %h = eval '%{$'.$p."::CONFIG}";
	foreach (keys %h) {
		$self->{$_} = $h{$_};
	}
}

sub apache_gid    { return $_[0]->{APACHE_GID};    }
sub apache_uid    { return $_[0]->{APACHE_UID};    }
sub code_path     { return $_[0]->{CODE_PATH};     }
sub conf_file     { return $_[0]->{CONF_FILE};     }
sub conf_path     { return $_[0]->{CONF_PATH};     }
sub install_path  { return $_[0]->{INSTALL_PATH};  }
sub prefix        { return $_[0]->{PREFIX};        }
sub session_path  { return $_[0]->{SESSION_PATH};  }
sub tmpl_path     { return $_[0]->{TMPL_PATH};     }
sub updates_path  { return $_[0]->{UPDATES_PATH};  }
sub debug_dbd     { return $_[0]->{DEBUG_DBD};     }
sub debug_path    { return $_[0]->{DEBUG_PATH};    }
sub use_log4perl  { return $_[0]->{USE_LOG4PERL};  }
sub log4perl_conf { return $_[0]->{LOG4PERL_CONF}; }

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
