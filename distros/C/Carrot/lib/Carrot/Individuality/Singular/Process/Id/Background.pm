package Carrot::Individuality::Singular::Process::Id::Background
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');

#FIXME: doesn't have to be a distinguished_exception
	$distinguished_exceptions->provide(
		my $syscall_related = 'syscall_related');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $fatal_syscalls = '::Meta::Greenhouse::Fatal_Syscalls',

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub detach
# /type method
# /effect ""
# //parameters
# //returns
{
	my $this = shift(\@ARGUMENTS);

	$fatal_syscalls->open(*STDIN, PKY_OPEN_MODE_READ, OS_FS_NULL_DEVICE);
	$fatal_syscalls->open(*STDOUT, PKY_OPEN_MODE_WRITE, OS_FS_NULL_DEVICE);

	unless (POSIX::setsid())
	{
		$posix_setsid_failed->raise_exception(
			{'os_error' => $OS_ERROR},
			 'syscall' => 'posix_setsid',
			'subject' => $$,
			ERROR_CATEGORY_OS);
	}

	$fatal_syscalls->open(*STDERR,
		PKY_OPEN_MODE_WRITE . PKY_OPEN_MODE_DUPLICATE,
		*STDOUT);
#        $OS_SIGNALS{'HUP'} = 'IGNORE';
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.52
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
