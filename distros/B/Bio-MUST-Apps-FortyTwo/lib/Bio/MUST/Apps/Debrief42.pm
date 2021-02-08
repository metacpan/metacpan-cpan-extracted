package Bio::MUST::Apps::Debrief42;
# ABSTRACT: Main class for debrief-42 tool
# CONTRIBUTOR: Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>
$Bio::MUST::Apps::Debrief42::VERSION = '0.210370';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments;

use Carp;

use Bio::MUST::Core;
use aliased 'Bio::MUST::Apps::Debrief42::RunReport';


has 'report_dir' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has 'config' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    handles  => {
        args_for  => 'get',
    },
);


sub run_report {
    my $self = shift;
    my $args = shift // {};             # HashRef (should not be empty...)

    # load config file (42's YAML)
    my @orgs = map { $_->{'org'} } @{ $self->args_for('orgs') };

    my @tax_report_files = File::Find::Rule
        ->file()
        ->name( qr{ \.tax-report\z }xmsi )
        ->maxdepth(1)
        ->in( $self->report_dir )
    ;

    return RunReport->new( orgs => \@orgs, tax_reports => \@tax_report_files );
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::Debrief42 - Main class for debrief-42 tool

=head1 VERSION

version 0.210370

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
