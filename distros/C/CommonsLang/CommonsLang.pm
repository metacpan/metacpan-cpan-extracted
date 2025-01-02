package CommonsLang;

=head1 NAME

CommonsLang - Commonly used functions for Perl language

=head1 SYNOPSIS
use CommonsLang;

print s_pad("a", 5, "0") . "\n";
# > "a0000"

print s_left("abc", 1) . "\n";
# > "a"

print s_right("abc", 1) . "\n";
# > "c"

print s_starts_with("abc", "ab") . "\n";
# > 1

print s_ends_with("abc", "bc") . "\n";
# > 1

=head1 DESCRIPTION

  * v_type_of - returns a string indicating the type of the variable.
  * v_cmp - compare function, usually it is used for sort.
  * v_max - returns the largest of the element given as input parameters, or undef if there are no parameters.
  * v_min - returns the smallest of the numbers given as input parameters, or undef if there are no parameters.
  * s_match_glob - check if a string matches a glob pattern.
  * s_left - returns a string containing a specified number of characters from the left side of a string.
  * s_right - returns a string containing a specified number of characters from the right side of a string.
  * s_starts_with - check whether the string begins with the characters of a specified string, returning 1 or 0 as appropriate.
  * s_ends_with - check whether the string ends with the characters of a specified string, returning 1 or 0 as appropriate.
  * s_pad - string padding.
  * s_trim - a new string representing str stripped of whitespace from both its beginning and end. Whitespace is defined as /\s/.
  * s_ellipsis - truncate the string to the specified length and add ellipsis "..." at the end of the string to indicate that the string has been truncated.
  * s_split - takes a pattern and divides this string into an ordered list of substrings by searching for the pattern, puts these substrings into an array, and returns the array.
  * a_splice - changes the contents of an array by removing or replacing existing elements and/or adding new elements in place.
  * a_slice - returns a shallow copy of a portion of an array into a new array
  * a_left - returns an array containing a specified number of elements from the left side of an array.
  * a_right - returns an array containing a specified number of elements from the right side of an array.
  * a_push - adds the specified elements to the end of an array and returns the new length of the array.
  * a_pop - removes the last element from an array and returns that element. This method changes the length of the array.
  * a_shift - removes the first element from an array and returns that removed element. This method changes the length of the array.
  * a_unshift - adds the specified elements to the beginning of an array and returns the new length of the array.
  * a_filter - creates a shallow copy of a portion of a given array, filtered down to just the elements from the given array that pass the test implemented by the provided function.
  * a_sort - returns a sorted array by callbackFn. The original array will not be modified.
  * a_concat - merge two or more arrays. This method does not change the existing arrays, but instead returns a new array.
  * a_find_index - returns the index of the first element in an array that satisfies the provided testing function. If no elements satisfy the testing function, -1 is returned.
  * a_find_last_index - iterates the array in reverse order and returns the index of the first element that satisfies the provided testing function.  If no elements satisfy the testing function, -1 is returned.
  * a_find - returns the first element in the provided array that satisfies the provided testing function. If no values satisfy the testing function, undef is returned.
  * a_find_last - iterates the array in reverse order and returns the index of the first element that satisfies the provided testing function. If no elements satisfy the testing function, -1 is returned.
  * a_index_of - returns the first index at which a given element can be found in the array, or -1 if it is not present.
  * a_last_index_of - returns the first index at which a given element can be found in the array, or -1 if it is not present.
  * a_every - tests whether all elements in the array pass the test implemented by the provided function. It returns 1 or 0. It doesn't modify the array.
  * a_some - tests whether at least one element in the array passes the test implemented by the provided function. It returns 1 if, in the array, it finds an element for which the provided function returns 1; otherwise it returns 0. It doesn't modify the array.
  * a_map - creates a new array populated with the results of calling a provided function on every element in the calling array.
  * a_reduce - executes a user-supplied "reducer" callback function on each element of the array, in order, passing in the return value from the calculation on the preceding element. The final result of running the reducer across all elements of the array is a single value.
  * a_join - creates and returns a new string by concatenating all of the elements in this array, separated by commas or a specified separator string.
  * h_keys - returns an array of a given hash's own enumerable names.
  * h_values - returns an array of a given hash's own enumerable values.
  * h_find - returns the k-v tuple in the provided hash that satisfies the provided testing function. If no values satisfy the testing function, undef is returned.
  * h_group_by - groups the elements of a given iterable according to the string values returned by a provided callback function.
  * h_assign - Copies all key/value from one or more source objects to a target object.
  * x_now_ts - get formated timestamp(YYYY-mm-ddTHH:MM:SS.SSS).
  * x_now_ms - get current timestamp.
  * x_log - print with the line number and subroutine name of caller to STDOUT.
  * x_debug - print with the line number and subroutine name of caller to STDOUT for debug.
  * x_error - print with the line number and subroutine name of caller to STDERR.
  * x_stack - print the call stack to STDERR.
  * x_fatal - print the error, and exit the perl process with code 1.

=head1 AUTHOR

YUPEN 12/23/24 - new

