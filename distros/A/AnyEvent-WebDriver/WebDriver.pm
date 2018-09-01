=head1 NAME

AnyEvent::WebDriver - control browsers using the W3C WebDriver protocol

=head1 SYNOPSIS

   # start geckodriver or any other w3c-compatible webdriver via the shell
   $ geckdriver -b myfirefox/firefox --log trace --port 4444

   # then use it
   use AnyEvent::WebDriver;

   # create a new webdriver object
   my $wd = new AnyEvent::WebDriver;

   # create a new session with default capabilities.
   $wd->new_session ({});

   $wd->navigate_to ("https://duckduckgo.com/html");
   my $searchbox = $wd->find_element ("css selector" => 'input[type="text"]');

   $wd->element_send_keys ($searchbox => "free software");
   $wd->element_click ($wd->find_element ("css selector" => 'input[type="submit"]'));

   sleep 10;

=head1 DESCRIPTION

WARNING: THE API IS NOT GUARANTEED TO BE STABLE UNTIL VERSION 1.0.

This module aims to implement the W3C WebDriver specification which is the
standardised equivalent to the Selenium WebDriver API., which in turn aims
at remotely controlling web browsers such as Firefox or Chromium.

At the time of this writing, it was so brand new that I could only get
C<geckodriver> (For Firefox) to work, but that is expected to be fixed
very soon indeed.

To make most of this module, or, in fact, to make any reasonable use of
this module, you would need to refer to the W3C WebDriver recommendation,
which can be found L<here|https://www.w3.org/TR/webdriver1/>:

   https://www.w3.org/TR/webdriver1/

=head2 CONVENTIONS

Unless otherwise stated, all delays and time differences in this module
are represented as an integer number of milliseconds.

=cut

package AnyEvent::WebDriver;

use common::sense;

use Carp ();
use AnyEvent ();
use AnyEvent::HTTP ();

our $VERSION = 0.9;

our $WEB_ELEMENT_IDENTIFIER = "element-6066-11e4-a52e-4f735466cecf";
our $WEB_WINDOW_IDENTIFIER  =  "window-fcc6-11e5-b4f8-330a88ab9d7f";
our $WEB_FRAME_IDENTIFIER   =   "frame-075b-4da1-b6ba-e579c2d3230a";

my $json = eval { require JSON::XS; JSON::XS:: } || do { require JSON::PP; JSON::PP:: };
$json = $json->new->utf8;

$json->boolean_values (0, 1)
   if $json->can ("boolean_values");

sub req_ {
   my ($self, $method, $ep, $body, $cb) = @_;

   AnyEvent::HTTP::http_request $method => "$self->{_ep}$ep",
      body => $body,
      $self->{persistent} ? (persistent => 1) : (),
      $self->{proxy} eq "default" ? () : (proxy => $self->{proxy}),
      timeout => $self->{timeout},
      headers => { "content-type" => "application/json; charset=utf-8", "cache-control" => "no-cache" },
      sub {
         my ($res, $hdr) = @_;

         $res = eval { $json->decode ($res) };
         $hdr->{Status} = 500 unless exists $res->{value};

         $cb->($hdr->{Status}, $res->{value});
      }
   ;
}

sub get_ {
   my ($self, $ep, $cb) = @_;

   $self->req_ (GET => $ep, undef, $cb)
}

sub post_ {
   my ($self, $ep, $data, $cb) = @_;

   $self->req_ (POST => $ep, $json->encode ($data || {}), $cb)
}

sub delete_ {
   my ($self, $ep, $cb) = @_;

   $self->req_ (DELETE => $ep, "", $cb)
}

sub AUTOLOAD {
   our $AUTOLOAD;

   $_[0]->isa (__PACKAGE__)
      or Carp::croak "$AUTOLOAD: no such function";

   (my $name = $AUTOLOAD) =~ s/^.*://;

   my $name_ = "$name\_";

   defined &$name_
      or Carp::croak "$AUTOLOAD: no such method";

   my $func_ = \&$name_;

   *$name = sub {
      $func_->(@_, my $cv = AE::cv);
      my ($status, $res) = $cv->recv;

      if ($status ne "200") {
         my $msg;

         if (exists $res->{error}) {
            $msg = "AyEvent::WebDriver: $res->{error}: $res->{message}";
            $msg .= "\n$res->{stacktrace}caught at" if length $res->{stacktrace};
         } else {
            $msg = "AnyEvent::WebDriver: http status $status (wrong endpoint?), caught";
         }

         Carp::croak $msg;
      }

      $res
   };

   goto &$name;
}

=head2 WEBDRIVER OBJECTS

=over

=item new AnyEvent::WebDriver key => value...

Create a new WebDriver object. Example for a remote WebDriver connection
(the only type supported at the moment):

   my $wd = new AnyEvent::WebDriver host => "localhost", port => 4444;

Supported keys are:

=over

=item endpoint => $string

