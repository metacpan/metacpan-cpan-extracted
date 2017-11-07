package App::GitGot::Command::gc;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Command::gc::VERSION = '1.334';
# ABSTRACT: Run the 'gc' command to garbage collect in git repos
use 5.014;

use Data::Dumper;
use Try::Tiny;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

# incremental output looks nicer for this command...
STDOUT->autoflush(1);
sub _use_io_page { 0 }

sub _execute {
  my( $self, $opt, $args ) = @_;

  my $max_len = $self->max_length_of_an_active_repo_label;

 REPO: for my $repo ( $self->active_repos ) {
    next REPO unless $repo->type eq 'git';
    try {
      printf "%3d) %-${max_len}s : ", $repo->number , $repo->label unless $self->quiet;
      # really wish this gave _some_ kind of output...
      $repo->gc;
      printf "%s\n", $self->major_change( 'COLLECTED' ) unless $self->quiet;
    }
    catch {
      say STDERR $self->error( 'ERROR: Problem with GC on repo ' , $repo->label );
      say STDERR "\n" , Dumper $_;
    };
  }
}

1;

## FIXME docs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Command::gc - Run the 'gc' command to garbage collect in git repos

=head1 VERSION

version 1.334

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
