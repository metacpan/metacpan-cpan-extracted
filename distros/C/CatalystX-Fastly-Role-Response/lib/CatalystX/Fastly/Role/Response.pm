package CatalystX::Fastly::Role::Response;
$CatalystX::Fastly::Role::Response::VERSION = '0.07';
use Moose::Role;
use Carp;

use constant CACHE_DURATION_CONVERSION => {
    s => 1,
    m => 60,
    h => 3600,
    d => 86_400,
    M => 2_628_000,
    y => 31_556_952,
};

my $convert_string_to_seconds = sub {
    my $input   = $_[0];
    my $measure = chop($input);

    my $unit = CACHE_DURATION_CONVERSION->{$measure} ||    #
        carp
        "Unknown duration unit: $measure, valid options are Xs, Xm, Xh, Xd, XM or Xy";

    carp "Initial duration start (currently: $input) must be an integer"
        unless $input =~ /^\d+$/;

    return $unit * $input;
};

=head1 NAME

CatalystX::Fastly::Role::Response - Methods for Fastly intergration to Catalyst

=head1 SYNOPTIS

    package MyApp;

    ...

    use Catalyst qw/
        +CatalystX::Fastly::Role::Response
      /;

    extends 'Catalyst';

    ...

    package MyApp::Controller::Root

    sub a_page :Path('some_page') {
        my ( $self, $c ) = @_;

        $c->cdn_max_age('10d');
        $c->browser_max_age('1d');

        $c->add_surrogate_key('FOO','WIBBLE');

        $c->response->body( 'Add cache and surrogate key headers' );
    }

=head1 DESCRIPTION

This role adds methods to set appropreate cache headers in Catalyst responses,
relating to use of a Content Distribution Network (CDN) and/or Cacheing
proxy as well as cache settings for HTTP clients (e.g. web browser). It is
specifically targeted at L<Fastly|https://www.fastly.com> but may also be
useful to others.

Values are converted and headers set in C<finalize_headers>. Headers
affected are:

=over 4

=item -

Cache-Control: HTTP client (e.g. browser) and CDN (if Surrogate-Control not used) cache settings

=item -

Surrogate-Control: CDN only cache settings

=item -

Surrogate-Key: CDN only, can then later be used to purge content

=item -

Pragma: only set for for L<browser_never_cache>

=item -

Expires: only for L<browser_never_cache>

=back

=head1 TIME PERIOD FORMAT

All time periods are expressed as: C<Xs>, C<Xm>, C<Xh>, C<Xd>, C<XM> or C<Xy>,
e.g. seconds, minutes, hours, days, months or years, e.g. C<3h> is three hours.

=head1 CDN METHODS

=head2 cdn_max_age

  $c->cdn_max_age( '1d' );

Used to set B<max-age> in the B<Surrogate-Control> header, which CDN's use
to determine how long to cache for. B<If I<not> supplied the CDN will use the
B<Cache-Control> headers value> (as set by L</browser_max_age>).

=cut

has cdn_max_age => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);

=head2 cdn_stale_while_revalidate

  $c->cdn_stale_while_revalidate('1y');

Applied to B<Surrogate-Control> only when L</cdn_max_age> is set, this
informs the CDN how long to continue serving stale content from cache while
it is revalidating in the background.

=cut

has cdn_stale_while_revalidate => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);

=head2 cdn_stale_if_error

  $c->cdn_stale_if_error('1y');

Applied to B<Surrogate-Control> only when L</cdn_max_age> is set, this
informs the CDN how long to continue serving stale content from cache
if there is an error at the origin.

=cut

has cdn_stale_if_error => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);

=head2 cdn_never_cache

  $c->cdn_never_cache(1);

When true the a B<private> will be added to the B<Cache-Control> header
this forces Fastly to never cache the results, no matter what other
options have been set.

=cut

has cdn_never_cache => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub {0},
);

=head1 BROWSER METHODS

=head2 browser_max_age

  $c->browser_max_age( '1m' );

Used to set B<max-age> in the B<Cache-Control> header, browsers use this to
determine how long to cache for. B<The CDN will also use this if there is
no B<Surrogate-Control> (as set by L</cdn_max_age>)>.

=cut

has browser_max_age => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);

=head2 browser_stale_while_revalidate

  $c->browser_stale_while_revalidate('1y');

Applied to B<Cache-Control> only when L</browser_max_age> is set, this
informs the browser how long to continue serving stale content from cache while
it is revalidating from the CDN.

=cut

has browser_stale_while_revalidate => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);

=head2 browser_stale_if_error

  $c->browser_stale_if_error('1y');

