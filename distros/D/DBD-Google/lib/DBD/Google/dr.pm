package DBD::Google::dr;

# ----------------------------------------------------------------------
# This is the driver implementation.
# DBI->connect defers to this class.
# ----------------------------------------------------------------------

use strict;
use base qw(DBD::_::dr);
use vars qw($VERSION $imp_data_size);

use Carp qw(carp croak);
use DBI;
use Net::Google;
use Symbol qw(gensym);

$VERSION = "2.00";
$imp_data_size = 0;

# These are valid Net::Google::Search options
my @valid_google_opts = qw(key lr ie oe safe filter http_proxy debug);

# ----------------------------------------------------------------------
# connect($dsn, $user, $pass, \%attrs);
# 
# Method called when an external process does:
# 
#   my %opts = ("filter" => 0, "debug" => 1);
#   my $dbh = DBI->connect("dbi:Google:", $KEY, undef, \%opts);
#
# Username must be the google API key, password is ignored and can be
# anything, and valid options in the %attr hash are passed to Net::Google.
# ----------------------------------------------------------------------
sub connect {
    my ($drh, $dbname, $user, $pass, $attr) = @_;
    my ($dbh, $google, %google_opts, @create_opts);

    # Issue a warning, rather than croak, because the user can
    # specify a key in %attr
    # carp "No Google API key specified\n" unless defined $user;
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
    # to $google->search.
    for my $google_opt (@valid_google_opts) {
        if (defined $attr->{ $google_opt }) {
            $google_opts{ $google_opt } =
                delete $attr->{ $google_opt };
        }
    }

    # Create a list of name => value pairs to pass to Net::Google
    # constructor.
    push @create_opts, "key" => $user || $google_opts{'key'} || '';

    push @create_opts, 'debug' => $google_opts{'debug'}
        if defined $google_opts{'debug'};

    push @create_opts, 'http_proxy' => $google_opts{'http_proxy'}
        if defined $google_opts{'http_proxy'};

    # Create a Net::Google instance, and store it.  We can reuse
    # this for multiple queries.
    $google = Net::Google->new(@create_opts);

    $dbh->STORE('driver_google' => $google);
    $dbh->STORE('driver_google_opts' => \%google_opts);

    return $dbh;
}

sub disconnect_all { 1 }

sub data_sources { return "Google" }

1;

__END__
