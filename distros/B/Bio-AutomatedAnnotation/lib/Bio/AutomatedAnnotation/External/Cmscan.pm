package Bio::AutomatedAnnotation::External::Cmscan;

# ABSTRACT: Run and parse the output of cmscan


use Moose;
use Bio::SeqFeature::Generic;

has 'cmdb'       => ( is => 'ro', isa => 'Str', required => 1 );
has 'input_file' => ( is => 'ro', isa => 'Str', required => 1 );

has 'exec'     => ( is => 'ro', isa => 'Str',     default => 'cmscan' );
has 'version'  => ( is => 'ro', isa => 'Str',     default => '1.1' );
has 'cpus'     => ( is => 'ro', isa => 'Int',     default => 1 );
has 'evalue'   => ( is => 'ro', isa => 'Num',     default => 1E-6 );
has 'features' => ( is => 'ro', isa => 'HashRef', lazy    => 1, builder => '_build_features' );
has 'number_of_features'  => ( is => 'rw', isa => 'Int',  default => 0 );

has '_tool'        => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build__tool' );
has '_cpus'        => ( is => 'ro', isa => 'Int', lazy => 1, builder => '_build__cpus' );
has '_infernal_fh' => ( is => 'ro',  lazy => 1, builder => '_build__infernal_fh' );

sub _build__tool {
    my ($self) = @_;
    return "Infernal:" . $self->version;
}

sub _build__cpus {
    my ($self) = @_;
    return $self->cpus || 1;
}

sub _build__infernal_fh {
    my ($self) = @_;
    open(
        my $fh,
        '-|',
        join(
            ' ',
            (
                $self->exec,   '--cpu', $self->_cpus, '-E',      $self->evalue, '--tblout',
                '/dev/stdout', '-o',    '/dev/null',  '--noali', $self->cmdb,   $self->input_file
            )
        )
    );
    return $fh;
}

sub _build_features {
    my ($self) = @_;
    my %features;
    
    my $number_of_features = 0;
    my $fh = $self->_infernal_fh;
    while ( <$fh> ) {
        next if (/\#/);
        my @x = split ' ';    # magic Perl whitespace splitter
        next if ( @x < 16 );
        next unless $x[1] =~ m/^RF\d/;

        # The start coord is always the lowest
        my $sequence_id = $x[2];
        my $start_coords   = $x[7];
        my $end_coords     = $x[8];
        my $current_strand = $x[9] eq '-' ? -1 : +1;

        if ( $start_coords > $end_coords ) {
            my $tmp_coords = $end_coords;
            $end_coords     = $start_coords;
            $start_coords   = $tmp_coords;
            $current_strand = -1;
        }

        push @{ $features{$sequence_id} },
          Bio::SeqFeature::Generic->new(
            -primary => 'ncRNA',
            -seq_id  => $sequence_id,
            -source  => $self->_tool,
            -start   => $start_coords,
            -end     => $end_coords,
            -strand  => $current_strand,
            -frame   => 0,
            -tag     => {
                'product'   => $x[0],
                'inference' => "COORDINATES:profile:" . $self->_tool,
            }
          );
          $number_of_features++;

    }
    $self->number_of_features($number_of_features);
    return \%features;
}


sub add_features_to_prokka_structure
{
  my ($self, $prokka_sequence_structure) = @_;
  for my $sequence_id (keys %{$self->features})
  {
    push(@{$prokka_sequence_structure->{$sequence_id}{FEATURE}},  @{$self->features->{$sequence_id}});
  }
  return $prokka_sequence_structure;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Bio::AutomatedAnnotation::External::Cmscan - Run and parse the output of cmscan

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Run and parse the output of cmscan
   use Bio::AutomatedAnnotation::External::Cmscan;

   my $obj = Bio::AutomatedAnnotation::External::Cmscan->new(
     cmdb       => 'database/cm/Bacteria',
     input_file => 'abc.fa',
     exec       => 'cmscan',
     version    => '1.1',
     cpus       => 1,
     evalue     => 1E-6,
   );
  $obj->features;

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
