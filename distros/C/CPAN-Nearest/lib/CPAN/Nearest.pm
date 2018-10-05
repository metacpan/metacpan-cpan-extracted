package CPAN::Nearest;
use warnings;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/search/;
our $VERSION = '0.14';
use Carp;
use Text::Fuzzy '0.25';
use Gzip::Faster '0.18', 'gunzip_file';

sub search
{
    my ($file, $module) = @_;
    if (! -f $file) {
	carp "Cannot find module file '$file'.\n";
    }
    my $text;
    if ($file =~ /\.gz$/) {
	$text = gunzip_file ($file);
    }
    else {
	# Slurp file
	local $/ = undef;
	open my $in, "<", $file or croak "Error opening '$file': $!";
	$text = <$in>;
	close $in or die $!;
    }
    my @modules;
    # Skip to first line.
    $text =~ s/.*^\s*$//m;
    while ($text =~ /^(\S+)\s+(\S+)\s+(\S*)\s*$/gm) {
	push @modules, $1;
    }
    my $tf = Text::Fuzzy->new ($module, max => 10);
    return $tf->nearestv (\@modules);
}

1;

