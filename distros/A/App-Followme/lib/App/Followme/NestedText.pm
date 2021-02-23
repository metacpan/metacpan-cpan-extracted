package App::Followme::NestedText;

use 5.008005;
use strict;
use warnings;
use integer;
use lib '../..';

our $VERSION = "1.98";

use App::Followme::FIO;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(nt_parse_almost_yaml_file nt_parse_almost_xml_file
                 nt_parse_almost_yaml_string nt_parse_almost_xml_string
                 nt_write_almost_yaml_file nt_write_almost_xml_file
                 nt_merge_items);

#----------------------------------------------------------------------
# Merge items from two nested lists

sub nt_merge_items {
    my ($old_config, $new_config) = @_;

    my $final_config;
    my $ref = ref $old_config;

    if ($ref eq ref $new_config) {
        if ($ref eq 'ARRAY') {
            $final_config = [];
            @$final_config = @$old_config;
            my %old = map {$_ => 1} @$old_config;

            foreach my $item (@$new_config) {
                push(@$final_config, $item) unless $old{$item};    
            }

        } elsif ($ref eq 'HASH') {
            $final_config = {};
            %$final_config = %$old_config;

            foreach my $name (keys %$new_config) {
                if (exists $old_config->{$name}) {
                    $final_config->{$name} = nt_merge_items($old_config->{$name},
                                                            $new_config->{$name});
                } else {
                    $final_config->{$name} = $new_config->{$name};
                }
            }

        } else {
            $final_config = $new_config;
        }

    } else {
        $final_config = $new_config;
    }

    return $final_config;
}

#----------------------------------------------------------------------
# Read file in "almost yaml" format

sub nt_parse_almost_yaml_file {
	my ($filename) = @_;

	my %configuration;
	my $page = fio_read_page($filename);

	eval {%configuration = nt_parse_almost_yaml_string($page)};
	die "$filename: $@" if $@;

	return %configuration;
}

#----------------------------------------------------------------------
# Read file in "almost xml" format

sub nt_parse_almost_xml_file {
	my ($filename) = @_;

	my %rss;
	my $page = fio_read_page($filename);

	eval {%rss = nt_parse_almost_xml_string($page)};
	die "$filename: $@" if $@;

	return %rss;
}

#----------------------------------------------------------------------
# Read string in "almost yaml" Format

sub nt_parse_almost_yaml_string {
	my ($page) = @_;

	my @lines = split(/\n/, $page);
	my $block = parse_almost_yaml_block(\@lines);
	
	if (@lines) {
		my $msg = trim_string(shift(@lines));
		die("Bad indent at $msg\n");
	}

	if (ref($block) ne 'HASH') {
		die("Configuration must be a hash\n");
	}

	return %$block;
}

#----------------------------------------------------------------------
# Read string in "almost xml" Format

sub nt_parse_almost_xml_string {
	my ($page) = @_;

	my @tokens = split(/(<[^>]*>)/, $page);
	my ($block, $blockname) = parse_almost_xml_block(\@tokens);
    die "Unexpected closing tag at </$blockname>\n" if $blockname;

	return %$block;
}

#----------------------------------------------------------------------
# Write file in "almost yaml" Format

sub nt_write_almost_yaml_file {
	my ($filename, %configuration) = @_;

	my ($type, $page) = format_almost_yaml_value(\%configuration);
    $page .= "\n";

	fio_write_page($filename, $page);
	return;
}

#----------------------------------------------------------------------
# Write file in "almost xml" Format

sub nt_write_almost_xml_file {
    my ($filename, %rss) = @_;

    my $page = "<?xml version=\"1.0\"?>\n";
    $page .= format_almost_xml_value(\%rss);
    $page .= "\n";

	fio_write_page($filename, $page);
    return;
}

#----------------------------------------------------------------------
# Format a value as a yaml string for writing

sub format_almost_yaml_value {
	my ($value, $level) = @_;
	$level = 0 unless defined $level;

	my $text;
    my $type = ref $value;
	my $leading = ' ' x (4 * $level);
	if ($type eq 'ARRAY') {
		my @subtext;
		foreach my $subvalue (@$value) {
			my ($subtype, $subtext) = format_almost_yaml_value($subvalue, $level+1);
			if ($subtype) {
				$subtext = $leading . "-\n" . $subtext;
			} else {
				$subtext = $leading . "- " . $subtext;
			}
			push (@subtext, $subtext);
		} 
		$text = join("\n", @subtext);

	} elsif ($type eq 'HASH') {
		my @subtext;
		foreach my $name (sort keys %$value) {
			my $subvalue = $value->{$name};
			my ($subtype, $subtext) = format_almost_yaml_value($subvalue, $level+1);
			if ($subtype) {
				$subtext = $leading . "$name:\n" . $subtext;
			} else {
				$subtext = $leading . "$name: " . $subtext;
			}
			push (@subtext, $subtext);
		} 
		$text = join("\n", @subtext);

	} elsif (length($value) > 60) {
        $type = 'SCALAR';
		my @subtext = split(/(\S.{0,59}\S*)/, $value);
		@subtext = grep( /\S/, @subtext);
		@subtext = map("$leading> $_", @subtext);
		$text = join("\n", @subtext);
		
	} else {
		$text = $value;
	}

	return ($type, $text);
}

