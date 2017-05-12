package C::Utility;
use warnings;
use strict;
use File::Spec;
use Carp;
use File::Versions 'make_backup';

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw/
		   add_lines
		   brute_force_line
		   c_string
		   c_to_h_name
		   ch_files
		   convert_to_c_string
		   convert_to_c_string_pc
		   escape_string
		   hash_to_c_file
		   line_directive
		   linein 
		   lineout
		   print_bottom_h_wrapper
		   print_top_h_wrapper
		   remove_quotes
		   stamp_file
		   valid_c_variable
               /;

our %EXPORT_TAGS = (
    'all' => \@EXPORT_OK,
);

our $VERSION = '0.006';

sub convert_to_c_string
{
    my ($text) = @_;
    if (length ($text) == 0) {
        return "\"\"";
    }
    # Convert backslashes to double backslashes.
    $text =~ s/\\/\\\\/g;
    # Escape double quotes
    $text = escape_string ($text);
    # If there was a backslash before a quote, as in \", the first
    # regex above converted it to \\", and then escape_string
    # converted that to \\\".
    $text =~ s/\\\\"/\\"/g;
    # Remove backslashes from before the @ symbol.
    $text =~ s/\\\@/@/g;
    # Turn each line into a string
    $text =~ s/(.*)\n/"$1\\n"\n/gm;
    # Catch a final line without any \n at its end.
    if ($text !~ /\\n\"$/) {
	$text =~ s/(.+)$/"$1"/g;
    }
    return $text;
}

sub c_string
{
    goto & convert_to_c_string;
}

sub ch_files
{
    my ($c_file_name) = @_;
    if ($c_file_name !~ /\.c/) {
       die "$c_file_name is not a C file name";
    }
    my $h_file_name = $c_file_name;
    $h_file_name =~ s/\.c$/\.h/;
    if (-f $c_file_name) {
	make_backup ($c_file_name);
    }
    if (-f $h_file_name) {
	make_backup ($h_file_name);
    }
    return $h_file_name;
}

sub convert_to_c_string_pc
{
    my ($text) = @_;
    $text =~ s/%/%%/g;
    return convert_to_c_string ($text);
}

sub escape_string
{
    my ($text) = @_;
    $text =~ s/\"/\\\"/g;
    return $text;
}

sub c_to_h_name
{
    my ($c_file_name) = @_;
    if ($c_file_name !~ /\.c/) {
	die "$c_file_name is not a C file name";
    }
    my $h_file_name = $c_file_name;
    $h_file_name =~ s/\.c$/\.h/;
    return $h_file_name;
}

# This list of reserved words in C is from
# http://crasseux.com/books/ctutorial/Reserved-words-in-C.html

my @reserved_words = sort {length $b <=> length $a} qw/auto if break
int case long char register continue return default short do sizeof
double static else struct entry switch extern typedef float union for
unsigned goto while enum void const signed volatile/;

# A regular expression to match reserved words in C.

my $reserved_words_re = join '|', @reserved_words;

sub valid_c_variable
{
    my ($variable_name) = @_;
    if ($variable_name !~ /^[A-Za-z_][A-Za-z_0-9]+$/ ||
	$variable_name =~ /^(?:$reserved_words_re)$/) {
	return;
    }
    return 1;
}

# Wrapper name
# BKB 2009-10-05 14:09:41

sub wrapper_name
{
    my ($string) = @_;
    $string =~ s/[.-]/_/g;
    if (! valid_c_variable ($string)) {
        croak "Bad string for wrapper '$string'";
    }
    my $wrapper_name = uc $string;
    return $wrapper_name;
}

sub print_top_h_wrapper
{
    my ($fh, $file_name) = @_;
    
    my $wrapper_name = wrapper_name ($file_name);
    my $wrapper = <<EOF;
#ifndef $wrapper_name
#define $wrapper_name
EOF
    print_out ($fh, $wrapper);
}

sub print_out
{
    my ($fh, $wrapper) = @_;
    if (ref $fh && ref $fh eq 'SCALAR') {
        ${$fh} .= $wrapper;
    }
    else {
        print $fh $wrapper;
    }
}

