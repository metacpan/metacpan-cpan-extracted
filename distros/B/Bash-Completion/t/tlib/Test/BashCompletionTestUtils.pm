package    ## Hide from PAUSE
  Test::BashCompletionTestUtils;

use strict;
use warnings;
use File::Temp;
use File::Spec::Functions 'catfile';
use Config;
use parent 'Exporter';

our @EXPORT = qw( create_test_cmds );


sub create_test_cmds {
  my %results;

  my $bin_dir = $results{tempdir} = File::Temp->newdir;
  $results{path} = join($Config{path_sep}, $bin_dir, $ENV{PATH});

  for my $cmd (@_) {
    my $path = catfile($bin_dir->dirname, $cmd);
    open(my $fh, '>', $path);
    next unless $fh && chmod(0755, $path);
    $results{cmd}{$cmd} = {path => $path, fh => $fh};
  }

  return \%results;
}

1;
