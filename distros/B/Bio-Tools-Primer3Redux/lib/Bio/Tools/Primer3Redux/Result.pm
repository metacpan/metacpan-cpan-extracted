# $Id: Result.pm,v 0.01 2007-03-27 12:43:27 heikki Exp $
#
# BioPerl module for Bio::Tools::Primer3Redux::Result
#
# Cared for by Chris Fields cjfields at bioperl dot org
#
# Copyright Chris Fields
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code


# Let the code begin...

package Bio::Tools::Primer3Redux::Result;
BEGIN {
  $Bio::Tools::Primer3Redux::Result::AUTHORITY = 'cpan:CJFIELDS';
}
BEGIN {
  $Bio::Tools::Primer3Redux::Result::VERSION = '0.09';
}

use strict;
use warnings;

use base qw(Bio::Root::Root);

use Bio::Seq;
use Bio::Tools::Primer3Redux::Primer;
use Bio::Tools::Primer3Redux::PrimerPair;
use Data::Dumper;
use Scalar::Util qw(reftype blessed);


sub _initialize {
    my ($self) = shift;
    my %args;
    ($self->{sequence_data},
     $self->{feature_data},
     $self->{persistent_data},
     $self->{run_parameters}) =
        $self->_rearrange([qw(SEQ FEATURES PERSISTENT PARAMETERS)], @_);
}


sub attach_seq {
    my ($self) = shift;
    if (@_) {
        my $seq = shift;
        if (defined $seq) {
            $self->throw("Passed sequence must be a Bio::SeqI")
                unless ( ref $seq && $seq->isa('Bio::SeqI') );
        }
        # this allows resetting seq() to use built-in report sequence
        $self->{using_seq} = $seq;
        $self->{reattach_sf} = 1;
    }
}


sub get_seq {
    my $self = shift;
    if (defined $self->{using_seq}) {
        return $self->{using_seq}
    } else {
        if (!defined $self->{default_seq}) {
            $self->{default_seq} = $self->_create_default_seq;
        }
        return $self->{default_seq}
    }
}


sub get_processed_seq {
    my ($self) = shift;
    # Run through all iterators to generate features
    # Run out primer pair first, then others
    for my $it_type (qw(PAIR LEFT RIGHT INTERNAL)) {
        my $it = $self->_generate_iterator($it_type);
        while (my $sf = $it->($self)) {}
    }
    return $self->get_seq();
}


sub num_primer_pairs {
    my $self = shift;
    exists($self->{persistent_data}{PAIR}{num_returned})  ?
        return $self->{persistent_data}{PAIR}{num_returned} : 0;
}


sub next_left_primer {
    my ($self, @args) = @_;
    if (!exists $self->{it}->{left} || !defined $self->{it}->{left}) {
        $self->{it}->{left} = $self->_generate_iterator('left',@args);
    }
    $self->{it}->{left}->($self);
}


sub next_right_primer {
    my ($self, @args) = @_;
    if (!exists $self->{it}->{right} || !defined $self->{it}->{right}) {
        $self->{it}->{right} = $self->_generate_iterator('right',@args);
    }
    $self->{it}->{right}->($self);
}


sub next_internal_oligo {
    my ($self, @args) = @_;
    if (!exists $self->{it}->{internal} || !defined $self->{it}->{internal}) {
        $self->{it}->{internal} = $self->_generate_iterator('internal',@args);
    }
    $self->{it}->{internal}->($self);
}


sub next_primer_pair {
    my ($self, @args) = @_;
    if (!exists $self->{it}->{pair} || !defined $self->{it}->{pair}) {
        $self->{it}->{pair} = $self->_generate_iterator('pair',@args);
    }
    $self->{it}->{pair}->($self);
}


sub persistent_data {
    my ($self, @params) = @_;
    return $self->{persistent_data};
}


sub run_parameters {
    my ($self, @params) = @_;
    my %params;
    if (@params) {
        %params =
            map {
                $_ => $self->{run_parameters}->{$_}
                }
            grep {
                exists $self->{run_parameters}->{$_}
                } @params;
    } else {
        %params = %{$self->{run_parameters}};
    }
    return %params;
}