sub print_bottom_h_wrapper
{
    my ($fh, $file_name) = @_;
    my $wrapper_name = wrapper_name ($file_name);
    my $wrapper = <<EOF;
#endif /* $wrapper_name */
EOF
    print_out ($fh, $wrapper);
}

sub print_include
{
    my ($fh, $h_file_name) = @_;
    print $fh <<EOF;
#include "$h_file_name"
EOF
}

sub hash_to_c_file
{
    # $prefix is an optional prefix applied to all variables.
    my ($c_file_name, $hash_ref, $prefix) = @_;
    my $h_file_name = ch_files ($c_file_name);
    die "Not a hash ref" unless ref $hash_ref eq "HASH";
    $prefix = "" unless $prefix;
    open my $c_out, ">:utf8", $c_file_name or die $!;
    my (undef, undef, $h_file) = File::Spec->splitpath ($h_file_name);
    print_include ($c_out, $h_file);
    open my $h_out, ">:utf8", $h_file_name or die $!;
    print_top_h_wrapper ($h_out, $h_file);
    for my $variable (sort keys %$hash_ref) {
	if (! valid_c_variable ($variable)) {
	    croak "key '$variable' is not a valid C variable";
	}
	my $value = $hash_ref->{$variable};
	$value = convert_to_c_string ($value);
	print $c_out "const char * $prefix$variable = $value;\n";
	print $h_out "extern const char * $prefix$variable; /* $value */\n";
    }
    close $c_out or die $!;
    print_bottom_h_wrapper ($h_out, $h_file);
    close $h_out or die $!;
    return $h_file_name;
}

sub line_directive
{
    my ($output, $line_number, $file_name) = @_;
    die "$line_number is not a positive integer number"
	unless $line_number =~ /^[0-9]+$/ && $line_number > 0;
    print_out ($output, "#line $line_number \"$file_name\"\n");
}

sub brute_force_line
{
    my ($input_file, $output_file) = @_;
    open my $input, "<:encoding(utf8)", $input_file or die $!;
    open my $output, ">:encoding(utf8)", $output_file or die $!;
    while (<$input>) {
        print $output "#line $. \"$input_file\"\n";
        print $output $_;
    }
    close $input or die $!;
    close $output or die $!;
}

sub add_lines
{
    my ($input_file) = @_;
    my $full_name = File::Spec->rel2abs ($input_file);
    my $text = '';
    open my $input, "<:encoding(utf8)", $input_file or die $!;
    while (<$input>) {
        if (/^#line/) {
            my $line_no = $. + 1;
            $text .= "#line $line_no \"$full_name\"\n";
        }
        elsif ($. == 1) {
            $text .= "#line 1 \"$full_name\"\n";
            $text .= $_;
        }
        else {
            $text .= $_;
        }
    }
    return $text;
}

sub remove_quotes
{
    my ($string) = @_;
    $string =~ s/^"|"$|"\s*"//g;
    return $string;
}

sub linein
{
    my ($infile) = @_;
    my $intext = '';
    open my $in, "<:encoding(utf8)", $infile or die "Can't open $infile: $!";
    while (<$in>) {
	if (/#linein/) {
	    my $line = $. + 1;
	    s/#linein/#line $line "$infile"/;
	}
	$intext .= $_;
    }
    close $in or die $!;
    return $intext;
}

sub lineout
{
    my ($outtext, $outfile) = @_;

    my @outlines = split /\n/, $outtext;
    open my $out, ">:encoding(utf8)", $outfile or die $!;
    for (my $i = 0; $i <= $#outlines; $i++) {
	if ($outlines[$i] =~ /#lineout/) {
	    my $line = $i + 1;
	    print $out "#line $line \"$outfile\"\n";
	}
	else {
	    print $out $outlines[$i], "\n";
	}
    }
    close $out or die $!;
}

sub stamp_file
{
    my ($fh, $name) = @_;
    if (! defined $name) {
	$name = "This C file";
    }
    my $now = scalar localtime ();
    my $stamp =<<EOF;
/*
$name was generated by $0 at $now.
*/
EOF
    print_out ($fh, $stamp);
}


1;
