package Acme::Pythonic::Functions;

use 5;
use warnings;
use strict;

#######################################################################
#  Acme::Pythonic::Functions is Copyright (C) 2009-2017, Hauke Lubenow.
#
#  This module is free software; you can redistribute it and/or modify it
#  under the same terms as Perl 5.14.2.
#  For more details, see the full text of the licenses in the directory
#  LICENSES. The full text of the licenses can also be found in the
#  documents 'perldoc perlgpl' and 'perldoc perlartistic' of the official
#  Perl 5.14.2-distribution. In case of any contradictions, these
#  'perldoc'-texts are decisive.
#
#  THIS PROGRAM IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL, BUT
#  WITHOUT ANY WARRANTY; WITHOUT EVEN THE IMPLIED WARRANTY OF
#  MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
#  FOR MORE DETAILS, SEE THE FULL TEXTS OF THE LICENSES IN THE DIRECTORY
#  LICENSES AND IN THE 'PERLDOC'-TEXTS MENTIONED ABOVE.
#######################################################################

use Carp;

use Exporter;

our ($VERSION, @ISA, @EXPORT);
@ISA         = qw(Exporter);

$VERSION     = 0.40;

@EXPORT      = qw(append endswith extend has_key insert isdigit isin isdir isfile len listdir lstrip lstrip2 oslistdir osname pyprint readfile remove replace rstrip rstrip2 startswith strip writefile);

# Internal Functions

sub checkArgs {

    my ($nr, @vals) = @_;

    my $lenvals = @vals;

    if($lenvals != $nr) {

        my $name = (caller 1)[3];
        my @temp = split("::", $name);
        $name = pop(@temp) . "()";

        my $arg = "arguments";

        if($nr == 1) {
            $arg = "argument";
        }

        croak "Error: Function '$name' takes exactly $nr $arg ($lenvals given),";
    }
}

# print-Replacement-Function

sub pyprint {
    if ($#_ == -1) {
        print "\n";
        return;
    }
    if ($#_ == 0) {
        print ("$_[0]\n");
        return;
    }
    # Print the array similar to a Python-list:
    my @a = @_;
    my $s;
    my $i;
    print "[";
    for $i (0 .. $#a) {
        # Put quotation-marks around strings, but not around references:
        if ($a[$i] =~ /[^0-9-]/ && ref($a[$i]) eq "") {
            print "\"$a[$i]\"";
        } else {
            print $a[$i];
        }
        if ($i != $#a) {
            print ", ";
        } else {
            print "]\n";
        }
    }
}

# String-Functions

sub endswith {

    checkArgs(2, @_);

    if ($_[0] =~ /\Q$_[1]\E$/) {
        return 1;
    }
    else {
        return 0;
    }
}


sub lstrip {

    checkArgs(1, @_);

    my $a = $_[0];

    $a =~ s/^\s+//;

    return $a;
}


sub isdigit {

    checkArgs(1, @_);

    if($_[0] =~ /\D/) {
        return 0;
    }
    else {
        return 1;
    }
}


sub lstrip2 {

    checkArgs(2, @_);

    my ($a, $b) = @_;

    if($a !~ /^\Q$b\E/) {
        return $a;
    }

    if (length($b) > length($a)) {
        return $a;
    }

    return substr($a, length($b));
}


sub replace {

    my $nrargs = @_;

    if($nrargs < 3 || $nrargs > 4) {
        croak "Error: Function 'replace()' takes either 3 or 4 arguments ($nrargs given),";
    }

    my $count = 0;

    if($nrargs == 4) {
        $count = pop(@_);
    }

    unless (isdigit($count)) {
        carp "Warning: Argument 4 of function 'replace()' should be a number; assuming 0,";
        $count = 0;
    }

    my ($all, $old, $new) = @_;

    if ($count == 0) {
        $all =~ s/\Q$old\E/$new/g;
        return $all;
    }

    for (1 .. $count) {
        $all =~ s/\Q$old\E/$new/;
    }

    return $all;
}