#----------------------------------------------------------------------
# Format a value as an xml string for writing

sub format_almost_xml_value {
	my ($value, $name, $level) = @_;
    $name = '' unless defined $name;
    $level = 0 unless defined $level;

	my $text;
    my $type = ref $value;
	my $leading = ' ' x (4 * $level);
    my ($shortname) = split(/ /, $name);

	if ($type eq 'ARRAY') {
		my @subtext;
		foreach my $subvalue (@$value) {
			my $subtext = format_almost_xml_value($subvalue, $name, $level);
            push (@subtext, $subtext);
		} 
		$text = join("\n", @subtext);

	} elsif ($type eq 'HASH') {
		my @subtext;
        $level += 1 if length $name;
        push(@subtext, "$leading<$name>") if length $name;
		foreach my $subname (sort_xml_hash($value)) {
			my $subvalue = $value->{$subname};
			my $subtext = format_almost_xml_value($subvalue, $subname, $level);
			push (@subtext, $subtext);
		} 
        push(@subtext, "$leading</$shortname>") if length $name; 
		$text = join("\n", @subtext);
		
	} else {
        $text = length $name ? "$leading<$name>$value</$shortname>" 
                             : $leading . $value; 
	}

	return $text;
}

#----------------------------------------------------------------------
# Parse a block of "almost yaml" lines at the same indentation level

sub parse_almost_yaml_block {
	my ($lines) = @_;

	my @block;
	my ($first_indent, $first_type);

	while (@$lines) {
		my $line = shift(@$lines);
		my ($indent, $value) = parse_almost_yaml_line($line);
		next unless defined $indent;

		if (! defined $first_indent) {
			$first_indent = $indent;
			$first_type = ref($value);
		}
		
		if ($indent == $first_indent) {
			my $type = ref($value);

			if ($type ne $first_type) {
				my $msg = trim_string($line);
				die("Missing indent at $msg\n");
			}

			if ($type eq 'ARRAY') {
				push(@block, @$value);
			} elsif ($type eq 'HASH') {
				push(@block, %$value);
			} else {
				push(@block, $value);
			}

		} elsif ($indent > $first_indent) {
			if ($first_type ne 'ARRAY' &&
			    $first_type ne 'HASH') {
				my $msg = trim_string($line);
				die("Indent under string at $msg\n");
			}

			if (length($block[-1])) {
				my $msg = trim_string($line);
				die("Duplicate value at $msg\n");
							
			}

			unshift(@$lines, $line);
			$block[-1] = parse_almost_yaml_block($lines);

		} elsif ($indent < $first_indent) {
			unshift(@$lines, $line);				
			last;	
		}
	}

	my $block;
	if (! defined $first_type) {
		$block = {};
	} elsif ($first_type eq 'ARRAY') {
		$block = \@block;
	} elsif ($first_type eq 'HASH') {
		my %block = @block;
		$block = \%block;
	} else {
		$block = join(' ', @block);
	}
	
	return $block;
}

#----------------------------------------------------------------------
# Parse a pair of xml tags and their contents

sub parse_almost_xml_block {
	my ($tokens) = @_;

	my $value;
	while (@$tokens) {
		my $token = shift(@$tokens);
        next if $token !~ /\S/ || $token =~ /^<\?/;

        if ($token =~ /^<\s*\/\s*([^\s>]+)/) {
            my $ending_tagname = $1;
            $value = '' unless defined $value;
    	    return ($value, $ending_tagname);

		} elsif ($token =~ /^<\s*([^\s>]+)/) {
            my $starting_tagname = $1;
            my ($subvalue, $ending_tagname) = parse_almost_xml_block($tokens);
            die "Mismatched tags at $token\n" if $starting_tagname ne $ending_tagname;

            $value = {} unless defined $value;
            die "Unexpected text at $token\n" unless ref $value eq 'HASH';

            if (exists $value->{$starting_tagname}) {
                my $old_value =  $value->{$starting_tagname};

                if (ref $old_value eq 'ARRAY') {
                    push(@$old_value, $subvalue);
                } else {
                    $value->{$starting_tagname} = [$old_value, $subvalue];
                }
                
            } else {
                $value->{$starting_tagname} = $subvalue;
            }

        } else {
            die "Unexpected text at \"$token\"\n" if defined $value;
            $value = trim_string($token);
        }
	}
	
    $value = '' unless defined $value;
    return ($value, '');
}

#----------------------------------------------------------------------
# Parse a single line of "almost yaml" to get its indentation and value

