package Bio::MUST::Apps::Roles::RunProcable;
# ABSTRACT: Attributes and methods common to RunProcessor objects
$Bio::MUST::Apps::Roles::RunProcable::VERSION = '0.210370';
use Moose::Role;

use autodie;
use feature qw(say);

use Smart::Comments -ENV;


has 'blast_args' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[HashRef]',
    default  => sub { {} },
    handles  => {
        blast_args_for => 'get',
    },
);


has 'trim_homologues' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'on',
);

has 'trim_max_shift' => (
    is       => 'ro',
    isa      => 'Num',
    default  => 20000,
);

has 'trim_extra_margin' => (
    is       => 'ro',
    isa      => 'Num',
    default  => 15,
);


has 'bank_dir' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'orgs' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[HashRef]',
    required => 1,
    handles  => {
        all_orgs => 'elements',
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


has 'out_suffix' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    # default provided in consuming classes
);


has 'out_dir' => (
    is       => 'ro',
    isa      => 'Str',
    default  => q{},
);


has 'debug_mode' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
);


has 'threads' => (
    is       => 'ro',
    isa      => 'Num',
    default  => 1,
);


no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::Roles::RunProcable - Attributes and methods common to RunProcessor objects

=head1 VERSION

version 0.210370

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
