package CGI::FileManager;

use warnings;
use strict;

=head1 NAME

CGI::FileManager - Managing a directory structure on an HTTP server

=head1 SYNOPSIS

Enable authenticated users to do full file management on
a subdirectory somewhere with a web server installed.

After installing the module you have to create a file with usernames and passwords
in it. For this we supply cfm-passwd.pl which should have been installed in your PATH.
Type:

> cfm-passwd.pl /home/user/mypwfile add someuser

It will ask for password and the home directory that the use is supposed to be able to
manage.

Then in nearby CGI script:

 #!/usr/bin/perl -wT
 use strict;
 
 use CGI::FileManager;
 my $fm = CGI::FileManager->new(
			PARAMS => {
				AUTH => {
					PASSWD_FILE => "/home/user/mypwfile",
				}
			}
		);
 $fm->run;

Now point your browser to the newly created CGI file and start managing your files.


=head1 WARNING

 This is Software is in Alpha version. Its interface, both human and programatic
 *will* change. If you are using it, please make sure you always read the Changes
 section in the documentation.


=head1 VERSION

Version 0.05


=cut

our $VERSION = '0.06';

=head1 DESCRIPTION

Enables one to do basic file management operations on a 
filesystem under an HTTP server. The actions on the file system
provide hooks that let you implement custom behavior on each 
such event.

It can be used as a base class for a simple web application
that mainly manipulates files.



=head1 Methods

=cut

use base 'CGI::Application';
use CGI::Application::Plugin::Session;
use CGI::Upload;
use File::Spec;
use File::Basename qw(dirname);
use Data::Dumper qw(Dumper);
use HTML::Template;
#use Fcntl qw(:flock);
#use POSIX qw(strftime);
use File::Copy qw(move);
use Carp qw(cluck croak);

use CGI::FileManager::Templates;
use CGI::FileManager::Auth;
my $cookiename = "cgi-filemanager";


#Standard CGI::Application method
#Setup the Session object and the default HTTP headers

=head2 cgiapp_init

Initialize application (standard CGI::Application)

=cut
sub cgiapp_init {
	my $self = shift;
	CGI::Session->name($cookiename);
	$self->session_config(
#		CGI_SESSION_OPTIONS => [ "driver:File", $self->query, {Directory => "/tmp"}],
		COOKIE_PARAMS       => {
				-expires => '+24h',
				-path    => '/',
#				-domain  => $ENV{HTTP_HOST},
		},
		SEND_COOKIE         => 1,
	);
	
	if ($self->param("TMPL_PATH")) {
		$self->tmpl_path([
			File::Spec->catfile($self->param("TMPL_PATH"), "custom"),
			File::Spec->catfile($self->param("TMPL_PATH"), "factory"),
			]);
	}

	$self->header_props( 
		-expires => '-1d',  
		# I think this this -expires causes some strange behaviour in IE 
		# on the other hand it is needed in Opera to make sure it won't cache pages.
		-charset => "utf-8",
	);
	$self->session_cookie();
}



# modes that can be accessed without a valid session
my @free_modes = qw(login login_process logout about redirect); 
my @restricted_modes = qw(
	list_dir 
	change_dir 
	upload_file 
	delete_file 
	create_directory 
	remove_directory
	rename_form
	rename
	unzip
); 


=head2 setup

Standart CGI::Appication method to setup the list of all run modes and the default run mode 

=cut
sub setup {
	my $self = shift;
	$self->start_mode("list_dir");
	$self->run_modes(\@free_modes);
	$self->run_modes(\@restricted_modes); 
	#$self->run_modes(AUTOLOAD => "autoload");
}

=head2 cgiapp_prerun

Regular CGI::Application method

=cut
sub cgiapp_prerun {
	my $self = shift;
	my $rm = $self->get_current_runmode();

	return if grep {$rm eq $_} @free_modes;

	# Redirect to login, if necessary
	if (not  $self->session->param('loggedin') ) {
		$self->header_type("redirect");
		$self->header_props(-url => "http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}?rm=login");
		$self->prerun_mode("redirect");
		return;
	}
}


sub _untaint_path {
	my ($self, $path) = @_;

	return "" if not defined $path;
	return "" if $path =~ /\.\./;
	if ($path =~ m{^([\w./-]+)$}) {
		return $1;
	}

	return "";
}


sub _untaint {
	my ($self, $filename) = @_;

	return if not defined $filename;

	return if $filename =~ /\.\./;
	if ($filename =~ /^([\w.-]+)$/) {
		return $1;
	}
	return;
}


