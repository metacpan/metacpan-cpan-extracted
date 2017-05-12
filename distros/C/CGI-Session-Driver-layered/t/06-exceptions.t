use strict;
use warnings;
use CGI::Session;
use File::Path qw(rmtree);

use Test::More tests => 16;
use Test::Exception;

my @tmpdirs = qw(tmp1 tmp2);
for (@tmpdirs) {
	mkdir($_) || die "Couldn't make dir $_: $!\n";
}

END {
	rmtree($_) for @tmpdirs;
}

#use Data::Dumper;
sub X {
	#my @files = glob('tmp?/*');
	#diag(Dumper(\@files));
}

my %die_on;

{
	package CGI::Session::Driver::file2;

	our @ISA = qw(CGI::Session::Driver::file);
	$INC{'CGI/Session/Driver/file2.pm'} = __FILE__;
	
	sub init {
		if ($die_on{init}) {
			die "init";
		}
		return shift->SUPER::init(@_);
	}
	
	sub retrieve {
		if ($die_on{retrieve}) {
			die "retrieve";
		}
		return shift->SUPER::retrieve(@_);
	}
	
	sub store {
		if ($die_on{store}) {
			die "store";
		}
		return shift->SUPER::store(@_);
	}


	sub remove {
		if ($die_on{remove}) {
			die "remove";
		}
		return shift->SUPER::remove(@_);
	}

	sub traverse {
		if ($die_on{traverse}) {
			die "traverse";
		}
		return shift->SUPER::traverse(@_);
	}
}

my $args = { 
	Layers => [
	   {
	     Driver    => 'file',
	     Directory => $tmpdirs[0],
	   },
	   {
	     Driver     => 'file2',
	     Directory  => $tmpdirs[1],
	   }
	]
};

my $id;

lives_ok {
	local $die_on{init} = 1;
	my $session = CGI::Session->new("driver:layered", undef, $args);

	isa_ok($session, 'CGI::Session');
	
	$session->param(test1 => $$);
	$session->flush;
	
	$id = $session->id;
} 'created session' || die "No session\n";

X();

lives_ok {
	local $die_on{retrieve} = 1;
	my $session = CGI::Session->new("driver:layered", $id, $args);

	isa_ok($session, 'CGI::Session');
	
	$session->param(test1 => $$ + 1);
	$session->flush;
};

X();

lives_ok {
	local $die_on{store} = 1;
	my $session = CGI::Session->new("driver:layered", $id, $args);

	isa_ok($session, 'CGI::Session');
	
	$session->param(test1 => $$ + 2);
	$session->flush;
};

X();

lives_ok {
	local $die_on{traverse} = 1;
	my $count = 0;
	my $counter = sub { $count++ };
	my $session = CGI::Session->new("driver:layered", $id, $args);
	my $driver  = $session->_driver;
	
	$driver->traverse($counter);
	
	is($count, 1);
};

X();

lives_ok {
	# check that it has been stored in both places by this point
	my $count = 0;
	my $counter = sub { $count++ };
	my $session = CGI::Session->new("driver:layered", $id, $args);
	
	my @drivers = $session->_driver->_drivers;
	
	foreach my $driver (@drivers) {
		$driver->traverse($counter);
	}
	
	is($count, 2);
	
};

X();

lives_ok {
	local $die_on{remove} = 1;
	my $session = CGI::Session->new("driver:layered", $id, $args);

	$session->delete;
};

X();

lives_ok {
	# check that it has been delete in one driver
	my $count = 0;
	my $counter = sub { $count++ };
	my $session = CGI::Session->new("driver:layered", $id, $args);
	
	my @drivers = $session->_driver->_drivers;
	
	foreach my $driver (@drivers) {
		$driver->traverse($counter);
	}
	
	is($count, 1);
	
};

X();

lives_ok {
	my $session = CGI::Session->new("driver:layered", $id, $args);

	$session->delete;
};

X();

lives_ok {
	# check that it has been delete in one driver
	my $count = 0;
	my $counter = sub { $count++ };
	my $session = CGI::Session->new("driver:layered", $id, $args);
	
	my @drivers = $session->_driver->_drivers;
	
	foreach my $driver (@drivers) {
		$driver->traverse($counter);
	}
	
	is($count, 0);
	
};

X();