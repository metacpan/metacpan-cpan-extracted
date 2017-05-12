#!/usr/bin/perl

use warnings;
use strict;
no strict 'vars';

# example.pl

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

pyprint;
pyprint oslistdir(".");

pyprint;
pyprint "System-related:";
pyprint osname();
