#!/usr/bin/perl

use strict;
use warnings;

use DNS::PunyDNS;
use Data::Dumper;



my $dns = DNS::PunyDNS->new({'username' => '<sapo_user>', 'password' => '<sapo_pass>'});




########### ADD DNS
=head

	my $added = $dns->add_dns('pesquisa.sl.pt', '10.135.3.179','A');
	if (!$added) { 
		print "ERROR: " .$dns->{'error'}  ."\n";
	} else {
		print "dns added\n";
	}
=cut


############ REMOVE DNS
=head
	my $removed = $dns->remove_dns('bruno1234.sl.pt');
	if (!$removed) {
		print "ERROR: " . $dns->{'error'};
	} else {
		print "dns removed\n";
	}
=cut


########### LIST DNS 
=head
	my $info = $dns->list_dns();

	print Dumper $info;
=cut

########### LIST DNS INFO
=head
	my $info = $dns->list_dns_info();

	print Dumper $info;
=cut

########### GET  DNS  INFO
=head
	my $info = $dns->get_dns_info('pesquisa.sl.pt');

	if (!$info) {
		print "ERROR: " . $dns->{'error'} ."\n";
	} else {
		print Dumper $info;
	}
=cut



########### UPDATE  DNS IP 
=head
	my $updated = $dns->update_dns('pesquisa.sl.pt','10.134.4.100','A', 'AAAA');
	if (!$updated) {
		print "ERROR: " . $dns->{'error'};
	} else {
		print "dns updated\n";
	}
=cut

########### UPDATE  DNS IP AND RECORD TYPE 
=head
	my $updated = $dns->update_dns('pesquisa.sl.pt','10.134.4.100','A', 'AAAA');
	if (!$updated) {
		print "ERROR: " . $dns->{'error'};
	} else {
		print "dns updated\n";
	}
=cut




