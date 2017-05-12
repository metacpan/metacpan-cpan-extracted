# $Id: AuthCfg.pm,v 1.2 2003/10/02 06:30:10 cmdrwalrus Exp $

package AuthCfg;

use vars qw/$authcfg/;

# Basic Auth configuration, used by authman.pl and any web-based scripts.
$authcfg = {
	-authdir		=> 'auth',
	-authfields		=> [
		{id => 'user', display => 'User Name', hidden => 0, required => 1},
		{id => 'pw', display => 'Password', hidden => 1, required => 1},
	],
};
