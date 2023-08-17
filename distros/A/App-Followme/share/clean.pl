#!/usr/bin/perl

use strict;
use warnings;

use IO::File;
use Getopt::Std;

use App::Followme::Web;

# False outside of body tags, true inside
our $in_body;

use constant PATTERNS => <<EOQ;
# Rework quote paragraphs
(<p><font><b>*</b></font></p>)                      ->   <p>(<b>*</b><br/>)</p>
# Remove cruft from comment paragraphs
<p><font>*</font></p>                               ->   <p>*</p>
# Remove paragraphs containing breaks
<p><br/>*</p>                                       ->
# Title
<p><font><font size="6"><b>*</b></font></font></p>  ->   <h1>*</h1>
# Subtitle
<h1>*</h1>                                          ->   <h2>*</h2>
# Remove font tags
<font>*</font>                                      ->   *
# Remove other span tags
<span>*</span>                                      ->   *
# Remove document styling
<style>*</style>                                    ->
# Remove metadata tags
<meta>                                              ->
EOQ

use constant TEMPLATE => <<EOQ;
<html>
<head>
<!-- section meta -->
<title></title>
<!-- endsection meta -->
</head>
<body>
<!-- section primary -->
<!-- endsection primary-->
<!-- section secondary -->
<!-- endsection secondary-->
</body>
</html>
EOQ

use constant METADATA => <<EOQ;
<title></title>
<meta name="description" content="">
<meta name="keywords" content="">
<meta name="author" content="">
EOQ

#----------------------------------------------------------------------
# Main

my %opt;
getopts('r', \%opt);

if ($opt{r}) {
    revert_files(@ARGV);
} else {
    my $patterns = read_patterns(PATTERNS);
    clean_files($patterns, @ARGV);
}

#----------------------------------------------------------------------
# Add sections to cleaned file

sub add_sections {
    my ($text, $template) = @_;

    my @hold;
    my @output;
    my @input = web_split_at_tags($text);

    foreach my $tag ($template =~ /<[^>]*>/g) {
        if ($tag =~ /^<!--\s*end/) {
            push(@hold, $tag);

        } elsif ($tag =~ /^<!--/) {
            if (@hold) {
                push(@hold, $tag);
            } else {
                push(@output, shift @input);
                push(@output, "$tag\n");
            }

        } else {
            my $extra;
            if (@hold) {
                $extra = join("\n", @hold) . "\n";
                @hold = ();
            }

            my $output = search_for_tag(\@input, $tag, $extra);
            push(@output, $output);
        }
    }

    die "No matching tag for\n" . join("\n", @hold) . "\n" if @hold;

    push(@output, @input);
    return join('', @output)
}

#----------------------------------------------------------------------
# Create a backup copy of the original file

sub backup_file {
    my ($file, $text) = @_;
    $file .= '~';

    write_file($file, $text);
}

#----------------------------------------------------------------------
# Clean each file by substuting tokens with their patterns

sub clean_files {
    my ($patterns, @files) = @_;


    foreach my $file (@files) {
        my $text = slurp_file($file);
        backup_file($file, $text);

        my @tags = web_split_at_tags($text);
        my $tokens = {next => 0, data => \@tags};
        $text = replace_tokens($patterns, $tokens);

        $text = add_sections($text, TEMPLATE);
        $text = web_substitute_sections($text, {meta => METADATA});
        write_file($file, $text);
    }

    return;
}

#----------------------------------------------------------------------
# Remove parameters from a token

sub clean_token {
    my ($token) = @_;

    if (web_is_tag($token)) {
        $in_body = 1 if $in_body == 0 and $token =~ /^<body/;
        $in_body = 0 if $in_body == 1 and $token =~ /^<\/body/;
        $token =~ s/^<\s*([\/\w]+)[^>]*>/<$1>/ if $in_body;
    } 

    return $token;
}

#----------------------------------------------------------------------
# Fill text to fit 65+ characters per line

