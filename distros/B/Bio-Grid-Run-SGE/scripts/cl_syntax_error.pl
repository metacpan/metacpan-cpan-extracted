#!/usr/bin/env perl

use warnings;
use strict;

use Carp;
use Data::Dumper;

use Bio::Grid::Run::SGE;
use Bio::Gonzales::Util::Cerial;

use File::Spec;

run_job(
  {
    task => sub {
      my ( $c, $result_prefix, $idx_item ) = @_;

      INFO "Running $idx_item->[0] -> $result_prefix";
      jspew( $result_prefix . ".env.json",  \%ENV );
      jspew( $result_prefix . ".item.json", $idx_item );
      sleep 1;
      function_that_does_not_exist();

    },
    post_task => sub {
      my $c = shift;
      open my $fh, '>', File::Spec->catfile( $c->{result_dir}, 'finished' )
        or die "Can't open filehandle: $!";
      say $fh $c->{job_id};
      $fh->close;
    },
    usage => \&usage,
  }
);

sub usage {
  return <<EOF;
The script takes an list like index, prints element(s) to <result_prefix>.item.json.
Additionally, the current environment will be stored in <result_prefix>.env.json.

EXAMPLE CONFIG:
  ---
  input:
  - elements:
    - a
    - b
    - c
    - d
    - e
    - f
    format: List
  job_name: <job_name>
  mode: Consecutive
EOF

}

1;
