#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test to fix point syntaxe.

=cut

use Test::More tests => 14;

use_ok('App::WIoZ');


my $dirname = (-f 't/test-words.txt')?'t/':''; 

my $wioz = App::WIoZ->new( height => 300, font_min => 18, font_max => 64 );
is($wioz->center->x,400,'x center is 400 (def 800)');
is($wioz->center->y,150,'y center is 150');

is($wioz->font->{font},'LiberationSans','default font LiberationSans');

# a new smallest svg image for tests
$wioz = App::WIoZ->new( height => 200, width => 200, font_min => 18, font_max => 64, filename => $dirname.'test'); 
my @words = $wioz->read_words($dirname.'test-words.txt'); 
isa_ok($words[0],'App::WIoZ::Word');

$wioz->do_layout(@words); # compute image
is(-f $dirname.'test.svg',1,"create image ".$dirname.'test.svg');
is(-f $dirname.'test.sl.txt',1,"save layout ".$dirname.'test.sl.txt');

# a new smallest png image for tests
$wioz = App::WIoZ->new( height => 200, width => 200, font_min => 18, font_max => 64,
        filename => $dirname.'test' , svg => 0,
        set_font => 'DejaVuSans,italic,normal');
is($wioz->font->{font},'DejaVuSans','set_font to DejaVuSans');


@words = $wioz->read_words($dirname.'test-words.txt'); 

is ($words[0]->font->{font},'DejaVuSans','word with DejaVuSans font');

$wioz->do_layout(@words); # compute image
is(-f $dirname.'test.png',1,"create image ".$dirname.'test.png');
is(-f $dirname.'test.sl.txt',1,"save layout ".$dirname.'test.sl.txt');

# update colorsa nd font
#$wioz->chg_font('strenuous,normal,normal');
$wioz->chg_font('LiberationSans,normal,bold');
is($wioz->font->{font},'LiberationSans','chg_font to LiberationSans');

$wioz->filename($dirname.'test2');
$wioz->update_colors($dirname.'test.sl.txt');
is(-f $dirname.'test2.png',1,"create image with new color ".$dirname.'test2.png');

# update colors
$wioz->filename($dirname.'test3');
$wioz->update_colors($dirname.'test.sl.txt');
is(-f $dirname.'test3.png',1,"create image with new color ".$dirname.'test3.png');

# test directory clean up
unlink $dirname.'test.sl.txt';
unlink $dirname.'test.svg';
unlink $dirname.'test.png';
unlink $dirname.'test2.png';
unlink $dirname.'test3.png';


$wioz = App::WIoZ->new( height => 300, font_min => 18, font_max => 64, set_font => 'DejaVuSans,normal,bold');

