#!perl -T
use 5.006;
use strict;
use warnings;

use utf8;

our $VERSION='0.03';

binmode STDERR, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN,  ':encoding(UTF-8)';
# to avoid wide character in TAP output
# do this before loading Test* modules
use open ':std', ':encoding(utf8)';

use Test::More;
#use Test::Deep;

my $num_tests = 0;

use Data::Roundtrip;

use Data::Dumper qw/Dumper/;

my $abc = "abc-αβγ";
my $xyz = "χψζ-xyz";

my $json_string = <<EOS;
{"$abc":"$xyz"}
EOS
$json_string =~ s/\s*$//;

my $yaml_string = <<EOS;
---
$abc: $xyz
EOS
#$yaml_string =~ s/\s*$//;

my $perl_var = {$abc => $xyz};

# perl2json
my $result = Data::Roundtrip::perl2json($perl_var);
ok(defined $result, "perl2json() called."); $num_tests++;
ok($result eq $json_string, "perl2json() checked (got: '$result', expected: '$json_string')."); $num_tests++;

# json2perl
$result = Data::Roundtrip::json2perl($json_string);
ok(defined $result, "json2perl() called."); $num_tests++;
for (keys %$result){
	ok(exists $perl_var->{$_}, "json2perl() key exists."); $num_tests++;
	ok($perl_var->{$_} eq $result->{$_}, "json2perl() values are the same."); $num_tests++;
}
for (keys %$perl_var){
	ok(exists $result->{$_}, "json2perl() key exists (other way round)."); $num_tests++;
}
# this fails:
#cmp_deeply($perl_var, $result, "json2perl() checked (got: '".Dumper($result)."', expected: ".Dumper($perl_var).")."); $num_tests++;

# perl2yaml
$result = Data::Roundtrip::perl2yaml($perl_var);
ok(defined $result, "perl2yaml() called."); $num_tests++;
ok($result eq $yaml_string, "perl2yaml() checked (got: '$result', expected: '$yaml_string')."); $num_tests++;

# yaml2perl
$result = Data::Roundtrip::yaml2perl($yaml_string);
ok(defined $result, "yaml2perl() called."); $num_tests++;
for (keys %$result){
	ok(exists $perl_var->{$_}, "yaml2perl() key exists."); $num_tests++;
	ok($perl_var->{$_} eq $result->{$_}, "yaml2perl() values are the same."); $num_tests++;
}
for (keys %$perl_var){
	ok(exists $result->{$_}, "yaml2perl() key exists (other way round)."); $num_tests++;
}

# yaml2json
$result = Data::Roundtrip::yaml2json($yaml_string);
ok(defined $result, "yaml2json() called."); $num_tests++;
ok($result eq $json_string, "perl2yaml() checked (got: '$result', expected: '$json_string')."); $num_tests++;

# json2yaml
$result = Data::Roundtrip::json2yaml($json_string);
ok(defined $result, "json2yaml() called."); $num_tests++;
ok($result eq $yaml_string, "perl2yaml() checked (got: '$result', expected: '$yaml_string')."); $num_tests++;

# perl2dump and dump2perl with unicode quoting (default Data::Dumper behaviour)
my $adump = Data::Roundtrip::perl2dump($perl_var, {'terse'=>1});
ok(defined $adump, "perl2dump() called."); $num_tests++;
ok($adump=~/\\x\{3b1\}/, "perl2dump() unicode quoted."); $num_tests++;
# dump2perl
$result = Data::Roundtrip::dump2perl($adump);
ok(defined $result, "dump2perl() called."); $num_tests++;
for (keys %$result){
	ok(exists $perl_var->{$_}, "perl2dump() and dump2perl() key exists."); $num_tests++;
	ok($perl_var->{$_} eq $result->{$_}, "perl2dump() and dump2perl() values are the same."); $num_tests++;
}
for (keys %$perl_var){
	ok(exists $result->{$_}, "perl2dump() and dump2perl() key exists (other way round)."); $num_tests++;
}

# perl2dump and dump2perl WITHOUT unicode quoting
$adump = Data::Roundtrip::perl2dump($perl_var, {'terse'=>1, 'dont-bloody-escape-unicode'=>1});
ok(defined $adump, "perl2dump() called."); $num_tests++;
ok($adump!~/\\x\{3b1\}/, "perl2dump() unicode not quoted."); $num_tests++;
# dump2perl
$result = Data::Roundtrip::dump2perl($adump);
ok(defined $result, "dump2perl() called."); $num_tests++;
for (keys %$result){
	ok(exists $perl_var->{$_}, "perl2dump() and dump2perl() key exists."); $num_tests++;
	ok($perl_var->{$_} eq $result->{$_}, "perl2dump() and dump2perl() values are the same."); $num_tests++;
}
for (keys %$perl_var){
	ok(exists $result->{$_}, "perl2dump() and dump2perl() key exists (other way round)."); $num_tests++;
}

done_testing($num_tests);
