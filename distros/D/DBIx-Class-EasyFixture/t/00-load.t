#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('DBIx::Class::EasyFixture') || print "Bail out!\n";

    my @classes = sort qw(
      DateTime
      DateTime::Format::SQLite
      DBD::SQLite
      DBI
      DBIx::Class
      List::MoreUtils
      Moose
      namespace::autoclean
    );

    foreach my $class (@classes) {
        eval "use $class";
        die $@ if $@;
        diag sprintf "%-35s version %s" => "$class",
          ( $class->VERSION || 'unknown' );
    }
}

Test::More::diag(
    "Testing DBIx::Class::EasyFixture $DBIx::Class::EasyFixture::VERSION, Perl $], $^X"
);
