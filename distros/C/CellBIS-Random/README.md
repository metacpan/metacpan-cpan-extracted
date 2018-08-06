# CellBIS::Random

The purpose of this module is to randomize characters in strings.
Before a random or unrandom character (extract from random), the string
will be converted to an array to get an odd/even number of key array.

## How to Install :
From Source :
```bash
git clone -b v0.1 git@github.com:CellBIS/CellBIS-Random.git
perl Makefile.PL
make && make test
make install && make clean
```
with `cpan` command :
```bash
cpan -i CellBIS::Random
```
with `cpanm` command :
```bash
cpanm CellBIS::Random
```

# METHODS

There is four methods `set_string`, `get_result`, `random` and `unrandom`.

Specifically for `random` and `unrandom` methods, you can use two or three arguments.
If using Object Oriented, you can use 2 arguments. But if using Procedural, you can use 3 arguments.

```perl
# Object Oriented
# Arguments : <number_of_random_odd>, <number_of_random_even>
$rand->random(2, 3);
$rand->unrandom(2, 3);

# Procedural
# Arguemnts : <your_string_to_random>, <number_of_random_odd>, <number_of_random_even>
CellBIS::Random->random('your string to random', 2, 3);
CellBIS::Random->unrandom('result of random to extract', 2, 3);
```

## set_string

Method to set up string for Random action.

## get_result

Method to get result of random character and Extract result of random.

## random

With `set_string` :
```perl
use CellBIS::Random;

my $string = 'my string here';
$rand->set_string($string);

my $result_random = $rand->random(2, 3);
print "Random Result : $result_random \n";
```
Without `set_string` :
```perl
my $result_random = $rand->random('my string here', 2, 3);
print "Random Result : $result_random \n";
```
## unrandom

With `set_string` :
```perl
$rand->set_string($result_random);

my $result_unrandom = $rand->unrandom(2, 3);
print "Extract Random Result : $result_unrandom \n";
```
Without `set_string` :
```perl
my $result_unrandom = $rand->unrandom($rand->{result}, 2, 3);
print "Extract Random Result : $result_unrandom \n";
```
# EXAMPLES

Example to using Procedural and Object Oriented

## Procedural

Case 1
```perl
use CellBIS::Random;

my $result_random = CellBIS::Random->random('my string here', 2, 3);
print "Random Result : $result_random \n";

my $extract_random = CellBIS::Random->unrandom($result_random, 2, 3);
print "Extract Random Result : $extract_random \n";
```
Case 2

```
use CellBIS::Random;

my $rand = CellBIS::Random->new();
my $result_random = $rand->random('my string here', 2, 3);
print "Random Result : $result_random \n";

my $extract_random = $rand->unrandom($result_random, 2, 3);
print "Extract Random Result : $extract_random \n";
  
```
## Object Oriented

Case 1

```perl
use CellBIS::Random;

my $rand = CellBIS::Random->new();

# For Random
$rand->set_string('my string here');
$rand->random(2, 3);
my $result_random = $rand->get_result();

print "Random Result : $result_random \n";

=====================================================

# For Extract Random
$rand->set_string($result_random);
$rand->unrandom(2, 3);
my $extract_random = $rand->get_result();

print "Extract Random Result : $extract_random \n";
```
  
Case 2

```perl
use CellBIS::Random;

my $rand = CellBIS::Random->new();

# For Random
$rand->set_string('my string here');
my $result_random = $rand->random('my string here', 2, 3);

print "Random Result : $result_random \n";

=====================================================

# For Extract Random
my $extract_random = $rand->unrandom($result_random, 2, 3);

print "Extract Random Result : $extract_random \n";
```
  
Case 3
```perl
use CellBIS::Random;

my $rand = CellBIS::Random->new();

# For Random
my $result_random = $rand->random('my string here', 2, 3);

print "Random Result : $result_random \n";

=====================================================

# For Extract Random
my $extract_random = $rand->unrandom($result_random, 2, 3);

print "Extract Random Result : $extract_random \n";
```
  
# AUTHOR

Achmad Yusri Afandi, <yusrideb@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2018 by Achmad Yusri Afandi

This program is free software, you can redistribute it and/or modify it under the terms of
the Artistic License version 2.0.
