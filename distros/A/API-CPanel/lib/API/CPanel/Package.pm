package API::CPanel::Package;

use strict;
use warnings;

use API::CPanel;
use Data::Dumper;

our $VERSION = 0.07;

# Добавить пакет
# name* (string)	-- Name of package.
# featurelist (string)	-- Name of the feature list to be used when creating a new package.
# quota (integer)	-- Disk space quota in Megabytes.
# ip (string)		-- Whether or not the domain has a dedicated IP address.
# cgi (boolean)		-- Whether or not the domain has CGI access.
# frontpage (boolean)	-- Whether or not the domain has FrontPage extensions installed.
# cpmod (string)	-- cPanel theme name.
# language (string)	-- Language to use in the account's cPanel interface.
# maxftp (string)	-- Maximum number of FTP accounts the user can create.
# maxsql (string)	-- Maximum number of SQL databases the user can create.
# maxpop (string)	-- Maximum number of email accounts the user can create.
# maxlst (string)	-- Maximum number of mailing lists the user can create.
# maxsub (string)	-- Maximum number of subdomains the user can create.
# maxpark (string)	-- Maximum number of parked domains the user can create.
# maxaddon (string)	-- Maximum number of addon domains the user can create.
# hasshell (boolean)	-- Whether or not the domain has shell/SSH access.
# bwlimit (string)	-- Bandiwdth limit in Megabytes.

# According to http://docs.cpanel.net/twiki/bin/view/AllDocumentation/AutomationIntegration/AddPackage
sub add {
    my $params = shift;

    return API::CPanel::action_abstract(
	params         => $params,
	func           => 'addpkg',
	container      => 'result',
	allowed_fields =>
	   'name
	    featurelist
	    quota
	    ip
	    cgi
	    frontpage
	    cpmod
	    language
	    maxftp
	    maxsql
	    maxpop
	    maxlst
	    maxsub
	    maxpark
	    maxaddon
	    hasshell
	    bwlimit',
    );
}

# Редактировать пакет
# name* (string)	-- Name of package.
# featurelist (string)	-- Name of the feature list to be used when creating a new package.
# quota (integer)	-- Disk space quota in Megabytes.
# ip (string)		-- Whether or not the domain has a dedicated IP address.
# cgi (boolean)		-- Whether or not the domain has CGI access.
# frontpage (boolean)	-- Whether or not the domain has FrontPage extensions installed.
# cpmod (string)	-- cPanel theme name.
# language (string)	-- Language to use in the account's cPanel interface.
# maxftp (string)	-- Maximum number of FTP accounts the user can create.
# maxsql (string)	-- Maximum number of SQL databases the user can create.
# maxpop (string)	-- Maximum number of email accounts the user can create.
# maxlst (string)	-- Maximum number of mailing lists the user can create.
# maxsub (string)	-- Maximum number of subdomains the user can create.
# maxpark (string)	-- Maximum number of parked domains the user can create.
# maxaddon (string)	-- Maximum number of addon domains the user can create.
# hasshell (boolean)	-- Whether or not the domain has shell/SSH access.
# bwlimit (string)	-- Bandiwdth limit in Megabytes.

# According to http://docs.cpanel.net/twiki/bin/view/AllDocumentation/AutomationIntegration/EditPackage
sub edit {
    my $params = shift;

    return API::CPanel::action_abstract(
	params         => $params,
	func           => 'editpkg',
	container      => 'result',
	allowed_fields =>
	   'name
	    featurelist
	    quota
	    ip
	    cgi
	    frontpage
	    cpmod
	    language
	    maxftp
	    maxsql
	    maxpop
	    maxlst
	    maxsub
	    maxpark
	    maxaddon
	    hasshell
	    bwlimit',
    );
}

# Удалить пакет
# pkg* (string)	-- Name of package.
# According to http://docs.cpanel.net/twiki/bin/view/AllDocumentation/AutomationIntegration/DeletePackage
sub remove {
    my $params = shift;

    return API::CPanel::action_abstract(
	params         => $params,
	func           => 'killpkg',
	container      => 'result',
	allowed_fields => 'pkg',
    );
}

# 
sub list {
    my $params = shift;

    return API::CPanel::action_abstract(
	params    => $params,
	func      => 'listpkgs',
	container => 'package',
	want_hash => 1,
    );
}

1;
