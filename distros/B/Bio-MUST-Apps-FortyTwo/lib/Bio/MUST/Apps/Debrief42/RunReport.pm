package Bio::MUST::Apps::Debrief42::RunReport;
# ABSTRACT: Internal class for tabular tax-report parser
# CONTRIBUTOR: Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>
$Bio::MUST::Apps::Debrief42::RunReport::VERSION = '0.190820';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Path::Class qw(file);
use Tie::IxHash;

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Apps::Debrief42::TaxReport';
use aliased 'Bio::MUST::Apps::Debrief42::OrgReport';


has 'tax_reports' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    handles  => {
        all_tax_reports => 'elements',
    },
);


has 'orgs' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    handles  => {
        all_orgs => 'elements',
    },
);


has '_org_reports' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Bio::MUST::Apps::Debrief42::OrgReport]',
    init_arg => undef,
    default  => sub { {} },
    handles  => {
        _set_org_report_for => 'set',
             org_report_for => 'get',
    },
);


has '_orgs_by_' . $_ => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Str]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_orgs_by_' . $_,
    handles  => {
        'orgs_by_' . $_ => 'keys',
    },
) for qw(contamination completeness);


sub BUILD {
    my $self = shift;

    my %new_seqs_by;

    # parse tax-reports
    for my $file ( @{ $self->tax_reports } ) {
        my $tax_report = TaxReport->new( file => file($file) );

        while ( my $new_seq = $tax_report->next_seq ) {
            my $acc     = $new_seq->acc;
            my $outfile = $new_seq->outfile;

            my $full_id = $new_seq->seq_id;
            my $seq_id  = SeqId->new( full_id => $full_id );
            my $org     = $seq_id->full_org;

            push @{ $new_seqs_by{$org}{acc    }{$acc     } }, $new_seq;
            push @{ $new_seqs_by{$org}{outfile}{$outfile } }, $new_seq;
        }
    }

    # build OrgReport objects
    # Note: why to store org twice per report here?
    for my $org ( $self->all_orgs ) {
        my $org_report = OrgReport->new(
            org => $org,
            _new_seqs_by_acc     => $new_seqs_by{$org}{acc    } // {},
            _new_seqs_by_outfile => $new_seqs_by{$org}{outfile} // {},
        );
        $self->_set_org_report_for( $org => $org_report );
    }

    return;
}

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_orgs_by_contamination {
    my $self = shift;

    my %contamination_for;

    for my $org ( $self->all_orgs ) {
        my $org_report = $self->org_report_for($org);

        my $total = 0;
        my $contaminants = 0;

        for my $new_seqs ( $org_report->all_new_seqs_by_acc ) {
            for my $new_seq ( @{$new_seqs} ) {
                $contaminants++ if $new_seq->contam_org;
            }
            $total += @{$new_seqs};
        }

        $contamination_for{$org} = $contaminants / $total
            unless $total == 0;
    }

    return _sort_hash( \%contamination_for, 1 );
}

sub _build_orgs_by_completeness {
    my $self = shift;

    my %completeness_for;

    for my $org ( $self->all_orgs ) {
        my $org_report = $self->org_report_for($org);

        my %pure_seq_for;

        for my $outfile ( $org_report->all_outfiles ) {
            my $new_seqs = $org_report->new_seqs_by_outfile_for($outfile);
            $pure_seq_for{$outfile} = grep {
                $_->contam_org || $_->lca =~ m/unclassified \s sequences/xms ? 0 : 1
            } @{$new_seqs};
        }

        my $total = $self->all_tax_reports;
        my $enriched_alis = keys %pure_seq_for;
        $completeness_for{$org} = $enriched_alis / $total
            unless $total == 0;
    }

    return _sort_hash( \%completeness_for, 0 );
}

## use critic

sub _sort_hash {
    my $hashref = shift;
    my $reverse = shift;

    # Note: Can't we work on the hashref here?
    my %hash = %{$hashref};

    # Note: improve this if this is too slow to run
    # what about a mere reverse of the keys afterwards?
    tie my %sorted_hash, 'Tie::IxHash';
    for my $key ( sort { $reverse ? $hash{$b} <=> $hash{$a}
                                  : $hash{$a} <=> $hash{$b} } keys %hash ) {
        $sorted_hash{$key} = $hash{$key};
    }

    return \%sorted_hash;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::Debrief42::RunReport - Internal class for tabular tax-report parser

=head1 VERSION

version 0.190820

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Mick VAN VLIERBERGHE

Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
