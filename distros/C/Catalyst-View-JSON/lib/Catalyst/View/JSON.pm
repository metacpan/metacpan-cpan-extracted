package Catalyst::View::JSON;

use strict;
use warnings;
our $VERSION = '0.37';
use 5.008_001;

use base qw( Catalyst::View );
use Encode ();
use MRO::Compat;
use Catalyst::Exception;

__PACKAGE__->mk_accessors(qw(
  allow_callback callback_param expose_stash
  encoding json_dumper no_x_json_header json_encoder_args
  use_force_bom));

sub new {
    my($class, $c, $arguments) = @_;
    my $self = $class->next::method($c);

    for my $field (keys %$arguments) {
        
        # Remove catalyst_component_name (and future Cat specific params)
        next if $field =~ /^catalyst/;
        
        # no longer supported
        warn('json_driver is no longer supported'), next if $field eq 'json_driver';

        if ($self->can($field)) {
            $self->$field($arguments->{$field});
        } else {
            $c->log->debug("Unknown config parameter '$field'");
        }
    }

    if (my $method = $self->can('encode_json')) {
        $self->json_dumper( sub {
                                my($data, $self, $c) = @_;
                                $method->($self, $c, $data);
                            } );
    } else {
        require JSON::MaybeXS;
        my %args = (utf8=>1, %{$self->json_encoder_args ||+{}});
        my $json = JSON::MaybeXS->new(%args);
        $self->json_dumper(sub { $json->encode($_[0]) });
    }

    return $self;
}

sub process {
    my($self, $c) = @_;

    # get the response data from stash
    my $cond = sub { 1 };

    my $single_key;
    if (my $expose = $self->expose_stash) {
        if (ref($expose) eq 'Regexp') {
            $cond = sub { $_[0] =~ $expose };
        } elsif (ref($expose) eq 'ARRAY') {
            my %match = map { $_ => 1 } @$expose;
            $cond = sub { $match{$_[0]} };
        } elsif (!ref($expose)) {
            $single_key = $expose;
        } else {
            $c->log->warn("expose_stash should be an array reference, Regexp object, or key for a single stash entry.");
            $c->log->warn("Returning all stash entries");
        }
    }

    my $data;
    if ($single_key) {
        $data = $c->stash->{$single_key};
    } else {
        $data = { map { $cond->($_) ? ($_ => $c->stash->{$_}) : () }
                  keys %{$c->stash} };
    }

    my $cb_param = $self->allow_callback
        ? ($self->callback_param || 'callback') : undef;
    my $cb = $cb_param ? $c->req->param($cb_param) : undef;
    $self->validate_callback_param($cb) if $cb;

    # When you set encoding option in View::JSON, this plugin DWIMs
    my $encoding = $self->encoding || 'utf-8';

    $c->res->content_type("application/json; charset=$encoding");

    if ($c->req->header('X-Prototype-Version') && !$self->no_x_json_header) {
        $c->res->header('X-JSON' => 'eval("("+this.transport.responseText+")")');
    }

    my $json = $self->render($c, $data);
    my $output;

    ## add UTF-8 BOM if the client meets a test and the application wants it.
    if ($self->use_force_bom && $encoding eq 'utf-8') {
        my $user_agent = $c->req->user_agent || '';
        if ($self->user_agent_bom_test($user_agent)) {
            $output = "\xEF\xBB\xBF";
        }
    }

    $output .= "$cb(" if $cb;
    $output .= $json;
    $output .= ");"   if $cb;

    $c->res->output($output);
}

# allow for called as $c, $template, $data || $c, $data so that we are compatible
# with the semi standard render method that a lot of views use.

sub render {
    my $self = shift;
    my $c = shift;
    my $data = pop;

    return $self->json_dumper->($data, $self, $c); # weird order to be backward compat
}

sub user_agent_bom_test {
    my ($self, $user_agent) = @_;
    return(($user_agent =~ m/\bSafari\b/) and ($user_agent !~ m/\bChrome\b/));
}


sub validate_callback_param {
    my($self, $param) = @_;
    $param =~ /^[a-zA-Z0-9\.\_\[\]]+$/
        or Catalyst::Exception->throw("Invalid callback parameter $param");
}

1;
__END__

=head1 NAME

Catalyst::View::JSON - JSON view for your data

=head1 SYNOPSIS

  # lib/MyApp/View/JSON.pm
  package MyApp::View::JSON;
  use base qw( Catalyst::View::JSON );
  1;

  # configure in lib/MyApp.pm
  MyApp->config({
      ...
      'View::JSON' => {
          allow_callback  => 1,    # defaults to 0
          callback_param  => 'cb', # defaults to 'callback'
          expose_stash    => [ qw(foo bar) ], # defaults to everything
      },
  });

  sub hello : Local {
      my($self, $c) = @_;
      $c->stash->{message} = 'Hello World!';
      $c->forward('View::JSON');
  }

=head1 DESCRIPTION

Catalyst::View::JSON is a Catalyst View handler that returns stash
data in JSON format.

=head1 CONFIG VARIABLES

=over 4

=item allow_callback

