package Catalyst::TraitFor::Request::BrowserDetect;
our $VERSION = '0.02';

# ABSTRACT: Browser detection for Catalyst::Requests

use Moose::Role;
use aliased 'HTTP::BrowserDetect';
use namespace::autoclean;


has browser => (
    is      => 'ro',
    isa     => BrowserDetect,
    lazy    => 1,
    builder => '_build_browser',
);

requires 'user_agent';

sub _build_browser {
    my ($self) = @_;
    return BrowserDetect->new($self->user_agent);
}

1;

__END__

=pod

=head1 NAME

Catalyst::TraitFor::Request::BrowserDetect - Browser detection for Catalyst::Requests

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    package MyApp;

    use Moose;
    use namespace::autoclean;

    use Catalyst;
    use CatalystX::RoleApplicator;

    extends 'Catalyst';

    __PACKAGE__->apply_request_class_roles(qw/
        Catalyst::TraitFor::Request::BrowserDetect
    /);

    __PACKAGE__->setup;

=head1 DESCRIPTION

Extend request objects with a method for browser detection.

=head1 ATTRIBUTES

=head2 browser

    my $browser = $ctx->request->browser;

Returns an C<HTTP::BrowserDetect> instance for the request. This allows you to
get information about the client's user agent.



=head1 AUTHOR

  Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 


