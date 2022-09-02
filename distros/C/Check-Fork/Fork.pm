package Check::Fork;

use base qw(Exporter);
use strict;
use warnings;

use Config;
use Readonly;

our $ERROR_MESSAGE;
Readonly::Array our @EXPORT_OK => qw(check_fork $ERROR_MESSAGE);

our $VERSION = 0.03;

sub check_fork {
	my ($config_hr, $os) = @_;

	$config_hr ||= \%Config;
	$os ||= $^O;

	if ($config_hr->{'d_fork'}) {
		return 1;
	} elsif ($config_hr->{'d_pseudofork'}) {
		return 1;
	} elsif ($os eq 'MSWin32' || $os eq 'NetWare') {
		if (! $config_hr->{'useithreads'}) {
			$ERROR_MESSAGE = "$os: No interpreter-based threading implementation.";
			return 0;
		}
		if ($config_hr->{'ccflags'} !~ /-DPERL_IMPLICIT_SYS/) {
			$ERROR_MESSAGE = "$os: No PERL_IMPLICIT_SYS ccflags set.";
			return 0;
		}
		return 1;
	}
	$ERROR_MESSAGE = 'No fork() routine available.';

	return 0;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Check::Fork - Check fork functionality.

=head1 SYNOPSIS

 use Check::Fork qw(check_fork $ERROR_MESSAGE);

 my $ret = check_fork($config_hr, $os);
 print $ERROR_MESSAGE."\n";

=head1 DESCRIPTION

There is need of check for fork functionality in tests.
Actually we have many duplicated and not same check code in distributions. Sic!

Intent of this module is create common code for check and test all behaviours.
Extra thing is error message which describe issue.

=head1 SUBROUTINES

=head2 C<check_fork>

 my $ret = check_fork($config_hr, $os);

Check possibility of forking functionality on system.

Variable C<$config_hr> is primarily for testing and default is C<\%Config::Config>.

Variable C<$os> is primarily for testing and default is C<$^O>.

Return value is 1 as possible fork() or 0 as not possible fork().
If return value is 0, set C<$ERROR_MESSAGE> variable.

Returns 0/1.

=head1 ERRORS

 check_fork():
         Set $ERROR_MESSAGE variable if $ret is 0:
                 No fork() routine available.
                 $^O: No interpreter-based threading implementation.
                 $^O: No PERL_IMPLICIT_SYS ccflags set.

=head1 EXAMPLE1

=for comment filename=check_fork.pl

 use strict;
 use warnings;

 use Check::Fork qw(check_fork $ERROR_MESSAGE);

 if (check_fork()) {
         print "We could fork.\n";
 } else {
         print "We couldn't fork.\n";
         print "Error message: $ERROR_MESSAGE\n";
 }

 # Output on Unix with Config{'d_fork'} set:
 # We could fork.

 # Output on Unix without Config{'d_fork'} set:
 # We couldn't fork.
 # Error message: No fork() routine available.

 # Output on Windows without $Config{'useithreads'} set:
 # We couldn't fork.
 # Error message: MSWin32: No interpreter-based threading implementation.

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

=head1 EXAMPLE3

=for comment filename=test_fork_and_socket.pl

 use strict;
 use warnings;

 use Check::Fork qw(check_fork);
 use Check::Socket qw(check_socket);
 use Test::More 'tests' => 1;

 SKIP: {
         skip $Check::Fork::ERROR_MESSAGE, 1 unless check_fork();
         skip $Check::Socket::ERROR_MESSAGE, 1 unless check_socket();

         ok(1, 'Fork and Socket test');
 };

 # Output on Unix:
 # 1..1
 # ok 1 - Fork and Socket test

=head1 DEPENDENCIES

L<Config>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Check::Socket>

Check socket functionality.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Check-Fork>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