For remote connections, the endpoint to connect to (defaults to C<http://localhost:4444>).

=item proxy => $proxyspec

The proxy to use (same as the C<proxy> argument used by
L<AnyEvent::HTTP>). The default is C<undef>, which disables proxies. To
use the system-provided proxy (e.g. C<http_proxy> environment variable),
specify a value of C<default>.

=item autodelete => $boolean

If true (the default), then automatically execute C<delete_session> when
the WebDriver object is destroyed with an active session. IF set to a
false value, then the session will continue to exist.

=item timeout => $seconds

The HTTP timeout, in (fractional) seconds (default: C<300>, but this will
likely drastically reduce). This timeout is reset on any activity, so it
is not an overall request timeout. Also, individual requests might extend
this timeout if they are known to take longer.

=item persistent => C<1> | C<undef>

If true (the default) then persistent connections will be used for all
requests, which assumes you have a reasonably stable connection (such as
to C<localhost> :) and that the WebDriver has a persistent timeout much
higher than what L<AnyEvent::HTTP> uses.

You can force connections to be closed for non-idempotent requests by
setting this to C<undef>.

=back

=cut

sub new {
   my ($class, %kv) = @_;

   bless {
      endpoint   => "http://localhost:4444",
      proxy      => undef,
      persistent => 1,
      autodelete => 1,
      timeout    => 300,
      %kv,
   }, $class
}

sub DESTROY {
   my ($self) = @_;

   $self->delete_session
      if exists $self->{sid};
}

=item $al = $wd->actions

Creates an action list associated with this WebDriver. See L<ACTION
LISTS>, below, for full details.

=cut

sub actions {
   AnyEvent::WebDriver::Actions->new (wd => $_[0])
}

=item $sessionstring = $wd->save_session

Save the current session in a string so it can be restored load with
C<load_session>. Note that only the session data itself is stored
(currently the session id and capabilities), not the endpoint information
itself.

The main use of this function is in conjunction with disabled
C<autodelete>, to save a session to e.g., and restore it later. It could
presumably used for other applications, such as using the same session
from multiple processes and so on.

=item $wd->load_session ($sessionstring)

=item $wd->set_session ($sessionid, $capabilities)

Starts using the given session, as identified by
C<$sessionid>. C<$capabilities> should be the original session
capabilities, although the current version of this module does not make
any use of it.

The C<$sessionid> is stored in C<< $wd->{sid} >> (and could be fetched
form there for later use), while the capabilities are stored in C<<
$wd->{capabilities} >>.

=cut

sub save_session {
   my ($self) = @_;

   $json->encode ([1, $self->{sid}, $self->{capabilities}]);
}

sub load_session {
   my ($self, $session) = @_;

   $session = $json->decode ($session);

   $session->[0] == 1
      or Carp::croak "AnyEvent::WebDriver::load_session: session corrupted or from different version";

   $self->set_session ($session->[1], $session->[2]);
}

sub set_session {
   my ($self, $sid, $caps) = @_;

   $self->{sid}          = $sid;
   $self->{capabilities} = $caps;

   $self->{_ep} = "$self->{endpoint}/session/$self->{sid}/";
}

=back

=head2 SIMPLIFIED API

This section documents the simplified API, which is really just a very
thin wrapper around the WebDriver protocol commands. They all block (using
L<AnyEvent> condvars) the caller until the result is available, so must
not be called from an event loop callback - see L<EVENT BASED API> for an
alternative.

The method names are pretty much taken directly from the W3C WebDriver
specification, e.g. the request documented in the "Get All Cookies"
section is implemented via the C<get_all_cookies> method.

The order is the same as in the WebDriver draft at the time of this
writing, and only minimal massaging is done to request parameters and
results.

=head3 SESSIONS

=over

=cut

=item $wd->new_session ({ key => value... })

Try to connect to the WebDriver and initialize a new session with a
"new session" command, passing the given key-value pairs as value
(e.g. C<capabilities>).

No session-dependent methods must be called before this function returns
successfully, and only one session can be created per WebDriver object.

On success, C<< $wd->{sid} >> is set to the session ID, and C<<
$wd->{capabilities} >> is set to the returned capabilities.

Simple example of creating a WebDriver object and a new session:

   my $wd = new AnyEvent::Selenium endpoint => "http://localhost:4545";
   $wd->new_session ({});

Real-world example with capability negotiation:

   $wd->new_session ({
      capabilities => {
         alwaysMatch => {
            pageLoadStrategy        => "eager",
            unhandledPromptBehavior => "dismiss",
            # proxy => { proxyType => "manual", httpProxy => "1.2.3.4:56", sslProxy => "1.2.3.4:56" },
         },
         firstMatch => [
            {
               browserName => "firefox",
               "moz:firefoxOptions" => {
                  binary => "firefox/firefox",
                  args => ["-devtools"],
                  prefs => {
                     "dom.webnotifications.enabled" => \0,
                     "dom.push.enabled" => \0,
                     "dom.disable_beforeunload" => \1,
                     "browser.link.open_newwindow" => 3,
                     "browser.link.open_newwindow.restrictions" => 0,
                     "dom.popup_allowed_events" => "",
                     "dom.disable_open_during_load" => \1,
                  },
               },
            },
            {
               # generic fallback
            },
         ],

      },
   });

Firefox-specific capability documentation can be found L<on
MDN|https://developer.mozilla.org/en-US/docs/Web/WebDriver/Capabilities>,
Chrome-specific capability documentation might be found
L<here|http://chromedriver.chromium.org/capabilities>, but the latest
release at the time of this writing has effectively no WebDriver support
at all, and canary releases are not freely downloadable.

If you have URLs for Safari/IE/Edge etc. capabilities, feel free to tell
me about them.

=cut

sub new_session_ {
   my ($self, $kv, $cb) = @_;

   local $self->{_ep} = "$self->{endpoint}/";
   $self->post_ (session => $kv, sub {
      my ($status, $res) = @_;

      exists $res->{capabilities}
         or $status = "500"; # blasted chromedriver

      $self->set_session ($res->{sessionId}, $res->{capabilities})
         if $status eq "200";

      $cb->($status, $res);
   });
}

=item $wd->delete_session

Deletes the session - the WebDriver object must not be used after this
call.

=cut

sub delete_session_ {
   my ($self, $cb) = @_;

   local $self->{_ep} = "$self->{endpoint}/session/$self->{sid}";
   $self->delete_ ("" => $cb);
}

=item $timeouts = $wd->get_timeouts

Get the current timeouts, e.g.:

   my $timeouts = $wd->get_timeouts;
   => { implicit => 0, pageLoad => 300000, script => 30000 }

=item $wd->set_timeouts ($timeouts)

Sets one or more timeouts, e.g.:

   $wd->set_timeouts ({ script => 60000 });

=cut

sub get_timeouts_ {
   $_[0]->get_ (timeouts => $_[1], $_[2]);
}

sub set_timeouts_ {
   $_[0]->post_ (timeouts => $_[1], $_[2], $_[3]);
}

=back

=head3 NAVIGATION

=over

=cut

=item $wd->navigate_to ($url)

Navigates to the specified URL.

=item $url = $wd->get_current_url

Queries the current page URL as set by C<navigate_to>.

=cut

sub navigate_to_ {
   $_[0]->post_ (url => { url => "$_[1]" }, $_[2]);
}

sub get_current_url_ {
   $_[0]->get_ (url => $_[1])
}

=item $wd->back

The equivalent of pressing "back" in the browser.

=item $wd->forward

The equivalent of pressing "forward" in the browser.

=item $wd->refresh

The equivalent of pressing "refresh" in the browser.

=cut

sub back_ {
   $_[0]->post_ (back => undef, $_[1]);
}

sub forward_ {
   $_[0]->post_ (forward => undef, $_[1]);
}

sub refresh_ {
   $_[0]->post_ (refresh => undef, $_[1]);
}

=item $title = $wd->get_title

Returns the current document title.

=cut

sub get_title_ {
   $_[0]->get_ (title => $_[1]);
}

=back

=head3 COMMAND CONTEXTS

=over

=cut

=item $handle = $wd->get_window_handle

Returns the current window handle.

=item $wd->close_window

Closes the current browsing context.

=item $wd->switch_to_window ($handle)

Changes the current browsing context to the given window.

=cut

sub get_window_handle_ {
   $_[0]->get_ (window => $_[1]);
}

sub close_window_ {
   $_[0]->delete_ (window => $_[1]);
}

sub switch_to_window_ {
   $_[0]->post_ (window => { handle => "$_[1]" }, $_[2]);
}

=item $handles = $wd->get_window_handles

Return the current window handles as an array-ref of handle IDs.

=cut

sub get_window_handles_ {
   $_[0]->get_ ("window/handles" => $_[1]);
}

=item $handles = $wd->switch_to_frame ($frame)

Switch to the given frame identified by C<$frame>, which must be either
C<undef> to go back to the top-level browsing context, an integer to
select the nth subframe, or an element object.

=cut

sub switch_to_frame_ {
   $_[0]->post_ (frame => { id => "$_[1]" }, $_[2]);
}

=item $handles = $wd->switch_to_parent_frame

Switch to the parent frame.

=cut

sub switch_to_parent_frame_ {
   $_[0]->post_ ("frame/parent" => undef, $_[1]);
}

=item $rect = $wd->get_window_rect

Return the current window rect(angle), e.g.:

   $rect = $wd->get_window_rect
   => { height => 1040, width => 540, x => 0, y => 0 }

=item $wd->set_window_rect ($rect)

Sets the window rect(angle).

=cut

sub get_window_rect_ {
   $_[0]->get_ ("window/rect" => $_[1]);
}

sub set_window_rect_ {
   $_[0]->post_ ("window/rect" => $_[1], $_[2]);
}

=item $wd->maximize_window

=item $wd->minimize_window

=item $wd->fullscreen_window

Changes the window size by either maximising, minimising or making it
fullscreen. In my experience, this will timeout if no window manager is
running.

=cut

sub maximize_window_ {
   $_[0]->post_ ("window/maximize" => undef, $_[1]);
}

sub minimize_window_ {
   $_[0]->post_ ("window/minimize" => undef, $_[1]);
}

sub fullscreen_window_ {
   $_[0]->post_ ("window/fullscreen" => undef, $_[1]);
}

=back

=head3 ELEMENT RETRIEVAL

To reduce typing and memory strain, the element finding functions accept
some shorter and hopefully easier to remember aliases for the standard
locator strategy values, as follows:

   Alias   Locator Strategy
   css     css selector
   link    link text
   substr  partial link text
   tag     tag name

=over

=cut

our %USING = (
   css    => "css selector",
   link   => "link text",
   substr => "partial link text",
   tag    => "tag name",
);

sub _using($) {
   using => $USING{$_[0]} // "$_[0]"
}

=item $element = $wd->find_element ($locator_strategy, $selector)

Finds the first element specified by the given selector and returns its
element object. Raises an error when no element was found.

Examples showing all standard locator strategies:

   $element = $wd->find_element ("css selector" => "body a");
   $element = $wd->find_element ("link text" => "Click Here For Porn");
   $element = $wd->find_element ("partial link text" => "orn");
   $element = $wd->find_element ("tag name" => "input");
   $element = $wd->find_element ("xpath" => '//input[@type="text"]');
   => e.g. { "element-6066-11e4-a52e-4f735466cecf" => "decddca8-5986-4e1d-8c93-efe952505a5f" }

Same examples using aliases provided by this module:

   $element = $wd->find_element (css => "body a");
   $element = $wd->find_element (link => "Click Here For Porn");
   $element = $wd->find_element (substr => "orn");
   $element = $wd->find_element (tag => "input");

=item $elements = $wd->find_elements ($locator_strategy, $selector)

As above, but returns an arrayref of all found element objects.

=item $element = $wd->find_element_from_element ($element, $locator_strategy, $selector)

Like C<find_element>, but looks only inside the specified C<$element>.

=item $elements = $wd->find_elements_from_element ($element, $locator_strategy, $selector)

Like C<find_elements>, but looks only inside the specified C<$element>.

   my $head = $wd->find_element ("tag name" => "head");
   my $links = $wd->find_elements_from_element ($head, "tag name", "link");

=item $element = $wd->get_active_element

Returns the active element.

=cut

sub find_element_ {
   $_[0]->post_ (element => { _using $_[1], value => "$_[2]" }, $_[3]);
}

sub find_elements_ {
   $_[0]->post_ (elements => { _using $_[1], value => "$_[2]" }, $_[3]);
}

sub find_element_from_element_ {
   $_[0]->post_ ("element/$_[1]/element" => { _using $_[2], value => "$_[3]" }, $_[4]);
}

sub find_elements_from_element_ {
   $_[0]->post_ ("element/$_[1]/elements" => { _using $_[2], value => "$_[3]" }, $_[4]);
}

sub get_active_element_ {
   $_[0]->get_ ("element/active" => $_[1]);
}

=back

=head3 ELEMENT STATE

=over

=cut

=item $bool = $wd->is_element_selected

Returns whether the given input or option element is selected or not.

=item $string = $wd->get_element_attribute ($element, $name)

Returns the value of the given attribute.

=item $string = $wd->get_element_property ($element, $name)

Returns the value of the given property.

=item $string = $wd->get_element_css_value ($element, $name)

Returns the value of the given CSS value.

=item $string = $wd->get_element_text ($element)

Returns the (rendered) text content of the given element.

=item $string = $wd->get_element_tag_name ($element)

Returns the tag of the given element.

=item $rect = $wd->get_element_rect ($element)

Returns the element rect(angle) of the given element.

=item $bool = $wd->is_element_enabled

Returns whether the element is enabled or not.

=cut

sub is_element_selected_ {
   $_[0]->get_ ("element/$_[1]{$WEB_ELEMENT_IDENTIFIER}/selected" => $_[2]);
}

sub get_element_attribute_ {
   $_[0]->get_ ("element/$_[1]{$WEB_ELEMENT_IDENTIFIER}/attribute/$_[2]" => $_[3]);
}

sub get_element_property_ {
   $_[0]->get_ ("element/$_[1]{$WEB_ELEMENT_IDENTIFIER}/property/$_[2]" => $_[3]);
}

sub get_element_css_value_ {
   $_[0]->get_ ("element/$_[1]{$WEB_ELEMENT_IDENTIFIER}/css/$_[2]" => $_[3]);
}

sub get_element_text_ {
   $_[0]->get_ ("element/$_[1]{$WEB_ELEMENT_IDENTIFIER}/text" => $_[2]);
}

sub get_element_tag_name_ {
   $_[0]->get_ ("element/$_[1]{$WEB_ELEMENT_IDENTIFIER}/name" => $_[2]);
}

sub get_element_rect_ {
   $_[0]->get_ ("element/$_[1]{$WEB_ELEMENT_IDENTIFIER}/rect" => $_[2]);
}

sub is_element_enabled_ {
   $_[0]->get_ ("element/$_[1]{$WEB_ELEMENT_IDENTIFIER}/enabled" => $_[2]);
}

=back

=head3 ELEMENT INTERACTION

=over

=cut

=item $wd->element_click ($element)

Clicks the given element.

=item $wd->element_clear ($element)

Clear the contents of the given element.

=item $wd->element_send_keys ($element, $text)

Sends the given text as key events to the given element.

=cut

sub element_click_ {
   $_[0]->post_ ("element/$_[1]{$WEB_ELEMENT_IDENTIFIER}/click" => undef, $_[2]);
}

sub element_clear_ {
   $_[0]->post_ ("element/$_[1]{$WEB_ELEMENT_IDENTIFIER}/clear" => undef, $_[2]);
}

sub element_send_keys_ {
   $_[0]->post_ ("element/$_[1]{$WEB_ELEMENT_IDENTIFIER}/value" => { text => "$_[2]" }, $_[3]);
}

=back

=head3 DOCUMENT HANDLING

=over

=cut

=item $source = $wd->get_page_source

Returns the (HTML/XML) page source of the current document.

=item $results = $wd->execute_script ($javascript, $args)

Synchronously execute the given script with given arguments and return its
results (C<$args> can be C<undef> if no arguments are wanted/needed).

   $ten = $wd->execute_script ("return arguments[0]+arguments[1]", [3, 7]);

=item $results = $wd->execute_async_script ($javascript, $args)

Similar to C<execute_script>, but doesn't wait for script to return, but
instead waits for the script to call its last argument, which is added to
C<$args> automatically.

  $twenty = $wd->execute_async_script ("arguments[0](20)", undef);

=cut

sub get_page_source_ {
   $_[0]->get_ (source => $_[1]);
}

sub execute_script_ {
   $_[0]->post_ ("execute/sync" => { script => "$_[1]", args => $_[2] || [] }, $_[3]);
}

sub execute_async_script_ {
   $_[0]->post_ ("execute/async" => { script => "$_[1]", args => $_[2] || [] }, $_[3]);
}

=back

=head3 COOKIES

=over

=cut

=item $cookies = $wd->get_all_cookies

Returns all cookies, as an arrayref of hashrefs.

   # google surely sets a lot of cookies without my consent
   $wd->navigate_to ("http://google.com");
   use Data::Dump;
   ddx $wd->get_all_cookies;

=item $cookie = $wd->get_named_cookie ($name)

Returns a single cookie as a hashref.

=item $wd->add_cookie ($cookie)

Adds the given cookie hashref.

=item $wd->delete_cookie ($name)

Delete the named cookie.

=item $wd->delete_all_cookies

Delete all cookies.

=cut

sub get_all_cookies_ {
   $_[0]->get_ (cookie => $_[1]);
}

sub get_named_cookie_ {
   $_[0]->get_ ("cookie/$_[1]" => $_[2]);
}

sub add_cookie_ {
   $_[0]->post_ (cookie => { cookie => $_[1] }, $_[2]);
}

sub delete_cookie_ {
   $_[0]->delete_ ("cookie/$_[1]" => $_[2]);
}

sub delete_all_cookies_ {
   $_[0]->delete_ (cookie => $_[2]);
}

=back

=head3 ACTIONS

=over

=cut

=item $wd->perform_actions ($actions)

Perform the given actions (an arrayref of action specifications simulating
user activity, or an C<AnyEvent::WebDriver::Actions> object). For further
details, read the spec or the section L<ACTION LISTS>, below.

An example to get you started (see the next example for a mostly
equivalent example using the C<AnyEvent::WebDriver::Actions> helper API):

   $wd->navigate_to ("https://duckduckgo.com/html");
   my $input = $wd->find_element ("css selector", 'input[type="text"]');
   $wd->perform_actions ([
      {
         id => "myfatfinger",
         type => "pointer",
         pointerType => "touch",
         actions => [
            { type => "pointerMove", duration => 100, origin => $input, x => 40, y => 5 },
            { type => "pointerDown", button => 1 },
            { type => "pause", duration => 40 },
            { type => "pointerUp", button => 1 },
         ],
      },
      {
         id => "mykeyboard",
         type => "key",
         actions => [
            { type => "pause" },
            { type => "pause" },
            { type => "pause" },
            { type => "pause" },
            { type => "keyDown", value => "a" },
            { type => "pause", duration => 100 },
            { type => "keyUp", value => "a" },
            { type => "pause", duration => 100 },
            { type => "keyDown", value => "b" },
            { type => "pause", duration => 100 },
            { type => "keyUp", value => "b" },
            { type => "pause", duration => 2000 },
            { type => "keyDown", value => "\x{E007}" }, # enter
            { type => "pause", duration => 100 },
            { type => "keyUp", value => "\x{E007}" }, # enter
            { type => "pause", duration => 5000 },
         ],
      },
   ]);

And here is essentially the same (except for fewer pauses) example as
above, using the much simpler C<AnyEvent::WebDriver::Actions> API. Note
that the pointer up and key down event happen concurrently in this
example:

   $wd->navigate_to ("https://duckduckgo.com/html");
   my $input = $wd->find_element ("css selector", 'input[type="text"]');
   $wd->actions
      ->move ($input, 40, 5, "touch1")
      ->click
      ->key ("a")
      ->key ("b")
      ->pause (2000)
      ->key ("\x{E007}")
      ->pause (5000)
      ->perform;

=item $wd->release_actions

Release all keys and pointer buttons currently depressed.

=cut

sub perform_actions_ {
   if (UNIVERSAL::isa $_[1], AnyEvent::WebDriver::Actions::) {
      my ($actions, $duration) = $_[1]->compile;
      local $_[0]{timeout} = $_[0]{timeout} + $duration * 1e-3;
      $_[0]->post_ (actions => { actions => $actions }, $_[2]);
   } else {
      $_[0]->post_ (actions => { actions => $_[1] }, $_[2]);
   }
}

sub release_actions_ {
   $_[0]->delete_ (actions => $_[1]);
}

=back

=head3 USER PROMPTS

=over

=cut

=item $wd->dismiss_alert

Dismiss a simple dialog, if present.

=item $wd->accept_alert

Accept a simple dialog, if present.

=item $text = $wd->get_alert_text

Returns the text of any simple dialog.

=item $text = $wd->send_alert_text

Fills in the user prompt with the given text.


=cut

sub dismiss_alert_ {
   $_[0]->post_ ("alert/dismiss" => undef, $_[1]);
}

sub accept_alert_ {
   $_[0]->post_ ("alert/accept" => undef, $_[1]);
}

sub get_alert_text_ {
   $_[0]->get_ ("alert/text" => $_[1]);
}

sub send_alert_text_ {
   $_[0]->post_ ("alert/text" => { text => "$_[1]" }, $_[2]);
}

=back

=head3 SCREEN CAPTURE

=over

=cut

=item $wd->take_screenshot

Create a screenshot, returning it as a PNG image in a C<data:> URL.

=item $wd->take_element_screenshot ($element)

Accept a simple dialog, if present.

=cut

sub take_screenshot_ {
   $_[0]->get_ (screenshot => $_[1]);
}

sub take_element_screenshot_ {
   $_[0]->get_ ("element/$_[1]{$WEB_ELEMENT_IDENTIFIER}/screenshot" => $_[2]);
}

=back

=head2 ACTION LISTS

Action lists can be quite complicated. Or at least it took a while for
me to twist my head around them. Basically, an action list consists of a
number of sources representing devices (such as a finger, a mouse, a pen
or a keyboard) and a list of actions for each source.

An action can be a key press, a pointer move or a pause (time
delay). Actions from different sources can happen "at the same time",
while actions from a single source are executed in order.

While you can provide an action list manually, it is (hopefully) less
cumbersome to use the API described in this section to create them.

The basic process of creating and performing actions is to create a new
action list, adding action sources, followed by adding actions. Finally
you would C<perform> those actions on the WebDriver.

Virtual time progresses as long as you add actions to the same event
source. Adding events to different sources are considered to happen
concurrently. If you want to force time to progress, you can do this using
a call to C<< ->pause (0) >>.

Most methods here are designed to chain, i.e. they return the web actions
object, to simplify multiple calls.

For example, to simulate a mouse click to an input element, followed by
entering some text and pressing enter, you can use this:

   $wd->actions
      ->click (1, 100)
      ->type ("some text")
      ->key ("{Enter}")
      ->perform;

By default, keyboard and mouse input sources are provided. You can create
your own sources and use them when adding events. The above example could
be more verbosely written like this:

   $wd->actions
      ->source ("mouse", "pointer", pointerType => "mouse")
      ->source ("kbd", "key")
      ->click (1, 100, "mouse")
      ->type ("some text", "kbd")
      ->key ("{Enter}", "kbd")
      ->perform;

When you specify the event source explicitly it will switch the current
"focus" for this class of device (all keyboards are in one class, all
pointer-like devices such as mice/fingers/pens are in one class), so you
don't have to specify the source for subsequent actions.

When you use the sources C<keyboard>, C<mouse>, C<touch1>..C<touch3>,
C<pen> without defining them, then a suitable default source will be
created for them.

=over 4

=cut

package AnyEvent::WebDriver::Actions;

=item $al = new AnyEvent::WebDriver::Actions

Create a new empty action list object. More often you would use the C<<
$wd->action_list >> method to create one that is already associated with
a given web driver.

=cut

sub new {
   my ($class, %kv) = @_;

   $kv{last_kbd} = "keyboard";
   $kv{last_ptr} = "mouse";

   bless \%kv, $class
}

=item $al = $al->source ($id, $type, key => value...)

The first time you call this with a given ID, this defines the event
source using the extra parameters. Subsequent calls merely switch the
current source for its event class.

It's not an error to define built-in sources (such as C<keyboard> or
C<touch1>) differently then the defaults.

