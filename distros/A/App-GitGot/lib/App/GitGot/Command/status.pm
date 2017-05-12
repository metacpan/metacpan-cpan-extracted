package App::GitGot::Command::status;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Command::status::VERSION = '1.333';
# ABSTRACT: print status info about repos
use 5.014;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub command_names { qw/ status st / }

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'show-branch' => 'show which branch' => { default => 0 } ] ,
  );
}


sub _execute {
  my ( $self, $opt, $args ) = @_;

  $self->_status( $self->active_repos );
}

1;

## FIXME docs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Command::status - print status info about repos

=head1 VERSION

version 1.333

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