sub run_parameter {
    my ($self, $param) = @_;
    return unless defined $param && exists $self->{run_parameters}->{$param};
    return $self->{run_parameters}->{$param};
}



sub warnings {
  my $self = shift;
  my $warning_value = $self->run_parameter('PRIMER_WARNING') || '';
  return split(/;\s*/, $warning_value);
} # warnings


sub errors {
  my $self = shift;
  my $error_value = $self->run_parameter('PRIMER_ERROR') || '';
  return split(/;\s*/, $error_value);
} # errors


sub rewind {
    my ($self, $it_type) = @_;
    return unless defined $it_type;
    if (exists $self->{it}->{$it_type}) {
        delete $self->{it}->{$it_type};
    }
    return;
}

################ PRIVATE STUFF ################

{
my %VALID_ITERATORS = (
    PAIR        => \&_generate_pair,
    INTERNAL    => \&_generate_primer,
    LEFT        => \&_generate_primer,
    RIGHT       => \&_generate_primer,
    );

sub _generate_iterator {
    my ($self, $it_type, @args) = @_;
    $self->throw("Must define a valid iterator; current allowed values are ".
        join(',', sort keys %VALID_ITERATORS)) unless
        (defined $it_type || !exists $VALID_ITERATORS{uc $it_type});
    $it_type = uc $it_type;

    my $mth = $VALID_ITERATORS{$it_type};

    my $persistent_data = $self->{persistent_data}{$it_type};
    my @feat_data = ($it_type eq 'PAIR') ?
        map {$self->{feature_data}{$_}}           sort {$a <=> $b} keys %{$self->{feature_data}} :
        map {$self->{feature_data}{$_}{$it_type}} sort {$a <=> $b} keys %{$self->{feature_data}};
    my $ct = 0;

    # for attaching the features
    my $seq = $self->get_seq;

    return ($it_type eq 'PAIR') ?
        sub {
            my $instance = shift;
            my $ft = shift @feat_data;
            return unless $ft;
            # return cached features if previously generated and seq already attached
            return $ft->{PAIR} if (blessed $ft->{PAIR} && $ft->{PAIR}->isa('Bio::SeqFeature::Generic')
                && !$self->{reattach_sf});

            # carry over persistent data
            for my $fkey (keys %{$ft}) {
                $ft->{$fkey}{rank} = $ct;
                $ft->{$fkey}{type} = lc $fkey;
                for my $pkey (keys %{$persistent_data}) {
                    $ft->{$fkey}{$pkey} = $persistent_data->{$pkey};
                }
            }
            my $sf = $mth->($ft,$seq,$instance);
            # run caching here
            $ct++;
            $sf;
        } :
        sub {
            my $instance = shift;
            # these are tags
            my $ft = shift @feat_data;
            return unless $ft;
            # return cached features if previously generated and seq already attached
            if (blessed $ft && $ft->isa('Bio::SeqFeature::Generic') && !$self->{reattach_sf}) {
                $ct++;
                return $ft;
            }

            # carry over persistent data
            for my $key (keys %{$persistent_data}) {
                $ft->{$key} = $persistent_data->{$key};
            }

            $ft->{rank} = $ct;
            $ft->{type} = lc $it_type;
            my $sf = $mth->($ft, $seq, $instance);
            $ct++;
            $sf;
        }
}

}

