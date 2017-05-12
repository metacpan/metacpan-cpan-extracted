use strict;
use warnings;
use Test::More;
use AnnoCPAN::Config 't/config.pl';
use AnnoCPAN::PodToHtml;

#plan 'no_plan';
plan tests => 15;

my $parser = AnnoCPAN::PodToHtml->new;
isa_ok( $parser, 'AnnoCPAN::PodToHtml' );

is ( $parser->verbatim(" aaa"), 
    qq{<div class="content"><div><pre> aaa</pre>\n</div></div>\n}, "pre" );

is ($parser->ac_i_L("My::Pod"),
    qq{\0<a href="/perldoc?My::Pod"\0>My::Pod\0</a\0>}, "L<My::Pod>" );

is ($parser->ac_i_L("My::Pod/stuff"),
    qq{\0<a href="/perldoc?My::Pod#stuff"\0>"stuff" in My::Pod\0</a\0>}, 
    "L<My::Pod/stuff>" );

is ($parser->ac_i_L("/stuff"),
    qq{\0<a href="#stuff"\0>"stuff"\0</a\0>}, "L</stuff>" );

is ($parser->ac_i_L('"stuff"'),
    qq{\0<a href="#stuff"\0>"stuff"\0</a\0>}, 'L<"stuff">' );

is ($parser->ac_i_L('/"stuff"'),
    qq{\0<a href="#stuff"\0>"stuff"\0</a\0>}, 'L</"stuff">' );

is ($parser->ac_i_L('My::Pod/"stuff"'),
    qq{\0<a href="/perldoc?My::Pod#stuff"\0>"stuff" in My::Pod\0</a\0>}, 
    'L<My::Pod/"stuff">' );

is ($parser->ac_i_L('stuff at my pod|My::Pod/"stuff"'),
    qq{\0<a href="/perldoc?My::Pod#stuff"\0>stuff at my pod\0</a\0>}, 
    'L<stuff at my pod|My::Pod/"stuff">' );

is ($parser->ac_i_L('"stuff at my pod"|My::Pod/"stuff"'),
    qq{\0<a href="/perldoc?My::Pod#stuff"\0>"stuff at my pod"\0</a\0>}, 
    'L<"stuff at my pod"|My::Pod/"stuff">' );

is ($parser->ac_i_L('http://perl.org'),
    qq{\0<a href="http://perl.org"\0>http://perl.org\0</a\0>}, 
    'L<http://perl.org>' );

is ($parser->ac_i_L("my pod|My::Pod"),
    qq{\0<a href="/perldoc?My::Pod"\0>my pod\0</a\0>}, "L<my pod|My::Pod>" );

is ($parser->ac_i_L('"my pod"|My::Pod'),
    qq{\0<a href="/perldoc?My::Pod"\0>"my pod"\0</a\0>}, 'L<"my pod"|My::Pod>' );

is ($parser->ac_i_L('deprecated section'),
    qq{\0<a href="#deprecated_section"\0>"deprecated section"\0</a\0>}, 
    'L<deprecated section>' );

is ($parser->ac_i_L("\0<code\0>(pattern)\0</code\0>"),
    qq{\0<a href="#%28pattern%29"\0>"\0<code\0>(pattern)\0</code\0>"\0</a\0>}, 
    'L<C<< (pattern) >>>' );

