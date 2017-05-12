# $Id: gff3_to_chaos.pm,v 1.1 2003/07/23 04:50:24 cjm Exp $
# BioPerl module for Bio::Parser::gff3_to_chaos
#
# cjm
#
# POD documentation - main docs before the code

=head1 NAME

Bio::Parser::gff3_to_chaos

=head1 SYNOPSIS

Do not use this module directly.

=head1 DESCRIPTION

=head1 FEEDBACK

=head1 AUTHORS - Chris Mungall

Email: cjm@fruitfly.org

=cut

# Let the code begin...

package Bio::Chaos::Handler::gff3_to_chaos;
use Bio::Chaos::FeatureUtil qw(:all);
use Data::Stag qw(:all);
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Object

use base qw(Bio::Chaos::Handler::base_handler);

sub EMITS {
    qw(feature
       feature_relationship)
}

sub CONSUMES {
    qw(gffblock);
}

sub e_gffblock {
    my ($self, $block) = @_;
    my @gff_fl = stag_get($block,'gff_feature');
    my @fl = ();
    my %type_by_id = ();
    my @events = ();
    for (my $i=0; $i<@gff_fl; $i++) {
        my $gf = $gff_fl[$i];
        my @subfeatures = ();
        my $source = stag_sget($gf,'source');
        my $attr_line = stag_sget($gf,'attr_line');

        my $type = stag_sget($gf,'type');

        my $j = $i;
        my $extent_start = stag_sget($gf,'start');
        my $extent_end;
        my $seqid;
        my $strand;
        my $stype;

        # iterate through contiguous chunk of same feature;
        # make subfeatures
        while (my $nf = $gff_fl[$j]) {
            if ($j > $i && !$attr_line) {
                last;
            }
            if (stag_sget($nf,'attr_line') ne $attr_line) {
                last;
            }
            $extent_end = stag_sget($gf,'end');
            $j++;
            my ($start,$end);
            ($start,$end,$seqid) =
              (stag_sget($nf,'start'),
               stag_sget($nf,'end'),
               stag_sget($nf,'seqid'));
            my ($nb,$ne);
            ($nb,$ne,$strand) =
              bcmm2ibv($start,
                       $end,
                       stag_sget($nf,'strand'));
            my $phase = stag_sget($nf,'phase');
            $stype = _get_subtype($type);
            my $subid = _make_id($seqid,$start,$end,$stype);
            push(@subfeatures,
                 [feature=>[[feature_id=>$subid],
                            [uniquename=>$subid],
                            [name=>$subid],
                            [featureprop=>[
                                           [type=>'source'],
                                           [value=>$source]]],
                            [featureloc=>[
                                          [srcfeature_id=>$seqid],
                                          [nbeg=>$nb],
                                          [nend=>$ne],
                                          [strand=>$strand],
                                          (defined $phase ? [phase=>$phase] : ()),
                                         ]
                            ]]]);
        }
        # skip ahead past contiguous feature block
        $i = $j-1;

        my $id = stag_sget($gf,'id');
        if (!$id) {
            $id =
              _make_id($seqid,$extent_start,$extent_end,$type);
        }

        my $floc;
        my @frs = ();
        if ($type eq $stype && @subfeatures == 1) {
            # do not split feature into subfeatures
            my $subf = shift @subfeatures;
            $floc = stag_sget($subf,'featureloc');
        }
        else {
            # keep floc split into subfeatures
            if ($stype eq $type) {
                $stype = "part_of-$type";
            }

            my ($nb,$ne) =
              bcmm2ibv($extent_start,
                       $extent_end,
                       $strand);
            $floc =
              [featureloc=>[
                            [srcfeature_id=>$seqid],
                            [nbeg=>$nb],
                            [nend=>$ne],
                            [strand=>$strand]]];
            push(@frs,
                 map {
                     [feature_relationship=>[[subject_id=>$id],
                                             [object_id=>stag_sget($_,'feature_id')],
                                             [type=>'part_of']]]
                 } @subfeatures);
        }
        my @fprops = ();
        foreach my $attr (stag_get($gf,'attr')) {
            my $tag = stag_sget($gf,'tag');
            foreach (stag_get($gf,'val')) {
                push(@fprops,
                     [featureprop=>[[type=>$tag],
                                    [value=>$_]]]);
            }
        }
        my $cf = Data::Stag->new(feature=>[
                                           [feature_id=>$id],
                                           [uniquename=>$id],
                                           [type=>$type],
                                           $floc,
                                           @fprops,
                                          ]);
        my @parents = stag_get($gf,'parent');
        foreach my $p (@parents) {
            my $rtype = 'part_of';
            push(@frs,
                 Data::Stag->new(feature_relationship=>[
                                                        [subject_id=>$id],
                                                        [object_id=>$p],
                                                        [type=>$rtype],
                                                       ]));
        }
        push(@events,$cf,@subfeatures,@frs);
    }
    return @events;
}

sub _make_id {
    my ($seqid,$start,$end,$type) = @_;
    return "$seqid:$type:$start-$end";
}

sub gffsafe {
    my $w = shift;
    return '.' unless $w;
    $w =~ s/ /\+/g;
    $w;
}

sub _get_subtype {
    my $type = shift;
    if ($type =~ /RNA/) {
        return 'exon';
    }
    return $type;
}


1;
