#!/usr/bin/perl

use 5.8.0;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => "DBIx::QueryByName",
    ABSTRACT        => 'Execute SQL queries by name',
    VERSION_FROM    => 'lib/DBIx/QueryByName.pm',
    PREREQ_PM       => {
        'XML::Parser' => 2.34,
        'XML::SimpleObject' => 0.53,
        'accessors::chained' => 1.01,
    },
    AUTHOR          => "Joel Jacobson <joel\@gluefinance.com, Erwan Lemonnier <erwan\@gluefinance.com>, Claes Jakobsson <claes\@gluefinance.com>",
    );
