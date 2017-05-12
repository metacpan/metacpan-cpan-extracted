package CPAN::Testers::API::Controller::Release;
our $VERSION = '0.006';
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
#pod     GET /v1/release
#pod     GET /v1/release?since=2016-01-01T12:34:00Z
#pod     GET /v1/release/dist/My-Dist
#pod     GET /v1/release/dist/My-Dist?since=2016-01-01T12:34:00Z
#pod     GET /v1/release/author/PREACTION
#pod     GET /v1/release/author/PREACTION?since=2016-01-01T12:34:00Z
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
#pod Get release data. Results can be limited by distribution (with the
#pod C<dist> key in the stash), by author (with the C<author> key in the
#pod stash), and by date (with the C<since> query parameter).
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

    my @results;
    if ( my $dist = $c->validation->param( 'dist' ) ) {
        $rs = $rs->by_dist( $dist );
        @results = $rs->all;
        if ( !@results ) {
            return $c->render_error( 404, sprintf 'Distribution "%s" not found', $dist );
        }
    }
    elsif ( my $author = $c->validation->param( 'author' ) ) {
        @results = $rs->by_author( $author )->all;
        if ( !@results ) {
            return $c->render_error( 404, sprintf 'Author "%s" not found', $author );
        }
    }
    else {
        @results = $rs->all;
    }

    return $c->render(
        openapi => \@results,
    );
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::API::Controller::Release - API for test reports collected by CPAN release

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This API accesses summary data collected by CPAN release. So, if you
just want to know how many PASS and FAIL reports a single distribution
has for each version released, this is the best API.

=head1 METHODS

=head2 release

    ### Requests:
    GET /v1/release
    GET /v1/release?since=2016-01-01T12:34:00Z
    GET /v1/release/dist/My-Dist
    GET /v1/release/dist/My-Dist?since=2016-01-01T12:34:00Z
    GET /v1/release/author/PREACTION
    GET /v1/release/author/PREACTION?since=2016-01-01T12:34:00Z

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

Get release data. Results can be limited by distribution (with the
C<dist> key in the stash), by author (with the C<author> key in the
stash), and by date (with the C<since> query parameter).

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

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
