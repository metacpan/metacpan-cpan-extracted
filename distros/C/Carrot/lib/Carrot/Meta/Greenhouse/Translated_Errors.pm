package Carrot::Meta::Greenhouse::Translated_Errors
# /type class
# /instances singular
# /attribute_type ::One_Anonymous::Scalar
# /capability "Generate error messages from language specific collections"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Translated_Errors./manual_modularity.pl');
	} #BEGIN

	require Carrot::Meta::Greenhouse::File_Content;
	my $file_content =
		Carrot::Meta::Greenhouse::File_Content->constructor;

	require Carrot::Meta::Greenhouse::Translated_Errors::Language;
	my $languages =
		Carrot::Meta::Greenhouse::Translated_Errors::Language->constructor;

	require Carrot::Meta::Greenhouse::Named_RE;
	my $named_re = Carrot::Meta::Greenhouse::Named_RE->constructor;

	$named_re->provide(
		my $re_perl_pkg_last_element = 'perl_pkg_last_element');

	my $universal = {};
	my $pkg_names = {};

	require Carrot::Meta::Greenhouse::Site_Directories;
	my $site_directories = Carrot::Meta::Greenhouse::Site_Directories->constructor;

	my $candidates = $site_directories->subdirectories('translated_errors');
	foreach my $directory (@$candidates)
	{
		foreach my $language ($languages->both)
		{
			my $file_name = "$directory/$language.txt";
			next unless(-f $file_name);
			__PACKAGE__->add_universal($language, $file_name);
		}
	}

# =--------------------------------------------------------------------------= #

#FIXME: duplicates ::Patterns and is already out of sync
sub dot_directory_from_file
# /type class_method
# /effect ""
# //parameters
#	pkg_file        ::Personality::Abstract::Text
# //returns
#	?
{
	return((($_[SPX_PKG_FILE] =~ m{\A(.+?)\.(?:[^/]+|/shadow.+)\z}saa)
			? $1
			: $_[SPX_PKG_FILE])
		.'.');
}

sub dot_ini_got_directory_name
# /type method
# /effect "Processes a directory name from an .ini file."
# //parameters
#	directory_name  ::Personality::Valued::File::Name::Type::Directory
# //returns
{
	my ($class, $directory_name) = @ARGUMENTS;

	$directory_name->require_fatally;

	foreach my $language ($languages->both)
	{
		my $file_name = $directory_name->entry("$language.txt");
		next unless($file_name->exists);
		$class->add_universal($language, $file_name);
	}

	return;
}

sub add_universal
# /type method
# /effect ""
# //parameters
#	language
#	file_name
# //returns
{
	my ($class, $language, $file_name) = @ARGUMENTS;

	unless (exists($universal->{$language}))
	{
		$universal->{$language} = [];
	}
	push($universal->{$language}, $class->parse_txt($file_name));

	return;
}

sub dot_ini_got_package_name
# /type class_method
# /effect "Processes a package name from an .ini file."
# //parameters
#       package_name    ::Modularity::Package::Name
# //returns
{
        my ($class, $package_name) = @ARGUMENTS;

	my $dot_directory = $package_name->dot_directory_actual;
	my $lang_dir = $dot_directory->directory_entry('translated_errors');
	$class->dot_ini_got_directory_name($lang_dir);

        return;
}

sub add_pkg_directory
# /type method
# /effect ""
# //parameters
#	caller
#	msg_name
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $caller, $msg_name) = @ARGUMENTS;

	my ($pkg_name, $pkg_file, undef) = @$caller;

	my $msg_dir = $this->dot_directory_from_file($pkg_file)
		. '/translated_errors';
	while (length($pkg_name) > 2)
	{
		$this->_add_pkg_directory($pkg_name, $msg_dir, $msg_name);
		last unless($pkg_name =~ s{$re_perl_pkg_last_element}{}o);
		last if (exists($pkg_names->{$pkg_name}));
		$msg_dir =~ s{\.?/[^/]+(\./translated_errors)}{$1}s;
	}

	return;
}

