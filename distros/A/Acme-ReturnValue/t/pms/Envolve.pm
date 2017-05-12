use strict;
use warnings;
package Chat::Envolve;
BEGIN {
  $Chat::Envolve::VERSION = '1.0007';
}

use Any::Moose;
use MIME::Base64 qw(encode_base64url);
use Digest::HMAC_SHA1 qw(hmac_sha1_hex);
use Encode qw(encode);

has api_key => (
    is          => 'ro',
    required    => 1,
    trigger     => sub {
        my ($self, $value) = @_;
        confess 'EnvolveAPI: Invalid API Key' unless $value =~ m/\d+-\w+/;
        my @key_parts = split /-/, $self->api_key;
        $self->secret($key_parts[1]);
        $self->site_id($key_parts[0]);
    }
);

has secret  => (
    is          => 'rw',
);

has site_id => (
    is          => 'rw',
);

sub get_tags {
    my ($self, $first_name, %options) = @_;
    my $command = ($first_name) ? $self->get_login_command($first_name, %options) : $self->get_logout_command;
    my $html = q{
<script type="text/javascript">
    envoSn=%s;
    env_commandString="%s";
</script>
<script type="text/javascript" src="//d.envolve.com/env.nocache.js"></script>
    };
    return sprintf $html, $self->site_id, $command;
}

sub get_login_command {
    my ($self, $first_name, %options) = @_;
    my %params = ( fn => $first_name );
    $params{ln} = $options{last_name} if exists $options{last_name};
    $params{pic} = $options{picture_url} if exists $options{picture_url};
    $params{admin} = 't' if exists $options{is_admin} && $options{is_admin};
    return $self->sign_command_string(
        $self->generate_command_string('login', %params)
        );
}

sub get_logout_command {
    my ($self) = @_;
    return $self->sign_command_string(
        $self->generate_command_string('logout')
        );
}

sub generate_command_string {
    my ($self, $command, %params) = @_;
    my $command_string = (time() * 1000)
        .';v=0.2'
        .',c='.$command;
    foreach my $key (keys %params) {
        my $value = ($key eq 'admin') ? $params{$key} : encode_base64url(encode("UTF-8",$params{$key}));
        $command_string .= ',' . $key . '=' . $value; 
        chomp $command_string;
    }
    return $command_string;
}

sub sign_command_string {
    my ($self, $command_string) = @_;
    my $hash = hmac_sha1_hex( $command_string, $self->secret);
    return $hash . ';' . $command_string;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;


=head1 NAME

Chat::Envolve - A Perl API for the Envolve web chat system.

=head1 VERSION

version 1.0007

=head1 SYNOPSIS

 my $chat = Chat::Envolve->new(
    api_key     => $key,
 );
 
 my $html = $chat->get_tags('Joe');
 
 my $command = $chat->get_login_command('Joe');

=head1 DESCRIPTION

This is a Perl API for the Envolve L<http://www.envolve.com> chat system. If you'd like to see it in use, check out The Lacuna Expanse L<http://www.lacunaexpanse.com>. Currently Envolve has not exposed much functionality, but using this API will allow you to have your users automatically logged in/out of the chat based upon their web site logins.

=head1 METHODS

=head2 new ( api_key => '111-xxx' )

Constructor. Requires both params.

=over

=item api_key

The API key provided by Envolve.

=back

=head2 get_login_command ( first_name , [ options ] )

Returns a signed login command string that can be used to log a user into a chat by calling some javascript.

 <script type="text/javascript">
    env_executeCommand(command_string_goes_here);
 </script>

If you prefer you can just inline it into the web page using the C<get_tags> method.

=over

=item first_name

A string, either the first name of the user, or their alias.

=item options

A hash of optional parameters.

=over

=item last_name

A string, the last name of the user.

=item picture_url

A url of a picture or avatar for the user.

=item is_admin

If set to 1, the user will gain admin privileges, which currently means that if enabled in the Envolve settings they'll be able to create and close chats administratively.

=back

=back


=head2 get_logout_command ( )

Returns a signed logout command string that can be used to log a user out of a chat by calling some javascript.

 <script type="text/javascript">
    env_executeCommand(command_string_goes_here);
 </script>

If you prefer you can just inline it into the web page using the C<get_tags> method and pass no params to it.


=head2 get_tags ( [ first_name, login_options,  ] )

Returns some HTML tags that can be inlined into your web page to start the chat. If no parameters are passed in, then the user will be anonymous. If C<first_name> is passed in then the user will be authenticated.

=over

=item first_name

See C<get_login_command>

=item login_options

See C<get_login_command>

=back




=head1 EXCEPTIONS

Currently this module doesn't throw any exceptions.


=head1 TODO

Nothing is planned until Envolve releases more functionality.


=head1 PREREQS

L<Moose>
L<MIME::Base64>
L<Digest::HMAC_SHA1>
L<Encode>



=head1 SUPPORT

=over

=item Repository

L<http://github.com/rizen/Chat-Envolve>

=item Bug Reports

L<http://github.com/rizen/Chat-Envolve/issues>

=back


=head1 SEE ALSO

If you want to see this module in use, check out The Lacuna Expanse L<http://www.lacunaexpanse.com>. If you want to learn more about Envolve visit their web site L<http://www.envolve.com>.

=head1 AUTHOR

JT Smith <jt_at_plainblack_dot_com>

=head1 LEGAL

Chat::Envolve is Copyright 2010 Plain Black Corporation (L<http://www.plainblack.com>) and is licensed under the same terms as Perl itself. Envolve and its copyrights and trademarks are the property of Envolve, Inc.



=cut