package App::GitGot::Command::fetch;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Command::fetch::VERSION = '1.336';
# ABSTRACT: fetch remotes for managed repositories
use 5.014;

use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub _execute {
  my ( $self, $opt, $args ) = @_;

  $self->_fetch( $self->active_repos );
}

1;

### FIXME docs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Command::fetch - fetch remotes for managed repositories

=head1 VERSION

version 1.336

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
