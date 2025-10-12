package MHFS::BitTorrent::Metainfo v0.7.0;
use 5.014;
use strict;
use warnings;
use feature 'say';
use Digest::SHA qw(sha1);
use MHFS::BitTorrent::Bencoding qw(bdecode bencode);
use Data::Dumper;
use MHFS::Process;

sub Parse {
    my ($srcdata) = @_;
    my $tree = bdecode($srcdata, 0);
    return undef if(! $tree);
    return MHFS::BitTorrent::Metainfo->_new($tree->[0]);
}

sub mktor {
    my ($evp, $params, $cb) = @_;
    my $process;
    my @cmd = ('mktor', @$params);
    $process    = MHFS::Process->new_output_process($evp, \@cmd, sub {
        my ($output, $error) = @_;
        chomp $output;
        say 'mktor output: ' . $output;
        $cb->($output);
    });
    return $process;
}

sub Create {
    my ($evp, $opt, $cb) = @_;

    if((! exists $opt->{src}) || (! exists $opt->{dest_metafile}) || (! exists $opt->{tracker})) {
        say "MHFS::BitTorrent::Metainfo::Create - Invalid opts";
        $cb->(undef);
        return;
    }

    my @params;
    push @params, '-p' if($opt->{private});
    push @params, ('-o', $opt->{dest_metafile});
    push @params, $opt->{src};
    push @params, $opt->{tracker};
    print "$_ " foreach @params;
    print "\n";

    mktor($evp, \@params, $cb);
}

sub InfohashAsHex {
    my ($self) = @_;
    return uc(unpack('H*', $self->{'infohash'}));
}

sub _bdictfind {
    my ($node, $keys, $valuetype) = @_;
    NEXTKEY: foreach my $key (@{$keys}) {
        if($node->[0] ne 'd') {
            say "cannot search non dictionary";
            return undef;
        }
        for(my $i = 1; $i < scalar(@{$node}); $i+=2) {
            if($node->[$i][1] eq $key) {
                $node = $node->[$i+1];
                last NEXTKEY;
            }
        }
        say "failed to find key $key";
        return undef;
    }
    if(($valuetype) && ($node->[0] ne $valuetype)) {
        say "node has wrong type, expected $valuetype got ". $node->[0];
        return undef;
    }
    return $node;
}

sub _bdictgetkeys {
    my ($node) = @_;
    if($node->[0] ne 'd') {
        say "cannot search non dictionary";
        return undef;
    }
    my @keys;
    for(my $i = 1; $i < scalar(@{$node}); $i+=2) {
        push @keys, $node->[$i][1];
    }
    return \@keys;
}

sub _new {
    my ($class, $tree) = @_;
    my $infodata = _bdictfind($tree, ['info'], 'd');
    return undef if(! $infodata);
    my %self = (tree => $tree, 'infohash' => sha1(bencode($infodata)));
    bless \%self, $class;
    return \%self;
}

1;
