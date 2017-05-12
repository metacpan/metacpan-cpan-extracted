#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use lib '/home/ben/projects/C-Tokenize/lib';
use C::Tokenize qw/tokenize @fields/;
use File::Slurper 'read_text';

=head1 NAME

c2html - convert C program text into HTML

=head1 SYNOPSIS

    c2html bug.c > bug.c.html

The output HTML probably requires editing to be useful.

Requires L<File::Slurper> (not a distribution dependency).

=cut

for my $file (@ARGV) {
    my $text = read_text ($file);
    my $tokens = tokenize ($text);
    my $html = make_html ($tokens);
    $html = boilerplate ($html, $file);
    print $html;
}

exit;

sub boilerplate
{
    my ($html, $file_name) = @_;
    my $top = '';
    $top .= <<EOF;
<html><head><title>$file_name</title>
<style>
EOF
    for my $field (@fields) {
        $top .= ".$field {color:#". sprintf ("%06X", rand (0x1000000)) ."}\n";
    }
    $top .= <<EOF;
</style>
</head><body>
EOF
    my $bottom = '';
    $bottom .= <<EOF;
</body></html>
EOF
    $html = "$top$html$bottom";
    return $html;
}

sub make_html
{
    my ($tokens_ref) = @_;
    my $html = '';
    $html .= "<pre class='c-code'>\n";
    for my $token (@$tokens_ref) {
        $html .= $token->{leading};
        my $type = $token->{type};
        $html .= "<span class='$type'>";
        my $value = $token->{$type};
        $value =~ s/([<>&])/"&#".ord ($1).";"/ge;
        $html .= $value;
        $html .= "</span>";
    }
    $html .= "</pre>\n";
    return $html;
}