=head2 redirect

Just to easily redirect to the home page

=cut
sub redirect {
    my $self = shift;
	return;
#	my $target = shift;
#    $self->header_type("redirect");
#    $self->header_props(-url => "http://$ENV{HTTP_HOST}/$target");
}
    


=head2 load_tmpl

Change the default behaviour of CGI::Application by overriding this
method. By default we'll load the template from within our module.

=cut
sub load_tmpl {
	my $self = shift;

	my $t;
	if ($self->param("TMPL_PATH")) {
		$t = $self->SUPER::load_tmpl(@_);
	} else {
		my $name = shift;
	
		my $template = CGI::FileManager::Templates::_get_template($name);
		croak "Could not load template '$name'" if not $template;

		$t = HTML::Template->new_scalar_ref(\$template, @_);
	}
	

#	my $t = $self->SUPER::load_tmpl(@_, 
#		      die_on_bad_params => -e ($self->param("ROOT") . "/die_on_bad_param") ? 1 : 0
#	);
	return $t;
}

=head2 message

Print an arbitrary message to the next page

=cut
sub message {
	my $self = shift;
	my $message = shift;
	
	my $t = $self->load_tmpl(
			"message",
	);

	$t->param("message" => $message) if $message;
	return $t->output;
}


=head2 login

Show login form

=cut
sub login {
	my $self = shift;
	my $errs = shift;
	my $q = $self->query;
	
	my $t = $self->load_tmpl(
			"login",
			associate => $q,
	);

	$t->param($_ => 1) foreach @$errs;
	return $t->output;
}


=head2 login_process

Processing the login information, checking authentication, configuring the session object
or giving error message.

=cut
sub login_process {
	my $self = shift;
	my $q = $self->query;

	if (not $q->param("username") or not $q->param("password")) {
		return $self->login(["login_failed"]);
	}

	my $auth = $self->authenticate();
	if ($auth->verify($q->param("username"), $q->param("password"))) {
		$self->session->param(loggedin => 1);
		$self->session->param(username => $q->param("username"));
		$self->session->param(homedir  => $auth->home($q->param("username")));
#		$self->session->param(workdir  => $auth->home($q->param("username")));
		$self->header_type("redirect");
		$self->header_props(-url => "http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}");
		return;
	} else {
		return $self->login(["login_failed"]);
	}
}

=head2 authenticate

Called without parameter.
Returns an objects that is capable to authenticate a user.

By default it returns a CGI::FileManager::Auth object.

It is planned that this method will be overriden by the user to be able to replace the
authentication back-end. Currently the requirements from the returned object is to have 
these methods:

 $a->verify(username, password)   returns true/false
 $a->home(username)               return the full path to the home directory of the given user

WARNING: 
this interface might change in the future, before we reach version 1.00 Check the Changes.

=cut
sub authenticate {
	my $self = shift;
	return CGI::FileManager::Auth->new($self->param("AUTH"));
}


=head2 logout

logout and mark the session accordingly.

=cut
sub logout {
	my $self = shift;
	$self->session->param(loggedin => 0);
	my $t = $self->load_tmpl(
			"logout",
	);
	$t->output;
}



=head2 change_dir

Changes the current directory and then lists the new current directory

