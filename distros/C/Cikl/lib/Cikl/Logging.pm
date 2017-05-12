package Cikl::Logging;
use strict;
use warnings;
require Log::Log4perl;
use Log::Log4perl::Level;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw/get_logger/;

Log::Log4perl->easy_init({
    level => 'ERROR',
    category => "",
    layout => "[%p][%d{yyyy-MM-dd'T'HH:mm:ss}Z][%F{1}:%L]: %m%n"
  });

$Log::Log4perl::DateFormat::GMTIME = 1;

sub get_logger {
  my $category = shift || "";
  return Log::Log4perl->get_logger($category);
}
