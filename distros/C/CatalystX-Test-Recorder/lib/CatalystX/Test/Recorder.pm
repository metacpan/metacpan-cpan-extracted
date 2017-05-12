#
# This file is part of CatalystX-Test-Recorder
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::Test::Recorder;
BEGIN {
  $CatalystX::Test::Recorder::VERSION = '1.0.0';
}

use strict;
use warnings;
use Moose::Role;
use List::Util qw(first);


around locate_components => sub {
    my $orig = shift;
    my $self = shift;
    my @components = $self->$orig(@_);
    push(@components, 'CatalystX::Test::Recorder::Controller');
    return @components;
};

after finalize => sub {
    my $c = shift;
    return unless $CatalystX::Test::Recorder::Controller::record;
    my $config = CatalystX::Test::Recorder::Controller->config;
    return if(first { $c->req->path =~ $_ } @{$config->{skip}});
    push(@{$CatalystX::Test::Recorder::Controller::requests}, $c->req);
    push(@{$CatalystX::Test::Recorder::Controller::responses}, $c->res);
    
};

1;



=pod

=head1 NAME

CatalystX::Test::Recorder

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

  package MyApp;
  use Moose;
  extends 'Catalyst';
  __PACKAGE__->setup(qw(+CatalystX::Test::Recorder));
  1;
  
  # hit /recorder/start to start recording
  # make requests to your application
  # hit /recorder/stop to get the test

Example output: 

  use Test::More;
  use strict;
  use warnings;

  use URI;
  use HTTP::Request::Common qw(GET HEAD PUT DELETE POST);

  use Test::WWW::Mechanize::Catalyst 'MyApp';

  my $mech = Test::WWW::Mechanize::Catalyst->new();
  $mech->requests_redirectable([]); # disallow redirects

  my ( $response, $request, $url );

  $request = POST '/foo', [ 'foo' => 'bar' ];
  $response = $mech->request($request);
  is( $response->code, 200 );

  $url = URI->new('/foo');
  $url->query_form( { 'foo' => 'bar' } );
  $request = GET $url;
  $response = $mech->request($request);

  done_testing;

=head1 DESCRIPTION

In order to test your application thoroughly you have to write a lot of tests, to ensure all controllers
and actions are set up properly. This can be quite a pain, especially for large forms and complex business logic.

This module provides a test skeleton from HTTP requests to your application. It captures body parameters as well
as query parameters and handles all HTTP request methods. The generated test checks the response code only. This is
where the real work begins. See L<Test::WWW::Mechanize::Catalyst> for more testing goodness.

This plugin should only be used in a development environment.

=head1 NAME

CatalystX::Test::Recorder - Generate tests from HTTP requests

=head1 CONFIGURATION

  package MyApp;
  ...
  __PACKAGE__->config( 'CatalystX::Test::Recorder' => {
    namespace => '...',
    ...
  } );

=head2 namespace

Sets the namespace under which the start and stop actions are located. Defaults to C<recorder>.

=head2 skip

This is an arrayref of regexprefs. Requests, whose path matches on of these regexes, will not be recorded.
Defaults to C<qr/^static\//, qr/^favicon.ico/>.

=head2 template

Specify the path to a L<Template::Alloy> (TT dialect) file which is used to render the test. 
For reference, the default template is available in the C<__DATA__> section of C<CatalystX::Test::Recorder::Controller>.

The following variables are avaiable from the template:

=over

=item * requests

An arrayref of L<Catalyst::Request> objects.

=item * responses

An arrayref of L<Catalyst::Response> objects.

=item * app

The name of the current application.

=back

=head1 AUTHOR

Moritz Onken, C<onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

