package Bio::Roary::External::Blastp;
$Bio::Roary::External::Blastp::VERSION = '3.8.0';
# ABSTRACT: Wrapper around NCBIs blastp command


use Moose;
with 'Bio::Roary::JobRunner::Role';

has 'fasta_file'        => ( is => 'ro', isa => 'Str', required => 1 );
has 'blast_database'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'exec'              => ( is => 'ro', isa => 'Str', default  => 'blastp' );
has '_evalue'           => ( is => 'ro', isa => 'Num', default  => 1E-6 );
has '_num_threads'      => ( is => 'ro', isa => 'Int', default  => 1 );
has '_max_target_seqs'  => ( is => 'ro', isa => 'Int', default  => 2000 );
has '_logging'          => ( is => 'ro', isa => 'Str', default  => '2> /dev/null' );
has 'output_file'       => ( is => 'ro', isa => 'Str', default  => 'results.out' );
has 'perc_identity'     => ( is => 'ro', isa => 'Num', default  => 98 );

sub _command_to_run {
    my ($self) = @_;
    return join(
        " ",
        (
            $self->exec,  
            '-query', $self->fasta_file, 
            '-db', $self->blast_database, 
            '-evalue', $self->_evalue,
            '-num_threads', $self->_num_threads,
            '-outfmt 6',
            '-max_target_seqs', $self->_max_target_seqs,
            ' | awk \'{ if ($3 > '.$self->perc_identity.') print $0;}\'',  
            $self->_logging, '1> ', $self->output_file,
        )
        
        
    );
}

sub run {
    my ($self) = @_;
	$self->logger->info( "Running command: " . $self->_command_to_run() );
    system( $self->_command_to_run );
    1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Roary::External::Blastp - Wrapper around NCBIs blastp command

=head1 VERSION

version 3.8.0

=head1 SYNOPSIS

Wrapper around NCBIs blastp command

   use Bio::Roary::External::Blastp;
   
   my $blast_database= Bio::Roary::External::Blastp->new(
     fasta_file => 'contigs.fa',
     blast_database => 'db',
     exec       => 'blastp',
     output_file => 'results.out'
   );
   
   $blast_database->run();

=head1 METHODS

=head2 result_file

Returns the path to the results file

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