=cut

our $VERSION = 0.02;

use Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = (
    v_type_of,     v_cmp,
    v_max,         v_min,
    s_match_glob,  s_left, s_right,
    s_starts_with, s_ends_with,
    s_pad,         s_trim,
    s_ellipsis,    s_split,
    a_splice,      a_slice,
    a_left,        a_right,
    a_push,        a_pop,
    a_shift,       a_unshift,
    a_filter,      a_sort, a_concat,
    a_find_index,  a_find_last_index,
    a_find,        a_find_last,
    a_index_of,    a_last_index_of,
    a_every,       a_some,
    a_map,         a_reduce, a_join,
    h_keys,        h_values, h_find, h_group_by, h_assign,
    x_now_ts,      x_now_ms,
    x_log,         x_debug, x_error, x_stack, x_fatal
);
@EXPORT = @EXPORT_OK;

use strict;
use Data::Dumper;
use Carp 'croak';
use POSIX qw(floor ceil);

use Env;
use Time::HiRes;
use File::Basename;
use Time::Piece;

########################################
########################################
########################################

##################
# Subroutine : x_now_ms
# Purpose    : get current timestamp
sub x_now_ms {
    return int(Time::HiRes::time * 1000);
}

##################
# Subroutine : x_now_ts
# Purpose    : get formated timestamp(YYYY-mm-ddTHH:MM:SS.SSS)
sub x_now_ts {
    my $t  = localtime();
    my $ms = int(x_now_ms() % 1000);
    return $t->strftime("%Y-%m-%dT%H:%M:%S") . "." . sprintf("%03d", $ms);
}

##################
sub i_log {
    my $dest  = shift;
    my $level = shift;

    # locate the call info
    my ($package, $filename, $lineno) = caller(1);
    my @next_caller_info = caller(2);
    my $next_subroutine  = @next_caller_info ? $next_caller_info[3] : "::";
    ##
    my ($pkg_name, $sub_name) = split("::", $next_subroutine);
    my ($basename, $dirname)  = fileparse($filename);
    #
    my $now_ts = x_now_ts();
    ## print the msg string line by line
    my $joined_str = join("", @_);
    my @lines      = split(/\r?\n/, $joined_str);
    foreach my $line (@lines) {
        my $msg =
          (     "["
              . $now_ts . "] "
              . $basename . ":"
              . sprintf("%4d",   $lineno) . ":"
              . sprintf("%-20s", $sub_name) . " - "
              . $level . ": "
              . $line
              . "\n");

        # https://www.perlmonks.org/?node_id=791373
        # sub print_to {
        #     print {$_[0]} $_[1];
        # }
        # print_to (*STDOUT, "test stdout");
        # print_to (*STDERR, "test stderr");
        print {$dest} $msg;
    }
}

##################
# Subroutine : x_log
# Purpose    : print with the line number and subroutine name of caller to STDOUT.
sub x_log {
    i_log(*STDOUT, "LOG", @_);
}

##################
# Subroutine : x_debug
# Purpose    : print with the line number and subroutine name of caller to STDOUT for debug
sub x_debug {
    i_log(*STDOUT, "DEBUG", @_);
}

##################
# Subroutine : x_error
# Purpose    : print with the line number and subroutine name of caller to STDERR
sub x_error {
    i_log(*STDERR, "ERROR", @_);
}

##################
# Subroutine : x_stack
# Purpose    : print the call stack to STDERR.
sub x_stack {
    my $capture = shift;
    ##
    my $output = [];
    my $level  = 0;
    my @info   = caller($level++);
    while (@info) {
        my $prefix = "  " x ($level - 1);
        my ($package, $filename, $lineno) = @info;
        my ($basename) = fileparse($filename);
        @info = caller($level++);
        if (@info) {
            my ($pkg_name, $sub_name) = split("::", $info[3]);
            my $msg = "$prefix$basename:$lineno" . ($sub_name ? ", subroutine: $sub_name" : "");
            if ($capture) {
                push(@$output, $msg);
            }
            else {
                i_log(*STDERR, "STACK", $msg);
            }
        }
    }
    return $output;
}

##################
# Subroutine : x_fatal
# Purpose    : print the error, and exit the perl process with code 1.
sub x_fatal {
    i_log(*STDERR, "FATAL", @_);
    exit(1);
}

########################################
######################################## (scalar)variable
########################################

##################
# Subroutine : v_type_of
# Purpose    : The v_type_of method returns a string indicating the type of the variable.
# Input      : var
# Returns    : string of (UNDEF, ARRAY, HASH, CODE, ..., STRING, NUMBER)
sub v_type_of {
    my $var = shift;
    if (!defined($var)) {
        return "UNDEF";
    }
    my $ref_type = ref($var);
    if ($ref_type ne "") {
        return uc($ref_type);
    }
    else {
        if ($var eq "") {
            return "STRING";
        }
        else {
            my $scalar_type = ($var ^ $var) ? "STRING" : "NUMBER";
            return $scalar_type;
        }
    }
}

