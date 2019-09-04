package App::DBCritic::Violation;

# ABSTRACT: A violation of a App::DBCritic::Policy

#pod =head1 SYNOPSIS
#pod
#pod     use App::DBCritic::Violation;
#pod
#pod     my $violation = App::DBCritic::Violation->new(
#pod         description => 'Violated policy',
#pod         explanation => 'Consult the rulebook',
#pod         description => 'The frob table is improperly swizzled.',
#pod     );
#pod     print "$violation\n";
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class represents L<App::DBCritic::Policy|App::DBCritic::Policy>
#pod violations flagged by L<App::DBCritic|App::DBCritic>.
#pod
#pod =cut

use strict;
use utf8;
use Modern::Perl '2011';    ## no critic (Modules::ProhibitUseQuotedVersion)

our $VERSION = '0.023';     # VERSION
use Const::Fast;
use English '-no_match_vars';
use Moo;
use Sub::Quote;
use overload q{""} => sub { shift->as_string };

const my @TEXT_FIELDS => qw(description explanation details);
for (@TEXT_FIELDS) {
    has $_ => ( is => 'ro', default => quote_sub q{q{}} );
}

#pod =attr description
#pod
#pod A short string briefly describing what's wrong.
#pod Only settable at construction.
#pod
#pod =attr explanation
#pod
#pod A string giving a longer general description of the problem.
#pod Only settable at construction.
#pod
#pod =attr details
#pod
#pod A string describing the issue as it specifically applies to the L</element>
#pod being critiqued.
#pod
#pod =cut

has element => ( is => 'ro' );

#pod =attr element
#pod
#pod The schema element that violated a
#pod L<App::DBCritic::Policy|App::DBCritic::Policy>.
#pod Only settable at construction.
#pod
#pod =cut

has as_string => ( is => 'ro', lazy => 1, default => \&_build_as_string );

sub _build_as_string {
    my $self    = shift;
    my $element = $self->element;
    my $type    = ref $element;

    $type =~ s/\A .* :://xms;
    const my %TYPE_MAP => (
        Table     => $element->from,
        ResultSet => $element->result_class,
        Schema    => 'schema',
    );
    return "[$type $TYPE_MAP{$type}] " . join "\n",
        map { $self->$_ } @TEXT_FIELDS;
}

#pod =attr as_string
#pod
#pod Returns a string representation of the object.  The same method is called if
#pod the object appears in double quotes.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Mark Gardner cpan testmatrix url annocpan anno bugtracker rt cpants
kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

App::DBCritic::Violation - A violation of a App::DBCritic::Policy

=head1 VERSION

version 0.023

=head1 SYNOPSIS

    use App::DBCritic::Violation;

    my $violation = App::DBCritic::Violation->new(
        description => 'Violated policy',
        explanation => 'Consult the rulebook',
        description => 'The frob table is improperly swizzled.',
    );
    print "$violation\n";

=head1 DESCRIPTION

This class represents L<App::DBCritic::Policy|App::DBCritic::Policy>
violations flagged by L<App::DBCritic|App::DBCritic>.

=head1 ATTRIBUTES

=head2 description

A short string briefly describing what's wrong.
Only settable at construction.

=head2 explanation

A string giving a longer general description of the problem.
Only settable at construction.

=head2 details

A string describing the issue as it specifically applies to the L</element>
being critiqued.

=head2 element

The schema element that violated a
L<App::DBCritic::Policy|App::DBCritic::Policy>.
Only settable at construction.

=head2 as_string

Returns a string representation of the object.  The same method is called if
the object appears in double quotes.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc App::DBCritic::Violation

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
