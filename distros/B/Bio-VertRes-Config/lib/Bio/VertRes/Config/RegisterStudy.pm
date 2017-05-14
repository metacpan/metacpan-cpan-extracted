package Bio::VertRes::Config::RegisterStudy;

# ABSTRACT: Register a study 


use Moose;
use File::Basename;
use File::Path qw(make_path);
use Bio::VertRes::Config::Exceptions;
with 'Bio::VertRes::Config::Pipelines::Roles::RootDatabaseLookup';

has 'database'            => ( is => 'ro', isa => 'Str', required => 1 );
has 'study_name'          => ( is => 'ro', isa => 'Str', required => 1 );
has 'config_base'         => ( is => 'ro', isa => 'Str', default => '/nfs/pathnfs05/conf' );

has 'study_file_name'    => ( is => 'ro', isa => 'Str', lazy    => 1, builder => '_build_study_file_name' );

sub _build_study_file_name
{
  my ($self) = @_;
  my $filename = join( '.', ( $self->root_database_name, 'ilm','studies' ) );
  return join('/',($self->config_base,$self->root_database_name, $filename));
}

sub is_study_in_file_already
{
  my ($self) = @_;
  if(-e $self->study_file_name)
  {
    open(my $study_file_name_fh, $self->study_file_name) or Bio::VertRes::Config::Exceptions::FileDoesntExist->throw(error => 'Couldnt open file '.$self->study_file_name);
    while(<$study_file_name_fh>)
    {
      my $line = $_;
      chomp($line);
      next if($line =~ /^#/);
      next if($line =~ /^\s*$/);
      # If the study is already in the file, do nothing
      return 1 if($self->study_name eq $line);
    }
    close($study_file_name_fh);
  }
  
  return 0;
}

sub register_study_name {
    my ($self) = @_;
    return $self if($self->is_study_in_file_already == 1);
    my $mode = 0777;
    
    if(!(-e $self->study_file_name))
    {
      my($overall_config_filename, $directories, $suffix) = fileparse($self->study_file_name);
      make_path($directories, {mode => $mode});
    }
    
    # Study is not in the file so append it to the end, or create a file if it doesnt exist
    open(my $study_file_name_write_fh, '+>>', $self->study_file_name) or Bio::VertRes::Config::Exceptions::FileDoesntExist->throw(error => 'Couldnt open file for append '.$self->study_file_name);
    print {$study_file_name_write_fh} $self->study_name."\n";
    close($study_file_name_write_fh);
    chmod $mode, $self->study_file_name;

    return $self;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::RegisterStudy - Register a study 

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Register a study. Its just a wrapper around a list of study names
   use Bio::VertRes::Config::RegisterStudy;

   my $pipeline = Bio::VertRes::Config::RegisterStudy->new(database => 'abc', study_name => 'ABC study');
   $pipeline->register_study_name();

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