##################
# Subroutine : v_cmp
# Purpose    : compare function, usually it is used for sort.
# Input      : x, y
# Returns    : > 0: x after y, < 0: x before y, = 0: they are equals
sub v_cmp {
    my ($x, $y) = @_;

    if (!defined($x) and !defined($y)) {
        return 0;
    }
    elsif (!defined($x) and defined($y)) {
        return -1;
    }
    elsif (defined($x) and !defined($y)) {  ## undef first
        return 1;
    }
    else {
        my $tx = v_type_of($x);
        my $ty = v_type_of($y);
        if ($tx eq $ty) {
            if ($tx eq "NUMBER") {  # https://www.tutorialspoint.com/perl/perl_operators.htm
                return $x <=> $y;
            }
            elsif ($tx eq "STRING") {
                return $x cmp $y;
            }
            elsif ($tx eq "UNDEF") {
                return 0;
            }
            else {
                # https://stackoverflow.com/questions/37220558/how-can-i-check-for-reference-equality-in-perl
                if ($x == $y) {  # check if there are same references
                    return 0;
                }
                else {
                    # -1, only mean they are not same.
                    # return -1;
                    # if ($tx eq "ARRAY") {
                    #     my $a_size = scalar @$x;
                    #     my $b_size = scalar @$y;
                    #     return $a_size <=> $b_size;
                    # } elsif ($tx eq "HASH") {
                    #     my $a_size = scalar keys %$x;
                    #     my $b_size = scalar keys %$y;
                    #     return $a_size <=> $b_size;
                    # } else {
                    #     # not able to compare.
                    #     # die "Since they are different type of variables, not able to compare. type of x is $tx, type of y is $ty";
                    #     return -1;
                    # }
                    # die "Not able to compare. type of x & y is $tx.";
                    die "Not able to compare.";
                }
            }
        }
        else {
            ## undef first
            if ($tx eq "UNDEF" and $ty ne "UNDEF") {
                return -1;
            }
            if ($tx ne "UNDEF" and $ty eq "UNDEF") {
                return 1;
            }
            ##################
            if ($tx eq "NUMBER" and $ty eq "STRING") {
                return $x <=> $y;
            }
            if ($tx eq "STRING" and $ty eq "NUMBER") {
                return $x cmp $y;
            }
            #######
            # die "Since they are different type of variables, not able to compare. type of x is $tx, type of y is $ty";
            my $stack = x_stack(1);
            unshift(@$stack, "Not able to compare. type of x is $tx, type of y is $ty.");
            die join("\n", @$stack);
        }
    }
}

##################
# Subroutine : v_max
# Purpose    : returns the largest of the element given as input parameters, or undef if there are no parameters.
# Input      : array
# Returns    : returns the largest element
sub v_max {
    my $the_one  = undef;
    my $cmp_func = \&v_cmp;
    my $idx      = 0;
    foreach my $x (@_) {
        if ($idx == 0 and v_type_of($x) eq "CODE") {
            $cmp_func = $x;
        }
        else {
            if ($idx == 0) {
                $the_one = $x;
            }
            else {
                if ($cmp_func->($the_one, $x) <= 0) {
                    $the_one = $x;
                }
            }
            $idx = $idx + 1;
        }
    }
    return $the_one;
}

##################
# Subroutine : v_min
# Purpose    : returns the smallest of the numbers given as input parameters, or undef if there are no parameters.
# Input      : array
# Returns    : returns the smallest element
sub v_min {
    my $the_one  = undef;
    my $cmp_func = \&v_cmp;
    my $idx      = 0;
    foreach my $x (@_) {
        if ($idx == 0 and v_type_of($x) eq "CODE") {
            $cmp_func = $x;
        }
        else {
            if ($idx == 0) {
                $the_one = $x;
            }
            else {
                if ($cmp_func->($the_one, $x) >= 0) {
                    $the_one = $x;
                }
            }
            $idx = $idx + 1;
        }
    }
    return $the_one;
}

########################################
######################################## string
########################################

##################
# Subroutine : s_pad
# Purpose    : String padding.
# Input      : 1. text
#              2. width - can be undef or -1 if you supply multiple texts, in which case the width will be determined from the longest text.
#              3. which(optional) - is either "r" or "right" for padding on the right (the default if not specified),
#                         "l" or "left" for padding on the right, or "c" or "center" or "centre" for left+right padding to center the text.
#                         Note that "r" will mean "left justified", while "l" will mean "right justified".
#              4. padchar(optional) - is whitespace if not specified. It should be string having the width of 1 column.
#              5. is_trunc(optional) - is boolean. When set to 1, then text will be truncated when it is longer than $width.
# Returns    : Return $text padded with $padchar to $width columns.
#              Can accept multiple texts (\@texts); in which case will return a new arrayref of padded texts.
sub s_pad {
    my ($text0, $width, $which, $padchar, $is_trunc) = @_;
    if ($which) {
        $which = substr($which, 0, 1);
    }
    else {
        $which = "r";
    }
    $padchar //= " ";

    my $texts = ref $text0 eq 'ARRAY' ? [@$text0] : [$text0];

    if (!defined($width) || $width < 0) {
        my $longest = 0;
        for (@$texts) {
            my $len = length($_);
            $longest = $len if $longest < $len;
        }
        $width = $longest;
    }

    for my $text (@$texts) {
        my $w = length($text);
        if ($is_trunc && $w > $width) {
            $text = substr($text, 0, $width, 1);
            $w    = $width;
        }
        else {
            if ($which eq 'l') {
                no warnings;  # negative repeat count
                $text = ($padchar x ($width - $w)) . $text;
            }
            elsif ($which eq 'c') {
                my $n = int(($width - $w) / 2);
                $text = ($padchar x $n) . $text . ($padchar x ($width - $w - $n));
            }
            else {
                no warnings;  # negative repeat count
                $text .= ($padchar x ($width - $w));
            }
        }
    }  # for $text

    return ref $text0 eq 'ARRAY' ? $texts : $texts->[0];
}