Flag to allow callbacks by adding C<callback=function>. Defaults to 0
(doesn't allow callbacks). See L</CALLBACKS> for details.

=item callback_param

Name of URI parameter to specify JSON callback function name. Defaults
to C<callback>. Only effective when C<allow_callback> is turned on.

=item expose_stash

Scalar, List or regular expression object, to specify which stash keys are
exposed as a JSON response. Defaults to everything. Examples configuration:

  # use 'json_data' value as a data to return
  expose_stash => 'json_data',

  # only exposes keys 'foo' and 'bar'
  expose_stash => [ qw( foo bar ) ],

  # only exposes keys that matches with /^json_/
  expose_stash => qr/^json_/,

Suppose you have data structure of the following.

  $c->stash->{foo} = [ 1, 2 ];
  $c->stash->{bar} = 2;

By default, this view will return:

  {"foo":[1,2],"bar":2}

When you set C<< expose_stash => [ 'foo' ] >>, it'll return

  {"foo":[1,2]}

and in the case of C<< expose_stash => 'foo' >>, it'll just return

  [1,2]

instead of the whole object (hashref in perl). This option will be
useful when you share the method with different views (e.g. TT) and
don't want to expose non-irrelevant stash variables as in JSON.

=item no_x_json_header

  no_x_json_header: 1

By default this plugin sets X-JSON header if the requested client is a
Prototype.js with X-JSON support. By setting 1, you can opt-out this
behavior so that you can do eval() by your own. Defaults to 0.

=item json_encoder_args

An optional hashref that supplies arguments to L<JSON::MaybeXS> used when creating
a new object.

=item use_force_bom

If versions of this view older than 0.36, there was some code that added a UTF-8 BOM
marker to the end of the JSON string when the user agent was Safari.  After looking
at a lot of existing code I don't think this is needed anymore so we removed it by
default.  However if this turns out to be a problem you can re enable it by setting
this attribute to true.  Possible a breaking change so we offer this workaround.

You may also override the method 'user_agent_bom_test' which received the current
request user agent string to try and better determine if this is needed.  Patches
for this welcomed.

=back

=head1 METHODS

=head2 process

Standard target of $c->forward used to prepare a response

=head2 render

The methods accepts either of the following argument signatures in order to promote
compatibility with the semi standard render method as define in numerous L<Catalyst>
views on CPAN:

    my $json_string = $c->view('JSON')->render($c, undef, $data);
    my $json_string = $c->view('JSON')->render($c, $data);

Given '$data' returns the JSON serialized version, or throws and error.

=head1 OVERRIDING JSON ENCODER

By default it uses L<JSON::MaybeXS::encode_json> to serialize perl data structure into
JSON data format. If you want to avoid this and encode with your own
encoder (like passing different options to L<JSON::MaybeXS> etc.), you can implement
the C<encode_json> method in your View class.

  package MyApp::View::JSON;
  use base qw( Catalyst::View::JSON );

  use JSON::MaybeXS ();

  sub encode_json {
      my($self, $c, $data) = @_;
      my $encoder = JSON::MaybeXS->new->(ascii => 1, pretty => 1, allow_nonref => 1);
      $encoder->encode($data);
  }

  1;

=head1 ENCODINGS

B<NOTE> Starting in release v5.90080 L<Catalyst> encodes all text
like body returns as UTF8.  It however ignores content types like
application/json and assumes that a correct JSON serializer is
doing what it is supposed to do, which is encode UTF8 automatically.
In general this is what this view does so you shoulding need to
mess with the encoding flag here unless you have some odd case.

Also, the comment about regard 'browser gotcha's' was written a
number of years ago and I can't say one way or another if those
gotchas continue to be common in the wild.

B<NOTE> Setting this configuation has no bearing on how the actual
serialized string is encoded.  This ONLY sets the content type
header in your response.  By default we set the 'utf8' flag on
L<JSON::MaybeXS> so that the string generated and set to your response
body is proper UTF8 octets that can be transmitted over HTTP.  If
you are planning to do some alternative encoding you should turn off
this default via the C<json_encoder_args>:

    MyApp::View::JSON->config(
      json_encoder_args => +{utf8=>0} );

B<NOTE> In 2015 the use of UTF8 as encoding is widely standard so it
is very likely you should need to do nothing to get the correct
encoding.  The following documentation will remain for historical
value and backcompat needs.

Due to the browser gotchas like those of Safari and Opera, sometimes
you have to specify a valid charset value in the response's
Content-Type header, e.g. C<text/javascript; charset=utf-8>.

Catalyst::View::JSON comes with the configuration variable C<encoding>
which defaults to utf-8. You can change it via C<< YourApp->config >>
or even runtime, using C<component>.

  $c->component('View::JSON')->encoding('euc-jp');

This assumes you set your stash data in raw euc-jp bytes, or Unicode
flagged variable. In case of Unicode flagged variable,
Catalyst::View::JSON automatically encodes the data into your
C<encoding> value (euc-jp in this case) before emitting the data to
the browser.

Another option would be to use I<JavaScript-UCS> as an encoding (and
pass Unicode flagged string to the stash). That way all non-ASCII
characters in the output JSON will be automatically encoded to
JavaScript Unicode encoding like I<\uXXXX>. You have to install
L<Encode::JavaScript::UCS> to use the encoding.

=head1 CALLBACKS

By default it returns raw JSON data so your JavaScript app can deal
with using XMLHttpRequest calls. Adding callbacks (JSONP) to the API
gives more flexibility to the end users of the API: overcome the
cross-domain restrictions of XMLHttpRequest. It can be done by
appending I<script> node with dynamic DOM manipulation, and associate
callback handler to the returned data.

For example, suppose you have the following code.

  sub end : Private {
      my($self, $c) = @_;
      if ($c->req->param('output') eq 'json') {
          $c->forward('View::JSON');
      } else {
          ...
      }
  }

C</foo/bar?output=json> will just return the data set in
C<< $c->stash >> as JSON format, like:

  { result: "foo", message: "Hello" }

but C</foo/bar?output=json&callback=handle_result> will give you:

  handle_result({ result: "foo", message: "Hello" });

and you can write a custom C<handle_result> function to handle the
returned data asynchronously.

The valid characters you can use in the callback function are

  [a-zA-Z0-9\.\_\[\]]

but you can customize the behaviour by overriding the
C<validate_callback_param> method in your View::JSON class.

See L<http://developer.yahoo.net/common/json.html> and
L<http://ajaxian.com/archives/jsonp-json-with-padding> for more about
JSONP.

B<NOTE> For another way to enable JSONP in your application take a look
at L<Plack::Middleware::JSONP>

=head1 INTEROPERABILITY

JSON use is still developing and has not been standardized. This
section provides some notes on various libraries.

Dojo Toolkit: Setting dojo.io.bind's mimetype to 'text/json' in
the JavaScript request will instruct dojo.io.bind to expect JSON
data in the response body and auto-eval it. Dojo ignores the
server response Content-Type. This works transparently with
Catalyst::View::JSON.

Prototype.js: prototype.js will auto-eval JSON data that is
returned in the custom X-JSON header. The reason given for this is
to allow a separate HTML fragment in the response body, however
this of limited use because IE 6 has a max header length that will
cause the JSON evaluation to silently fail when reached. The
recommend approach is to use Catalyst::View::JSON which will JSON
format all the response data and return it in the response body.

In at least prototype 1.5.0 rc0 and above, prototype.js will send the
X-Prototype-Version header. If this is encountered, a JavaScript eval
will be returned in the X-JSON response header to automatically eval
the response body, unless you set I<no_x_json_header> to 1. If your
version of prototype does not send this header, you can manually eval
the response body using the following JavaScript:

  evalJSON: function(request) {
    try {
      return eval('(' + request.responseText + ')');
    } catch (e) {}
  }
  // elsewhere
  var json = this.evalJSON(request);

B<NOTE> The above comments were written a number of years ago and
I would take then with a grain of salt so to speak.  For now I will
leave them in place but not sure they are meaningful in 2015.

=head1 SECURITY CONSIDERATION

Catalyst::View::JSON makes the data available as a (sort of)
JavaScript to the client, so you might want to be careful about the
security of your data.

=head2 Use callbacks only for public data

When you enable callbacks (JSONP) by setting C<allow_callback>, all
your JSON data will be available cross-site. This means embedding
private data of logged-in user to JSON is considered bad.

  # MyApp.yaml
  View::JSON:
    allow_callback: 1

  sub foo : Local {
      my($self, $c) = @_;
      $c->stash->{address} = $c->user->street_address; # BAD
      $c->forward('View::JSON');
  }

If you want to enable callbacks in a controller (for public API) and
disable in another, you need to create two different View classes,
like MyApp::View::JSON and MyApp::View::JSONP, because
C<allow_callback> is a static configuration of the View::JSON class.

See L<http://ajaxian.com/archives/gmail-csrf-security-flaw> for more.

=head2 Avoid valid cross-site JSON requests

Even if you disable the callbacks, the nature of JavaScript still has
a possibility to access private JSON data cross-site, by overriding
Array constructor C<[]>.

  # MyApp.yaml
  View::JSON:
    expose_stash: json

  sub foo : Local {
      my($self, $c) = @_;
      $c->stash->{json} = [ $c->user->street_address ]; # BAD
      $c->forward('View::JSON');
  }

When you return logged-in user's private data to the response JSON,
you might want to disable GET requests (because I<script> tag invokes
GET requests), or include a random digest string and validate it.

See
L<http://jeremiahgrossman.blogspot.com/2006/01/advanced-web-attack-techniques-using.html>
for more.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 CONTRIBUTORS

Following people has been contributing patches, bug reports and
suggestions for the improvement of Catalyst::View::JSON.

  John Wang
  kazeburo
  Daisuke Murase
  Jun Kuriyama
  Tomas Doran

=head1 SEE ALSO

L<Catalyst>, L<JSON::MaybeXS>, L<Encode::JavaScript::UCS>

L<http://www.prototypejs.org/learn/json>
L<http://docs.jquery.com/Ajax/jQuery.getJSON>
L<http://manual.dojotoolkit.org/json.html>
L<http://developer.yahoo.com/yui/json/>

=cut
