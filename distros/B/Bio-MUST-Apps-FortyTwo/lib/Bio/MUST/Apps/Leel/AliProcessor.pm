package Bio::MUST::Apps::Leel::AliProcessor;
# ABSTRACT: Internal class for leel tool
$Bio::MUST::Apps::Leel::AliProcessor::VERSION = '0.210570';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments -ENV;

use Carp;
use File::Basename;
use List::AllUtils 'uniq';
use Path::Class qw(file);
use Test::Deep::NoTest 'eq_deeply';

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(:filenames secure_outfile);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::GeneticCode::Factory';
use aliased 'Bio::MUST::Apps::SlaveAligner::Local';
use aliased 'Bio::MUST::Apps::Leel::OrgProcessor';

with 'Bio::MUST::Apps::Roles::AliProcable';


has 'run_proc' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Apps::Leel::RunProcessor',
    required => 1,
);


has '+ali' => (
    handles  => {
        protein_for => 'get_seq_with_id',
    },
);


has 'cds_ali' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_cds_ali',
);


## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_cds_ali {
    return Ali->new( file => shift->ali->filename );
}


sub _build_integrator {
    return Local->new( ali => shift->cds_ali );
}

## use critic


sub _check_ali_by_translation {
    my $self = shift;

    my $rp = $self->run_proc;

    # build genetic codes for all orgs
    # Note: we uses the raw config file to fetch code ids...
    # ... if code ids are not specified behavior is not defined
    # ... (because the code attribute default has yet been triggered)
    my $gc_fac = Factory->new;
    my %code_for = map {
        $_->{org} => $gc_fac->code_for( $_->{code} )
    } $rp->all_orgs;

    # translate aligned transcripts to aligned proteins (using right code)...
    # ... sort seqs according to full_id...
    # ... and uniformize gap/missing chars
    my $cds_ali = $self->cds_ali;
    my @got_seqs = sort { $a->full_id cmp $b->full_id } map {
        $code_for{ $_->full_org }->translate($_, 1)->gapify
    } $cds_ali->all_seqs;

    # fetch original proteins
    my $ali = $self->ali;
    my @exp_seqs = sort { $a->full_id cmp $b->full_id } map {
                                                 $_->gapify
    }     $ali->all_seqs;

    # build uniformized versions of translated and original Alis
    my $got_ali = Ali->new( seqs => \@got_seqs )->uniformize;
    my $exp_ali = Ali->new( seqs => \@exp_seqs )->uniformize;

    # check congruence between translated and original Alis
    unless (eq_deeply $got_ali, $exp_ali) {
        carp '[ALI] Warning: round-trip check failed;'
            . ' writing -got and -exp files!';

        # build ALI outfile honoring out_dir and out_suffix
        # TODO: try to avoid code duplication here?
        my $cds_ali = $self->cds_ali;
        my $outfile = $cds_ali->filename;
           $outfile = file( $rp->out_dir, basename($outfile) ) if $rp->out_dir;

        $got_ali->store( secure_outfile($outfile, '-got') );
        $exp_ali->store( secure_outfile($outfile, '-exp') );
    }

    return;
}


sub BUILD {
    my $self = shift;

    my $rp = $self->run_proc;

    my $ali = $self->ali;
    #### [ALI] #seqs: $ali->count_seqs
    unless ($ali->count_seqs) {
        #### [ALI] empty file; skipping!
        return;
    }

    for my $org ($rp->all_orgs) {
        #### [ALI] Processing ORG: $org->{org}
        OrgProcessor->new( ali_proc => $self, %{$org} );
    }

    unless ($rp eq 'off') {
        #### [ALI] Making delayed indels...
        $self->integrator->make_indels;

        if ($rp->round_trip_mode eq 'on') {
            #### [ALI] Retranslating nucleotide sequences...
            $self->_check_ali_by_translation;
        }
    }

    # build ALI outfile honoring out_dir and out_suffix
    my $cds_ali = $self->cds_ali;
    my $outfile = insert_suffix($cds_ali->filename, $rp->out_suffix);
       $outfile = file( $rp->out_dir, basename($outfile) ) if $rp->out_dir;

    #### [ALI] Writing nucleotide file...
    $cds_ali->store( secure_outfile($outfile) );

    return;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::Leel::AliProcessor - Internal class for leel tool

=head1 VERSION

version 0.210570

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