##################
# Subroutine : s_left
# Purpose    : Returns a string containing a specified number of characters from the left side of a string.
# Input      : 1. string
#              2. length -  a number indicating how many characters to return.
#                           If 0, a zero-length string ("") is returned.
#                           If greater than or equal to the number of characters in string, the entire string is returned.
# Returns    : string
sub s_left {
    my $str    = shift;
    my $length = shift;
    ###
    return "" if ($length <= 0);
    my $str_length = length($str);
    if ($length > $str_length) {
        return $str;
    }
    return substr($str, 0, $length);
}

##################
# Subroutine : s_starts_with
# Purpose    : Check whether the string begins with the characters of a specified string, returning 1 or 0 as appropriate.
# Input      : 1. string
#              2. string
# Returns    :
sub s_starts_with {
    my $str1 = shift;
    my $str2 = shift;
    my $len1 = length($str1);
    my $len2 = length($str2);
    if ($len1 < $len2) {
        return 0;
    }
    my $cutted = s_left($str1, $len2);
    if ($cutted eq $str2) {
        return 1;
    }
    return 0;
}

##################
# Subroutine : s_right
# Purpose    : Returns a string containing a specified number of characters from the right side of a string.
# Input      : 1. string
#              2. length -  a number indicating how many characters to return.
#                           If 0, a zero-length string ("") is returned.
#                           If greater than or equal to the number of characters in string, the entire string is returned.
# Returns    : string
sub s_right {
    my $str    = shift;
    my $length = shift;
    ###
    return "" if ($length <= 0);
    my $str_length = length($str);
    if ($length > $str_length) {
        return $str;
    }
    return substr($str, $str_length - $length, $length);
}

##################
# Subroutine : s_ends_with
# Purpose    : Check whether the string ends with the characters of a specified string, returning 1 or 0 as appropriate.
# Input      : 1. string
#              2. string
# Returns    :
sub s_ends_with {
    my $str1 = shift;
    my $str2 = shift;
    my $len1 = length($str1);
    my $len2 = length($str2);
    if ($len1 < $len2) {
        return 0;
    }
    my $cutted = s_right($str1, $len2);
    if ($cutted eq $str2) {
        return 1;
    }
    return 0;
}

##################
# Subroutine : s_trim
# Purpose    : A new string representing str stripped of whitespace from both its beginning and end.
#               Whitespace is defined as /\s/.
# Input      : 1. string
# Returns    : string
sub s_trim {
    my $str = shift;
    ###
    $str =~ s/^\s+|\s+$//g;
    return $str;
}

##################
# Subroutine : s_ellipsis
# Purpose    : truncate the string to the specified length and add ellipsis "..." at the end of the string to indicate that the string has been truncated.
# Input      : 1. string
#              2. width
#              3. align
#              4. padchar
# Returns    : string
sub s_ellipsis {
    my ($str, $width, $align, $padchar) = @_;
    $align = defined($align) ? $align : "l";
    $align = lc(substr($align, 0, 1));
    ##
    $padchar = defined($padchar) ? $padchar : " ";
    ##
    $str =~ s/\r?\n//g;
    ##
    my $length = length($str);
    #
    if ($length <= $width) {
        $str = s_pad($str, $width, ($align eq "r" ? "l" : "r"), $padchar);
    }
    else {
        if ($align eq "r") {
            $str = "..." . s_right($str, $width - 3);
        }
        elsif ($align eq "c") {
            my $m_odd     = $width % 2;
            my $m_mid_len = floor($width / 2);
            my $head_str  = s_left($str, $m_mid_len - 1);
            my $tail_str  = s_right($str, $m_mid_len - ($m_odd ? 1 : 2));
            $str = $head_str . "..." . $tail_str;
        }
        else {
            $str = s_left($str, $width - 3) . "...";
        }
    }

    return $str;
}

##################
# Subroutine : s_split
# Purpose    : takes a pattern and divides this string into an ordered list of substrings by searching for the pattern, puts these substrings into an array, and returns the array.
# Input      : 1. string
#              2. separator
# Returns    : array
sub s_split {
    my ($str, $sep) = @_;
    my @arr = split($sep, $str);
    return \@arr;
}

