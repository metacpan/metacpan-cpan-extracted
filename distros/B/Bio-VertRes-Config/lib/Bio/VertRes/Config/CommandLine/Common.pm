package Bio::VertRes::Config::CommandLine::Common;

# ABSTRACT: Create config scripts


use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Bio::VertRes::Config::CommandLine::LogParameters;
use Bio::VertRes::Config::CommandLine::ConstructLimits;
use Bio::VertRes::Config::Exceptions;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );

has 'database'    => ( is => 'rw', isa => 'Str', default => 'pathogen_prok_track' );
has 'config_base' => ( is => 'rw', isa => 'Str', default => '/nfs/pathnfs05/conf' );
has 'root_base'   => ( is => 'rw', isa => 'Str', default => '/lustre/scratch108/pathogen/pathpipe' );
has 'log_base'    => ( is => 'rw', isa => 'Str', default => '/nfs/pathnfs05/log' );
has 'database_connect_file' =>
  ( is => 'rw', isa => 'Str', default => '/software/pathogen/config/database_connection_details' );
has 'reference_lookup_file' =>
  ( is => 'rw', isa => 'Str', default => '/lustre/scratch108/pathogen/pathpipe/refs/refs.index' );
has 'reference'                      => ( is => 'rw', isa => 'Maybe[Str]', );
has 'available_references'           => ( is => 'rw', isa => 'Maybe[Str]' );
has 'type'                           => ( is => 'rw', isa => 'Maybe[Str]' );
has 'id'                             => ( is => 'rw', isa => 'Maybe[Str]' );
has 'species'                        => ( is => 'rw', isa => 'Maybe[Str]' );
has 'mapper'                         => ( is => 'rw', isa => 'Maybe[Str]' );
has 'protocol'                       => ( is => 'rw', isa => 'Str', default => 'StrandSpecificProtocol' );
has 'regeneration_log_file'          => ( is => 'rw', isa => 'Maybe[Str]' );
has 'overwrite_existing_config_file' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'help'                           => ( is => 'rw', isa => 'Bool', default => 0 );

# mapper specific
has 'smalt_index_k'  => ( is => 'rw', isa => 'Maybe[Int]' );
has 'smalt_index_s'  => ( is => 'rw', isa => 'Maybe[Int]' );
has 'smalt_mapper_r' => ( is => 'rw', isa => 'Maybe[Int]' );
has 'smalt_mapper_x' => ( is => 'rw', isa => 'Maybe[Bool]' );
has 'smalt_mapper_y' => ( is => 'rw', isa => 'Maybe[Num]' );
has 'smalt_mapper_l' => ( is => 'rw', isa => 'Maybe[Str]' );
has 'tophat_mapper_I' => ( is => 'rw', isa => 'Maybe[Int]' );
has 'tophat_mapper_i' => ( is => 'rw', isa => 'Maybe[Int]' );
has 'tophat_mapper_g' => ( is => 'rw', isa => 'Maybe[Int]' );

# set assembler
has 'assembler' => ( is => 'rw', isa => 'Maybe[Str]' );

