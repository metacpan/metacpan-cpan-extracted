package Bio::InterProScanWrapper::CommandLine::AnnotateEukaryotes;

# ABSTRACT: provide a commandline interface to the annotation wrappers


use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd;
use File::Basename;
use Bio::InterProScanWrapper;

has 'args'                    => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name'             => ( is => 'ro', isa => 'Str',      required => 1 );
has 'help'                    => ( is => 'rw', isa => 'Bool',     default  => 0 );
has 'cpus'                    => ( is => 'rw', isa => 'Int',      default  => 100 );
has 'exec_script'             => ( is => 'rw', isa => 'Str',      default  => '/software/pathogen/external/apps/usr/local/iprscan-5.0.7/interproscan.sh' );
has 'proteins_file'           => ( is => 'rw', isa => 'Str' );
has 'tmp_directory'           => ( is => 'rw', isa => 'Str', default => '/tmp' );
has 'output_filename'         => ( is => 'rw', isa => 'Str', lazy => 1, builder => '_build_output_filename' );
has 'no_lsf'                  => ( is => 'rw', isa => 'Bool', default => 0 );
has 'intermediate_output_dir' => ( is => 'rw', isa => 'Maybe[Str]');

sub BUILD {
    my ($self) = @_;
    my ( $proteins_file, $tmp_directory, $help, $exec_script, $cpus, $output_filename, $no_lsf,$intermediate_output_dir );

    GetOptionsFromArray(
        $self->args,
        'a|proteins_file=s'   => \$proteins_file,
        't|tmp_directory=s'   => \$tmp_directory,
        'e|exec_script=s'     => \$exec_script,
        'p|cpus=s'            => \$cpus,
        'o|output_filename=s' => \$output_filename,
        'l|no_lsf'            => \$no_lsf,
        'intermediate_output_dir=s' => \$intermediate_output_dir,
        'h|help'              => \$help,
    );

    $self->proteins_file($proteins_file) if ( defined($proteins_file) );
    if ( defined($tmp_directory) ) { $self->tmp_directory($tmp_directory); }
    else {
        $self->tmp_directory( getcwd() );
    }
    $self->exec_script($exec_script)         if ( defined($exec_script) );
    $self->cpus($cpus)                       if ( defined($cpus) );
    $self->output_filename($output_filename) if ( defined($output_filename) );
    $self->no_lsf(1)                         if (  defined($no_lsf) );
    $self->intermediate_output_dir($intermediate_output_dir)  if (  defined($intermediate_output_dir) );

}

sub _build_output_filename
{
  my ($self) = @_;
  my $output_filename = 'iprscan_results.gff';
  if(defined($self->proteins_file))
  {
    my($filename, $directories, $suffix) = fileparse($self->proteins_file);
    $output_filename = getcwd().'/'.$filename.'.iprscan.gff';
  }
  return $output_filename;
}

sub merge_results
{
   my ($self) = @_;
   ( ( -e $self->proteins_file ) && !$self->help ) or die $self->usage_text;
  
   my $obj = Bio::InterProScanWrapper->new(
       input_file      => $self->proteins_file,
       _tmp_directory  => $self->tmp_directory,
       cpus            => $self->cpus,
       exec            => $self->exec_script,
       output_filename => $self->output_filename,
       use_lsf         => ($self->no_lsf == 1 ? 0 : 1),
   );
   $obj->merge_results($self->intermediate_output_dir);
}

sub run {
    my ($self) = @_;
    ( ( -e $self->proteins_file ) && !$self->help ) or die $self->usage_text;

    my $obj = Bio::InterProScanWrapper->new(
        input_file      => $self->proteins_file,
        _tmp_directory  => $self->tmp_directory,
        cpus            => $self->cpus,
        exec            => $self->exec_script,
        output_filename => $self->output_filename,
        use_lsf         => ($self->no_lsf == 1 ? 0 : 1)
    );
    $obj->annotate;

}

sub usage_text {
    my ($self) = @_;
    my $script_name = $self->script_name;

    return <<USAGE;
    Usage: $script_name [options]
    Annotate eukaryotes using InterProScan. It is limited to using 400 CPUs at once on the farm.
  
    # Run InterProScan using LSF
    annotate_eukaryotes -a proteins.faa
    
    # Provide an output file name 
    annotate_eukaryotes -a proteins.faa -o output.gff
    
    # Create 200 jobs at a time, writing out intermediate results to a file
    annotate_eukaryotes -a proteins.faa -p 200
    
    # Run on a single host (no LSF). '-p x' needs x*2 CPUs and x*2GB of RAM to be available
    annotate_eukaryotes -a proteins.faa --no_lsf -p 10 

    # This help message
    annotate_eukaryotes -h

USAGE
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::InterProScanWrapper::CommandLine::AnnotateEukaryotes - provide a commandline interface to the annotation wrappers

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

provide a commandline interface to the annotation wrappers

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
