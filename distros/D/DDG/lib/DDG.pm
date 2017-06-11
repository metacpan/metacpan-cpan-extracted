package DDG;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: DuckDuckGo Search Engines Open Source Parts
$DDG::VERSION = '1017';

use strict;
use warnings;

use File::ShareDir::ProjectDistDir;

use Exporter 'import';

our @EXPORT = qw( templates_dir );

sub templates_dir { File::Spec->rel2abs( File::Spec->catfile(dist_dir('DDG'), 'templates') ) }

1;

__END__

=pod

=head1 NAME

DDG - DuckDuckGo Search Engines Open Source Parts

=head1 VERSION

version 1017

=head1 DESCRIPTION

This is the main DDG class which is right now only used for storing the function for getting the not yet used template directory.
Longtime it will get probably a kind of metaclass or stays a general configuration class. Please dont use it for anything.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
