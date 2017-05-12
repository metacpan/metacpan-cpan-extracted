package CatalystX::OAuth2::Provider::Error;

use strict;
use warnings;

use overload
    q{""}    => sub { sprintf q{%s: %s}, $_[0]->type, $_[0]->description },
    fallback => 1;

sub new {
    my ($class, %args) = @_;
    bless {
        description => $args{description} || '',
        state       => $args{state}       || '',
        code        => $args{code}        || 400,
    }, $class;
}

sub throw {
    my ($class, %args) = @_;
    die $class->new(%args);
}

sub code        { $_[0]->{code}         }
sub type        { die "abstract method" }
sub description { $_[0]->{description}  }
sub state       { $_[0]->{state}        }

# OAuth Server Error
package CatalystX::OAuth2::Provider::Error::InvalidRequest;
our @ISA = qw(CatalystX::OAuth2::Provider::Error);
sub type { "invalid_request" }

package CatalystX::OAuth2::Provider::Error::InvalidClient;
our @ISA = qw(CatalystX::OAuth2::Provider::Error);
sub code { 401 }
sub type { "invalid_client" }

package CatalystX::OAuth2::Provider::Error::UnauthorizedClient;
our @ISA = qw(CatalystX::OAuth2::Provider::Error);
sub code { 401 }
sub type { "unauthorized_client" }

package CatalystX::OAuth2::Provider::Error::RedirectURIMismatch;
our @ISA = qw(CatalystX::OAuth2::Provider::Error);
sub code { 401 }
sub type { "redirect_uri_mismatch" }

package CatalystX::OAuth2::Provider::Error::AccessDenied;
our @ISA = qw(CatalystX::OAuth2::Provider::Error);
sub code { 401 }
sub type { "access_denied" }

package CatalystX::OAuth2::Provider::Error::UnsupportedResourceType;
our @ISA = qw(CatalystX::OAuth2::Provider::Error);
sub type { "unsupported_resource_type" }

package CatalystX::OAuth2::Provider::Error::InvalidGrant;
our @ISA = qw(CatalystX::OAuth2::Provider::Error);
sub code { 401 }
sub type { "invalid_grant" }

package CatalystX::OAuth2::Provider::Error::UnsupportedGrantType;
our @ISA = qw(CatalystX::OAuth2::Provider::Error);
sub type { "unsupported_grant_type" }

package CatalystX::OAuth2::Provider::Error::InvalidScope;
our @ISA = qw(CatalystX::OAuth2::Provider::Error);
sub code { 401 }
sub type { "invalid_scope" }

package CatalystX::OAuth2::Provider::Error::InvalidToken;
our @ISA = qw(CatalystX::OAuth2::Provider::Error);
sub code { 401 }
sub type { "invalid_token" }

package CatalystX::OAuth2::Provider::Error::ExpiredToken;
our @ISA = qw(CatalystX::OAuth2::Provider::Error);
sub code { 401 }
sub type { "expired_token" }

package CatalystX::OAuth2::Provider::Error::InsufficientScope;
our @ISA = qw(CatalystX::OAuth2::Provider::Error);
sub code { 401 }
sub type { "insufficient_scope" }

package CatalystX::OAuth2::Provider::Error;

=head1 AUTHOR
=head1 COPYRIGHT AND LICENSE
  This package is stolen from OAuth::Lite2::Server::Error
=cut

1;