sub _add_pkg_directory
# /type method
# /effect ""
# //parameters
#	pkg_name
#	msg_dir
#	msg_name
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $pkg_name, $msg_dir, $msg_name) = @ARGUMENTS;

	unless (-d $msg_dir)
	{
		$pkg_names->{$pkg_name} = IS_UNDEFINED;
		return;
	}

	$pkg_names->{$pkg_name} = {};
	foreach my $language ($languages->both)
	{
		my $file_name = "$msg_dir/$language.txt";
		if (-f $file_name)
		{
			$pkg_names->{$pkg_name}{$language} =
				$this->parse_txt($file_name);
		} else {
			$pkg_names->{$pkg_name}{$language} =
				IS_UNDEFINED
		}
	}

	return;
}

sub find_format
# /type method
# /effect ""
# //parameters
#	caller
#	msg_name
# //returns
#	::Personality::Abstract::Text +undefined
{
	my ($this, $caller, $msg_name) = @ARGUMENTS;

	return($this->find_universal_format($caller, $msg_name)
		// $this->find_pkg_format($caller, $msg_name));
}

sub find_pkg_format
# /type method
# /effect ""
# //parameters
#	caller
#	msg_name
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $caller, $msg_name) = @ARGUMENTS;

	my $pkg_name = $caller->[RDX_CALLER_PACKAGE];
	unless (exists($pkg_names->{$pkg_name}))
	{
		$this->add_pkg_directory($caller, $msg_name);
	}

	while (length($pkg_name) > 2)
	{
		my $msg = $this->_find_pkg_format($pkg_name, $msg_name);
		return($msg) if (defined($msg));
		last unless($pkg_name =~ s{$re_perl_pkg_last_element}{}o);
	}

	if ($msg_name eq 'message_not_found')
	{
		die("Message not found and meta message not found.\n");
	}

	return(IS_UNDEFINED);
}

sub _find_pkg_format
# /type method
# /effect ""
# //parameters
#	pkg_name
#	msg_name
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $pkg_name, $msg_name) = @ARGUMENTS;

	return(IS_UNDEFINED) unless (defined($pkg_names->{$pkg_name}));

	my $messages = $pkg_names->{$pkg_name};
	foreach my $language ($languages->both)
	{
		next unless (defined($messages->{$language}));
		my $collection = $messages->{$language};
		next unless (exists($collection->{$msg_name}));
		return($collection->{$msg_name});
	}

	return(IS_UNDEFINED);
}

sub find_universal_format
# /type method
# /effect ""
# //parameters
#	caller
#	msg_name
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $caller, $msg_name) = @ARGUMENTS;

	my $pkg_name = $caller->[RDX_CALLER_FILE];
	foreach my $language ($languages->both)
	{
		next unless (exists($universal->{$language}));
		my $collection = $universal->{$language};
		foreach my $messages (@$collection)
		{
			next unless(exists($messages->{$msg_name}));
			return($messages->{$msg_name});
		}
	}

	return(IS_UNDEFINED);
}

sub parse_txt
# /type method
# /effect ""
# //parameters
#	file_name
# //returns
#	::Personality::Abstract::Array
{
	my ($this, $file_name) = @ARGUMENTS;

	my $lines = $file_content->read_lines($file_name);
	my $name = IS_UNDEFINED;
	my $message = [];
	my $messages = {};
	foreach my $line (@$lines)
	{
		next unless(length($line));
		next if(substr($line, 0, 1) eq '#');
		if ($line =~ m{\A(\w+)\z}saag)
		{
			if (defined($name))
			{
				$messages->{$name} = join("\n", @$message);
				$message = [];
			}
			$name = $1;

		} elsif ($line =~ m{\A((?: {8}|\t).*)\z}saag)
		{
			push($message, $1);

		} else {
			die("Couldn't recognize line '$line'.");
		}
	}
	if (defined($name) and @$message)
	{
		$messages->{$name} = join("\n", @$message);
	}

	return($messages);
}

