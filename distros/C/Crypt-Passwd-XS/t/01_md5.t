use strict;
use warnings;

use Test::More 'tests' => 7;
use Crypt::Passwd::XS ();

my $checks = [
    [ 'test1234', 'test1234',                           '$1$test1234$0BvsB10tWW2oD4p7fanjN.' ],
    [ 'test1234', '$1$test1234$0BvsB10tWW2oD4p7fanjN.', '$1$test1234$0BvsB10tWW2oD4p7fanjN.' ],
    [ 'test1234', '',                                   '$1$$a/H3O7Gxc.2w21w4XZrCJ0' ],
    [ '',         '',                                   '$1$$qRPK7m23GJusamGpoGLby/' ],
    [ '',         'test1234',                           '$1$test1234$SfXsccdkbnafvYcgc7xbd0' ],
    [ 'test1234', undef,                                '$1$$a/H3O7Gxc.2w21w4XZrCJ0' ],
    [ undef,      'test1234',                           '$1$test1234$SfXsccdkbnafvYcgc7xbd0' ],
];

foreach my $check_ref (@$checks) {
    my $pass    = $check_ref->[0];
    my $salt    = $check_ref->[1];
    my $crypted = $check_ref->[2];
    my $result  = Crypt::Passwd::XS::unix_md5_crypt( $pass, $salt );
    is( $result, $crypted, q{Hashed with pass:} . ( defined $pass ? qq{"$pass"} : q{(undef)} ) . q{ salt:} . ( defined $salt ? qq{"$salt"} : q{(undef)} ) );
}

