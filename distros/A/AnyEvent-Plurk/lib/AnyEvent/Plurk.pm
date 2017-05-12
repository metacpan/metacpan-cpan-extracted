package AnyEvent::Plurk;
our $VERSION = "0.12";

use 5.008;
use common::sense    2.02;
use parent           0.223 "Object::Event";

use AnyEvent         5.202;
use AnyEvent::HTTP   1.44;

use JSON 2.15 qw(to_json from_json);

use URI;
use Carp "croak";
use POSIX qw(strftime);

# Sub
sub current_time_offset() {
    my @t = gmtime;
    return strftime('%Y-%m-%dT%H:%M:%S', @t);
}

sub plurk_api_uri {
    my ($x, %form) = @_;
    $x = "/$x" unless  index($x, "/Users/") == 0;
    my $u = URI->new("http://www.plurk.com");
    $u->scheme("https") if index($x, "/Users/") == 0;
    $u->path("/API$x");
    $u->query_form(%form);
    return $u
}

# Method
sub send_request {
    my ($self, $path, $form, $cb) = @_;
    $form->{api_key} = $self->{api_key};

    my $v = AE::cv;

    my ($data, $header);
    $self->{__current_request} = http_request(
        GET => plurk_api_uri($path, %$form),
        cookie_jar => $self->{__cookie_jar},
        $cb || sub {
            ($data, $header) = @_;
            $data = from_json($data);
            $v->send;
        }
    );

    $v->recv if !$cb;
    return wantarray ? ($data, $header) : $data;
}

sub new {
   my $this  = shift;
   my $class = ref($this) || $this;
   my $self  = $class->SUPER::new(@_);

   unless (defined $self->{api_key}) {
      croak "no 'api_key' given to AnyEvent::Plurk\n";
   }

   unless (defined $self->{username}) {
      croak "no 'username' given to AnyEvent::Plurk\n";
   }

   unless (defined $self->{password}) {
      croak "no 'password' given to AnyEvent::Plurk\n";
   }

   $self->{__cookie_jar} = {};
   return $self
}

sub login {
    my $self = shift;
    my $cb   = shift;

    $self->send_request(
        "Users/login", {
            username => $self->{username},
            password => $self->{password}
        }
    )
}

sub _start_polling {
    my $self = shift;
    $self->{__polling_time_offset} ||= current_time_offset;

    $self->send_request(
        "Polling/getPlurks",
        {
            offset => $self->{__polling_time_offset}
        },
        sub {
            my ($data, $header) = @_;

            if ($header->{Status} == 400) {
                # say $data;
            }
            else {
                $data = from_json($data);
                my $unread_plurks = $data->{plurks};
                if (@$unread_plurks) {
                    my $users = $data->{plurk_users};
                    for my $pu (@$unread_plurks) {
                        $pu->{owner} = $users->{$pu->{owner_id}} if $users->{$pu->{owner_id}};
                    }

                    $self->event("unread_plurks" => $unread_plurks);
                    $self->{__polling_time_offset} = current_time_offset;
                }
            }

            $self->{__polling_timer} = AE::timer 60, 0, sub {
                undef $self->{__polling_timer};
                $self->_start_polling;
            }
        }
    );
}

sub start {
    my $self = shift;

    $self->login;
    $self->_start_polling;
}

sub add_plurk {
    my $self    = shift;
    my $content = shift;

    $self->send_request("Timeline/plurkAdd", {qualifier => ":", content => $content});
}

sub delete_plurk {
    my $self = shift;
    my $id   = shift;

    $self->send_request("Timeline/plurkDelete", {plurk_id => $id});
}


1;

__END__

=head1 NAME

AnyEvent::Plurk - plurk interface for AnyEvent-based programs

=head1 SYNOPSIS

    my $p = AnyEvent::Plurk->new(
        username => $username,
        password => $password
    );
    $p->reg_cb(
        unread_plurks => sub {
            my ($p, $plurks) = @_;
            is(ref($plurks), "ARRAY", "Received latest plurks");
        }
    );

    my $v = AE::cv;
    $p->start;
    $v->recv;

=head1 METHODS

=over 4

=item reg_cb( x => $cb, ...)

Register a callback for event x. See below for the list of events.

=item start

Start polling plurk.com for plurks. In the current implementation, it
only checks new plurks ever 60 seconds.

=item add_plurk( $content )

Add a new plurk with the given text C<$content>.

=item delete_plurk( $id )

Delete the plurk with the given plurk C<$id>.

=back

=head1 EVENTS

=over 4

=item unread_plurks

Arguments to callback: ($self, $plurks)

C<$self> is the C<AnyEvent::Plurk> object which emits this event, and
C<$plurks> is the arrayref to the list of plurks just receieved.

Each elements in C<$plurks> is a hashref. See L<Net::Plurk> for the
explaination of the its keys.

=back

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