sub _message_text
# /type method
# /effect ""
# //parameters
#	caller
#	msg_name
#	details
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $caller, $msg_name, $details) = @ARGUMENTS;

	my $format = $this->find_format($caller, $msg_name);
	return(sprintf($format, @$details)) if (defined($format));

	$format = $this->find_universal_format(
		$caller,
		'message_not_found');
	return(sprintf($format, $msg_name));
}

sub message_text
# /type method
# /effect ""
# //parameters
#	msg_name
#	details
# //returns
#	::Personality::Abstract::Text
{
	return(shift(\@ARGUMENTS)->_message_text([caller], @ARGUMENTS));
}

sub oppose
# /type method
# /effect ""
# //parameters
#	msg_name
#	details
#	depth
# //returns
{
	my ($this, $msg_name, $details, $depth) = @ARGUMENTS;

	$depth //= 1;
	my $caller0 = [caller(0)];
	my $caller1 = [caller($depth)];
	my $msg = "\n\n# $msg_name (opposed)\n"
		.$this->_message_text(
			[__PACKAGE__, __FILE__, __LINE__],
			'opponent',
			[$caller1->[RDX_CALLER_SUB_NAME], $caller1->[RDX_CALLER_LINE], $caller1->[RDX_CALLER_PACKAGE]])
		."\n\n"
		.$this->_message_text(
			$caller0,
			$msg_name,
			$details)
		."\n";
	die($msg);
	return;
}

sub advocate
# /type method
# /effect ""
# //parameters
#	msg_name
#	details
# //returns
{
	my ($this, $msg_name, $details) = @ARGUMENTS;

	my $calling_sub = (caller(1))[RDX_CALLER_SUB_NAME];
	$calling_sub =~ s{^.*::}{}sg;
	my ($calling_line, $calling_pkg) = (caller(0))[RDX_CALLER_LINE, RDX_CALLER_PACKAGE];
	my $msg = "\n\n# $msg_name (advocated)\n"
		.$this->_message_text(
			[caller],
			$msg_name,
			$details)
		."\n"
		.$this->_message_text(
			[__PACKAGE__, __FILE__, __LINE__],
			'origin',
			[$calling_line, $calling_sub, $calling_pkg])
		."\n";
	die($msg);
	return;
}

sub escalate
# /type method
# /effect ""
# //parameters
#	msg_name
#	details
#	eval_error
# //returns
{
	my ($this, $msg_name, $details, $eval_error) = @ARGUMENTS;

	unless ($eval_error =~ m{\A\n*# }s)
	{
		$eval_error = "\n# raw_die (wrap)\n$eval_error";
	}

	my $msg = "\n\n# $msg_name (escalated)\n"
		.$this->_message_text(
			[caller],
			$msg_name,
			$details)
		.$eval_error
		."\n";
	if ($this->hits_explicit_eval)
	{
		die($msg);
	} else {
		$this->publish($msg);
	}

	return;
}

sub publish
# /type method
# /effect ""
# //parameters
#	eval_error
# //returns
{
	my ($this, $eval_error) = @ARGUMENTS;

	my $errid = time.'-'.$PROCESS_ID;
	$eval_error =~ s{Compilation failed in require at .*? line \d+\.\s+}{}saag;

	my $msg = "\n# ERROR-$errid-START\n"
		.$this->_message_text(
			[__PACKAGE__, __FILE__, __LINE__],
			'publication',
			[$PROGRAM_NAME, $Carrot::Progress])
		.$eval_error
		."\n#ERROR-$errid-END\n";

	print(STDERR $msg);
	exit(1);
	return;
}

sub hits_explicit_eval
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this) = @ARGUMENTS;

	my $level = 0;
	while ($level < 1_000)
	{
		$level += 1;
		my $caller = [caller($level)];
		last if ($#$caller < 2);
		next if ($caller->[RDX_CALLER_LINE] == 0);
		next if ($caller->[RDX_CALLER_IS_REQUIRE]);
		next if ($caller->[RDX_CALLER_SUB_NAME] ne '(eval)');

		return(IS_TRUE);
	}

	return(IS_FALSE);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.516
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
