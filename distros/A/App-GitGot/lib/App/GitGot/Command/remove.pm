package App::GitGot::Command::remove;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Command::remove::VERSION = '1.335';
# ABSTRACT: remove a managed repository from your config
use 5.014;

use List::Util qw/ any /;

use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub command_names { qw/ remove rm / }

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'force' => 'FIXME' ] ,
  );
}

sub _use_io_page { 0 }

sub _execute {
  my( $self, $opt, $args ) = @_;

  unless ( $self->active_repos and @$args or $self->tags) {
    say STDERR "ERROR: You need to select one or more repos to remove";
    exit(1);
  }

  my @new_repo_list;

 REPO: for my $repo ( $self->all_repos ) {
    my $number = $repo->number;

    if ( any { $number == $_->number } $self->active_repos ) {
      my $name = $repo->label;

      if ( $self->opt->force or $self->prompt_yn( "got rm: remove '$name'?" )) {
        say "Removed repo '$name'" if $self->verbose;
        next REPO;
      }
    }
    push @new_repo_list , $repo;
  }

  $self->set_full_repo_list( \@new_repo_list );
  $self->write_config();
}

1;

## FIXME docs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Command::remove - remove a managed repository from your config

=head1 VERSION

version 1.335

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
