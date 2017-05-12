#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;

# This is just to test whether this stuff compiles.
use Alzabo::Config;

use Alzabo::ChangeTracker;

use Alzabo;

use Alzabo::Create;

use Alzabo::Runtime;

use Alzabo::Runtime::UniqueRowCache;

use Alzabo::SQLMaker;
use Alzabo::SQLMaker::MySQL;
use Alzabo::SQLMaker::PostgreSQL;

use Alzabo::Driver;
use Alzabo::RDBMSRules;

if ( eval { require DBD::mysql } && ! $@ )
{
    require Alzabo::Driver::MySQL;
    require Alzabo::RDBMSRules::MySQL;
}

if ( eval { require DBD::Pg } && ! $@ )
{
    require Alzabo::Driver::PostgreSQL;
    require Alzabo::RDBMSRules::PostgreSQL;
}

require Alzabo::MethodMaker;

ok(1);
