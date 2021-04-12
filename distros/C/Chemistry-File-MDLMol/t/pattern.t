use strict;
use warnings;
use Test::More;
use Chemistry::File::MDLMol;

my @patt_files = glob 't/pat/*.mol';
my @mol_files  = glob 't/mol/*.mol';

if (eval "use Chemistry::Pattern; 1") {
    plan tests => 1 + 1 * @patt_files + 1 * @patt_files * @mol_files;
    #plan 'no_plan';
    ok(1, "loaded Chemistry::Pattern");
} else {
    plan skip_all => 'Chemistry::Pattern not installed';
}

#$Chemistry::File::MDLMol::DEBUG = 1;

for my $patt_file (@patt_files) {
    my $patt = Chemistry::Pattern->read($patt_file);
    isa_ok ($patt, 'Chemistry::Pattern');
    my ($patt_basename) = $patt_file =~ /([^\/]*)\.mol/;
    my %expected = split " ", $patt->name;

    for my $mol_file (@mol_files) {
        my ($mol_basename) = $mol_file =~ /([^\/]*)\.mol/;
        $expected{$mol_basename} ||= 0;

        my $mol = Chemistry::Mol->read($mol_file);
        Chemistry::Ring::aromatize_mol($mol);

        my $n = 0;
        $n++ while $patt->match($mol);
        is ($n, $expected{$mol_basename}, 
            "$patt_basename matches $mol_basename $expected{$mol_basename} times?");
    }
}