=cut
sub change_dir {
	my $self = shift;
	my $q = $self->query;

	my $workdir = $self->_untaint_path($q->param("workdir"));
	my $homedir = $self->session->param("homedir");

	my $dir = $q->param("dir");
	if (not defined $dir) {
		warn "change_dir called without a directory name\n";
		return $self->list_dir;
	}
		
	# check santity of the directory
	# something else, does this directory exist ?
	if ($dir eq "..") {
		# ".." are we at the root ?
		if ($workdir eq "") {
			# do nothing (maybe a beep ?)
			return $self->list_dir;
		} else {
			# shorten the path by one
			$workdir = dirname $workdir;
			$self->header_type("redirect");
			$self->header_props(-url => "http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}?rm=list_dir;workdir=$workdir");
			return $self->redirect;
			#Redirect
			return $self->list_dir;
		}
	} else {
		if ($dir =~ /\.\./) {
			warn "change_dir: Two dots ? '$dir'";
			return $self->message("Hmm, two dots in a regular file ? Please contact the administrator");
		}
		if ($dir =~ /^([\w.-]+)$/) {
			$dir = $1;
			$workdir = File::Spec->catfile($workdir, $dir);
			my $path = File::Spec->catfile($homedir, $workdir);
			if (-d $path) {
				$self->header_type("redirect");
				$self->header_props(-url => "http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}?rm=list_dir;workdir=$workdir");
				return $self->redirect;
				#$self->session->param(workdir => $workdir);
				#return $self->list_dir;
			} else {
				# after changing directory people might press back ...
				# and then the whole thing can get scread up not only the change directory
				# but if they now delete a file that happen to exist both in the current directory
				# and in its parent (which is currenly shown in the browser) the file will be deleted
				# from the "current directory", I think the only solution is that the user supplies us
				# with full (virtual) path name for every action.
				# This seems to be easy regarding action on existing files as they are all done by clicking
				# on links and the links can contain.
				# Regardin upload/create dir and later create file we have to know where should the thing go
				# - what does the user think is the current working directory. For such operations we can
				# hide the workdir in a hidden field in the form.
				#
				# In either case we have to make sure the full virtual directory is something the user
				# has right to access.
				 
				#my $workdir_name = basename $workdir;
				#if ($workdir_name eq $dir) {
				#	return $self->message("Heuristics !");
				#} else {
					warn "change_dir: Trying to change to invalid directory ? '$workdir'$dir'";
					return $self->message("It does not seem to be a correct directory. Please contact the administrator");
				#}
			}
		} else {
			warn "change_dir: Bad regex, or bad visitor ? '$dir'";
			return $self->message("Hmm, we don't recognize this. Please contact the administrator");
		}
	}
	
	warn "should never got here....";
	return $self->list_dir;
}

=head2 list_dir

Listing the content of a directory

=cut
sub list_dir {
	my $self = shift;
	my $msgs = shift;

	my $q = $self->query;

	my $workdir = $self->_untaint_path($q->param("workdir"));
	my $homedir = $self->session->param("homedir");
	my $path = File::Spec->catfile($homedir, $workdir);


	my $t = $self->load_tmpl(
			"list_dir",
		 	associate => $q,
			loop_context_vars => 1,
	);
	if (opendir my $dh, $path) {
		my @entries = grep {$_ ne "." and $_ ne ".."} readdir $dh;
		if ($workdir ne "" and $workdir ne "/") {
			unshift @entries, "..";
		}
		my @files;
		
		foreach my $f (@entries) {
			my $full = File::Spec->catfile($path, $f);
			push @files, {
				filename    => $f,
				filetype    => $self->_file_type($full),
				subdir      => -d $full,
				zipfile     => ($full =~ /\.zip/i ? 1 : 0),
				filedate    => scalar (localtime((stat($full))[9])),
				size        => (stat($full))[7],
				delete_link => $f eq ".." ? "" : $self->_delete_link($full),
				rename_link => $f eq ".." ? "" : $self->_rename_link($full),
				workdir     => $workdir,
			};
		}	
		
		$t->param(workdir => $workdir);
		$t->param(files   => \@files);
		$t->param(version => $VERSION);
	}
	$t->param($_ => 1) foreach @$msgs;

	return $t->output;
}

# returns the type of the given file
sub _file_type {
	my ($self, $file) = @_;
	return "dir"  if -d $file;
	return "file" if -f $file;
	return "n/a";
}

sub _delete_link {
	my ($self, $file) = @_;
	return "rm=remove_directory;dir="  if -d $file;
	return "rm=delete_file;filename="  if -f $file;
	return "";
}

sub _rename_link {
	my ($self, $file) = @_;
	return "rm=rename_form;filename="  if -d $file;
	return "rm=rename_form;filename="  if -f $file;
	return "";
}


=head2 delete_file

Delete a file from the server

=cut
sub delete_file {
	my ($self) = @_;
	my $q = $self->query;

	my $filename = $q->param("filename");
	$filename = $self->_untaint($filename);

	if (not $filename) {
		warn "Tainted filename: '" . $q->param("filename") . "'";
		return $self->message("Invalid filename. Please contact the system administrator");
	}
	my $homedir = $self->session->param("homedir");
	my $workdir = $self->_untaint_path($q->param("workdir"));
	
	$filename = File::Spec->catfile($homedir, $workdir, $filename);

	unlink $filename;

	$self->list_dir;
}

=head2 remove_directory

Remove a directory

=cut
sub remove_directory {
	my ($self) = @_;
	my $q = $self->query;

	my $dir = $q->param("dir");
	$dir = $self->_untaint($dir);

	if (not $dir) {
		warn "Tainted diretory name: '" . $q->param("dir") . "'";
		return $self->message("Invalid directory name. Please contact the system administrator");
	}
	my $homedir = $self->session->param("homedir");
	my $workdir = $self->_untaint_path($q->param("workdir"));
	
	$dir = File::Spec->catfile($homedir, $workdir, $dir);

	rmdir $dir;

	$self->list_dir;
}