Example: define a new touch device called C<fatfinger>.

   $al->source (fatfinger => "pointer", pointerType => "touch");

Example: define a new touch device called C<fatfinger>.

   $al->source (fatfinger => "pointer", pointerType => "touch");

Example: switch default keyboard source to C<kbd1>, assuming it is of C<key> class.

   $al->source ("kbd1");

=cut

sub _default_source($) {
   my ($source) = @_;

      $source eq "keyboard" ? { actions => [], id => $source, type => "key" }
    : $source eq "mouse"    ? { actions => [], id => $source, type => "pointer", pointerType => "mouse" }
    : $source eq "touch"    ? { actions => [], id => $source, type => "pointer", pointerType => "touch" }
    : $source eq "pen"      ? { actions => [], id => $source, type => "pointer", pointerType => "pen" }
    : Carp::croak "AnyEvent::WebDriver::Actions: event source '$source' not defined"
}

my %source_class = (
   key     => "kbd",
   pointer => "ptr",
);

sub source {
   my ($self, $id, $type, %kv) = @_;

   if (defined $type) {
      !exists $self->{source}{$id}
         or Carp::croak "AnyEvent::WebDriver::Actions: source '$id' already defined";

      $kv{id}      = $id;
      $kv{type}    = $type;
      $kv{actions} = [];

      $self->{source}{$id} = \%kv;
   }

   my $source = $self->{source}{$id} ||= _default_source $id;

   my $last = $source_class{$source->{type}} // "xxx";

   $self->{"last_$last"} = $id;

   $self
}

