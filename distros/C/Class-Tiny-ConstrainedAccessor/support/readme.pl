#!perl
# readme_md.pl: Make README.md from a Perl file.
# Part of Class::Tiny::ConstrainedAccessor.

use 5.014;
use strict;
use warnings;
use Getopt::Long qw(:config gnu_getopt);
use Path::Class;

# Parse command-line options
my ($source_fn, $dest_fn, $appveyor, $appveyor_badge, $travis, $travis_badge);
my $format = 'md';
GetOptions( "i|input=s" => \$source_fn,
            "o|output=s" => \$dest_fn,
            "f|format=s" => \$format,
            "appveyor=s" => \$appveyor,         # username/repo
            "avbadge=s" => \$appveyor_badge,    # default $appveyor
            "travis=s" => \$travis,             # username/repo
            "trbadge=s" => \$travis_badge,      # default $travis
)
    or die "Error in arguments.  Usage:\nreadme_md.pl -i input -o output [-f format]\nFormat = md (default) or text.";

die "Need an input file" unless $source_fn;
die "Need an output file" unless $dest_fn;

$appveyor =~ m{^[A-Za-z0-9-]+/[A-Za-z0-9-]+} or die '--appveyor <GH username>/<GH repo>' if $appveyor;
$appveyor_badge //= $appveyor;
$appveyor_badge =~ m{^[A-Za-z0-9-]+/[A-Za-z0-9-]+} or die '--avbadge <GH username>/<GH repo>' if $appveyor_badge;

$travis =~ m{^[A-Za-z0-9-]+/[A-Za-z0-9-]+} or die '--travis <GH username>/<GH repo>' if $travis;
$travis_badge //= $travis;
$travis_badge =~ m{^[A-Za-z0-9-]+/[A-Za-z0-9-]+} or die '--trbadge <GH username>/<GH repo>' if $travis_badge;


# Load the right parser
my $parser;
if($format eq 'md') {
    require Pod::Markdown;
    $parser = Pod::Markdown->new;

} elsif($format eq 'text') {
    require Pod::Text;
    $parser = Pod::Text->new(sentence => 1, width => 78);

} else {
    die "Invalid format $format (I understand 'md' and 'text')"
}

# Turn the POD into the output format
my $parsed = '';
$parser->output_string(\$parsed);
my $pod = file($source_fn)->slurp;
$parser->parse_string_document($pod);
open my $fh, '<', \$parsed;

# Filter and tweak the POD
my $saw_name = 0;
my $tweak_name = ($format eq 'md');
my $output = '';

while(my $line = <$fh>) {

    # In Markdown, turn NAME into the text, as a heading.
    # Also add the Appveyor badge.
    if($tweak_name && !$saw_name && $line =~ /NAME/) {
        $saw_name = 1;
        next;
    } elsif($tweak_name && $saw_name && $line =~ m{\H\h*$/}) {
        $output .= ($format eq 'md' ? '# ' : '') . "$line\n";
        $output .= "[![Appveyor Status](https://img.shields.io/appveyor/ci/${appveyor_badge}.svg?logo=appveyor)](https://ci.appveyor.com/project/${appveyor}) " if $appveyor;
        $output .= "[![Travis Status](https://img.shields.io/travis/${travis_badge}.svg?logo=travis)](https://travis-ci.org/${travis}) " if $travis;

        $output .= "\n\n" if $appveyor || $travis;
        $saw_name = 0;
        next;
    } elsif($tweak_name && $saw_name) {
        next;   # Waiting for the name line to come around
    }

    next if $line =~ /SYNOPSIS/;    # Don't need this header.

##    # Skip the internals
##    $output .= $line if $line =~ /AUTHOR/;
##    next if ($line =~ /SUBROUTINES/)..($line =~ /AUTHOR/);

    $output .= $line;   # Copy everything that's left.
}

file($dest_fn)->spew($output);
