package App::DBCritic::PolicyType::ResultSource;

# ABSTRACT: Role for ResultSource critic policies

#pod =head1 SYNOPSIS
#pod
#pod     package App::DBCritic::Policy::MyResultSourcePolicy;
#pod     use Moo;
#pod
#pod     has description => ( default => sub{'Follow my policy'} );
#pod     has explanation => ( default => {'My way or the highway'} );
#pod     sub violates { $_[0]->element ne '' }
#pod
#pod     with 'App::DBCritic::PolicyType::ResultSource';
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a role composed into L<App::DBCritic|App::DBCritic> policy classes
#pod that are interested in L<ResultSource|DBIx::Class::ResultSource>s.  It takes
#pod care of composing the L<App::DBCritic::Policy|App::DBCritic::Policy>
#pod for you.
#pod
#pod =cut

use strict;
use utf8;
use Modern::Perl '2011';    ## no critic (Modules::ProhibitUseQuotedVersion)

our $VERSION = '0.023';     # VERSION
use Moo::Role;
use namespace::autoclean -also => qr{\A _}xms;
with 'App::DBCritic::PolicyType';
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Mark Gardner cpan testmatrix url annocpan anno bugtracker rt cpants
kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

App::DBCritic::PolicyType::ResultSource - Role for ResultSource critic policies

=head1 VERSION

version 0.023

=head1 SYNOPSIS

    package App::DBCritic::Policy::MyResultSourcePolicy;
    use Moo;

    has description => ( default => sub{'Follow my policy'} );
    has explanation => ( default => {'My way or the highway'} );
    sub violates { $_[0]->element ne '' }

    with 'App::DBCritic::PolicyType::ResultSource';

=head1 DESCRIPTION

This is a role composed into L<App::DBCritic|App::DBCritic> policy classes
that are interested in L<ResultSource|DBIx::Class::ResultSource>s.  It takes
care of composing the L<App::DBCritic::Policy|App::DBCritic::Policy>
for you.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc App::DBCritic::PolicyType::ResultSource

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
