# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More tests => 160;
use HTTP::Headers;
use HTTP::Status qw(:constants);
use IO::Capture::Stderr;
use JSON;
use XML::XPath;
use English qw(-no_match_vars);
use Carp;

use lib qw(t/headers/lib t/lib);
use t::request;
use t::model::response;
use t::view::response;

#########
# database setup
#
no warnings qw(redefine once);
local $ENV{dev} = 'live';
unlink 't/headers/data/headers.sql3';
local *ClearPress::util::data_path = sub { return 't/headers/data'; };
my $dbh = ClearPress::util->new->dbh;
$dbh->do(q[create table response (code int primary key, name char(32))]) or croak qq[could not create table];
$dbh->commit();

my $runner = sub {
  my ($headers_ref, $content_ref, $config) = @_;

  my $response = t::request->new($config);

  my ($header_str, $content) = $response =~ m{^(.*?\n)\n(.*)$}smix;
  my $headers = HTTP::Headers->new();

  for my $line (split /\n/smx, $header_str) {
    my ($k, $v) = split m{\s*:\s*}smx, $line, 2;
    $headers->header($k, $v);
  }

  ${$headers_ref} = $headers;
  ${$content_ref} = $content;

  return 1;
};

{
  my $sets = [
	      [ '',     'text/html',        sub { my $arg=shift; return $arg;                                       } ], # plain # <p class="error">
	      [ '.js',  'application/json', sub { my $arg=shift; return JSON->new->decode($arg)->{error};           } ], # json
	      [ '.csv', 'text/csv',         sub { my $arg=shift; return [split /[\r\n]+/smix, $arg]->[0];           } ], # csv
	      [ '.xml', 'text/xml',         sub { my $arg=shift; return XML::XPath->new(xml=>$arg)->find('/error'); } ], # xml
	     ];

  my $tests = [
	       ['/t', '/no_config',    'GET', '', HTTP_NOT_FOUND,             'No such view (no_config)', 'no config'],
	       ['/t', '/no_model',     'GET', '', HTTP_INTERNAL_SERVER_ERROR, 'Failed to instantiate no_model model', 'no model'],
	       ['/t', '/response/200', 'GET', '', HTTP_OK,                    '', '200 response'], # extractors look for error blocks, so can't check "code=200" here
	       ['/t', '/response/301', 'GET', '', HTTP_MOVED_PERMANENTLY,     '', '301 redirect'],
	       ['/t', '/response/302', 'GET', '', HTTP_FOUND,                 '', '302 moved'],
	       ['/t', '/response/403', 'GET', '', HTTP_FORBIDDEN,             '', '403 forbidden'],
	       ['/t', '/response/404', 'GET', '', HTTP_NOT_FOUND,             '', '404 not found'],
	       ['/t', '/response/500', 'GET', '', HTTP_INTERNAL_SERVER_ERROR, '', '500 error'],
	       ['/t', '/response/999', 'GET', '', HTTP_INTERNAL_SERVER_ERROR, 'Application Error', '999 failure'],

	       ['/t', '/no_config',    'POST', '', HTTP_NOT_FOUND,             '', 'no config'],
	       ['/t', '/no_model',     'POST', '', HTTP_INTERNAL_SERVER_ERROR, '', 'no model'],
	       ['/t', '/response/200', 'POST', '', HTTP_OK,                    '', '200 response'], # extractors look for error blocks, so can't check "code=200" here
	       ['/t', '/response/301', 'POST', '', HTTP_MOVED_PERMANENTLY,     '', '301 redirect'],
	       ['/t', '/response/302', 'POST', '', HTTP_FOUND,                 '', '302 moved'],
	       ['/t', '/response/403', 'POST', '', HTTP_FORBIDDEN,             '', '403 forbidden'],
	       ['/t', '/response/404', 'POST', '', HTTP_NOT_FOUND,             '', '404 not found'],
	       ['/t', '/response/500', 'POST', '', HTTP_INTERNAL_SERVER_ERROR, '', '500 error'],
	       ['/t', '/response/999', 'POST', '', HTTP_INTERNAL_SERVER_ERROR, 'Application Error', '999 failure'], # update non-existent entity
	      ];

  my $skips = [
               ['GET',  '/no_config.csv'    ],
               ['GET',  '/no_model.csv'     ],
               ['GET',  '/response/999.csv' ],
               ['POST', '/response/999.csv' ],
              ];
  for my $set (@{$sets}) {
    my ($extension, $content_type, $extraction) = @{$set};

    for my $t (@{$tests}) {

      my ($script_name, $path_info, $method, $username, $status, $errstr, $msg) = @{$t};
      $path_info .= $extension;

      my $cap = IO::Capture::Stderr->new;
      $cap->start;
      my ($headers, $content);
      $runner->(\$headers, \$content,
		{
		 SCRIPT_NAME    => $script_name,
		 PATH_INFO      => $path_info,
		 REQUEST_METHOD => $method,
		 username       => $username,
		 cgi_params     => {
				    name => 'value',
				   },
		});
      $cap->stop;

      my $ct_header = $headers->header('Content-Type') || q[];
      my ($charset) = $ct_header =~ m{\s*;\s*charset\s*=\S*(.*)$}smix;
      $ct_header    =~ s{\s*;\s*charset\s*=\S*.*$}{}smix;

      is($headers->header('Status'), $status,       "$method $script_name$path_info status $status [$msg]");
      is($ct_header,                 $content_type, "$method $script_name$path_info content_type $content_type [$msg]");

      if($errstr) {
        $errstr =~ s{([ ()])}{\[$1\]}smxg;
        my $str;
        eval {
          $str = $extraction->($content);
          1;

        } or do {
          diag("failed to extract content: $EVAL_ERROR", "headers=".$headers->as_string, "content=".$content);
        };

      SKIP: {
          for my $skip (@{$skips}) {
            if ($method    eq $skip->[0] &&
                $path_info eq $skip->[1]) {
              skip "$method $path_info : @{$t}", 1;
            }
          }

          like($str, qr{$errstr}smx, "$method $script_name$path_info content matches '$errstr'");
        }
      }

#      diag $content;
#      diag $cap->read();
#      diag "HEADERS=".$headers->as_string;
    }
  }
}
