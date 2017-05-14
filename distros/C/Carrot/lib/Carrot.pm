package Carrot
# /type library
# //tabulators
#	::Individuality::Controlled
# /capability "Maintain a global identifier for access to the meta provider "
{
	use strict;
	use warnings 'FATAL' => 'all';

	# aim: ($Carrot::Progress eq 'CARROT')
	BEGIN {
		binmode(STDOUT, ":utf8");
		binmode(STDERR, ":utf8");

		$Carrot::Progress = 'C';
		require Carrot::Meta::Greenhouse;

		$Carrot::Progress .= 'A';
		require('Carrot./manual_modularity.pl');
	} #BEGIN
	$Carrot::Progress .= 'R';

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors',
		my $meta_provider = '::Meta::Provider');
	$Carrot::Progress .= 'R';

	$meta_provider->final_setup; # must leave the constructor for setup
	$Carrot::Progress .= 'O';

	my $carrot_main = Carrot::Meta::Greenhouse::carrot_main;
	eval {
		if (defined($carrot_main))
		{
			$meta_provider->evt_package_load_before(
				'main', $carrot_main);
		} else {
			$meta_provider->modularity(
				'main', $PROGRAM_NAME, 0, 'Carrot');
		}
		return(IS_TRUE);

	} or $translated_errors->escalate(
		'activate_main',
		[$0],
		$EVAL_ERROR);
	$Carrot::Progress .= 'T';

# =--------------------------------------------------------------------------= #

sub diversity
# /type function
# /effect "Reminder that this sub isn't the implementation of diversity."
# //parameters
# //returns
{
	die('Technically diversity is $this in Prepare.pm.');
}

sub modularity
# /type function
# /effect "Wrapper to the homonymous method of the meta provider"
# //parameters
# //returns
#	::Meta::Monad::Phase::Begin
{
	return($meta_provider->modularity(caller));
}

sub individuality
# /type function
# /effect "Wrapper to the homonymous method of the meta provider"
# //parameters
# //returns
#	::Meta::Monad::Phase::Run
{
	return($meta_provider->individuality(caller));
}

#NOTE: caller(0) doesn't give information about the calling block.
#	This information can only be obtained by a search through caller(1..N).
#	That is costly and not even guaranteed to work.
#	Ideally [caller(0)]->[11] would be BEGIN, UNITCHECK or ''.
#	caller(1) assumes nobody tries eval {$meta_monad = Carrot:meta_monad}.
sub expressiveness
# /type function
# /effect "Selector for methods of the meta provider"
# //parameters
# //returns
#	::Meta::Monad
{
	my $caller1 = [caller(1)]; # skew due to information mangling
	my $block_name = $caller1->[RDX_CALLER_SUB_NAME];
	if (substr($block_name, -7) eq '::BEGIN')
	{
		return($meta_provider->modularity(caller));

	} elsif ($block_name eq '')
	{
		return($meta_provider->individuality(caller));

	} else {
		die("Don't know how to handle block '$block_name'.");
	}

}

sub main
# /type function
# /effect "Returns the script file name containing the main routine."
# //parameters
#	meta_provider
# //returns
{
	unless (defined($carrot_main))
	{
		die("No --carrot-main=... given.");
	}

	return($carrot_main);
}

sub import
# /type function
# /effect "Issues a warning only."
# //parameters
# //returns
{
#	return if((caller)[RDX_CALLER_LINE] == 0); # perl -MCarrot
	warn($translated_errors->message_text('require_preferred', []));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.309
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