sub _add {
   my ($self, $source, $sourcetype, $type, %kv) = @_;

   my $last = \$self->{"last_$sourcetype"};

   $source
      ? ($$last = $source)
      : ($source = $$last);

   my $source = $self->{source}{$source} ||= _default_source $source;

   my $al = $source->{actions};

   push @$al, { type => "pause" }
      while @$al < $self->{tick} - 1;

   $kv{type} = $type;

   push @{ $source->{actions} }, \%kv;

   $self->{tick_duration} = $kv{duration}
      if $kv{duration} > $self->{tick_duration};

   if ($self->{tick} != @$al) {
      $self->{tick} = @$al;
      $self->{duration} += delete $self->{tick_duration};
   }

   $self
}

=item $al = $al->pause ($duration)

Creates a pause with the given duration. Makes sure that time progresses
in any case, even when C<$duration> is C<0>.

=cut

sub pause {
   my ($self, $duration) = @_;

   $self->{tick_duration} = $duration
      if $duration > $self->{tick_duration};

   $self->{duration} += delete $self->{tick_duration};

   # find the source with the longest list

   for my $source (values %{ $self->{source} }) {
      if (@{ $source->{actions} } == $self->{tick}) {
         # this source is one of the longest

         # create a pause event only if $duration is non-zero...
         push @{ $source->{actions} }, { type => "pause", duration => $duration*1 }
            if $duration;

         # ... but advance time in any case
         ++$self->{tick};

         return $self;
      }
   }

   # no event sources are longest. so advance time in any case
   ++$self->{tick};

   Carp::croak "AnyEvent::WebDriver::Actions: multiple pause calls in a row not (yet) supported"
      if $duration;

   $self
}