sub _generate_primer {
    my ($ft, $seq, $instance) = @_;
    my ($type, $loc) = (delete($ft->{type}), delete($ft->{location}));

    # TODO: There is data showing up here that doesn't have locations, traceback
    if (!defined($loc)) {
        #print STDERR (caller(1))[3].":".Dumper $ft;
        return ;
    }

    my $rank = $ft->{rank};
    my $strand = $type eq 'right' ? -1 : 1;
    my ($start, $len) = split(',', $loc);
    # coordinates for Primer3 may be zero-based, may need conversion to 1-based
    if (!$instance->run_parameter('PRIMER_FIRST_BASE_INDEX')) {
        $start++
    }
    my $end = ($strand == 1) ? $start + $len -1 : $start - $len + 1;
    ($start, $end) = ($end, $start) if $strand == -1;
    my $primary = $type eq 'internal' ? 'ss_oligo'       :
                  $type eq 'left'     ? 'forward_primer' :
                  'reverse_primer' ;
    my $sf = Bio::Tools::Primer3Redux::Primer->new(-start       => $start,
                                                  -end          => $end,
                                                  -strand       => $strand,
                                                  -display_name => $type.'_'.$rank,
                                                  -primary_tag  => $primary,
                                                  -tag          => $ft);
    $seq->add_SeqFeature($sf) if ($seq && blessed $seq && $seq->isa('Bio::SeqI'));

    # cache Primer
    $instance->{feature_data}{$rank}{uc $type} = $sf;
    $sf;
}

sub _generate_pair {
    my ($ft, $seq, $instance) = @_;
    # some combinations of parameters do not return proper pairings,
    # so punt and return
    return if (!exists $ft->{PAIR} ||
               !exists $ft->{PAIR}->{num_returned} ||
               $ft->{PAIR}->{num_returned} == 0);

    my $pair = delete $ft->{PAIR};
    my $rank = $pair->{rank};

    $pair = Bio::Tools::Primer3Redux::PrimerPair->new(-tag => $pair);

    for my $type (sort keys %$ft) {
        my $sf = _generate_primer($ft->{$type}, $seq, $instance);
        $pair->add_SeqFeature($sf, 'EXPAND');
    }
    $seq->add_SeqFeature($pair) if ($seq && blessed $seq && $seq->isa('Bio::SeqI'));
    # cache PrimerPair
    $instance->{feature_data}{$rank}{PAIR} = $pair;
    return $pair;
}

# a fallback Bio::SeqI in case the parser is called directly (not from the
# wrapper)
# This is also needed to construct a "dummy" sequence in case there is no
# SEQUENCE_TEMPLATE, which is legal when running a "check_priemrs" task.
# In this case, we make a dummy sequence that contains the given primers
# separated with Ns to match the product length.
sub _create_default_seq {
    my $self = shift;

    my $seq = $self->{sequence_data}{SEQUENCE_TEMPLATE} ||
                $self->{sequence_data}{SEQUENCE} ||
                $self->_dummy_seq_template_from_primers;
    my $acc = $self->{sequence_data}{SEQUENCE_ID} ||
                $self->{sequence_data}{PRIMER_SEQUENCE_ID} ||
                'ACC';

    return Bio::Seq->new(
      -seq => $seq,
      -accession_number => $acc,
      -alphabet => 'dna'
    );
}

# Generate a dummy sequence based on the given primers and product size
# in case no SEQUENCE_TEPLATE is set, in which case we should have primer seqs
# The sequence consists of Ns with the forard, reverse and internal oligo
# inserted at the beginning, end and middle. The returned sequence will
# always be 200bp long (primer3 default).
# TODO: is it safe to assume 200bp here?
sub _dummy_seq_template_from_primers{
  my $self = shift;
  my $prod_length = 200;

  my $seq = 'N' x $prod_length;
  my $fp = $self->{run_parameters}{SEQUENCE_PRIMER};
  if ($fp){
    substr( $seq, 0, length($fp)) = $fp;
  }
  my $ip = $self->{run_parameters}{SEQUENCE_INTERNAL_OLIGO};
  # If we have an internal oligo, just put it in the middle.
  # This might fail if $seq is actually shorter
  if( $ip ){
    substr( $seq, int(length($seq)/2), length($ip)) = $ip;
  }

  my $rp = $self->{run_parameters}{SEQUENCE_PRIMER_REVCOMP};
  if ($rp){
    my $rp_revcom = Bio::Seq->new(-seq=>$rp)->primary_seq->revcom->seq;
    substr( $seq, -1 * length($rp)) = $rp_revcom;
  }
  return $seq;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Bio::Tools::Primer3Redux::Result

=head1 SYNOPSIS

    # parse a Primer3 report, and get Bio::Tools::Primer3Redux::Result
    while (my $result = $parser->next_result) {
        (say "primer design failed" and next) if $result->errors;

        say $result->num_primer_pairs;
        my $pair = $result->next_primer_pair;

        my ($fp, $rp) = ($pair->forward_primer, $pair->reverse_primer);

        say $fp->seq->seq;
        say $rp->seq->seq;
    }

=head1 DESCRIPTION

This is a simple holder class for Primer3 sequence results. The sequence used by
default is the one returned in the Primer3 results, but one can pass in a
(more-SeqFeature/Annotation-rich) version as a Bio::Seq using attach_seq() (see
below for more on this).

This parser will attach any lazily-generated features to that Bio::Seq object.
The sequence can be retrieved via get_seq() at any point, such as prior to
the end of a parse). To retrieve a sequence guaranteed to have all
Primer/PrimerPair data attached, use get_processed_seq(). Switching seqs will
cause a new batch of features to be generated and attached.

