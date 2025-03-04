package App::GitGot::Repo::Git;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Repo::Git::VERSION = '1.339';
# ABSTRACT: Git repo objects
use 5.014;

use Git::Wrapper;
use Test::MockObject;
use Try::Tiny;
use Types::Standard -types;

use App::GitGot::Types qw/ GitWrapper /;

use Moo;
extends 'App::GitGot::Repo';
use namespace::autoclean;

has '+type' => ( default => 'git' );

has '_wrapper' => (
  is         => 'lazy' ,
  isa        => GitWrapper ,
  handles    => [ qw/
                      checkout
                      cherry
                      clone
                      config
                      fetch
                      gc
                      pull
                      push
                      remote
                      status
                      symbolic_ref
                    / ] ,
);

sub _build__wrapper {
  my $self = shift;

  # for testing...
  if ( $ENV{GITGOT_FAKE_GIT_WRAPPER} ) {
    my $mock = Test::MockObject->new;
    $mock->set_isa( 'Git::Wrapper' );
    foreach my $method ( qw/ cherry clone fetch gc pull
                             remote symbolic_ref / ) {
      $mock->mock( $method => sub { return( '1' )});
    }
    $mock->mock( 'checkout' => sub { } );
    $mock->mock( 'status' => sub { package
                                     MyFake; sub get { return () }; return bless {} , 'MyFake' } );
    $mock->mock( 'config' => sub { 0 });
    $mock->mock( 'ERR'    => sub { [ ] });

    return $mock
  }
  else {
    return Git::Wrapper->new( $self->path )
      || die "Can't make Git::Wrapper";
  }
}



sub current_branch {
  my $self = shift;

  my $branch;

  try {
    ( $branch ) = $self->symbolic_ref( 'HEAD' );
    $branch =~ s|^refs/heads/|| if $branch;
  }
  catch {
    die $_ unless $_ && $_->isa('Git::Wrapper::Exception')
      && $_->error eq "fatal: ref HEAD is not a symbolic ref\n"
  };

  return $branch;
}


sub current_remote_branch {
  my( $self ) = shift;

  my $remote = 0;

  if ( my $branch = $self->current_branch ) {
    try {
      ( $remote ) = $self->config( "branch.$branch.remote" );
    }
    catch {
      ## not the most informative return....
      return 0 if $_ && $_->isa('Git::Wrapper::Exception') && $_->{status} eq '1';
    };
  }

  return $remote;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Repo::Git - Git repo objects

=head1 VERSION

version 1.339

=head1 METHODS

=head2 current_branch

Returns the current branch checked out by this repository object.

=head2 current_remote_branch

Returns the remote branch for the branch currently checked out by this repo
object, or 0 if that information can't be extracted (if, for example, the
branch doesn't have a remote.)

=head1 AUTHOR

John SJ Anderson <john@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
