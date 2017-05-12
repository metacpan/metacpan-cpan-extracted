#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
#!D:\workspace\perl\perl\bin\perl.exe -w

use strict;
use warnings;

use Catalyst::ScriptRunner;
Catalyst::ScriptRunner->run('MyApp', 'Create');

1;

=head1 NAME

myapp_create.pl - Create a new Catalyst Component

=head1 SYNOPSIS

myapp_create.pl [options] model|view|controller name [helper] [options]

 Options:
   --force        don't create a .new file where a file to be created exists
   --mechanize    use Test::WWW::Mechanize::Catalyst for tests if available
   --help         display this help and exits

 Examples:
   myapp_create.pl controller My::Controller
   myapp_create.pl -mechanize controller My::Controller
   myapp_create.pl view My::View
   myapp_create.pl view MyView TT
   myapp_create.pl view TT TT
   myapp_create.pl model My::Model
   myapp_create.pl model SomeDB DBIC::Schema MyApp::Schema create=dynamic\
   dbi:SQLite:/tmp/my.db
   myapp_create.pl model AnotherDB DBIC::Schema MyApp::Schema create=static\
   dbi:Pg:dbname=foo root 4321

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Create a new Catalyst Component.

Existing component files are not overwritten.  If any of the component files
to be created already exist the file will be written with a '.new' suffix.
This behavior can be suppressed with the C<-force> option.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
