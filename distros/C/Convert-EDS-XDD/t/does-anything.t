use Test::More;

BEGIN {
    use_ok 'Convert::EDS::XDD', 'eds2xdd_string';
}

my $eds = do {
    local $/;
    <DATA>
};
my @time = (
    fileModificationDate => ' ',
    fileModificationTime => ' ',
    fileCreationDate => ' ',
    fileCreationTime => ' ',
);

is eds2xdd_string('', @time), eds2xdd_string('', @time);

my $empty_xdd     = eds2xdd_string('', @time);
my $non_empty_xdd = eds2xdd_string($eds, @time);
isnt $empty_xdd, $non_empty_xdd;

done_testing;

__DATA__
[FileInfo]
CreatedBy=Tim Toady

