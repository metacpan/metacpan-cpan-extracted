#!/usr/bin/perl
#
# This file is part of App-PythonToPerl
#
# This software is Copyright (c) 2023 by Auto-Parallel Technologies, Inc.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

my $x = <<'END';

{
  "model": "code-davinci-002",
  "prompt": "# Python to Perl\nPython:\n\n        for test_index in self._iter_test_masks(X, y, groups):\n            test_var = \"test data\"\n            train_index = indices[np.logical_not(test_index)]\n\nPerl:",
  "temperature": 0,
  "max_tokens": 256,
  "top_p": 1,
  "frequency_penalty": 0,
  "presence_penalty": 0,
  "stop": ["# Python to", "test_stop_sequence"]
}

END

print "\n", '[[[ BEGIN ORIGINAL ]]]', "\n";
print $x;
print "\n", '[[[ END ORIGINAL ]]]', "\n";

# replace curly braces with parentheses
$x =~ s/^\{$/\(/gmsx;
$x =~ s/^\}$/\)/gmsx;

# remove double quotes from around hash keys;
# replace double quotes with single quotes, to avoid interpolation;
# replace colon separator with fat arrow (AKA fat comma);
# regex must all be on one line to avoid inserting additional spaces or newlines into output
my $regex_replaced = 0;
do {
    $x =~ s/^\s*\"(\w+)\"\:\s+\[([^\"]*)\"([^\"]*)\"([^\n]*)\](\,?)$/\ \ \ \ \"$1\"\: \[$2\'$3\'$4\]$5/gmsx;  # "foo": ["bar", "baz"]

    if ((defined $3) and ($3 ne '')) {
        $regex_replaced = 1;
    }
    else {
        $regex_replaced = 0;
    }
print 'DEBUG, have $3 = \'', $3, '\'', "\n";
#} while ((defined $3) and ($3 ne ''));  # DEV NOTE: regex variable $3 does not keep value into postfix while() header, must test inside 
} while ($regex_replaced);

$x =~ s/^\s*\"(\w+)\"\:\s+\"([^\n]*)\"(\,?)$/\ \ \ \ $1\ => \'$2\'$3/gmsx;  # "foo": "bar",  __OR__  "foo": "bar" 
$x =~ s/^\s*\"(\w+)\"\:\s+([^\n]*)(\,?)$/\ \ \ \ $1\ => $2$3/gmsx;          # "foo": 123,    __OR__  "foo": 123

# NEED FORMAT W/ PERL TIDY TO ALIGN COLUMNS
# NEED FORMAT W/ PERL TIDY TO ALIGN COLUMNS
# NEED FORMAT W/ PERL TIDY TO ALIGN COLUMNS

print "\n", '[[[ BEGIN MODIFIED ]]]', "\n";
print $x;
print "\n", '[[[ END MODIFIED ]]]', "\n";

