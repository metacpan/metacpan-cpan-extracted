#!/usr/bin/perl -w

=head1 NAME

01_basic.t

=head1 DESCRIPTION

test App::Basis::ConvertText2::UtfTransform

=head1 AUTHOR

kevin mulholland, moodfarm@cpan.org

=cut

use v5.10;
use strict;
use warnings;
use Test::More tests => 8;

BEGIN { use_ok('App::Basis::ConvertText2::UtfTransform'); }

my $string = "<b>bold text</b> 
<i>italic text</i>
<f>flipped upside down text</f>
<s>script text</s>
<o>bubles text</o>
<l>Leet Speak</l>" ;

my $new =  utf_transform( $string) ;
ok( $new !~ /<b>/, 'bold has been replaced') ;
ok( $new !~ /<i>/, 'italic has been replaced') ;
ok( $new !~ /<l>/, 'leet has been replaced') ;
ok( $new !~ /<o>/, 'bubbles has been replaced') ;
ok( $new !~ /<s>/, 'script has been replaced') ;

my $smile = ":beer: <3" ;
$new = utf_smilies( $smile) ;
ok( $new !~ /:beer:/, 'beer has been replaced') ;
ok( $new !~ /<3/, 'heart has been replaced') ;
