package Apache2::Controller::Const;

=head1 NAME

Apache2::Controller::Const - constants for Apache2::Controller

=head1 VERSION

Version 1.001.001

=cut

use version;
our $VERSION = version->new('1.001.001');

=head1 SYNOPSIS

 use Apache2::Controller::Const 
    '@RANDCHARS',
    qw( $NOT_GOOD_CHARS $ACCESS_LOG_REASON_LENGTH );

=head1 DESCRIPTION

Various common Readonly constants for use by Apache2::Controller modules.

=head1 CONSTANTS

=cut

use strict;
use warnings FATAL => 'all';
use Readonly;

use Log::Log4perl qw( :levels );
use Apache2::Const -compile => qw( :log );

use base 'Exporter';

our @EXPORT_OK = qw(
    @RANDCHARS
    $NOT_GOOD_CHARS
    $DEFAULT_CONSUMER_SECRET
    $DEFAULT_SESSION_SECRET
);

=head2 @RANDCHARS

An array of the alphabet plus ascii symbols
from which to pick random characters.

=cut

Readonly::Array our @RANDCHARS => ( 
    'A'..'Z', 'a'..'z', 0..9, '#', '(', ')', ',',
    qw( ! @ $ % ^ & * - _ = + [ ] { } ; : ' " \ | < . > / ? ~ ` )  
);


=head2 $NOT_GOOD_CHARS

A strict qr{} pattern of characters that are not good for basic user input.
Maybe get rid of this one...

=cut

Readonly our $NOT_GOOD_CHARS => qr{ [^\w\#\@\.\-:/, ] }mxs;

=head2 $DEFAULT_CONSUMER_SECRET

Some hardcoded garbage characters used to salt the sha hash of time
for the OpenID consumer secret if one isn't specified or generated.

See L<Apache2::Controller::Auth::OpenID> and
L<Apache2::Controller::Directives/A2C_Auth_OpenID_Consumer_Secret>.

=cut

Readonly our $DEFAULT_CONSUMER_SECRET => q|-qf_AD4#~a{~3)84cCvd+$6R89+,[l|;

=head2 $DEFAULT_SESSION_SECRET

Some hardcoded garbage characters used to salt the sha hash of time
for the session key secret if one isn't specified or generated.

See L<Apache2::Controller::Session::Cookie> and
L<Apache2::Controller::Directives/A2C_Session_Secret>.

=cut

Readonly our $DEFAULT_SESSION_SECRET => q|Je52oN~$VSE.8PNs-e$5tRzB<=l.IC|;

=head1 SEE ALSO

Apache2::Controller

=cut

1;
