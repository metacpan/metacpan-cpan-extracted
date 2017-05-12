package TestUtils;

use strict;
use warnings;

use base qw/ Exporter /;

use HTTP::Request::Common;
use Catalyst::Test 'TestApp';
use Data::Dumper;

use Test::Most;
use Test::Deep;

=head1 NAME

TestUtils - Utilities for testing Catalyst::Plugin::I18N::PathPrefixGeoIP

=head1 SYNOPSIS

  run_prepare_path_prefix_tests(@tests);

=head1 DESCRIPTION

=head1 EXPORTS

Optional exports: L</run_prepare_path_prefix_tests>

=cut

our @EXPORT_OK = qw/
  &run_prepare_path_prefix_tests
/;

=head1 METHODS

=cut

=head2 run_prepare_path_prefix_tests

  run_prepare_path_prefix_tests(@tests);

Runs all the tests in C<@tests>.

Each element of C<@tests> is a hashref, with the following key-value pairs:

=over

=item config

An arrayref that describes the configuration of the module. The corresponding
key-value pairs of C<< $c->config->{'Plugin::I18N::PathPrefixGeoIP'} >> are set to
these values before the request.

=item request

An arrayref that describes the request.

It can contain the following key-value pairs:

=over

=item path

The path part of the URI to request.

=item accept_language

An arrayref, contains language codes to set the C<Accept-Language> request
header to before the request.

=back

=item expected

A hashref that contains the expected values after the request.

It contains following key-value pairs:

=over

=item language

The expected single value of $c->languages.

=item req

The expected value of some C<< $c->req >> methods. A hashref with the following
key-value pairs:

=over

=item uri

The expected value of C<< $c->req->uri >>.

=item base

The expected value of C<< $c->req->base >>.

=item path

The expected value of C<< $c->req->path >>.

=back

=item action

The fully qualified name of the action the dispatcher is expected to dispatch
the request.

=item log

The expected messages logged by the plugin. If defined, arrayref that contains
pairs of values, where the first value is the log level string (see
L<Catalyst::Log> for the valid log levels) and the second value is the message.
If not defined then the messages are not checked.

=back

=cut

sub run_prepare_path_prefix_tests {
  my (@tests) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my %original_config = %{ TestApp->config->{'Plugin::I18N::PathPrefixGeoIP'} };

  foreach my $test (@tests) {
    my $test_description =
      Data::Dumper->new([
        +{
          map {
            ( $_ => $test->{$_} )
          } qw(config request)
        }
      ])->Terse(1)->Indent(0)->Quotekeys(0)->Dump;

    TestApp->config->{'Plugin::I18N::PathPrefixGeoIP'} = { %original_config };
    while (my ($config_key, $config_value) = each %{ $test->{config} }) {
      TestApp->config->{'Plugin::I18N::PathPrefixGeoIP'}->{$config_key}
        = $config_value;
    }
    TestApp->setup_finalize;  # force C:P:I18N::PathPrefixGeoIP re-parse its config

    my ($response, $c) = ctx_request(
      GET $test->{request}->{path},
        'Accept-Language' => $test->{request}->{accept_language},
    );

    ok(
      $response->is_success,
      "The request was successful ($test_description)"
    );

    is(
      $c->action->class . '::' . $c->action->name,
      $test->{expected}->{action},
      "Dispatched to the right action ($test_description)"
    );

    cmp_deeply(
      $c->languages,
      [ $test->{expected}->{language} ],
      "\$c->languages is set to the expected value ($test_description)"
    );

    is(
      $c->req->uri,
      $test->{expected}->{req}->{uri},
      "\$c->req->uri is set to the expected value ($test_description)"
    );

    isa_ok($c->req->uri, 'URI', "\$c->req->uri ($test_description)");

    is(
      $c->req->base,
      $test->{expected}->{req}->{base},
      "\$c->req->base is set to the expected value ($test_description)"
    );

    isa_ok($c->req->base, 'URI', "\$c->req->base ($test_description)");

    is(
      $c->req->path,
      $test->{expected}->{req}->{path},
      "\$c->req->path is set to the expected value ($test_description)"
    );

    eq_or_diff(
      $c->language_prefix_debug_messages,
      $test->{expected}->{log},
      "The plugin logged only the expected messages during the request "
        . "($test_description)"
    ) if defined $test->{expected}->{log};
  }
}
