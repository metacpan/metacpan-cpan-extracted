use Test::More tests => 4;

BEGIN {
  use_ok( 'Bot::Cobalt::Utils', qw/
    mkpasswd passwdcmp 
  / );
}

my @alph = ( 'a' .. 'z' );
my $passwd = join '', map { $alph[rand @alph] } 1 .. 8;
my $bcrypted = mkpasswd $passwd;
ok( $bcrypted, 'bcrypt-enabled mkpasswd()' );
ok( passwdcmp($passwd, $bcrypted), 'bcrypt-enabled passwd comparison' );
ok( !passwdcmp('a', $bcrypted), 'bcrypt negative comparison' );
