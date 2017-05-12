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
          -title    => 'Apache2::UploadProgress Embedded Example',
          -encoding => 'UTF-8',
          -script   => [ { -src => '/UploadProgress/progress.js'      },
                         { -src => '/UploadProgress/progress.jmpl.js' }, ],
          -style    => [ { -src => '/UploadProgress/progress.css', -rel => 'StyleSheet',           -title => 'Default' },
                         { -src => 'css/progress_blueblock.css',   -rel => 'Alternate StyleSheet', -title => 'Blue Blocks' },
                         { -src => 'css/progress_bluebar.css',     -rel => 'Alternate StyleSheet', -title => 'Blue Animated Bar' }, ],
      ),
      $q->h1( $q->param('file') ? 'Upload complete!' : 'Apache2::UploadProgress Example' ),
      $q->p('Apache2::UploadProgress is a mod_perl module designed to make it easy to add progress monitors to your form uploads.  Use the form below to upload a file, and if your browser supports it, you will see a progress bar appear under the form when you submit it.  During the upload, you can choose a different stylesheet to see some different styles for the progress bar.'),
      $q->p('Choose a StyleSheet: ',
          $q->a({-href => "#", -onclick => "setActiveStyleSheet('Default');           return false;" }, 'Default'),
          ', ',
          $q->a({-href => "#", -onclick => "setActiveStyleSheet('Blue Blocks');       return false;" }, 'Blue Blocks'),
          ', ',
          $q->a({-href => "#", -onclick => "setActiveStyleSheet('Blue Animated Bar'); return false;" }, 'Blue Animated Bar'),
      ),
      $q->start_form(
          -action   => $q->script_name,
          -enctype  => 'multipart/form-data',
          -method   => 'POST',
          -onsubmit => 'return startEmbeddedProgressBar(this);'
      ),
      $q->table(
          $q->Tr( [
              $q->td( [ 'File', $q->filefield( -name => 'file' ) ] ),
              $q->td( [ 'File', $q->filefield( -name => 'file' ) ] )
          ] )
      ),
      $q->div( { -id => 'progress' }, $q->submit ),
      $q->end_form,
      $q->h2('Parameters'),
      $q->Dump,
      $q->end_html;
