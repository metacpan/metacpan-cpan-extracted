package CGI::Application::Util::Diff;

# Author:
#	Ron Savage <ron@savage.net.au>

use base 'CGI::Application';
use strict;
use warnings;

use Algorithm::Diff qw/sdiff/;

use Carp;

use CGI::Application::Util::Diff::Actions;
use CGI::Application::Util::Diff::Config;

use Cwd; # For realpath.

use File::stat;

use HTML::Entities::Interpolate; # For %Entitize.
use HTML::Template;

use IPC::Capture;

use JSON::XS;

use Path::Class; # For dir() and cleanup().

our $VERSION = '1.03';

# -----------------------------------------------

sub build_form
{
	my($self)        = @_;
	my($dir_action)  = $self -> param('actions') -> get_dir_menu();
	my(@dir_action)  = map{qq|{text: "$$dir_action{$_}", value: "$_", onclick: {fn: onMenuItemClick} }|} sort keys %$dir_action;
	my($file_action) = $self -> param('actions') -> get_file_menu();
	my(@file_action) = map{qq|{text: "$$file_action{$_}", value: "$_", onclick: {fn: onMenuItemClick} }|} sort keys %$file_action;

	# Since this is Javascript, we must add a ',' to all elements but the last.
	# We cannot add a ',' to all elements, and then use this:
	# substr($dir_action[$#dir_action], -1, 1) = '';
	# to chop a comma off the last element, because substr() won't work with an array element as an lvalue.

	for my $i (0 .. ($#dir_action - 1) )
	{
		$dir_action[$i] .= ',';
	}

	for my $i (0 .. ($#file_action - 1) )
	{
		$file_action[$i] .= ',';
	}

	# Build the form and the corresponding Javascript.

	$self -> param('js') -> param(confirm_action => $self -> param('actions') -> get_confirm_action());
	$self -> param('js') -> param(dir_loop       => [map{ {item => $_} } @dir_action]);
	$self -> param('js') -> param(file_loop      => [map{ {item => $_} } @file_action]);
	$self -> param('js') -> param(form_action    => $self -> param('config') -> get_form_action() );

	# Keep YUI happy by ensuring the HTML is one long string...

	my($form) = $self -> param('form') -> output();
	$form     =~ s/\n//g;

	$self -> log('Leaving build_form');

	return ($self -> param('js') -> output(), $form);

} # End of build_form.

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> param(config  => CGI::Application::Util::Diff::Config -> new() );
	$self -> tmpl_path($self -> param('config') -> get_tmpl_path() );
	$self -> param(actions => CGI::Application::Util::Diff::Actions -> new() );
	$self -> param(form    => $self -> load_tmpl('form.tmpl') );
	$self -> param(js      => $self -> load_tmpl('form.js') );
	$self -> run_modes(['diff', 'initialize']);

	# Connect to the database for logging.

	my($logger_class, $logger_file) = split(/=/, $self -> param('config') -> get_logger() || '');

	if ($logger_class)
	{
		my($class) = $logger_class;
		$class     =~ s|::|/|g;

		eval qq|require "$class.pm"|;

		if ($@)
		{
			Carp::carp "Unable to require '$class'. Logging disabled. Error: $@";
		}
		else
		{
			$self -> param('logger' => $logger_class -> new({config_file => $logger_file}) );

			my($q) = $self -> query();

			$self -> log('=' x 50);
			$self -> log("Param: $_ => " . $q -> param($_) ) for $q -> param();
			$self -> log('Leaving cgiapp_init');
		}
	}

} # End of cgiapp_init.

# -----------------------------------------------

sub check_names
{
	my($self, $left_name, $right_name) = @_;
	my($message) = '';

	if ($left_name && ! $right_name)
	{
		$message = $self -> error_message(2);
	}
	elsif ($right_name && ! $left_name)
	{
		$message = $self -> error_message(1);
	}
	elsif ($left_name && $right_name)
	{
		if (! -d $left_name)
		{
			$message = $self -> error_message(3);
		}
		elsif (! -d $right_name)
		{
			$message = $self -> error_message(4);
		}
	}

	$self -> log('Leaving check_names');

	return $message;

} # End of check_names.

# -----------------------------------------------

sub diff
{
	my($self)       = @_;
	my($query)      = $self -> query();
	my($left_name)  = $query -> param('left')   || '';
	my($right_name) = $query -> param('right')  || '';
	my($action)     = $query -> param('action') || '';
	my($target)     = $self -> remove_span($query -> param('target') || '');
	my($message)    = $self -> check_names($left_name, $right_name);
	my($output)     = '';
	my($result)     = [];

	if ($left_name && $right_name && ! $message)
	{
		$output = $action ? $self -> process_action($action, \$left_name, \$right_name, $target) : '';

		my(@result);

		($message, @result) = $self -> read_dirs($left_name, $right_name);

		if (! $message)
		{
			$result = $self -> format_result(@result);
		}
	}

	$self -> log("Leaving run mode 'diff'");

	# $left_name and $right_name are in double quotes to satisfy Path::Class.
	# Encode HTML entities with HTML::Entities::Interpolate.

	return JSON::XS -> new() -> encode
		({
			response =>
			{
				left    => "$left_name",
				message => $message ? $self -> format_span($Entitize{$message}) : '',
				output  => $output,
				table   => $result,
				right   => "$right_name",
			}
		 });

} # End of diff.

# -----------------------------------------------

sub error_message
{
	my($self, $n, $s) = @_;
	my(%message) =
		(
		 1 => 'Left directory name not specified',
		 2 => 'Right directory name not specified',
		 3 => 'Left name is not a directory',
		 4 => 'Right name is not a directory',
		 5 => "Can't open($s): $!",
		 6 => "Unexpected action '$s'",
		);

	return $message{$n};

} # End of error_message.

# -----------------------------------------------

sub format_result
{
	my($self, @result) = @_;
	my(@sdiff) = sdiff([sort keys %{$result[0]}], [sort keys %{$result[1]}]);

	my($left, $left_name);
	my(@output);
	my($right, $right_name);

	for my $item (@sdiff)
	{
		$left       = ${$result[0]}{$$item[1]};
		$left_name  = $$left{'type'} && ($$left{'type'} eq 'Dir') ? $self -> format_span($$item[1], 'green') : $$item[1];
		$right      = ${$result[1]}{$$item[2]};
		$right_name = $$right{'type'} && ($$right{'type'} eq 'Dir') ? $self -> format_span($$item[2], 'green') : $$item[2];

		if ($$item[0] eq '-')
		{
			push @output,
			{
				left_size   => $$left{'size'},
				left_mtime  => $$left{'mtime'},
				match       => $self -> format_span('x'),
				name        => $left_name,
				right_size  => '',
				right_mtime => '',
				type        => $$left{'type'},
			};
		}
		elsif ($$item[0] eq '+')
		{
			push @output,
			{
				left_size   => '',
				left_mtime  => '',
				match       => $self -> format_span('x'),
				name        => $right_name,
				right_size  => $$right{'size'},
				right_mtime => $$right{'mtime'},
				type        => $$right{'type'},
			};
		}
		elsif ($$item[0] eq 'u')
		{
			# Currently, we only check that the sizes match.

			if ($$left{'size'} eq $$right{'size'})
			{
				push @output,
				{
					left_size   => $$left{'size'},
					left_mtime  => $$left{'mtime'},
					match       => '',
					name        => $left_name,
					right_size  => $$right{'size'},
					right_mtime => $$right{'mtime'},
					type        => $$left{'type'},
				};
			}
			else
			{
				push @output,
				{
					left_size   => $$left{'size'},
					left_mtime  => $$left{'mtime'},
					match       => $self -> format_span('x'),
					name        => $left_name,
					right_size  => $$right{'size'},
					right_mtime => $$right{'mtime'},
					type        => $$left{'type'},
				};
			}
		}
		else # 'c'.
		{
			if ($$item[1] lt $$item[2])
			{
				push @output,
				{
					left_size   => $$left{'size'},
					left_mtime  => $$left{'mtime'},
					match       => $self -> format_span('x'),
					name        => $left_name,
					right_size  => '',
					right_mtime => '',
					type        => $$left{'type'},
				};
				push @output,
				{
					left_size   => '',
					left_mtime  => '',
					match       => $self -> format_span('x'),
					name        => $right_name,
					right_size  => $$right{'size'},
					right_mtime => $$right{'mtime'},
					type        => $$right{'type'},
				};
			}
			else
			{
				push @output,
				{
					left_size   => '',
					left_mtime  => '',
					match       => $self -> format_span('x'),
					name        => $right_name,
					right_size  => $$right{'size'},
					right_mtime => $$right{'mtime'},
					type        => $$right{'type'},
				};
				push @output,
				{
					left_size   => $$left{'size'},
					left_mtime  => $$left{'mtime'},
					match       => $self -> format_span('x'),
					name        => $left_name,
					right_size  => '',
					right_mtime => '',
					type        => $$left{'type'},
				};
			}
		}
	}

	$self -> log('Leaving format_result');

	return [sort{$$a{'name'} cmp $$b{'name'} } @output];

} # End of format_result.

# -----------------------------------------------

sub format_span
{
	my($self, $s, $color) = @_;
	$color ||= 'red';

	return qq|<span class="$color">$s</span>|;

} # End of format_span.

# -----------------------------------------------

sub initialize
{
	my($self) = @_;
	my(@form) = $self -> build_form();

	# Generate the Javascript which will be called upon page load.

	my($head_init)   = <<EJS;
make_left_name_focus();
EJS

	# Generate the Javascript which will do all the work.

	my($head_js) = <<EJS;
$form[0]

function make_left_name_focus(eve)
{
document.util_diff_form.left.focus();
}
EJS

	# Generate the web page itself. This is not loaded by sub cgiapp_init(),
	# because, with AJAX, we only need it the first time the script is run.

	my($page) = $self -> load_tmpl('web.page.tmpl');

	$page -> param(content   => $form[1]);
	$page -> param(head_init => $head_init);
	$page -> param(head_js   => $head_js);
	$page -> param(yui_url   => $self -> param('config') -> get_yui_url() );

	$self -> log("Leaving run mode 'initialize'");

	return $page -> output();

} # End of initialize.

# -----------------------------------------------

sub log
{
	my($self, $s) = @_;

	if ($self -> param('logger') )
	{
		$self -> param('logger') -> log($s);
	}

} # End of log.

# -----------------------------------------------

sub process_action
{
	my($self, $action, $left_name, $right_name, $target) = @_;

	my(%command, $command);

	$command{'dir'}  = $self -> param('actions') -> get_dir_commands();
	$command{'file'} = $self -> param('actions') -> get_file_commands();
	my($output)      = [];

	if ($action eq 'dir_cd_both')
	{
		# We want to handle the case where the user goes into a directory,
		# and then back out again by clicking on '..', but Path::Class::dir::cleanup()
		# calls File::Spec::canonpath(), which does not clean-up '/a/b/..' to '/a'.

		$$left_name  = Cwd::realpath(dir($$left_name, $target) );
		$$right_name = Cwd::realpath(dir($$right_name, $target) );
	}
	elsif ($action eq 'dir_cd_left')
	{
		$$left_name  = Cwd::realpath(dir($$left_name, $target) );
	}
	elsif ($action eq 'dir_cd_right')
	{
		$$right_name  = Cwd::realpath(dir($$right_name, $target) );
	}
	elsif ($action =~ /(dir|file)_(cp|mv)_left2right/)
	{
		my($type)  = $1;
		my($act)   = $2;
		my($key)   = "${type}_${act}_left2right";
		my($left)  = file($$left_name, $target);
		my($right) = file($$right_name, $target);
		$command   = qq|$command{$type}{$key} "$left" "$right"|;
	}
	elsif ($action =~ /(dir|file)_(cp|mv)_right2left/)
	{
		my($type)  = $1;
		my($act)   = $2;
		my($key)   = "${type}_${act}_right2left";
		my($left)  = file($$left_name, $target);
		my($right) = file($$right_name, $target);
		$command   = qq|$command{$type}{$key} "$right" "$left"|;
	}
	elsif ($action eq 'file_diff')
	{
		my($left)  = file($$left_name, $target);
		my($right) = file($$right_name, $target);
		$command   = qq|$command{'file'}{'file_diff'} "$left" "$right"|;
	}
	elsif ($action =~ /(dir|file)_rm_both/)
	{
		my($type)  = $1;
		my($key)   = "${type}_rm_both";
		my($left)  = $type eq 'dir' ? dir($$left_name)  : file($$left_name, $target);
		my($right) = $type eq 'dir' ? dir($$right_name) : file($$right_name, $target);
		$command   = qq|$command{$type}{$key} "$left" "$right"|;
	}
	elsif ($action =~ /(dir|file)_rm_(left|right)/)
	{
		my($type)  = $1;
		my($side)  = $2;
		my($key)   = "${type}_rm_$side";
		my($left)  = $type eq 'dir' ? dir($$left_name)  : file($$left_name, $target);
		my($right) = $type eq 'dir' ? dir($$right_name) : file($$right_name, $target);
		my($thing) = $side eq 'left' ? $left : $right;
		$command   = qq|$command{$type}{$key} "$thing"|;
	}
	else
	{
		$output = $self -> error_output(6, $action);
	}

	if ($command)
	{
		$self -> log(qq|Running command: $command|);

		# We use IPC::Capture with autochomp false so we can split the output string.

		my($ipc)    = IPC::Capture -> new({filter => 'all_output'});
		my($result) = $ipc -> run($command);
		@$output    = split(/\n/, $result);

		if ($action eq 'file_diff')
		{
			my($limit) = $self -> param('actions') -> get_max_diff_line_count();

			if ($#$output >= $limit)
			{
				my($diff) = $#$output + 1 - $limit;
				$#$output = $limit - 1;

				push @$output, "Output truncated by $diff line" . ($diff == 1 ? '' : 's');
			}
		}

		# Log before calling $Entitize{...}!

		$self -> log('First few lines of output');

		for my $i (0 .. ( ($#$output >= 4) ? 4 : $#$output) )
		{
			$self -> log($$output[$i]);
		}

		@$output = map{ {line => $Entitize{$_} } } @$output;
	}

	$self -> log("Leaving run mode 'process_action'");

	return $output;

} # End of process_action.

# -----------------------------------------------

sub read_dir
{
	my($self, $dir_name) = @_;

	opendir(INX, $dir_name) || return ($self -> error_message(5, $dir_name), []);
	my(@file_name) = readdir INX;
	closedir INX;

	my(%file_name);
	my($name);
	my($stat);

	for my $file_name (@file_name)
	{
		$name                  = file($dir_name, $file_name);
		$stat                  = stat($name);
		$file_name{$file_name} =
			{
				mtime => scalar localtime($stat -> mtime() ),
				size  => $stat -> size(),
				type  => -d $name ? 'Dir' : 'File',
			};
	}

	$self -> log('Leaving read_dir');

	return ('', {%file_name});

} # End of read_dir.

# -----------------------------------------------

sub read_dirs
{
	my($self, $left, $right) = @_;
	my(@left_result)  = $self -> read_dir($left);
	my(@right_result) = $self -> read_dir($right);

	$self -> log('Leaving read_dirs');

	return ($left_result[0] || $right_result[0], $left_result[1], $right_result[1]);

} # End of read_dirs.

# -----------------------------------------------

sub remove_span
{
	my($self, $s) = @_;
	$s            =~ s|^<span class=".+">(.+)</span>$|$1|;

	return $s;

} # End of remove_span.

# -----------------------------------------------

sub teardown
{
	my($self) = @_;

	$self -> log('Leaving ' . __PACKAGE__);

} # End of teardown.

# -----------------------------------------------

1;

=head1 NAME

C<CGI::Application::Util::Diff> - Diff 2 directories or files, or run other commands

=head1 Synopsis

A classic CGI script:

	use strict; 
	use warnings;

	use CGI;
	use CGI::Application::Dispatch;

	# ---------------------

	my($cgi) = CGI -> new();

	CGI::Application::Dispatch -> dispatch
	(
		args_to_new => {QUERY => $cgi},
 		prefix      => 'CGI::Application::Util',
 		table       =>
		[
		''      => {app => 'Diff', rm => 'initialize'},
		'/diff' => {app => 'Diff', rm => 'diff'},
		],
	);

A modern FCGI script:

	use strict;
	use warnings;

	use CGI::Application::Dispatch;
	use CGI::Fast;
	use FCGI::ProcManager;

	# ---------------------

	my($proc_manager) = FCGI::ProcManager -> new({processes => 2});

	$proc_manager -> pm_manage();

	my($cgi);

	while ($cgi = CGI::Fast -> new() )
	{
		$proc_manager -> pm_pre_dispatch();

		CGI::Application::Dispatch -> dispatch
		(
		 args_to_new => {QUERY => $cgi},
		 prefix      => 'CGI::Application::Util',
		 table       =>
		 [
			''      => {app => 'Diff', rm => 'initialize'},
			'/diff' => {app => 'Diff', rm => 'diff'},
		 ],
		);

		$proc_manager -> pm_post_dispatch();
	}

=head1 Description

C<CGI::Application::Util::Diff> diffs 2 directories or files, or runs other commands. on the web server's machine.

The output of a directory diff is a table, where the I<Match> column contains a red 'x' if there is a mis-match in the sizes
of a file or sub-directory in the 2 given directories.

You click on a file name, or any field in the row, and a menu appears (beside the I<Diff> button) which contains the actions available.

The output of a file diff is the output of the shell's I<diff> command.

Available actions are in the file lib/CGI/Application/Util/Diff/.htutil.diff.actions.conf. They are listed below.

There is an action confirmation option in this file, which you are strongly advised to leave as is.

The confirmation is effected by means of a call to the Javascript confirm() function.

I hope this will be the first in a set of such tools. I plan to release any of my own under the same
namespace C<CGI::Application::Util::*>.

Since I expect this set to grow, I've decided to immediately adopt a Javascript library, rather than struggle
with a more ad hoc approach. And the Yahoo User Interface, YUI, is the one I like the most.

This module was developed using YUI V 2.7.0b.

=head1 Security

This module does not incorporate any security protection whatsoever.

If you need any more convincing that this module is unsafe because it runs shell commands,
there is plenty of info on the net about this topic. For instance:

http://hea-www.harvard.edu/~fine/Tech/cgi-safe.html

=head1 Actions

=head2 Overview

The actions will actually be run under the user who is running the web server.

This is often a fake human called I<nobody> or I<daemon>.

Such special user accounts normally have deliberately restricted permissions, so you might find the commands don't appear to do anything.

How you solve that on your machine is a security issue you must deal with.

=head2 Details

This is the contents of .htutil.diff.actions.conf:

	[global]
	
	# This option, when 1, causes a Javascript confirm() message box
	# to pop-up before the action is sent to the server.
	# If not present, the value defaults to 1.
	
	confirm_action = 1
	
	# The option limits output of the file_diff action.
	# If not present, the value defaults to 100.
	
	max_diff_line_count = 100
	
	# Actions
	# -------
	# Format: Name = Shell command (except for 'cd') = Javascript menu text.
	# The duplication is deliberate. It allows 'action' to be validated, because the first token
	# on each line is sent to the client, and returned by the CGI form field 'action'
	# when the user selects an action from the menu.
	#
	# Also, in CGI::Application::Util::Diff::Actions, all of these keys are stored in a single hash.
	#
	# For Perl equivalents of these shell commands, see:
	# o File::Copy::Recursive
	# o File::Tools
	# o File::Util
	
	[dir]
	
	# The 'cd' commands don't actually use the shell's 'cd',
	# and neither do they use Perl's 'chdir'.
	# Rather, the CGI form fields 'left' and 'right'
	# have the chosen directory appended. This emulates 'cd'.
	
	dir_cd_both  = cd = Change directory on both sides
	dir_cd_left  = cd = Change directory on left side
	dir_cd_right = cd = Change directory on right side
	
	# For here on down, they are shell commands.
	# Warning: Don't use anything which prompts, e.g. mv -i,
	# or your app will hang, making you look r-e-a-l-l-y stupid!
	
	dir_cp_left2right = cp -fprv = Copy directory from left side to right
	dir_cp_right2left = cp -fprv = Copy directory from right side to left
	
	dir_mv_left2right = mv -fv   = Move directory from left side to right
	dir_mv_right2left = mv -fv   = Move directory from right side to left
	
	dir_rm_both       = rm -frv  = Remove directory from both sides
	dir_rm_left       = rm -frv  = Remove directory from left side
	dir_rm_right      = rm -frv  = Remove directory from right side
	
	[file]
	
	file_cp_left2right = cp -fpv  = Copy file from left side to right
	file_cp_right2left = cp -fpv  = Copy file from right side to left
	
	file_diff          = diff     = Run 'diff' on left and right files
	
	file_mv_left2right = mv -fv   = Move file from left side to right
	file_mv_right2left = mv -fv   = Move file from right side to left
	
	file_rm_both       = rm -frv  = Remove file from both sides
	file_rm_left       = rm -frv  = Remove file from left side
	file_rm_right      = rm -frv  = Remove file from right side

=head2 A Note on Diff

The file_diff action, unlike the other actions, has the potential to output a great deal of text.

To help protect against that, the file .htutil.diff.actions.conf has a [global] section containing the line:

	max_diff_line_count = 100

This is the maximum number of lines of output from diff which are transferred from this module to the web client.

It's set large enough to give you a clear indicator that the 2 files being diffed are indeed different,
without being so large as to overwhelm the web client.

=head1 Contents

C<CGI::Application::Util::Diff> ships with:

=over 4

=item Two instance scripts: util.diff.cgi and util.diff

I<util.diff.cgi> is a trivial C<CGI> script, while I<util.diff> is a fancy script which uses C<FCGI::ProcManager>.

Both use C<CGI::Application::Dispatch>.

Trivial here refers to using a classic C<CGI>-style script, while fancy refers to using a modern C<FCGID>-style script.

The word fancy was chosen because it allows you to use fancier URLs. For samples, see I<Start Testing>, below.

The scripts are shipped as httpd/cgi-bin/util.diff.cgi and htdocs/local/util.diff.

These directory names were chosen because you'll be installing I<util.diff.cgi> in your web server's cgi-bin/
directory, whereas you'll install I<util.diff> in a directory under your web server's doc root.

For home-grown modules, I use the namespace Local::*, and for local web server scripts I use the
directory local/ under Apache's doc root.

For C<FCGID>, see http://fastcgi.coremail.cn/.

C<FCGID> is a replacement for the older C<FastCGI>. For C<FastCGI>, see http://www.fastcgi.com/drupal/.

Also, edit I<util.diff.cgi> and I<util.diff> to fix the 'use lib' line. See the I<Note> in those files for details.

=item A set of C<HTML::Template> templates: *.tmpl

See htdocs/assets/templates/cgi/application/util/diff/*.

=item A config file for C<CGI::Application::Util::Diff>

See lib/CGI/Application/Util/Diff/.htutil.diff.conf.

=item A config file for C<CGI::Application::Util::Diff::Actions>

See lib/CGI/Application/Util/Diff/.htutil.diff.actions.conf.

=item A config file for C<CGI::Application::Util::Logger>

See lib/CGI/Application/Util/.htutil.logger.conf.

=item A patch to httpd.conf, if you run Apache and FCGID.

See httpd/conf/httpd.conf.

Yes, I realise that if you run FCGID you already have this patch installed, but there's nothing
wrong with having such information documented in various places.

=back

Lastly, the config files .htutil.*.conf are installed by both Build.PL and Makefile.PL.

=head1 Bells and Whistles

For a huge range of features, in a package developed over many years, see Webmin:

http://www.webmin.com/

However, I could not see anything in Webmin's standard packages which offered the same features as this module.
And that's probably because of security concerns.

=head1 Logging

C<CGI::Application::Util::Diff> ships with a default logging module, C<CGI::Application::Util::Logger>.

The option to activate logging is 'logging', in .htutil.diff.conf.

If this line is missing, no attempt is made to log.

Note: The logger's own config file, .htutil.logger.conf by default, might also turn logging off.

The default 'logging' line looks something like:

logger=CGI::Application::Util::Logger=/some/dir/CGI/Application/Util/.htutil.logger.conf

You'll notice it refers to the Util/ directory, not the Util/Diff/ directory.

This is because this logging mechanism is meant to be shared among all modules in the 
C<CGI::Application::Util::*> namespace.

This version of C<CGI::Application::Util::Diff> does not contain a menuing system for such utilities,
because there is as yet only this 1 module, but later versions will.

If the logging class cannot be loaded (with 'require'), the error is ignored, and no logging takes place,
but a message is written to the web-server's log with C<Carp::carp>.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing distros.

=head1 Installation

At the very least, you will need to patch .htutil.diff.conf, since that's where C<HTML::Template>'s
tmpl_path is stored, if using another path.

Config file options are documented in the config file itself.

Also, you may want to edit .htutil.logger.conf and .htutil.diff.actions.conf.

=head2 Install the module

Note: I<Build.PL> and I<Makefile.PL> refer to C<FCGI::ProcManager>. If you are not going to use
the fancy script, you don't need C<FCGI::ProcManager>.

Install C<CGI::Application::Util::Diff> as you would for any C<Perl> module:

Run I<cpan>: shell>sudo cpan CGI::Application::Util::Diff

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake)
	make test
	make install

=head2 Install the C<HTML::Template> files.

Copy the distro's htdocs/assets/ directory to your doc root.

=head2 Install the trivial instance script

Copy the distro's httpd/cgi-bin/util.diff.cgi to your cgi-bin/ directory,
and make I<util.diff.cgi> executable.

=head2 Install the fancy instance script

Copy the distro's htdocs/local/ directory to your doc root, and make I<util.diff> executable.

=head2 Configure C<Apache> to use /local/util.diff

If in fancy mode, add these to C<Apache>'s httpd.conf:

	LoadModule fcgid_module modules/mod_fcgid.so

and:

	<Location /local>
		SetHandler fcgid-script
		Options ExecCGI
		Order deny,allow
		Deny from all
		Allow from 127.0.0.1
	</Location>

Of course, use of '/local' is not mandatory; you could use any URL fragment there.

And don't forget to restart C<Apache> after editing it's httpd.conf.

=head2 Start testing

Point your broswer at http://127.0.0.1/cgi-bin/util.diff.cgi (trivial script), or
http://127.0.0.1/local/util.diff (fancy script).

=head1 FAQ

=over 4

=item The command did nothing!

What you mean is that it did not perform according to your false expectations, and/or you did not read
the section called Actions.

The user running the web server is the user who runs these actions, and hence their limited permissions
means the actions are limited in what they are allowed to do.

=item The log always contains the word 'message'!

Right! The log is a database table, and the column heading you refer to I<should> be there.

=back

=head1 Author

C<CGI::Application::Util::Diff> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2009.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2009, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
