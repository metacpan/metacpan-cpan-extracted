use 5.010;
use warnings;
use strict;

package BrickyardTest::StringMunger::PluginBundle::Default;
use Role::Basic 'with';
with 'Brickyard::Role::PluginBundle';

sub bundle_config {
    [   [ '@Default/Uppercase', 'Uppercase', {} ],
        [ '@Default/Repeat',   'Repeat',   { times => 3 } ],
        [ '@Default/Reporter', 'Reporter', {} ],
    ];
}
1;
