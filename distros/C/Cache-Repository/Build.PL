#! /usr/bin/perl

use Module::Build;

my $class = Module::Build->subclass
    (
     class => 'CR::Builder',
     code => q{
use File::Find;
sub __clean {
  my $self = shift;
  find(sub
       {
           if (/~$/)
           {
               $self->delete_filetree($_)
           }
       },
       '.');
}
sub ACTION_clean {
  my $self = shift;
  $self->__clean(); $self->SUPER::ACTION_clean(@_);
}
sub ACTION_realclean {
  my $self = shift;
  $self->__clean(); $self->SUPER::ACTION_realclean(@_);
}
     });;
     #my $build = Module::Build->new
my $build = $class->new
    (
     module_name => 'Cache::Repository',
     license => 'perl',
     requires => {
         perl => '5.8.0',
         'Filesys::DiskUsage' => '0.04',
     },
     recommends => {
         'Filesys::Statvfs' => 0,
     },
    );

$build->create_build_script();

