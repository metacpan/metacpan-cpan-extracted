package CGI::Session::Driver::hidden;

use strict;
use base qw(CGI::Session::Driver CGI::Session::ErrorHandler);

use MIME::Base64 qw();

our $VERSION = '0.03';

sub store {
    my( $self, $sid, $datastr ) = @_;

    $self->{_data} = $datastr;
}

sub retrieve {
    my( $self, $sid ) = @_;

    return MIME::Base64::decode_base64( $self->_cgi->param( $sid ) || '' );
}

sub remove {
    my( $self, $sid ) = @_;

    return 1;
}

sub traverse {
    my( $self, $coderef ) = @_;

    # not meaningful...
}

sub field {
    my( $self, $session ) = @_;

    $session->flush;
#    die 'Call $session->flush() first' unless $self->_data;

    my $val = MIME::Base64::encode_base64( $self->_data );
    return ( 'type="hidden" name="' .
             $session->id . '" value="' . $val . '"' );
}

sub _data { $_[0]->{_data} }
sub _cgi { $_[0]->{CGI} }

# EVIL
sub CGI::Session::field {
    my( $self ) = @_;

    return $self->_driver->field( $self );
}

1;

__END__

=head1 NAME

CGI::Session::Driver::hidden - persistent session using hidden fields

=head1 SYNOPSIS

In the CGI script:

    use CGI::Session;
    my $session = new CGI::Session("driver:hidden", undef,
                                   {CGI=>$cgi_obj});

In the HTML (pseudo-code):

    <input type="hidden" name="$CGI::Session::NAME" value="$session->id()" />

or

    <input $session->field() />

=head1 DESCRIPTION

This driver module for CGI::Session 4.x allows storing the session inside
a hidden field in the HTML page.

The semantics are somewhat different
than standard driver modules, but good enough for most uses.

=head1 METHODS

=head2 field

  $attributes = $session->field;

Produces C<type>, C<name> and C<value> attributes to be used
inside and HTML C<< <input> >> tag.

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
