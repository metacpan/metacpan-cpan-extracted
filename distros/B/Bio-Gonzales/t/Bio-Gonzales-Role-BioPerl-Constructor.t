use warnings;
use Test::More;
use Data::Dumper;

BEGIN {
  eval { require Bio::Perl };

  plan( skip_all => 'Bio::Perl not installed; skipping' ) if $@;
}

package Bio::MySeq;
use Bio::Seq;

use Mouse;
use MouseX::Foreign 'Bio::Seq';
with 'Bio::Gonzales::Role::BioPerl::Constructor';

has 'my_special_id_prefix' => ( is => 'rw', default => '' );

sub my_special_id {
  my ($self) = @_;

  return $self->my_special_id_prefix . "_" . $self->display_id;
}

package main;

my $seq = Bio::MySeq->new(
  -seq                  => 'ATGGGGGTGGTGGTACCCT',
  -id                   => 'human_id',
  -accession_number     => 'AL000012',
  -my_special_id_prefix => 'jwb'
);

is( ref($seq),           'Bio::MySeq' );
is( $seq->my_special_id, 'jwb_human_id' );
is( $seq->seq,           'ATGGGGGTGGTGGTACCCT' );

$seq->my_special_id_prefix('kxc');
is( $seq->my_special_id, 'kxc_human_id' );

done_testing();

