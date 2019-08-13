package CLI::Driver::CommonRole;

use Modern::Perl;
use Moose::Role;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use Devel::Confess;
use Capture::Tiny 'capture';
use Time::localtime;

#########################################################################################

has verbosity => (
	is      => 'rw',
	isa     => 'Num',
	lazy    => 1,
	builder => '_build_verbosity',
);

#########################################################################################

method chdir (Str $dir) {

	$self->verbose3("chdir($dir)");
	chdir($dir) or confess "failed to chdir to $dir: $!";
}

method die (Str $str) {

	chomp $str;
	die "[ERROR] $str\n";
}

method fatal (Str $str, Num $frames? = 0) {

	chomp $str;

	my $caller = '';
	if ($frames) {
		$caller = sprintf " %s", ( caller($frames) )[3];
	}

	printf STDERR "[FATAL%s] $str\n", $caller;
	exit 1;
}

method localdatetime ($time = time) {

	my $l = localtime($time);

	my $str = sprintf(
		'%04d-%02d-%02d %02d:%02d:%02d',
		$l->year + 1900,
		$l->mon + 1,
		$l->mday, $l->hour, $l->min, $l->sec
	);

	return $str;
}

method system (Str  :$cmd,
               Bool :$confess_on_err = 1,
               Bool :$capture = 0) {

	$self->verbose($cmd);

	if ($capture) {
		my ( $stdout, $stderr, $exit ) = capture {
			system($cmd);
		};

		if ( $exit and $confess_on_err ) {
			confess $stderr;
		}

		return ( $stdout, $stderr, $exit );
	}
	else {
		system($cmd);
		my $exit = $? >> 8;

		if ( $exit and $confess_on_err ) {
			confess "last command failed with exit code $exit";
		}

		return $exit;
	}
}

method verbose (Str $str, Num $frames? = 1) {

	$self->_verbose( 1, $str, $frames + 1 );
}

method verbose2 (Str $str, Num $frames? = 1) {

	$self->_verbose( 2, $str, $frames + 1 );
}

method verbose3 (Str $str, Num $frames? = 1) {

	$self->_verbose( 3, $str, $frames + 1 );
}

method warn (Str $str, Num $frames? = 1) {

	chomp $str;

	my $caller = '';
	if ($frames) {
		$caller = sprintf " %s", ( caller($frames) )[3];
	}

	printf STDERR "[WARN%s] $str\n", $caller;
}

######################################################################

method _build_verbosity {

	my $level = 0;
	$level = $ENV{VERBOSE} if $ENV{VERBOSE};

	return $level;
}

method _verbose (Num $level, Str $str, Num $frames) {

	if ( $self->verbosity >= $level ) {
		chomp $str;
		my $caller = ( caller($frames) )[3];
		printf STDERR "[VERBOSE-%d] ($caller) $str\n", $level;
	}
}

1;
