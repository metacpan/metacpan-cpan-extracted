#!/usr/bin/env perl

use strict;
use warnings;

use CGI::Pure;
use CGI::Pure::Save;
use IO::Barf qw(barf);
use File::Temp qw(tempfile);
use File::Slurp qw(write_file);

# Temporary file.
my ($tempfile_fh, $tempfile) = tempfile();

# CGI::Pure data.
my $cgi_pure_data = <<'END';
par1=val1
par1=val2
par2=value
=
END

# Create file.
barf($tempfile_fh, $cgi_pure_data);
close $tempfile_fh;

# CGI::Pure Object.
my $cgi = CGI::Pure->new;

# CGI::Pure::Save object.
my $save = CGI::Pure::Save->new(
	'cgi_pure' => $cgi,
);

# Load.
open $tempfile_fh, '<', $tempfile;
$save->load($tempfile_fh);
close $tempfile_fh;

# Print out.
foreach my $param_key ($cgi->param) {
	print "Param '$param_key': ".join(' ', $cgi->param($param_key))."\n";
}

# Clean temp file.
unlink $tempfile;

# Output:
# Param 'par1': val1 val2
# Param 'par2': value