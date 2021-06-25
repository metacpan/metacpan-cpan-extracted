use strict;
use warnings;
package App::Cmd::Plugin 0.334;

# ABSTRACT: a plugin for App::Cmd commands

sub _faux_curried_method {
  my ($class, $name, $arg) = @_;

  return sub {
    my $cmd = $App::Cmd::active_cmd;
    $class->$name($cmd, @_);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cmd::Plugin - a plugin for App::Cmd commands

=head1 VERSION

version 0.334

=head1 PERL VERSION SUPPORT

This module has a long-term perl support period.  That means it will not
require a version of perl released fewer than five years ago.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
