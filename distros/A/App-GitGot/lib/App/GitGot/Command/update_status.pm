package App::GitGot::Command::update_status;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Command::update_status::VERSION = '1.336';
# ABSTRACT: update managed repositories then display their status
use 5.014;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub command_names { qw/ update_status upst / }

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'show-branch' => 'show which branch' => { default => 0 } ] ,
  );
}

sub _execute {
  my ( $self, $opt, $args ) = @_;

  say "UPDATE";
  $self->_update( $self->active_repos );

  say "\nSTATUS";
  $self->_status( $self->active_repos );
}

1;

## FIXME docs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Command::update_status - update managed repositories then display their status

=head1 VERSION

version 1.336

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
