package DBD::Salesforce::dr;

# ----------------------------------------------------------------------
# $Id: dr.pm,v 1.1.1.1 2006/02/14 16:54:03 shimizu Exp $
# ----------------------------------------------------------------------
# This is the driver implementation.
# DBI->connect defers to this class.
# ----------------------------------------------------------------------

use strict;
use base qw(DBD::_::dr);
use vars qw($VERSION $imp_data_size);

use Carp qw(carp croak);
use DBI;
use Salesforce;
use Symbol qw(gensym);

$VERSION = "0.01";
$imp_data_size = 0;

# These are valid Salesforce::query options
my @valid_salesforce_opts = qw(key lr ie oe safe filter http_proxy debug);

# ----------------------------------------------------------------------
# connect($dsn, $user, $pass, \%attrs);
# 
# Method called when an external process does:
# 
#   my %opts = ("filter" => 0, "debug" => 1);
#   my $dbh = DBI->connect("dbi:Salesforce:", $KEY, undef, \%opts);
#
# Username must be the salesforce API key, password is ignored and can be
# anything, and valid options in the %attr hash are passed to Salesforce.
# ----------------------------------------------------------------------
sub connect {
    my ($drh, $dbname, $user, $pass, $attr) = @_;
    my ($dbh, $salesforce, %salesforce_opts, @create_opts);

    # Issue a warning, rather than croak, because the user can
    # specify a key in %attr
    # carp "No Salesforce API key specified\n" unless defined $user;
    $user ||= $attr->{'key'} || '';
    $pass ||= '';

    # If the user sends a keyfile as $user, open it and treat
    # the first line as the key
    if (-e $user) {
        my $fh = gensym;
        open $fh, $user or die "Can't open $user for reading: $!";
        chomp($user = <$fh>);
        close $fh or die "Can't close $user: $!";
    }

    $dbh = DBI::_new_dbh($drh, {
        'Name'          => $dbname,
        'USER'          => $user,
        'CURRENT_USER'  => $user,
        'Password'      => $pass,
    });

    # Get options from %attr.  These will be passed 
    # to $salesforce->search.
    for my $salesforce_opt (@valid_salesforce_opts) {
        if (defined $attr->{ $salesforce_opt }) {
            $salesforce_opts{ $salesforce_opt } =
                delete $attr->{ $salesforce_opt };
        }
    }

    # Create a list of name => value pairs to pass to Salesforce
    # constructor.
    push @create_opts, "key" => $user || $salesforce_opts{'key'} || '';

    push @create_opts, 'debug' => $salesforce_opts{'debug'}
        if defined $salesforce_opts{'debug'};

    push @create_opts, 'http_proxy' => $salesforce_opts{'http_proxy'}
        if defined $salesforce_opts{'http_proxy'};

    # Create a Salesforce instance, and store it.  We can reuse
    # this for multiple queries.
    $salesforce = new Salesforce::SforceService()->get_port_binding('Soap');
    $salesforce->login('username' => $user, 'password' => $pass);

    $dbh->STORE('driver_salesforce' => $salesforce);
    $dbh->STORE('driver_salesforce_opts' => \%salesforce_opts);

    return $dbh;
}

sub disconnect_all { 1 }

sub data_sources { return "Salesforce" }

1;

__END__