sub rstrip {

    checkArgs(1, @_);

    my $a = $_[0];

    $a =~ s/\s+$//;

    return $a;
}


sub rstrip2 {

    checkArgs(2, @_);

    my ($a, $b) = @_;

    if($a !~ /\Q$b\E$/) {
        return $a;
    }

    if (length($b) > length($a)) {
        return $a;
    }

    return substr($a, 0, length($a) - length($b));
}


sub startswith {

    checkArgs(2, @_);

    if ($_[0] =~ /^\Q$_[1]\E/) {
        return 1;
    }
    else {
        return 0;
    }
}


sub strip {

    checkArgs(1, @_);

    my $a = $_[0];

    $a =~ s/^\s+//;
    $a =~ s/\s+$//;

    return $a;
}

# List-Functions

sub append {

    if($#_ < 1) {
        carp "Warning: Not enough arguments for 'append()',";
    }

    return @_;
}

sub extend {

    if($#_ < 1) {
        carp "Warning: Not enough arguments for 'extend()',";
    }

    return @_;
}


sub insert {

    if($#_ < 1) {
        carp "Warning: Not enough arguments for 'insert()'; nothing inserted,";
        return @_;
    }

    my $a = pop;
    my $b = pop;

    if($b =~ /\D/) {
        carp "Warning: Second argument for 'insert()' must be a number; nothing inserted,";
        return @_;
    }
 
    my @c = @_;

    if ($b > $#c + 1) {
        carp "Warning: Position for 'insert()' beyond list; nothing inserted,";
        return @_;
    }

    splice(@c, $b, 0, $a);

    return @c;
}


sub lenlist {
    return $#_ + 1;
}


sub remove {

    if($#_ < 1) {
        carp "Warning: Not enough arguments for 'remove()',";
        return @_;
    }

    my $a = pop;

    my @b = @_;
    my $i;
    my $x = 0;

    for $i (0 .. $#_) {
        if ($_[$i] eq $a) {
            splice(@b, $i, 1);
            $x = 1;
            last;
        }
    }

    unless($x) {
        carp "Warning: Element to remove not found in list; nothing removed,";
    }

    return @b;
}

# Hash-Functions

sub has_key {

    if($#_ < 2 || $#_ % 2) {
        croak "Error: Unsuitable arguments to 'has_key()',";
    }

    my $key = pop;
    my %hash = @_;

    if (exists $hash{$key}) {
        return 1;
    }
    else {
        return 0;
    }
}


# Functions for several datatypes

sub isin {

    my $lenarg = @_;

    if ($lenarg < 3) {
        croak "Error: 'isin()' takes at least 3 arguments ($lenarg given),";
    }

    my $mode = pop;

    if ($mode ne "s" && $mode ne "l" && $mode ne "h") {
        croak "Error: Last argument to 'isin()' must be 's', 'l' or 'h',";
    }

    if ($mode eq "s") {

        if ($lenarg != 3) {
            croak "Error: 'isin()' in mode 's' takes exactly 3 arguments ($lenarg given),";
        }

        if ($_[0] =~ m/\Q$_[1]\E/) {
            return 1;
        }
        return 0;
    }

    if ($mode eq "l") {
        my $a = pop;
        for (@_) {
            if ($_ eq $a) {
                return 1;
            }
        }
        return 0;
    }

    # Only mode 'h' is left by now.

    if ($lenarg % 2) {
        croak "Error: Unsuitable arguments to 'isin()' in 'h'-mode,";
    }

    my $key = pop;
    my %hash = @_;

    if (exists $hash{$key}) {
        return 1;
    }
    else {
        return 0;
    }
}

