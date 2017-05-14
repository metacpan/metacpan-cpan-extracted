package Bio::VertRes::Config::CommandLine::ConstructLimits;

# ABSTRACT: Put the limits together


use Moose;
use Bio::VertRes::Config::Exceptions;
use File::Slurp;
use DBI;


has 'input_type'   => ( is => 'ro', isa => 'Str',   required => 1 );
has 'input_id'     => ( is => 'ro', isa => 'Str',   required => 1 );
has 'species'      => ( is => 'ro', isa => 'Maybe[Str]' );

sub limits_hash
{
  my ($self) = @_;
  my %limits;
  
  if($self->input_type eq 'study' && $self->input_id =~ /^[\d]+$/)
  {
    # Todo: move ssid lookup to somewhere more sensible
    my $dbh = DBI->connect("DBI:mysql:host=mcs7:port=3379;database=sequencescape_warehouse", "warehouse_ro",undef, {'RaiseError' => 1, 'PrintError' => 0});
    my $sql = "select name from current_studies where internal_id = '".$self->input_id."' ";
    my @study_names = $dbh->selectrow_array($sql );
    
    #
    #for my $study_name( @study_names)
    #{
    #      $study_name =~ s/^\\([^-\w$()*+.\/?@\[\\\]^{|}])$/$1/;
    #}
    
    $limits{project} = \@study_names;

  }
  elsif($self->input_type eq 'study')
  {
    $limits{project} = [$self->input_id];
  }
  elsif($self->input_type eq 'library' || $self->input_type eq 'sample')
  {
    $limits{$self->input_type} = [$self->input_id];
  } 
  elsif($self->input_type eq 'lane')
  {
    if($self->input_id =~ /^\d+_\d$/)
    {
      $limits{$self->input_type} = [$self->input_id.'(#.+)?'];
    }
    else
    {
      $limits{$self->input_type} = [$self->input_id];
    }
  }
  elsif($self->input_type eq 'file')
  {
    $limits{lane} = $self->_extract_lanes_from_file;
  }
  else
  {
    Bio::VertRes::Config::Exceptions::InvalidType->throw(error => 'Invalid type passed in, can only be one of study/file/lane/library/sample not '.$self->input_type);
  }
  
  if(defined($self->species))
  {
    $limits{species} = [$self->species];
  }
  
  return \%limits;
}

sub _extract_lanes_from_file
{
  my ($self) = @_;
  
  my $file_contents  = read_file( $self->input_id ) or Bio::VertRes::Config::Exceptions::FileDoesntExist->throw(error => 'Couldnt open the file '.$self->input_id);
  my @lanes = split(/[\n\r]+/, $file_contents);
  my @filtered_lanes;
  for my $lane (@lanes)
  {
    next if($lane =~ /^#/);
    next if($lane =~ /^\s*$/);
    $lane = $lane.'(#.+)?' if $lane =~ /^\d+_\d$/;
    push(@filtered_lanes, $lane);
  }
  
  return \@filtered_lanes;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::CommandLine::ConstructLimits - Put the limits together

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

A class to represent multiple top level files. It splits out mixed config files into the correct top level files
   use Bio::VertRes::Config::CommandLine::ConstructLimits;

   Bio::VertRes::Config::CommandLine::ConstructLimits->new(input_type => $type, input_id => $id, species => $species)->limits_hash;

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
