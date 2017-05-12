#!/usr/bin/perl

use strict;
use lib '../blib/lib';
use CGI qw(:standard);
use CGI::Widget::Series;

my $series = CGI::Widget::Series->new(
                                      -length=>10,
                                      -render=> \&image,
                                      -break=>1,
                                      -linebreak=>1,
                                     );

print $series,"\n";

sub image {
  my $pos = shift;
  return image_button(-name   =>"zoom$pos",
                      -src    =>"/buttons/zoom/green$pos.gif",
                      -alt    =>"show $pos"."000 bp",
                      -title  =>"show $pos"."000 bp",
                      -border =>0,
                      -height => $pos*2,
                      -width  =>  1,
                     );
}

<input type="image" name="zoom1" src="/buttons/zoom/green2.gif" alt="show 2000 bp" border="-title" show 2000 bp>