sub fill_text {
    my ($text) = @_;

    # Convert code to space
    $text =~ s/&#8198;/ /g;
    # Convert all white space to a single space
    $text =~ s/\s+/ /g;
    # Convert first white space after 65th character to a newline
    $text =~ s/(.{65}\S*)\s/$1\n/g;

    return $text;
}

#----------------------------------------------------------------------
# Find the location ($i) of the $iast-th asterisk in a pattern

sub find_asterisk {
    my ($pattern, $iast) = @_;

    for (my $i = 0; $i < @$pattern; $i++) {
        $iast -- if $pattern->[$i] eq '*';
        return $i if $iast == 0;
    }

    die "No asterisk found for replace_match";
}

#----------------------------------------------------------------------
# Find the $j-th group in the array

sub find_group {
    my ($array, $igroup) = @_;

    for (my $i = 0; $i <= @$array; $i++) {
        $igroup -- if ref($array->[$i]) eq 'ARRAY';
        return $i if $igroup == 0;
    } 

    die "Group not found in array in replace_match";
}

#----------------------------------------------------------------------
# Find the match to a pattern, or fail

sub find_match {
    my ($pattern, $patterns, $tokens, $repeat) = @_;

    my @matches = ();

    do {
        my $next = 0;
        my @submatch = ();
        my $first = $tokens->{next};

        while ($next < @$pattern &&
               $tokens->{next} < @{$tokens->{data}}) {

            my $token = $tokens->{data}[$tokens->{next}];
            if ($token !~ /\S/) {
                $tokens->{next} ++;
                next;
            }

            $token = web_parse_tag($token) if web_is_tag($token);

            if ($pattern->[$next] eq '*') {
                die "Invalid pattern" if $next+1 == @$pattern;
                my $text = search_for_end($patterns, $tokens, 
                                        $pattern->[$next+1]);
                last unless defined $text;

                push(@submatch, $text);
            
            } elsif (ref $pattern->[$next] eq 'ARRAY') {
                my $match = find_match($pattern->[$next], $patterns, $tokens, 1);
                last unless @$match;

                push(@submatch, $match);
                $tokens->{next} ++;

            } elsif (ref $pattern->[$next] eq 'HASH') {
                last unless ref $token;
                last unless web_same_tag($pattern->[$next], $token);
                push(@submatch, $token);
                $tokens->{next} ++;

            } else {
                last if ref $token;
                last unless $token =~ /$pattern->[$next]/;
                push(@submatch, $token);
                $tokens->{next} ++;
            }

            $next ++;
        }

        if ($next < @$pattern) {
            $tokens->{next} = $first;
            return \@matches; 

        } else {
            push(@matches, \@submatch);
        }

    } while ($repeat);

    return \@matches;
}

#----------------------------------------------------------------------
# Get the replacement for the next matched tokens

sub get_match {
    my ($patterns, $tokens) = @_;

    my $i = 0;
    my $first = $tokens->{next};

    while ($i < @$patterns) {
        $tokens->{next} = $first;

        my $matches = find_match($patterns->[$i], $patterns, $tokens);
        if (@$matches) {
            return replace_match($patterns->[$i], $patterns->[$i+1], $matches);
        } else {
            $i += 2;
        }
    }

    $tokens->{next} = $first;
    return;
}

#----------------------------------------------------------------------
# Parse pattern to match text

sub parse_pattern {
    my ($pattern_parts, $stopper) = @_;

    my $part;
    my @pattern;
    while (defined($part = shift @$pattern_parts)) {
        if ($part eq '(') {
            push(@pattern, parse_pattern($pattern_parts, ')'));

        } elsif ($stopper && $part eq $stopper) {
            last;

        } else {
            foreach (web_split_at_tags($part)) {
                if (web_is_tag($_)) {
                    push(@pattern, web_parse_tag($_));
                } else {
                    push(@pattern, $_);
                }
            }
        }
    }

    return \@pattern;
}

