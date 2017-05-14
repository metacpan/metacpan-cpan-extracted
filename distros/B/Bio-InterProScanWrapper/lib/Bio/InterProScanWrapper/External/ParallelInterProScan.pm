package Bio::InterProScanWrapper::External::ParallelInterProScan;

# ABSTRACT: Run and parse the output of interproscan


use Moose;

has 'input_files_path' => ( is => 'ro', isa => 'Str', required => 1 );
has 'exec'             => ( is => 'ro', isa => 'Str', default  => 'interproscan.sh' );
has 'cpus'             => ( is => 'ro', isa => 'Int', default  => 1 );
has '_output_suffix'   => ( is => 'ro', isa => 'Str', default  => '.out' );

has 'output_type' => ( is => 'ro', isa => 'Str', default => 'gff3' );

sub _cmd 
{
  my ($self) = @_;
  my $paropts = $self->cpus > 0 ? " -j " . $self->cpus : "";
  my $cmd = join(
      ' ',
      (
          'nice', 'parallel', $paropts, $self->exec, '-f', $self->output_type, '--goterms', '--iprlookup',
          '--pathways', '-i', '{}', '--outfile', '{}' . $self->_output_suffix, ':::', $self->input_files_path
      )
  );
  return $cmd;
}

sub run {
    my ($self) = @_;
    my $cmd = $self->_cmd;
    `$cmd`;
    1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Bio::InterProScanWrapper::External::ParallelInterProScan - Run and parse the output of interproscan

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Run and parse the output of cmscan
   use Bio::InterProScanWrapper::External::ParallelInterProScan;

   my $obj = Bio::InterProScanWrapper::External::ParallelInterProScan->new(
     input_file => 'abc.faa',
     exec       => 'interproscan.sh ',
   );
  $obj->run;

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
