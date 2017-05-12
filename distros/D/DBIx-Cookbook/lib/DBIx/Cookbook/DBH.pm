package DBIx::Cookbook::DBH;

use Moose;
extends 'DBIx::DBH';

has '+username' => ( default => 'shootout' );
has '+password' => ( default => 'shootout1' );

has '+dsn' => (
    default => sub {
        {
            driver   => 'mysql',
            database => 'sakila',
            host     => 'localhost',
            port     =>  3306,
        };
    }
);

has '+attr' => ( default => sub { { RaiseError => 1 } } );

1;

=head1 NAME

DBIx::Cookbook::DBH -- base class holding connection data and dbh() method

=head1 SYNOPSIS

DBIx::Cookbook::DBH is simply a derived class of L<DBIx::DBH>. Instances of 
L<DBIx::Cookbook::DBH> supply database connection info in forms consumable
by DBI(-based ORMs)?, including

=over 4

=item * L<DBI>

=item * L<DBIx::Class>

=item * L<DBIx::Skinny>

=item * L<Rose::DB::Object>

=back

