#!perl
  
use strict;
use warnings FATAL => 'all';
  
use lib qw(lib);
use base q(Apache::TestRunPerl);
use Apache::TestConfig ();

main::->new->run(@ARGV);

sub pre_configure {
      my $self = shift;
      # mod_bt doesn't like to be loaded if it isn't configured.
      Apache::TestConfig::autoconfig_skip_module_add('mod_bt.c')
}

sub configure {
    my $self = shift;
    bless $self->{server}, "Apache2::AUS::TestServer";
    return $self->SUPER::configure(@_);
}

package Apache2::AUS::TestServer;

use base q(Apache::TestServer);
use lib 't/tlib';
use t::dbh;
use DBIx::Migration::Directories;

sub start {
    my $self = shift;
    warn "installing database schema!";
    if(my $dbh = dbh) {
        my $mh = DBIx::Migration::Directories->new(
            schema      =>  "Schema::RDBMS::AUS",
            dbh         =>  $dbh,
        );
        $mh->full_migrate;
        $dbh->disconnect;
    }
    return $self->SUPER::start(@_);
}

sub stop {
    my $self = shift;
    my $rv;
    if($rv = $self->SUPER::stop(@_)) {
        warn "removing database schema!";
        if(my $dbh = dbh) {
            my $mh = DBIx::Migration::Directories->new(
                schema      =>  "Schema::RDBMS::AUS",
                dbh         =>  $dbh,
            );
            $mh->full_delete_schema;
            $dbh->disconnect;
        }
    }
    return $rv;
}
