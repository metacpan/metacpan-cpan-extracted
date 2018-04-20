package CPAN::Testers::API::Controller::Release;
our $VERSION = '0.025';
# ABSTRACT: API for test reports collected by CPAN release

#pod =head1 DESCRIPTION
#pod
#pod This API accesses summary data collected by CPAN release. So, if you
#pod just want to know how many PASS and FAIL reports a single distribution
#pod has for each version released, this is the best API.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item L<CPAN::Testers::Schema::Result::Release>
#pod
#pod =item L<Mojolicious::Controller>
#pod
#pod =back
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Controller';
use CPAN::Testers::API::Base;

#pod =method release
#pod
#pod     ### Requests:
#pod     GET /v3/release
#pod     GET /v3/release/dist/My-Dist
#pod     GET /v3/release/author/PREACTION
#pod
#pod     ### Optional query parameters (may be combined):
#pod     # ?since=2016-01-01T12:34:00
#pod     # ?maturity=stable
#pod     # ?limit=2
#pod
#pod     ### Response:
#pod     200 OK
#pod     Content-Type: application/json
#pod
#pod     [
#pod         {
#pod             "dist": "My-Dist",
#pod             "version": "1.000",
#pod             "pass": 34,
#pod             "fail": 2,
#pod             "na": 1,
#pod             "unknown": 0
#pod         }
#pod     ]
#pod
#pod Get release data. Results can be limited by:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod distribution (with the C<dist> key in the stash)
#pod
#pod =item *
#pod
#pod author (with the C<author> key in the stash)
#pod
#pod =item *
#pod
#pod date (with the C<since> query parameter)
#pod
#pod =item *
#pod
#pod maturity (with the C<maturity> query parameter)
#pod
#pod =item *
#pod
#pod limit (limits the total number of results sent with the C<limit> query parameter)
#pod
#pod =back
#pod
#pod Release data contains a summary of the pass, fail, na, and unknown test
#pod results created by stable Perls. Development Perls (odd-numbered 5.XX
#pod releases) are not included.
#pod
#pod =cut

sub release( $c ) {
    $c->openapi->valid_input or return;

    my $rs = $c->schema->resultset( 'Release' );
    $rs = $rs->search(
        {
            perlmat => 1, # only stable perls
            patched => 1, # not patched perls
        },
        {
            columns => [qw( dist version pass fail na unknown )],
            # Only get hashrefs out
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    );

    # Only allow "since" for "dist" and "author" because the query can
    # not be optimized to return in a reasonable time.
    if ( my $since = $c->param( 'since' ) ) {
        unless ( $c->validation->param( 'dist' ) || $c->validation->param( 'author' ) ) {
            return $c->render_error( 400 => '"since" parameter not allowed' );
        }
        $rs = $rs->since( $since );
    }

    if ( my $maturity = $c->param( 'maturity' ) ) {
        $rs = $rs->maturity( $maturity );
    }

    my @results;
    my $limit = $c->param( 'limit' );
    # OpenAPI spec doesn't support property "minimum" on parameters
    if ( $limit and $limit < 1 ) {
        return $c->render_error( 400 => 'The value for "limit" must be a positive integer' );
    }
    if ( $limit ) {
        $rs = $rs->slice( 0, $limit - 1 );
    }

    if ( my $dist = $c->validation->param( 'dist' ) ) {
        $rs = $rs->by_dist( $dist );
    }
    elsif ( my $author = $c->validation->param( 'author' ) ) {
        $rs = $rs->by_author( $author );
    }

    return $c->stream_rs( $rs );
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::API::Controller::Release - API for test reports collected by CPAN release

=head1 VERSION

version 0.025

=head1 DESCRIPTION

This API accesses summary data collected by CPAN release. So, if you
just want to know how many PASS and FAIL reports a single distribution
has for each version released, this is the best API.

=head1 METHODS

=head2 release

    ### Requests:
    GET /v3/release
    GET /v3/release/dist/My-Dist
    GET /v3/release/author/PREACTION

    ### Optional query parameters (may be combined):
    # ?since=2016-01-01T12:34:00
    # ?maturity=stable
    # ?limit=2

    ### Response:
    200 OK
    Content-Type: application/json

    [
        {
            "dist": "My-Dist",
            "version": "1.000",
            "pass": 34,
            "fail": 2,
            "na": 1,
            "unknown": 0
        }
    ]

Get release data. Results can be limited by:

=over

=item *

distribution (with the C<dist> key in the stash)

=item *

author (with the C<author> key in the stash)

=item *

date (with the C<since> query parameter)

=item *

maturity (with the C<maturity> query parameter)

=item *

limit (limits the total number of results sent with the C<limit> query parameter)

=back

Release data contains a summary of the pass, fail, na, and unknown test
results created by stable Perls. Development Perls (odd-numbered 5.XX
releases) are not included.

=head1 SEE ALSO

=over

=item L<CPAN::Testers::Schema::Result::Release>

=item L<Mojolicious::Controller>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
