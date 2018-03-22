package App::GitGot::Command::move;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Command::move::VERSION = '1.335';
# ABSTRACT: move repo to new location
use 5.014;

use Cwd;
use File::Copy::Recursive qw/ dirmove /;
use Path::Tiny;

use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub command_names { qw/ move mv / }

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'destination=s' => 'FIXME' => { required => 1 } ] ,
  );
}

sub _execute {
  my( $self, $opt, $args ) = @_;

  my @repos = $self->active_repos;

  my $dest = $self->opt->destination;

  path($dest)->mkpath if @repos > 1;

  for my $repo ( @repos ) {
    my $target_dir = -d $dest
      ? path($dest)->child( path($repo->path)->basename )
      : $dest;

    dirmove( $repo->path => $target_dir )
      or die "couldn't move ", $repo->name, " to '$target_dir': $!";

    $repo->{path} = "$target_dir";
    $self->write_config;

    say sprintf '%s moved to %s', $repo->name, $target_dir;
  }
}

1;

## FIXME docs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Command::move - move repo to new location

=head1 VERSION

version 1.335

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
