package Business::EDI::CodeList::ReturnablePackageLoadContentsCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8393;}
my $usage       = 'B';

# 8393  Returnable package load contents code                   [B]
# Desc: Code specifying the load contents for a returnable
# package.
# Repr: an..3

my %code_hash = (
'1' => [ 'Loaded with empty 4-block for blocking purposes',
    'Loaded with empty 4-block for blocking purposes.' ],
'2' => [ 'Empty container with dunnage',
    'The container is, has been, or will be returned with dunnage only.' ],
'3' => [ 'Empty container',
    'The container is, has been, or will be returned empty.' ],
'4' => [ 'Loaded with production material',
    'The package is, has been, or will be returned loaded with production material.' ],
'6' => [ 'Obsolete material',
    'The package is, has been, or will be returned loaded with obsolete material.' ],
'7' => [ 'Loaded with excess returned production material',
    'The package is, has been, or will be returned loaded with excess production material.' ],
'8' => [ 'Loaded with rejected material',
    'The package is, has been, or will be returned loaded with rejected material.' ],
'10' => [ 'Loaded with returned processed material',
    'The package is, has been, or will be returned loaded with processed material.' ],
'11' => [ 'Empty container, folded',
    'An empty container, which is folded.' ],
);
sub get_codes { return \%code_hash; }

1;