sub BUILD {
    my ($self) = @_;
    my $log_params =
      Bio::VertRes::Config::CommandLine::LogParameters->new( args => $self->args, script_name => $self->script_name );

    my (
        $database,              $config_base,                    $reference_lookup_file,
        $available_references,  $reference,                      $type,
        $id,                    $species,                        $mapper,
        $regeneration_log_file, $overwrite_existing_config_file, $protocol,
        $smalt_index_k,         $smalt_index_s,                  $smalt_mapper_r,
        $smalt_mapper_y,        $smalt_mapper_x,                 $smalt_mapper_l,
        $tophat_mapper_I,       $tophat_mapper_i,                $tophat_mapper_g,
        $assembler,             $root_base,                      $log_base,
        $database_connect_file, $help
    );

    GetOptionsFromArray(
        $self->args,
        'd|database=s'                     => \$database,
        'c|config_base=s'                  => \$config_base,
        'l|reference_lookup_file=s'        => \$reference_lookup_file,
        'r|reference=s'                    => \$reference,
        'a|available_references=s'         => \$available_references,
        't|type=s'                         => \$type,
        'i|id=s'                           => \$id,
        's|species=s'                      => \$species,
        'm|mapper=s'                       => \$mapper,
        'b|regeneration_log_file=s'        => \$regeneration_log_file,
        'overwrite_existing_config_file'   => \$overwrite_existing_config_file,
        'p|protocol=s'                     => \$protocol,
        'smalt_index_k=i'                  => \$smalt_index_k,
        'smalt_index_s=i'                  => \$smalt_index_s,
        'smalt_mapper_r=i'                 => \$smalt_mapper_r,
        'smalt_mapper_y=f'                 => \$smalt_mapper_y,
        'smalt_mapper_x'                   => \$smalt_mapper_x,
        'smalt_mapper_l=s'                 => \$smalt_mapper_l,
        'tophat_mapper_max_intron=i'       => \$tophat_mapper_I,
        'tophat_mapper_min_intron=i'       => \$tophat_mapper_i,
        'tophat_mapper_max_multihit=i'     => \$tophat_mapper_g,
        'assembler=s'                      => \$assembler,
        'root_base=s'                      => \$root_base,
        'log_base=s'                       => \$log_base,
        'db_file:s'                        => \$database_connect_file,
        'h|help'                           => \$help
    );

    $self->database($database)                           if ( defined($database) );
    $self->config_base($config_base)                     if ( defined($config_base) );
    $self->root_base($root_base)                         if ( defined($root_base) );
    $self->log_base($log_base)                           if ( defined($log_base) );
    $self->reference_lookup_file($reference_lookup_file) if ( defined($reference_lookup_file) );
    $self->reference($reference)                         if ( defined($reference) );
    $self->available_references($available_references)   if ( defined($available_references) );
    $self->type($type)                                   if ( defined($type) );
    $self->id($id)                                       if ( defined($id) );
    $self->species($species)                             if ( defined($species) );
    $self->mapper($mapper)                               if ( defined($mapper) );
    $self->protocol($protocol)                           if ( defined($protocol) );
    $self->help($help)                                   if ( defined($help) );
    $self->smalt_index_k($smalt_index_k)                 if ( defined($smalt_index_k) );
    $self->smalt_index_s($smalt_index_s)                 if ( defined($smalt_index_s) );
    $self->smalt_mapper_r($smalt_mapper_r)               if ( defined($smalt_mapper_r) );
    $self->smalt_mapper_y($smalt_mapper_y)               if ( defined($smalt_mapper_y) );
    $self->smalt_mapper_x($smalt_mapper_x)               if ( defined($smalt_mapper_x) );
    $self->smalt_mapper_l($smalt_mapper_l)               if ( defined($smalt_mapper_l) );
    $self->tophat_mapper_I($tophat_mapper_I)             if ( defined($tophat_mapper_I) );
    $self->tophat_mapper_i($tophat_mapper_i)             if ( defined($tophat_mapper_i) );
    $self->tophat_mapper_g($tophat_mapper_g)             if ( defined($tophat_mapper_g) );
    $self->assembler($assembler)                         if ( defined($assembler) );
    $self->database_connect_file($database_connect_file) if ( defined($database_connect_file) );

    $regeneration_log_file ||= join( '/', ( $self->config_base, 'command_line.log' ) );
    $self->regeneration_log_file($regeneration_log_file) if ( defined($regeneration_log_file) );
    $self->overwrite_existing_config_file($overwrite_existing_config_file)
      if ( defined($overwrite_existing_config_file) );

    $log_params->log_file( $self->regeneration_log_file );
    $log_params->create();
}

sub _construct_smalt_index_params
{
  my ($self) = @_;
  if(defined($self->smalt_index_k) && defined($self->smalt_index_s) )
  {
    return join(' ', ('-k',$self->smalt_index_k,'-s',$self->smalt_index_s));
  }
  return undef;
}

sub _construct_smalt_additional_mapper_params
{
  my ($self) = @_;
  my $output_param_str = "";
  if(defined($self->smalt_mapper_r))
  {
    $output_param_str = join(' ',($output_param_str,'-r',$self->smalt_mapper_r));
  }
  if(defined($self->smalt_mapper_y))
  {
    $output_param_str = join(' ',($output_param_str,'-y',$self->smalt_mapper_y));
  }
  if(defined($self->smalt_mapper_x))
  {
    $output_param_str = join(' ',($output_param_str,'-x'));
  }
  if(defined($self->smalt_mapper_l))
  {
    my %pairtyp = ('pe' => 1, 'mp' => 1, 'pp' => 1);
    Bio::VertRes::Config::Exceptions::InvalidType->throw(error => 'Invalid type passed in for smalt_mapper_l, can only be one of pe/mp/pp not '.$self->smalt_mapper_l.".\n") unless exists $pairtyp{$self->smalt_mapper_l};
    $output_param_str = join(' ',($output_param_str,'-l',$self->smalt_mapper_l));
  }
  
  if($output_param_str eq "")
  {
    return undef;
  }
  
  return $output_param_str;
}

