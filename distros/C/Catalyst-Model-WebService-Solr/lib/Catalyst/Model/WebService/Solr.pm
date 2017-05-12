package Catalyst::Model::WebService::Solr;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;
use WebService::Solr;

extends 'Catalyst::Model';

has 'server' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://localhost:8983/solr',
);

has 'options' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'solr' => (
    is         => 'ro',
    isa        => 'WebService::Solr',
    handles    => qr{^[^_].*},
    lazy_build => 1
);

our $VERSION = '0.04';

sub _build_solr {
    my $self   = shift;

    return WebService::Solr->new( $self->server, $self->options );
}

1;

__END__

=head1 NAME

Catalyst::Model::WebService::Solr - Use WebService::Solr in your Catalyst application

=head1 SYNOPSIS

    package MyApp::Model::Solr;
    
    use Moose;
    use namespace::autoclean;
    
    extends 'Catalyst::Model::WebService::Solr';
    
    __PACKAGE__->config(
        server  => 'http://localhost:8080/solr/',
        options => {
            autocommit => 1,
        }
    );

=head1 DESCRIPTION

This module helps you use remote indexes via WebService::Solr in your
Catalyst application.

=head1 METHODS

=head2 solr( )

This is the L<WebService::Solr> instance to which all methods are delegated.

    # delegates to solr->search behind the scenes
    my $response = $c->model('Solr')->search( $q );

=head1 SEE ALSO

=over 4

=item * L<Catalyst>

=item * L<WebService::Solr>

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 CONTRIBUTORS

Matt S. Trout E<lt>mst@shadowcatsystems.co.ukE<gt>

Oleg Kostyuk E<lt>cub@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