##################
# Subroutine : s_match_glob
# Purpose    : match globbing patterns against text
# Input      : 1. pattern
#              2. string to match
# Returns    : Returns the list of things which match the glob from the source list.
# Example    :
# ```
# print "matched\n" if s_match_glob( "foo.*", "foo.bar" );
# > matched
# ```
# Reference  : https://metacpan.org/pod/Text::Glob
sub s_match_glob {
    use constant debug                 => 0;
    use constant strict_leading_dot    => 0;
    use constant strict_wildcard_slash => 0;
    ###
    sub glob_to_regex_string {
        my $glob      = shift;
        my $seperator = quotemeta("/");
        my ($regex, $in_curlies, $escaping);
        local $_;
        my $first_byte = 1;
        for ($glob =~ m/(.)/gs) {
            if ($first_byte) {
                if (strict_leading_dot) {
                    $regex .= '(?=[^\.])' unless $_ eq '.';
                }
                $first_byte = 0;
            }
            if ($_ eq '/') {
                $first_byte = 1;
            }
            if (   $_ eq '.'
                || $_ eq '('
                || $_ eq ')'
                || $_ eq '|'
                || $_ eq '+'
                || $_ eq '^'
                || $_ eq '$'
                || $_ eq '@'
                || $_ eq '%') {
                $regex .= "\\$_";
            }
            elsif ($_ eq '*') {
                $regex .=
                    $escaping             ? "\\*"
                  : strict_wildcard_slash ? "(?:(?!$seperator).)*"
                  :                         ".*";
            }
            elsif ($_ eq '?') {
                $regex .=
                    $escaping             ? "\\?"
                  : strict_wildcard_slash ? "(?!$seperator)."
                  :                         ".";
            }
            elsif ($_ eq '{') {
                $regex .= $escaping ? "\\{" : "(";
                ++$in_curlies unless $escaping;
            }
            elsif ($_ eq '}' && $in_curlies) {
                $regex .= $escaping ? "}" : ")";
                --$in_curlies unless $escaping;
            }
            elsif ($_ eq ',' && $in_curlies) {
                $regex .= $escaping ? "," : "|";
            }
            elsif ($_ eq "\\") {
                if ($escaping) {
                    $regex .= "\\\\";
                    $escaping = 0;
                }
                else {
                    $escaping = 1;
                }
                next;
            }
            else {
                $regex .= $_;
                $escaping = 0;
            }
            $escaping = 0;
        }
        x_debug "# $glob $regex" if debug;

        return $regex;
    }

    sub glob_to_regex {
        my $glob  = shift;
        my $regex = glob_to_regex_string($glob);
        return qr/^$regex$/;
    }
    ###
    my ($glob, $str) = @_;
    my $regex   = glob_to_regex($glob);
    my $matched = $str =~ $regex;
    x_debug "$str =~ $regex = $matched " if debug;
    return $matched ? 1 : 0;
}

########################################
######################################## array
########################################

##################
# Subroutine : a_join
# Purpose    : creates and returns a new string by concatenating all of the elements in this array, separated by commas or a specified separator string.
#              If the array has only one item, then that item will be returned without using the separator.
# Input      : array, separator
# Returns    : joined string
sub a_join {
    my ($arr, $separator) = @_;
    $separator = defined($separator) ? $separator : ",";
    return join($separator, @$arr);
}

##################
# Subroutine : a_concat
# Purpose    : merge two or more arrays. This method does not change the existing arrays, but instead returns a new array.
# Input      : ...array_list
# Returns    : A new array
sub a_concat {
    my $result = [];
    foreach my $x (@_) {
        a_push($result, @{$x});
    }
    return $result;
}

##################
# Subroutine : a_push
# Purpose    : adds the specified elements to the end of an array and returns the new length of the array.
#
# Input      : ...elements
# Returns    : new length of the array
sub a_push {
    my $target = shift;
    push(@$target, @_);
    return scalar @$target;
}

##################
# Subroutine : a_pop
# Purpose    : removes the last element from an array and returns that element. This method changes the length of the array.
#
# Input      : array
# Returns    : The removed element from the array; undef if the array is empty.
sub a_pop {
    my $arr  = shift;
    my $item = pop(@$arr);
    return $item;
}

##################
# Subroutine : a_splice
# Purpose    : changes the contents of an array by removing or replacing existing elements and/or adding new elements in place.
#
# Input      : array
#              a_splice(array, start)
#              a_splice(array, start, deleteCount)
#              a_splice(array, start, deleteCount, item1)
#              a_splice(array, start, deleteCount, item1, item2)
#              a_splice(array, start, deleteCount, item1, item2, /* …, */ itemN)
# Returns    : An array containing the deleted elements.
sub a_splice {
    my $arr   = shift;
    my $start = shift;
    ####
    my $deleted = [];
    ####
    my $arr_size           = scalar @$arr;
    my $optional_args_size = scalar @_;
    my $deleteCount        = ($optional_args_size == 0 ? ($arr_size - $start) : shift);
    my $count              = v_max(v_min($deleteCount, $arr_size - $start), 0);

    for my $i (1 .. $count) {
        my $the_one_item = splice(@$arr, $start, 1);
        a_push($deleted, $the_one_item);
    }
    splice(@$arr, $start, 0, @_);
    return $deleted;
}

