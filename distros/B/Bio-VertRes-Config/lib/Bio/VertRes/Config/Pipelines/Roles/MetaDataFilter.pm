package Bio::VertRes::Config::Pipelines::Roles::MetaDataFilter;
# ABSTRACT: Moose Role for dealing with limits meta data filters


use Moose::Role;

has 'limits'             => ( is => 'ro', isa => 'HashRef', required => 1 );
has '_escaped_limits'    => ( is => 'ro', isa => 'HashRef', lazy    => 1, builder => '_build__escaped_limits' );

sub _build__escaped_limits
{
  my ($self) = @_;
  my %escaped_limits;
  
  for my $limit_type (keys %{$self->limits}) 
  {
    my @escaped_array_values;
    for my $array_value ( @{$self->limits->{$limit_type}})
    {
      # Dont backslash out the values in lane
      if($limit_type eq 'lane')
      {
        push(@escaped_array_values,  $array_value);
      }
      else
      {
        push(@escaped_array_values, (quotemeta $array_value));
      }
    }
    $escaped_limits{$limit_type} = \@escaped_array_values;
  }
  return \%escaped_limits;
}

no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Pipelines::Roles::MetaDataFilter - Moose Role for dealing with limits meta data filters

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Moose Role for dealing with limits meta data filters, for example by study, species, samples, lanes etc...

   with 'Bio::VertRes::Config::Pipelines::Roles::MetaDataFilter';

=head1 METHODS

=head2 _escaped_limits

Internal variable containing a hash of arrays with the strings in the array escaped out.

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
