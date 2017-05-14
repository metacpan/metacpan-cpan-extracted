package Carrot::Individuality::Singular::Process::Id::Child
# /type class
# /instances none
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $os_process = '::Individuality::Singular::Process::Id',
		my $kindergarden = '::Individuality::Singular::Process::Kindergarden');

# =--------------------------------------------------------------------------= #

sub fork_2fd_piped
# /type method
# /effect ""
# //parameters
#	method
#	*
# //returns
#	?
{
	my ($this, $method) = splice(\@ARGUMENTS, 0, 2);

	pipe(my $parent_in, my $child_out);
	pipe(my $child_in, my $parent_out);
	my $old_fh = select($child_in);
	$| = 1; # Perl autoflush magic
	select($parent_in);
	$| = 1;
	select($old_fh);

	my $pid = $os_process->fork;

	if ($pid < 0)
	{
		my $parent_pid = -$pid;

		close($parent_in);
		close($parent_out);

		$this->$method($parent_pid, $child_in, $child_out, @ARGUMENTS);
		exit(PDX_EXIT_SUCCESS);
	}

	$kindergarden->admit($pid);

	close($child_in);
	close($child_out);

	return($pid, $parent_in, $parent_out);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.48
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