sub len {

    my $lenarg = @_;

    if ($lenarg < 2) {
        croak "Error: 'len()' takes at least 2 arguments ($lenarg given),";
    }

    my $mode = pop;

    if ($mode ne "s" && $mode ne "l" && $mode ne "h") {
        croak "Error: Last argument to 'len()' must be 's', 'l' or 'h',";
    }

    if ($mode eq "s") {

        if ($lenarg != 2) {
            croak "Error: 'len()' in mode 's' takes exactly 2 arguments ($lenarg given),";
        }

        return length($_[0]);
    }

    if ($mode eq "l") {
        return $lenarg - 1;
    }

    # Only mode 'h' is left by now.

    if (! $lenarg % 2) {
        croak "Error: Unsuitable arguments to 'isin()' in 'h'-mode,";
    }

    return ($lenarg - 1) / 2;
}


# File-related-Functions

sub isdir {

    checkArgs(1, @_);

    if(-d $_[0]) {
        return 1;
    }
    else {
        return 0;
    }
}

sub isfile {

    checkArgs(1, @_);

    if(-f $_[0]) {
        return 1;
    }
    else {
        return 0;
    }
}

sub readfile {

    checkArgs(1, @_);

    my $file = shift;

    open(FH, "<$file") or croak "Error reading file '$file',";
    my @a = <FH>; # Gulp !
    close(FH);

    return @a;
}


sub writefile {

    if($#_ < 1) {
        croak "Error: Function 'writefile()' needs a list to write to a file as an argument,";
    }

    my ($file, @a) = @_;

    open(FH, ">$file") or croak "Error writing to file '$file',";

    print(FH @a);

    close(FH);
}

sub listdir {

    checkArgs(1, @_);

    my $dir = shift;
    if (! -d $dir) {
        croak "Error: No such directory: '$dir',";
    }
    my $filename;
    my @files = ();
    opendir (DIR, $dir) || croak "Error opening directory '$dir',";
    while(($filename = readdir(DIR))){
        if ($filename ne "." && $filename ne "..") {
            push(@files, "$filename");
        }
    }
    return @files;
}

sub oslistdir {
    return listdir(@_);
}


# System-related-Functions

sub osname {

    checkArgs(0);

    return $^O;
}

1;

__END__


=head1 NAME

Acme::Pythonic::Functions - Python-like functions for Perl

=head1 VERSION

Version 0.39

=head1 SYNOPSIS

The following script "example.pl" shows the usage of the functions. A ready-to-run version of it can be found in the "examples"-directory in the module's tar-ball: 

    use Acme::Pythonic::Functions;
    
    pyprint "Strings:";
    
    $a = "Hello";
    
    if (endswith($a, "ello")) {
        pyprint '$a ends with "ello".';
    }
    
    if (isin($a, "ll", "s")) {
        pyprint '"ll" is in $a.';
    }
    
    $a = "2345";
    
    if (isdigit($a)) {
        pyprint '$a is a digit.';
    }
    
    $a = "    Line    ";
    
    pyprint lstrip($a);
    $a = replace($a, "Line", "Another line");
    pyprint $a;
    pyprint rstrip($a);
    
    $a = "Hello";
    
    if (startswith($a, "He")) {
        pyprint '$a starts with "He".';
    }
    
    pyprint len($a, "s");
    
    pyprint;
    pyprint "Lists:";
    
    @a = ("a", "b", "c");
    $b = "d";
    
    @a = append(@a, $b);
    
    pyprint @a;
    
    @a = ("a", "b", "c");
    @b = (1, 2, 3);
    
    @a = extend(@a, @b);
    
    pyprint @a;
    
    if (isin(@a, "c", "l")) {
        pyprint '"c" is in @a.';
    }
    
    @a = insert(@a, 1, "a2");
    
    pyprint @a;
    
    pyprint len(@a, "l");
    
    @a = remove(@a, "a2");
    
    pyprint @a;
    
    pyprint;
    pyprint "Hashes:";
    
    %a = ("a" => 1, "b" => 2, "c" => 3);
    
    if (has_key(%a, "c")) {
        pyprint '%a has a key "c".';
    }
    
    if (isin(%a, "c", "h")) {
        pyprint '%a has a key "c".';
    }
    
    pyprint;
    pyprint "File-related:";
    
    if (isdir("/home/user")) {
        pyprint "Is directory.";
    }
    
    if (isfile("/home/user/myfile")) {
        pyprint "Is file.";
    }
    
    @a = ("a\n", "b\n", "c\n");
    
    if (isfile("test12345.txt")) {
    
        pyprint 'File "test12345.txt" already exists. Nothing done.';
    } else {
    
        writefile("test12345.txt", @a);
        @c = readfile("test12345.txt");
    
        for $i (@c) {
            $i = rstrip($i);
            print $i . " " ;
        }
        pyprint;
    }

    pyprint oslistdir(".");
    pyprint;
    pyprint "System-related:";
    pyprint osname();
    