##################
# Subroutine : a_shift
# Purpose    : removes the first element from an array and returns that removed element. This method changes the length of the array.
#
# Input      : array
# Returns    : The removed element from the array; undef if the array is empty.
sub a_shift {
    my $arr = shift;
    return shift(@$arr);
}

##################
# Subroutine : a_unshift
# Purpose    : adds the specified elements to the beginning of an array and returns the new length of the array.
#
# Input      : element1, …, elementN
# Returns    : The new length property of the object upon which the method was called.
sub a_unshift {
    my $arr = shift;
    return unshift(@$arr, @_);
}

#################
# Subroutine : a_filter
# Purpose    : creates a shallow copy of a portion of a given array, filtered down to just the elements from the given array that pass the test implemented by the provided function.
# Input      : array, callback
# Returns    : A shallow copy of the given array containing just the elements that pass the test. If no elements pass the test, an empty array is returned.
sub a_filter {
    my ($arr, $callbackFn) = @_;
    my $result = [];
    my $count  = scalar @$arr;
    if ($count > 0) {
        for my $i (0 .. ($count - 1)) {
            if ($callbackFn->($arr->[$i], $i, $arr)) {
                a_push($result, $arr->[$i]);
            }
        }
    }
    return $result;
}

##################
# Subroutine : a_find_index
# Purpose    : returns the index of the first element in an array that satisfies the provided testing function. If no elements satisfy the testing function, -1 is returned.
# Input      : array, callback,
# Returns    : The index of the first element in the array that passes the test. Otherwise, -1.
sub a_find_index {
    my ($arr, $callbackFn, $fromIndex) = @_;
    my $callbackFnA = v_type_of($callbackFn) eq "CODE" ? $callbackFn : sub {
        my ($itm, $idx) = @_;
        return v_cmp($itm, $callbackFn) == 0;
    };

    my $idx   = -1;
    my $count = scalar @$arr;
    if ($count > 0) {
        my $sidx = v_max(v_min((defined($fromIndex) ? $fromIndex : 0), $count - 1), 0);
        my $eidx = $count - 1;
        ##
        my $i = $sidx;
        while ($i <= $eidx) {
            if ($callbackFnA->($arr->[$i], $i, $arr)) {
                $idx = $i;
                last;
            }
            #####
            $i++;
        }
    }
    return $idx;
}

##################
# Subroutine : a_find_last_index
# Purpose    : iterates the array in reverse order and returns the index of the first element that satisfies the provided testing function.
#              If no elements satisfy the testing function, -1 is returned.
# Input      : array, callback,
# Returns    : The index of the last (highest-index) element in the array that passes the test. Otherwise -1 if no matching element is found.
sub a_find_last_index {
    my ($arr, $callbackFn, $toIndex) = @_;

    my $callbackFnA = v_type_of($callbackFn) eq "CODE" ? $callbackFn : sub {
        my ($itm, $idx) = @_;
        return v_cmp($itm, $callbackFn) == 0;
    };
    my $idx   = -1;
    my $count = scalar @$arr;
    if ($count > 0) {
        my $sidx = v_min(v_max((defined($toIndex) ? $toIndex : $count - 1), 0), $count - 1);
        my $eidx = 0;
        ##
        my $i = $sidx;
        while ($i >= $eidx) {
            if ($callbackFnA->($arr->[$i], $i, $arr)) {
                $idx = $i;
                last;
            }
            #####
            $i--;
        }
    }
    return $idx;
}

##################
# Subroutine : a_find
# Purpose    : returns the first element in the provided array that satisfies the provided testing function.
#              If no values satisfy the testing function, undef is returned.
# Input      : array, callback,
# Returns    : The first element in the array that satisfies the provided testing function. Otherwise, undef is returned.
sub a_find {
    my ($arr, $callbackFn, $fromIndex) = @_;
    my $callbackFnA = v_type_of($callbackFn) eq "CODE" ? $callbackFn : sub {
        my ($itm, $idx) = @_;
        return v_cmp($itm, $callbackFn) == 0;
    };
    my $idx = a_find_index($arr, $callbackFnA, $fromIndex);
    if ($idx != -1) {
        return $arr->[$idx];
    }
    return undef;
}

##################
# Subroutine : a_find_last
# Purpose    : iterates the array in reverse order and returns the value of the first element that satisfies the provided testing function.
#              If no elements satisfy the testing function, undef is returned.
# Input      : array, callback,
# Returns    : The last (highest-index) element in the array that satisfies the provided testing function; undef if no matching element is found.
sub a_find_last {
    my ($arr, $callbackFn, $toIndex) = @_;
    my $callbackFnA = v_type_of($callbackFn) eq "CODE" ? $callbackFn : sub {
        my ($itm, $idx) = @_;
        return v_cmp($itm, $callbackFn) == 0;
    };
    my $idx = a_find_last_index($arr, $callbackFnA, $toIndex);
    if ($idx != -1) {
        return $arr->[$idx];
    }
    return undef;
}

