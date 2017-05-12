package DBIx::ObjectMapper::Query;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use base qw(DBIx::ObjectMapper::Query::Base);
use DBIx::ObjectMapper::Query::Select;
use DBIx::ObjectMapper::Query::Insert;
use DBIx::ObjectMapper::Query::Update;
use DBIx::ObjectMapper::Query::Delete;
use DBIx::ObjectMapper::Query::Count;

sub select { DBIx::ObjectMapper::Query::Select->new( shift->engine, @_ ) }
sub insert { DBIx::ObjectMapper::Query::Insert->new( shift->engine, @_ ) }
sub update { DBIx::ObjectMapper::Query::Update->new( shift->engine, @_ ) }
sub delete { DBIx::ObjectMapper::Query::Delete->new( shift->engine, @_ ) }
sub count  { DBIx::ObjectMapper::Query::Count->new( shift->engine, @_ ) }

1;
