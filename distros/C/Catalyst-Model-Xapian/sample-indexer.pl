#!/usr/bin/perl -w

# Indexer example
# retrofit to fit your data model.

use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;

use myapp::Model::DBIC;

use Search::Xapian qw(:db);
use String::Tokenizer;
use Storable;
use YAML;
use DateTime;

$ARGV[0] || die "usage: xapian-indexer.pl <xapian-indexer.cfg>";
my $config=YAML::LoadFile( $ARGV[0]) || die "Could not load specified config file";

$config->{index} ||= "$FindBin::Bin/../index";
$config->{ts_file} ||= $config->{index}.'/timestamp';
my $stemmer=Search::Xapian::Stem->new($config->{index_lang}||'english');
my $db=Search::Xapian::WritableDatabase->new( $config->{index}, DB_CREATE_OR_OPEN );

my $ts;
if ( -f $config->{ts_file} ) {
    open( CONF, $config->{ts_file} ) or die "Could not open ".$config->{ts_file}.':'.$@;
    $ts=<CONF>;
    chomp $ts;
} 
else {
    $ts=0;
}
my $now=DateTime->now->epoch;
open CONF, '>'.$config->{ts_file} or die "Could not open ".$config->{ts_file}.':'.$@;
print CONF $now;
close CONF;

my $items=myapp::Model::DBIC->resultset('Application')->search({modified=>{'>',$ts}});
while ( my $item=$items->next ) {
    my $doc=Search::Xapian::Document->new();
    $doc->set_data(
    Storable::nfreeze({
    id         => $item->id,
    name       => $item->name,
    }));
    my $termpos=0;
    $termpos=index_text($doc,$item->name,$stemmer,4,$termpos,'T');
    $termpos=index_text($doc,$item->description,$stemmer,2,$termpos);
    my $tags=$item->tags;
    while (my $tag=$tags->next) {
        $doc->add_term("T" . $tag->name );
	$doc->add_term($tag->name);
    }
    my $docid="Q".$item->id;
    $doc->add_term($docid);
    my $p=$db->postlist_begin($docid);
    unless ( $p eq $db->postlist_end($docid) ) {
        $db->replace_document($p->get_docid, $doc);
        warn('replacing '.$item->id);
    } else {
        eval {
            $db->add_document( $doc );
        };
        if ($@) {
            my $s=$doc->termlist_begin();
            while($s ne $doc->termlist_end) {
                warn "got:".$s;
                $s++;
            }
            die "oops:". $@. "\n". Dumper(Storable::thaw($doc->get_data));
        }
        warn('indexing '.$item->id) if (($item->id % 100)==0);
    }
    $db->flush if (($item->id % 100000)==0);
}


sub index_text {
    my ($doc,$text,$stemmer,$weight,$termpos,$prefix)=@_;
    return $termpos unless $text;
    #warn ("text:".$text);
    $text=~ s/\.//g;
    $text=~ s/,(?!\d)//g;
    foreach my $token ( split(/\s+/,$text) ) {
        next unless $token;
        $termpos++;
 #warn "adding :". lc($stemmer->stem_word($token)). ": at $termpos with $weight";
        $doc->add_posting(lc($token),$termpos);
        if ($prefix) {
            $doc->add_posting('T'.lc($token),$termpos);
        }
    }
    return $termpos;
}