##################
# Subroutine : a_index_of
# Purpose    : returns the first index at which a given element can be found in the array, or -1 if it is not present.
# Input      : array, searchElement, fromIndex(optional)
# Returns    : The first index of searchElement in the array; -1 if not found.
sub a_index_of {
    my ($arr, $searchElement, $fromIndex) = @_;
    my $idx = a_find_index(
        $arr,
        sub {
            my ($itm) = @_;
            return v_cmp($searchElement, $itm) == 0;
        },
        $fromIndex
    );
    return $idx;
}

##################
# Subroutine : a_last_index_of
# Purpose    : returns the first index at which a given element can be found in the array, or -1 if it is not present.
# Input      : array, searchElement, fromIndex(optional)
# Returns    : The first index of searchElement in the array; -1 if not found.
sub a_last_index_of {
    my ($arr, $searchElement, $toIndex) = @_;
    my $idx = a_find_last_index(
        $arr,
        sub {
            my ($itm) = @_;
            return v_cmp($searchElement, $itm) == 0;
        },
        $toIndex
    );
    return $idx;
}

##################
# Subroutine : a_every
# Purpose    : tests whether all elements in the array pass the test implemented by the provided function.
#              It returns 1 or 0.
#              It doesn't modify the array.
# Input      : array, callback(element, index, the_array)
# Returns    : 1 unless callbackFn returns a falsy value for an array element, in which case 0 is immediately returned.
sub a_every {
    my ($arr, $callbackFn) = @_;

    my $count = scalar @$arr;
    if ($count > 0) {
        my $sidx = 0;
        my $eidx = $count - 1;
        ##
        my $i = $sidx;
        while ($i <= $eidx) {
            if (!$callbackFn->($arr->[$i], $i, $arr)) {
                return 0;
            }
            #####
            $i++;
        }
    }
    return 1;
}

##################
# Subroutine : a_some
# Purpose    : tests whether at least one element in the array passes the test implemented by the provided function.
#              It returns 1 if, in the array, it finds an element for which the provided function returns 1;
#              otherwise it returns 0.
#              It doesn't modify the array.
# Input      : array, callback(element, index, the_array)
# Returns    : 0 unless callbackFn returns a truthy value for an array element, in which case 1 is immediately returned.
sub a_some {
    my ($arr, $callbackFn) = @_;

    my $count = scalar @$arr;
    if ($count > 0) {
        my $sidx = 0;
        my $eidx = $count - 1;
        ##
        my $i = $sidx;
        while ($i <= $eidx) {
            if ($callbackFn->($arr->[$i], $i, $arr)) {
                return 1;
            }
            #####
            $i++;
        }
    }
    return 0;
}

##################
# Subroutine : a_map
# Purpose    : creates a new array populated with the results of calling a provided function on every element in the calling array.
# Input      : array, callback(element, index, the_array)
# Returns    : A new array with each element being the result of the callback function.
sub a_map {
    my ($arr, $callbackFn) = @_;
    if (!defined($arr)) {
        return $arr;
    }
    my $result = [];
    my $count  = scalar @$arr;
    if ($count > 0) {
        for my $i (0 .. ($count - 1)) {
            a_push($result, $callbackFn->($arr->[$i], $i, $arr));
        }
    }
    return $result;
}

##################
# Subroutine : a_reduce
# Purpose    : executes a user-supplied "reducer" callback function on each element of the array,
#              in order, passing in the return value from the calculation on the preceding element.
#              The final result of running the reducer across all elements of the array is a single value.
# Input      : array, callback(accumulator, currentValue, currentIndex, theArray), initialValue
# Returns    : The value that results from running the "reducer" callback function to completion over the entire array.
sub a_reduce {
    my ($arr, $callbackFn, $initialValue) = @_;
    my $result = $initialValue;
    my $count  = scalar @$arr;
    if ($count > 0) {
        for my $i (0 .. ($count - 1)) {
            $result = $callbackFn->($result, $arr->[$i], $i, $arr);
        }
    }
    return $result;
}

##################
# Subroutine : a_slice
# Purpose    : returns a shallow copy of a portion of an array into a new array
#              The original array will not be modified.
# Input      : 1. array
#              2. start index
#              3. end index (optional)
# Returns    : A new array containing the extracted elements.
sub a_slice {
    my ($arr, $sidx, $eidx) = @_;
    if (!defined($arr)) {
        return $arr;
    }
    my $count  = scalar @$arr;
    my $result = [];
    if ($count > 0) {
        $eidx = defined($eidx) ? $eidx : $count;
        for my $j ($sidx .. $eidx - 1) {
            push(@$result, $arr->[$j]);
        }
    }
    return $result;
}

