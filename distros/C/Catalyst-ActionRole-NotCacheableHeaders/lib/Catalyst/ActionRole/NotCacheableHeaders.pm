package Catalyst::ActionRole::NotCacheableHeaders;
BEGIN {
  $Catalyst::ActionRole::NotCacheableHeaders::VERSION = '0.02';
}
# ABSTRACT: Set no cache headers for actions

use strict;
use Moose::Role;
use HTTP::Date qw(time2str);

after 'execute' => sub {
    my $self = shift;
    my ($controller, $c, @args) = @_;

    if ( exists $c->action->attributes->{NotCacheable} ) {
        $c->response->header(
            'Expires' =>  'Thu, 01 Jan 1970 00:00:00 GMT',
            'Pragma' => 'no-cache',
            'Cache-Control' => 'no-cache',
            'Last-Modified' => time2str( time ),
        );
    }
};

no Moose::Role;

1; # End of Catalyst::ActionRole::NotCacheableHeaders



__END__
=pod

=encoding utf-8

=head1 NAME

Catalyst::ActionRole::NotCacheableHeaders - Set no cache headers for actions

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    package MyApp::Controller::Foo;
    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller::ActionRole' }

    __PACKAGE__->config(
        action_roles => [qw( NotCacheableHeaders )],
    );

    sub dont_cache_me : Local NotCacheable { ... }

=head1 DESCRIPTION

Provides a ActionRole to set HTTP headers instructing proxies and browsers to
not cache the response.

    Pragma: no-cache
    Cache-Control: no-cache
    Expires: Thu, 01 Jan 1970 00:00:00 GMT
    Last-Modified: %current time%

Please note that if any of above headers were already set they will be
overwritten.

=head1 SEE ALSO

Take a look at L<Catalyst::ActionRole::ExpiresHeader> if you want to set the
C<Expires> header only.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

