#!/usr/bin/env perl

#BEGIN { $ENV{BRACKET_DEBUG} = 0 }
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Bracket::Schema;
use Config::JFDI;
use Term::Prompt;

my ($dsn, $user, $pass);
my $jfdi   = Config::JFDI->new(name => "Bracket");
my $config = $jfdi->get;

eval {
    if (!$dsn)
    {
        if (ref $config->{'Model::DBIC'}->{'connect_info'}) {
            $dsn  = $config->{'Model::DBIC'}->{'connect_info'}->{dsn};
            $user = $config->{'Model::DBIC'}->{'connect_info'}->{user};
            $pass = $config->{'Model::DBIC'}->{'connect_info'}->{password};

        }
        else {
            $dsn = $config->{'Model::DBIC'}->{'connect_info'};
        }
    }
};
if ($@) {
    die "Your DSN line in bracket.conf doesn't look like a valid DSN."
      . "  Add one, or pass it on the command line.";
}
die "No valid Data Source Name (DSN).\n" if !$dsn;
$dsn =~ s/__HOME__/$FindBin::Bin\/\.\./g;

my $schema = Bracket::Schema->connect($dsn, $user, $pass)
  or die "Failed to connect to database";

# Check if database is already deployed by
# examining if the table Person exists and has a record.
eval { $schema->resultset('Bracket::Schema::Result::Player')->count };
if (!$@) {
    die "You have already deployed your database\n";
}

print "\nCreate an admin account..\n\n";
my %custom_values = (
    admin_first_name => prompt('x', 'First name:', '', ''),
    admin_last_name  => prompt('x', 'Last name:',  '', ''),
    admin_email      => prompt('x', 'E-Mail:',     '', ''),
    admin_password   => prompt('x', 'Password:',   '', ''),
);

print "\nDeploying schema to $dsn\n";
$schema->deploy;
print "Creating initial data and admin account.\n";
$schema->create_initial_data($config, \%custom_values);
print "Success!\n\nYou probably want to start your application, e.g:
    script/bracket_server.pl
and login with the admin account you just created.\n\n";
