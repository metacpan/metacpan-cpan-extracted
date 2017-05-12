package Aspect::Loader;
use 5.008008;
use strict;
use warnings;
our $VERSION = '0.03';
use Aspect;
use Aspect::Loader::Configuration::YAML;
use Aspect::Loader::Definition;
use UNIVERSAL::require;
use Class::Inspector;

sub new{
	my $class     = shift;
	my $configuration  = shift;
	my $self = {
		_configuration => $configuration,
	};
	bless $self,$class;
  $self->load_aspect;
	return $self;
}

sub yaml_loader{
	my $class = shift;
	my $file_path = shift;
	my $configuration = Aspect::Loader::Configuration::YAML->new($file_path);
	return $class->new($configuration);
}

sub load_aspect{
	my $self = shift;
  my $configuration = $self->{_configuration}->get_configuration();
  foreach my $conf (@$configuration){
	    my $definition = Aspect::Loader::Definition->new($conf);
      my $class = $definition->get_class_name;
      unless(Class::Inspector->loaded($class )){
        $class->require or die "cant load class $class";
      }
      if($definition->get_class_name){

      }
      aspect $definition->get_library  => $definition->get_call;
  }
}


1;
__END__

=head1 NAME

Aspect::Loader - load aspect by configuration 

=head1 SYNOPSIS
configuration by yaml 

  aspects:
   - library: Singleton
     call: Hoge::new
   - library: Trace
     call: Hoge::hogehoge

code
  
  Aspect::Loader->yaml_loader($yaml_path);
  # singleton  same instance
  Hoge->new->hoge;
  Hoge->new->hoge;
  # trace method
  Hoge->hogehoge;

=head1 DESCRIPTION

This class is the one for Aspect.pm where Aspect is achieved with perl. 
Aspect.pm is facilitated and the management enabling and operation are facilitated by the configuration file.  

=head1 SEE ALSO

this class is a tool for L<Aspect> 

=head1 AUTHOR

Masafumi Yoshida, E<lt>masafumi.yoshida820@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by masafumi yoshida

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
