package CPAN::Digger::Tools;
use strict;
use warnings;

our $VERSION = '0.08';

use base 'Exporter';
our @EXPORT = qw(slurp LOG ERROR WARN);

sub slurp {
	my $file = shift;
	open my $fh, '<', $file or die;
	local $/ = undef;
	<$fh>;
}

sub ERROR {
	_log( 'ERROR', @_ );
}

sub WARN {
	_log( 'WARN', @_ );
}

sub LOG {
	_log( 'LOG', @_ );
}

sub _log {
	my ( $level, @msg ) = @_;

	return if $ENV{DIGGER_SILENT};

	#return if $level eq 'LOG';

	my $time = POSIX::strftime( "%Y-%b-%d %H:%M:%S", localtime );

	# need to interpolate outside the printf format as there might be % signs in @msg somewhere
	printf STDERR "%5s - %s - %s\n", $level, $time, "@msg";

	return;
}


1;
