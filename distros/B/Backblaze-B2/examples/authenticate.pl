#!perl -w
use strict;
use JSON::XS;
use Backblaze::B2;
use Getopt::Long;

GetOptions(
    'c|credentials:s' => \my $credentials_file,
    'o|application-credentials:s' => \my $app_credentials_file,
);

$app_credentials_file ||= './app-credentials.json';

=head1 SYNOPSIS

=head1 SEE ALSO

L<https://www.backblaze.com/b2/docs/b2_authorize_account.html>

=cut

my $b2 = Backblaze::B2->new(
    version => 'v1',
    log_message => sub { warn sprintf "[%d] %s\n", @_; },
);

my $credentials = $b2->read_credentials( $credentials_file );

use Data::Dumper;
my ($app_credentials) = $b2->authorize_account(
    %$credentials
);

open my $fh, '>', $app_credentials_file
    or die "Couldn't write credentials to '$app_credentials_file'";
binmode $fh;
print {$fh} encode_json( $app_credentials );
