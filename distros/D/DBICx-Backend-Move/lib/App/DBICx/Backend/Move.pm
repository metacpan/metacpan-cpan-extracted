package App::DBICx::Backend::Move;

# ABSTRACT: Run a database migration with DBICx::Backend::Move


use 5.010;
use strict;
use warnings;
use base qw(App::Cmd::Simple);
use DBI;
use Module::Load 'load';

my $user = getlogin || getpwuid($<) || "unknown";

sub opt_spec {
        return (
                [ "schema|s=s",    "Name of the database schema",  { required => 1 }              ],
                [ "from_dsn|f=s",  "DSN for source database",      { required => 1 }              ],
                [ "to_dsn|t=s",    "DSN for destination database", { required => 1 }              ],
                [ "from_user=s",   "Username for source database; \$USER ($user) by default"      ],
                [ "from_pass=s",   "Password for source database; empty by default"               ],
                [ "to_user=s",     "Username for source database; \$USER ($user) by default"      ],
                [ "to_pass=s",     "Password for source database; empty by default"               ],
                [ "rawmode",       "Transfer raw values, without inflate/deflate"                 ],
                [ "verbose|v+",    "Be more verbose"],
               );
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  # no args allowed but options!
  $self->usage_error("No args allowed") if @$args;
}

sub execute {
        my ($self, $opt, $args) = @_;


        my (undef, $driver ) = DBI->parse_dsn($opt->{to_dsn})    or die "Can't parse DBI DSN '$opt->{from_dsn}'";
        my $module;
        given (lc($driver)) {
                when ('sqlite') { $module='DBICx::Backend::Move::SQLite' };
                when ('pg')     { $module='DBICx::Backend::Move::Psql' };
                default         { die "There is no migrator for driver '$driver'. This was parsed from $opt->{to_dsn}" };
        }

        load $module;
        my $migrator;
        $migrator = $module->new;


        my $connect_from = [ $opt->{from_dsn}, $opt->{from_user} || $user, $opt->{from_pass} || '' ];
        my $connect_to   = [ $opt->{to_dsn},   $opt->{to_user}   || $user, $opt->{to_pass}   || '' ];
        my $retval = $migrator->migrate($connect_from, $connect_to, $opt);
}

1;
