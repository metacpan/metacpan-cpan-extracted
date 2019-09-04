package App::DBCritic::Loader;

# ABSTRACT: Loader class for schemas generated from a database connection

#pod =head1 SYNOPSIS
#pod
#pod     use App::DBCritic::Loader;
#pod     my $schema = App::DBCritic::Loader->connect('dbi:sqlite:foo');
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a simple subclass of
#pod L<DBIx::Class::Schema::Loader|DBIx::Class::Schema::Loader> used by
#pod L<App::DBCritic|App::DBCritic> to dynamically
#pod generate a schema based on a database connection.
#pod
#pod =cut

use strict;
use utf8;
use Modern::Perl '2011';    ## no critic (Modules::ProhibitUseQuotedVersion)

our $VERSION = '0.023';     # VERSION
use Moo;
extends 'DBIx::Class::Schema::Loader';
__PACKAGE__->loader_options( naming => 'v4', generate_pod => 0 );
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Mark Gardner cpan testmatrix url annocpan anno bugtracker rt cpants
kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

App::DBCritic::Loader - Loader class for schemas generated from a database connection

=head1 VERSION

version 0.023

=head1 SYNOPSIS

    use App::DBCritic::Loader;
    my $schema = App::DBCritic::Loader->connect('dbi:sqlite:foo');

=head1 DESCRIPTION

This is a simple subclass of
L<DBIx::Class::Schema::Loader|DBIx::Class::Schema::Loader> used by
L<App::DBCritic|App::DBCritic> to dynamically
generate a schema based on a database connection.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc App::DBCritic::Loader

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-DBCritic>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-DBCritic>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-DBCritic>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-DBCritic>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-DBCritic>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=bin::dbcritic>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at L<https://github.com/mjgardner/dbcritic/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/dbcritic>

  git clone git://github.com/mjgardner/dbcritic.git

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Mark Gardner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
