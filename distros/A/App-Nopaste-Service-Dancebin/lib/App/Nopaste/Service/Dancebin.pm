use strict;
use warnings;
package App::Nopaste::Service::Dancebin;
{
  $App::Nopaste::Service::Dancebin::VERSION = '0.004';
}
use Encode qw( decode_utf8 );

use base q[App::Nopaste::Service];

# ABSTRACT: nopaste service for L<Dancebin>

sub uri { $ENV{DANCEBIN_URL} || 'http://danceb.in/' }

sub get {
    my ($self, $mech) = @_;

    # Set BasicAuth credentials if needed
    $mech->credentials( $self->_credentials ) if $self->_credentials;

    return $mech->get($self->uri);
}

sub fill_form {
    my ($self, $mech) = (shift, shift);
    my %args = @_;

    my $content = {
        code    => decode_utf8($args{text}),
        title   => decode_utf8($args{desc}),
        lang    => decode_utf8($args{lang}),
    };
    my $exp = $ENV{DANCEBIN_EXP};
    $content->{expiration} = $exp if $exp;

    # Set BasicAuth credentials if needed
    $mech->credentials( $self->_credentials ) if $self->_credentials;

    my $form = $mech->form_number(1) || return;

    # do not follow redirect please
    @{$mech->requests_redirectable} = ();

    my $paste = HTML::Form::Input->new(
        type  => 'text',
        value => 'Send',
        name  => 'paste'
    )->add_to_form($form);

    return $mech->submit_form( form_number => 1, fields => $content );
}

sub return {
    my ( $self, $mech ) = @_;

    if($mech->response->is_redirect) {
      return ( 1, $mech->response->header("Location") );
    } else {
      return ( 0, "Cannot find URL" );
    }
}

sub _credentials { ($ENV{DANCEBIN_USER}, $ENV{DANCEBIN_PASS}) }

1;


__END__
=pod

=head1 NAME

App::Nopaste::Service::Dancebin - nopaste service for L<Dancebin>

=head1 VERSION

version 0.004

=head1 SYNOPSIS

L<Dancebin|https://github.com/throughnothing/Dancebin> Service for L<nopaste>.

To use, simple use:

    $ echo "text" | nopaste -s Dancebin

By default it pastes to L<http://danceb.in/|http://danceb.in/>, but you can
override this be setting the C<DANCEBIN_URL> environment variable.

You can set HTTP Basic Auth credentials to use for the nopaste service
if necessary by using:

    DANCEBIN_USER=username
    DANCEBIN_PASS=password

The expiration of the post can be modified by setting the C<DANCEBIN_EXP>
environment variable.  Acceptable values are things like:

    DANCEBIN_EXP=weeks:1
    DANCEBIN_EXP=years:1:months:2
    DANCEBIN_EXP=weeks:1:days:2:hours:12:minutes:10:seconds:5
    DANCEBIN_EXP=never:1  # Never Expire

=head1 AUTHOR

William Wolf <throughnothing@gmail.com>

=head1 COPYRIGHT AND LICENSE


William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut

