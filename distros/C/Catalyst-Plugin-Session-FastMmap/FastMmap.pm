package Catalyst::Plugin::Session::FastMmap;

use strict;
use base qw/Class::Accessor::Fast Class::Data::Inheritable/;
use MRO::Compat;
use Cache::FastMmap;
use Digest::MD5;
use URI;
use URI::Find;
use File::Temp 'tempdir';

our $VERSION = '0.13';

__PACKAGE__->mk_classdata('_session');
__PACKAGE__->mk_accessors('sessionid');

=head1 NAME

Catalyst::Plugin::Session::FastMmap - [DEPRECATED] FastMmap sessions for Catalyst

=head1 DEPRECATION

Note that this module is deprecated in favor of L<Catalyst::Plugin::Session>.

It works under Catalyst 5.5, but might not work in future versions. Using
L<Catalyst::Plugin::Session> should be a small change, since the API is mostly
backwards compatible.

=head1 SYNOPSIS

    use Catalyst 'Session::FastMmap';
    
    MyApp->config->{session} = {
        expires => 3600,
        rewrite => 1,
        storage => '/tmp/session'
    };

    $c->session->{foo} = 'bar';
    print $c->sessionid;

=head1 DESCRIPTION

C<Catalyst::Plugin::Session::FastMmap> is a fast session plugin for
Catalyst that uses an mmap'ed file to act as a shared memory
interprocess cache.  It is based on C<Cache::FastMMap>.


=head2 EXTENDED METHODS

=over 4

=item finalize

=cut

sub finalize {
    my $c = shift;
    if ( $c->config->{session}->{rewrite} ) {
        my $redirect = $c->response->redirect;
        $c->response->redirect( $c->uri($redirect) ) if $redirect;
    }
    if ( my $sid = $c->sessionid ) {
        $c->_session->set( $sid, $c->session );
        my $set = 1;
        if ( my $cookie = $c->request->cookies->{session} ) {
            $set = 0 if $cookie->value eq $sid;
        }
        if ( $set ) {
            $c->response->cookies->{session} = { 
                value => $sid
            };
        }
        if ( $c->config->{session}->{rewrite} ) {
            my $finder = URI::Find->new(
                sub {
                    my ( $uri, $orig ) = @_;
                    my $base = $c->request->base;
                    return $orig unless $orig =~ /^$base/;
                    return $orig if $uri->path =~ /\/-\//;
                    return $c->uri($orig);
                }
            );
            $finder->find( \$c->res->{body} ) if $c->res->body;
        }
    }
    return $c->NEXT::finalize(@_);
}

=item prepare_action

=cut

sub prepare_action {
    my $c = shift;
    if ( $c->request->path =~ /^(.*)\/\-\/(.+)$/ ) {
        $c->request->path($1);
        $c->sessionid($2);
    }
    if ( my $cookie = $c->request->cookies->{session} ) {
        my $sid = $cookie->value;
        $c->sessionid($sid);
        $c->log->debug(qq/Found sessionid "$sid" in cookie/) if $c->debug;
    }
    $c->NEXT::prepare_action(@_);
}

sub session {
    my $c = shift;
    return $c->{session} if $c->{session};
    my $sid = $c->sessionid;
    if (   $sid
        && $c->_session
        && ( $c->{session} = $c->_session->get($sid) ) )
    {
        $c->log->debug(qq/Found session "$sid"/) if $c->debug;
        return $c->{session};
    }
    else {
        my $sid = Digest::MD5::md5_hex( time, rand, $$, 'catalyst' );
        $c->sessionid($sid);
        $c->log->debug(qq/Created session "$sid"/) if $c->debug;
        return $c->{session} = {};
    }
}

=item setup

Sets up the session cache file.

=cut

sub setup {
    my $self = shift;
    $self->config->{session}->{storage} ||= '/tmp/session';
    $self->config->{session}->{expires} ||= 60 * 60 * 24;
    $self->config->{session}->{rewrite} ||= 0;

    $self->_session(
        Cache::FastMmap->new(
            share_file  => $self->config->{session}->{storage},
            expire_time => $self->config->{session}->{expires}
        )
    );

    return $self->NEXT::setup(@_);
}

=back

=head2 METHODS

=over 4

=item session

=item uri

Extends an uri with session id if needed.

    my $uri = $c->uri('http://localhost/foo');

=cut

sub uri {
    my ( $c, $uri ) = @_;
    if ( my $sid = $c->sessionid ) {
        $uri = URI->new($uri);
        my $path = $uri->path;
        $path .= '/' unless $path =~ /\/$/;
        $uri->path( $path . "-/$sid" );
        return $uri->as_string;
    }
    return $uri;
}

=back

=head2 CONFIG OPTIONS

=over 4

=item rewrite

If set to a true value sessions are automatically stored in the url;
defaults to false.

=item storage

Specifies the file to be used for the sharing of session data;
defaults to C</tmp/session>. 

Note that the file will be created with mode 0640, which means that it
will only be writeable by processes running with the same uid as the
process that creates the file.  If this may be a problem, for example
if you may try to debug the program as one user and run it as another,
specify a filename like C<< /tmp/session-$> >>, which includes the
UID of the process in the filename.


=item expires

Specifies the session expiry time in seconds; defaults to 86,400,
i.e. one day.

=back

=head1 SEE ALSO

L<Catalyst>, L<Cache::FastMmap>, L<Catalyst::Plugin::Session>.

=head1 AUTHOR

Sebastian Riedel E<lt>C<sri@cpan.org>E<gt>,
Marcus Ramberg E<lt>C<mramberg@cpan.org>E<gt>,
Andrew Ford E<lt>C<andrewf@cpan.org>E<gt>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
