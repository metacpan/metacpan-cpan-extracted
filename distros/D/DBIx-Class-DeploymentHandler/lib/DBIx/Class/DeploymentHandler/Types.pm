package DBIx::Class::DeploymentHandler::Types;
$DBIx::Class::DeploymentHandler::Types::VERSION = '0.002227';
use strict;
use warnings;
use IO::All;

# ABSTRACT: Types internal to DBIx::Class::DeploymentHandler

use Type::Library
  -base,
  -declare => qw( Databases VersionNonObj DirObject );
use Type::Utils -all;
BEGIN { extends "Types::Standard" };

declare Databases, as ArrayRef[Str];

coerce Databases,
  from Str, via { [ $_ ] };

declare VersionNonObj, as Str;

coerce VersionNonObj,
  from InstanceOf['version'], via { $_->numify + 0 };

declare DirObject, as InstanceOf['IO::All::Dir'];
coerce DirObject,
  from Str, via { io->dir($_) };

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=head1 NAME

DBIx::Class::DeploymentHandler::Types - Types internal to DBIx::Class::DeploymentHandler

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
