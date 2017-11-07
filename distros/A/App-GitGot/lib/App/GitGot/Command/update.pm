package App::GitGot::Command::update;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Command::update::VERSION = '1.334';
# ABSTRACT: update managed repositories
use 5.014;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub command_names { qw/ update up / }

sub _execute {
  my ( $self, $opt, $args ) = @_;

  $self->_update( $self->active_repos );
}

1;

## FIXME docs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Command::update - update managed repositories

=head1 VERSION

version 1.334

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
