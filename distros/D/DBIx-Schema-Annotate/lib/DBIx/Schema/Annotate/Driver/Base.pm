package DBIx::Schema::Annotate::Driver::Base;
use strict;
use warnings;
use Smart::Args;

sub new {
    args(
        my $class => 'ClassName',
        my $dbh,
    );

    bless { dbh => $dbh } => $class;
}




1;

