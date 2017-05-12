use strict;
use warnings;

use Test::More;
use Crypt::Password::StretchedHash::HashInfo;

TEST_NEW: {

    my $hash_info = Crypt::Password::StretchedHash::HashInfo->new;
    ok ( $hash_info, q{constructor is returned} );

};

TEST_ABSTRACT: {

    my $hash_info = Crypt::Password::StretchedHash::HashInfo->new;
    my ($delimiter, $identifier, $hash, $salt, $stretch_count, $format);
    eval{
        $delimiter = $hash_info->delimiter; 
    };
    ok ( $@, q{hash_info->delimiter is abstract method} );

    eval{
        $identifier = $hash_info->identifier; 
    };
    ok ( $@, q{hash_info->identifier is abstract method} );

    eval{
        $hash = $hash_info->hash; 
    };
    ok ( $@, q{hash_info->hash is abstract method} );

    eval{
        $salt = $hash_info->salt; 
    };
    ok ( $@, q{hash_info->salt is abstract method} );

    eval{
        $stretch_count = $hash_info->stretch_count; 
    };
    ok ( $@, q{hash_info->stretch_count is abstract method} );

    eval{
        $format = $hash_info->format; 
    };
    ok ( $@, q{hash_info->format is abstract method} );

};

done_testing;