sub parse_almost_yaml_line {
	my ($line) = @_;
    
    $line =~ s/\t/    /g;
	$line .= ' ';

	my ($indent, $value);
	if ($line !~ /^\s*#/ && $line =~ /\S/) {
		my $spaces;
		if ($line =~ /^(\s*)> (.*)/) {
			$spaces = $1;
			$value = trim_string($2);
		} elsif ($line =~ /^(\s*)- (.*)/) {
			$spaces = $1;
			$value = [trim_string($2)];
		} elsif ($line =~ /^(\s*)(\S+): (.*)/) {
			$spaces = $1;
			$value = {$2 => trim_string($3)};
		} else {
			my $msg = trim_string($line);
			die "Bad tag at $msg\n";
		}

		$indent = defined($spaces) ? length($spaces) : 0;
	} 
	
	return ($indent, $value);
}

#----------------------------------------------------------------------
# Sort the keys of an xml hash so that scalars are listed first

sub sort_xml_hash {
    my ($hash) = @_;

    my @augmented_keys = map {[ref $hash->{$_}, $_]} keys %$hash;
    @augmented_keys = sort {$a->[0] cmp $b->[0] || $a->[1] cmp $b->[1]} @augmented_keys;
    my @keys = map {$_->[1]} @augmented_keys;

    return @keys;
}

#----------------------------------------------------------------------
# Compress whitespace and remove leading and trailing space from string

sub trim_string {
	my ($str) = @_;
	return '' unless defined $str;

    $str =~ s/[ \t\n]+/ /g;	
	$str =~ s/^\s//;
	$str =~ s/\s$//;

	return $str;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Followme::NestedText - Read a file or string using a subset of yaml or xml

=head1 SYNOPSIS

	use App::Followme::NestedText
    my %config = nt_parse_almost_yaml_file($filename);
    %config = nt_parse_almost_yaml_string($str);
	nt_write_almost_yaml_file($filename, %config);

    my %rss = nt_parse_almost_xml_file($filename);
    %rss = nt_parse_almost_xml_string($str);
	nt_write_almost_xml_file($filename, %rss);

=head1 DESCRIPTION

This module reads configuration data from either a file or string. The data
is a hash whose values are strings, arrays, or other hashes. Because of the
loose typing of Perl, numbers can be represted as strings. It supports two
formats. The first is a subset of yaml, called "almost yaml."  This format
is used to read the configuration files and metadata text files that are
oing to be converted to web pages. In this format a hash is a list of name 
value pairs separated by a colon and a space:

    name1: value1
    name2: value2
    name3: value3

In the above example all the values are short strings and fit on a line.
Longer values can be split across several lines by starting each line
sith a greater than sign and space indented beneath the name:

    name1: value1
    name2:
        > A longer value
        > split across lines
        > however many you need
        > for your application.
    name3: value3

The lines are joined with spaces into a single string.

Array values are formatted one element per line with each line indented 
beneath the name starting with a dash and space

    name1: value1
	array_name: 
	    - subvalue1
        - subvalue2
        - subvalue3

Hash values are indented from the field containg them, each field in
the hash on a separate line.

    name1: value1
    hash_name:
        subname1: subvalue1
        subname2: subvalue2
        subname3: subvalue3

Hashes, arrays, and strings can be nested to any depth, but the top level
must be a hash. Values may contain any character except a newline. Quotes
are not needed around values. Leading and trailing spaces are trimmed
from values, interior spaces are unchanged. Values can be the empty 
string. Names can contain any non-whitespace character. The amount of 
indentation is arbitrary, but must  be consistent for all values in a 
string, array, or hash. The three special characters which indicate the
field type (:, -, and > ) must be followed by at least one space unless 
they are the last character on the line.

The other format is a subset of xml, called "almost xml." This format is 
used for rss files. In this format a hash is represented by a sequence of
values enclosed by tags in angle brackets. The tag names in the angle 
brackets are the hash field names.

    <title>Liftoff News</title>
    <link>http://liftoff.msfc.nasa.gov/</link>
    <description>Liftoff to Space Exploration.</description>
    <language>en-us</language>

if a tag name is repeated the values in those tags are treated as an array:

    <item>first</item>
    <item>second</item>
    <item>third</item>

A hash can also be contained in a value by placing a list of tags within 
another pair of tags:

    <item>
        <title>The Engine That Does More</title>
        <link>http://liftoff.msfc.nasa.gov/news/2003/news-VASIMR.asp</link>
    </item>
    <item>
        <title>Astronauts' Dirty Laundry</title>
        <link>http://liftoff.msfc.nasa.gov/news/2003/news-laundry.asp</link>
    </item>

Indentation is nice for anyone looking at the file, but is not required by 
the format.

=head1 SUBROUTINES

The following subroutines can be use to read nested text. Subroutine
names are exported when you use this module.

=over 4

=item my %config = nt_parse_almost_yaml_file($filename);

Load a configuration from an almost yaml  file into a hash.

=item my %config = nt_parse_almost_yaml_string($string);

Load a configuration from an almost yaml  string into a hash.

=item nt_write_almost_yaml_file($filename, %config);

Write a configuration back to an almost yaml file

=item my %rss = nt_parse_almost_xml_file($filename);

Load a rss file into a hash.

=item my %rss = nt_parse_almost_xml_string($string);

Load a rss file from a string into a hash.

=item nt_write_almost_xml_file($filename, %rss);

Write rss back to an almost xml file

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
