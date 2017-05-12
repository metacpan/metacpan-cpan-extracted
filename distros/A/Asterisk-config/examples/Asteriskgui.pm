package Dahdi::Config::Gen::Asteriskgui;
use strict;

use Asterisk::config;
use Dahdi::Config::Gen qw(is_true);

sub new($$$) {
	my $pack = shift || die;
	my $gconfig = shift || die;
	my $genopts = shift || die;
	my $users_file = $ENV{USERS_CONF_FILE} || "/etc/asterisk/users.conf";
	my $ext_file = $ENV{EXTENSIONS_FILE} || "/etc/asterisk/extensions.conf";
	my $self = {
			USERS_FILE	=> $users_file,
			EXT_FILE	=> $ext_file,
			GCONFIG		=> $gconfig,
			GENOPTS		=> $genopts,
		};
	$self->{USERS} = new Asterisk::config(file => $self->{USERS_FILE});
	$self->{EXT}   = new Asterisk::config(file => $self->{EXT_FILE});
	bless $self, $pack;
	return $self;
}

# A digital trunk for a single span
sub gen_digital_trunk($$) {
	my $self = shift || die;
	my $span = shift || die;
	my $gconfig = $self->{GCONFIG};
	my $num = $span->num() || die;
	my $bchan_range = Dahdi::Config::Gen::bchan_range($span);
	my $sect_name = "span_dahdi_$num";
	my $context = "DID_$sect_name";
	die "Span #$num is analog" unless $span->is_digital();
	if($span->is_pri && $gconfig->{'pri_connection_type'} eq 'R2') {
		return;
	}
	my $type = $span->type() || die "$0: Span #$num -- unkown type\n";
	my $termtype = $span->termtype() || die "$0: Span #$num -- unkown termtype [NT/TE]\n";
	my $info_str = "Span $num: $type". $span->name(). " -- ", 
		$span->description();
	my $group = $gconfig->{'group'}{"$type"};
	my $switchtype = $span->switchtype;

	die "$0: missing default group (termtype=$termtype)\n" unless defined($group);
	die "$0: missing default context\n" unless $context;

	my $sig = $span->signalling || die "missing signalling info for span #$num type $type";
	grep($gconfig->{'bri_sig_style'} eq $_, 'bri', 'bri_ptmp', 'pri') or die "unknown signalling style for BRI";
	if($span->is_bri() and $gconfig->{'bri_sig_style'} eq 'bri_ptmp') {
		$sig .= '_ptmp';
	}
	my @overlapdial = ();
	if ($span->is_bri() && $termtype eq 'NT' && is_true($gconfig->{'brint_overlap'})) {
		@overlapdial = ("overlapdial = yes");
	}
		
	$group .= "," . (10 + $num);	# Invent unique group per span
	$self->{EXT}->assign_addsection(section=>$sect_name);
	$self->{EXT}->assign_addsection(section=>$sect_name."_default");
	$self->{USERS}->assign_addsection(section=>$sect_name);
	$self->{USERS}->assign_append(section=>$sect_name, point=>'foot',
		data => ";;; $info_str");
	$self->{USERS}->assign_append(section=>$sect_name, point=>'foot',
		data=> [
			"group = $group",
			"hasexten = no",
			"signalling = $sig",
			"switchtype = $switchtype",
			"trunkname = Span $num $type",
			"trunkstyle = digital  ; GUI metadata",
			"hassip = no",
			"hasiax = no",
			"context = $context",
			@overlapdial,
			"dahdichan = $bchan_range",
		]
	);
}

# A trunk for all the analog FXO ports
sub gen_analog_trunk {
	my $self = shift || die;
	my @fxo_ports = @_;
	return unless (@fxo_ports); # no ports

	my $ports = join(',', @fxo_ports);
	my $sect_name = 'trunk_analog';
	$self->{EXT}->assign_addsection(section=>$sect_name);
	$self->{USERS}->assign_addsection(section=>$sect_name);
	$self->{USERS}->assign_append(section=>$sect_name, point=>'foot',
		data => ";;; Trunk for all analog FXO ports ($ports)");
	$self->{USERS}->assign_append(section=>$sect_name, point=>'foot',
		data=> [
			"trunkname = analog",
			"hasexten = no",
			"hasiax = no",
			"hassip = no",
			"hasregisteriax = no",
			"hasregistersip = no",
			"trunkstyle = analog",
			"dahdichan = $ports",
		]
	);
}