sub _construct_tophat_additional_mapper_params
{
  my ($self) = @_;
  my $output_param_str = "";
  if(defined($self->tophat_mapper_I))
  {
    $output_param_str = join(' ',($output_param_str,'-I',$self->tophat_mapper_I));
  }
  if(defined($self->tophat_mapper_i))
  {
    $output_param_str = join(' ',($output_param_str,'-i',$self->tophat_mapper_i));
  }
  if(defined($self->tophat_mapper_g))
  {
    $output_param_str = join(' ',($output_param_str,'-g',$self->tophat_mapper_g));
  }
  
  if($output_param_str eq "")
  {
    return undef;
  }
  
  return $output_param_str;
}

sub mapping_parameters {
    my ($self) = @_;
    my $limits = Bio::VertRes::Config::CommandLine::ConstructLimits->new(
        input_type => $self->type,
        input_id   => $self->id,
        species    => $self->species
    )->limits_hash;

    my %mapping_parameters = (
        database                       => $self->database,
        config_base                    => $self->config_base,
        root_base                      => $self->root_base,
        log_base                       => $self->log_base,
        limits                         => $limits,
        reference_lookup_file          => $self->reference_lookup_file,
        reference                      => $self->reference,
        overwrite_existing_config_file => $self->overwrite_existing_config_file,
        protocol                       => $self->protocol,
        database_connect_file          => $self->database_connect_file
    );
    
    if(defined($self->_construct_smalt_index_params))
    {
      $mapping_parameters{mapper_index_params} = $self->_construct_smalt_index_params;
    }
    if(defined($self->_construct_smalt_additional_mapper_params))
    {
      $mapping_parameters{additional_mapper_params} = $self->_construct_smalt_additional_mapper_params;
    }
    if(defined($self->_construct_tophat_additional_mapper_params))
    {
      $mapping_parameters{additional_mapper_params} = $self->_construct_tophat_additional_mapper_params;
    }
    
    return \%mapping_parameters;
}

# Overwrite this method
sub retrieving_results_text {
    my ($self) = @_;
}

# Overwrite this method
sub usage_text {
    my ($self) = @_;
}

sub retrieving_rnaseq_results_text {
    my ($self) = @_;
    print "Once the data is available you can run these commands:\n\n";

    print "Create symlinks to all your data\n";
    print "  rnaseqfind -t " . $self->type . " -i " . $self->id . " -symlink\n\n";

    print "Symlink to the spreadsheets of statistics per gene\n";
    print "  rnaseqfind -t " . $self->type . " -i " . $self->id . " -symlink -f spreadsheet\n\n";

    print "Symlink to the BAM files (corrected for the protocol)\n";
    print "  rnaseqfind -t " . $self->type . " -i " . $self->id . " -symlink -f bam\n\n";

    print "Symlink to the annotation for the intergenic regions\n";
    print "  rnaseqfind -t " . $self->type . " -i " . $self->id . " -symlink -f intergenic\n\n";

    print "Symlink to the coverage plots\n";
    print "  rnaseqfind -t " . $self->type . " -i " . $self->id . " -symlink -f coverage\n\n";

    print "More details\n";
    print "  rnaseqfind -h\n";
}

sub retrieving_mapping_results_text {
    my ($self) = @_;
    print "Once the data is available you can run these commands:\n\n";

    print "Symlink to the BAM files\n";
    print "  mapfind -t " . $self->type . " -i " . $self->id . " -symlink\n\n";

    print "Find out which mapper and reference was used\n";
    print "  mapfind -t " . $self->type . " -i " . $self->id . " -d\n\n";

    print "More details\n";
    print "  mapfind -h\n\n";
}

sub retrieving_snp_calling_results_text {
    my ($self) = @_;
    print "Once the data is available you can run these commands:\n\n";

    print "Create a multifasta alignment file of your data\n";
    print "  snpfind -t " . $self->type . " -i " . $self->id . " -p \n\n";

    print "Create symlinks to the unfiltered variants in VCF format\n";
    print "  snpfind -t " . $self->type . " -i " . $self->id . " -symlink\n\n";

    print "Symlink to the BAM files\n";
    print "  mapfind -t " . $self->type . " -i " . $self->id . " -symlink\n\n";

    print "More details\n";
    print "  snpfind -h\n";
    print "  mapfind -h\n\n";
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::CommandLine::Common - Create config scripts

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Create config scripts

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
