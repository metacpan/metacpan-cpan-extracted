#!/usr/bin/perl -w
$| = 1;
use strict;
use Test::More tests => 13;
use lib qw' ./ ./t ';
use SQLtest;

my $table = SQL::Eval::Table->new(
    {
        col_names => [qw(c1 c2 c3)],
        col_nums  => {
                      c1 => 0,
                      c2 => 1,
                      c3 => 2
                    },
        row => [ 1, 2, 3 ],
    }
);

ok( 3 == scalar @{ $table->row() }, 'eval row()' );
ok( 2 == $table->column('c2'),      'eval column()' );

my $eval = SQL::Eval->new( {} );
ok( $eval->params( [ 1, 2, 3 ] ), 'eval params($val)' );
ok( 3 == scalar @{ $eval->params() }, 'eval params()' );

$eval->{tables}->{a} = $table;
ok( 3 == $eval->column( 'a', 'c3' ), 'eval column($tbl,$col)' );

my $ram = SQL::Statement::RAM::Table->new( 'dummy', [], [ [] ] );
ok( !eval_seek( $ram, 0, -100 ), 'ram seek(bad whence)' );
$ram->{index} = -100;
ok( !eval_seek( $ram, 0, 1 ), 'ram seek(bad index)' );
ok( eval_seek( $ram, 0, 2 ), 'ram seek(pos=2)' );

my $func = SQL::Statement::Util::Function->new( 'a', 'b', 'c' );
ok( 'function' eq $func->type, '$function->type' );
ok( 'a'        eq $func->name, '$function->name' );
my $col = SQL::Statement::Util::Column->new( 'a', 'b', 'c' );
ok( 'column' eq $col->type, '$column->type' );

eval { $func->validate() };
ok( $@, 'function validate - no sub' );
$func = SQL::Statement::Util::Function->new( 'ok', 'Test::More::ok' );
ok( $func->validate(), 'function validate' );

sub eval_seek
{
    my ( $ram, $pos, $whence ) = @_;
    eval { $ram->seek( undef, $pos, $whence ) };
    #    diag $@ if $@;
    return ($@) ? 0 : 1;
}
