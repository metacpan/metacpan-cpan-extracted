package Catalyst::Plugin::Session::Manager::Client::StickyQuery;
use strict;
use warnings;
use base qw/Catalyst::Plugin::Session::Manager::Client/;

use HTML::StickyQuery;

our $SESSIONID = "SESSIONID";

sub set {
    my ( $self, $c ) = @_;
    my $sid = $c->sessionid or return;
    my $sessionid_name = $self->sessionid_name;
    my $content = $c->response->{body};
    $content =~ s/(<form\s*.*?>)/$1\n<input type="hidden" name="$sessionid_name" value="$sid">/isg;
    $c->response->output(
        HTML::StickyQuery->new->sticky(
            scalarref => \$content,
            param     => { $sessionid_name => $sid },
        )
    );
}

sub get {
    my ( $self, $c ) = @_;
    $c->request->param( $self->sessionid_name ) || undef;
}

sub sessionid_name {
    my $self = shift;
    return $self->{config}{name} || $SESSIONID;
}

1;
__END__

=head1 NAME

Catalyst::Plugin::Session::Manager::Client::StickyQuery - handles sessionid with sticky query.

=head1 SYNOPSIS

    use Catalyst qw/Session::Manager/;

    MyApp->config->{session} = {
        client => 'StickyQuery',
        name   => 'SESSIONID',
    };

=head1 DESCRIPTION

This module allows you to handle sessionid with sticky query.
This is useful in case you can't use cookie, for example, your project is for mobile-phone or like that,
which has browser doesn't apply cookie.

=head1 CONFIGURATION

=over 4

=item name

'SESSIONID' is set by default.

=back

=head1 SEE ALSO

L<Catalyst>

L<Catalyst::Plugin::Session::Manager>

L<HTML::StickyQuery>

=head1 AUTHOR

Lyo Kato E<lt>lyo.katp@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

