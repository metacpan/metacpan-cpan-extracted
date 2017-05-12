package Apache2::Controller::Session::Cookie;

=head1 NAME

Apache2::Controller::Session::Cookie - track a sessionid with a cookie in A2C

=head1 VERSION

Version 1.001.001

=cut

use version;
our $VERSION = version->new('1.001.001');

=head1 SYNOPSIS

See L<Apache2::Controller::Session> for detailed setup example.

 package MyApp::Session;
 use base qw( Apache2::Controller::Session::Cookie );
 sub get_options {
     # ...
 }
 1;

=head1 DESCRIPTION

This module implements C<get_session_id> and C<set_session_id>
to get and set the session id from
a cookie.  

=head1 DIRECTIVES

=over 4 

=item A2C_Session_Cookie_Opts

=back

L<Apache2::Controller::Directives>

L<Apache2::Cookie>

=head1 METHODS

These methods must by implemented by any 
L<Apache2::Controller::Session> subclass.

=cut

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( Apache2::Controller::Session );

use Log::Log4perl qw(:easy);
use Readonly;
use YAML::Syck;

use Apache2::Controller::X;

Readonly my $DEFAULT_COOKIE_NAME => 'A2CSession';

=head2 get_session_id

 my $sid = $self->get_session_id();

Get the session id from the cookie and verifies it.

Sets C<< $r->pnotes->{a2c}{session_id} >> to be the session id string.

See L<Apache2::Controller::Methods/get_cookie_jar>
and L<Apache2::Controller::Directives/A2C_Skip_Bogus_Cookies>.

If the cookie is not present or invalid, returns undef.

Warns the debug log if sig validation fails and returns undef.

=cut

sub get_session_id {
    my ($self) = @_;

    my %copts = %{ $self->get_directive('A2C_Session_Cookie_Opts') || { } }; 
    $copts{name} ||= $DEFAULT_COOKIE_NAME;
    my $cookie_name = $copts{name};
    
    my $jar = $self->get_cookie_jar();  # result might be undef
    my ($sid, $valid_sig, $cookie) = ();
    my $sig = qq{};

    if (defined $jar) {
        DEBUG "looking for cookie name '$cookie_name'";
        $cookie = $jar->cookies($cookie_name);

        if ($cookie) {
            DEBUG "found cookie named '$cookie_name'";
            my ($read_sid, $read_sig) = $cookie->value();
            $sid = $read_sid;
            $sig = $read_sig if defined $read_sig;
        }
        else {
            DEBUG "found no valid cookie named '$cookie_name'";
        }
        DEBUG sub { Dump({
            sid_from_cookie => $sid,
            sig_from_cookie => $sig,
        }) };
    }

    if (defined $sid) {
        # if the session_id does not pass signature, return nothing
        $valid_sig = $self->signature($sid);

        if ($valid_sig ne $sig) {
            WARN "signature validation failed";
            return;
        }
    }

    # save sig and Apache2::Cookie object for this handler stage
    # (do not need to recompute the signature since we will use this one)
    $self->{session_valid_sig} = $valid_sig;
    
    return $sid;
}

=head2 set_session_id

 $self->set_session_id($sid);

Set the session id in the cookie.

=cut

sub set_session_id {
    my ($self, $session_id) = @_;
    DEBUG("Setting session_id '$session_id'");
    my $r = $self->{r};

    my $directives = $self->get_directives();

    my %opts = %{ $self->get_directive('A2C_Session_Cookie_Opts') || { } }; 
    $opts{name} ||= $DEFAULT_COOKIE_NAME;

    DEBUG(sub {"Creating session cookie with opts:\n".Dump(\%opts)});
    my $name = delete $opts{name};

    my $cookie = Apache2::Cookie->new( $r,
        -name           => $name,
        -value          => [ 
            $session_id, 
            ( $self->{session_valid_sig} || $self->signature($session_id) )
        ],
    );

    $cookie->$_($opts{$_}) for keys %opts;

    DEBUG("baking cookie '$cookie'");
    $cookie->bake($r);

    DEBUG('setting in pnotes');
    $r->pnotes->{a2c}{session_id} = $session_id;

    DEBUG("done setting session_id");
    return;
}

=head1 SEE ALSO

L<Apache2::Controller::Session>

L<Apache2::Controller::Directives/Apache2::Controller::Session>

L<Apache2::Controller>

L<Apache2::Cookie>

=head1 AUTHOR

Mark Hedges, C<< <hedges at formdata.biz> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Mark Hedges, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This software is provided as-is, with no warranty 
and no guarantee of fitness
for any particular purpose.

=cut


1; # End of Apache2::Controller::Session::Cookie
