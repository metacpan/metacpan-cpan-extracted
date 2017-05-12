# $Id: fasta.pm,v 1.4 2004/03/08 21:45:49 cjm Exp $
# BioPerl module for Bio::Chaos::Parser::fasta
#
# cjm
#
# POD documentation - main docs before the code

=head1 NAME

Bio::Chaos::Parser::fasta - fasta sequence input/output stream

=head1 SYNOPSIS

Do not use this module directly.  Use it via the Bio::Chaos::Parser class.

=head1 DESCRIPTION

generates events with this schema:

  (fastaseqset
   (fastaseq*
    (header "str")
    (residues "str")
    (seqlen "int")))

=head1 FEEDBACK


=head1 AUTHORS - Chris Mungall

Email: cjm AT fruitfly DOT org


=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::Chaos::Parser::fasta;
use vars qw(@ISA);
use strict;
# Object preamble - inherits from Bio::Root::Object

#use Bio::Chaos::Parser;

use base qw(Bio::Chaos::Parser::base_parser);

sub _initialize {
    my($self,@args) = @_;
    $self->SUPER::_initialize(@args);  
}

sub record_tag {'fastaseqset'}

sub next_record {
    my $self = shift;

    my $hdr = $self->_readline;
    return unless $hdr;

    $hdr =~ s/^\>//;

    $self->start_event('fastaseq');
    $self->event(header => $hdr);
    my ($id, $desc);
    if ($hdr =~ /(\S+)\s+(.*)/) {
	($id, $desc) = ($1, $2);
	$self->event(id => $id);
	$self->event(desc => $desc);
	my ($F1, $v1, $F2, $v2full, $v2) = split(/\|/, $id);
	if (defined $v1) {
	    $self->event($F1 => $v1);
	    if (defined $v2full) {
		$self->event($F2->$v2full);
	    }
	    if (defined $v2) {
		$self->event(symbol => $v2);
	    }
	}
    }

    my $seq = "";
    while ($_ = $self->_readline) {
        chomp;
        if (/^\>/) {
            $self->_pushback($_);
            last;
        }
        $seq .= $_;
    }
    $self->event(residues => $seq);
    $self->event(seqlen => length($seq));
    $self->end_event('fastaseq');

    return 1;
}

1;
