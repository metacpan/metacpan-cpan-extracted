#!/usr/bin/perl

## Author    Olivier Salaün
## Copyright Comité Réseau des Universités
## http://www.cru.fr

## This is a sample CAS client
## You should add 3 ScriptAlias entries for it in your Apache conf file
## ScriptAlias /testproxy /var/www/cgi-bin/AuthCAS/sampleCasClient.pl
## ScriptAlias /testapp /var/www/cgi-bin/AuthCAS/sampleCasClient.pl
##
## This last alias should be set as HTTPS 
## ScriptAlias /testcallback /var/www/cgi-bin/AuthCAS/sampleCasClient.pl


use AuthCAS;

my $proxy_url = 'http://your.server/testproxy';
my $proxy_callback_url = 'https://your.server/testcallback';
my $app_url = 'http://your.server/testapp';
my $cas_url = 'https://your.cas.server';

my $cas = new AuthCAS(casUrl => $cas_url, 
		      CAFile => '/usr/local/apache/conf/ssl.crt/ca-bundle.crt',
		      );

if ($ENV{'SCRIPT_NAME'} eq '/testproxy') {
    $cas->proxyMode(pgtFile => '/tmp/pgt.txt',
		    pgtCallbackUrl => $proxy_callback_url
		    );

    unless ($ENV{'QUERY_STRING'} =~ /ticket=/) {
	## Redirect the User for login at CAS
	## This step is not required if we already have a PGT (Proxy Granting Ticket)
	my $login_url = $cas->getServerLoginURL($proxy_url);
	
	printf "Location: $login_url\n\n";
	exit 0;
    }
    
    my $ST;
    
    $ENV{'QUERY_STRING'} =~ /ticket=([^&]+)/;
    $ST = $1;

    my $user = $cas->validateST($proxy_url, $ST);

    unless (defined $user) {
	&error(&AuthCAS::get_errors);
	exit 1;
    }

    my $PT = $cas->retrievePT($app_url);
    
    my ($user2, @proxies) = $cas->validatePT($app_url, $PT);

    printf "Content-type: text/plain\n\nST: $ST\nUser: $user\nPT: $PT\nUser2 : $user2\nProxies : %s", join(',',@proxies);

    exit 0;
}elsif ($ENV{'SCRIPT_NAME'} eq '/testapp') {
    unless ($ENV{'QUERY_STRING'} =~ /ticket=/) {
	## Redirect the User for login at CAS
	## This step is not required if we already have a PGT (Proxy Granting Ticket)
	my $login_url = $cas->getServerLoginURL($app_url);
	
	printf "Location: $login_url\n\n";
	exit 0;
    }
    
    my $ST;
    
    $ENV{'QUERY_STRING'} =~ /ticket=([^&]+)/;
    $ST = $1;
    
    my $user = $cas->validateST($app_url, $ST);

    printf "Content-type: text/plain\n\nST: $ST\nUser: $user\n";

    exit 0;
}elsif ($ENV{'SCRIPT_NAME'} eq '/testcallback') {
    $cas->proxyMode(pgtFile => '/tmp/pgt.txt',
		    pgtCallbackUrl => $proxy_callback_url
		    );

    $ENV{'QUERY_STRING'} =~ /^pgtIou=(\S+)&pgtId=(\S+)$/;
    $cas->storePGT($1,$2);
    print "Content-type: text/plain\n\n";
    dump_env(\*STDOUT);
    exit 0;
}else {
    print "Content-type: text/plain\n\n";
    &dump_env(\*STDOUT);
}


sub dump_env {
    my $fd = shift;

    foreach my $k (keys %ENV) {
	printf $fd "$k = $ENV{$k}\n";
    }
}

sub error {
    
    print "Content-type: text/plain\n\n";
    printf "Erreur : %s\n", join('',@_);
    
    return 1;
}

