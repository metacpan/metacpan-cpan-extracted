#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use CGI::Tiny;
use Log::Any;
use Log::Any::Adapter
  {category => 'cgi-script'}, # only log our category here
  File => '/path/to/log/file.log',
  binmode => ':encoding(UTF-8)',
  log_level => $ENV{MYCGI_LOG_LEVEL} || 'info';

my $log = Log::Any->get_logger(category => 'cgi-script');

local $SIG{__WARN__} = sub {
  my ($warning) = @_;
  chomp $warning;
  $log->warn($warning);
};

cgi {
  my $cgi = $_;

  $cgi->set_error_handler(sub {
    my ($cgi, $error, $rendered) = @_;
    chomp $error;
    $log->error($error);
  });

  # only logged if MYCGI_LOG_LEVEL=debug set in CGI server environment
  $log->debugf('Method: %s, Path: %s, Query: %s', $cgi->method, $cgi->path, $cgi->query);

  my $number = $cgi->param('number');
  die "Excessive number\n" if abs($number) > 1000;
  my $doubled = $number * 2;
  $cgi->render(text => "Doubled: $doubled");
};
