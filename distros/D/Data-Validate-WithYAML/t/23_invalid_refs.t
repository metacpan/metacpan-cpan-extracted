#!/usr/bin/env perl 

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

{
    my $validator = Data::Validate::WithYAML->new( [] );
    is $Data::Validate::WithYAML::errstr, 'file does not exist';
}

{
    my $validator = Data::Validate::WithYAML->new( {} );
    is $Data::Validate::WithYAML::errstr, 'file does not exist';
}

{
    my $validator = Data::Validate::WithYAML->new( \'test' );
    like $Data::Validate::WithYAML::errstr, qr!YAML::Tiny failed to classify line 'test'!;
}

done_testing();
