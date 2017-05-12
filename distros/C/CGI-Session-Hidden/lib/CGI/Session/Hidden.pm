package CGI::Session::Hidden;

use strict;
use MIME::Base64 qw();

our $VERSION = '0.03';

sub store {
    my( $self, $sid, $options, $data ) = @_;
    my $storable_data = $self->freeze( $data );

    $self->{_data} = $storable_data;

    return 1;
}

sub retrieve {
    my( $self, $sid, $options ) = @_;

    my $data = $self->thaw( MIME::Base64::decode_base64
                                ( $options->[1]{CGI}->param( $sid ) || '' ) );

    return $data;
}

# these two do not require an implementation
sub remove {
}

sub teardown {
}

sub field {
    my $self = shift;

    $self->flush unless $self->_data;

    my $val = MIME::Base64::encode_base64( $self->_data );
    return ( 'type="hidden" name="' .
             $self->id . '" value="' . $val . '"' );
}

sub _data { $_[0]->{_data} }

1;

__END__

=head1 NAME

CGI::Session::Hidden - persistent session using hidden fields

=head1 SYNOPSIS

In the CGI script:

    use CGI::Session;
    my $session = new CGI::Session("driver:Hidden", undef,
                                   {CGI=>$cgi_obj});

In the HTML (pseudo-code):

    <input type="hidden" name="$CGI::Session::NAME" value="$session->id()" />

or

    <input $session->field() />

=head1 DESCRIPTION

This driver module for CGI::Session 3.x allows storing the session inside
a hidden field in the HTML page.

The semantics are somewhat different
than standard driver modules, but good enough for most uses.

=head1 METHODS

=head2 field

  $attributes = $session->field;

Produces C<type>, C<name> and C<value> attributes to be used
inside and HTML C<< <input> >> tag.

=head1 BUGS

It is not (and can not be) a drop-in replacement for other
drivers.

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SOURCES

The latest sources can be found on GitHub at
L<http://github.com/mbarbon/cgi-session-hidden/tree>

=head1 SEE ALSO

L<CGI::Session|CGI::Session>
