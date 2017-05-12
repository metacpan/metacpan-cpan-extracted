package CGI::Test::Input::Custom;

our $VERSION = '0.03';

use strict;
use warnings;
use Carp;
use Encode qw(encode);

use base 'CGI::Test::Input';

sub _firstdef {
    defined && return $_ for @_;
    undef;
}

sub new {
    my ($class, %args) = @_;
    my $this = bless {}, $class;
    $this->_init;
    $this->{_ctic_mime_type} = _firstdef(delete $args{-mime_type}, 'application/octet-stream');
    $this->{_data_decoded} = _firstdef(delete $args{-content}, '');
    $this->{_encoding} = _firstdef(delete $args{-encoding}, 'utf8');
    %args and croak "unsupported constructor argument(s) ".join(', ', keys %args);
    $this->{stale} = 1;
    $this;
}

*make = \&new;

for (qw(widget field file file_now)) {
    my $m = "add_$_";
    no strict 'refs';
    *$m = sub { croak "method '$m' is not supported by ".__PACKAGE__." objects" };
}

sub set_mime_type {
    my ($this, $type) = @_;
    $this->{_ctic_mime_type} = $type;
}

sub mime_type { shift->{_ctic_mime_type} }

sub _build_data {
    my $this = shift;
    encode($this->{_encoding}, $this->{_data_decoded})
}

sub add_content {
    my $this = shift;
    $this->{_data_decoded} .= join('', @_);
    $this->{stale} = 1;
}



1;
__END__


=head1 NAME

CGI::Test::Input::Custom - send custom data to CGIs for testing

=head1 SYNOPSIS

  use CGI::Test;
  use CGI::Test::Input::Custom;

  my $ct = CGI::Test->new(...);

  my $input = CGI::Test::Input::Custom->new();

  $input->set_mime_type('text/xml', -encoding => 'utf8');

  $input->add_content(<<EOX);
  <?xml version="1.0" encoding="UTF-8"?>
  <FooBar>
    <Chanel>Whatever</Chanel>
    <Date>20080304231200</Date>
  </FooBar>
  EOX

  my $page = $ct->POST('http://www.foo.org/cgi/sendMeXML', $input);

=head1 DESCRIPTION

This module allows to send custom data to CGIs on POST requests when
using the L<CGI::Test> framework.

=head2 API

These are the methods available:

=over 4

=item CGI::Test::Input::Custom->new(%args)

creates a new input object.

The accepted arguments are as follows:

=over 4

=item -mime_type => $mime_type

mime type of the content. Default is C<application/octect-stream>.

=item -content => $data

data to send in the request

=item -content => $encoding

encoding to use when converting data from internal perl representation
to on-the-wire format. Default is utf8.

See L<Encode>.

=back

=item $input->set_mime_type($mime_type);

sets the mime type

=item $input->add_content($data);

appends data to be sent to the CGI

=back

=head1 SEE ALSO

L<Test::CGI>, L<Test::CGI::Input>, Internet media types (aka MIME
types) entry on the
L<Wikipedia|http://en.wikipedia.org/wiki/Internet_media_type>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Qindel Formacion y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
