package Bio::MLST::Databases;
# ABSTRACT: List available MLST databases
$Bio::MLST::Databases::VERSION = '2.1.1706216';

use Moose;

has 'base_directory'    => ( is => 'ro', isa => 'Str',      required => 1 );
has 'database_names'    => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_builder_database_names' );

sub _builder_database_names
{
  my($self) = @_;
  my @only_directories;
  opendir(my $dh,$self->base_directory);
  my @database_names = grep { /^[^\.]/ } readdir($dh);

  for my $file_or_dir_name (sort(@database_names))
  {
    next unless(-d ($self->base_directory.'/'.$file_or_dir_name));
    push(@only_directories, $file_or_dir_name);
  }
  
  return \@only_directories;
}

sub print_db_list
{
  my($self) = @_;
  for my $database_name (@{$self->database_names})
  {
    $database_name =~ s!_! !g;
    print $database_name."\n";
  }
  1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::MLST::Databases - List available MLST databases

=head1 VERSION

version 2.1.1706216

=head1 SYNOPSIS

List available MLST databases

   use Bio::MLST::Databases;
   
   my $mlst_dbs = Bio::MLST::Databases->new(
     base_directory => '/path/to/databases',
   );
   $mlst_dbs->print_db_list;

=head1 METHODS

=head2 print_db_list

List available MLST databases

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