#----------------------------------------------------------------------
# Read and parse pattern tokens in file

sub read_patterns {
    my ($patterns) = @_;

    my @patterns;
    my @pattern_line = split(/\n/, $patterns);

    foreach (@pattern_line) {
        s/\#.*//;
        next unless /\S/;

        my @pattern_text = split(/->/, $_);
        if  (@pattern_text > 2 || $pattern_text[0] !~ /\S/) {
            die "Bad patterns on line:\n$_\n";
        }
        
        foreach (@pattern_text) {
            s/^\s+//;
            s/\s+$//;
            my @pattern_parts = grep (/\S/, split(/([\(\)])/, $_));
            push(@patterns, parse_pattern(\@pattern_parts))
        }

        push(@patterns, ["\n"]) if @pattern_text == 1;
    }

    return \@patterns;
}

#----------------------------------------------------------------------
# Get the replacement for a match

sub replace_match {
    my ($pattern, $replacement, $matches) = @_;

    my @tokens;
    for my $match (@$matches) {
        my $iast = 1;
        my $igroup = 1;
        my @subtokens = ();
        for (my $irep = 0; $irep < @$replacement; $irep++) {
            my $subtoken;
            if (ref $replacement->[$irep] eq 'HASH') {
                my %subtoken = %{$replacement->[$irep]};
                foreach my $key (keys %subtoken) {
                    $subtoken{$key} = $match->[$irep]{$key} 
                                      if $subtoken{$key} eq '*'; 
                }

                $subtoken = '<';
                $subtoken .= delete $subtoken{_};
                while (my ($key, $value) = each %subtoken) {
                    $subtoken .= " $key=\"$value\"";
                }
                $subtoken .= '>';      
        
            } elsif (ref $replacement->[$irep] eq 'ARRAY') {
                my $group = find_group($pattern, $igroup);
                $igroup ++;

                $subtoken = replace_match($pattern->[$group], 
                                          $replacement->[$irep], 
                                          $match->[$group]);

            } elsif ($replacement->[$irep] eq '*') {
                my $asterisk = find_asterisk($pattern, $iast);
                $subtoken = fill_text($match->[$asterisk]);
                $iast ++;

            } else {
                $subtoken = $replacement->[$irep];
            }

            push(@subtokens, $subtoken);
        }

        push(@tokens, join('', @subtokens))
    }

    return join("\n", @tokens);
}

#----------------------------------------------------------------------
# Find the replacement for the next token or tokens

sub replace_a_token {
    my ($patterns, $tokens) = @_;

    my $replacement;
    my $token = $tokens->{data}[$tokens->{next}];
    $replacement = get_match($patterns, $tokens) if web_is_tag($token);

    if (! defined $replacement) {
        $replacement = clean_token($token);
        $tokens->{next} ++;
    }

    return $replacement
}

#----------------------------------------------------------------------
# Replace tokens in text according to patterns

sub replace_tokens {
    my ($patterns, $tokens) = @_;

    $in_body = 0;
    my @replaced_tokens;
    while ($tokens->{next} < @{$tokens->{data}}) {
        push(@replaced_tokens, replace_a_token($patterns, $tokens));
    }

    my $text = join('', @replaced_tokens);

    $text =~ s/[ \r\t]+\n/\n/g;
    $text =~ s/\n{3,}/\n\n/g;

    return $text;
}

#----------------------------------------------------------------------
# Revert to original version of files

sub revert_files {

    foreach my $file (@_) {
        my $old_file = "$file~";
        rename($old_file, $file) if -e $old_file;
    }

    return;
}

#----------------------------------------------------------------------
# Look for a stop pattern, accumulate tokens until then

