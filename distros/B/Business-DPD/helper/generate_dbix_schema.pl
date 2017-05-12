#!/opt/perl5.10/bin/perl

use strict;
use warnings;
use 5.010;

use DBIx::Class::Schema::Loader qw/ make_schema_at /;
use Business::DPD::DBIC;

eval { Business::DPD::DBIC->generate_sqlite };
my $dbfile = Business::DPD::DBIC->path_to_sqlite;

make_schema_at(
    'Business::DPD::DBIC::Schema',
    { dump_directory => './lib' },
    ["dbi:SQLite:dbname=$dbfile"],
);

__END__

=head1 NAME


