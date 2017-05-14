=head1 LICENSE

Copyright [2015-2017] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

use strict;
use warnings;

use Test::More;
use Test::Fake::HTTPD;
use Test::Output;
use Test::Exception;
use Bio::DB::Big;

use FindBin '$Bin';
use bytes qw//;

note 'This code implements a basic HTTP range system otherwise tests do not work properly';

my $return_file = sub {
  my ($file, $range_request, $seek, $length) = @_;
  my $target = "${Bin}/data/${file}";
  open my $fh, '<', $target or die "Cannot open '${target}' file: $!";
  binmode $fh;
  my $file_contents;
  
  if($range_request) {
    seek($fh, $seek, 0);
    read($fh, $file_contents, $length);
  }
  else {
    local $/ = undef;
    $file_contents = <$fh>;
  }
  
  close $fh;
  
  # Get file stats
  my @stat = stat $target;
  my $total_size = $stat[7];
  
  return (\$file_contents, $total_size);
};

delete $ENV{HTTP_PROXY} if $ENV{HTTP_PROXY};
delete $ENV{http_proxy} if $ENV{http_proxy};

my $get_server = sub {
  my $httpd = Test::Fake::HTTPD->new();
  $httpd->run(sub {
    my $req = shift;
    my $content = \q{};
    my $total_size = 0;
    my $code = '404';
    my %headers = (
      'Content-Type' => 'application/octet-stream'
    );
    
    my $range = $req->header('range');
    my ($range_request, $start, $end, $length) = (0,0,0,0);
    if($range =~ /bytes=(\d+)-(\d+)/) {
      $range_request = 1;
      $start = $1;
      $end = $2;
      $length = ($end - $start)+1;
    }
    
    if($req->uri() eq '/test.bw') {
      ($content, $total_size) = $return_file->('test.bw', $range_request, $start, $length);
      $code = '200';
    }
    elsif($req->uri() eq '/test.bb') {
      ($content, $total_size) = $return_file->('test.bb', $range_request, $start, $length);
      $code = '200';
    }
    elsif($req->uri() eq '/moved/test.bw') {
      # warn 'asked about this!';
      $code = '302';
      $headers{'Location'} = '/test.bw';
    }
    
    if($start && $code eq '200') {
      $code = '206'; # change to partial content
      my $content_length = bytes::length($$content);
      my $actual_end = $start + $content_length;
      $headers{'Content-Length'} = $content_length;
      $headers{'Content-Range'} = "bytes $start-$actual_end/$total_size";
    }

    return [
      $code,
      [%headers],
      [ $$content ]
    ];
  });
  ok(defined $httpd, 'Got a web server');
  note( sprintf "You can connect to your server at %s.\n", $httpd->host_port );
  return $httpd;
};

Bio::DB::Big->init();

subtest 'Testing opening remote BigWig file' => sub {
  my $httpd = $get_server->();
  my $url_root = $httpd->endpoint;
  my $bw_file = "${url_root}/test.bw";
  note $bw_file;
  {
    my $big = Bio::DB::Big->open($bw_file);
    is($big->type(), 0, 'Type of file should be 0 i.e. a bigwig file');
  }

  {
    is(Bio::DB::Big::File->test_big_wig($bw_file), 1, 'Expect a bigwig file to report as being a bigwig');
    is(Bio::DB::Big::File->test_big_bed($bw_file), 0, 'Expect a bigwig file to report as not being a bigbed');
    my $big = Bio::DB::Big::File->open_big_wig($bw_file);
    ok($big, 'Testing we have an object');
    is($big->type(), 0, 'Type of file should be 0 i.e. a bigwig file');
  }
};

subtest 'Testing opening remote BigBed file' => sub {
  my $httpd = $get_server->();
  my $url_root = $httpd->endpoint;
  my $bb_file = "${url_root}/test.bb";
  note $bb_file;
  {
    my $big = Bio::DB::Big->open($bb_file);
    is($big->type(), 1, 'Type of file should be 0 i.e. a bigbed file');
  }
  is(Bio::DB::Big::File->test_big_wig($bb_file), 0, 'Expect a bigbed file to report as being a bigbed');
  is(Bio::DB::Big::File->test_big_bed($bb_file), 1, 'Expect a bigbed file to report as not being a bigbed');
  my $big = Bio::DB::Big::File->open_big_bed($bb_file);
  ok($big, 'Testing we have an object');
  is($big->type(), 1, 'Type of file should be 0 i.e. a bigbed file');
};

subtest 'Checking that we can influence the CURL opts' => sub {
  my $httpd = $get_server->();
  my $url_root = $httpd->endpoint;
  
  {
    my $bw_file = "${url_root}/test.bw";
  
    Bio::DB::Big->timeout(1);
  
    my $err_regex = qr/Timeout was reached/;
    stderr_like(sub {
      Bio::DB::Big::File->test_big_wig($bw_file)
    }, $err_regex, 'Checking a low timeout causes connection issues');
  
    Bio::DB::Big->timeout(0);
    stderr_unlike(sub {
      Bio::DB::Big::File->test_big_wig($bw_file)
    }, $err_regex, 'Resetting timeout to 0 makes the error go away');

  }
  
  {
    my $bw_file = "${url_root}/moved/test.bw";
    Bio::DB::Big->follow_redirects(1);
    my $bw = Bio::DB::Big::File->test_big_wig($bw_file);
    ok(defined $bw, 'Checking we can find the moved bigwig file with 302 HTTP responses');
    Bio::DB::Big->follow_redirects(0);
    Bio::DB::Big->timeout(200);
    
    # We are doing two nested tests here. 
    # First layer checks for perl exception. 
    # Second layer checks libcurl writes an error to STDERR
    dies_ok { 
      stderr_like(sub {
          Bio::DB::Big::File->open_big_wig($bw_file)
        },
        qr/timeout/i,
        'Checking we get an error from libcurl to stderr'
      );
    } 'Check that not following redirects causes an exception';
    Bio::DB::Big->timeout(0);
  }
};

done_testing();