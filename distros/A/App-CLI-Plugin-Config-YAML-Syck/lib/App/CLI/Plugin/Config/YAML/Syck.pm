package App::CLI::Plugin::Config::YAML::Syck;

=pod

=head1 NAME

App::CLI::Plugin::Config::YAML::Syck - for App::CLI::Extension config plugin module

=head1 VERSION

1.2

=head1 SYNOPSIS

  # MyApp.pm
  package MyApp;

  use strict;
  use base qw(App::CLI::Extension);

  # extension method
  __PACKAGE__->load_plugins(qw(Config::YAML::Syck));
  
  # extension method
  __PACKAGE__->config( config_file => "/path/to/config.yaml");
  
  1;
  
  
  # /path/to/config.yaml
  # ---
  # name: kurt
  # age:  27
  
  # MyApp/Hello.pm
  package MyApp::Hello;
  
  use strict;
  use base qw(App::CLI::Command);
  
  sub run {
  
      my($self, @argv) = @_;
      print "Hello! my name is " . $self->config->{name} . "\n";
      print "age is " . "$self->config->{age}\n";
  }
  
  # myapp
  #!/usr/bin/perl
  
  use strict;
  use MyApp;
  
  MyApp->dispatch;
  
  # execute
  [kurt@localhost ~] ./myapp hello
  Hello! my name is kurt
  age is 27

=head1 DESCRIPTION

App::CLI::Extension YAML::Syck Configuration plugin module

The priority of the config file (name of the execute file in the case of *myapp*)

1. /etc/myapp.yml

2. /usr/local/etc/myapp.yaml

3. $HOME/.myapp.yml

4. $APPCLI_CONFIGFILE(environ variable. if exists)

5. command line option

   myapp hello --configfile=/path/to/config.yml

6. config method setting
   
   __PACKAGE__->config(config_file => "/path/to/config.yml");

=cut

use strict;
use FindBin qw($Script);
use File::Spec;
use YAML::Syck;

our $VERSION = '1.2';
our @CONFIG_SEARCH_PATH = ("/etc", "/usr/local/etc", $ENV{HOME});

=pod

=head1 EXTENDED METHOD

=head2 setup

=cut

sub setup {

	my($self, @argv) = @_;
	my $config_file_name = "${Script}.yml";

	foreach my $search_path(@CONFIG_SEARCH_PATH){

		my $file = File::Spec->catfile($search_path, (($search_path eq $ENV{HOME}) ? ".$config_file_name" : $config_file_name));
		if(-e $file && -f $file){
			$self->config(LoadFile($file));
		}
	}

	if(exists $ENV{APPCLI_CONFIGFILE} && defined $ENV{APPCLI_CONFIGFILE}){$self->config(LoadFile($ENV{APPCLI_CONFIGFILE}));
	}
    
	if(exists $self->{configfile} && defined $self->{configfile}){
		$self->config(LoadFile($self->{configfile}));
	}

	if(exists $self->config->{config_file} && defined $self->config->{config_file}){
		$self->config(LoadFile($self->config->{config_file}));
	}

	$self->maybe::next::method(@argv);
}

1;

__END__

=head1 SEE ALSO

L<App::CLI::Extension> L<YAML::Syck>

=head1 AUTHOR

Akira Horimoto

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Copyright (C) 2009 Akira Horimoto

=cut

