package Batch::Interpreter;

use v5.10;
use warnings;
use strict;

=head1 NAME

Batch::Interpreter - interpreter for CMD.EXE batch files

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS
	use Batch::Interpreter;

	open my $fh, '<:crlf', $ARGV[0]
		or die "$ARGV[0]: $!";

	my $rc = Batch::Interpreter->new(
		locale => 'de_DE',
		# more settings, see below
	)->run({}, [ <$fh> ], @ARGV);

=head1 METHODS

=head2 ->new(%settings)

Create an instance of the class, which can be custimized with the following parameters (values for keys of C<%settings>):

=head3 Customization and Behavior

=over

=item filenames => $self->default_filenames

A Hash with the mapping of emulated filenames to host filenames, the default likely contains the entry NUL => '/dev/null'.

=item mountpoints => []

Mapping of emulated mount points (in most cases: drives) to host directories. The entries are scanned in order. Example: 'D:\' => '/mnt/data'.

=item remote_names => []

Mapping of emulated directories to remote names, for prompt $M.

=item extension_handlers => $self->builtin_extension_handlers

The list of handlers for file extensions. See chapter 'Extension Handlers' for the call interface.

=item internal_commands => $self->builtin_internal_commands

The list of handlers for internal commands, i.e. commands handled by CMD.EXE. See chapter 'Command Handlers' for the call interface.

=item external_commands => $self->builtin_external_commands

The list of handlers for external commands, i.e. command line tools. See chapter 'Command Handlers' for the call interface.

=item locale

The locale, see chapter LOCALES.

=back


=head3 Interpreter State

=over

=item echo => 1

State of the ECHO setting, 0 = OFF, 1 = ON.

=item exit_value => 0

%ERRORLEVEL%.

=item extensions => 1

State of SETLOCAL ENABLEEXTENSIONS / DISABLEEXTENSIONS, 0 = DISABLE, 1 = ENABLE.
.

Extensions are always enabled, but the state variable is maintained correctly.

=item delayedexpansion => 1

State of SETLOCAL ENABLEDELAYEDEXPANSION / DISABLEDELAYEDEXPANSION, 0 = DISABLE, 1 = ENABLE.

=item vars => {}

The values of the environment variables. Due to the case insensitivity all keys are in CAPS, while the real case of the variable names is stored in varcases under the same key.

=item varcases => { map((uc $_ => $_), keys %{$self->{vars}}), %{$self->default_variable_cases} }

See vars.

=back

=head3 Defaults and Constants

=over

=item version_string => __PACKAGE__." $VERSION"

The string for prompt $V and the ver command.

=item default_drive => 'C'

The default drive. Per default a mountpoint for this drive is generated.

=item default_pathext => '.COM;.EXE;.BAT'

The default, if %PATHEXT% is unset.

=back

=head3 User Interface

=over

=item terminal => undef

An optional instance of Term::ReadLine or any other class that supports the ->readline($prompt) method.

=back

=head3 Tracing and Verbosity

=over

=item dump_parse_tree => undef

Dump parse tree of parsed command before execution.

=item verbose_system => undef

Print command lines before calling system() for external commands.

=back


=head2 ->run($attr, $lines, @arg)

Run the interpreter.
If given, C<$lines> is an ArrayRef of the lines of the script, else the commands are read from the terminal (as set in the contructor). The arguments of the script can be passed in C<@arg>. Per default the arguments have to be unquoted, like in perl's @ARGV -- in this case a realistically looking quoting is added internally.

C<$attr> has the keys

=over

=item quoted_arguments => undef

Set to true, if C<@arg> contains quoted arguments. In this case the values in C<@arg> have to be quoted like under the emulated system. Specifically, they have to look like the return value of the internal function C<next_token()>, i.e. trailing blanks are mandatory for all but the last argument. In this case the arguments can be used as-is.

=back


=head1 CUSTOMIZATION

=head2 Extension Handlers

Extension handlers are CodeRefs, that are called with the arguments:

	my $ret = $handler->($self, $command, \@arg, $qcommand, \@qarg);

C<$self> is the interpreter instance, C<$command> is the name of the command (i.e. the key the handler was found under in the handler hash), C<@arg> is the array of unquoted command line arguments. $C<$qcommand> and C<@qarg> and C<$args> are the raw forms of C<$command> and C<@arg>, i.e. the quoted command and arguments, which are most likely not needed in the handler. C<$command> is resolved via the C<%PATH%>, while C<$qcommand> is not.

The code has to return an empty list (to do nothing) or a list with the name of the interpreter and the arguments that lead to the interpretation of C<$command> (likely including C<$command> itself), which is prepended to C<@arg> and C<@qarg> in the calling code.

=head2 Command Handlers

Command handlers are CodeRefs, that are called with the arguments:

	my $ret = $handler->($self, $command, \@arg, \@qarg, $args);

C<$self> is the interpreter instance, C<$command> is the name of the command (i.e. the key the handler was found under in the handler hash), C<@arg> is the array of unquoted command line arguments. C<@qarg> and C<$args> are the raw forms of C<@arg>, namely the quoted arguments and the unsplit command line, which are most likely not needed in the handler.

The handler can:

=over

=item
Execute the command and return a numeric exit code or the value 'keep' to keep the %ERRORLEVEL% unchanged, or return a string beginning with the word 'error' to signal an error.

If the handler culminates in calling an external program, it will likely be based on the methods $self->unc2sys($path), $self->unc2sys_arg($path) and $self->run_external_command($attr, $exe, @arg), which are documented elsewhere in this document.

=item
Optionally change the contents of C<@arg> (and C<@qarg>, if finished is not set) and return a HashRef with the following keys:

=over

=item type

Must be 'rewrite'.

=item command

Return a new C<$command> to restart the handler search.

=back

=back

=head2 Locales

The locale class has to implement the following methods:

=head3 ->format_date($year, $month, $day)

Format a date for %DATE%, prompt $D, and the date command.

=head3 ->format_time_short($hour, $min)

Format a time for the time command.

=head3 ->format_time($hour, $min, $sec, $sec100)

Format a time for %TIME%, and prompt $T.

=head3 ->format_file_timedate($year, $month, $day, $hour, $min)

Format a file timestamp for the dir command.

=head3 ->format_file_timedate_for($year, $month, $day, $hour, $min)

Format a file timestamp for for %I in (...) do echo %~tI

=head3 ->get_string($category, $key)

Get a localized version of string C<$key> in category C<$category>. The only implemented category is 'message'.

=head1 METHODS TO BE CALLED FROM COMMAND HANDLERS

=cut


use Data::Dump qw(dump);
use Cwd;
use Time::HiRes qw(gettimeofday);
use List::MoreUtils qw(first_value);
use File::DosGlob qw(glob);
use File::Spec;
use File::Spec::Win32;
use File::Temp;
use File::Find;
use File::Copy;
use Clone qw(clone);
use POSIX ":sys_wait_h";

my $is_win_host = $^O =~ /Win32/;

# TODO: is there a need to port this to Moo??
sub new {
	my ($class, @arg) = @_;
	my $self = bless {
		var_path_cache => {},

		dump_parse_tree => undef,
		verbose_system => undef,

		echo => 1,
		exit_value => 0,
		extensions => 1, # always active :)
		delayedexpansion => 1,
		default_pathext => '.COM;.EXE;.BAT',
		default_drive => 'C',
		version_string => __PACKAGE__." $VERSION",

		@arg
	}, $class;

	$self->{vars} //= {};
	$self->{varcases} //= {
		map((uc $_ => $_), keys %{$self->{vars}}),
		%{$self->default_variable_cases},
	};
	$self->{filenames} //= $self->default_filenames;
	$self->{extension_handlers} //= $self->builtin_extension_handlers;
	$self->{internal_commands} //= $self->builtin_internal_commands;
	$self->{external_commands} //= $self->builtin_external_commands;
	# no commands are implemented by the windows shell, but not emulated
	$self->{assume_is_executable} //= {};

	# mapping back and forth (potentially)
	$self->{filename_map} = { %{delete($self->{filenames}) // {}} };
	$self->{filename_invmap} = { reverse %{$self->{filename_map}} };

	$self->{remote_name_map} //= delete($self->{remote_names}) // [];
	normalize_map($self->{remote_name_map}, sub {
		my ($path) = @_;
		$path =~ y|\\|/|;
		return $path;
	}, undef);

	$self->{mountpoint_map} = [
		map {
			$_;
		} @{delete($self->{mountpoints}) // [
			$self->{default_drive}.':' => '/',
		]}
	];
	# need to write system paths with unix slashes to be compatible with		# for_first_match
	normalize_map($self->{mountpoint_map}, sub {
		my ($path) = @_;
		$path =~ y|\\|/|;
		return $path;
	}, sub {
		my ($path) = @_;
		$path = File::Spec->rel2abs($path);
		$path =~ y|\\|/|;
		return $path;
	});

	defined $self->{locale}
		or die "missing locale";
	if ('' eq ref(my $locale = $self->{locale})) {
		my $first_err;
		my $locale_class = "Batch::Interpreter::Locale::$locale";
		eval "require $locale_class";
		if ($@) {
			$first_err = $@;
			$locale_class = $locale;
			eval "require $locale_class";
		}
		$@ and die "couldn't load locale $locale:\n$first_err\n$@";
		$self->{locale} = $locale_class;
	}
	if (my @missing = grep !$self->{locale}->can($_), qw(
		format_date format_time_short format_time
		format_file_timedate format_file_timedate_for
		get_string
	)) {
		die "invalid locale, no handler for: ", join ', ', @missing;
	}

	return $self;
}

sub deep_clone {
	my ($self, @modifier) = @_;
	return bless clone({ %$self, @modifier }), ref $self;
}

sub get_message {
	my ($self, $message) = @_;
	return $self->{locale}->get_string('message', $message) // $message;
}

sub internal_error {
	my ($self, $message, @arg) = @_;
	return 'error: '.sprintf $message, @arg;
}

sub syn_error {
	my ($self, $message, @arg) = @_;
	return 'error: '.sprintf $self->get_message($message), @arg;
}

