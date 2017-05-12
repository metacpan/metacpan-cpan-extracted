package App::DBCritic;

use strict;
use utf8;
use Modern::Perl;

our $VERSION = '0.020';    # VERSION
use Carp;
use English '-no_match_vars';
use List::MoreUtils 'any';
use Module::Pluggable
    search_path => [ __PACKAGE__ . '::Policy' ],
    sub_name    => 'policies',
    instantiate => 'new';
use Moo;
use Scalar::Util 'blessed';
use App::DBCritic::Loader;

for (qw(username password class_name)) { has $ARG => ( is => 'ro' ) }

has dsn => ( is => 'ro', lazy => 1, default => \&_build_dsn );

sub _build_dsn {
    my $self = shift;

    ## no critic (ValuesAndExpressions::ProhibitAccessOfPrivateData)
    my $dbh = $self->schema->storage->dbh;
    return join q{:} => 'dbi', $dbh->{Driver}{Name}, $dbh->{Name};
}

has schema => (
    is      => 'ro',
    coerce  => 1,
    lazy    => 1,
    default => \&_build_schema,
    coerce  => \&_coerce_schema,
);

sub _build_schema {
    my $self = shift;

    my @connect_info = map { $self->$ARG } qw(dsn username password);

    if ( my $class_name = $self->class_name ) {
        return $class_name->connect(@connect_info)
            if eval "require $class_name";
    }

    return _coerce_schema( \@connect_info );
}

sub _coerce_schema {
    my $schema = shift;

    return $schema if blessed $schema and $schema->isa('DBIx::Class::Schema');

    local $SIG{__WARN__} = sub {
        if ( $ARG[0] !~ / has no primary key at /ms ) {
            print {*STDERR} $ARG[0];
        }
    };
    return App::DBCritic::Loader->connect( @{$schema} )
        if ref $schema eq 'ARRAY';
    ## no critic (ErrorHandling::RequireUseOfExceptions)
    croak q{don't know how to make a schema from a } . ref $schema;
}

has _elements => ( is => 'ro', lazy => 1, default => \&_build__elements );

sub _build__elements {
    my $self   = shift;
    my $schema = $self->schema;
    return {
        Schema       => [$schema],
        ResultSource => [ map { $schema->source($ARG) } $schema->sources ],
        ResultSet    => [ map { $schema->resultset($ARG) } $schema->sources ],
    };
}

sub critique {
    for ( @{ shift->violations } ) {say}
    return;
}

has violations => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        [   map { $self->_policy_loop( $ARG, $self->_elements->{$ARG} ) }
                keys %{ $self->_elements },
        ];
    },
);

sub _policy_loop {
    my ( $self, $policy_type, $elements_ref ) = @_;
    my @violations;
    for my $policy ( grep { _policy_applies_to( $ARG, $policy_type ) }
        $self->policies )
    {
        push @violations, grep {$ARG}
            map { $policy->violates( $ARG, $self->schema ) } @{$elements_ref};
    }
    return @violations;
}

sub _policy_applies_to {
    my ( $policy, $type ) = @_;
    return any { $ARG eq $type } @{ $policy->applies_to };
}

1;

# ABSTRACT: Critique a database schema for best practices

__END__

=pod

=for :stopwords Mark Gardner cpan testmatrix url annocpan anno bugtracker rt cpants
kwalitee diff irc mailto metadata placeholders

=encoding utf8

=head1 NAME

App::DBCritic - Critique a database schema for best practices

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use App::DBCritic;

    my $critic = App::DBCritic->new(
        dsn => 'dbi:Oracle:HR', username => 'scott', password => 'tiger');
    $critic->critique();

=head1 DESCRIPTION

This package is used to scan a database schema and catalog any violations
of best practices as defined by a set of policy plugins.  It takes conceptual
and API inspiration from L<Perl::Critic|Perl::Critic>.

B<dbcritic> is the command line interface.

This is a work in progress - please see the L</SUPPORT> section below for
information on how to contribute.  It especially needs ideas (and
implementations!) of new policies!

=head1 ATTRIBUTES

=head2 class_name

The name of a L<DBIx::Class::Schema|DBIx::Class::Schema> class you wish to
L</critique>.
Only settable at construction time.

=head2 schema

A L<DBIx::Class::Schema|DBIx::Class::Schema> object you wish to L</critique>.
Only settable at construction time.

=head2 dsn

=head2 username

=head2 password

The L<DBI|DBI> data source name (required) and optional username and password
used to connect to the database.  If no L</class_name> or L</schema> is
provided, L<DBIx::Class::Schema::Loader|DBIx::Class::Schema::Loader> will then
construct schema classes dynamically to be critiqued.

=head1 METHODS

=head2 policies

Returns an array of loaded policy names that will be applied during
L</critique>.  By default all modules under the
C<App::DBCritic::Policy> namespace are loaded.

=head2 critique

Runs the L</schema> through the C<App::DBCritic> engine using all
the policies that have been loaded and dumps a string representation of
L</violations> to C<STDOUT>.

=head2 violations

Returns an array reference of all
L<App::DBCritic::Violation|App::DBCritic::Violation>s
picked up by the various policies.

=head1 SEE ALSO

=over

=item L<Perl::Critic|Perl::Critic>

=item L<DBIx::Class|DBIx::Class>

=item L<DBIx::Class::Schema::Loader|DBIx::Class::Schema::Loader>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc bin::dbcritic

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-DBCritic>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annonations of Perl module documentation.

L<http://annocpan.org/dist/App-DBCritic>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-DBCritic>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/App-DBCritic>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-DBCritic>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual way to determine what Perls/platforms PASSed for a distribution.

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

This software is copyright (c) 2011 by Mark Gardner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