##################
# Subroutine : a_left
# Purpose    : Returns an array containing a specified number of elements from the left side of an array.
# Input      : 1. array
#              2. length -  a number indicating how many elements to return.
# Returns    : array
sub a_left {
    my ($arr, $length) = @_;
    ###
    return [] if ($length <= 0);
    ##
    my $arr_length = scalar @$arr;
    return [] if ($arr_length <= 0);
    ##
    my $end_idx = v_min($length, $arr_length) - 1;
    return a_slice($arr, 0, $end_idx + 1);
}

##################
# Subroutine : a_right
# Purpose    : Returns an array containing a specified number of elements from the right side of an array.
# Input      : 1. array
#              2. length -  a number indicating how many elements to return.
# Returns    : array
sub a_right {
    my ($arr, $length) = @_;
    ###
    return [] if ($length <= 0);
    ##
    my $arr_length = scalar @$arr;
    return [] if ($arr_length <= 0);
    ##
    my $start_idx = v_max($arr_length - $length, 0);
    return a_slice($arr, $start_idx);
}

##################
# Subroutine : a_sort
# Purpose    : The a_sort method returns a sorted array by callbackFn
#              The original array will not be modified.
# Input      : array, callback(a, b),
# Returns    : The new sorted array by the callbackFn
# Example    :
#     my $sorted_arr = a_sort(@array, sub {
#         my ($a, $b) = @_;
#         return $a cmp $b;
#     });
sub a_sort {
    my ($arr, $callbackFn) = @_;
    $callbackFn = defined($callbackFn) ? $callbackFn : \&v_cmp;
    my @sorted_arr = sort { $callbackFn->($a, $b) } @$arr;
    return \@sorted_arr;
}

########################################
######################################## hash
########################################


##################
# Subroutine : h_keys
# Purpose    : returns an array of a given hash's own enumerable names.
# Input      : hash
# Returns    : An array of strings representing the given hash's own enumerable keys.
sub h_keys {
    my $hash = shift;
    my @ks   = keys %$hash;
    return \@ks;
}

##################
# Subroutine : h_values
# Purpose    : returns an array of a given hash's own enumerable values.
# Input      : hash
# Returns    : An array containing the given object's own enumerable values.
sub h_values {
    my $hash = shift;
    my @vs   = values %$hash;
    return \@vs;
}

##################
# Subroutine : h_find
# Purpose    : returns the k-v tuple in the provided hash that satisfies the provided testing function.
#              If no values satisfy the testing function, undef is returned.
# Input      : $hash, callback,
# Returns    : The he k-v tuple in the provided hash that satisfies the provided testing function. Otherwise, undef is returned.
sub h_find {
    my ($hash, $callbackFn) = @_;
    ###
    my $callbackFnA = v_type_of($callbackFn) eq "CODE" ? $callbackFn : sub {
        my ($val, $key) = @_;
        return v_cmp($val, $callbackFn) == 0;
    };
    ###########
    # my $ks    = h_keys($hash);
    # my $count = scalar @$ks;
    # if ($count > 0) {
    #     my $eidx = $count - 1;
    #     my $i    = 0;
    #     while ($i <= $eidx) {
    #         my $key = $ks->[$i];
    #         my $val = $hash->{$key};
    #         ##
    #         if ($callbackFnA->($val, $key, $hash)) {
    #             return ($key, $val);
    #         }
    #         #####
    #         $i++;
    #     }
    # }
    ###########
    while (my ($key, $val) = each %$hash) {
        if ($callbackFnA->($val, $key, $hash)) {
            return ($key, $val);
        }
    }
    return undef;
}

##################
# Subroutine : h_group_by
# Purpose    : groups the elements of a given iterable according to the string values returned by a provided callback function.
# Input      : array, callback(element, idx)
#              the callback function should return a value that can get coerced into a key
# Returns    : A hash object with keys for all groups,
#              each assigned to an array containing the elements of the associated group.
sub h_group_by {
    my ($arr, $callbackFn) = @_;
    my $group_hash = a_reduce(
        $arr,
        sub {
            my ($hash, $element, $idx) = @_;
            my $group_key = $callbackFn->($element, $idx);
            if (v_type_of($group_key) ne "STRING") {
                my $stack = x_stack(1);
                unshift(@$stack, "the callback function of group_by should return a string");
                die join("\n", @$stack);
            }
            if (!defined($hash->{$group_key})) {
                $hash->{$group_key} = [];
            }
            a_push($hash->{$group_key}, $element);
            #####
            return $hash;
        },
        {}
    );
    return $group_hash;
}

##################
# Subroutine : h_assign
# Purpose    : Copies all key/value from one or more source objects to a target object.
# Input      : target_hash, source_hash_1, source_hash_2, ....
# Returns    : returns the modified target object.
sub h_assign {
    my $target_hash = shift;
    foreach my $source_hash (@_) {
        if (v_type_of($source_hash) eq "HASH") {
            while (my ($key, $val) = each %$source_hash) {
                $target_hash->{$key} = $val;
            }
        }
        else {
            ## raise an error?
        }
    }
    return $target_hash;
}

1;
