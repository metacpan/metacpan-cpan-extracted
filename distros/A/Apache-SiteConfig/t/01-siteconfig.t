#!/usr/bin/env perl
use feature ':5.10';
use Test::More;
use lib 'lib';

BEGIN {
    use_ok('Apache::SiteConfig');
    use_ok('Apache::SiteConfig::Root');
    use_ok('Apache::SiteConfig::Deploy');
    use_ok('Apache::SiteConfig::Template');
    use_ok('Apache::SiteConfig::Statement');
    use_ok('Apache::SiteConfig::Directive');
    use_ok('Apache::SiteConfig::Section');

}

use Apache::SiteConfig;

my $sect = Apache::SiteConfig::Section->new( name => 'VirtualHost' , value => '*:80' );
ok( $sect );
is( $sect->name , 'VirtualHost' );
is( $sect->value , '*:80' );

$sect->add_directive( 'ServerName' , ['localhost'] );

is( $sect->to_string , <<'END' );
<VirtualHost *:80>
    ServerName localhost
</VirtualHost>
END

my $sub_sect = $sect->add_section( 'Location' , '/' );
ok( $sub_sect );

is( $sect->to_string , <<'END' );
<VirtualHost *:80>
    ServerName localhost
    <Location />
    </Location>

</VirtualHost>
END


my $dt = Apache::SiteConfig::Directive->new( name => 'ServerName' , values => [ 'localhost' ] );
is( $dt->name , 'ServerName' );
is_deeply( $dt->values, ['localhost'] );
is( $dt->to_string , 'ServerName localhost' );

done_testing;
