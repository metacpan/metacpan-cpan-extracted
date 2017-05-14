package Carrot::Diversity::Block_Modifiers::Monad::Source_Code
# /type class
# //parent_classes
#	::Modularity::Package::Source_Code
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Monad/Source_Code./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

# =--------------------------------------------------------------------------= #

sub modify_block_code
# /type method
# /effect ""
# //parameters
#	block_id
#	target
# //returns
{
	my ($this, $block_id, $target) = @ARGUMENTS;

	unless ($$this =~ s{
		(?:\012|\015\012?)\#--8<--\ \w+-$block_id-head\ -->8--\#\K
		(.*
		(?:\012|\015\012?)\}\ \#--8<--\ \w+-$block_id-close\ -->8--\#)
	}{
		$target->re_replacement_value($1);
	}sxe) {
		$translated_errors->advocate(
			'block_not_found',
			[$block_id]);
	}
	return;
}

sub modify_block_body_code
# /type method
# /effect ""
# //parameters
#	block_id
#	target
# //returns
{
	my ($this, $block_id, $target) = @ARGUMENTS;

	unless ($$this =~ s{
		(?:\012|\015\012?)\{\ \#--8<--\ \w+-$block_id-open\ -->8--\#\K
		(.*)
		((?:\012|\015\012?)\}\ \#--8<--\ \w+-$block_id-close\ -->8--\#)
	}{
		$target->re_replacement_value($1).$2;
	}sxe) {
		$translated_errors->advocate(
			'block_not_found',
			[$block_id]);
	}
	return;
}

sub remove_block_id
# /type method
# /effect ""
# //parameters
#	block_id
# //returns
{
	my ($this, $block_id) = @ARGUMENTS;

	unless ($$this =~ s{
		(?:\012|\015\012?)(\h*)\#--8<--\ \w+-$block_id-head\ -->8--\#
		.*
		(?:\012|\015\012?)\g{1}(?:\}|;)\ \#--8<--\ \w+-$block_id-(?:open)?close\ -->8--\#
	}{}sx) {

		require Data::Dumper;
		print(STDERR Data::Dumper::Dumper($this));

		$translated_errors->advocate(
			'block_not_found',
			[$block_id]);
	}
	return;
}

sub extract_modifier_block_body
# /type method
# /effect "Extract the source code of a subroutine by block id"
# //parameters
#	block_id
# /returns
#	::Personality::Abstract::Text
{
	my ($this, $block_id) = @ARGUMENTS;

	$$this =~ m
	{
		(?:\012|\015\012?)\{\ \#--8<--\ \w+-$block_id-open\ -->8--\#
		(.*)
		(?:\012|\015\012?)\}\ \#--8<--\ \w+-$block_id-close\ -->8--\#
	}sx;
	my $perl_code = $1;
	return($perl_code) if (defined($perl_code));

	return('') if ($$this =~ m
		{
			(?:\012|\015\012?)\;\ \#--8<--\ sub-$block_id-openclose\ -->8--\#
		}sx);

	$translated_errors->advocate(
		'block_not_found',
		[$block_id]);
}

sub seek_modifier_open
# /type method
# /effect ""
# //parameters
#	block_id
# /returns
#	::Personality::Abstract::Text
{
	my ($this, $block_id) = @ARGUMENTS;

	unless ($$this =~ m{
		(?:\012|\015\012?)\{\ \#--8<--\ \w+-$block_id-open\ -->8--\#
	}sxg) {
		$translated_errors->advocate(
			'block_not_found',
			[$block_id]);
	}
	return;
}

sub insert_before_first_sub
# /type method
# /effect ""
# //parameters
#	code
# //returns
{
	my ($this, $code) = @ARGUMENTS;

	my $modified = ($$this =~ s
		{
			((?:\012|\015\012?)\#--8<--\ sub-\w+-head\ -->8--\#)
		}
		{$code$1}sx);

	if ($modified == 0)
	{
		#FIXME: not helpful
		print(STDERR "$$this\n");
		die("Could not insert_before_first_sub.");
	}
	return($modified);
}

sub insert_after_modifier_block_head
# /type method
# /effect ""
# //parameters
#	block_id
#	perl_code
# //returns
{
	my ($this, $block_id, $perl_code) = @ARGUMENTS;

	unless($$this =~ s{
		((?:\012|\015\012?)\h+\#--8<--\ \w+-$block_id-head\ -->8--\#\K
	}{
		$perl_code
	}sx) {
		die("Could not match block id '$block_id'.");
	}
	return;
}

sub insert_after_modifier_block_open
# /type method
# /effect ""
# //parameters
#	block_id
#	perl_code
# //returns
{
	my ($this, $block_id, $perl_code) = @ARGUMENTS;

	unless($$this =~ s{
		\{\ \#--8<--\ \w+-$block_id-open\ -->8--\#\K
	}{
		$perl_code
	}sx) {
		die("Could not match block id '$block_id'.");
	}
	return;
}

sub insert_before_modifier_block_close
# /type method
# /effect ""
# //parameters
#	block_id
#	perl_code
# //returns
{
	my ($this, $block_id, $perl_code) = @ARGUMENTS;

	unless($$this =~ s{
		((?:\012|\015\012?)\h+\}\ \#--8<--\ \w+-$block_id-close\ -->8--\#)
	}{
		$perl_code$1
	}sx) {
		die("Could not match block id '$block_id'.");
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.92
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
