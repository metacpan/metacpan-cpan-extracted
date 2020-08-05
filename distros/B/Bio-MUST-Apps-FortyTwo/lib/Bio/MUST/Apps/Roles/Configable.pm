package Bio::MUST::Apps::Roles::Configable;
# ABSTRACT: Attributes and methods common to Leel and FortyTwo objects
$Bio::MUST::Apps::Roles::Configable::VERSION = '0.202160';
use Moose::Role;

use autodie;
use feature qw(say);

use Smart::Comments -ENV;

use Carp;


has 'config' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    handles  => {
        args_for  => 'get',
    },
);


has 'infiles' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    handles  => {
        all_infiles => 'elements',
    },
);


sub inject_args {
    my $self = shift;
    my $args = shift // {};             # HashRef (should not be empty...)

    # do some pre-flight QC
    # and propagate 'defaults' args as default values for all org args
    my %def_args = %{ $self->args_for('defaults') // {} };
    for my $org_args ( @{ $self->args_for('orgs') } ) {

        # check that org has no underscore between genus and species
        # to prevent app from distinguishing Genus_species and Genus species
        _check_org_format( $org_args->{org} );
        $org_args = { %def_args, %{ $org_args } };
    }

    # same check for query_orgs
    _check_org_format($_)
        for @{ $self->args_for('query_orgs') };

    # combine YAML and CLI parameters (e.g., debug_mode)
    # Note: CLI take precedences over YAML (in case of duplicates)
    my %args = ( %{ $self->config }, %{$args} );

    # add infiles
    $args{infiles} = $self->infiles;

    ### [CFG] Bio::FastParsers...........: $Bio::FastParsers::VERSION
    ### [CFG] Bio::MUST::Core............: $Bio::MUST::Core::VERSION
    ### [CFG] Bio::MUST::Drivers.........: $Bio::MUST::Drivers::VERSION
    ### [CFG] Bio::MUST::Apps::FortyTwo..: $Bio::MUST::Apps::FortyTwo::VERSION

    ### [CFG] BMD_BLAST_BINDIR...........: $ENV{BMD_BLAST_BINDIR}

    ### [CFG] config: %args

    return %args;
}


sub _check_org_format {
    my $org = shift;

    carp "[CFG] Warning: '$org' incorrectly written; use '$1 $2' instead!"
        if $org =~ m/^(\S+)_(.*)/xms;

    return;
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::Roles::Configable - Attributes and methods common to Leel and FortyTwo objects

=head1 VERSION

version 0.202160

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
