package Bio::MUST::Apps::Roles::AliProcable;
# ABSTRACT: Attributes and methods common to AliProcessor objects
$Bio::MUST::Apps::Roles::AliProcable::VERSION = '0.190820';
use Moose::Role;

use autodie;
use feature qw(say);

use Smart::Comments -ENV;

use Bio::MUST::Core;

requires '_build_integrator';


has 'ali' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    required => 1,
    coerce   => 1,
);


has 'integrator' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Apps::SlaveAligner::Local',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_integrator',
);


sub display {                               ## no critic (RequireArgUnpacking)
    return join "\n=== ", q{}, @_
}


no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::Roles::AliProcable - Attributes and methods common to AliProcessor objects

=head1 VERSION

version 0.190820

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
