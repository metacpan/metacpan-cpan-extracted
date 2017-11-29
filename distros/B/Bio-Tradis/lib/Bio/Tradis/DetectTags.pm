package Bio::Tradis::DetectTags;
$Bio::Tradis::DetectTags::VERSION = '1.4.0';
# ABSTRACT: Detect tr tags in BAM file


use Moose;
use Bio::Tradis::Parser::Bam

has 'bamfile' => ( is => 'ro', isa => 'Str', required => 1 );
has 'samtools_exec' => ( is => 'rw', isa => 'Str', default => 'samtools' );

sub tags_present {
    my ($self) = @_;
    my $pars = Bio::Tradis::Parser::Bam->new( file => $self->bamfile, samtools_exec => $self->samtools_exec );
    my $read_info = $pars->read_info;
    $pars->next_read;
    $read_info = $pars->read_info;
    if(defined(${$read_info}{tr}))
    {
      return 1;
    }
    else
    { 
      return 0;
    }
    
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Tradis::DetectTags - Detect tr tags in BAM file

=head1 VERSION

version 1.4.0

=head1 SYNOPSIS

Detects presence of tr/tq tags in BAM files from Tradis analyses
   use Bio::Tradis::DetectTags;

   my $pipeline = Bio::Tradis::DetectTags->new(bamfile => 'abc');
   $pipeline->tags_present();

=head1 NAME

Bio::Tradis::DetectTags

=head1 PARAMETERS

=head2 Required

C<bamfile> - path to/name of file to check

=head1 METHODS

C<tags_present> - returns true if TraDIS tags are detected in C<bamfile>

=head1 AUTHOR

Carla Cummins <path-help@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