=head2 unzip

unzip

=cut
sub unzip {
	my $self = shift;
	my $q = $self->query;

	my $filename = $q->param("filename");
	$filename = $self->_untaint($filename);
	$filename = "" if $filename !~ /\.zip/i;

	if (not $filename) {
		warn "Tainted or not zip file name: '" . $q->param("filename") . "'";
		return $self->message("Invalid filename '" . $q->param("filename") . "'. Please contact the system administrator");
	}

	my $homedir = $self->session->param("homedir");
	my $workdir = $self->_untaint_path($q->param("workdir"));

	$filename = File::Spec->catfile($homedir, $workdir, $filename);
	if (not -e $filename) {
		warn "Could not find '$filename' for unzip";
		return $self->message("File does not seem to exist.");
	}

	my $dir = File::Spec->catfile($homedir, $workdir);
	warn "Unzipping $filename in $dir";
	warn `cd $dir; /usr/bin/unzip -o $filename`;

	$self->list_dir;
}
		

=head2 rename_form

Rename file form

=cut
sub rename_form {
	my $self = shift;
	my $q = $self->query;
	
	my $t = $self->load_tmpl(
			"rename_form",
		 	associate => $q,
	);
	return $t->output;
}


sub _move {
	my ($self, $old, $new) = @_;
	
	if (-e $new) {
		return $self->message("Target file already exist");
	}
	move $old, $new;
	return $self->list_dir;
}

=head2 rename

Rename file

=cut
sub rename {
	my $self = shift;
	my $q = $self->query;

	my $old = $q->param("filename");
	my $old_name = $old = $self->_untaint($old);

	if (not $old) {
		warn "Tainted file name: '" . $q->param("filename") . "'";
		return $self->message("Invalid filename '" . $q->param("filename") . "'. Please contact the system administrator");
	}

	my $homedir = $self->session->param("homedir");
	my $workdir = $self->_untaint_path($q->param("workdir"));

	$old = File::Spec->catfile($homedir, $workdir, $old);
	if (not -e $old) {
		warn "Could not find '$old' for rename";
		return $self->message("File does not seem to exist.");
	}


	my $new = $q->param("newname");
	my $targetdir;
	if ($new eq "..") {
		if ($workdir eq "") {
			warn "Trying to move something above the root: '" . $q->param("filename") . "'";
			return $self->message("This wont work. Please contact the system administrator");
		} else {
			$new = File::Spec->catfile($homedir, dirname($workdir), $old_name);
			return $self->_move($old, $new);
		}
	}

	$new = $self->_untaint($new);

	if (not $new) {
		warn "Tainted file name: '" . $q->param("newname") . "'";
		return $self->message("Invalid filename. '" . $q->param("newname") . "' Please contact the system administrator");
	}

	$new = File::Spec->catfile($homedir, $workdir, $new);
	if (-d $new) {
		$new = File::Spec->catfile($new, $old_name);
	}
	return $self->_move($old, $new);
}


=head2 upload_file

Upload a file

=cut
sub upload_file {
	my $self = shift;
	my $q = $self->query;

	my $homedir = $self->session->param("homedir");
	my $workdir = $self->_untaint_path($q->param("workdir"));

	my $upload = CGI::Upload->new();
	my $file_name = $upload->file_name('filename');
	my $in = $upload->file_handle('filename');
	
	if (ref $in ne "IO::File") {
		warn "No file handle in upload ? '$file_name'";
		return $self->message("Hmm, strange. Please contact the administrator");
	}

	if ($file_name =~ /\.\./) {
		warn "two dots in upload file ? '$file_name'";
		return $self->message("Hmm, we don't recognize this. Please contact the administrator");
	}
	if ($file_name =~ /^([\w.-]+)$/) {
		$file_name = $1;
		if (open my $out, ">", File::Spec->catfile($homedir, $workdir,$file_name)) {
			my $buff;
			while (read $in, $buff, 500) {
				print $out $buff;
			}
		} else {
			warn "Could not open local file: '$file_name'";
			return $self->message("Could not open local file. Please contact the administrator");
		}
	} else {
		warn "Invalid name for upload file ? '$file_name'";
		return $self->message("Hmm, we don't recognize this. Please contact the administrator");
	}

	$self->list_dir;
}

=head2 create_directory

Create a directory

