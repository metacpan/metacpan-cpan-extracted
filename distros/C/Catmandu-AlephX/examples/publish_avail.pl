#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use JSON qw(to_json);
use open qw(:std :utf8);
use Catmandu::Exporter::MARC;
use Data::Dumper;

my $aleph = Catmandu::AlephX->new(url => "http://borges1.ugent.be/X");

my $exporter = Catmandu::Exporter::MARC->new(type => 'ALEPHSEQ');

my $publish = $aleph->publish_avail(doc_num => '000196220,001313162,001484478,001484538,001317121,000000000',library=>'rug01');

#say ${ $publish->content_ref };

if($publish->is_success){

  for my $record(@{ $publish->records }){

    if($record->metadata->data->{record}){
      $exporter->add($record->metadata->data);
      $exporter->commit;
    }
    else{
      say "nothing for ".$record->metadata->data->{_id};
    }

    say "\n---";
  }
}else{
  say STDERR join('',@{$publish->errors});
}
