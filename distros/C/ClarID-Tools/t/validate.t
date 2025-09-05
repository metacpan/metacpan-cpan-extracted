#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec::Functions qw(catfile catdir);
use Test::More;

my $codebook = catfile( 'share', 'clarid-codebook.yaml' );
my $schema   = catfile( 'share', 'clarid-codebook-schema.json' );
my $exe      = catfile( 'bin',   'clarid-tools' );
my $inc      = join ' -I', '', @INC;    # prepend -I to each path in @INC

# how many tests? e.g. 3
plan tests => 10;

# 1) Valid codebook should pass
{
    my $out =
      `$^X $inc $exe validate --codebook $codebook --schema $schema 2>&1`;
    my $exit = $? >> 8;
    is( $exit, 0, 'exit 0 on valid codebook' );
    like( $out, qr/✅ Codebook is valid/, 'prints valid message' );
}

# 2) Invalid schema path
{
    my $out =
      `$^X $inc $exe validate --codebook $codebook --schema missing.json 2>&1`;
    my $exit = $? >> 8;
    ok( $exit != 0, 'non-zero exit on missing schema' );
    like(
        $out,
        qr/missing\.json.*No such file or directory/,
        'complains about missing schema'
    );
}

# 3) Invalid codebook data
{
    # you can create a temp YAML with invalid structure or pass bad JSON
    my $bad_yaml = 't/data/bad_codebook.yaml';

    # ... ensure that file exists with bad format ...
    my $out =
      `$^X $inc $exe validate --codebook $bad_yaml --schema $schema 2>&1`;
    my $exit = $? >> 8;
    ok( $exit != 0, 'non-zero exit on invalid codebook' );
    like( $out, qr/Codebook validation failed/, 'fails validation' );
}

# 4) Default JSON schema
{
    my $out  = `$^X $inc $exe validate --codebook $codebook 2>&1`;
    my $exit = $? >> 8;
    is( $exit, 0, 'exit 0 on valid codebook' );
    like( $out, qr/✅ Codebook is valid/, 'prints valid message' );
}

# 5) Duplicate stub_code in tissue
{
    my $dup_yaml = 't/data/duplicate_codebook.yaml';
    my $out =
      `$^X $inc $exe validate --codebook $dup_yaml --schema $schema 2>&1`;
    my $exit = $? >> 8;
    ok( $exit != 0, 'non-zero exit on duplicate stub_code' );
    like(
        $out,
qr/Duplicate stub_code 'B' in category 'tissue' \(entity: 'biosample'\) for keys '(?:Kidney' and 'Blood|Blood' and 'Kidney')/,
        'detects duplicate stub_code in tissue'
    );
}

done_testing();
