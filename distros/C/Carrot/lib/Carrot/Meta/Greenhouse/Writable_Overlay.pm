package Carrot::Meta::Greenhouse::Writable_Overlay
# /type class
# //parent_classes
#	[=parent_pkg=]
# /capability "Redirect file access to a writeable directory."
{
	use strict;
	use warnings 'FATAL' => 'all';
	use open qw(:encoding(utf8));

	BEGIN {
		require('Carrot/Meta/Greenhouse/Writable_Overlay./manual_modularity.pl');
	} #BEGIN

#	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
#		my $file_content = '::Meta::Greenhouse::File_Content',
#		my $compilation_name = '::Meta::Greenhouse::Compilation_Name',
#		my $fatal_syscalls = '::Meta::Greenhouse::Fatal_Syscalls',
#		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

	require Carrot::Meta::Greenhouse::File_Content;
	my $file_content = Carrot::Meta::Greenhouse::File_Content->constructor;

	require Carrot::Meta::Greenhouse::Compilation_Name;
	my $compilation_name = Carrot::Meta::Greenhouse::Compilation_Name->constructor;

	require Carrot::Meta::Greenhouse::Fatal_Syscalls;
	my $fatal_syscalls = Carrot::Meta::Greenhouse::Fatal_Syscalls->constructor;

	require Carrot::Meta::Greenhouse::Translated_Errors;
	my $translated_errors = Carrot::Meta::Greenhouse::Translated_Errors->constructor;

	my $cache = "$ENV{'HOME'}/.carrot/writable_overlay/$$compilation_name";
	my $cache_fnl = length($cache);
	my $index_file = "$cache.idx";
	my $index = {};
	my $xedni = {};
	my $highest_id = 0;
	my $prefix = '';
	my $prefix_fnl = 1;

	if (REDIRECT_FLAG) {
		unless (-e $cache)
		{
			$fatal_syscalls->mkdir($cache);
		}
		unless (-w $cache)
		{
			$translated_errors->advocate(
				'file_not_writable',
				[$cache]);
		}

		if (-f $index_file)
		{
			read_index();
		} else {
			create_index();
		}
	}

# =--------------------------------------------------------------------------= #

sub read_index
# /type method
# /effect ""
# //parameters
#	file_name
# //returns
{
	my $lines = $file_content->read_lines($index_file);
	my $deleted = 0;
	pop($lines);
	foreach my $line (@$lines)
	{
		if($line =~ m{\A#}saa)
		{
			next;

		} elsif ($line eq '')
		{
			$prefix = '';
			$prefix_fnl = 1;

		} elsif ($line =~ m{\A/}saa)
		{
			$prefix = $line;
			$prefix_fnl = length($prefix);

		} elsif ($line =~ m{\A((\d{8})\.\w+)\t(.*)\z}saa)
		{
			my ($redirected, $id, $logical) = ($1, $2, $3);
			if ($logical eq '-')
			{
				$logical = delete($xedni->{$redirected});
				delete($index->{$logical});
				$deleted += 1;

			} else {
				unless (substr($logical, 0, 1) eq '/')
				{
					$logical = $prefix.$logical;
				}
				$index->{$logical} = $redirected;
				$xedni->{$redirected} = $logical
			}

			$highest_id = $id;

		} else {
			die($line);
		}
	}
	$highest_id = int($highest_id);

#	if ($deleted > 1_000)
#	{
#		recreate_index();
#	}
	return;
}

sub recreate_index
# /type method
# /effect ""
# //parameters
# //returns
{
	create_index();
	my $keys = [sort(keys($index))];
	foreach my $key (@$keys)
	{
		update_index($index->{$key}, $key);
	}

	return;
}

sub create_index
# /type method
# /effect ""
# //parameters
# //returns
{
	print STDERR "CREATE CACHE $index_file\n" if (TRACE_FLAG);

	my $datetime = scalar(gmtime(time()));
	$file_content->overwrite_from($index_file,
		"# Automatically created on $datetime GMT.\n"
		."# Manual changes will get lost.\n");

	return;
}

sub update_index
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this, $id, $file_name) = @ARGUMENTS;

	if (substr($file_name, 0, 1) ne '/')
	{
			$prefix = '';
			$prefix_fnl = 1;

	} elsif (substr($file_name, 0, $prefix_fnl) ne $prefix)
	{
		foreach my $directory (@MODULE_SEARCH_PATH)
		{
			next unless (substr($file_name, 0, length($directory)) eq $directory);
			$prefix = $directory.'/';
			$prefix_fnl = length($prefix);
			$file_content->append_from($index_file, $prefix."\n");
			$file_name = substr($file_name, $prefix_fnl);
			last;
		}
	} else {
		$file_name = substr($file_name, $prefix_fnl);
	}
	$file_content->append_from($index_file, "$id\t$file_name\n");

	return;
}

sub redirect_read
# /type method
# /effect ""
# //parameters
#	file_name
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	return(IS_FALSE) unless (REDIRECT_FLAG);
	return(IS_FALSE) unless (exists($index->{$$file_name}));
#	return(IS_FALSE) if (substr($$file_name, 0, $cache_fnl) eq $cache);

	print STDERR "CACHE HIT $$file_name\n" if (TRACE_FLAG);
	$$file_name = "$cache/$index->{$$file_name}";

	return(IS_TRUE);
}

sub direct_read
# /type method
# /effect ""
# //parameters
#	file_name
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	return(IS_UNDEFINED) unless (REDIRECT_FLAG);
	return(IS_UNDEFINED) unless (substr($$file_name, 0, $cache_fnl) eq $cache);
	my $redirected = substr($$file_name, $cache_fnl+1);
	return(IS_UNDEFINED) unless (exists($xedni->{$redirected}));

	print STDERR "CACHE REVERSE HIT $$file_name\n" if (TRACE_FLAG);
	$$file_name = $xedni->{$redirected};

	return($redirected);
}

sub redirect_write
# /type function
# /effect ""
# //parameters
#	file_name
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	return(IS_FALSE) unless (REDIRECT_FLAG);
	return(IS_FALSE) if($this->redirect_read($file_name));

#	if ((-f $$file_name) and (-w $$file_name))
#	{
#		return(IS_FALSE);
#
#	} elsif (open(my $f, PKY_OPEN_MODE_READ_WRITE, $$file_name))
#	{
#		close($f);
#		unlink($$file_name);
#		return(IS_FALSE);
#	}
	print STDERR "CACHE MISS $$file_name\n" if (TRACE_FLAG);

	$highest_id += 1;

	my $ext = '.dat';
	if ($$file_name =~ m{(\.\w+)\z}s)
	{
		$ext = $1;
	}
	$index->{$$file_name} =
		my $redirected = sprintf('%08d', $highest_id).$ext;
	$xedni->{$redirected} = $$file_name;
	$this->update_index($redirected, $$file_name);
	$$file_name = "$cache/$redirected";

	return(IS_TRUE);
}

sub remove
# /type function
# /effect ""
# //parameters
#	physical
# //returns
{
	my ($this, $physical) = @ARGUMENTS;

	my $logical = $physical;
	my $redirected = $this->direct_read(\$logical);
	return unless(defined($redirected));

	delete($xedni->{$redirected});
	delete($index->{$logical});

	$this->update_index($redirected, '-');
	print(STDERR "DELETE CACHE $physical\n") if (TRACE_FLAG);
	unlink($physical) || die($physical); # not fatal

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.353
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
