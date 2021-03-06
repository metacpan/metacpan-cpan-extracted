package App::GitGot::Command::checkout;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Command::checkout::VERSION = '1.339';
# ABSTRACT: checkout specific branch for managed repositories
use 5.014;

use Try::Tiny;

use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'branch=s' => 'branch to checkout in the different repos' => { required => 1 } ] ,
    [ 'create|b' => 'create branch like checkout -b in each of the repos' ],
  );
}

sub _execute {
  my( $self, $opt, $args ) = @_;

  $self->_checkout( $self->opt->branch, $self->active_repos );
}

sub _checkout {
  my( $self , $branch, @repos ) = @_;

  my $max_len = $self->max_length_of_an_active_repo_label;

 REPO: for my $repo ( @repos ) {
    next REPO unless $repo->repo;

    my $name = $repo->name;

    my $msg = sprintf "%3d) %-${max_len}s  : ", $repo->number, $repo->label;

    my ( $status, $fxn );

    my $repo_type = $repo->type;

    if ( $repo_type eq 'git' ) { $fxn = '_git_checkout' }
    ### FIXME elsif( $repo_type eq 'svn' ) { $fxn = 'svn_update' }
    else { $status = $self->error("ERROR: repo type '$_' not supported") }

    $status = $self->$fxn($repo, $branch) if ($fxn);

    next REPO if $self->quiet and !$status;

    say "$msg$status";
  }
}

sub _git_checkout {
  my ( $self, $entry, $branch ) = @_
    or die "Need entry";

  # no callback because we need to run checkout even if just cloned
  $self->_git_clone_or_callback( $entry , sub { '' } );

  my $msg = '';

  my @o = try { $entry->checkout($self->opt->create ? '-b' : (), $branch); } catch { $_->error };

  my @err = try { @{ $entry->_wrapper->ERR } } catch { $_ };

  # Typically STDOUT will contain something similar to
  # Your branch is up-to-date with 'origin/main'.
  # or
  # Your branch is ahead of 'origin/main' by 2 commits.

  # Typically STDERR will contain something similar to
  # Switched to branch 'beta'
  # or
  # Already on 'beta'
  if ( grep { /(ahead|behind).*?by (\d+) commits./ } @o ) {
    # branch checked out but not yet in sync
    $msg .= $self->major_change("\u$1\e by $2");
  }
  elsif ( grep { /^Switched to/ } @err ) {
    # branch checked out and in sync
    $msg .= $self->major_change('Checked out');
    #$msg .= "\n" . join("\n",@err) unless $self->quiet;
  }
  elsif ( grep { /^Already on/ } @err ) {
    # already on requested branch
    $msg .= $self->minor_change('OK') unless $self->quiet;
  }
  elsif ( grep { /did not match/ } @o ) {
    # branch doesn't exist and was not created
    $msg .= $self->error('Unknown branch');
  }
  elsif ( scalar @o == 0 && scalar @err == 0 ) {
    # No messages to STDERR means repo was already updated (or this is a test)
    $msg .= $self->minor_change('OK') unless $self->quiet;
  }
  else {
    # Something else occured (possibly a warning)
    # Print STDOUT/STDERR and move on
    $msg .= $self->warning('Problem during checkout');
    $msg .= "\n" . join("\n", @o, @err) unless $self->quiet;
    return $msg;
  }

  return $msg;
}

1;

### FIXME docs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Command::checkout - checkout specific branch for managed repositories

=head1 VERSION

version 1.339

=head1 AUTHOR

John SJ Anderson <john@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