=item $al = $al->pointer_down ($button, $source)

=item $al = $al->pointer_up ($button, $source)

Press or release the given button. C<$button> defaults to C<1>.

=item $al = $al->click ($button, $source)

Convenience function that creates a button press and release action
without any delay between them. C<$button> defaults to C<1>.

=item $al = $al->doubleclick ($button, $source)

Convenience function that creates two button press and release action
pairs in a row, with no unnecessary delay between them. C<$button>
defaults to C<1>.

=cut

sub pointer_down {
   my ($self, $button, $source) = @_;

   $self->_add ($source, ptr => pointerDown => button => ($button // 1)*1)
}

sub pointer_up {
   my ($self, $button, $source) = @_;

   $self->_add ($source, ptr => pointerUp => button => ($button // 1)*1)
}

sub click {
   my ($self, $button, $source) = @_;

   $self
      ->pointer_down ($button, $source)
      ->pointer_up   ($button)
}

sub doubleclick {
   my ($self, $button, $source) = @_;

   $self
      ->click ($button, $source)
      ->click ($button)
}

=item $al = $al->move ($button, $origin, $x, $y, $duration, $source)

Moves a pointer to the given position, relative to origin (either
"viewport", "pointer" or an element object.

=cut

sub move {
   my ($self, $origin, $x, $y, $duration, $source) = @_;

   $self->_add ($source, ptr => pointerMove =>
                origin => $origin, x => $x*1, y => $y*1, duration => $duration*1)
}

=item $al = $al->keyDown ($key, $source)

=item $al = $al->keyUp ($key, $source)

Press or release the given key.

=item $al = $al->key ($key, $source)

Peess and release the given key, without unnecessary delay.

A special syntax, C<{keyname}> can be used for special keys - all the special key names from
L<section 17.4.2|https://www.w3.org/TR/webdriver1/#keyboard-actions> of the WebDriver recommendation
can be used.

Example: press and release "a".

   $al->key ("a");

Example: press and release the "Enter" key:

   $al->key ("\x{e007}");

Example: press and release the "enter" key using the special key name syntax:

   $al->key ("{Enter}");

=item $al = $al->type ($string, $source)

Convenience method to simulate a series of key press and release events
for the keys in C<$string>. There is no syntax for special keys,
everything will be typed "as-is" if possible.

=cut

our %SPECIAL_KEY = (
   "Unidentified"   => 0xE000,
   "Cancel"         => 0xE001,
   "Help"           => 0xE002,
   "Backspace"      => 0xE003,
   "Tab"            => 0xE004,
   "Clear"          => 0xE005,
   "Return"         => 0xE006,
   "Enter"          => 0xE007,
   "Shift"          => 0xE008,
   "Control"        => 0xE009,
   "Alt"            => 0xE00A,
   "Pause"          => 0xE00B,
   "Escape"         => 0xE00C,
   " "              => 0xE00D,
   "PageUp"         => 0xE00E,
   "PageDown"       => 0xE00F,
   "End"            => 0xE010,
   "Home"           => 0xE011,
   "ArrowLeft"      => 0xE012,
   "ArrowUp"        => 0xE013,
   "ArrowRight"     => 0xE014,
   "ArrowDown"      => 0xE015,
   "Insert"         => 0xE016,
   "Delete"         => 0xE017,
   ";"              => 0xE018,
   "="              => 0xE019,
   "0"              => 0xE01A,
   "1"              => 0xE01B,
   "2"              => 0xE01C,
   "3"              => 0xE01D,
   "4"              => 0xE01E,
   "5"              => 0xE01F,
   "6"              => 0xE020,
   "7"              => 0xE021,
   "8"              => 0xE022,
   "9"              => 0xE023,
   "*"              => 0xE024,
   "+"              => 0xE025,
   ","              => 0xE026,
   "-"              => 0xE027,
   "."              => 0xE028,
   "/"              => 0xE029,
   "F1"             => 0xE031,
   "F2"             => 0xE032,
   "F3"             => 0xE033,
   "F4"             => 0xE034,
   "F5"             => 0xE035,
   "F6"             => 0xE036,
   "F7"             => 0xE037,
   "F8"             => 0xE038,
   "F9"             => 0xE039,
   "F10"            => 0xE03A,
   "F11"            => 0xE03B,
   "F12"            => 0xE03C,
   "Meta"           => 0xE03D,
   "ZenkakuHankaku" => 0xE040,
   "Shift"          => 0xE050,
   "Control"        => 0xE051,
   "Alt"            => 0xE052,
   "Meta"           => 0xE053,
   "PageUp"         => 0xE054,
   "PageDown"       => 0xE055,
   "End"            => 0xE056,
   "Home"           => 0xE057,
   "ArrowLeft"      => 0xE058,
   "ArrowUp"        => 0xE059,
   "ArrowRight"     => 0xE05A,
   "ArrowDown"      => 0xE05B,
   "Insert"         => 0xE05C,
   "Delete"         => 0xE05D,
);

sub _kv($) {
   $_[0] =~ /^\{(.*)\}$/s
      ? (exists $SPECIAL_KEY{$1}
           ? chr $SPECIAL_KEY{$1}
           : Carp::croak "AnyEvent::WebDriver::Actions: special key '$1' not known")
      : $_[0]
}

sub key_down {
   my ($self, $key, $source) = @_;

   $self->_add ($source, kbd => keyDown => value => _kv $key)
}

sub key_up {
   my ($self, $key, $source) = @_;

   $self->_add ($source, kbd => keyUp => value => _kv $key)
}

sub key {
   my ($self, $key, $source) = @_;

   $self
      ->key_down ($key, $source)
      ->key_up   ($key)
}

sub type {
   my ($self, $string, $source) = @_;

   $self->key ($_, $source)
      for $string =~ /(\X)/g;

   $self
}

=item $al->perform ($wd)

Finalises and compiles the list, if not done yet, and calls C<<
$wd->perform >> with it.

If C<$wd> is undef, and the action list was created using the C<<
$wd->actions >> method, then perform it against that WebDriver object.

There is no underscore variant - call the C<perform_actions_> method with
the action object instead.

=item $al->perform_release ($wd)

Exactly like C<perform>, but additionally call C<release_actions>
afterwards.

=cut

sub perform {
   my ($self, $wd) = @_;

   ($wd //= $self->{wd})->perform_actions ($self)
}

sub perform_release {
   my ($self, $wd) = @_;

   ($wd //= $self->{wd})->perform_actions ($self);
   $wd->release_actions;
}

=item ($actions, $duration) = $al->compile

Finalises and compiles the list, if not done yet, and returns an actions
object suitable for calls to C<< $wd->perform_actions >>. When called in
list context, additionally returns the total duration of the action list.

Since building large action lists can take nontrivial amounts of time,
it can make sense to build an action list only once and then perform it
multiple times.

Actions must not be added after compiling a list.

=cut

sub compile {
   my ($self) = @_;

   $self->{duration} += delete $self->{tick_duration};

   delete $self->{tick};
   delete $self->{last_kbd};
   delete $self->{last_ptr};

   $self->{actions} ||= [values %{ delete $self->{source} }];

   wantarray
      ? ($self->{actions}, $self->{duration})
      : $self->{actions}
}

=back

=head2 EVENT BASED API

This module wouldn't be a good AnyEvent citizen if it didn't have a true
event-based API.

In fact, the simplified API, as documented above, is emulated via the
event-based API and an C<AUTOLOAD> function that automatically provides
blocking wrappers around the callback-based API.

Every method documented in the L<SIMPLIFIED API> section has an equivalent
event-based method that is formed by appending a underscore (C<_>) to the
method name, and appending a callback to the argument list (mnemonic: the
underscore indicates the "the action is not yet finished" after the call
returns).

For example, instead of a blocking calls to C<new_session>, C<navigate_to>
and C<back>, you can make a callback-based ones:

   my $cv = AE::cv;

   $wd->new_session ({}, sub {
      my ($status, $value) = @_,

      die "error $value->{error}" if $status ne "200";

      $wd->navigate_to_ ("http://www.nethype.de", sub {

         $wd->back_ (sub {
            print "all done\n";
            $cv->send;
         });

      });
   });

   $cv->recv;

While the blocking methods C<croak> on errors, the callback-based ones all
pass two values to the callback, C<$status> and C<$res>, where C<$status>
is the HTTP status code (200 for successful requests, typically 4xx or
5xx for errors), and C<$res> is the value of the C<value> key in the JSON
response object.

Other than that, the underscore variants and the blocking variants are
identical.

=head2 LOW LEVEL API

All the simplified API methods are very thin wrappers around WebDriver
commands of the same name. They are all implemented in terms of the
low-level methods (C<req>, C<get>, C<post> and C<delete>), which exists
in blocking and callback-based variants (C<req_>, C<get_>, C<post_> and
C<delete_>).

Examples are after the function descriptions.

=over

=item $wd->req_ ($method, $uri, $body, $cb->($status, $value))

=item $value = $wd->req ($method, $uri, $body)

Appends the C<$uri> to the C<endpoint/session/{sessionid}/> URL and makes
a HTTP C<$method> request (C<GET>, C<POST> etc.). C<POST> requests can
provide a UTF-8-encoded JSON text as HTTP request body, or the empty
string to indicate no body is used.

For the callback version, the callback gets passed the HTTP status code
(200 for every successful request), and the value of the C<value> key in
the JSON response object as second argument.

=item $wd->get_ ($uri, $cb->($status, $value))

=item $value = $wd->get ($uri)

Simply a call to C<req_> with C<$method> set to C<GET> and an empty body.

=item $wd->post_ ($uri, $data, $cb->($status, $value))

=item $value = $wd->post ($uri, $data)

Simply a call to C<req_> with C<$method> set to C<POST> - if C<$body> is
C<undef>, then an empty object is send, otherwise, C<$data> must be a
valid request object, which gets encoded into JSON for you.

=item $wd->delete_ ($uri, $cb->($status, $value))

=item $value = $wd->delete ($uri)

Simply a call to C<req_> with C<$method> set to C<DELETE> and an empty body.

=cut

=back

Example: implement C<get_all_cookies>, which is a simple C<GET> request
without any parameters:

   $cookies = $wd->get ("cookie");

Example: implement C<execute_script>, which needs some parameters:

   $results = $wd->post ("execute/sync" => { script => "$javascript", args => [] });

Example: call C<find_elements> to find all C<IMG> elements:

   $elems = $wd->post (elements => { using => "css selector", value => "img" });

=cut

=head1 HISTORY

This module was unintentionally created (it started inside some quickly
hacked-together script) simply because I couldn't get the existing
C<Selenium::Remote::Driver> module to work, ever, despite multiple
attempts over the years and trying to report multiple bugs, which have
been completely ignored. It's also not event-based, so, yeah...

=head1 AUTHOR

   Marc Lehmann <schmorp@schmorp.de>
   http://anyevent.schmorp.de

=cut

1