Please note that primer3 does not terminate on errors during primer design
(e.g. due to input parameters that are impossible to fulfill).
To check if errors or warnings were produced, it is recommended to always
check the result object for errors like so:

  if ($result->errors){
    # handle the situation
  }

=head1 NAME

Bio::Tools::Primer3Redux::Result - Result class for Primer3 data

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

Nathan Hillson

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=head2 new

 Title   : new
 Usage   : my $obj = new
 Function: Builds a new Bio::Tools::Primer3::Result object
 Returns : an instance of Bio::Tools::Primer3::Result
 Args    :

=head2 attach_seq

 Title    : attach_seq
 Usage    : $obj->attach_seq
 Function :
 Returns  : Bio::SeqI
 Args     : Bio::SeqI (warning: may or may not have primers attached)
 Note     : calling this method resets the feature iterators to prevent (for
            instance) issues with references

=head2 get_seq

 Title    : get_seq
 Usage    : $obj->get_seq
 Function :
 Returns  :
 Args     :

=head2 get_processed_seq

 Title    : get_processed_seq
 Usage    : $obj->get_processed_seq
 Function :
 Returns  :
 Args     :
 Note     : unlike get_seq(), this guarantees getting back the full
            sequence with attached Primer/PrimerPair SeqFeatureI

=head2 num_primer_pairs

 Title    : num_primer_pairs
 Usage    : $obj->num_primer_pairs
 Function :
 Returns  :
 Args     :

=head2 next_left_primer

 Title    : next_left_primer
 Usage    : $obj->next_left_primer
 Function :
 Returns  :
 Args     :

=head2 next_right_primer

 Title    : next_right_primer
 Usage    : $obj->next_right_primer
 Function :
 Returns  :
 Args     :

=head2 next_internal_oligo

 Title    : next_internal_oligo
 Usage    : $obj->next_internal_oligo
 Function :
 Returns  :
 Args     :

=head2 next_primer_pair

 Title    : next_primer_pair
 Usage    : $obj->next_primer_pair
 Function :
 Returns  :
 Args     :

=head2 persistent_data

 Title    : persistent_data
 Usage    : $obj->persistent_data
 Function :
 Returns  :
 Args     :

=head2 run_parameters

 Title    : run_parameters
 Usage    : $obj->run_parameters
 Function :
 Returns  :
 Args     :

=head2 run_parameter

 Title    : run_parameter
 Usage    : $obj->run_parameter('FOO')
 Function :
 Returns  :
 Args     :

=head2 warnings

 Title   : warnings
 Function: returns a list of the warning messages returned by primer3, if any
 Usage   : my @warnings = $obj->warnings;
 Args    : none
 Returns : Array of messages

=head2 errors

 Title   : errors
 Function: returns a list of the error messages returned by primer3, if any
 Usage   : my @errors = $obj->errors;
 Args    : none
 Returns : Array of messages

=head2 rewind

 Title    : rewind
 Usage    : $obj->rewind('primer_pair')
 Function :
 Returns  :
 Args     :

=head1 AUTHOR

cjfields <cjfields@bioperl.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Fields.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

