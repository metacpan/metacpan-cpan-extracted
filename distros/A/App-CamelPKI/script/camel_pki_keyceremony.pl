#!/usr/bin/perl -w

use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/../blib/lib";

=head1 NAME

B<camel_pki_keyceremony.pl> - The Camel-PKI Key Ceremony.

=head1 SYNOPSIS

    camel_pki_keyceremony.pl <directory of secrets>

=head1 DESCRIPTION

This script run the Camel-PKI B<Key Ceremony>, and write the associated
secret components (private key and admin credentials) in I<directory
of secrets>.

=cut

use App::CamelPKI;
use App::CamelPKI::Model::CA;
use App::CamelPKI::CA;
use App::CamelPKI::CADB;
use App::CamelPKI::Error;

unless (@ARGV == 1 && -d $ARGV[0]) {
    require Pod::Usage;
    Pod::Usage::pod2usage( { -exitval => 1, -verbose => 1 } );
}


my $camodel = App::CamelPKI->model("CA");
my $webservermodel = App::CamelPKI->model("WebServer");

try {
    $camodel->instance;
    my $dbdir = $camodel->db_dir();
    die <<"MESSAGE";

The CA existing in $dbdir seems to be operationnal, so I won't take
the risk to delete it.

MESSAGE
} catch App::CamelPKI::Error::State with {
    1;
};

$camodel->do_ceremony($ARGV[0], $webservermodel->apache);

warn <<"SUCCESS";

The Key Ceremony was successful. $ARGV[0] contains the secret data (private
key and certificate of the Root CA, admin credentials).

SUCCESS

exit 0;
