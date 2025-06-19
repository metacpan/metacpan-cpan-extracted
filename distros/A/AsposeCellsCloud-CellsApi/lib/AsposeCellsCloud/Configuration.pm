=begin comment

Copyright (c) 2025 Aspose.Cells Cloud
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=end comment

=cut

package AsposeCellsCloud::Configuration;

use strict;
use warnings;
use utf8;

use Log::Any qw($log);
use Carp;

use constant VERSION => '25.6.1';

=head1 Name

        AsposeCellsCloud::Configuration - holds the configuration for all AsposeCellsCloud Modules

=head1 new(%parameters)

=over 4

=item http_timeout: (optional)

Integer. timeout for HTTP requests in seconds

default: 180

=item http_user_agent: (optional)

String. custom UserAgent header

default: Swagger-CodeGen/22.5/perl

=item api_key: (optional)

Hashref. Keyed on the name of each key (there can be multiple tokens).

    api_key => {
	secretKey => 'aaaabbbbccccdddd',
	anotherKey => '1111222233334444',
    };

=item api_key_prefix: (optional)

Hashref. Keyed on the name of each key (there can be multiple tokens). Note not all api keys require a prefix.

    api_key_prefix => {
        secretKey => 'string',
	anotherKey => 'same or some other string',
    };

=item api_key_in: (optional)

=item username: (optional)

String. The username for basic auth.

=item password: (optional)

String. The password for basic auth.

=item access_token: (optional)

String. The OAuth access token.

=item base_url: (optional)

String. The base URL of the API

default: https://api.aspose.cloud/v3.0

=item client_id: (optional)
String. Application SID.

=item client_secret: (optional)
String. Application Key.

=item api_version:(optional)
String. api version.
default: v3.0

=back

=cut

sub new {
	my ($self, %p) = (shift,@_);

	# class/static variables
	$p{http_timeout} //= 180;
	$p{http_user_agent} //= 'Apose.Cells.Cloud.SDK/25.6.1/perl';

	# authentication setting
	$p{api_key} //= {};
	$p{api_key_prefix} //= {};
	$p{api_key_in} //= {};

	# username and password for HTTP basic authentication
	$p{username} //= '';
	$p{password} //= '';

	# access token for OAuth
	$p{access_token} //= '';

	# base_url
    $p{base_url} //= 'https://api.aspose.cloud';
	$p{api_version} //= 'v4.0';

	return bless \%p => $self;
}


sub get_tokens {
	my $self = shift;

	my $tokens = {};
	$tokens->{username} = $self->{username} if $self->{username};
	$tokens->{password} = $self->{password} if $self->{password};
	#$tokens->{client_id} = $self->{client_id} if $self->{client_id};
	#$tokens->{client_secret} = $self->{client_secret} if $self->{client_secret};
	$tokens->{access_token} = $self->{access_token} if $self->{access_token};

	foreach my $token_name (keys %{ $self->{api_key} }) {
		$tokens->{$token_name}->{token} = $self->{api_key}{$token_name};
		$tokens->{$token_name}->{prefix} = $self->{api_key_prefix}{$token_name};
		$tokens->{$token_name}->{in} = $self->{api_key_in}{$token_name};
	}

	return $tokens;
}

sub clear_tokens {
	my $self = shift;
	my %tokens = %{$self->get_tokens}; # copy

	$self->{username} = '';
	$self->{password} = '';
	$self->{client_id} = '';
	$self->{client_secret} = '';
	$self->{access_token} = '';

	$self->{api_key} = {};
	$self->{api_key_prefix} = {};
	$self->{api_key_in} = {};

	return \%tokens;
}

sub accept_tokens {
	my ($self, $tokens) = @_;

	foreach my $known_name (qw(username password access_token)) {
		next unless $tokens->{$known_name};
		$self->{$known_name} = delete $tokens->{$known_name};
	}

	foreach my $token_name (keys %$tokens) {
		$self->{api_key}{$token_name} = $tokens->{$token_name}{token};
		if ($tokens->{$token_name}{prefix}) {
			$self->{api_key_prefix}{$token_name} = $tokens->{$token_name}{prefix};
		}
		my $in = $tokens->{$token_name}->{in} || 'head';
		croak "Tokens can only go in 'head' or 'query' (not in '$in')" unless $in =~ /^(?:head|query)$/;
		$self->{api_key_in}{$token_name} = $in;
	}
}	

1;