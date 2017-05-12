use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBIx::Class::EncodedColumn::Crypt;

my $gen_salt_meth = sub {
    my @salt_vals = (qw(. /), '0'..'9', 'a'..'z', 'A'..'Z');
    return $salt_vals[int(rand(64))] . $salt_vals[int(rand(64))];
};
my ( $col_name, $col_info ) = ( 'password', { salt => $gen_salt_meth } );
my $passwd = 'mypasswd';
my $cripted_pass = crypt($passwd, $gen_salt_meth->());

throws_ok { DBIx::Class::EncodedColumn::Crypt->make_encode_sub(
    $col_name, { salt => $gen_salt_meth->() }
) } qr{valid.*coderef}i;

my $encoder = DBIx::Class::EncodedColumn::Crypt->make_encode_sub(
    $col_name, $col_info
);

my $checker = DBIx::Class::EncodedColumn::Crypt->make_check_sub(
    $col_name, $col_info
);

package MyEncodedColumn;

sub new { return bless {}, shift }
sub get_column { return $cripted_pass }
sub _column_encoders { return { $col_name => $encoder } }

package main;

isnt($passwd, $encoder->($passwd));
is($cripted_pass, $encoder->($passwd, $cripted_pass));
ok($checker->(MyEncodedColumn->new, $passwd));

done_testing();
