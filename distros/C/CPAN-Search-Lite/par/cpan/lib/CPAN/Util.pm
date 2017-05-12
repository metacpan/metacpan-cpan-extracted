package # hide from PAUSE
  CPAN::Util;
use strict;
use warnings;
require File::Spec;
use File::Which;
use constant WIN32 => $^O eq 'MSWin32';

use vars qw($VERSION @ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(has_cpan has_cpanplus download);

$VERSION = '0.01';

sub has_cpan {
  my $has_config = 0;
  if ($ENV{HOME}) {
    eval 
      {require File::Spec->catfile($ENV{HOME}, '.cpan', 
                                   'CPAN', 'MyConfig.pm');};
    $has_config = 1 unless $@;
  }
  unless ($has_config) {
    eval {require CPAN::Config;};
    my $dir;
    unless (WIN32) {
        $dir = $INC{'CPAN/Config.pm'};
    }
    $has_config = 1 unless ($@ or ($dir and not -w $dir));
  }
  return $has_config;
}

sub has_cpanplus {
  my $has_config = 0;
  eval {require CPANPLUS::Config;};
  return if $@;
  return 1 if WIN32();
  my $dir = $INC{'CPANPLUS/Config.pm'};
  my $sudo = which('sudo');
  if ($dir) {
    $has_config = $sudo ? 1 : ( (-w $dir) ? 1 : 0 );
  }
  return $has_config;
}

sub download {
  my ($cpanid, $dist_file) = @_;
  (my $fullid = $cpanid) =~ s!^(\w)(\w)(.*)!$1/$1$2/$1$2$3!;
  my $download = $fullid . '/' . $dist_file;
  return $download;
}


1;

__END__
