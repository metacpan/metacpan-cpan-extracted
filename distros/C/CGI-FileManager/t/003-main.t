#!/usr/bin/perl -w
use strict;


use Test::More "no_plan";
use Test::Warn;

use lib ("blib/lib", "t/lib");
use CGI::FileManager;

use CGI::FileManager::Test;

my $t = CGI::FileManager::Test->new({
	module => "CGI::FileManager",
	cookie => "cgi-filemanager",
});

my $cookie;
my $parent = "\Q..\E";   # the regex for matching the text shown on parent directory

# access main page and login screen
{
	my $result = $t->cgiapp("/");
	like ($result, qr{\QLocation: http://test-host/?rm=login}, "Redirected");
	my $cookie = $t->extract_cookie($result);
	is($cookie, "", "no cookie, when redirecting");
}

# get a new cookie
{
	my $result = $t->cgiapp("/", "", {rm => "login"});  # try also  /?rm=login
	like($result, qr{Login form});
	$cookie = $t->extract_cookie($result);
	like($cookie, qr{^\w+$}, "nice cookie, eh ?");
	unlike($result, qr{gabor});
	unlike($result, qr{Login failed});
	unlike($result, qr{badpw});
	like($result,  qr{text/css});
}

# failed logins:
{
	my $result = $t->cgiapp("/", $cookie, {rm => "login_process"});
	my $newcookie = $t->extract_cookie($result);
	is($newcookie, $cookie, "Cookie did not change");
	like($result, qr{Login form});
	unlike($result, qr{gabor});
	like($result, qr{Login failed});
	unlike($result, qr{badpw});
}

{
	my $result = $t->cgiapp("/", $cookie, {rm => "login_process", username => "gabor", password=> "badpw"});
	like($result, qr{Login form});
	like($result, qr{gabor});
	like($result, qr{Login failed});
	unlike($result, qr{badpw});
	like($result,  qr{text/css});
}

# successful login:
{
	my $result = $t->cgiapp("/", $cookie, {rm => "login_process", username => "gabor", password=> "nincs"});
	like ($result, qr{\QLocation: http://test-host/}, "Redirected to home page");
}

# accessing home page after login
{
	my $result = $t->cgiapp("/", $cookie);
	unlike($result, qr{Login form});
	like($result, qr{gabor\@pti.co.il});
	unlike($result, qr{Login failed});
	unlike($result, qr{badpw});
	like($result, qr{Directory Listing});
	like($result,  qr{text/css});

	like($result,  qr{data\.txt});
	unlike($result,  qr{<a href="\?rm=change_dir;workdir=;dir=\.\.">\s*$parent\s*</a>});
	like($result,  qr{<a href="\?rm=change_dir;workdir=;dir=subdir">\s*subdir\s*</a>});
}

# changing to a subdir
{
	my $result = $t->cgiapp("/", $cookie, {rm => "change_dir", dir => "subdir"});
	like($result, qr{Location: http://test-host/\?rm=list_dir;workdir=/subdir});
}
{
	my $result = $t->cgiapp("/", $cookie, {rm => "list_dir", workdir => "/subdir"});
	like($result, qr{Directory Listing});
	unlike($result,  qr{data\.txt});
	unlike($result,  qr{<a href="\?rm=change_dir;workdir=/subdir;dir=subdir">\s*subdir\s*</a>});
	like($result,  qr{<a href="\?rm=change_dir;workdir=/subdir;dir=\.\.">\s*$parent\s*</a>});
	like($result,  qr{somefile\.txt});
}	

# listing the home directory again
{
	my $result = $t->cgiapp("/", $cookie, {rm => "list_dir", workdir => "" });
	like($result, qr{Directory Listing});
	like($result,  qr{data\.txt});
	like($result,  qr{<a href="\?rm=change_dir;workdir=;dir=subdir">\s*subdir\s*</a>});
	unlike($result,  qr{<a href="\?rm=change_dir;workdir=;dir=\.\.">\s*$parent\s*</a>});
	unlike($result,  qr{somefile\.txt});
}	

# changing back to the parent
{
	my $result = $t->cgiapp("/", $cookie, {rm => "change_dir", workdir => "/subdir", dir => ".."});
	like($result, qr{Location: http://test-host/\?rm=list_dir;workdir=/});

}
{
	my $result = $t->cgiapp("/", $cookie, {rm => "list_dir", workdir => "/"});
	like($result, qr{Directory Listing});
	like($result,  qr{data\.txt});
	like($result,  qr{<a href="\?rm=change_dir;workdir=/;dir=subdir">\s*subdir\s*</a>});
	unlike($result,  qr{<a href="\?rm=change_dir;workdir=/;dir=\.\.">\s*$parent\s*</a>});
	unlike($result,  qr{somefile\.txt});
}	

# trying to change back (..) from the root
{
	my $result = $t->cgiapp("/", $cookie, {rm => "change_dir", workdir => "/", dir => ".."});
	like($result, qr{Location: http://test-host/\?rm=list_dir;workdir=/});
}

{
	my $result = $t->cgiapp("/", $cookie, {rm => "list_dir", workdir => ""});
	like($result, qr{Directory Listing});
	like($result,  qr{data\.txt});
	like($result,  qr{<a href="\?rm=change_dir;workdir=;dir=subdir">\s*subdir\s*</a>});
	unlike($result,  qr{<a href="\?rm=change_dir;workdir=;dir=\.\.">\s*$parent\s*</a>});
	unlike($result,  qr{somefile\.txt});
}	

# trying to change back (..) from the root
{
	my $result = $t->cgiapp("/", $cookie, {rm => "change_dir", dir => ".."});
	like($result, qr{Directory Listing});
	like($result,  qr{data\.txt});
	like($result,  qr{<a href="\?rm=change_dir;workdir=;dir=subdir">\s*subdir\s*</a>});
	unlike($result,  qr{<a href="\?rm=change_dir;workdir=;dir=\.\.">\s*$parent\s*</a>});
	unlike($result,  qr{somefile\.txt});
}	


# trying to change to a non existant subdir
{

	# this gives a warning but we use __WARN__ so we cannot use Test::Warn here
	my $result;
	warning_like 
		{$result = $t->cgiapp("/", $cookie, {rm => "change_dir", dir => "nosuch"})}
		qr{Trying to change to invalid directory},
		"invalid directory change warning";
	like($result,  qr{It does not seem to be a correct directory. Please contact the administrator});
}




# logout
{
	my $result = $t->cgiapp("/", $cookie, {rm => "logout"});
	like($result, qr{Good bye});

	# after logut cannot access the internal pages
	$result = $t->cgiapp("/", $cookie);
	like ($result, qr{\QLocation: http://test-host/?rm=login}, "Redirected");
}




