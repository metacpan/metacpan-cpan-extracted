package App::RepoSync;
use strict;
use warnings;
our $VERSION = '0.03';






1;
__END__

=head1 NAME

App::RepoSync - an application that helps you import,export,sync repositories.

=head1 SYNOPSIS

Export repository mapping into a YAML file:

    $ repo export [yaml file] [dirs ...]

Import repository mapping into a YAML file:

    $ repo import [yaml file]

=head1 DESCRIPTION

App::RepoSync is an application helps you import, export, sync
Git,SVN,git-svn,Mercurial repositories.

=head1 AUTHOR

Yo-An Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
