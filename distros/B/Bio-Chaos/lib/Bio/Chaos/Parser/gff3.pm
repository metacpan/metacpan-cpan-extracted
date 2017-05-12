# $Id: gff3.pm,v 1.2 2003/07/23 04:50:19 cjm Exp $
# BioPerl module for Bio::Parser::gff3
#
# cjm
#
# POD documentation - main docs before the code

=head1 NAME

Bio::Parser::gff3 - gff sequence input/output stream

=head1 SYNOPSIS

Do not use this module directly.  Use it via the Bio::Parser class.

=head1 DESCRIPTION

=head1 FEEDBACK


=head1 AUTHORS - Chris Mungall

Email: cjm@fruitfly.org


=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::Chaos::Parser::gff3;
use vars qw(@ISA);
use strict;
# Object preamble - inherits from Bio::Root::Object

#use Bio::Chaos::Parser
use base qw(Bio::Chaos::Parser::base_parser);

our @COLUMNS =
  qw(
     seqid source type start end score strand phase attributes
    );

sub _initialize {
    my($self,@args) = @_;
    $self->SUPER::_initialize(@args);  
}

sub post_parse {
    my $self = shift;
    $self->end_event("gffblock")
      if $self->{inblock};
    $self->SUPER::post_parse(@_);
}

our @DEFINED_TAGS = qw(ID Align Parent Target Align);
our %DEFINED_TAGH = map {$_ => 1} @DEFINED_TAGS;

sub record_tag {'gffset'}

sub locregexp {
    '(\S+)[\:|\s](\d+)[\.\.|\s](\d+)'
}

sub parseloc {
    my $loc = shift;
    my $locregexp = locregexp();
    if ($loc =~ /$locregexp/) {
        return
        [
         [seqid=>$1],
         [start=>$2],
         [end=>$3],
        ];
    }
    else {
        die;
    }
}

sub next_record {
    my $self = shift;

    $self->start_event("gffblock")
      unless $self->{inblock};
    $self->{inblock} = 1;
    my $line;
    my $last;
    my $ok = 1;
    my $locregexp = locregexp();
    while ($ok) {
        $line = $self->_readline;
        if (!$line) {
            $last = 1;
            last;
        }
        chomp $line;
        if ($line =~ /^\#\#\#/) {
            $self->end_event("gffblock")
              if $self->{inblock};
            $self->{inblock} = 0;
            last;
        }
        elsif ($line =~ /^\#\#gff-version\s+(\d+)/i) {
            $self->event(gff_version => $1);
            next;
        }
        elsif ($line =~ /^\#\#sequence-region\s+($locregexp)/) {
            $self->event(sequence_region => parseloc($1));
            next;
        }
        elsif ($line =~ /^\#\#FASTA/ || $line =~ /^\>/) {
	    if ($line =~ /^\>/) {
		$self->_pushback;
	    }
	    $self->start_event("fastaseqset");
	    $self->load_module("Bio::Chaos::Parser::fasta");
	    while(Bio::Chaos::Parser::fasta::next_record($self)) {
	    }
	    $self->end_event("fastaseqset");
            next;
        }
        elsif ($line =~ /^\#\#(\w+)\s(.*)/) {
            $self->event($1 => $2);
            next;
        }
        elsif ($line =~ /^\#\#(.*)/) {
            $self->event($1 => 1);
            next;
        }
        else {
        }
        $ok = 0;
        $line =~ s/^\#.*//;
        next unless $line;

        my @colvals = split(/\t/, $line);

        $self->start_event("gff_feature");
        foreach (@COLUMNS) {
            my $v = shift @colvals;
            $v = '' unless defined $v;
            if (/^attributes$/) {
                $self->event(attr_line => $v);
                # handle group parsing
#                $v =~ s/\\;/$;/g; # protect embedded semicolons in the group
#                $v =~ s/( \"[^\"]*);([^\"]*\")/$1$;$2/g;
                my @attrs = split(/;/,$v);
                foreach (@attrs) {
                    if (!$_) {
                        $self->warn("Empty attribute in: $v");                        
                        next;
                    }
                    # unescape URL chars
#                    s//;/g;
                    my ($tag, $val) = split(/\=/, $_);
                    if (!defined($val)) {
                        $self->warn("Incorrect attribute: $_");
                        $val = $tag;
                        $tag = "Unparsed";
                    }
                    my @vals = split(/\,/, $val);
                    if ($DEFINED_TAGH{$tag}) {
                        foreach my $val (@vals) {
                            if ($tag eq 'Target') {
                                $self->event(target =>
                                             parseloc($val))
                            }
                            else {
                                $self->event(lc($tag)=>$val);
                            }
                        }
                    }
                    else {
                        $self->event(attr => [
                                              [tag=>$tag],
                                              map { [val=>$_] } @vals
                                             ]);
                    }
                }
            } else {
                $self->event($_ => $v)
                  unless $v eq '.';
            }
        }
        $self->end_event("gff_feature");
#        $attr->add(@$f) if $ok;
    }

    #    $self->event(@$attr);
#    $self->end_event("gffblock");
    return !$last;
}

1;
