# $Id: Indexer.pm,v 1.2 2003/02/02 21:20:46 matt Exp $

package AxKit::XSP::Wiki::Indexer;
use strict;
use XML::SAX::Base;
use vars qw($VERSION @ISA);
$VERSION = '1.00';
@ISA = qw(XML::SAX::Base);

sub new {
    my $class = shift;
    my (%opts) = @_;
    
    my $db = $opts{DB} || die "DB argument required";
    my $page_id = $opts{PageId} || die "PageId argument required";
    
    my $self = bless { DB => $db, PageId => $page_id }, $class;
    
    $self->{InsertCTI} = $db->prepare("INSERT INTO ContentIndex (page_id, word_id, value) VALUES (?, ?, ?)");
    $self->{InsertWord} = $db->prepare("INSERT INTO Word (word) VALUES (?)");
    $self->{InsertWord}->{PrintError} = 0;
    $self->{FindWord} = $db->prepare("SELECT id FROM Word WHERE word = ?");
    $self->{DeleteCTI} = $db->prepare("DELETE FROM ContentIndex WHERE page_id = ?");
    
    $self->{Words} = {};
    $self->{DocSize} = 0;
    
    return $self;
}

sub end_document {
    my ($self) = @_;
    
    # Delete current index for this page
    $self->{DeleteCTI}->execute($self->{PageId});
    
    for my $word (keys %{$self->{Words}}) {
        next unless $word;
        my $word_id = $self->insert_word($word);
        next unless $word_id;
warn("Indexing: $self->{PageId}, $word_id, $word\n");
        $self->{InsertCTI}->execute(
            $self->{PageId},
            $word_id,
            $self->{Words}{$word},
        );
    }
    $self->{DB}->commit;
}

sub insert_word {
    my ($self, $word) = @_;
    
    my $word_id;
    eval {
        $self->{InsertWord}->execute($word);
        $word_id = $self->{DB}->func('last_insert_rowid');
    };
    if ($@) {
        $self->{FindWord}->execute($word);
        my $row = $self->{FindWord}->fetch;
        $word_id = $row->[0];
    }
    
    return $word_id;
}

# NB: This implementation assumes SAX parsers that don't break mid-word.
# (Could use filter if this is a problem)
sub characters {
    my ($self, $node) = @_;
    
    while ($node->{Data} =~ /\G(\S*)\s*/gc) {
        my $word = $1;
        $word =~ s/\W*$//; # strip trailing non-word chars
        $word =~ s/^\W*//; # strip leading non-word chars
        $self->{Words}{lc($word)}++;
    }
}

1;
