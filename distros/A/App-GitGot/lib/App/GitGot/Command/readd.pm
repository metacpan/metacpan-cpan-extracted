package App::GitGot::Command::readd;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Command::readd::VERSION = '1.337';
# ABSTRACT: update config metadata to match repo
use 5.014;

use App::GitGot -command;
use App::GitGot::Repo::Git;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub options {
  my( $class , $app ) = @_;
  return ();
}

sub _use_io_page { 0 }

sub _execute {
  my ( $self, $opt, $args ) = @_;

  my $max_len        = $self->max_length_of_an_active_repo_label();
  my $updated_config = 0;

 REPO: for my $repo ( $self->active_repos ) {
   next unless $repo->type eq 'git';

   my $configuration_url = $repo->repo;
   my( $repo_url ) = $repo->config("remote.origin.url");

   if( $configuration_url ne $repo_url ) {
     # do as i say, not as i do...
     $repo->{repo}   = $repo_url;
     $updated_config = 1;

     printf "Updated repo url for %-${max_len}s to %s\n", $repo->name, $repo->repo
         if $self->verbose;
   }
 }

  $self->write_config()
     if $updated_config;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Command::readd - update config metadata to match repo

=head1 VERSION

version 1.337

=head1 SYNOPSIS

# update ~/.gitgot to reflect current remotes
$ got readd

=head1 AUTHOR

John SJ Anderson <john@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
