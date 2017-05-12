#
# BioPerl module for Bio::Tools::Primer3Redux::PrimerPair
#
# Cared for by Chris Fields cjfields at bioperl dot org
#
# Copyright Chris Fields
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code


# Let the code begin...

package Bio::Tools::Primer3Redux::PrimerPair;
BEGIN {
  $Bio::Tools::Primer3Redux::PrimerPair::AUTHORITY = 'cpan:CJFIELDS';
}
BEGIN {
  $Bio::Tools::Primer3Redux::PrimerPair::VERSION = '0.09';
}

use strict;

# Object preamble - inherits from Bio::Root::Root

use base qw(Bio::SeqFeature::Generic);


sub left_primer {
    shift->forward_primer(@_);
}


sub forward_primer {
    my ($self, $primer) = @_;
    if ($primer) {
        $self->throw("Not a Primer object") unless $primer->isa('Bio:::Tools::Primer3Redux::Primer');
        $self->add_SeqFeature($primer, 'EXPAND');
    }
    my ($for) = grep {$_->primary_tag eq 'forward_primer'} $self->get_SeqFeatures;
    return $for;
}


sub right_primer { shift->reverse_primer(@_)}


sub reverse_primer {
    my ($self, $primer) = @_;
    if ($primer) {
        $self->throw("Not a Primer object") unless $primer->isa('Bio:::Tools::Primer3Redux::Primer');
        $self->add_SeqFeature($primer, 'EXPAND');
    }
    my ($rev) = grep {$_->primary_tag eq 'reverse_primer'} $self->get_SeqFeatures;
    return $rev;
}


sub internal_oligo {
    my ($self, $primer) = @_;
    if ($primer) {
        $self->throw("Not a Primer object") unless $primer->isa('Bio:::Tools::Primer3Redux::Primer');
        # Note this doesn't expand to fit; the assumption is this is added
        # after forward/reverse primers are added and acts to ensure the
        # oligo is actually internal to the fragment (otherwise it throws)
        $self->add_SeqFeature($primer);
    }
    my ($oligo) = grep {$_->primary_tag eq 'ss_oligo'} $self->get_SeqFeatures;
    return $oligo;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Bio::Tools::Primer3Redux::PrimerPair

=head1 SYNOPSIS

  # get the primer pair from the Bio::Tools::Primer3Redux::Result
  my $pair = $result->next_primer_pair;

  # grab left/right primers
  my ($fp, $rp) = ($pair->forward_primer, $pair->reverse_primer);

=head1 DESCRIPTION

Bio::Tools::Primer3Redux::PrimerPair acts as a simple SeqFeature that bundles
primer pair data together into one object.  This object can be used to retrieve
the amplicon sequence, the forward/reversion (left/right) primers, and any
internal oligos.  Furthermore, any primer information relative to the product
is included as SeqFeature tags.

=head1 NAME

Bio::Tools::Primer3Redux::PrimerPair - Simple Decorator of a
Bio::SeqFeature::Generic with convenience methods for retrieving left and
right primers, internal oligos, and any amplicon-related information

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
the web:

  http://bugzilla.open-bio.org/

=head1 AUTHOR - Chris Fields

  Email cjfields at bioperl dot org

Describe contact details here

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=head2 left_primer

 Title    : left_primer
 Note     : Alias of forward_primer()

=head2 forward_primer

 Title    : forward_primer
 Usage    : $obj->forward_primer
 Function : returns the forward (left) primer
 Returns  : Bio::Tools::Primer3Redux::Primer
 Args     : Optional Bio::Tools::Primer3Redux::Primer

=head2 right_primer

 Title    : right_primer
 Note     : alias of reverse_primer()

=head2 reverse_primer

 Title    : reverse_primer
 Usage    : $obj->reverse_primer
 Function : returns the reverse (right) primer
 Returns  : Bio::Tools::Primer3Redux::Primer
 Args     : Optional Bio::Tools::Primer3Redux::Primer

=head2 internal_oligo

 Title    : internal_oligo
 Usage    : $obj->internal_oligo
 Function : returns the internal oligo (if present)
 Returns  : Bio::Tools::Primer3Redux::Primer
 Args     : Optional Bio::Tools::Primer3Redux::Primer

=head1 AUTHOR

cjfields <cjfields@bioperl.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Fields.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

