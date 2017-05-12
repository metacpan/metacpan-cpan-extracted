# $Id: test.pl,v 1.2.2.1 2007/02/01 18:29:21 matisse Exp $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;

use Test::More tests => 1;
use_ok('Apache::AuthCookieDBI');
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

package Apache;
use Carp qw(carp);
sub server {
    return bless {}, 'Mock::Apache::Server';
}

sub log_error {
    my $args = join "\t", @_;
    carp "Apache->log_error called with '$args'", ;
}
package Mock::Apache::Server;

sub dir_config {
    my ($class, $key) = @_;
    my $config = { Mock_DBI_SecretKeyFile => 'MockKeyFile' };
    if ( $key ) {
        return $config->{$key};
    }
    else {
        return $config;
    }
}