sub search_for_end {
    my ($patterns, $tokens, $next_pattern) = @_;

    my $found;
    my @replaced_tokens;
    while ($tokens->{next} < @{$tokens->{data}}) {
        my $token = $tokens->{data}[$tokens->{next}];

        if (web_is_tag($token)) {
            $token = web_parse_tag($token);
            if (web_same_tag($next_pattern, $token)) {
                $found = 1;
                last;
            }
        }

        push(@replaced_tokens, replace_a_token($patterns, $tokens));
    }

    return $found ? join('', @replaced_tokens) : undef;

}

#----------------------------------------------------------------------
# Look for a stop tag, accumulate tokens until then

sub search_for_tag {
    my ($input, $next_tag, $extra) = @_;

    my @output;
    my $pattern = web_parse_tag($next_tag);

    while (@$input) {
        my $input_tag = shift(@$input);

        if (web_is_tag($input_tag)) {
            my $token = web_parse_tag($input_tag);

            if (web_same_tag($pattern, $token)) {
                push(@output, $extra) if $extra;
                push(@output, $input_tag);
                last;
            }
        } 

        push(@output, $input_tag);
    }

    return join('', @output);
}

#----------------------------------------------------------------------
# Read the file into a single string

sub slurp_file {
    my ($file) = @_;

    local $/;
    my $fd = IO::File->new($file, 'r');
    die "Couldn't read file ($file): $!\n" unless $fd;

    my $text = <$fd>;
    return $text;
}

#----------------------------------------------------------------------
# Write 

sub write_file {
    my ($file, $text) = @_;

    my $fd = IO::File->new($file, 'w');
    die "Couldn't write file ($file): $!\n" unless $fd;

    print $fd $text;
    close($fd);
}

__END__

=encoding utf-8

=head1 NAME

clean.pl - Remove unwanted html from file

=head1 SYNOPSIS

    perl clean.pl html_file [html_file]*

=head1 DESCRIPTION

Parse an html file into html tags and text. Use the patterns in a pattern
string to match and replace combinations of tags and text. Save the existing 
file by appending a ~ to the file name and save the modified file under 
the old name. Use the -r option to restore the original file under its old name.

In addition to the replacements in the patterns string, this script strips 
options from html tags not mentioned in the patterns string, fills pararagraph
lines to 65 characters, and deletes consecutive blank lines.

=head1 CONFIGURATION

The PATTERNS string has two patterns on each line separated by
the string "->". The first pattern is matched in the html file and replaced
using the second pattern. The second pattern can be blank. In this case the
html matched by the first pattern is replace by an empty line. The file can
contain blank and comment lines in addition to pattern lines. Comment lines
start with a sharp character (#). 

Patterns contain a combination to tags and text. Partial matches are done on 
tage. For example, <div> matches any div tag while <div class="article"> 
only matches tags of the article class and <div class=*> matches any div tag
with a class option. A single star (*) matches any combination of text or tags. 
Any other text is matched as a regular expression. Patterns can be grouped 
inside of parentheses, which mean match one or more consecutive instances of 
the pattern.

The replacement pattern contain the tags that replace the match and text. A
star in the pattern is replaced by the text matched by the corresponding star
in the match pattern. If the star is in a tag otion, set the option to 
the value in the corresponding option in the match pattern. Any other text is 
put in the output verbatim. Patterns can be grouped inside parentheses. The 
pattern will be copied as many times as were matched in the correpsonding set 
of parentheses in the match pattern.

The format is probably best explained by example:

    # Replace strong tags by bold
    <strong>*</strong> -> <b>*</b>
    # Replace center tags
    <center>*</center> -> <div class="centered">*</div>
    # Remove font tags
    <font>*</font> -> *
    # Remove style tag and its content (empty replacement)
    <style>*</style> ->
    # Replace div tags with p tags, keep class
    <div class=*>*</div> -> <p class=*>*</p>
    # Replace list with breaks
    <ul>(<li>*</li>)</ul> -> (*<br>)
    # Remove page numbering (empty replacement)
    <p>^\d+$</p> ->

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut