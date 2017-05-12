#!/usr/bin/perl -w
use strict;


use Test::More "no_plan";

use lib ("blib/lib", "t/lib");
use CGI::FileManager;

use CGI::FileManager::Test;

my $t = CGI::FileManager::Test->new({
	module => "CGI::FileManager",
	cookie => "cgi-filemanager",
});

my $cookie;
my $parent = "\Q..\E";   # the regex for matching the text shown on parent directory

# get a new cookie and login
{
	my $result = $t->cgiapp("/", "", {rm => "login"});  # try also  /?rm=login
	$cookie = $t->extract_cookie($result);
	$t->cgiapp("/", $cookie, {rm => "login_process", username => "gabor", password=> "nincs"});
}

# accessing home page after login
{
	my $result = $t->cgiapp("/", $cookie);
	like($result, qr{Directory Listing});
	like($result,  qr{data\.txt});
	unlike($result,  qr{<a href="\?rm=change_dir;workdir=;dir=\.\.">\s*$parent\s*</a>});
	like($result,  qr{<a href="\?rm=change_dir;workdir=;dir=subdir">\s*subdir\s*</a>});
	unlike($result,  qr{new_file\.txt});
}

{
	ok(not(-f "dir/new_file.txt"), "file is not there yet");
	my $result = $t->upload_file("/", $cookie, {rm => "upload_file"}, "local/1.txt", "somename/new_file.txt");
	ok((-f "dir/new_file.txt"), "file was uploaded");

	like($result, qr{Directory Listing});
	like($result,  qr{data\.txt});
	unlike($result,  qr{<a href="\?rm=change_dir;workdir=;dir=\.\.">\s*$parent\s*</a>});
	like($result,  qr{<a href="\?rm=change_dir;workdir=;dir=subdir">\s*subdir\s*</a>});
	like($result,  qr{new_file\.txt});

	# compare file content !
	# test binary files too
}

# delete a file
{
	my $result = $t->cgiapp("/", $cookie, {rm => "delete_file", filename => "new_file.txt"});
	ok(not(-f "dir/new_file.txt"), "file is not there any more");

	like($result, qr{Directory Listing});
	like($result,  qr{data\.txt});
	unlike($result,  qr{<a href="\?rm=change_dir;workdir=;dir=\.\.">\s*$parent\s*</a>});
	like($result,  qr{<a href="\?rm=change_dir;workdir=;dir=subdir">\s*subdir\s*</a>});
	unlike($result,  qr{new_file\.txt});
}
	

# try to delete not existing file (maybe should give a warning ?)
{
	my $result = $t->cgiapp("/", $cookie, {rm => "delete_file", filename => "new_file.txt"});
	ok(not(-f "dir/new_file.txt"), "file is not there any more");

	like($result, qr{Directory Listing});
	like($result,  qr{data\.txt});
	unlike($result,  qr{<a href="\?rm=change_dir;workdir=;dir=\.\.">\s*$parent\s*</a>});
	like($result,  qr{<a href="\?rm=change_dir;workdir=;dir=subdir">\s*subdir\s*</a>});
	unlike($result,  qr{new_file\.txt});
}
	
# create new directory
{
	ok(not(-d "dir/folder"), "folder is not there yet");
	my $result = $t->cgiapp("/", $cookie, {rm => "create_directory", dir => "folder"});
	ok(-d "dir/folder", "folder is already there");
}

# change directory to the new one
# upload a file to the subdirectory
# change back to parent, try to delete child - and fail
# change back to child
# remove uploaded file
# change back to parent
# remove directory

{
	my $result = $t->cgiapp("/", $cookie, {rm => "remove_directory", dir => "folder"});
	ok(not(-d "dir/folder"), "folder is not there any more");
}



