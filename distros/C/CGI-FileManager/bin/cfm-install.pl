#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Path qw(mkpath);
use Data::Dumper qw(Dumper);
use Pod::Usage qw(pod2usage);

use lib "lib";
use CGI::FileManager::Templates;


my %opt;
GetOptions(\%opt, "dir=s", "help", "force");
$opt{dir} ||= ".";

if ($opt{help}) {
	pod2usage(2);
	exit;
}


if (-e $opt{dir}) {
	opendir my $dh, $opt{dir} or die "Could not look at directory '$opt{dir}' $!\n";
	if (not $opt{force} and grep {$_ ne "." and $_ ne ".."} readdir $dh) {
		die "Cannot install in non-empty directory\n";
	}
} else {
	eval {
		mkpath($opt{dir});
	};
	if ($@) {
		die "Could not create directory: '$opt{dir}'   $@";
	}
}

foreach my $dir (qw(cgi data templates css templates/custom templates/factory)) {
	eval {
		mkpath(File::Spec->catfile($opt{dir}, $dir));
	};
	if ($@) {
		die "Could not create directory: '$dir'   $@";
	}
}

# put in cgi directory, in it the cgi script
# next to it templates directory
# next to it data directory

foreach my $name (keys %CGI::FileManager::Templates::tmpl) {
	my $t_file = File::Spec->catfile($opt{dir}, "templates", "factory", $name);
	open my $fh, ">", $t_file or die "Could not open '$t_file' $!\n";
	$CGI::FileManager::Templates::tmpl{$name} =~ s{CSS_STYLE_SHEET}{<link rel="stylesheet" href="../css/style.css" type="text/css">};
	print $fh $CGI::FileManager::Templates::tmpl{$name};
}

{
	my $css_file = File::Spec->catfile($opt{dir}, "css", "style.css");
	open my $fh, ">", $css_file or die "Could not open '$css_file' $!\n";
	print $fh $CGI::FileManager::Templates::css;
}

{
	my $cgi_file = File::Spec->catfile($opt{dir}, "cgi", "fm.pl");
	open my $fh, ">", $cgi_file or die "Could not open '$cgi_file' $!\n";
	print $fh $CGI::FileManager::Templates::cgi;
	chmod oct(755), $cgi_file;
}


#print <<MSG;
#You have to add users now.  Please run:
#
#cfm-passwd.pl $opt{dir}/data/authpasswd  add username
#MSG


# add users in the data directory

#print Dumper \%opt;

=head1 SYNOPSIS

  Usage:
     cfm-install.pl
	                 --dir      DIR      where to install (defaults to current directory)
					 --help              this help
					 --force             overwrite whatever you want

=cut


