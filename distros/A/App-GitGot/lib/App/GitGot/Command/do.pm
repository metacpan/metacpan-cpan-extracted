package App::GitGot::Command::do;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Command::do::VERSION = '1.339';
# ABSTRACT: run command in many repositories
use 5.014;

use Capture::Tiny qw/ capture_stdout /;
use File::chdir;
use Types::Standard -types;

use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'command|e=s' => 'command to execute in the different repos' => { required => 1 } ] ,
    [ 'with_repo'   => 'prepend all output lines with the repo name' => { default => 0 } ] ,
  );
}

sub _execute {
  my $self = shift;

  for my $repo ( $self->active_repos ) {
    $self->_run_in_repo( $repo => $self->opt->command );
  }
}

sub _run_in_repo {
  my( $self, $repo, $cmd ) = @_;

  if ( not -d $repo->path ) {
    printf "repo %s: no repository found at path '%s'\n",
      $repo->label, $repo->path;
    return;
  }

  say "\n## repo ", $repo->label, "\n" unless $self->opt->with_repo;

  my $prefix = $self->opt->with_repo ? $repo->label . ': ' : '';

  say $prefix, $_ for split "\n", capture_stdout {
    $CWD = $repo->path;
    system $cmd;
  };
}

1;

### FIXME docs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Command::do - run command in many repositories

=head1 VERSION

version 1.339

=head1 AUTHOR

John SJ Anderson <john@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
