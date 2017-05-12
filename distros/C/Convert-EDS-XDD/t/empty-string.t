use Test::More;

BEGIN {
    use_ok 'Convert::EDS::XDD', 'eds2xdd_string';
}

my $xdd = eds2xdd_string('');
ok ($xdd); # not empty

done_testing;

