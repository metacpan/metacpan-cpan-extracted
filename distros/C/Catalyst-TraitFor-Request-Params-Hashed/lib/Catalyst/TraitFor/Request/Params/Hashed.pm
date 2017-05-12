package Catalyst::TraitFor::Request::Params::Hashed;

use namespace::autoclean;
use Moose::Role;
use MooseX::Types::Moose qw/ HashRef /;

our $VERSION = '0.03';

=head1 NAME

Catalyst::TraitFor::Request::Params::Hashed - Access to parameters
like C<name[index]> as hashes for Catalyst::Request.

=head1 VERSION

Version is 0.03

=head1 SYNOPSIS

    #
    # application class
    #
    package TestApp;

    use Moose;
    use namespace::autoclean;
    use Catalyst qw/ ......... /;
    extends 'Catalyst';
    use CatalystX::RoleApplicator;
    
    __PACKAGE__->apply_request_class_roles(qw/
        Catalyst::TraitFor::Request::Params::Hashed
    /);

    #
    # controller class
    #
    package TestApp::Controller::Test;
    .........
        # query string was like
        # site[name1]=100&site[name1]=150&site[name2]=200
        my $site = $c->req->hashed_params->{site};

        # $site is hashref:
        #
        # $site = {
        #   name1 => [100, 150],
        #   name2 => 200,
        # }
    .........

=head1 DESCRIPTION

You can access C<hashed_parameters>, C<hashed_query_parameters>,
C<hashed_body_parameters> to get access to parameters as to hashes.
Also you can use C<hashes_params>, C<hashed_query_params> and
C<hashed_body_params> as shortcuts. Or, if you too lazy, you can use
C<hparams>, C<hquery_params> and C<hbody_params> :)

Note, that this trait gives you read-only version of C<params>,
C<query_params> and C<body_params> respectively. Also note, that
any change to any of three above <WILL NOT HAVE> any effect to all
of C<hashed*params>.

=cut

has hashed_parameters => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_hashed_parameters',
);

has hashed_query_parameters => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_hashed_query_parameters',
);

has hashed_body_parameters => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_hashed_body_parameters',
);

sub __build_hashed {
    my ( $self, $params ) = @_;
    $params = {%$params};    # make copy
    for my $key ( keys %$params ) {
        next unless $key =~ m/^([^[]+)\[(.*)\]$/;
        $params->{$1}{$2} = delete $params->{$key};
    }
    return $params;
}

sub _build_hashed_parameters {
    my ($self) = @_;
    return $self->__build_hashed( $self->parameters );
}

sub _build_hashed_query_parameters {
    my ($self) = @_;
    return $self->__build_hashed( $self->query_parameters );
}

sub _build_hashed_body_parameters {
    my ($self) = @_;
    return $self->__build_hashed( $self->body_parameters );
}

=head1 METHODS

=head2 hashed_params

=head2 hparams

=head2 hashed_query_params

=head2 hquery_params

=head2 hashed_body_params

=head2 hbody_params

=cut

sub hashed_params       { shift->hashed_parameters }
sub hparams             { shift->hashed_parameters }
sub hashed_query_params { shift->hashed_query_parameters }
sub hquery_params       { shift->hashed_query_parameters }
sub hashed_body_params  { shift->hashed_body_parameters }
sub hbody_params        { shift->hashed_body_parameters }

=head1 TODO

Write tests.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Request>, C<Catalyst::TraitFor::Request::BrowserDetect>

=head1 SUPPORT

=over 4

=item * Report bugs or feature requests

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-TraitFor-Request-Params-Hashed>

L<http://www.assembla.com/spaces/Catalyst-TraitFor-Request-Params-Hashed/tickets>

=item * Git repository

git clone git://git.assembla.com/Catalyst-TraitFor-Request-Params-Hashed.git

=back

=head1 AUTHOR

Oleg Kostyuk, C<< <cub#cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Oleg Kostyuk.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Catalyst::TraitFor::Request::Params::Hashed
