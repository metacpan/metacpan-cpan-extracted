#!/usr/bin/env perl
use warnings;
use strict;
use feature 'say';

=head1 DESCRIPTION

A basic example to generate a svg word cloud.

=cut


use App::WIoZ;

sub usage {
     say './wioz.pl [file.txt|color]';
     exit;
}

my $File = $ARGV[0];

&usage if !$File ;

my $wioz = App::WIoZ->new( 
   font_min => 18, font_max => 64,
   filename => "testoutput",
   #set_font => 'DejaVuSans,normal,bold',
   basecolor => '226666'); # violet
   #basecolor => '084A93'); # bleu
   #basecolor => '29872F'); # vert

if (-f $File) {
 my @words = $wioz->read_words($File);
 $wioz->do_layout(@words);
}
else {
 $wioz->update_colors('testoutput.sl.txt');
}

