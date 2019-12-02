package Bio::Tradis::CommandLine::AddTags;
$Bio::Tradis::CommandLine::AddTags::VERSION = '1.4.3';
# ABSTRACT: Add given tags to the start of the sequence


use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Tradis::AddTagsToSeq;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'bamfile'     => ( is => 'rw', isa => 'Str',      required => 0 );
has 'help'        => ( is => 'rw', isa => 'Bool',     required => 0 );
has 'outfile'     => ( is => 'rw', isa => 'Str',      required => 0 );

has 'verbose'       => ( is => 'rw', isa => 'Bool', default => 0 );
has 'samtools_exec' => ( is => 'rw', isa => 'Str', default => 'samtools' );

sub BUILD {
    my ($self) = @_;

    my ( $bamfile, $outfile, $help, $verbose, $samtools_exec);

    GetOptionsFromArray(
        $self->args,
        'b|bamfile=s' => \$bamfile,
        'o|outfile=s' => \$outfile,
        'h|help'      => \$help,
        'v|verbose'         => \$verbose,
        'samtools_exec=s'   => \$samtools_exec,
    );

    $self->bamfile( abs_path($bamfile) ) if ( defined($bamfile) );
    $self->outfile( abs_path($outfile) ) if ( defined($outfile) );
    $self->help($help)                   if ( defined($help) );
    $self->verbose($verbose)             if ( defined($verbose) );
    $self->samtools_exec($samtools_exec) if ( defined($samtools_exec) );

	# print usage text if required parameters are not present
	($bamfile) or die $self->usage_text;
}

sub run {
    my ($self) = @_;

    if ( defined( $self->help ) ) {
    #if ( scalar( @{ $self->args } ) == 0 ) {
          $self->usage_text;
    }

    my $tagadd = Bio::Tradis::AddTagsToSeq->new(
        bamfile => $self->bamfile,
        outfile => $self->outfile,
        verbose       => $self->verbose,
        samtools_exec => $self->samtools_exec
    );
    $tagadd->add_tags_to_seq;
}

sub usage_text {
      print <<USAGE;
Adds transposon sequence and quality tags to the read strings and
outputs a BAM.

Usage: add_tags -b file.bam [options]

Options:
-b  : bam file with tradis tags
-o  : output BAM name (optional. default: <file>.tr.bam)
-v  : verbose debugging output

USAGE
      exit;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Tradis::CommandLine::AddTags - Add given tags to the start of the sequence

=head1 VERSION

version 1.4.3

=head1 SYNOPSIS

Adds given tags to the start of the sequence

=head1 AUTHOR

Carla Cummins <path-help@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
