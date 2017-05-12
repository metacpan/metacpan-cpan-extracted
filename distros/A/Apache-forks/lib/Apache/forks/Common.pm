package
	Apache::forks::Common;	# hide from PAUSE

$VERSION = 0.03;

# Abstract class 

use strict;
use warnings;
use Carp ();

use constant BASE => '';	#to be set in concrete class definition

use constant MP2 => (exists $ENV{MOD_PERL_API_VERSION} &&
                     $ENV{MOD_PERL_API_VERSION} == 2) ? 1 : 0;
my @Import;
our $DEBUG = 0;
my $BASE;

BEGIN {
	if (MP2) {
		require mod_perl2;
		require Apache2::MPM;
		require Apache2::Module;
		require Apache2::ServerUtil;
	}
	else {
		require mod_perl;
		if (defined $mod_perl::VERSION && $mod_perl::VERSION > 1 &&
			$mod_perl::VERSION < 1.99) {
			require Apache;

			#not using Apache::fork support yet (may be non-portable and/or deprecated)
#			require Apache::fork;
#			Apache::fork::forkoption(1);
#			no warnings 'redefine';
#			*threads::_fork = \&Apache::fork::fork;
		} else {
			die "Apache.pm is unavailable or unsupported version ($mod_perl::VERSION)";
		}
	}
}

### functions ###
sub DEBUG { $DEBUG = shift() ? 1 : 0; }

sub debug {
	print STDERR "$_[1]\n" if $DEBUG >= $_[0] || threads->debug >= $_[0];
}

sub _load_forks {
	my $self = shift;
	$BASE = $self->BASE;
	$forks::DEFER_INIT_BEGIN_REQUIRE = 1;
	eval 'require '.$self->_forks();
	die "forks version 0.26 or later required--this is only version $forks::VERSION"
		unless defined($forks::VERSION) && $forks::VERSION >= 0.26;
	eval 'import '.$self->_forks();	#set environment and preload server process
	eval 'require '.$self->_forks_shared();
	eval 'import '.$self->_forks_shared();	#set environment
	
	{
		no warnings 'redefine';
		my $old_server_pre_startup = \&threads::_server_pre_startup;
		*threads::_server_pre_startup = sub {
			unless ($self->DEBUG) {
				### close IO pipes to silence possible warnings to terminal ###
				close(STDERR);
				close(STDOUT);
				close(STDIN);
			}
			$old_server_pre_startup->()
				if ref($old_server_pre_startup) eq 'CODE';
		};
	}
}

sub childinit {
	threads->isthread;
	my $timestamp = localtime(time);
	debug(1, "[$timestamp] [notice] $$:".threads->tid
		." Apache::$BASE PerlChildInitHandler executed");

	1;
}

### methods ###
sub _forks { return shift->BASE; }

sub _forks_shared { return shift->BASE.'::shared'; }

sub import {
	my $self = shift;
	$self->_forks->import(@_);
	$self->_forks_shared->import();	#kludge: insures correct %INC for forks::shared

	my $timestamp = localtime(time);
	if (MP2) {
		if (!@Import) {
			Carp::carp("Apache MPM '".Apache2::MPM->show()
				."' is not supported: "
				."This package can't be used under threaded MPMs: "
				."Only 'Prefork' MPM is supported at this time\n")
			and return if Apache2::MPM->is_threaded;
			
			my $s = Apache2::ServerUtil->server;
			$s->push_handlers(PerlChildInitHandler => \&childinit);
			debug(1, "[$timestamp] [notice] $$:".threads->tid
				." Apache::".$self->_forks." PerlChildInitHandler enabled");
		}
	} else {
		Carp::carp("Apache.pm was not loaded\n")
		and return unless $INC{'Apache.pm'};

		if (!@Import and Apache->can('push_handlers')) {
			Apache->push_handlers(PerlChildInitHandler => \&childinit);
			debug(1, "[$timestamp] [notice] $$:".threads->tid
				." Apache::".$self->_forks." PerlChildInitHandler enabled");
		}
	}

	push @Import, [@_];
}

package
	Apache::forks::common::shared;	# hide from PAUSE

sub import {
	my $self = shift;
	$self->_forks_shared->import(@_);
}

1;
