package Check::Socket;

use base qw(Exporter);
use strict;
use warnings;

use Config;
use Readonly;
use Socket;

our $ERROR_MESSAGE;
Readonly::Array our @EXPORT_OK => qw(check_socket $ERROR_MESSAGE);

our $VERSION = 0.04;

sub check_socket {
	my ($config_hr, $os, $env_hr) = @_;

	$config_hr ||= \%Config;
	$os ||= $^O;
	$env_hr ||= \%ENV;

	if ($env_hr->{PERL_CORE} and $config_hr->{'extensions'} !~ /\bSocket\b/) {
		$ERROR_MESSAGE = 'Socket extension unavailable.';
		return 0;
	}

	if ($env_hr->{PERL_CORE} and $config_hr->{'extensions'} !~ /\bIO\b/) {
		$ERROR_MESSAGE = 'IO extension unavailable.';
		return 0;
	}

	if ($os eq 'os2') {
		eval { IO::Socket::pack_sockaddr_un('/foo/bar') || 1 };
		if ($@ =~ /not implemented/) {
			$ERROR_MESSAGE = "$os: Compiled without TCP/IP stack v4.";
			return 0;
		}
	}

	if ($os =~ m/^(?:qnx|nto|vos)$/ ) {
		$ERROR_MESSAGE = "$os: UNIX domain sockets not implemented.";
		return 0;
	}

	if ($os eq 'MSWin32') {
		if ($env_hr->{CONTINUOUS_INTEGRATION}) {
			# https://github.com/Perl/perl5/issues/17429
			$ERROR_MESSAGE = "$os: Skip sockets on CI.";
			return 0;
		}

		# https://github.com/Perl/perl5/issues/17575
		if (! eval { socket(my $sock, PF_UNIX, SOCK_STREAM, 0) }) {
			$ERROR_MESSAGE = "$os: AF_UNIX unavailable or disabled.";
			return 0;
		}
	}

	return 1;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Check::Socket - Check socket communication functionality.

=head1 SYNOPSIS

 use Check::Socket qw(check_socket $ERROR_MESSAGE);

 my $ret = check_socket();
 print $ERROR_MESSAGE."\n";

=head1 DESCRIPTION

There is need of check for socket communication functionality in tests.
Actually we have many duplicated and not same check code in distributions. Sic!

Intent of this module is create common code for check and test all behaviours.
Extra thing is error message which describe issue.

=head1 SUBROUTINES

=head2 C<check_socket>

 my $ret = check_socket();

Check possibility of socket communication functionality on system.
Return value is 1 as possible use of socket functionality or 0 as not possible use of
socket functionality.
If return value is 0, set C<$ERROR_MESSAGE> variable.

Returns 0/1.

=head1 ERRORS

 check_socket():
         Set $ERROR_MESSAGE variable if $ret is 0:
                 Socket extension unavailable.
                 IO extension unavailable.
                 $^O: AF_UNIX unavailable or disabled.
                 $^O: Compiled without TCP/IP stack v4.
                 $^O: Skip sockets on CI.
                 $^O: UNIX domain sockets not implemented.

=head1 EXAMPLE1

=for comment filename=check_socket.pl

 use strict;
 use warnings;

 use Check::Socket qw(check_socket $ERROR_MESSAGE);

 if (check_socket()) {
         print "We could use socket communication.\n";
 } else {
         print "We couldn't use socket communication.\n";
         print "Error message: $ERROR_MESSAGE\n";
 }

 # Output on Unix:
 # We could use socket communication.

=head1 EXAMPLE2

=for comment filename=check_fork_and_socket.pl

 use strict;
 use warnings;

 use Check::Fork qw(check_fork);
 use Check::Socket qw(check_socket);

 if (! check_fork()) {
         print "We couldn't fork.\n";
         print "Error message: $Check::Fork::ERROR_MESSAGE\n";
 } elsif (! check_socket()) {
         print "We couldn't use socket communication.\n";
         print "Error message: $Check::Socket::ERROR_MESSAGE\n";
 } else {
         print "We could use fork and socket communication.\n";
 }

 # Output on Unix:
 # We could use fork and socket communication.

=head1 DEPENDENCIES

L<Config>,
L<Exporter>,
L<Readonly>,
L<Socket>.

=head1 SEE ALSO

=over

=item L<Check::Fork>

Check fork functionality.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Check-Socket>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
