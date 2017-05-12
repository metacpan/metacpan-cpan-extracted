#!/usr/bin/env perl

use strict;
use warnings;

use CGI         qw[];
use Digest::MD5 qw[];
use Time::HiRes qw[];

my $id = Digest::MD5::md5_hex( time() . {} . rand() . $$ );
my $q  = CGI->new( sub { Time::HiRes::sleep(0.250) } ); # will give us a nice slowdown

print $q->header(
          -charset  => 'UTF-8',
      ),
      $q->start_html(
          -title    => 'Apache2::UploadProgress Popup Example',
          -encoding => 'UTF-8',
          -script   => { -src => '/UploadProgress/progress.js' },
      ),
      $q->h1( $q->param('file') ? 'Upload complete!' : 'Apache2::UploadProgress Example' ),
      $q->start_form(
          -action   => $q->script_name,
          -enctype  => 'multipart/form-data',
          -method   => 'POST',
          -onsubmit => 'return startPopupProgressBar(this, {width : 500, height : 400});'
      ),
      $q->table(
          $q->Tr( [
              $q->td( [ 'File', $q->filefield( -name => 'file' ) ] ),
              $q->td( [ 'File', $q->filefield( -name => 'file' ) ] )
          ] )
      ),
      $q->submit,
      $q->end_form,
      $q->h2('Parameters'),
      $q->Dump,
      $q->end_html;
