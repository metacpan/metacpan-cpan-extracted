use strict;
use warnings;
use inc::Module::Install 0.91;

if ( $Module::Install::AUTHOR ) {
    system( 'pod2text lib/Catalyst/Action/RenderView.pm > README' )
        and die $!;
}

name 'Catalyst-Action-RenderView';
all_from 'lib/Catalyst/Action/RenderView.pm';

requires 'Catalyst::Runtime' => '5.80030';
requires 'Test::More';
requires 'Data::Visitor' => '0.24';
requires 'MRO::Compat';

test_requires 'HTTP::Request::AsCGI';
test_requires 'Test::More' => '0.88';

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Action-RenderView/trunk/';

WriteAll;
