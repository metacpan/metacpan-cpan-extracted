package App::CLI::Plugin::Parallel::ForkManager;

=pod

=head1 NAME

App::CLI::Plugin::Parallel::ForkManager - for App::CLI::Extension fork plugin module

=head1 VERSION

1.1

=head1 SYNOPSIS

  # MyApp.pm
  package MyApp;
  
  use strict;
  use base qw(App::CLI::Extension);
  
  # extension method
  __PACKAGE__->load_plugins(qw(Parallel::ForkManager));
  
  # extension method
  __PACKAGE__->config( parallel_fork_manager => 5 );
  
  1;
  
  # MyApp/Fork.pm
  package MyApp::Fork;
  
  use strict;
  use base qw(App::CLI::Command);
  use LWP::UserAgent;
  use HTTP::Request;
  
  our %LINKS = (cpan => "http://search.cpan.org", perl => "http://www.perl.org", foo => "http://foo.foo/");
  
  sub options { return ("maxprocs=i" => "maxprocs") };
  
  sub run {
  
      my($self, @argv) = @_;
  
      $self->pm->run_on_start(sub {
  
          my ($pid, $ident) = @_;
          print "$ident PID[$pid] start\n";
      });
  
      $self->pm->run_on_finish(sub {
  
          my ($pid, $exit_value, $ident) = @_;
          print "$ident PID[$pid] finish. exit_value: $exit_value\n";
      });
  
      foreach my $key (keys %LINKS) {
  
          my $pid = $self->pm->start($key) and next;
          my $ua  = LWP::UserAgent->new;
          my $req = HTTP::Request->new(GET => $LINKS{$key});
          my $res = $ua->request($req);
          if ($res->is_success) {
              printf "%s's status code: %d\n", $key, $res->code;
          } else {
              printf "ERROR: $key %s\n", $res->status_line;
          }
          $self->pm->finish;
      }
  
      $self->pm->wait_all_children;
  }
  
  1;
  
  # myapp
  #!/usr/bin/perl
  
  use strict;
  use MyApp;
  
  MyApp->dispatch;
  
  # execute
  [kurt@localhost ~] ./myapp fork
  perl PID[3193] start
  cpan PID[3194] start
  foo PID[3195] start
  perl's status code: 200
  perl PID[3193] finish. exit_value: 0
  cpan's status code: 200
  cpan PID[3194] finish. exit_value: 0
  foo's status code: 200
  cpan PID[3195] finish. exit_value: 0

=head1 DESCRIPTION

App::CLI::Plugin::Parallel::ForkManager - Parallel::ForkManager plugin module

pm method setting

  __PACKAGE__->config( parallel_fork_manager => $maxprocs );

or if --maxprocs option is defined. it applies.

  # in MyApp/**.pm
  sub options {
      return ( "maxprocs=i" => "maxprocs" ) ;
  }
  
  # execute
  [kurt@localhost ~] ./myapp fork --maxprocs=10

=head1 METHOD

=head2 pm

return Parallel::ForkManager object. 

=cut

use strict;
use warnings;
use base qw(Class::Accessor::Grouped);
use Parallel::ForkManager;

__PACKAGE__->mk_group_accessors(inherited => "pm");
our $VERSION = '1.1';

sub setup {

	my($self, @argv) = @_;
	my $maxprocs;
	if (exists $self->config->{parallel_fork_manager}) {
		$maxprocs = $self->config->{parallel_fork_manager};
	}
	if (exists $self->{maxprocs} && defined $self->{maxprocs}) {
		$maxprocs = $self->{maxprocs};
	}
	$self->pm(Parallel::ForkManager->new($maxprocs));	
	$self->maybe::next::method(@argv);
}

1;

__END__


=head1 AUTHOR

Akira Horimoto

=head1 SEE ALSO

L<App::CLI::Extension> L<Parallel::ForkManager>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 COPYRIGHT

Copyright (C) 2010 Akira Horimoto

=cut
