package Carrot::Modularity::Package::Source_Code
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/Source_Code./manual_modularity.pl');
	} #BEGIN

	require Carrot::Meta::Greenhouse::Named_RE;
	my $named_re = Carrot::Meta::Greenhouse::Named_RE->constructor;

	require Carrot::Meta::Greenhouse::File_Content;
	my $file_content = Carrot::Meta::Greenhouse::File_Content->constructor;

	require Carrot::Modularity::Package::Source_Code::Begin_Block;
	my $begin_block_class =
		'Carrot::Modularity::Package::Source_Code::Begin_Block';

	$named_re->provide(
		my $re_perl_remove_data_or_end = 'perl_remove_data_or_end');

# =--------------------------------------------------------------------------= #

#sub attribute_construction
## /type method
## /effect "Constructs the attribute(s) of a newly created instance."
## //parameters
## //returns
#{
#	my $this = $_[THIS];
#
#	$$this = exists($_[SPX_VALUE]) ? $_[SPX_VALUE] : IS_UNDEFINED;
#
#	return;
#}

sub load
# /type method
# /effect ""
# //parameters
#	pkg_file
# //returns
{
	my ($this, $pkg_file) = @ARGUMENTS;

	return if (defined($$this));
	$pkg_file->read_into($$this);
	$$this =~ s{$re_perl_remove_data_or_end}{}o;

	return;
}

sub as_lines
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return([split(qr{(?:\012|\015\012)}, ${$_[THIS]})]);
}


sub store_in_file
# /type method
# /effect ""
# //parameters
#	file_name
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	$file_content->overwrite_from($file_name, $$this);
	return;
}

sub unique_matches
# /type method
# /effect ""
# //parameters
#	re
# //returns
{
	my ($this, $re) = @ARGUMENTS;

	my $symbols = [($$this =~ m{$re}sgx)];
	my $seen = {};
	my $unique = [];
	foreach my $symbol (@$symbols)
	{
		next if (exists($seen->{$symbol}));
		$seen->{$symbol} = IS_EXISTENT;
		push($unique, $symbol);
	}
	return($unique);
}

sub begin_block
# /type method
# /effect ""
# //parameters
#	code
# //returns
{
	return($begin_block_class->constructor($_[THIS]));
}

sub insert_after_modularity
# /type method
# /effect ""
# //parameters
#	code
# //returns
{
	my ($this, $code) = @ARGUMENTS;

	my $modified = ($$this =~ s
		{
			(?:\012|\015\012?)\h+
			my\h+\$expressiveness\h+=\h+Carrot::modularity(?:\(\))?;
			(?:\012|\015\012?)\K
		}
		{\t\t$code\n}sx);

	if ($modified == 0)
	{
		#FIXME: not helpful
		print(STDERR "$$this\n");
		die("Could not insert_after_modularity.");
	}
	return($modified);
}

sub insert_after_individuality
# /type method
# /effect ""
# //parameters
#	code
# //returns
{
	my ($this, $code) = @ARGUMENTS;

	my $modified = ($$this =~ s
		{
			(?:\012|\015\012?)\h+
			my\h+\$expressiveness\h+=\h+Carrot::individuality(?:\(\))?;
			(?:\012|\015\012?)\K
		}
		{\t$code\n}sx);

	if ($modified == 0)
	{
		#FIXME: not helpful
		print(STDERR "$$this\n");
		die("Could not insert_after_individuality.");
	}
	return($modified);
}

sub insert_before_perl_file_loaded
# /type method
# /effect ""
# //parameters
#	code
# //returns
{
	my ($this, $code) = @ARGUMENTS;

	my $modified = ($$this =~ s
		{
			((?:\012|\015\012?)\#\ =-+=\ \#
			(?:\012|\015\012?)+\h+return\h*\(PERL_FILE_LOADED\);
			(?:\012|\015\012?))
		}
		{\n$code\n$1}sx);

	if ($modified == 0)
	{
		#FIXME: not helpful
		print(STDERR "$$this\n");
		die("Could not insert_before_perl_file_loaded");
	}
	return($modified);
}

sub has_begin_block
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(${$_[THIS]} =~ m{(?:\012|\015\012?)\h+BEGIN\h+\{}s);
}

my $begin_block = q{
	BEGIN {
		my $expressiveness = Carrot::modularity;
		#--8<-- carrot-modularity-start -->8--#
		#--8<-- carrot-modularity-end -->8--#
	} #BEGIN
};
sub add_begin_block_after_warnings
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	unless ($$this =~ s
#		{use (warnings|strict)[^\015\012;]*;(?:\012|\015\012?)\K}
		{use warnings[^\015\012;]*;(?:\012|\015\012?)\K}
		{$begin_block}s)
	{
		die("Could not add a begin block.\n");
	}
	return;
}

my $carrot_modularity_start = '#--8<-- carrot-modularity-start -->8--#';
my $carrot_modularity_end = '#--8<-- carrot-modularity-end -->8--#';
sub add_modularity_markers
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	unless ($$this =~ s
		{((?:\012|\015\012?)\h+)my\h+\$expressiveness\h+=\h+Carrot::modularity(?:\(\))?;\K}
		{$1$carrot_modularity_start}saa)
	{
		die("Could not add carrot-modularity-start. $$this\n");
	}
	unless ($$this =~ s
		{(((?:\012|\015\012?)\h+)\} \#BEGIN)}
		{$1$carrot_modularity_end$2}saa)
	{
		die("Could not add carrot-modularity-end.\n");
	}
	return;
}

sub add_end_block_after_begin
# /type method
# /effect ""
# //parameters
#	id
#	shadow_tmp
# //returns
{
	my ($this, $id, $shadow_tmp) = @ARGUMENTS;

	my $end_block = qq{
	END { #$id
		Carrot::Modularity::Package::Shadow::compile(
			'$shadow_tmp');
	} #END-$id
};
	unless ($$this =~ s
		{(?:\012|\015\012?)\h+\}\ \#BEGIN\K}
		{$end_block}s)
	{
		print(STDERR "$$this\n");
		die("Could not add end block for file '$shadow_tmp'. $$this\n");
	}
	return;
}

sub has_carrot_individuality
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(${$_[THIS]} =~ m{(?:\012|\015\012?)\h*my\h+\$expressiveness\h+=\h+Carrot::individuality(?:\(\))?;}s);
}


my $carrot_individuality_start = '#--8<-- carrot-individuality-start -->8--#';
my $carrot_individuality_end = '#--8<-- carrot-individuality-end -->8--#';
sub add_individuality_markers
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	unless ($$this =~ s
		{(?:\012|\015\012?)\h*my\h+\$expressiveness\h+=\h+Carrot::individuality(?:\(\))?;\K}
		{\n\t$carrot_individuality_start\n\t$carrot_individuality_end}saa)
	{
		die("Could not add carrot-individuality-*.\n");
	}
	return;
}

my $carrot_individuality = q{
	my $expressiveness = Carrot::individuality;
	#--8<-- carrot-individuality-start -->8--#
	#--8<-- carrot-individuality-end -->8--#
};
sub add_individuality_after_end
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	unless ($$this =~ s
		{\}\ \#END-\d+(?:\012|\015\012?)\K}
		{$carrot_individuality}s)
	{
		print(STDERR "$$this\n");
		die("Could not add carrot_individuality.\n");
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.159
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