sub os_error {
	my ($self, $name, $message, @arg) = @_;
	return 'error: '.sprintf($self->get_message($message // ''), @arg).
		" '$name': $!";
}

eval q{
	use Win32::ShellQuote qw(quote_native);
};
$@ and eval {
	sub quote_native {
		my ($str) = @_;
		$str =~ s/(\W)/\\$1/g;
		return $str;
	}
};

sub set_variable {
	my ($self, $variable, $value) = @_;

	$self->{verbose_set}
		and say STDERR "SET($variable=$value)";

	defined($value) && '' eq $value
		and undef $value;

	my $uc_var = uc $variable;

	if (defined($value)
		? defined $self->{vars}{$uc_var} &&
			$self->{vars}{$uc_var} eq $value
		: !exists $self->{vars}{$uc_var}
	) {
		# no value change
		$self->{varcases}{$uc_var} = $variable;
		return;
	}
	
	if (defined $value) {
		$self->{vars}{$uc_var} = $value;
		$self->{varcases}{$uc_var} = $variable;
	} else {
		delete $self->{vars}{$uc_var};
		delete $self->{varcases}{$uc_var};
	}

	if ($uc_var eq 'PATHEXT') {
		%{$self->{var_path_cache}} = ();
	} else {
		delete $self->{var_path_cache}{$uc_var};
	}
}

sub get_date {
	my ($self) = @_;
	my @localtime = localtime;
	return $self->{locale}->format_date(
		$localtime[5]+1900, $localtime[4]+1, $localtime[3]
	);
}

sub get_time {
	my ($self, $short) = @_;

	my @time = gettimeofday;
	my @localtime = localtime $time[0];
	if ($short) {
		return $self->{locale}->format_time_short(
			$localtime[2], $localtime[1]
		);
	} else {
		return $self->{locale}->format_time(
			$localtime[2], $localtime[1],
			$localtime[0], $time[1]/10000
		);
	}
}


sub normalize_map {
	my ($map, $callback_unc, $callback_sys) = @_;
	for (0..$#$map) {
		if (my $callback = ($_ & 1) ? $callback_sys : $callback_unc) {
			my $path = $callback->($map->[$_]);
			$path =~ s/(?<!\/)$/\//;
			$map->[$_] = $path;
		}
	}
}

sub for_first_match {
	my ($path, $map, $cmp, $callback) = @_;

	(my $mpath = uc $path) =~ y|\\|/|;
	$mpath =~ s/(?<!\/)$/\//;
	for my $i (0..($#$map-1)/2) {
		if (uc($map->[$i*2+$cmp]) eq 
			substr $mpath, 0, length $map->[$i*2+$cmp]
		) {
			$callback->(
				length $map->[$i*2+$cmp], $map->[$i*2+1-$cmp]
			);
			last;
		}
	}
}


=head2 ->unc2sys($path)

Translates an emulated path into a host path.

Convert path separators from \ to / and apply the filename and mountpoint translation rules, return the result.

Bug: the path is not actually UNC, though that _may_ work through mountpoint translation.

=cut
my $switch_slashes = !$is_win_host;
sub unc2sys {
	my ($self, $path) = @_;

	$switch_slashes and $path =~ y|\\|/|;

	if (exists $self->{filename_map}{uc $path}) {
		defined($_ = $self->{filename_map}{uc $path})
			and return $_;
	}

	if (File::Spec->file_name_is_absolute($path)) {
		for_first_match $path, $self->{mountpoint_map}, 0, sub {
			my ($offs, $val) = @_;
			substr $path, 0, $offs, $val;
		};
	}

	return $path;
}

=head2 ->sys2unc($path)

Translates a host path into an emulated path.

Convert path separators from / to \ and apply the filename and mountpoint translation rules, return the result.

Bug: the path is not actually UNC, though that _may_ work through mountpoint translation.

=cut
sub sys2unc {
	my ($self, $path) = @_;

	if (exists $self->{filename_invmap}{$path}) {
		# TODO: slashes are not switched...
		defined($_ = $self->{filename_invmap}{$path})
			and return $_;
	}

	if (File::Spec::Win32->file_name_is_absolute($path)) {
		for_first_match $path, $self->{mountpoint_map}, 1, sub {
			my ($offs, $val) = @_;
			substr $path, 0, $offs, $val;
		};
	}

	#$switch_slashes and
	$path =~ y|/|\\|;

	return $path;
}


=head2 ->unc2sys_arg($arg)

Translates an emulated command line argument into a host command line argument.

Paths are found in the argument by crude heuristics, which are subject to change. The actual translation is done with ->unc2sys($arg).

=cut
sub unc2sys_arg {
	my ($self, $arg) = @_;

	if (exists $self->{filename_map}{uc $arg}) {
		defined($_ = $self->{filename_map}{uc $arg})
			and return $_;
	}

	# try to translate filenames inside the arguments.
	while ($arg =~ /\G.*?(
		(?<! [\w\.] )
		(?:
			# absolute path
			(?: [A-Z]\: )?
			(?: \\ [^\\\:]+ )+ \\?
		|
			# relative path
			(?: [^\\\:]+\\ )+ [^\\\:]*
		)
		(?! [\w\\\:] )
	)\b/gcix) {
		my ($pos, $path) = (pos($arg), $1);
		my $newpath = $self->unc2sys($path);
		substr $arg, $pos - length($path), length($path), $newpath;
		pos $arg = $pos - length($path) + length($newpath);
	}
	return $arg;
}

sub filter_glob {
	my ($self, $filter, $do_glob, $uncglob) = @_;
	my $sysglob = $self->unc2sys($uncglob);
	my @list;
	if ($filter eq 'directories') {
		@list = grep -d, glob $sysglob;
	} elsif ($filter eq 'files') {
		@list = grep -f, glob $sysglob;
	} else {
		if ($do_glob) {
			@list = grep -f, glob $sysglob;
		} else {
			@list = ($sysglob);
		}
		@list = map File::Spec->rel2abs($_), @list;
	}
	return map $self->sys2unc($_), @list;
}

sub set_curdir {
	my ($self, $dir) = @_;
	undef $self->{curdir};
	return chdir $self->unc2sys($dir);
}

sub get_curdir {
	my ($self) = @_;
	return $self->{curdir} //= 
		File::Spec::Win32->catdir($self->sys2unc(getcwd));
}


sub get_remote_name {
	my ($self, $path) = @_;
	my $result;
	for_first_match $path, $self->{remote_name_map}, 0, sub {
		my ($offs, $val) = @_;
		$result = $val;
	};
	return $result // '';
}

sub get_drive {
	my ($self, $path) = @_;
	return (File::Spec::Win32->splitpath($path))[0]
		// $self->{default_drive}.':';
}

sub get_path {
	my ($self, $path) = @_;
	return (File::Spec::Win32->splitpath($path))[1] // '\\';
}

sub get_filename {
	my ($self, $path) = @_;
	my $name = (File::Spec::Win32->splitpath($path))[2];
	$name =~ s/\.[^\.]+$//;
	return $name;
}

sub get_fileext {
	my ($self, $path) = @_;
	my $name = (File::Spec::Win32->splitpath($path))[2];
	$name =~ /(\.[^\.]+)$/
		and return $1;
	return '';
}

sub get_short_path {
	my ($self, $path) = @_;
	# TODO: not implemented
	return $path;
}

sub get_file_attr {
	my ($self, $syspath) = @_;
	# TODO: too simple
	return '--a------';
}

sub get_file_timedate {
	my ($self, $syspath, $mode) = @_;
	my @localtime = localtime((stat $syspath)[9] // 0);
	my @timedate = (
		$localtime[5]+1900, $localtime[4]+1, $localtime[3],
		$localtime[2], $localtime[1],
	);
	return ($mode//'') eq 'for'
		? $self->{locale}->format_file_timedate_for(@timedate)
		: $self->{locale}->format_file_timedate(@timedate)
	;
}

sub format_size {
	my ($self, $size) = @_;
	1 while $size =~ s/(?<=\d)(\d\d\d)(?!\d)/.$1/;
	return $size;
}

sub set_subprocess_env {
	my ($self, $add_env) = @_;

	my %old = %ENV;

	my $case = $self->{varcases};
	my @copy = grep exists($case->{$_}), keys %{$self->{vars}};

	# select the variables that can be safely copied
	if ($is_win_host) {
		# setting a variable converts its case
		#@copy = grep $_ eq ($case->{$_} // 'a'), @copy;
	} else {
	}

	# TODO: convert the variables that have to be translated
	@ENV{@$case{@copy}} = @{$self->{vars}}{@copy};
	$add_env and
		@ENV{keys %$add_env} = values %$add_env;

	return %old;
}

sub extract_for_tokens {
	my ($opts, $line) = @_;

	if ($opts->{skip}) {
		$opts->{skip}--;
		return;
	}

	# skip empty lines
	$line =~ /\S/ or return;

	$opts->{eol_re} and $line =~ s/$opts->{eol_re}/$1/;
	return map $_ // '', ($opts->{delim_re}
			? split($opts->{delim_re}, $line, $opts->{numvals})
			: ($line)
	)[@{$opts->{tokens}}];
}

my $re_quoted = qr/ \" (?:\\.|\"\"|[^\\\"])*+ (?:\"|$) /x;
my $re_quotesc = qr/ \^. | $re_quoted /xo;
my $re_string =
	qr/ (?: $re_quotesc | \d(?!\>) | [^\<\>\|\&\(\)\"\^\s] )++ /xo;
my $re_lhs =
	qr/ (?: $re_quotesc | \d(?!\>) | [^\<\>\|\&\(\)\"\^\s\=] )++ /xo;
my $re_call_arg =
	qr/ (?: $re_quotesc | \d(?!\>) | [^\<\>\|\&\(\)\"\^\s\=\,] )++ /xo;
my $re_call_arg_separator = qr/ [\=\,\s] /x;
my $re_redirect = qr/ \< | \d?\>\>?(?:\&\d?)? /x;
my $re_pipe = qr/ \|\|? | \&\&? /x;
my $re_grouping = qr/ [\(\)] /x;
my $any_token = qr/$re_redirect | $re_pipe | $re_grouping | $re_string/x;

sub next_token {
	# trailing separator is included to not have to store separators
	# separately. the separatator will be removed in unquote_token.
	$_[0] =~ /\G ( $any_token \s*+ ) /gcxo
		or return;
	return $1;
}

sub next_token_no_pipe {
	$_[0] =~ /\G ( (?:$re_redirect | $re_grouping | $re_string) \s*+ ) /gcxo
		or return;
	return $1;
}

sub next_token_string {
	$_[0] =~ /\G ( $re_string \s*+ ) /gcxo
		or return;
	return $1;
}

sub next_token_lhs {
	$_[0] =~ /\G ( $re_lhs \s*+ ) /gcxo
		or return;
	return $1;
}

sub next_token_call_arg {
	# semantics different from next_token, because no unquote_token is
	# following
	$_[0] =~ /\G ( $re_call_arg ) $re_call_arg_separator*+ /gcxo
		or return;
	return $1;
}

sub unquote_token {
	my ($token) = @_;
	defined $token or return;

	while ($token =~ /\G [^\"\^\s]* ( $re_quotesc | \s+ ) /gcxo) {
		my ($p, $q) = (pos($token) - length($1), $1);
		if ($q =~ /^\s+$/ && pos $token == length $token) {
			# remove space at end of string
			substr($token, $p) = '';
			last; # end of string
		} elsif ($q =~ /^\^(.)/) {
			substr $token, $p, 1, '';
			# reparse escaped " character
			pos $token = $p + ($1 eq '"' ? 0 : 1);
		} else {
			my $r = substr $q, 1, $q =~ /\"$/ ? -1 : length $q;
			$r =~ s/(\\[\\\"]|\"\")/substr $1, 1/ge;
			substr $token, $p, length($q), $r;
			pos $token = $p + length $r;
		}
	}

	return $token;
}

sub requote {
	my ($arg) = @_;
	# do the equivalent of Win32::ShellQuote

	# quote complex arguments
	if ($arg =~ /[\s\"]/) {
		$arg =~ s/([\\\"])/\\$1/g;
		$arg = "\"$arg\"";
	}

	# add separation blank as in internal calls
	return $arg . ' ';
}

sub unescape {
	my ($str) = @_;

	while ($str =~ /\G (?: $re_quoted | [^\"\^] )*+ \^ (.) /gcxo) {
		my $p = pos($str) - 2;
		substr $str, $p, 1, '';
		pos $str = $p + 1;
	}

	return $str;
}

# mini-unquote to remove just the trailing separation blanks
sub trim_quoted {
	$_[0] =~ /^ ( $any_token (?: \s*+ $any_token )* ) \s* $/xo
		or return $_[0]; # maybe empty..
	return $1;
}

sub has_escaped_newline {
	$_[0] =~ /^ ( (?: \s*+ $any_token )* \s*+ ) \^\n $/xo
		or return;
	return $1;
}

sub rebase_numbers {
	my ($str) = @_;
	while ($str =~ /\G\b(0(?:[0-7]++|x[0-9a-f]++|b[01]++))\b/gi) {
		my $num = $1;
		my $start = pos($str) - length $num;

		my $replace = oct $num;
		substr $str, $start, length($num), $replace;
		pos $str = $start + length $replace;
	}
	return $str;
}

my %find_marker = (
	'%' => [ qr/[^\%]*+\%/, qr/([^\%]*+)\%/ ],
	'!' => [ qr/[^\!]*+\!/, qr/([^\!]*+)\!/ ],
);
sub replace_env_variables {
	my ($self, $marker, $str) = @_;
	chomp $str;

	my ($find_start, $find_end) =
		@{$find_marker{$marker} // die "unknown marker '$marker'"};

	while ($str =~ /\G$find_start/g) {
		my $start = pos($str) - 1;
		my ($replace, $end);

		if ($str =~ /\G((?:\~[a-z]*)?)(\d|\*)/gci) {
			$end = pos $str;
			if ($2 eq '*') {
				if ($1 eq '') {
					# orig_args are still quoted, thus
					# have their trailing blank
					$replace = trim_quoted join '',
						@{$self->{orig_args}};
				} else {
					# TODO...
					$replace = 'illegal expansion';
				}
			} else {
				$replace = $self->{args}[$2] // '';
				if ($1 eq '') {
					# ... but remove the blank here
					$replace = trim_quoted $replace;
				} elsif ($1 eq '~') {
					$replace = unquote_token $replace;
				} else {
					# modifiers kill the value??
					$replace = '';
				}
			}
		} elsif ($str =~ /\G$find_end/gc) {
			my $expr = $1;
			$end = pos $str;
			my $vars = $self->{vars};

			my ($name, $mod) = split /\:/, $expr, 2;
			$name //= ''; # if $expr eq ''
			my $premod = $name =~ s/^(~)// ? $1 : '';

			my $val;
			
			my $uc_name = uc $name;
			if (exists $vars->{$uc_name}) {
				$val = $vars->{$uc_name};
			} elsif ('CD' eq $uc_name) {
				$val = $self->get_curdir;
			} elsif ('DATE' eq $uc_name) {
				$val = $self->get_date;
			} elsif ('TIME' eq $uc_name) {
				$val = $self->get_time;
			} elsif ('RANDOM' eq $uc_name) {
				$val = int rand 32768;
			} elsif ('ERRORLEVEL' eq $uc_name) {
				$val = $self->{exit_value};
			} elsif ('CMDEXTVERSION' eq $uc_name) {
				$val = 1;
			} elsif ('CMDCMDLINE' eq $uc_name) {
				$val = 'C:\\Windows\\system32\\cmd.exe';
			} elsif ('HIGHESTNUMANODENUMBER' eq $uc_name) {
				$val = 1;
			} elsif ('' eq $uc_name && !$mod && !$premod) {
				$val = $marker
					if $marker eq '%';
			}

			defined $val && $premod eq '~'
				and $val = unquote_token $val;

			if (defined $mod && defined $val) {
				if ($mod =~ /^(\*?[^=]++)\=(.*+)$/) {
					my ($from, $to) = ($1, $2);
					if ($from =~ s/^\*//) {
						$val =~ s/^.*?\Q$from\E/$to/i;
					} else {
						$val =~ s/\Q$from\E/$to/ig;
					}
				} elsif ($mod =~ /^\~(-?\d++)(?:,(-?\d++))?$/) {
					my ($offs, $len) = ($1, $2);
					$_ < 0 and $_ .= length $val
						for $offs, $len;
					if ($offs >= 0 && $offs < length $val
						&& $len >= 0) {
						$val = substr $val, $offs, $len;
					} else {
						undef $val;
					}
				} else {
					undef $val;
				}
			}

			if (defined $val) {
				$replace = $val;
			} else {
				$replace = substr $str, $start, $end-$start;
			}
		} else {
			last;
		}
		substr $str, $start, $end-$start, $replace;
		pos $str = $start + length $replace;
	}

	return $str;
}

sub find_in_path {
	my ($self, $var, $filename) = @_;

	(File::Spec::Win32->splitpath($filename))[2] eq $filename
		or return $filename;

	my @pathext = split ';',
		$self->{vars}{PATHEXT} // $self->{default_pathext};
	
	return $self->{var_path_cache}{$var}{$filename} //= do {
		my $found =
			first_value {
				#say "EXIST? ".$_;
				-f $self->unc2sys($_)
			}
			map {
				my $f = $_;
				($f, map "$f$_", @pathext);
			}
			map File::Spec::Win32->catfile($_, $filename),
			split ';', $self->{vars}{$var} // ''
		;

		defined $found ? $self->sys2unc($found) : undef;
	};
}

sub apply_var_modifiers {
	my ($self, $mod, $replace) = @_;

	my $sysfile = File::Spec->rel2abs($self->unc2sys($replace));
	my $file = $self->sys2unc($sysfile);

	-e $sysfile or return $file;

	$mod =~ s/f/dpnx/g;
	$mod =~ /s/ and $file = $self->get_short_path($file);
					
	$replace = '';
	$mod =~ /a/ and $replace .= $self->get_file_attr($sysfile);
	$mod =~ /t/ and $replace .= ($replace ? ' ' : '').
			$self->get_file_timedate($sysfile, 'for');
	$mod =~ /z/ and $replace .= ($replace ? ' ' : '').(-s $sysfile || '');

	$mod =~ /[dpnx]/ && $replace and $replace .= ' ';

	$mod =~ /d/ and $replace .= $self->get_drive($file);
	$mod =~ /p/ and $replace .= $self->get_path($file);
	$mod =~ /n/ and $replace .= $self->get_filename($file);
	$mod =~ /x/ and $replace .= $self->get_fileext($file);

	return $replace;
}

sub replace_for_variables {
	my ($self, $str) = @_;

	my $for_vars = $self->{for_vars};
	my $for_keys = join '', grep defined($for_vars->{$_}), keys %$for_vars;
	my $for_key_pat = qr/[\~\Q$for_keys\E]/;
	my $after_tilde_pat = qr/([^\Q$for_keys\E]*)([\Q$for_keys\E])/;

	pos $str = 0;

	while ($str =~ /\G[^\%]*+\%($for_key_pat)/gc) {
		my $first = $1;
		my $start = pos($str) - 2;
		my ($replace, $end);

		if ($first eq '~') {
			if ($str =~ /\G$after_tilde_pat/gc &&
				defined(my $var = $2) &&
				$1 =~ /^([fdpnxsatz]*+)(?:\$(\w++)\:)?$/
			) {
				my ($mod, $path) = ($1, $2);
				$replace = unquote_token $for_vars->{$var};
				$end = pos $str;

				defined $path and
					$replace = $self->find_in_path(
						uc($path), $replace
					) // ''
				;
				$mod and $replace = $self->apply_var_modifiers(
					$mod, $replace
				);
			} else {
				$end = pos $str;
				$replace = substr $str, $start, $end-$start;
			}
		} else {
			($replace, $end) = ($for_vars->{$first}, pos $str);
		}

		substr $str, $start, $end-$start, $replace;
		pos $str = $start + length $replace;
	}

	return $str;
}

sub replace_late_variables {
	my ($self, $str) = @_;

	keys %{$self->{for_vars}}
		and $str = $self->replace_for_variables($str);
	$self->{delayedexpansion}
		and $str = $self->replace_env_variables('!', $str);

	return $str;
}

my %prompt_replacement = (
	A => '&',
	B => '|',
	C => '(',
	E => "\x1b",
	F => ')',
	G => '>',
	H => "\x08",
	L => '<',
	Q => '=',
	S => ' ',
	'_' => "\n",
	'$' => '$',
);
sub get_prompt {
	my ($self) = @_;
	my $prompt = $self->{vars}{PROMPT} // '$N$G';
	my $result = '';
	while ($prompt =~ /\G([^\$]*+)\$(.)/gc) {
		$result .= $1;
		my $c = uc $2;
		if (exists $prompt_replacement{$c}) {
			$result .= $prompt_replacement{$c};
		} elsif ($c eq '+') {
			$result .= '+' x @{$self->{pushd_stack}};
		} elsif ($c eq 'D') {
			$result .= get_date;
		} elsif ($c eq 'M') {
			$result .= $self->get_remote_name($self->get_curdir);
		} elsif ($c eq 'N') {
			$result .= $self->get_drive($self->get_curdir);
		} elsif ($c eq 'P') {
			$result .= $self->get_curdir;
		} elsif ($c eq 'T') {
			$result .= $self->get_time;
		} elsif ($c eq 'V') {
			$result .= $self->{version_string};
		}
	}
	$prompt =~ /\G(.+)$/g
		and $result .= $1;

	return $result;
}

my %named_fileno = (
	STDIN => 0,
	STDOUT => 1,
	STDERR => 2,
);
sub set_handle {
	my ($self, $number, $file) = @_;
	my $fileno = $named_fileno{$number} // $number;

	my $old;
	if ($fileno == 0) {
		open $old, '<&', \*STDIN;
		open STDIN, '<&', $file;
	} elsif ($fileno == 1) {
		open $old, '>&', \*STDOUT;
		open STDOUT, '>&', $file;
	} elsif ($fileno == 2) {
		open $old, '>&', \*STDERR;
		open STDERR, '>&', $file;
	}

	$self->{saved_handles}{$fileno} //= $old;
}

sub print_stdout {
	my ($self, @string) = @_;
	if (exists $self->{saved_handles} &&
			exists $self->{saved_handles}{1}) {
		my $out = $self->{saved_handles}{1};
		say $out @string;
	} else {
		say @string;
	}
}

sub reset_handles {
	my ($self) = @_;
	if (my $saved = delete $self->{saved_handles}) {
		my $old;
		if ($old = $saved->{0}) {
			open STDIN, '<&', $old;
		}
		if ($old = $saved->{1}) {
			open STDOUT, '>&', $old;
		}
		if ($old = $saved->{2}) {
			open STDERR, '>&', $old;
		}
	}
}

sub rest {
	my ($cur) = @_;
	return substr($$cur, pos($$cur) // 0);
}

sub trace_statement {
	my ($cur, $stop) = @_;

	my $start = pos($$cur) // 0;
	my $end;

	while (1) {
		$end = pos $$cur;

		my $token = next_token_no_pipe $$cur;
		defined $token && $token ne ''
			or last;

		if ($stop) {
			(my $trim = $token) =~ s/\s*$//;
			$stop->{lc $trim}
				and last;
		}
	}

	my $statement;
	$statement = substr $$cur, $start, $end-$start
		unless $start == $end;
	pos $$cur = $end;

	return $statement;
}

sub readline {
	my ($self, $prompt) = @_;
	$self->{terminal} or return;
	return $self->{terminal}->readline($prompt);
}

sub get_raw_line {
	my ($self, $is_continuation) = @_;

	if ($self->{lines}) {
		defined $self->{pos}
			or return;

		my $raw_line = $self->{lines}[$self->{pos}++];
		$self->{pos} > $#{$self->{lines}}
			and undef $self->{pos};

		return $raw_line;
	} else {
		my $prompt = $is_continuation
			? $self->get_message('More? ')
			: ($is_win_host ? '' : "\n").$self->get_prompt;

		return $self->readline($prompt)
	}
}

sub get_next_line {
	my ($self, $pline, $is_continuation) = @_;

	my $raw_line;
read_raw_line:
	{
		if (defined(my $part = $self->get_raw_line($is_continuation))) {
			if (defined(my $head = has_escaped_newline $part)) {
				$raw_line = ($raw_line // '') . $head;
				redo read_raw_line;
			} else {
				$raw_line = ($raw_line // '') . $part;
			}
		}
	}

	$$pline = $self->replace_env_variables('%', $raw_line);

	return $pline;
}

sub parse_cmd;
sub parse_cmd {
	my ($self, $cur, $stop) = @_;

	my $do_echo = $self->{echo};
	my $is_start;

	unless (defined $cur) {
		$is_start = 1;

		$cur = \my $line;

		$self->get_next_line($cur)
			or return 'return';
	}

	$$cur =~ /\G\s+/gc;
	$$cur =~ /\G\@\s*/gc and $do_echo = 0;
	$$cur =~ /\G\:/gc and return ':';
	$$cur =~ /\G\s*$/gc and return 'empty';
	$$cur =~ /\Grem\b/igc and return 'rem';
	$$cur =~ /\G\)/igc and return ')';

	my %common = (
		echo => $do_echo,
		is_child => !$is_start,
	);

	my $cmd;

	if ($$cur =~ /\Gif\b/igc) {
		my $not = $$cur =~ /\G\s+not\b/igc;
		$cmd = {
			%common,
			type => 'if',
			not => $not,
		};
		if ($$cur =~ /\G\s+errorlevel\s+/igc) {
			$cmd->{mode} = 'errorlevel';
			$cmd->{content} = next_token_string $$cur;
		} elsif ($$cur =~ /\G\s+exist\s+/igc) {
			$cmd->{mode} = 'exist';
			$cmd->{content} = next_token_string $$cur;
		} elsif ($$cur =~ /\G\s+cmdextversion\s+/igc) {
			$cmd->{mode} = 'cmdextversion';
			$cmd->{content} = next_token_string $$cur;
		} elsif ($$cur =~ /\G\s+defined\s+/igc) {
			$cmd->{mode} = 'defined';
			$cmd->{content} = next_token_string $$cur;
		} else {
			$cmd->{ignorecase} = $$cur =~ /\G\s*+\/i\b/igc;
			$$cur =~ /\G\s+/gc;
			$cmd->{op1} = next_token_lhs $$cur;

			if ($not ? $$cur =~ /\G\s*+ (==) \s* /igcx
				: $$cur =~ /\G\s*+
					(==|(?:equ|neq|lss|leq|gtr|geq)\b)
					\s*
					/igcx
			) {
				$cmd->{mode} = lc $1;
				$cmd->{op2} = next_token_string $$cur;
			} else {
				return $self->syn_error(
					'illegal if: %s', rest $cur
				);
			}
		}
		$cmd->{then} = $self->parse_cmd(
			$cur, { %{$stop // {}}, else => 1 }
		);

		if ($$cur =~ /\Gelse\b/igc) {
			$cmd->{else} = $self->parse_cmd($cur, $stop);
		}
	} elsif ($$cur =~ /\Gfor\s+/igc) {
		$cmd = {
			%common,
			type => 'for',
		};
		if ($$cur =~ /\G\/d\b/igc) {
			# /D
			$cmd->{mode} = 'directories';
		} elsif ($$cur =~ /\G\/r\b/igc) {
			# /R
			$cmd->{mode} = 'recursive';
			$$cur =~ /\G\s+/gc;
			$cmd->{scandir} = next_token_string $$cur;
		} elsif ($$cur =~ /\G\/l\b/igc) {
			# /L
			$cmd->{mode} = 'numbers';
		} elsif ($$cur =~ /\G\/f\s++(?=\%)/igc) {
			# /F %%v
			$cmd->{mode} = 'lines';
			$cmd->{line_options} = '';
		} elsif ($$cur =~ /\G\/f\s+/igc) {
			if (defined(my $opts = next_token_string $$cur)) {
				# /F opts %%v
				$cmd->{mode} = 'lines';
				$cmd->{line_options} = $opts;
			} else {
				return $self->syn_error(
					'invalid for /f: %s', rest $$cur
				);
			}
		} else {
			$cmd->{mode} = 'files';
		}

		# in ( ...\n ...\n ...\n ... ) do
		# in ( \n\n ` \n\n cmd \n\n ` \n\n ) do
		$$cur =~ /\G\s*+\%([a-zA-Z])\s++in\s++\(/igc
			or return $self->syn_error(
				'invalid for token %s', rest $cur
			);
		$cmd->{var} = $1;

		$cmd->{list} = '';
		while (1) {
			# ) in quotes don't terminate the list
			if ($$cur =~
				/\G( (?: [^\)\"\^]+ | $re_quotesc )+ )/xgco
			) {
				$cmd->{list} .= $1;
			}
			if ($$cur =~ /\G([^\)]*+)\)/gc) {
				$cmd->{list} .= $1;
				last;
			}

			$cmd->{list} .= rest($cur)."\n";

			$self->get_next_line($cur, 'continuation')
				or return $self->syn_error(
					'invalid for list %s', $cmd->{list}
				);
		}

		$$cur =~ /\G\s*do\s+/igc
			or return $self->syn_error(
				'invalid for token %s', rest $cur
			);

		$cmd->{command} = $self->parse_cmd($cur, $stop);
	} elsif ($$cur =~ /\G\(/gc) {
		my @subcmd;
		# 'else' has no power inside the ()
		while (my $sub = $self->parse_cmd($cur, { ')' => 1 })) {
			$sub eq ')' and last;
			push @subcmd, $sub
				if ref $sub;

			$$cur =~ /\G\s*+\)/gc
				and last;

			$self->get_next_line($cur, 'continuation')
				or return $self->syn_error(') expected');
		}

		$$cur =~ /\G\s*/gc;
		my $rest = trace_statement $cur, $stop;

		$cmd = {
			%common,
			type => '(',
			commands => \@subcmd,
			redirect => $rest,
		};
	} elsif (my $statement = trace_statement $cur, $stop) {
		$cmd = {
			%common,
			type => 'simple',
			command => $statement,
		};
	}

	if ($$cur =~ /\G\s*+(
				(?:(?!\^)\|\|?) |
				(?:(?!\^)\&\&?)
			)/igcx) {
		if ($1 eq '|') {
			$cmd->{pipe_to} = $self->parse_cmd($cur, $stop);
		} else {
			$cmd->{next_if} = $1 eq '&' ? undef
				: $1 eq '&&' ? 'ok' : 'not ok';
			$cmd->{next_cmd} = $self->parse_cmd($cur, $stop);
		}
	}

	return $cmd;
}

sub setup_redirects {
	my ($self, $str) = @_;

	$str !~ /[\<\>]/
		and return ($str, '');

	# < > >> 2>

	my ($filtered, $redirects) = ('', '');
	my $spacer = '';

	while (1) {
		my $token = next_token_no_pipe $str;
		defined $token && $token ne ''
			or last;

		if ($token =~ /^ ( \< | \d?\>\>? ) (.*) /ix) {
			my ($op, $val) = ($1, $2);
			$val =~ /^\s*+$/ and $val = next_token_no_pipe $str;
			($val // '') =~ /^\s*+$/
				and return [
					$self->syn_error(
						'missing operand for %s: %s',
						$op, $str
					)
				];

			my $fn = unquote_token $val;

			my ($fd, $fh);
			if ($op eq '<') {
				$fd = 0;
				open $fh, '<:crlf', $self->unc2sys($fn)
					or return [ $self->os_error($fn, '<') ];
			} elsif ($op =~ /^(\d)?(\>\>?)$/) {
				$fd = $1 // 1;
				$op = $2;

				my $ok;
				if ($fn =~ /^\&(\d?)/) {
					# TODO: support more handles
					if ($1 eq '1') {
						$ok = open $fh, '>&',
							\*STDOUT;
					} else {
						$ok = open $fh, '>:crlf',
							$self->unc2sys('NUL');
					}
				} else {
					# need  to add :crlf ?
					$ok = open $fh, "$op:crlf",
						$self->unc2sys($fn);
				}
				$ok or return [ $self->os_error($fn, $op) ];
			} else {
				$self->internal_error(
					"unknown redirect operation '%s'", $op
				);
			}
			$self->set_handle($fd => $fh);

			$redirects .= " $fd$op$fn";
			# need to insert spacer for e.g.
			# sort /r>bla blubb
			$spacer = ' ';
		} else {
			$filtered .= $spacer.$token;
			$spacer = '';
		}
	}

	return ($filtered, $redirects);
}

sub print_prompt {
	my ($self, @str) = @_;
	$self->print_stdout("\n", $self->get_prompt, @str);
}

sub run_single_cmd {
	my ($self, $cmd) = @_;

	if ('' eq ref $cmd) {
		if ($cmd eq 'return' && @{$self->{call_stack}}) {
			# copied from 'goto'...
			my $call = pop @{$self->{call_stack}};

			if ($call->{recursion}) {
				return 'return';
			} else {
				$self->{pos} = $call->{pos};

				my $saved = $call->{saved};
				$self->{keys %$saved} = values %$saved;

				return 'next';
			}
		}
		return $cmd;
	} elsif ($cmd->{type} eq 'if') {
		my $true;
		my $mode = $cmd->{mode};
		my $content = !exists $cmd->{content} ? undef
			: unquote_token $self->replace_late_variables(
				$cmd->{content}
			  );

		my $str = defined $content ? "$mode $content" : undef;
		if ($mode eq 'errorlevel') {
			defined $content && $content =~ /^\d++$/
				or return $self->syn_error(
					"'%s' is not a number", $content
				);
			$true = $self->{exit_value} >= $content;
		} elsif ($mode eq 'exist') {
			$true = -e $self->unc2sys($content);
		} elsif ($mode eq 'cmdextversion') {
			defined $content && $content =~ /^\d++$/
				or return $self->syn_error(
					"'%s' is not a number", $content
				);
			$true = 1 <= $content;
		} elsif ($mode eq 'defined') {
			$true = '' ne $self->{vars}{uc $content};
		} else {
			my $uc = $cmd->{ignorecase};
			my ($op1, $op2) = @$cmd{qw(op1 op2)};
			($op1, $op2) = map unquote_token(
				$self->replace_late_variables($_)
			), $op1, $op2;

			$str = ($uc ? '/I ' : '')."\"$op1\" $mode \"$op2\"";

			if ($mode eq '==') {
				$true = $op1 eq $op2;
			} else {
				if ("$op1$op2" =~ /^\d++$/) {
					$true = $mode eq 'equ' ? $op1 == $op2
					: $mode eq 'neq' ? $op1 != $op2
					: $mode eq 'lss' ? $op1 < $op2
					: $mode eq 'leq' ? $op1 <= $op2
					: $mode eq 'gtr' ? $op1 > $op2
					: $mode eq 'geq' ? $op1 >= $op2
					: 0
				} else {
					$true = $mode eq 'equ' ? $op1 eq $op2
					: $mode eq 'neq' ? $op1 ne $op2
					: $mode eq 'lss' ? $op1 lt $op2
					: $mode eq 'leq' ? $op1 le $op2
					: $mode eq 'gtr' ? $op1 gt $op2
					: $mode eq 'geq' ? $op1 ge $op2
					: 0
				}
			}
		}
		$cmd->{not} and $true = !$true;

		$cmd->{echo} and $self->print_prompt(
			'if ', $cmd->{not} ? 'not ' : '', $str
		);

		if ($true) {
			return $self->run_cmd($cmd->{then});
		} elsif ($cmd->{else}) {
			return $self->run_cmd($cmd->{else});
		}
		return 'next';
	} elsif ($cmd->{type} eq 'for') {
		my $var = $cmd->{var};
		my $command = $cmd->{command};
		my $mode = $cmd->{mode};
		my $list = $self->replace_late_variables($cmd->{list});
		$list =~ s/\n/ /g;
		$list =~ /^\s*/g;

		my $handle_token =
			$mode !~ /^(?:files|directories|recursive)$/ ? undef
			: sub {
				my ($token) = @_;

				my $is_glob = $token =~ /[\*\?]/;
				my @for;
				if (!$is_glob && $mode ne 'recursive') {
					@for = (trim_quoted $token);
				} else {
					@for = sort $self->filter_glob($mode,
						$is_glob, unquote_token $token
					);
				}
				
				for (@for) {
					local $self->{for_vars}{$var} = $_;
					#dump $command;
					my $result = $self->run_cmd($command);
					$result eq 'next' or return $result;
				}
			};

		if ($mode eq 'files' || $mode eq 'directories') {

			$cmd->{echo} and $self->print_prompt('for ',
				$mode eq 'directories' ? '/d ' : '',
				"%$var in (", $list, ')'
			);

			while (my $token = next_token $list) {
				$handle_token->($token);
			}
		} elsif ($mode eq 'recursive') {
			my $scandir = unquote_token $cmd->{scandir};

			$cmd->{echo} and $self->print_prompt('for ',
				'/r ', $scandir, " %$var in (", $list, ')'
			);

			my @token;
			push @token, $_ while defined($_ = next_token $list);

			my $wanted = sub {
				-d or return;
				my $dir = $self->sys2unc($_);
				$handle_token->(File::Spec::Win32->catfile(
					$dir, $_
				)) for @token;
			};

			find {
				no_chdir => 1, wanted => $wanted,
				preprocess => sub {
					return sort @_;
				},
			}, $self->unc2sys($scandir);

		} elsif ($mode eq 'numbers') {
			my ($start, $step, $end) = split /,/, $list;
			s/^\s+//s for $start, $step, $end;
			s/\s+$//s for $start, $step, $end;
			/^-?\d+$/ or
				return $self->syn_error(
					"for: '%s' is not a number", $_
				)
					for $start, $step, $end;

			$cmd->{echo} and $self->print_prompt('for ',
				"/l %$var in ($start, $step, $end)"
			);

			for (my $i = $start;
				$step > 0 ? $i <= $end
					: $step < 0 ? $i >= $end : 0;
				$i += $step
			) {

				local $self->{for_vars}{$var} = $i;
				my $result = $self->run_cmd($command);
				$result eq 'next' or return $result;
			}
		} elsif ($mode eq 'lines') {
			my $opts = unquote_token $cmd->{line_options};

			$cmd->{echo} and $self->print_prompt('for ',
				"/f \"$opts\" %$var in (", $list, ')'
			);

			my %opt;
			(@opt{qw(eol skip delims tokens)}, my $usebackq) = (
				undef, 0, "\t ", '1', 0
			);
			$opts =~ /\beol=(.)/i and $opt{eol} = $1;
			$opts =~ /\bskip=(\d+)/i and $opt{skip} = $1;
			$opts =~ /\bdelims=(.?[^\s]*)/i and $opt{delims} = $1;
			$opts =~ /\btokens=(\d[\d,-]*+\*?)/i
				and $opt{tokens} = $1;
			$opts =~ /\busebackq\b/i and $usebackq = 1;

			$opt{eol} and $opt{eol_re} =
				qr/^([\Q$opt{eol}\E]+)\Q$opt{eol}\E.*+$/;
			$opt{delims} ne ''
				and $opt{delim_re} = qr/[\Q$opt{delims}\E]/;

			my @token = map {
				/^(\d+)\-(\d+)$/ ? ($1 .. $2) : ($_);
			} split /,/, $opt{tokens};

			if ($token[-1] =~ s/\*$//) {
				# 1,* or 1*
				$token[-1] eq '' and pop @token;
				push @token, $token[-1]+1;
				$opt{numvals} = @token;
			} else {
				$opt{numvals} = @token+1;
			}

			/^\d++$/ or
				return $self->syn_error(
					"invalid token '%s'", $_
				)
					for @token;
			$opt{tokens} = [ map $_-1, @token ];

			my @var;
			my $varcount = "$var";
			push @var, $varcount++ for 1..$opt{numvals};

			my $type = 'files';
			if ( # $usebackq &&
				$list =~ /^\s*\"/s && $list =~ /\"\s*+$/s
			) {
				$type = 'explicit';
				$list =~ s/^\s*+\"//s;
				$list =~ s/\"\s*+$//s;
			} elsif ($usebackq &&
				$list =~ /^\s*\`/s && $list =~ /\`\s*+$/s
			) {
				$type = 'output';
				$list =~ s/^\s*+\`//s;
				$list =~ s/\`\s*+$//s;
			}

			local $self->{for_vars} = my $for_vars = {
				%{$self->{for_vars}}
			};
			if ($type eq 'explicit') {
				if (my @val = extract_for_tokens \%opt, $list) {
					@$for_vars{@var} = @val;
					my $result = $self->run_cmd($command);
					$result eq 'next' or return $result;
				}
			} elsif ($type eq 'files') {
				$list =~ /^\s+/gc;
				while (my $token =
					unquote_token next_token $list
				) {
					open my $fh, '<:crlf',
							$self->unc2sys($token)
						or return $self->os_error(
							$token, 'for'
						);
					while (<$fh>) {
						chomp;
						my @val = extract_for_tokens
								\%opt, $_
							or next;
						@$for_vars{@var} = @val;
						my $result = $self->run_cmd(
							$command
						);
						$result eq 'next'
							or return $result;
					}
				}
			} else {
				my $pipe = File::Temp->new();
				open my $old_stdout, '>&', \*STDOUT;
				open STDOUT, '>&', $pipe;

				# clone to be safe about modification
				my $result = $self->deep_clone->run_script(
					# no arguments, but just in case...
					{ quoted_arguments => 1 },
					[ $list ]
				);
				$result ne 'next' and return $result;

				open STDOUT, '>&', $old_stdout;

				seek $pipe, 0, SEEK_SET;
				while (<$pipe>) {
					chomp;
					my @val = extract_for_tokens \%opt, $_
						or next;
					@$for_vars{@var} = @val;
					my $result = $self->run_cmd($command);
					$result eq 'next'
						or return $result;
				}
			}
		}
		return 'next';
	} elsif ($cmd->{type} eq '(') {
		my ($rest, $redirects) =
			$self->setup_redirects($cmd->{redirect} // '');
		'ARRAY' eq ref $rest and return $rest->[0];
		$rest eq '' or return $self->syn_error(
			'(): rest after redirects: %s', $rest
		);

		$cmd->{echo} and
			$self->print_prompt('()', $redirects);

		my $result;
		for my $sub (@{$cmd->{commands}}) {
			$result = $self->run_cmd($sub);
			# TODO: too simple for nested calls?
			$result eq 'next' or return $result;
		}
		return $result;
	} elsif ($cmd->{type} ne 'simple') {
		return $self->syn_error(
			'unknown command type %s', $cmd->{type}
		);
	}

	my ($cur, $redirects) = $self->setup_redirects($cmd->{command});
	'ARRAY' eq ref $cur and return $cur->[0];

	$cur = $self->replace_late_variables($cur);

	$cur =~ /\G\s*/gc;
	$cur =~ /\G$/gc
		and return 'empty';

	# be echo compatible at least for echo Hello World! ...
	$cmd->{echo} and
		$self->print_prompt($cur, $redirects || ' ');

	my ($qcommand, $args, @qarg);
	{
		my $pos = pos $cur;

		$qcommand = next_token $cur;
		defined $qcommand or return $self->syn_error(
			'no command in %s', rest \$cur
		);

		$args = rest \$cur;

		while (defined(my $arg = next_token $cur)) {
			push @qarg, $arg;
		}

		pos $cur = $pos;
	}
	my @arg = map unquote_token($_), @qarg;

	my $lc_qcommand = lc $qcommand;
	$lc_qcommand =~ s/\s++$//;

	# internal commands can't be quoted
	if ($lc_qcommand eq 'call') {
		if (@arg && $arg[0] =~ /^\:(\w+)$/) {
			my $label = $1;

			my $index = $self->{index}{uc $label};
			defined $index or
				return $self->syn_error(
					'no call label %s', $label
				);

			my @save = qw(args orig_args);
			my %saved = (
				map +($_ => $self->{$_}), @save
			);

			my @carg;
			while (defined(my $arg = next_token_call_arg $args)) {
				push @carg, $arg;
			}

			$self->{args} = \@carg;
			$self->{orig_args} = [ @qarg[1..$#qarg] ];

			if ($cmd->{is_child}) {
				my $pos = $self->{pos};
				push @{$self->{call_stack}}, {
					recursion => 1,
				};
				$self->{pos} = $index;
				my $result = $self->run_block;
				#say "RETURNED: $pos $result";
				$self->{pos} = $pos;
				@$self{@save} = @saved{@save};
				$result eq 'return' or
					return $self->internal_error(
						'illegal return %s', $result
					);
			} else {
				push @{$self->{call_stack}}, {
					saved => \%saved,
					pos => $self->{pos},
				};
				$self->{pos} = $index;
			}
			return 'next';
		} else {
			$args = substr $args, length $qcommand;

			$qcommand = shift @qarg;
			shift @arg;
			if (defined $qcommand) {
				$lc_qcommand = lc $qcommand;
				$lc_qcommand =~ s/\s++$//;
			} else {
				undef $lc_qcommand;
			}

			# fallthrough to external command
		}
	} elsif ($lc_qcommand eq 'goto' || $lc_qcommand eq 'exit') {
		my $return; # goto :EOF or exit /b
		my $label;

		if ($lc_qcommand eq 'goto') {
			$args =~ /\G\:?(\w+)/gc;
			$label = $1 // 'error';
			$return = 'EOF' eq uc $label;
		} else {
			my $b = $args =~ /\G\/b\b/igc;
			#say "EXIT???";
			$b or return 'exit';
			$return = 1;
		}

		if ($return) {
			#say "RETURN: @{$self->{call_stack}}";
			@{$self->{call_stack}} or return 'exitb';

			# undo call
			my $call = pop @{$self->{call_stack}};

			if ($call->{recursion}) {
				return 'return';
			} else {
				$self->{pos} = $call->{pos};

				my $saved = $call->{saved};
				@$self{keys %$saved} = values %$saved;

				return 'next';
			}
		}

		my $index = $self->{index}{uc $label};
		defined $index or
			return $self->syn_error('no goto label %s', $label);
		$self->{pos} = $index;
		return 'next';
	} elsif ($cur =~ /\Gecho\b/igc) {
		# very special parsing rules
		if ($cur =~ /\G\s*+$/gc) {
			say $self->get_message(
				$self->{echo} ? 'ECHO is ON.' : 'ECHO is OFF.'
			);
		} elsif ($cur =~ /\G\s+on\s*+$/gci) {
			$self->{echo} = 1;
		} elsif ($cur =~ /\G\s+off\s*+$/gci) {
			$self->{echo} = 0;
		} elsif ($cur =~ /\G\.\s*+$/gc) {
			say "";
		} elsif ($cur =~ /\G\s/gc) {
			say unescape rest \$cur;
		} else {
			return $self->syn_error('invalid echo %s', rest \$cur);
		}
		return 'next';
	}

	my $command = unquote_token $qcommand;

	if (my $interpreter = $self->get_interpreter_for_extension(
		$command, \@arg, $qcommand, \@qarg
	)) {
		$command = $interpreter;
		$args = join '', @qarg;
	}

	my $turn;
	my %add_env;
retry:
	for my $handlers (@$self{qw(internal_commands external_commands)}) {
		my $handler;
		my $key = $turn ? lc($command) : $lc_qcommand;
		unless (exists $handlers->{$key} &&
			defined($handler = $handlers->{$key})
		) {
			$turn++ > 100 and return $self->internal_error(
				'recursive handlers for %s', $key
			);
			next;
		}

		if ('CODE' eq ref $handler) {
			my $ret = $handler->($self,
				$command, \@arg, \@qarg, $args,
			);
			if ('HASH' eq ref $ret) {
				if ($ret->{type} eq 'rewrite') {
					$command = $ret->{command};
					$args = join '', @qarg;
					$ret->{env} and
						@add_env{keys %{$ret->{env}}}
							= values %{$ret->{env}};
					goto retry;
				}
			} elsif ('' eq ref $ret && defined $ret) {
				$ret =~ /^error/ and return $ret;
				$ret eq 'keep' or
					$self->{exit_value} = $ret;
				return 'next';
			}
			return $self->internal_error(
				'unknown handler result: %s', dump $ret
			);
		} elsif ('' eq ref $handler) {
			$command = $handler;
		}
		
	}

	my $ret = $self->run_external_command(
		{ add_to_env => \%add_env },
		$self->exe2sys($command),
		map $self->unc2sys_arg($_), @arg
	);
	$ret =~ /^error/ and return $ret;
	$ret eq 'keep' or
		$self->{exit_value} = $ret;
	return 'next';
}

sub exe2sys {
	my ($self, $command) = @_;

	my $exe = $self->unc2sys($command);
	unless ($self->{assume_is_executable}{uc $exe} || -f $exe) {
		$command = $self->find_in_path('PATH', $command) // $command;
		$exe = $self->unc2sys($command);
	}

	return $exe;
}

sub get_interpreter_for_extension {
	my ($self, $command, $args, $qcommand, $qargs) = @_;

	$command =~ /\.(\w)$/
		or return;
	my $ext = lc $1;

	my $handler = $self->{extension_handlers}{$ext}
		or return;

	my $found_command = -f $self->unc2sys($command) ? $command
		: $self->find_in_path('PATH', $command);

	my ($interpreter, @addarg) =
		$handler->($self, $found_command, $args, $qcommand, $qargs)
			or return;
	defined $interpreter
		or return;

	unshift @$args, @addarg;
	unshift @$qargs, map requote($_), @addarg;

	return $interpreter;
}

=head2 ->run_external_command($attr, $exe, @arg)

Runs the external program C<$exe> with command line arguments C<@arg> and an optionally changed environment, while optionally translating the input and output text format, and return a result compatible with the Command Handler interface.

C<$attr> supports the following keys:

=over

=item add_to_env
	A hash of additional environment variables that will be set temporarily while calling the program.

=item flip_stdin
	Convert the newlines of STDIN from crlf to the host format.

=item flip_stdout
	Convert the newlines of STDOUT from the host format to crlf.

=item flip_stderr
	Convert the newlines of STDERR from the host format to crlf.

=back

=cut
sub run_external_command {
	my ($self, $attr, $exe, @arg) = @_;

	my $result;
	my %old_env = $self->set_subprocess_env($attr->{add_to_env} // {});
	if ($is_win_host) {
		# windows has no system LIST
		my $commandline = join ' ', map quote_native($_), $exe, @arg;
		$self->{verbose_system} and say STDERR "SYSTEM $commandline";
		$result = system $commandline;
		# TODO: non-existent commands result in exit value 9009
		$result >>= 8;
	} else {
		$self->{verbose_system} and
			say STDERR 'SYSTEM '.join ' ', $exe, @arg;

		local $self->{saved_handles};
		my @wait;
		if ($attr->{flip_stdin} && !defined $result) {
			pipe my ($reader, $writer);
			my $pid = fork;
			unless ($pid // 1) {
				close $reader;
				binmode STDIN, ':crlf'; # to be sure
				binmode $writer;
				autoflush $writer;
				print $writer $_ while <STDIN>;
				exit 0;
			}

			unless (defined $pid) {
				$result = "error: fork: $!";
			} else {
				close $writer;
				$self->set_handle(STDIN => $reader);
				push @wait, $pid;
			}
		}
		if ($attr->{flip_stdout} && !defined $result) {
			pipe my ($reader, $writer);
			my $pid = fork;
			unless ($pid // 1) {
				close $writer;
				binmode $reader;
				binmode STDOUT, ':crlf'; # to be sure
				autoflush STDOUT;
				print STDOUT $_ while <$reader>;
				exit 0;
			}

			unless (defined $pid) {
				$result = "error: fork: $!";
			} else {
				close $reader;
				$self->set_handle(STDOUT => $writer);
				push @wait, $pid;
			}
		}
		if ($attr->{flip_stderr} && !defined $result) {
			pipe my ($reader, $writer);
			my $pid = fork;
			unless ($pid // 1) {
				close $writer;
				binmode $reader;
				binmode STDERR, ':crlf'; # to be sure
				autoflush STDERR;
				print STDERR $_ while <$reader>;
				exit 0;
			}

			unless (defined $pid) {
				$result = "error: fork: $!";
			} else {
				close $reader;
				$self->set_handle(STDERR => $writer);
				push @wait, $pid;
			}
		}
	
		unless (defined $result) {	
			$result = system $exe $exe, @arg;
			$result >>= 8;
		}

		$self->reset_handles;

		# wait for pipes to be flushed
		waitpid($_, 0) for @wait;
	}
	%ENV = %old_env;

	return $result;
}

sub command_usage {
	my ($self, $usage) = @_;
	say STDERR "usage: $usage";
	return 'keep';
}

sub command_error {
	my ($self, @arg) = @_;
	say STDERR $self->syn_error(@arg);
	return 'keep';
}

sub command_os_error {
	my ($self, @arg) = @_;
	say STDERR $self->os_error(@arg);
	return 'keep';
}

sub command_chdir {
	my ($self, $command, $args) = @_;

	my $drive = lc($args->[0] // '') eq '/d'
		and shift @$args;
	if (!@$args) {
		say $self->get_curdir;
	} elsif (@$args > 1) {
		 return $self->command_usage("$command <directory>");
	}

	my $dir = $args->[0];
	$self->set_curdir($dir)
		or return $self->command_os_error($dir, 'chdir');

	return 'keep';
}

sub command_delete {
	my ($self, $command, $args) = @_;

	@$args == 1 or return $self->command_usage("$command <file>");
	my $glob = $args->[0];

	/[\?\*]/ and return $self->command_error("%s: is a glob", $_)
		for $glob;

	my $file = $glob;
	unlink $self->unc2sys($file)
		or return $self->command_os_error($file, 'unlink');

	return 'keep';
}

sub command_mkdir {
	my ($self, $command, $args) = @_;

	@$args == 1 or return $self->command_usage("$command <directory>");
	my $dir = $args->[0];

	my ($vol, $dirs, $file) =
		File::Spec::Win32->splitpath($dir, 'no_file');

	my @path;
	my $ok;
	for my $level (File::Spec::Win32->splitdir($dir)) {
		push @path, $level;
		my $path = File::Spec::Win32->catpath(
			$vol, File::Spec::Win32->catdir(@path)
		);
		$ok = mkdir $self->unc2sys($path);
	}
	$ok or return $self->command_os_error($dir, 'mkdir');

	return 'keep';
}

sub command_move_copy {
	my ($self, $command, $args) = @_;

	my $src = $args->[0];
	my $dest = $args->[1];
	defined $src && defined $dest && !@$args
		or return $self->command_usage("$command <src> <dest>");
	/[\?\*]/ and return $self->commanderror("%s: is a glob", $_)
		for $src, $dest;
	-e $dest and return $self->command_error(
		"%s: exists, won't overwrite", $dest
	);

	if (lc $command eq 'copy') {
		# syscopy?
		copy map $self->unc2sys($_), $src, $dest
			or return $self->command_os_error($src, 'copy');
	} else {
		move map $self->unc2sys($_), $src, $dest
			or return $self->command_os_error($src, 'move');
	}

	return 'keep';
}

sub command_rmdir {
	my ($self, $command, $args) = @_;

	@$args == 1 or return $self->command_usage("$command <file>");
	my $glob = $args->[0];

	/[\?\*]/ and return $self->command_error('%s: is a glob', $_)
		for $glob;

	my $file = $glob;
	rmdir $self->unc2sys($file)
		or return $self->command_os_error($file, 'rmdir');

	return 'keep';
}

sub command_set {
	my ($self, $command, undef, undef, $cur) = @_;

	if ($cur =~ /\G\s*+([^\=\s]*+)\s*+$/gc) {
		my $filter = $1 ? qr/^\Q$1\E/i : undef;
		my ($vars, $cases) = @$self{qw(vars varcases)};
		my @order = sort grep exists $cases->{$_}, keys %$vars;
		$filter and @order = grep /$filter/, @order;

		say $cases->{$_}.'='.$vars->{$_}
			for @order;
		return 'keep';
	}

	my $arith = $cur =~ /\G\s*+\/a\b/igc;
	my $prompt = $cur =~ /\G\s*+\/p\b/igc;
	$arith && $prompt and
		return $self->command_error('set: /A and /P not combinable');
	my $set = rest \$cur;
	chomp $set;

	unless ($arith) {
		$set =~ s/^\s*+\"// and
			$set =~ s/\"[^\"]*$//;

		$set =~ s/^\s*+([^\=\s]++)\s*+\=//g
			or return $self->command_error(
				"syntax error in set: %s", $set
			);
		my $var = $1;

		$prompt and $set = $self->readline($set) // '';

		$self->set_variable($var => $set);

		return 'keep';
	}


	# ()                  - Gruppierung
	# ! ~ -               - monÑre Operatoren
	# * / %               - arithmetische Operatoren
	# + -                 - arithmetische Operatoren
	# << >>               - logische Verschiebung
	# &                   - bitweise UND
	# ^                   - bitweise exklusives ODER
	# |                   - bitweise ODER
	# = *= /= %= += -=    - Zuordnung
	# &= ^= |= <<= >>=
	# ,                   - Trennzeichen fÅr AusdrÅcke

	state $opchar = q{()!~-*/%+<>&^|};
	for my $expr (split /,/, $set) {
		$expr =~ s/\"//g;

		$expr =~ /\G\s*+
			([^\s\*\/\%\+\-\&\^\|\<\>]+)
			\s*+
			(|\*|\/|\%|\+|\-|\&|\^|\||\<\<|\>\>)\=
			(.*)
		/gcx
			or return $self->command_error(
				"syntax error in set: '%s'", $expr
			);
		my ($var, $op, $rhs) = ($1, $2, $3);
		$op and $rhs = "$var $op ( $rhs )";

		while ($rhs =~ /\G.*?([^0-9\s\.\;\Q$opchar\E]+)/gcio) {
			my $v = $1;
			my $start = pos($rhs) - length $v;
			my $r = ' '.($self->{vars}{uc $v} // 0).' ';
			substr $rhs, $start, length $v, $r;
			pos $rhs = $start + length $r;
		}
		$rhs = rebase_numbers $rhs;

		# kill magic
		$rhs =~ s/([\%\&])/$1 /g;

		# maybe more characters behave this way...
		$rhs =~ s/\;.*$//;

		$rhs =~ /^[0-9\s\Q$opchar\E]+$/o
			or return $self->command_error(
				"arithmetic expression for %s".
				" not supported: %s", $var, $expr
			);

		my $val = eval $rhs;
		$@ and return $self->command_error(
			"arithmethic expression".
			" error while evaluating '%s': %s", $rhs, $@
		);

		$self->set_variable($var => $val);
	}

	return 'keep';
}

my %internal_command = (
	cd => \&command_chdir,
	chdir => \&command_chdir,
	copy => \&command_move_copy,
	date => sub {
		my ($self, $command, $args) = @_;
		lc($args->[0] // '') eq '/t'
			or return $self->command_error(
				"%s: setting not supported", $command
			);
		say $self->get_date;
		return 'keep';
	},
	del => \&command_delete,
	dir => sub {
		my ($self, $command, $args) = @_;
		my $sort = 'time';
		my $glob = $args->[0] // '*';
		my @content =  map [ $_, $self->sys2unc($_) ],
			glob $self->unc2sys($glob);
		printf "%-21s%14s %s\n",
			$self->get_file_timedate($_->[0], 'dir'),
			-d $_->[0] ? '<DIR>         '
				: $self->format_size(-s $_->[0]),
			$_->[1]
				for @content;
		return 'keep';
	},
	endlocal => sub {
		my ($self, $command, $args) = @_;
		if (my $old = pop @{$self->{state_stack}}) {
			@$self{keys %$old} = values %$old;
		}
		return 'keep';
	},
	erase => \&command_delete,
	md => \&command_mkdir,
	mkdir => \&command_mkdir,
	move => \&command_move_copy,
	pause => sub {
		my ($self, $command, $args) = @_;
		# TODO: any key is allowed, readline wants Enter
		$self->readline(
			$self->get_message('Press a key to continue . . .')
		);
		return 'keep';
	},
	popd => sub {
		my ($self, $command, $args) = @_;
		my $dir = pop @{$self->{pushd_stack}};
		$self->set_curdir($dir)
			or return $self->command_os_error($dir, $command);
		return 'keep';
	},
	prompt => sub {
		my ($self, $command, $args) = @_;
		$self->set_variable(PROMPT => $args->[0]);
		return 'keep';
	},
	pushd => sub {
		my ($self, $command, $args) = @_;
		push @{$self->{pushd_stack}}, $self->get_curdir;
		if (defined(my $dir = $args->[0])) {
			$self->set_curdir($dir)
				or return $self->command_os_error(
					$dir, $command
				);
		}
		return 'keep';
	},
	rd => \&command_rmdir,
	ren => \&command_move_copy,
	rename => \&command_move_copy,
	rmdir => \&command_rmdir,
	set => \&command_set,
	setlocal => sub {
		my ($self, $command, $args) = @_;
		my %switch;

		while ($args =~ /\G
			(en|dis)able (delayedexpansion|extensions)
			\s*/igcx
		) {
			$switch{lc $2} = lc $1 eq 'en';
		}

		my @hash = qw(vars varcases var_path_cache);
		my @scalar = qw(delayedexpansion);

		push @{$self->{state_stack}}, {
			map +($_ => $self->{$_}), @hash, @scalar
		};
		$self->{$_} = { %{$self->{$_}} } for @hash;

		return %switch ? 0 : 1;
	},
	shift => sub {
		my ($self, $command, $args) = @_;

		my $fixed = 0;
		@$args && $args->[0] =~ /^\/([0-8])$/
			and $fixed = $1;
		splice @{$self->{args}}, $fixed, 1
			if $fixed < @{$self->{args}};

		return 'keep';
	},
	time => sub {
		my ($self, $command, $args) = @_;
		lc($args->[0] // '') eq '/t'
			or return $self->command_error(
				"%s: setting not supported", $command
			);
		say $self->get_time('short');
		return 'keep';
	},
	type => sub {
		my ($self, $command, $args) = @_;

		@$args == 1 or return $self->command_usage("$command <file>");
		my $filename = $args->[0];
		open my $fh, '<:crlf', $self->unc2sys($filename)
			or return $self->command_os_error($filename, $command);
		print while <$fh>;

		return 'keep';
	},
	ver => sub {
		my ($self, $command, $args) = @_;
		say $self->{version_string};
		$self->{exit_value} = 0;
		return 'keep';
	},
);

sub default_variable_cases {
	return { map +(uc $_ => $_), qw(
		Path ComSpec PSModulePath
		windir windows_tracing_flags windows_tracing_logfile
		CommonProgramFiles CommonProgramFiles(x86) CommonProgramW6432
		ProgramData ProgramFiles ProgramFiles(x86) ProgramW6432
		SystemDrive SystemRoot
	)};
}

sub default_filenames {
	return {
		$is_win_host ? (
		) : (
			NUL => '/dev/null',
			CON => '/dev/console',
		),
	};
}

sub builtin_internal_commands {
	return { %internal_command };
}

sub is_shortened {
	my ($pattern, $str) = @_;
	my $minlen = length $pattern;
	$pattern =~ s/^([^\[]*+)\[([^\]]*+)\]$/$1$2/
		and $minlen = length $1;
	return length $str >= $minlen
		&& $str eq substr $pattern, 0, length $str;
}

sub translate_sort {
	my ($self, $command, $args, $qargs) = @_;

	my @opt;
	my %env;
	for (my $i = 0; $i < @$args; ) {
		my $arg = uc $args->[$i];
		my $rest = $#$args - $i;

		my $splice;
		if ($rest && $arg =~ /^\/\+(\d+)$/) {
			push @opt, '-k', $1;
			$splice = 1;
		} elsif ($rest && is_shortened '/L[OCALE]', $arg) {
			# case??
			$env{LC_ALL} = $args->[$i+1];
			$splice = 2;
		} elsif ($rest && is_shortened '/M[EMORY]', $arg) {
			push @opt, '-S', "$args->[$i+1]K";
			$splice = 2;
		} elsif (is_shortened '/REC[ORD_MAXIMUM]', $arg) {
			# ignore
			$splice = 2;
		} elsif (is_shortened '/R[EVERSE]', $arg) {
			push @opt, '-r';
			$splice = 1;
		} elsif ($rest && is_shortened '/T[EMPORARY]', $arg) {
			push @opt, '-T', $args->[$i+1];
			$splice = 2;
		} elsif ($rest && is_shortened '/O[UTPUT]', $arg) {
			push @opt, '-o', $args->[$i+1];
			$splice = 2;
		}
		if ($splice) {
			splice @$args, $i, $splice;
			#splice @$qargs, $i, $splice;
		} else {
			$i++;
		}
	}
	unshift @$args, @opt;
	#unshift @$qargs, map "$_ ", @opt;

	return $self->run_external_command(
		{
			add_to_env => \%env,
			flip_stdin => 1,
			flip_stdout => 1,
		},
		'sort', @$args
	);
}

my %extension_handler = (
	bat => sub {
		my ($self, $command, $args) = @_;
		# TODO (or not): replacement of current script, if not called 
		return ($^X, $0, $command);
	},
);

sub builtin_extension_handlers {
	return { %extension_handler };
}

my %external_command = (
	mysort => \&translate_sort,
	$is_win_host ? () : (sort => \&translate_sort),
);

sub builtin_external_commands {
	return { %external_command };
}

sub run_single_pipe {
	my ($self, $cmd) = @_;
	my $result;
	my $wait_count = 0;

	local $self->{saved_handles} = {};
	while (ref $cmd && $cmd->{pipe_to}) {
		my $pseudo_pipe = $is_win_host;

		my ($reader, $writer, $pid);
		if ($pseudo_pipe) {
			# fork is emulated, fileno's are shared
			my $pipe_name = File::Temp->new();
			open $writer, '+>', $pipe_name;
			# '<&' doesn't work
			open $reader, '<', $pipe_name;
			$pid = 0;
		} else {
			pipe $reader, $writer;
			$pid = fork;
			defined $pid or $self->os_error(undef, 'fork');
		}
		unless ($pid // 1) {
			close $reader
				unless $pseudo_pipe;
			$self->set_handle(STDOUT => $writer);
			close $writer;

			# be safe for pseudo-fork
			my $substate = $self->deep_clone;

			$result = run_single_cmd $substate, $cmd;
			$self->reset_handles;
			exit $self->{exit_value}
				unless $pseudo_pipe;
		}
		close $writer;

		$wait_count++
			unless $pseudo_pipe;

		$self->set_handle(STDIN => $reader);
		close $reader;

		$cmd = $cmd->{pipe_to};
	}
	$result = $self->run_single_cmd($cmd);

	wait for 1..$wait_count;
	$self->reset_handles;

	return ($result, $cmd);
}

sub run_cmd {
	my ($self, $cmd) = @_;
	dump $cmd if $self->{dump_parse_tree} && ref $cmd;

	my $result;
	while (1) {
		($result, $cmd) = $self->run_single_pipe($cmd);
		$result eq 'next' or last;

		$cmd->{next_cmd} or last;

		if (defined $cmd->{next_if}) {
			if ($cmd->{next_if} eq 'ok') {
				$self->{exit_value} or last;
			} else {
				$self->{exit_value} and last;
			}
		}

		$cmd = $cmd->{next_cmd};
	}
		
	return $result;
}

sub run_block {
	my ($self) = @_;

	my $result;
	while (defined $self->{pos}) {
		$result = $self->run_cmd($self->parse_cmd);
		if ($result eq 'return') {
			last;
		} elsif ($result =~ /^error/g) {
			last;
		} elsif ($result =~ /^exit/) {
			die 'EXIT: '.(0+$self->{exit_value});
		}
	}
	return $result;
}

sub run_script {
	my ($self, $attr, $lines, @arg) = @_;

	# perl (under Win32) or the shell (unixoid systems) unquoted the
	# arguments -- and the quoting was system specific in any case.
	#
	# Make the arguments look like they came from a windows command line.
	unless ($attr->{quoted_arguments}) {
		$_ = requote $_
			for @arg;
	}

	# translate %0
	# hope the trailing blank survives...
	@arg && defined $arg[0]
		and $arg[0] = $self->sys2unc($arg[0]);

	my $index = {};
	if ($lines && @$lines > 1) {
		# need to add exit /b to get an extra iteration in run_block,
		# to make calls return
		$lines = [ @$lines, '@exit /b' ];

		$lines->[$_] =~ /^\s*+\:\s*+(\w+)\s*+$/
			and $index->{uc $1} = $_+1
				for 0..$#$lines;
	}

	local $self->{args} = \@arg;
	local $self->{orig_args} = [ @arg[1..$#arg] ];

	local $self->{pos} = 0;
	local $self->{lines} = $lines;
	local $self->{index} = $index;

	local $self->{for_vars} = {};
	local $self->{call_stack} = [];
	local $self->{state_stack} = [];
	local $self->{pushd_stack} = [];

	my $result;
	eval {
		$result = $self->run_block;
	};
	if (!$@) {
		# $result is set
	} elsif ($@ =~ /^EXIT: (\d+)\s/) {
		$result = $1;
	} else {
		$result = "error: $@";
	}
	return $result;
}

sub run {
	my ($self, $attr, $lines, @arg) = @_;

	my $result = $self->run_script($attr, $lines, @arg);
	$result eq 'next' || $result eq 'return'
		and $result = $self->{exit_value};
	return $result;
}

1; # End of Batch::Interpreter

__END__

=head1 AUTHOR

Ralf Neubauer, C<< <ralf at strcmp.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-batch-interpreter at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Batch-Interpreter>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Batch::Interpreter


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Batch-Interpreter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Batch-Interpreter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Batch-Interpreter>

=item * Search CPAN

L<http://search.cpan.org/dist/Batch-Interpreter/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Ralf Neubauer.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

