package Catalyst::Plugin::DefaultEnd;

use base qw/Catalyst::Controller/;

use strict;
our $VERSION = '0.08';

=head1 NAME

Catalyst::Plugin::DefaultEnd - DEPRECATED Sensible default end action.

=head1 SYNOPSIS

    use Catalyst qw/-Debug DefaultEnd/;

=head1 WARNING

This module is deprecated, and B<should not be used in new applications>.

Please use L<Catalyst::Action::RenderView> instead. It is preserved here for
backwards compatibility reasons.

=head1 DESCRIPTION

This action implements a sensible default end action, which will forward
to the first available view, unless status is set to 3xx, or there is a
response body. It also allows you to pass dump_info=1 to the url in order
to force a debug screen, while in debug mode.

If you have more than 1 view, you can specify which one to use with the
'view' config setting.

=head1 METHODS

=over 4

=item end

The default end action, you can override this as required in your application
class, normal inheritance applies.

=cut

sub end : Private {
    my ( $self, $c ) = @_;
    die "forced debug" if $c->debug && $c->req->params->{dump_info};
    return 1 if $c->req->method eq 'HEAD';
    return 1 if scalar @{ $c->error } && !$c->stash->{template};
    return 1 if $c->response->status =~ /^(?:401|204|3\d\d)$/;
    unless ( $c->response->content_type ) {
        $c->response->content_type('text/html; charset=utf-8');
    }
    return 1                                 if $c->response->body;
    return $c->forward( $c->config->{view} ) if $c->config->{view};
    my ($comp) = $c->comp( '^' . ref($c) . '::(V|View)::' );
    $c->forward( ref $comp );
}

=back

=head1 AUTHOR

Marcus Ramberg <marcus@thefeed.no>

=head1 COPYRIGHT

Copyright (c) 2005 - 2009
the Catalyst::Plugin::DefaultEnd L</AUTHOR>
as listed above.

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