In the "examples"-directory mentioned above, there's also a a Pythonic-Perl-version of this script called "perlpyex.pl" and a corresponding Python-script called "pyex.py" for comparison.

=head1 DESCRIPTION

The programming-language "Python" offers some basic string-, list- and other functions, that can be used quite intuatively. Perl often uses regular-expressions or special variables for these tasks. Although Perl's functions are in general more flexible and powerful, they are slightly more difficult to use and a bit harder to read for human beings. This module tries to mimic some of Python's functions in Perl. So maybe Python-programmers switching to Perl or programming-beginners could feel a bit more comfortable with them.

=head2 print-Replacement-Function

=over 12

=item C<pyprint>

Python adds a (system-dependent) newline-character by default to strings to be printed.
This is rather convenient and can be found in the say()-function of Perl 5.10 and above too. I wasn't happy with the way, say() prints lists though. You can have that with something like 'say for @a;', but I like the way, Python prints lists better. So I wrote my own little print-replacement called pyprint(). In Python, there isn't a function called pyprint().
If you have to print more complex data-structures, use Data::Dumper.

=back

=head2 String-Functions

=over 12

=item C<endswith($foo, $bar)>

Tests whether $foo ends with $bar (return-value: 1 or 0).

=item C<isdigit($foo)> 

Tests whether $foo contains just digits (return-value: 1 or 0).

=item C<isin($foo, $bar, "s")> 

See below.

=item C<lstrip($foo)> 

Returns $foo stripped from whitespace characters on the leftern side.

=item C<lstrip2($foo, $bar)> 

Returns $foo stripped from $bar on the leftern side. Just returns $foo, if $foo doesn't start with $bar. Not part of Python, but quite useful.

=item C<replace($foo, $old, $new [, $count])> 

Returns a copy of $foo with all occurrences of substring
$old replaced by $new. If the optional argument $count is
given, only the first $count occurrences are replaced.

=item C<rstrip($foo)> 

Returns $foo stripped from whitespace characters on the right side.

=item C<rstrip2($foo, $bar)> 

Returns $foo stripped from $bar on the right side. Just returns $foo, if $foo doesn't end with $bar. C<rstrip2()> is not a Python-builtin, although it is quite useful. The special case

C<$foo = rstrip2($foo, "\n");>

is similar to

C<chomp($foo);>

(although it makes me feel good, every time I C<chomp()> something).

=item C<startswith($foo, $bar)> 

Tests whether $foo starts with $bar (return-value: 1 or 0).

=item C<strip($foo)> 

Returns $foo stripped from whitespace characters on both sides.

=back

=head2 List-Functions

=over 12

=item C<append(@foo, $bar)> 

Returns a copy of list @foo with string $bar appended. (Perl: push()).

=item C<extend(@foo, @bar)> 

Returns a copy of list @foo extended by list @bar. That would be just C<(@foo, @bar)> in Perl.

=item C<insert(@foo, $nr, $bar)> 

