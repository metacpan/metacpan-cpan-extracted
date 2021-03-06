package Bio::Roary::JobRunner::Parallel;
$Bio::Roary::JobRunner::Parallel::VERSION = '3.13.0';
# ABSTRACT: Use GNU Parallel


use Moose;
use File::Temp qw/ tempfile /;
use Log::Log4perl qw(:easy);
use File::Slurper 'write_text';
use File::Temp qw/ tempfile /;

has 'commands_to_run' => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'cpus'            => ( is => 'ro', isa => 'Int',      default => 1 );
has 'logger'          => ( is => 'ro', lazy => 1, builder => '_build_logger');
has 'verbose'         => ( is => 'rw', isa => 'Bool', default => 0 );
has 'memory_in_mb'    => ( is => 'rw', isa => 'Int',  default => '200' );

sub run {
    my ($self) = @_;
	
	  my($fh, $temp_command_filename) = tempfile();
	  write_text($temp_command_filename, join("\n", @{ $self->commands_to_run }) );
		
    for my $command_to_run(@{ $self->commands_to_run })
    {
       $self->logger->info($command_to_run);
    }
		my $parallel_command  = "parallel --gnu -j ".$self->cpus." < ".$temp_command_filename ;
		$self->logger->info($parallel_command );
		
		system($parallel_command);
    1;
}

sub _construct_dependancy_params
{
  my ($self) = @_;
  return '';
}

sub submit_dependancy_job {
    my ( $self,$command_to_run) = @_;
    $self->logger->info($command_to_run);
    system($command_to_run );
}

sub _build_logger
{
    my ($self) = @_;
    my $level = $ERROR;
    if($self->verbose)
    {
       $level = $DEBUG;
    }
    Log::Log4perl->easy_init($level);
    my $logger = get_logger();
    return $logger;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Roary::JobRunner::Parallel - Use GNU Parallel

=head1 VERSION

version 3.13.0

=head1 SYNOPSIS

 Execute a set of commands using GNU parallel
   use Bio::Roary::JobRunner::Parallel;
   
   my $obj = Bio::Roary::JobRunner::Local->new(
     commands_to_run   => ['ls', 'echo "abc"'],
     max_jobs => 4
   );
   $obj->run();

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
