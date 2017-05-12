package Bio::MLST::Download::Downloadable;
# ABSTRACT: Moose Role to download everything data
$Bio::MLST::Download::Downloadable::VERSION = '2.1.1706216';


use Moose::Role;
use File::Copy;
use File::Basename;
use LWP::Simple;
use File::Path 2.06 qw(make_path);

sub _download_file
{
  my ($self, $filename,$destination_directory) = @_;
  
  # copy if its on the same filesystem
  if(-e $filename)
  {
    copy($filename, $destination_directory);
  }
  else
  {
    my $status = getstore($filename, join('/',($destination_directory,$self->_get_filename_from_url($filename))));
    die "Something went wrong, got a $status status code" if is_error($status);
  }
  1;
}

sub _get_filename_from_url
{
  my ($self, $filename) = @_;
  if($filename =~ m!/([^/]+)$!)
  {
    return $1;
  }
  
  return int(rand(10000)).".tfa";
}

sub _build_destination_directory
{
  my ($self) = @_;
  my $destination_directory = join('/',($self->base_directory,$self->_sub_directory));
  make_path($destination_directory);
  make_path(join('/',($destination_directory,'alleles')));
  make_path(join('/',($destination_directory,'profiles')));
  return $destination_directory;
}

sub _sub_directory
{
  my ($self) = @_;
  my $combined_name = join('_',($self->species));
  $combined_name =~ s!\.$!!gi;
  $combined_name =~ s!\W!_!gi;
  return $combined_name;
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::MLST::Download::Downloadable - Moose Role to download everything data

=head1 VERSION

version 2.1.1706216

=head1 SYNOPSIS

Moose Role to download everything data

   with 'Bio::MLST::Download::Downloadable';

=head1 SEE ALSO

=over 4

=item *

L<Bio::MLST::Download::Database>

=item *

L<Bio::MLST::Download::Databases>

=back

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
