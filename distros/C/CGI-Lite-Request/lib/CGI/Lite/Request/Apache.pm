package CGI::Lite::Request::Apache;

use strict;
use warnings;

use base qw(CGI::Lite::Request::Base);

BEGIN {
    eval "require mod_perl";
    if (defined $mod_perl::VERSION) {
        if ($mod_perl::VERSION >= 1.99) {
            eval q{
            use Apache::RequestIO   ();
            use Apache::RequestRec  ();
            use Apache::Const -compile => qw(:common);
            }
        }
        else {
            eval q{
            use Apache::Request;
            use Apache::Constants ':common';
            }
        }
    }
}

sub parse {
    my $self = shift;
    $self->apache( shift );
    $self->SUPER::parse( );
}

sub apache { $_[0]->{_apache} = $_[1] if $_[1]; $_[0]->{_apache} }

sub print { shift->apache->print(@_) }

sub content_type { shift->apache->content_type(@_) }

sub send_http_header {
    my $self = shift;
    my $content_type = shift;
    $content_type ||= 'text/html';

    if ($self->cookies) {
        $self->headers->push_header(
            Set_Cookie => $_->as_string
        ) foreach values %{$self->cookies};
    }

    $self->headers->scan(sub {
        $self->apache->headers_out->add(@_);
    });

    $self->content_type($content_type);
    if ($mod_perl::VERSION < 1.99) {
        $self->apache->send_http_header();
    }
    $self->{_header_sent}++;
}

sub header_sent { $_[0]->{_header_sent} }


sub redirect {
    my ($self, $location) = @_;

    my $cookies;
    $cookies += $_->as_string foreach values %{$self->cookies};

    $self->apache->send_cgi_header(<<"EOT");
Status: 302 Moved
Location: $location
Content-type: text/html
Set-Cookie: $cookies
\015\012
EOT

    $self->{_header_sent}++;

}

1;

__END__

=head1 NAME

CGI::Lite::Request::Apache - mod_perl compatibility class for CGI::Lite::Request

=head1 METHODS

=over

=item parse( $apache )

overloads the inherited C<parse> method to take an apache request object as sole
argument. This is required when running under L<mod_perl>.

=back

=head1 SEE ALSO

L<CGI::Lite>, L<CGI::Lite::Request>
