package API::CPanel::User;

use strict;
use warnings;

use API::CPanel;
use Data::Dumper;

our $VERSION = 0.08;

# ¬озвращает список пользователей
sub list {
    my $params = shift;

    return API::CPanel::fetch_hash_abstract(
	params       => $params,
	func         => 'listaccts',
	container    => 'acct',
	key_field    => 'user',
    );
}

# ¬озвращает список пользователей (возвращает массив, только имена пользователей)
sub list_simple {
    my $params = shift;

    return API::CPanel::fetch_array_abstract(
	params       => $params,
	func         => 'listaccts',
	container    => 'acct',
	result_field => 'user',
    );
}

# ¬озвращает число активных пользователей
sub active_user_count {
    my $params = shift;

    my $result = API::CPanel::fetch_array_abstract(
	params       => $params,
	func         => 'listaccts',
	container    => 'acct',
	result_field => 'suspendtime',
    );

    my $count = 0;
    foreach my $elem ( @$result ) {
	$count++ if ref $elem eq "HASH";
    };
    return $count;
}

# —оздать пользовател€
# username* (string)	-- User name.
# domain* (string)	-- Domain name.
# plan (string)		-- Package to use for account creation.
# pkgname (string)	-- Name of a new package to be created based on the settings used.
# savepkg (bool)	-- Save the settings used as a new package.
# featurelist (string)	-- Name of the feature list to be used when creating a new package.
# quota (integer)	-- Disk space quota in Megabytes.
# password (string)	-- Password for accessing cPanel.
# ip (string)		-- Whether or not the domain has a dedicated IP address.
# cgi (boolean)		-- Whether or not the domain has CGI access.
# frontpage (boolean)	-- Whether or not the domain has FrontPage extensions installed.
# hasshell (boolean)	-- Whether or not the domain has shell/SSH access.
# contactemail (string)	-- Contact email address for the account.
# cpmod (string)	-- cPanel theme name.
# maxftp (string)	-- Maximum number of FTP accounts the user can create.
# maxsql (string)	-- Maximum number of SQL databases the user can create.
# maxpop (string)	-- Maximum number of email accounts the user can create.
# maxlst (string)	-- Maximum number of mailing lists the user can create.
# maxsub (string)	-- Maximum number of subdomains the user can create.
# maxpark (string)	-- Maximum number of parked domains the user can create.
# maxaddon (string)	-- Maximum number of addon domains the user can create.
# bwlimit (string)	-- Bandiwdth limit in Megabytes.
# customip (string)	-- Specific IP address for the site.
# language (string)	-- Language to use in the account's cPanel interface.
# useregns (boolean)	-- Use the registered nameservers for the domain instead of the ones configured on the server.
# hasuseregns (boolean)	-- Set to 1 if you are using the above option.
# reseller (boolean)	-- Give reseller privileges to the account.
# forcedns (boolean)	-- Overwrite current DNS Zone if a DNS Zone already exists.
# mxcheck (enum)	-- Determines how the server will handle incoming mail for this domain. 

# According to http://docs.cpanel.net/twiki/bin/view/AllDocumentation/AutomationIntegration/CreateAccount
sub create {
    my $params = shift;

    return API::CPanel::action_abstract(
	params         => $params,
	func           => 'createacct',
	container      => 'result',
	want_hash      => $params->{want_hash},
	allowed_fields =>
	   'username
	    domain
	    plan
	    pkgname
	    savepkg
	    featurelist
	    quota
	    password
	    ip
	    cgi
	    frontpage
	    hasshell
	    contactemail
	    cpmod
	    maxftp
	    maxsql
	    maxpop
	    maxlst
	    maxsub
	    maxpark
	    maxaddon
	    bwlimit
	    customip
	    language
	    useregns
	    hasuseregns
	    reseller
	    forcedns
	    mxcheck',
    );
}

# Edit user data
# user* (string)	-- User name of the account.
# domain (string)	-- Domain name.
# newuser (string)	-- Used when changing the username of an account. This will be the new username.
# owner (string)	-- Change the owner of the account to the specified owner.
# CPTHEME (string)	-- cPanel theme name.
# HASCGI (boolean)	-- Whether or not the domain has CGI access.
# LANG (string)		-- Language to use in the account's cPanel interface.
# LOCALE (string)	-- Locale to use in the account's cPanel interface.
# maxftp (string)	-- Maximum number of FTP accounts the user can create.
# maxsql (string)	-- Maximum number of SQL databases the user can create.
# maxpop (string)	-- Maximum number of email accounts the user can create.
# maxlst (string)	-- Maximum number of mailing lists the user can create.
# maxsub (string)	-- Maximum number of subdomains the user can create.
# maxpark (string)	-- Maximum number of parked domains the user can create.
# maxaddon (string)	-- Maximum number of addon domains the user can create.
# shell (boolean)	-- Whether or not the domain has shell/SSH access.

# According to http://docs.cpanel.net/twiki/bin/view/AllDocumentation/AutomationIntegration/ModifyAccount
sub edit {
    my $params = shift;

    return API::CPanel::action_abstract( 
	params         => $params,
	func           => 'modifyacct',
	container      => 'result',
	allowed_fields =>
	   'user
	    domain
	    newuser
	    owner
	    CPTHEME
	    HASCGI
	    LANG
	    LOCALE
	    MAXFTP
	    MAXSQL
	    MAXPOP
	    MAXLST
	    MAXSUB
	    MAXPARK
	    MAXADDON
	    shell',
    );
}

# Delete user from panel
# user* -- user name
sub delete {
    my $params = shift;

    return API::CPanel::action_abstract(
	params         => $params,
	func           => 'removeacct',
	container      => 'result',
	allowed_fields => 'user',
    );
}

# Switch on user account
# user* -- user name
sub enable {
    my $params = shift;

    return API::CPanel::action_abstract(
	params         => $params,
	func           => 'unsuspendacct',
	container      => 'result',
	allowed_fields => 'user',
    );
}

# Switch off user account
# user* -- user name
# reason -- reason of suspend
sub disable {
    my $params = shift;

    return API::CPanel::action_abstract(
	params         => $params,
	func           => 'suspendacct',
	container      => 'result',
	allowed_fields => 'user reason',
    );
}

# This function changes the hosting package associated with a cPanel account.
# user* -- user name
# pkg   -- Name of the package that the account should use.
sub change_package {
    my $params = shift;

    return API::CPanel::action_abstract(
	params         => $params,
	func           => 'changepackage',
	container      => 'result',
	allowed_fields => 'user pkg',
    );
}

# This function changes the password of a domain owner (cPanel) or reseller (WHM) account
# user* -- user name
# pass* -- New password for the user.
sub change_account_password {
    my $params = shift;

    return API::CPanel::action_abstract(
	params         => $params,
	func           => 'passwd',
	container      => 'passwd',
	allowed_fields => 'user pass',
    );
}


1;