# A user for a single FXS port
sub gen_channel($$) {
	my $self = shift || die;
	my $chan = shift || die;
	my $gconfig = $self->{GCONFIG};
	my $type = $chan->type;
	my $num = $chan->num;
	my $full_name = "$type $num";
	my $sect_name = "chan_dahdi_$num";
	die "channel $num type $type is not an analog channel\n" if $chan->span->is_digital();
	my $exten = $self->{EXTEN}++;
	my $sig = $gconfig->{'chan_dahdi_signalling'}{$type};
	my $context = $gconfig->{'context'}{$type};
	my $group = $gconfig->{'group'}{$type};
	my @immediate;

	return if $type eq 'EMPTY';
	if(($type eq 'IN') || ($gconfig->{'fxs_immediate'} eq 'yes')) {
		@immediate = ("immediate = yes");
	}
	my $signalling = $chan->signalling;
	$signalling = " " . $signalling if $signalling;
	my $info = $chan->info;
	$info = " " . $info if $info;
	my $info_str = sprintf "line=\"%d %s%s%s\"", $num, $chan->fqn, 
			$signalling, $info;
	$self->{USERS}->assign_addsection(section=>$sect_name);
	$self->{USERS}->assign_append(section=>$sect_name, point=>'foot',
		data => ";;; $info_str");
	$self->{USERS}->assign_append(section=>$sect_name, point=>'foot',
		data=> [
			"context = DLPN_DialPlan1",
			"callwaiting = yes",
			"fullname = $full_name",
			"cid_number = $exten",
			"hasagent = no",
			"hasiax = no",
			"hasmanager = no",
			"hassip = no",
			"registeriax = no",
			"registersip = no",
			"hasvoicemail = yes",
			"mailbox = $exten",
			"threewaycalling = yes",
			"vmsecret = $exten",
			"signalling = auto",
			@immediate,
			"dahdichan = $num",
		],
	);
}

# Add instructions to remove existing relevant sections.
# Note that this function only adds the instructions to the commit_list.
# Requests will only actually be performed on on the save_file()-s in
# the end. Thus even after this function, the sections we "remove" still
# exist in fetch requests.
sub remove_old_sections($) {
	my $self = shift || die;
	my @user_del_sect = grep /^((chan|span_dahdi_)|trunk_analog$)/, 
		@{$self->{USERS}->fetch_sections_list()};
	foreach (@user_del_sect) {
		$self->{USERS}->assign_delsection(section=>$_);
	}

	my @ext_del_sect = grep /^DID_(span_dahdi_|trunk_analog)/, 
		@{$self->{EXT}->fetch_sections_list()};
	foreach (@ext_del_sect) {
		$self->{EXT}->assign_delsection(section=>$_);
	}
}

sub generate($) {
	my $self = shift || die;
	my @spans = @_;
	my $gconfig = $self->{GCONFIG};
	my $genopts = $self->{GENOPTS};
	$self->{EXTEN} = $self->{GCONFIG}->{'base_exten'};
	#$gconfig->dump;

	my @fxo_ports = ();
	warn "Empty configuration -- no spans\n" unless @spans;
	$self->remove_old_sections();
	foreach my $span (@spans) {
		#printf "; Span %d: %s %s\n", $span->num, $span->name, $span->description;
		if ($span->type =~ /^(BRI|E1|T1)_(NT|TE)$/) {
			$self->gen_digital_trunk($span);
			next;
		}
		foreach my $chan ($span->chans()) {
			if (grep { $_ eq $chan->type} ( 'FXS', 'IN', 'OUT' )) {
				$self->gen_channel($chan);
			} elsif ($chan->type eq 'FXO') {
				# TODO: "$first_chan-$last_chan"
				push @fxo_ports,($chan->num);
			} else {
				print "chan ", $chan->num, ", type: ", $chan->type, ".\n"
			}
		}
	}
	$self->gen_analog_trunk(@fxo_ports);
	$self->{USERS}->save_file();
	$self->{EXT}->save_file();
}

1;

__END__

=head1 NAME

asteriskgui - Generate configuration for the asterisk-gui

=head1 SYNOPSIS

 use Dahdi::Config::Gen::Chandahdi;

 my $cfg = new Dahdi::Config::Gen::Asteriskgui(\%global_config, \%genopts);
 $cfg->generate(@span_list);

=head1 DESCRIPTION

This module updates F</etc/asterisk/users.conf> and 
F</etc/asterisk/extensions.conf> according to the specifications in
L<http://svn.digium.com/svn/asterisk-gui/branches/2.0/developer_info/CONFIG-ASSUMPTIONS>

For each analog B<FXS> channel number I<N>, a section C<chan_dahdi>I<N>
will be generated in F<users.conf>.

All the B<FXO> channels will be in a single section, C<span_analog>.

For each digital span number I<N>, the section C<span_dahdi>I<N> will
be created in F<users.conf>.

=head1 ENVIRONMENT

=over 4

=item USERS_CONF_FILE

The users.conf file to use instead of F</etc/asterisk/users.conf>.

=item EXTENSIONS_FILE

The extensions.conf file to use instead of F</etc/asterisk/extensions.conf>.

=back

