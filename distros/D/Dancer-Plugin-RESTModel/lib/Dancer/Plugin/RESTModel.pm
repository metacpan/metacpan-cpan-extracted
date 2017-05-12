package Dancer::Plugin::RESTModel;
use strict;
use warnings;

use Moose;
with 'Role::REST::Client';

use Dancer qw( :syntax :moose );
use Dancer::Plugin;
use Carp 'croak';

our $VERSION = 0.02;

my $schemas = {};

register model => sub {
  my (undef, $name) = plugin_args(@_);
  return $schemas->{$name} if exists $schemas->{$name};

  my $conf = plugin_setting;
  my $options = $conf->{$name}
    or croak "The schema '$name' is not configured";

  my $model = __PACKAGE__->new( %{$conf->{$name}} );
  $schemas->{$name} = $model;

  return $model;
};

__PACKAGE__->meta->make_immutable;

register_plugin;
42;
__END__

=head1 NAME

Dancer::Plugin::RESTModel - REST model class for Dancer apps


=head1 SYNOPSIS

set the REST endpoint in your Dancer configuration file:

    plugins:
      RESTModel:
        MyData:
          server: http://localhost:5000
          type: application/json
          clientattrs:
            timeout: 5

then use it from any of your routes/controllers:

    use Dancer ':syntax';
    use Dancer::Plugin::RESTModel;

    get '/' => sub {
        my $res = model('MyData')->post( 'foo/bar/baz', { meep => 'moop' } );

        my $code = $res->code; # e.g. 200 
        my $data = $res->data;

        ...
    };


=head1 DESCRIPTION

This plugin lets you talk to a REST server as a separate model from within
your Dancer app. It is useful for keeping your API decoupled from your app
while still being able to manage it through the configuration file.

It is a thin wrapper over L<Role::REST::Client>.

=head1 INTERFACE 

=head2 model()

The exported C<model()> function returns a REST Model object which provides
the standard HTTP 1.1 verbs as methods:

    post
    get
    put
    delete
    options
    head

All methods take these parameters:

=over 4

=item * url - the REST service being accessed

=item * data - The data structure to send (hashref, arrayref). The data will
be encoded according to the value of the I<type> attribute

=item * args - B<optional> hashref with arguments to augment the way the call
is handled. It currently provides the 'deserializer' key to change the
deserializer if you I<know> that the response's content-type is incorrect,
and also the 'preserve_headers' which, if set to true, will keep the headers
between calls:

    my $res = model('MyData')->post(
        'users/123',
        { foo => 'bar' },
        { deserializer => 'application/yaml', preserve_headers => 1 },
    );

=back

The third parameter, I<args>, is an optional hashref which lets you give
extra information to the object. It currently provides 

=head1 CONFIGURATION AND ENVIRONMENT

=head2 server

=head2 type

=head2 user_agent

=head2 httpheaders

=head2 persistent_headers

=head2 clientattrs


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-dancer-plugin-restmodel@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

=over 4

=item L<Dancer::Plugin::REST>

=item L<Role::REST::Client>

=item L<Dancer>

=back

=head1 AUTHOR

Breno G. de Oliveira  C<< <garu@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, Breno G. de Oliveira C<< <garu@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


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
