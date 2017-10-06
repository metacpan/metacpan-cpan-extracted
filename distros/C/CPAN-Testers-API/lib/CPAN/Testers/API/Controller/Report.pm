package CPAN::Testers::API::Controller::Report;
our $VERSION = '0.020';
# ABSTRACT: Work with raw test reports

#pod =head1 DESCRIPTION
#pod
#pod This API allows working directly with the JSON report documents
#pod submitted by the army of testers of CPAN.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<CPAN::Testers::Schema::Result::TestReport>, L<Mojolicious::Controller>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Controller';
use CPAN::Testers::API::Base;

#pod =method report_post
#pod
#pod     ### Requests:
#pod     POST /v3/report
#pod     { ... }
#pod
#pod     ### Response:
#pod     201 Created
#pod     { "id": "..." }
#pod
#pod Submit a new CPAN Testers report. This is used by testers when they're
#pod finished running a test.
#pod
#pod =cut

sub report_post( $c ) {
    $c->app->log->debug( 'Submitting Report: ' . $c->req->body );
    $c->openapi->valid_input or return;
    my $report = $c->validation->param( 'report' );
    my $row = $c->schema->resultset( 'TestReport' )->create( {
        report => $report,
    } );
    return $c->render(
        status => 201,
        openapi => {
            id => $row->id,
        },
    );
}

#pod =method report_get
#pod
#pod     ### Requests:
#pod     GET /v3/report/:guid
#pod
#pod     ### Response
#pod     200 OK
#pod     { "id": "...", ... }
#pod
#pod Get a single CPAN Testers report from the database.
#pod
#pod =cut

sub report_get( $c ) {
    $c->openapi->valid_input or return;
    my $id = $c->validation->param( 'id' );
    my $row = $c->schema->resultset( 'TestReport' )->find( $id );
    if ( !$row ) {
        return $c->render(
            status => 404,
            openapi => {
                errors => [
                    {
                        message => 'Report ID not found',
                        path => '/id',
                    },
                ],
            },
        );
    }
    return $c->render(
        openapi => $row->report,
    );
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::API::Controller::Report - Work with raw test reports

=head1 VERSION

version 0.020

=head1 DESCRIPTION

This API allows working directly with the JSON report documents
submitted by the army of testers of CPAN.

=head1 METHODS

=head2 report_post

    ### Requests:
    POST /v3/report
    { ... }

    ### Response:
    201 Created
    { "id": "..." }

Submit a new CPAN Testers report. This is used by testers when they're
finished running a test.

=head2 report_get

    ### Requests:
    GET /v3/report/:guid

    ### Response
    200 OK
    { "id": "...", ... }

Get a single CPAN Testers report from the database.

=head1 SEE ALSO

L<CPAN::Testers::Schema::Result::TestReport>, L<Mojolicious::Controller>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
