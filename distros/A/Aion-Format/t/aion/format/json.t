use common::sense; use open qw/:std :utf8/; use Test::More 0.98; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { use Scalar::Util qw//; use Carp qw//; $SIG{__DIE__} = sub { my ($s) = @_; if(ref $s) { $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s; die $s } else {die Carp::longmess defined($s)? $s: "undef" }}; my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion-format!aion!format!json/'; `rm -fr '$s'` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; read $__f__, $s, -s $__f__; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Aion::Format::Json - Perl extension for formatting JSON
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Format::Json;

::is scalar do {to_json {a => 10}}, "{\n   \"a\": 10\n}\n", 'to_json {a => 10}    # => {\n   "a": 10\n}\n';
::is_deeply scalar do {from_json '[1, "5"]'}, scalar do {[1, "5"]}, 'from_json \'[1, "5"]\' # --> [1, "5"]';

# 
# # DESCRIPTION
# 
# `Aion::Format::Json` based on `JSON::XS`. And includethe following settings:
# 
# * allow_nonref - coding and decoding scalars.
# * indent - enable multiline with indent on begin lines.
# * space_after - `\n` after json.
# * canonical - sorting keys in hashes.
# 
# # SUBROUTINES
# 
# ## to_json (;$data)
# 
# Translate data to json format.
# 
done_testing; }; subtest 'to_json (;$data)' => sub { 
my $data = {
    a => 10,
};

my $result = '{
   "a": 10
}
';

::is scalar do {to_json $data}, scalar do{$result}, 'to_json $data # -> $result';

local $_ = $data;
::is scalar do {to_json}, scalar do{$result}, 'to_json # -> $result';

# 
# ## from_json (;$string)
# 
# Parse string in json format to perl structure.
# 
done_testing; }; subtest 'from_json (;$string)' => sub { 
::is_deeply scalar do {from_json '{"a": 10}'}, scalar do {{a => 10}}, 'from_json \'{"a": 10}\' # --> {a => 10}';

::is_deeply scalar do {[map from_json, "{}", "2"]}, scalar do {[{}, 2]}, '[map from_json, "{}", "2"]  # --> [{}, 2]';

# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [darviarush@mail.ru](darviarush@mail.ru)
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The Aion::Format::Json module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
