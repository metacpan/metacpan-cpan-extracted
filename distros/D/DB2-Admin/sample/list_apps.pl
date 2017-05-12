#!/usr/bin/perl
#
# list_apps - List Applications sample
#
# $Id: list_apps.pl,v 145.1 2007/10/17 14:44:49 biersma Exp $
#

use strict;
use DB2::Admin;
use DB2::Admin::Elements;

$| = 1;

DB2::Admin::->SetOptions('RaiseError' => 1);
DB2::Admin::->Attach();
my $retval = DB2::Admin::->GetSnapshot('Subject' => 'SQLMA_APPLINFO_ALL');
my $app_list = $retval->{'SQLM_ELM_APPL_INFO'};

print <<_END_;
Auth Id  Application    Appl.      Application Id                 DB       # of
         Name           Handle                                    Name    Agents
-------- -------------- ---------- ------------------------------ -------- -----
_END_
  ;

foreach my $entry (@$app_list) {
    printf("%-8s %-14s %-10s %-30s %-8s %-5s\n",
	   map { $entry->{$_}{'Value'} } qw(SQLM_ELM_AUTH_ID
					    SQLM_ELM_APPL_NAME
					    SQLM_ELM_AGENT_ID
					    SQLM_ELM_APPL_ID
					    SQLM_ELM_DB_NAME
					    SQLM_NUM_ASSOC_AGENTS
					   ));
}
			
#print DB2::Admin::Elements::->Format($retval);
DB2::Admin::->Detach();
