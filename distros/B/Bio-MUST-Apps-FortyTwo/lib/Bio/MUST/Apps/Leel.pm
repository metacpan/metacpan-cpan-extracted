package Bio::MUST::Apps::Leel;
# ABSTRACT: Main class for leel tool
$Bio::MUST::Apps::Leel::VERSION = '0.202160';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments -ENV;

use aliased 'Bio::MUST::Apps::Leel::RunProcessor';

with 'Bio::MUST::Apps::Roles::Configable';


sub run_proc {                              ## no critic (RequireArgUnpacking)
    my $self = shift;

    ### [1331] Welcome to Leel!
    RunProcessor->new( $self->inject_args(@_) );
    ### [1331] Done with Leel!

    return;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::Leel - Main class for leel tool

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