Applied to B<Cache-Control> only when L</browser_max_age> is set, this
informs the browser how long to continue serving stale content from cache
if there is an error at the CDN.

=cut

has browser_stale_if_error => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);

=head2 browser_never_cache

  $c->browser_never_cache(1);

When true the headers below are set, this forces the browser to never cache
the results. B<private> is NOT added as this would also affect the CDN
even if C<cdn_max_age> was set.

  Cache-Control: no-cache, no-store, must-revalidate, max-age=0, max-stale=0, post-check=0, pre-check=0
  Pragma: no-cache
  Expires: 0

N.b. Some versions of IE won't let you download files, such as a PDF if it is
not allowed to cache it, it is recommended to set a L</browser_max_age>('1m')
in this situation.

IE8 have issues with the above and using the back button, and need an additional I<Vary: *> header,
L<as noted by Fastly|https://docs.fastly.com/guides/debugging/temporarily-disabling-caching>,
this is left for you to impliment.

=cut

has browser_never_cache => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub {0},
);

=head1 SURROGATE KEYS

=head2 add_surrogate_key

  $c->add_surrogate_key('FOO','WIBBLE');

This can be called multiple times, the values will be set
as the B<Surrogate-Key> header as I<`FOO WIBBLE`>.

See L<MooseX::Fastly::Role/cdn_purge_now> if you are
interested in purging these keys!

=cut

has _surrogate_keys => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        add_surrogate_key   => 'push',
        has_surrogate_keys  => 'count',
        surrogate_keys      => 'elements',
        join_surrogate_keys => 'join',
    },
);

=head1 INTERNAL METHODS

=head2 finalize_headers

The method that actually sets all the headers, should be called
automatically by Catalyst.

=cut

before 'finalize_headers' => sub {
    my $c = shift;

    if ( $c->browser_never_cache ) {

        $c->res->header( 'Cache-Control' =>
                'no-cache, no-store, must-revalidate, max-age=0, max-stale=0, post-check=0, pre-check=0'
        );
        $c->res->header( 'Pragma'  => 'no-cache' );
        $c->res->header( 'Expires' => '0' );

    } elsif ( my $browser_max_age = $c->browser_max_age ) {

        my @cache_control;

        push @cache_control, sprintf 'max-age=%s',
            $convert_string_to_seconds->($browser_max_age);

        if ( my $duration = $c->browser_stale_while_revalidate ) {
            push @cache_control, sprintf 'stale-while-revalidate=%s',
                $convert_string_to_seconds->($duration);

        }

        if ( my $duration = $c->browser_stale_if_error ) {
            push @cache_control, sprintf 'stale-if-error=%s',
                $convert_string_to_seconds->($duration);

        }

        $c->res->header( 'Cache-Control' => join( ', ', @cache_control ) );

    }

    # Set the caching at CDN, seperate to what the user's browser does
    # https://docs.fastly.com/guides/tutorials/cache-control-tutorial
    if ( $c->cdn_never_cache ) {

        # Make sure fastly doesn't cache this by accident
        # tell them it's private, must be on the Cache-Control header
        my $cc = $c->res->header('Cache-Control') || '';
        if ( $cc !~ /private/ ) {
            $c->res->headers->push_header( 'Cache-Control' => 'private' );
        }

    } elsif ( my $cdn_max_age = $c->cdn_max_age ) {

        my @surrogate_control;

        push @surrogate_control, sprintf 'max-age=%s',
            $convert_string_to_seconds->($cdn_max_age);

        if ( my $duration = $c->cdn_stale_while_revalidate ) {
            push @surrogate_control, sprintf 'stale-while-revalidate=%s',
                $convert_string_to_seconds->($duration);

        }

        if ( my $duration = $c->cdn_stale_if_error ) {
            push @surrogate_control, sprintf 'stale-if-error=%s',
                $convert_string_to_seconds->($duration);

        }

        $c->res->header(
            'Surrogate-Control' => join( ', ', @surrogate_control ) );

    }

    # Surrogate key
    if ( $c->has_surrogate_keys ) {

        # See http://www.fastly.com/blog/surrogate-keys-part-1/
        $c->res->header( 'Surrogate-Key' => $c->join_surrogate_keys(' ') );
    }

};

=head1 SEE ALSO

L<MooseX::Fastly::Role> - provides cdn_purge_now and access to L<Net::Fastly>
L<stale-while-validate|https://www.fastly.com/blog/stale-while-revalidate/>

=head1 AUTHOR

Leo Lapworth <LLAP@cpan.org>

=cut

1;
