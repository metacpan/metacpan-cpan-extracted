package Bio::HTS::VCF;

use Mouse;
use Log::Log4perl qw( :easy );

use Bio::HTS; #load XS
with 'Bio::HTS::Logger';

has 'filename' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has '_bcf_reader' => (
    is        => 'ro',
    isa       => 'bcf_srs_tPtr',
    builder   => '_build__bcf_reader',
    predicate => '_has_bcf_reader',
    lazy      => 1,
);

sub _build__bcf_reader {
    my $self = shift;

    #we use the bcf synced reader because i feel like it
    my $reader = bcf_sr_open($self->filename);

    die "Error getting reader" unless $reader;

    return $reader;
}

sub num_variants {
    my $self = shift;

    return bcf_num_variants($self->_bcf_reader);
}

sub DEMOLISH {
    my $self = shift;

    if ( $self->_has_bcf_reader ) {
        bcf_sr_close($self->_bcf_reader);
    }
}

1;

__END__

=head1 NAME

Bio::HTS::VCF - start of an interface to the bcf/vcf utilities in htslib

=head1 SYNOPSIS

I haven't finished writing this yet, currently you can only count the number of variants.

=head1 LICENSE

Licensed under the terms of the GNU AFFERO GENERAL PUBLIC LICENSE (AGPL)

=head1 COPYRIGHT

Copyright 2015 Congenica Ltd.

=head1 AUTHOR

Alex Hodgkins

=cut