=cut
sub create_directory {
	my $self = shift;
	my $q = $self->query;

	my $homedir = $self->session->param("homedir");
	my $workdir = $self->_untaint_path($q->param("workdir"));
	my $dir = $q->param("dir");
	$dir = $self->_untaint($dir);
	if (not $dir) {
		warn "invalid directory: '" . $q->param("dir") . "'";
		return $self->message("Invalid directory name ? Contact the administrator");
	}

	mkdir File::Spec->catfile($homedir, $workdir, $dir);

	$self->list_dir;
}

=head2 DEFAULT

To get the default behavior you can write the following code.
The module will use the built in templates to create the pages.

 #!/usr/bin/perl -wT
 use strict;
 
 use CGI::FileManager;
 my $fm = CGI::FileManager->new(
			PARAMS => {
				AUTH => {
					PASSWD_FILE => "/home/user/mypwfile",
				}
			}
		);
 $fm->run;


=over 4

=item new(OPTIONS)

=back

=head2 META-DATA

Theoretically we could manage some meta-data about each file in some database that
can be either outside our virtual file system or can be a special file in each 
directory.


=cut

# Hmm, either this module does not deal at all with authentication and assumes that 
# something around it can deal with this.

# But we also would like to be able to create a list of users and for each user to assign
# a virtual directory. Onto this virtual directory we would like to be able to "mount"
# any subdirectory of the real file system. We can even go further and provide options
# to this "mount" such as read-only (for that specific user) or read/write.
#=head2 Quota
#Maybe we can also implement some quota on the file system ?


=head2 Limitations

The user running the web server has to have read/write access on the relevant part
of the file system in order to carry out all the functions.

=head1 USE CASES

=head2 Virtual web hosting with no ftp access for one user

A single user needs authentication and full access to one directory tree.
This does not work yet.
 
 #!/usr/bin/perl -T
 
 use CGI::FileManager;
 my $fm = CGI::FileManager->new({
             ROOT => "/home/gabor/web/client1",
	     AUTH => ["george", "WE#$%^DFRE"],   # the latter is the crypt-ed password we expect
             });
 $fm->run;

=head2 Virtual web hosting with no ftp access for a number of users

A number of users need authentication and full access to one directory tree per user.

 #!/usr/bin/perl -T
 
 use CGI::FileManager;
 my $fm = CGI::FileManager->new(
			PARAMS => {
				AUTH => {
					PASSWD_FILE => "/home/user/mypwfile",
				}
			}
		);
 $fm->run;

 The mypwfile file looks similar to an /etc/passwd file:
 username:password:uid:gid:geco:homedir:shell

 gid and shell are currently not used
 homedir is the directory the user has rights for
 password is encrypted by crypt
 uid is just a unique number

=head1 Changes


=head2 v0.01 2004 June 27

 Initial release

=head2 v0.02_01

 Move file/directory
 Unzip file (.zip)

=head2 v0.02_02

 Separate CGI::FileManager::Templates
 add cfm-install.pl install script


 Use CGI::Application::Plugin::Session
 remove catching the warning of CA and require higher version of CA
 add a test that test a particular warning
 some subs were called as functions, now they are called as methods allowing better subclassing

=head1 TODO

 - install the module as regular CPAN module and add a script that will generate the templates
   and hard-code their location in the script.
 
 - Replace the Unix::ConfigFile with my own implementation

 Test the module on Windows and find out what need to be done to pass the windows
 tests ? Especially look at Unix::ConfigFile

 Show most of the error messages on the directory listing page
 
 Support for filenames with funny characters (eg. space)

 Test all the functions, look for security issues !
 Show the current directory  (the virtual path)
 Separate footer/header
 Enable external templates

 Security issues: can I be sure that unzipping a file will open files only under the current directory ?
 What should I do in case a file that comes from an unzip operation already exists ?

 ZIP: currently the path to unzip is hard coded. It probably should be replaced by Archive::Zip

 More fancy things:
 Create file
 Copy file/directory
 Unzip file (tar/gz/zip)
 Edit file (simple editor)

 look at CGI::Explorer and check what is the relationsip to it ?

=head1 Author

Gabor Szabo, C<< <gabor@pti.co.il> >>

=head1 Bugs

Please report any bugs or feature requests to
C<bug-cgi-filemanager@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.


=head1 Copyright & License

Copyright 2004 Gabor Szabo, All Rights Reserved.
L<http://www.szabgab.com/>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 See also

CGI::Upload, WWW::FileManager, CGI::Uploader

=cut

1; 

