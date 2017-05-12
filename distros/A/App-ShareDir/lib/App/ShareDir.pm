package App::ShareDir;
BEGIN {
  $App::ShareDir::AUTHORITY = 'cpan:GETTY';
}
{
  $App::ShareDir::VERSION = '0.001';
}
# ABSTRACT: Applications for using File::ShareDir

use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

App::ShareDir - Applications for using File::ShareDir

=head1 VERSION

version 0.001

=head1 SYNOPSIS

On your shell:

  ~$ distdir File-ShareDir

  ~$ moduledir File::ShareDir

  ~$ distfile File-ShareDir file/name.txt

  ~$ modulefile File::ShareDir file/name.txt

  ~$ classfile Foo::Bar file/name.txt

=head1 DESCRIPTION

Just mapping the functions of L<File::ShareDir> to command line tools.

=head1 SUPPORT

Repository

  http://github.com/Getty/p5-app-sharedir
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-app-sharedir/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
