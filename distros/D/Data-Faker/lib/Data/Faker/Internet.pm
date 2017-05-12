package Data::Faker::Internet;
use strict;
use warnings;
use vars qw($VERSION); $VERSION = '0.10';
use base 'Data::Faker';
use Data::Faker::Company;
use Data::Faker::Name;

=head1 NAME

Data::Faker::Internet - Data::Faker plugin

=head1 SYNOPSIS AND USAGE

See L<Data::Faker>

=head1 DATA PROVIDERS

=over 4

=item email

Return a fake email address.

=cut

__PACKAGE__->register_plugin(
	'email' => [qw($username@$domain_name)],
);

=item username

Return a fake username.

=cut

__PACKAGE__->register_plugin(
	'username'				=> sub {
		my $self = shift;
		my $name = lc($self->first_name);
		$name =~ s/\W//g;
		return $name;
	},
);

=item hostname

Return a fake computer hostname.

=cut

__PACKAGE__->register_plugin(
	'hostname' => [qw($domain_word.$domain_name)],
);

=item server_name

Return a fake server name (some service name such as mail, dns, etc, prepended
to a fake domain name.)

=cut

__PACKAGE__->register_plugin(
	'server_name' => [
		'$network_service.$domain_name',
		'$network_service-###.$domain_name',
	],
);

=item network_service

Return a random network service name.  Only fairly common services are included.

=cut

__PACKAGE__->register_plugin(
	network_service => [qw(
		ftp ssh telnet shell smtp mail time ns dns tacacs bootp dhcp www
		kerberos pop pop2 pop3 imap nfs ntp imap imap2 snmp irc imap3 https
		snpp isakmp ipp printer fileserver logs log loghost syslog news
		nntp ldap ldaps socks vpn sql db radius cvs svn xmpp x11 backup
	)],
);

=item domain_name

Return a fake domain_name.

=cut

__PACKAGE__->register_plugin(
	'domain_name'			=> [qw($domain_word.$domain_suffix)],
);

=item domain_word

Return a random word that meets the requirements for being part of a domain
name.

=cut

__PACKAGE__->register_plugin(
	'domain_word'			=> sub {
		my $self = shift;
		my $company = lc($self->company);
		$company =~ s/'//g;
		$company =~ s/\W+/-/g;

		return $company;
	},
);

=item domain_suffix

Return a random domain suffix (.com, .net, .co.uk. etc)

=cut

__PACKAGE__->register_plugin(
	'domain_suffix'		=> [qw(
		ac ac.uk ad ae af ag ai al am an ao aq ar as at au aw az ba bb bd be
		bf bg bh bi bj bm bn bo br bs bt bv bw by bz ca cc cd cf cg ch ci ck
		cl cm cn co co.uk com cr cs cu cv cx cy cz de dj dk dm do dz ec edu ee
		eg eh er es et fi fj fk fm fo fr ga gd ge gf gg gh gi gl gm gn gov gp
		gq gr gs gt gu gw gy hk hm hn hr ht hu id ie il im in int io iq ir is
		it je jm jo jp ke kg kh ki km kn kp kr kw ky kz la lb lc li lk lr ls
		lt lu lv ly ma mc md mg mh mil mk ml mm mn mo mp mq mr ms mt mu mv mw
		mx my mz na nc ne net nf ng ni nl no np nr nt nu nz om org pa pe pf pg
		ph pk pl pm pn pr ps pt pw py qa re ro ru rw sa sb sc sd se sg sh si sj
		sk sl sm sn so sr sv st sy sz tc td tf tg th tj tk tm tn to tp tr tt tv
		tw tz ua ug uk um us uy uz va vc ve vg vi vn vu wf ws ye yt yu za zm zw

		aero biz coop info museum name pro

		al.us ak.us az.us ar.us ca.us co.us ct.us de.us dc.us fl.us ga.us hi.us
		id.us il.us in.us ia.us ks.us ky.us la.us me.us md.us ma.us mi.us mn.us
		ms.us mo.us mt.us ne.us nv.us nh.us nj.us nm.us ny.us nc.us nd.us oh.us
		ok.us or.us pa.us ri.us sc.us sd.us tn.us tx.us ut.us vt.us va.us wa.us
		wv.us wi.us wy.us
	)],
);

=item ip_address

Return a random IP Address.

=cut

__PACKAGE__->register_plugin(
	'ip_address'		=> sub {
		my @n = (1 .. 254);
		return join('.',@n[rand(@n),rand(@n),rand(@n),rand(@n)]);
	},
);

=back

=head1 SEE ALSO

L<Data::Faker>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
