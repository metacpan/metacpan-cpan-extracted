package App::CLI::Extension::Component::InstallCallback;

=pod

=head1 NAME

App::CLI::Extension::Component::InstallCallback - for App::CLI::Extension install callback module

=head1 VERSION

1.421

=head1 SYNOPSIS
  
  # MyApp.pm
  package MyApp;
  
  use strict;
  use base qw(App::CLI::Extension);
  
  # MyApp/Hello.pm
  package MyApp::Hello;
  use strict;
  use feature ":5.10.0";
  use base qw(App::CLI::Command);
  use constants options => ("runmode=s" => "runmode");
   
  sub prerun {
  
      my($self, @argv) = @_;
	  $self->new_callback("view", sub {
                                   my($self, @args) = @_;
								   # anything view to do...
                                   foreach $list (@{$self->anything_all_list}) {
                                       printf "%d: %s\n", $list->id, $list->name;
								   }
                               });
	  $self->new_callback("exec", sub {
                                   my($self, @args) = @_;
								   # anything execute to do...
								   $self->anything_execute(@args);
                               });
      $self->>maybe::next::method(@argv);
  }
  
  sub run {
  
      my($self, @args) = @_;
      my $runmode = $self->{runmode};
      if ($self->exists_callback($runmode)) {
          $self->exec_callback($runmode, @args);
      } else {
          die "invalid runmode!!";
	  }
  }
  
  # myapp
  #!/usr/bin/perl
  
  use strict;
  use MyApp;
  
  MyApp->dispatch;
  
  # execute view callback
  [kurt@localhost ~] myapp hello --runmode=view
  1: melon
  2: banana
     .
     .
     .

=cut

use strict;
use base qw(Class::Accessor::Grouped);

__PACKAGE__->mk_group_accessors( "inherited" => "_install_callback" );
__PACKAGE__->_install_callback({});
our $VERSION  = '1.421';

sub new_callback {

	my($self, $install, $callback) = @_;
	if ($self->exists_callback($install)) {
		die "already exists $install";
	}
	$self->_install_callback->{$install} = [];
	$self->add_callback($install, $callback) if defined $callback;
}

sub add_callback {

	my($self, $install, $callback) = @_;
	if (!$self->exists_callback($install)) {
		die "non install callback: $install";
	}
	if(ref($callback) ne "CODE") {
		die "\$callback is not CODE";
	}
    push @{$self->_install_callback->{$install}}, $callback;
}

sub exec_callback {

	my($self, $install, @args) = @_;
	if (!$self->exists_callback($install)) {
		die "non install callback: $install";
	}
	map { $self->$_(@args) } @{$self->_install_callback->{$install}};
}

sub exists_callback {

    my($self, $install) = @_;
	return exists $self->_install_callback->{$install} ? 1 : 0;
}

1;

__END__

=head1 SEE ALSO

L<App::CLI::Extension> L<Class::Accessor::Grouped>

=head1 AUTHOR

Akira Horimoto

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Copyright (C) 2010 Akira Horimoto

=cut
