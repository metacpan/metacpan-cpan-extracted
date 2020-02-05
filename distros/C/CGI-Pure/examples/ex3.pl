#!/usr/bin/env perl

use strict;
use warnings;

use CGI::Pure;
use CGI::Pure::Save;
use File::Temp qw(tempfile);
use Perl6::Slurp qw(slurp);

# Temporary file.
my ($tempfile_fh, $tempfile) = tempfile();

# Query string.
my $query_string = 'par1=val1;par1=val2;par2=value';

# CGI::Pure Object.
my $cgi = CGI::Pure->new(
	'init' => $query_string,
);

# CGI::Pure::Save object.
my $save = CGI::Pure::Save->new(
	'cgi_pure' => $cgi,
);

# Save.
$save->save($tempfile_fh);
close $tempfile_fh;

# Print file.
print slurp($tempfile);

# Clean temp file.
unlink $tempfile;

# Output:
# par1=val1
# par1=val2
# par2=value
# =