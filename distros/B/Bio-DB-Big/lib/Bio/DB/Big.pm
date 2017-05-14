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

package Bio::DB::Big;

=head1 NAME

Bio::DB::Big -- Read files using bigWigLib including BigBED and BigWig

=head1 SYNOPSIS

=cut


$Bio::DB::Big::VERSION = '1.0.0';

use strict;
use warnings;

use base 'DynaLoader';
bootstrap Bio::DB::Big;

sub open {
  my ($self, $filename) = @_;
  my $is_bw = Bio::DB::Big::File->test_big_wig($filename);
  if($is_bw) {
    return Bio::DB::Big::File->open_big_wig($filename);
  }
  return Bio::DB::Big::File->open_big_bed($filename);
}

package Bio::DB::Big::File;

use Bio::DB::Big::AutoSQL;

sub get_autosql {
  my ($self) = @_;
  my $as = $self->get_autosql_string();
  return if ! $as;
  return Bio::DB::Big::AutoSQL->new($as);
}

1;