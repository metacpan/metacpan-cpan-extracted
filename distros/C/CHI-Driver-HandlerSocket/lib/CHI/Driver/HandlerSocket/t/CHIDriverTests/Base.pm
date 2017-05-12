package CHI::Driver::HandlerSocket::t::CHIDriverTests::Base;
use DBI;
use Module::Load::Conditional qw(can_load);
use Test::More;
use strict;
use warnings;
use base qw(CHI::t::Driver);

sub supports_get_namespaces { 0 }

sub SKIP_CLASS {
    my $class = shift;

    if ( not $class->dbh() ) {
        return "Unable to get a database connection";
    }

    return 0;
}

sub dbh {
    my $self = shift;

    eval {
        return DBI->connect(
            $self->dsn(),
            '', '',
            {
                RaiseError => 0,
                PrintError => 0,
            }
        );
    };
}

sub new_cache_options {
    my $self = shift;

    return (
        $self->SUPER::new_cache_options(),
        dbh          => $self->dbh,
        create_table => 1
    );
}

sub test_with_dbix_connector : Tests(1) {
    return 'DBIx::Connector not installed'
      unless can_load( modules => { 'DBIx::Connector' => undef } );

    my $self  = shift;
    my $conn  = DBIx::Connector->new( $self->dsn() );
    my $cache = CHI->new( driver => 'DBI', dbh => $conn );
    $cache->clear();
    my $t = time;
    $cache->set( 'foo', $t );
    is( $cache->get('foo'), $t );
}

sub test_with_dbi_generator : Tests(1) {
    my $self  = shift;
    my $dbh   = $self->dbh;
    my $cache = CHI->new( driver => 'DBI', dbh => sub { $dbh } );
    $cache->clear();
    my $t = time;
    $cache->set( 'foo', $t );
    is( $cache->get('foo'), $t );
}

1;
