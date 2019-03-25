package Bio::MUST::Apps::Leel::RunProcessor;
# ABSTRACT: Internal class for leel tool
$Bio::MUST::Apps::Leel::RunProcessor::VERSION = '0.190820';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments;                    # logging always enabled here

use aliased 'Bio::MUST::Apps::Leel::AliProcessor';

with 'Bio::MUST::Apps::Roles::RunProcable';


has '+out_suffix' => (
    default  => '-1331',
);


has 'id_match_mode' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'enforce',
);


has 'round_trip_mode' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'off',
);


sub BUILD {
    my $self = shift;

    for my $infile ($self->all_infiles) {
        ### [RUN] Processing ALI: $infile
        AliProcessor->new(
            run_proc => $self,
            ali      => $infile,
        );
    }

    return;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::Leel::RunProcessor - Internal class for leel tool

=head1 VERSION

version 0.190820

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