Returns a copy of list @foo, with $bar inserted at position $nr.

=item C<isin(@foo, $bar, "l")> 

See below.

=item C<remove(@foo, $bar)> 

Returns a copy of list @foo with the first occurrence of element $bar removed. If $bar is not an element of @foo, just returns @foo.

=back

=head2 Hash-Functions

=over 12

=item C<has_key(%foo, $bar)> 

Tests whether hash %foo has a key $bar (return-value: 1 or 0).
C<isin()> can be used alternatively.

=item C<isin(%foo, $bar, "h")> 

See below.

=back

=head2 Functions for several datatypes

=over 12

=item C<isin([$foo, @foo, %foo], $bar, ["s", "l", "h"])> 

Tests whether $bar is a "member" of foo. Depending on the last argument given ("s" for string, "l" for list, "h" for hash"), foo can either be a string, a list or a hash.

In mode "s", it is tested, whether $bar is a substring of string $foo.
In mode "l", it is tested, whether $bar is an element of list @foo.
In mode "h", it is tested, whether $bar is a key of hash %foo.

The return-value is 1 or 0. This mimics a special syntax of Python:

if "ell" in "Hello":
    print "Is in."

if "b" in ["a", "b", "c"]:
    print "Is in."

if "c" in {"a" : 1, "b" : 2, "c" : 3}:
    print "Is in."

=item C<len([$foo, @foo, %foo], ["s", "l", "h"])> 

Returns the number of characters or elements of foo. Depending on the last argument given ("s" for string, "l" for list, "h" for hash"), foo can either be a string, a list or a hash.

In mode "s", the number of characters of string $foo is returned.
In mode "l", the number of elements of list @foo is returned.
In mode "h", the number of keys of hash %foo is returned.

=back

=head2 File-related-Functions

=over 12

=item C<isdir($foo)> 

Tests whether $foo is a directory. Python: C<os.path.isdir()>, Perl: C<-d>.

=item C<isfile($foo)> 

Tests whether $foo is a plain file. Python: C<os.path.isfile()>, Perl: C<-f>. For more detailed file-testing use the other file-testing-operators described in "perldoc perlfunc", the stat()-function or the "File::stat"-module.

=item C<listdir($foo)>, C<oslistdir($foo)>

Returns a list of the filenames in the directory $foo. Directory-entries "." and ".." are left out. Python: C<os.listdir()>.

=item C<readfile($foo)> 

Returns the contents of the text-file named $foo as a list. Only use on smaller files, as this can take a lot of memory. For processing larger files, use the "Tie::File"-module instead. C<readfile()> is not a Python-builtin, although Python has a function C<readlines()> to read multiple lines of text from a file-handle into a list at once.

=item C<writefile($foo, @bar)>

Writes @bar to a file named $foo. Not a Python-builtin.

=back

=head2 System-related-Functions

=over 12

=item C<osname()> 

Tells the name of the operating-system, similar to "os.name" in Python.

=back

=head1 AUTHOR

Hauke Lubenow, <hlubenow2@gmx.net>

=head1 COPYRIGHT AND LICENSE

Acme::Pythonic::Functions is Copyright (C) 2009-2017, Hauke Lubenow.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.14.2.
For more details, see the full text of the licenses in the directory LICENSES.
The full text of the licenses can also be found in the documents L<perldoc perlgpl> and L<perldoc perlartistic> of the official Perl 5.14.2-distribution. In case of any contradictions, these 'perldoc'-texts are decisive.

THIS PROGRAM IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL, BUT WITHOUT ANY WARRANTY; WITHOUT EVEN THE IMPLIED WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. FOR MORE DETAILS, SEE THE FULL TEXTS OF THE LICENSES IN THE DIRECTORY LICENSES AND IN THE 'PERLDOC'-TEXTS MENTIONED ABOVE.

=head1 SEE ALSO

L<Acme::Pythonic>

=cut

