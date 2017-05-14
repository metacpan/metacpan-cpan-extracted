#!/usr/local/bin/perl -w
######################################################################
#
# DNS/Config/File/Nsd.pm
#
# $Id: Nsd.pm,v 1.3 2003/02/16 10:15:32 awolf Exp $
# $Revision: 1.3 $
# $Author: awolf $
# $Date: 2003/02/16 10:15:32 $
#
# Copyright (C)2003 Bruce Campbell. All rights reserved.
# Base Class (Bind9) (C)2001-2003 Andy Wolf. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
######################################################################

package DNS::Config::File::Nsd;

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

use vars qw(@ISA);

use DNS::Config;
use DNS::Config::Server;
use DNS::Config::Statement;

@ISA = qw(DNS::Config::File);

my $VERSION   = '0.66';
my $REVISION  = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

# FILE is the nsd.zones file.
sub new {
	my($pkg, $file, $config) = @_;
	my $class = ref($pkg) || $pkg;

	my $self = {
		'FILE' => $file
	};

	$self->{'CONFIG'} = $config if($config);
	
	bless $self, $class;
	
	return $self;
}

# NSD has an additional config file for nsdc.  Return the filename
# if it has been defined.
sub nsdc {
	my( $self, $file ) = (@_);

	if( defined( $file ) ){
		$self->{'NSDC'} = $file;
	}

	return( $self->{'NSDC'} );
}

# NSD has a directory for TSIG keys.  Return the directory if it
# has been defined.
sub nsdkeysdir {
        my( $self, $dir ) = (@_);

        if( defined( $dir ) ){
                $self->{'NSDKEYSDIR'} = $dir;
        }

        return( $self->{'NSDKEYSDIR'} );
}


sub do_gettsig {
	my $self = shift;
	my $tsigdir = shift;
	my $keyname = shift;

	# This really should be a subroutine in DNS::Config::Statement::Keys.
	my %algs = (
			"157",	"hmac-md5",
			);

	# Get what it is.
	my $t_type = undef;
	my $t_zone = undef;
	my $t_ip = undef;
	if( $keyname =~ /^\s*(zi)\-(\S+)\-([^\-]+)\s*$/i ){
		$t_type = lc( $1 );
		$t_zone = $2;
		$t_ip = $3;
	}elsif( $keyname =~ /^\s*(ip|zo)\-(\S+)\s*$/i ){
		# either zo-$zone or ip-$ip
		$t_type = lc($1);
		$t_zone = $2;
		if( $t_type eq "ip" ){
			$t_ip = $t_zone;
			$t_zone = undef;
		}
	}else{
		$t_type = "unknown";
	}

	# We return a string (or maybe not) that should be inserted into
	# the main stream.  Usually we define a key, or a server statement,
	# but only if we haven't already done so for this key or server.
	my $retmain = undef;
	my $retkey = undef;

	if( ! defined( $self->{'TSIG'} ) ){
		%{$self->{'TSIG'}} = ();
	}

	if( ! defined( ${$self->{'TSIG'}}{$keyname} ) ){
		# We need to read in the file.
		my $t_file = "$tsigdir" . "/" . "$keyname" . ".tsiginfo";
		if( -f "$t_file" ){
			#
			if( open( TSIGINPUT, "$t_file" ) ){
				# Server IP address.
				my $t_addr = <TSIGINPUT>;
				my $t_name = <TSIGINPUT>;
				my $t_alg = <TSIGINPUT>;
				my $t_sec = undef;
				while( my $line = <TSIGINPUT> ){
					chomp( $line );
					$t_sec .= $line;
				}
				close( TSIGINPUT );

				chomp( $t_addr );
				chomp( $t_name );
				chomp( $t_alg );
				chomp( $t_sec );

				# print STDERR "Blot - $t_addr $t_name $t_alg $t_sec\n";

				# Store it here, and elsewhere.
				${$self->{'TSIG'}}{$keyname}{'ip'} = $t_addr;
				${$self->{'TSIG'}}{$keyname}{'name'} = $t_name;
				${$self->{'TSIG'}}{$keyname}{'algorithm-num'} = $t_alg;
				if( defined( $algs{$t_alg} ) ){
					${$self->{'TSIG'}}{$keyname}{'algorithm'} = $algs{$t_alg};
				}else{
					${$self->{'TSIG'}}{$keyname}{'algorithm'} = $t_alg;
				}
				
				${$self->{'TSIG'}}{$keyname}{'secret'} = $t_sec;
				${$self->{'TSIG'}}{$keyname}{'realname'} = "___$t_name";
				
			}
		}
	}

	# See if we've got this one.
	if( defined( ${$self->{'TSIG'}}{$keyname} ) ){
		# We've got it.  Whats the actual keyname?
		my $t_real = ${$self->{'TSIG'}}{$keyname}{'realname'};

		# If its not there, copy it.
		if( ! defined( ${$self->{'TSIG'}}{$t_real} ) ){
			${$self->{'TSIG'}}{$t_real}{'ip'} = ${$self->{'TSIG'}}{$keyname}{'ip'};
			${$self->{'TSIG'}}{$t_real}{'name'} = ${$self->{'TSIG'}}{$keyname}{'name'};
			${$self->{'TSIG'}}{$t_real}{'secret'} = ${$self->{'TSIG'}}{$keyname}{'secret'};
			${$self->{'TSIG'}}{$t_real}{'algorithm'} = ${$self->{'TSIG'}}{$keyname}{'algorithm'};
			${$self->{'TSIG'}}{$t_real}{'algorithm-num'} = ${$self->{'TSIG'}}{$keyname}{'algorithm-num'};
		}

		# Whats the name of this one?
		$retkey = ${$self->{'TSIG'}}{$t_real}{'name'};

		# Do we need to define this one?
		if( ! defined( ${$self->{'TSIG'}}{$t_real}{'done'} ) ){
			# We do need to define it.
			$retmain .= " key " . ${$self->{'TSIG'}}{$t_real}{'name'} . " {";
			$retmain .= " algorithm " . ${$self->{'TSIG'}}{$t_real}{'algorithm'} . ";";
			$retmain .= " secret \"" . ${$self->{'TSIG'}}{$t_real}{'secret'} . "\";";
			$retmain .= " };";

			# Say that we've defined this one.
			${$self->{'TSIG'}}{$t_real}{'done'}++;
		}

		if( $t_type eq "ip" && ! defined( ${$self->{'TSIG'}}{$keyname}{'done'} ) && defined( $t_ip ) ){
			# We now need to use this key with the server.
			$retmain .= " server $t_ip { keys { " . ${$self->{'TSIG'}}{$keyname}{'name'} . "; }; };";
			${$self->{'TSIG'}}{$keyname}{'done'}++;

			# print STDERR "Foo - $retmain\n";
		}
	}


	return( $retmain, $retkey );

}

sub parse {
	my($self, $file) = @_;

	$file = $file || $self->{'FILE'};

	my @lines = $self->read($file);

	my @nsdc = $self->read( $self->nsdc() );

	# This space left blank for any includes.
	
	return undef unless(scalar @lines);

	$self->{'CONFIG'} = new DNS::Config() if(!$self->{'CONFIG'});
	
	my $result;

	my %nsdc_h = (
			"namedxfer",	"CP:named-xfer VAL;",
			"nsdzonesdir",	"CP:directory VAL;",
			"nsdflags",	"SPECIAL",
			"nsdkeysdir",	"SPECIAL",
			);

	$result .= " options {";

	# Loop through the nsdc lines.
	my $nsdkeysdir = undef;

	for my $line (@nsdc) {

		next unless( $line =~ /^\s*(\S+)\s*=\s*\"(.*)\"\s*(\#.*)?$/ );
		my $name = lc( $1 );
		my $fill = $2;

		next unless( defined( $nsdc_h{$name} ) );

		my $tval = $nsdc_h{$name};
		if( $tval =~ /^CP:(\S+.*)\s*$/ ){
			$tval = $1;
			$tval =~ s/VAL/$fill/g;
			$result .= " $tval";
		}elsif( $tval eq 'SPECIAL' && $name eq 'nsdflags' ){
			# Special processing required.
			my @tsplit = split( /\s+/, $fill );
			my $curflag = undef;
			my @addys = ();
			my $port = 53;
			foreach my $kkey( @tsplit ){
				if( $kkey =~ /^\s*\-[ap]\s*$/ ){
					$curflag = $kkey;
				}elsif( defined($curflag) ){
					if( $curflag eq '-a' ){
						push @addys, $kkey;
					}elsif( $curflag eq '-p' ){
						$port = $kkey;
					}
				}
			}


			$result .= " listen-on port $port {";
			foreach my $kkey( @addys ){
				$result .= " $kkey;";
			}

			$result .= " };";
		}elsif( $tval eq 'SPECIAL' && $name eq 'nsdkeysdir' ){
			$nsdkeysdir = $fill;
		}else{
			next;
		}

	}

	$nsdkeysdir = $self->nsdkeysdir( $nsdkeysdir );

	$result .= " };";

	# tsig stuff.  Wheee.
	my %tsigs = ();

	# Loop through the lines in nsd.zones.
	for my $line (@lines) {
	
		# replace lots of space with one space.
		$line =~ s/\s+/ /g;

		# Remove '//' style comments.
		$line =~ s/\/\/.*$//g;

		# Remove '#' style comments.
		$line =~ s/\#.*$//g;

		# nsd.zones only has lines beginning with 'zone'.
		next unless( $line =~ /^\s*zone\s+(\S+)\s+(\S+)\s*(\S*.*)\s*$/ );
		my $this_zone=$1;
		my $this_file=$2;
		my $this_rest=$3;

		# We rework the string into Bind9-style, as the code for
		# dealing with this is nice and solid.

		# Set up a temporary line first.  We may need to insert
		# stuff into the stream beforehand (With BIND, you need to
		# define keys before you use them.  By inserting stuff in
		# this stream before we use them, we hopefully stop people 
		# shooting themselves in the foot if they generate a named.conf
		# file by simply dumping the config out.

		my $tmpresult = " zone \"$this_zone\" in { file \"$this_file\";";

		my $tmptype = "master";
		if( $this_rest =~ /masters\s*((\s+(\d+\.){3,3}\d+|\s+(([0-9a-f]*:){1,15}(:[0-9a-f]+){1,15}))){1,}\s*(notify|$)/ ){
			my @tmpres3 = split( / /, $1 );
			$tmpresult .= " masters {";
			foreach my $tval ( @tmpres3 ){
				$tmpresult .= " $tval";
				if( defined( $nsdkeysdir ) ){
					if( -f $nsdkeysdir . "/ip-" . $tval . ".tsiginfo" ){
						# print STDERR "Got dir $nsdkeysdir\n";
						# we need to predefine a key.
						my ($tmpstr, $keyname) = $self->do_gettsig( $nsdkeysdir, "ip-$tval" );
						$result .= $tmpstr if( defined( $tmpstr ) );
					}
					if( -f $nsdkeysdir . "/zi-" . $this_zone . "-" . $tval . ".tsiginfo" ){
						# This key gets used for this
						# one.
						my ($tmpstr, $keyname) = $self->do_gettsig( $nsdkeysdir, "zi-$this_zone-$tval" );
						$result .= $tmpstr if( defined( $tmpstr ) );
						$tmpresult .= " key $keyname" if( defined( $keyname ) );
					}elsif( -f $nsdkeysdir . "/zo-" . $this_zone . ".tsiginfo" ){
						# This key gets used for this
						# one.
						my ($tmpstr, $keyname) = $self->do_gettsig( $nsdkeysdir, "zo-$this_zone" );
						$result .= $tmpstr if( defined( $tmpstr ) );
						$tmpresult .= " key $keyname" if( defined( $keyname ) );
					}
				}

				$tmpresult .= ";";
			}
			$tmpresult .= " };";
			$tmptype = "slave";
		}

		if( $this_rest =~ /notify\s*((\s+(\d+\.){3,3}\d+|\s+(([0-9a-f]*:){1,15}(:[0-9a-f]+){1,15}))){1,}\s*(masters|$)/ ){

			my @tmpres3 = split( / /, $1 );
			$tmpresult .= " also-notify {";
			foreach my $tval ( @tmpres3 ){
				$tmpresult .= " $tval;";
			}
			$tmpresult .= " };"
		}

		# We need to check for tsig keys now.
		if( defined( $nsdkeysdir ) ){
			if( -f $nsdkeysdir . "/zo-" . $this_zone . ".tsiginfo" ){
				my ($tmpstr, $keyname) = $self->do_gettsig( $nsdkeysdir, "zo-$this_zone" );
				$result .= $tmpstr if( defined( $tmpstr ) );
				$tmpresult .= "allow-transfer { key $keyname;};" if( defined( $keyname ) );
			}
		}
				
		# Now that we've put tsig stuff beforehand, put in the zone.
		$result .= " $tmpresult type $tmptype;";
		# and end it.
		$result .= " };";
	}

	my $tree = &analyze_brackets($result);
	my @res = &analyze_statements(@$tree);

	foreach my $temp (@res) {
		my @temp = @$temp;
		my $type = shift @temp;

		my $statement;

		eval {
			my $tmp = 'DNS::Config::Statement::' . ucfirst(lc $type);

			if ( eval "require $tmp" ){
				$statement = $tmp->new();
				$statement->parse_tree(@temp);
			}else{
				# Doesn't exist.
				print STDERR "Require of $tmp failed\n";
			}
		};

		if($@) {
			#warn $@;
			
			$statement = DNS::Config::Statement->new();
			$statement->parse_tree($type, @temp);
		}

		$self->{'CONFIG'}->add($statement);
	}
		
	return $self;
}


# This routine only dumps the nsd.zones file.
sub dump_nsd_zones {
	my($self, $file) = @_;
	
	$file = $file || $self->{'FILE'};

	return undef unless($file);
	return undef unless($self->{'CONFIG'});

	my $config = $self->config;
	my @statements = $config->statements;

	my $infile = 0;
	my $old_fh = undef;
	if($file) {
		if(open(FILE, ">$file")) {
			$old_fh = select(FILE);
			$infile = 1;
		}else{
			return( undef );
		}
	}

	# We need to iterate through the config outselves
	foreach my $statement ( @statements ){
		my $tmpref = ref $statement;

		# Dump only the zone mentions.
		next unless( $tmpref =~ /^DNS::Config::Statement::Zone$/ );

		# ; zone^Iname^I^Ifilename^I^I[ masters/notify ip-address ]$
		# zone^I.^I^Iprimary/root.zone^Inotify 128.9.0.107 192.33.4.12 128.8.10.90$
		# zone^Iww.net^I^Iprimary/ww.net$
		# zone^Inlnetlabs.nl^Isecondary/nlnetlabs.nl^Imasters 213.53.69.1$
		print "zone\t" . $statement->{'NAME'} . "\t\t" . $statement->{'FILE'};
		my @masters = $statement->masters();
		my @anotify = $statement->also_notifys();
		if( ( scalar @masters ) > 0 ){
			print "\tmasters";
			foreach my $kkey( @masters ){
				my @foo = @{$kkey};
				foreach my $kkey2( @foo ){
					print " $kkey2";
				}
			}
		}
		if( ( scalar @anotify ) > 0 ){
			print "\tnotify";
			foreach my $kkey( @anotify ){
				my @foo = @{$kkey};
				foreach my $kkey2( @foo ){
					print " $kkey2";
				}
			}
		}
		print "\n";
		# print "Foo " . $statement->master . "\n";
	}


	# If we're in a file, select() back.
	if( $infile ){
		# map { $_->dump() } $self->config()->statements();
		select($old_fh);
		close FILE;
		$infile = 0;
	}
	
	return $self;
}

sub dump_nsdc {
	my($self, $file) = @_;
	
	$file = $file || $self->{'FILE'};

	return undef unless($file);
	return undef unless($self->{'CONFIG'});

	my $config = $self->config;
	my @statements = $config->statements;

	my $infile = 0;
	my $old_fh = undef;
	if($file) {
		if(open(FILE, ">$file")) {
			$old_fh = select(FILE);
			$infile = 1;
		}else{
			return( undef );
		}
	}

	# We need to iterate through the config outselves
	foreach my $statement ( @statements ){
		my $tmpref = ref $statement;

		# Dump only the option mentions.
		next unless( $tmpref =~ /^DNS::Config::Statement::Options$/ );

		# Where named-xfer is.
		if( defined( $statement->{'NAMED-XFER'} ) ){
			print "NAMEDXFER=\"" . $statement->{'NAMED-XFER'} . "\"\n";
		}

		# Where NSDZONES is.
		if( defined( $statement->{'DIRECTORY'} ) ){
			print "NSDZONES=\"" . $statement->{'DIRECTORY'} . "\"\n";
		}

		# Where the NSDKEYSDIR is.
		# nsdkeysdir isn't expected to be in the Options statement.
		if( defined( $self->nsdkeysdir() ) ){
			print "NSDKEYSDIR=\"" . $self->nsdkeysdir() . "\"\n";
		}elsif( defined( $statement->{'NSDKEYSDIR'} ) ){
			print "NSDKEYSDIR=\"" . $statement->{'NSDKEYSDIR'} . "\"\n";
		}elsif( defined( $statement->{'DIRECTORY'} ) ){
			print "NSDKEYSDIR=\"" . $statement->{'DIRECTORY'} . "\"\n";
		}

		# Now for the flags.  Oh my.
		if( defined( $statement->{'LISTEN-ON'} ) ){

			print "NSDFLAGS=\"";

			my @tsplit = @{ $statement->{'LISTEN-ON'} };

			foreach my $kkey( @tsplit ){
				if( ! ref( $kkey ) ){
					if( $kkey =~ /port/i ){
						print " -p";
					}else{
						print " $kkey";
					}
				}else{
					my @tref1 = @{$kkey};
					foreach my $kkey2( @tref1 ){
						if( ref( $kkey2 ) ){
							push @tref1, @{$kkey2};
							next;
						}
						if( $kkey2 =~ /any/ ){
							# NSD doesn't handle 
							# multiple interfaces
							# correctly.  This is
							# a hack to deal with
							# these cases.
							print " \`ifconfig -a | perl -e \'while(<>){ next unless(m/^\\s*inet(4|6)?(\\s+addr:)?\\s*(((\\d+\\.){3,3}\\d+)|(([0-9a-f]*:){1,15}(:[0-9a-f]+){1,15}))(\\/\\d+)?\\s+/); print \" -a \$3\"; }\'\`";
						}else{
							print " -a $kkey2";
						}
					}
				}
			}

			print "\"\n";
		}
		print "\n";
	}


	# If we're in a file, select() back.
	if( $infile ){
		# map { $_->dump() } $self->config()->statements();
		select($old_fh);
		close FILE;
		$infile = 0;
	}
	
	return $self;
}

sub dump_tsig() {
	my($self, $dir) = @_;

	$dir = $dir || $self->nsdkeysdir();

	return( undef ) unless( defined( $dir ) );

	# Make sure that its useful.
	return( undef ) unless( -d $dir );
	return( undef ) unless( -r $dir );
	return( undef ) unless( -w $dir );
	return( undef ) unless( -x $dir );

	# Map the algorithms.
	# Should really be invoking DNS::Config::Statement::Key for this.
	my %algs = (
			"157",	"hmac-md5",
			"hmac-md5",	"157",
		);

	# Run through the statements.
	my $config = $self->config;
	my @statements = $config->statements;

	my %keys = ();
	my %keys_written = ();
	my %want_keys = ();

	foreach my $statement( @statements ){
		my $tref = ref( $statement );

		# We only want Key, Zone or Server statements.
		next unless( $tref =~ /^DNS::Config::Statement::(Key|Zone|Server)$/ );

		my $this_ref = $1;
		if( $this_ref eq 'Key' ){
			my $tname = $statement->name();
			my $talg = $statement->algorithm();
			my $tsecret = $statement->secret();

			if( $talg =~ /\D/ ){
				$talg = $algs{$talg};
			}

			$keys{$tname}{'name'} = $tname;
			$keys{$tname}{'algorithm'} = $talg;
			$keys{$tname}{'secret'} = $tsecret;
		}elsif( $this_ref eq 'Server' ){

			my $tname = $statement->name();
			my @tkeys = $statement->keys();
			my %usekeys = ();
			foreach my $kkey( @tkeys ){
				if( ref( $kkey ) ){
					push @tkeys, @{$kkey};
				}else{
					$usekeys{"$kkey"}++;
				}
			}

			foreach my $kkey( keys %usekeys ){
				my $tstr = "ip-$tname.tsiginfo";
				$want_keys{$tstr} = $kkey;
			}
		}elsif( $this_ref eq 'Zone' ){
			my $tname = $statement->name();

			my @masters = $statement->masters();

			my $loop = 0;

			# This is possibly multiple levels of array, that 
			# should be the sequence of things in the 'masters'
			# field of the zone statement.  We *should* have
			# 'ip', 'port', 'port_num', 'key', 'key_id', 'ip' (etc)
			# with the 'port', 'port_num' and 'key', 'key_id'
			# sequences optional.
			while( $loop < scalar @masters ){
				my $kkey = $masters[$loop];
				if( ref( $kkey ) ){
					push @masters, @{$kkey};
					$loop++;
				}else{
					# $ip key $keyname
					my $tip = $kkey;
					$loop++;
					my $tport = undef;
					my $tkey = undef;
					while( ( $loop + 2 ) < ( scalar @masters ) && ! ref( $masters[$loop] ) && ! ref( $masters[$loop+1] ) && $masters[$loop] =~ /(port|key)/i ){
						my $twhat=$1;
						if( $twhat =~ /key/i ){
							$tkey = $masters[$loop+1];
							$loop++;
						}elsif( $twhat =~ /port/i ){
							$tport = $masters[$loop+1];
							$loop++;
						}
						$loop++;
					}

					# We found a key for this zone.  Yay!
					if( defined( $tkey ) ){
						my $tstr = "zi-$tname-$tip.tsiginfo";
						$want_keys{$tstr} = $tkey;
					}
				}
			}
		}
	}

	# Now write out all of the keys.
	foreach my $kkey( keys %want_keys ){
		my $tkey = $want_keys{$kkey};

		print STDERR "Key - $kkey - $tkey\n";
		next if( defined( $keys_written{$kkey} ) );
		next if( ! defined( $keys{$tkey}{'name'} ) );

		# Wheres the IP address?
		my $tip = "IPADDRESS";

		# zi-$zone-$ip.tsiginfo
		if( $kkey =~ /^zi-\S+-([^\-]+).tsiginfo$/ ){
			$tip=$1;
		# ip-$ip.tsiginfo
		}elsif( $kkey =~/^ip-(\S+).tsiginfo$/ ){
			$tip=$1;
		}

		# Write out the file.

		if( open( TSIGOUT, "> $dir/$kkey" ) ){
			print TSIGOUT "$tip\n";	
			print TSIGOUT $keys{$tkey}{'name'} . "\n";	
			print TSIGOUT $keys{$tkey}{'algorithm'} . "\n";	

			# Deal with the secret.
			my $toutsec = undef;
			if( ref( $keys{$tkey}{'secret'} ) ){
				$toutsec = join( ' ', @{$keys{$tkey}{'secret'}} ) ;
			}else{
				$toutsec = $keys{$tkey}{'secret'};
			}
			$toutsec =~ s/^"//g;
			$toutsec =~ s/"$//g;
			print TSIGOUT "$toutsec";
			print TSIGOUT "\n";
			close( TSIGOUT );
			$keys_written{$kkey}++;
		}
			
	}
	
	return( $self );
}

sub dump {
	my($self, $file) = @_;

	# Eventually this could dump all of it, but you need to specify
	# multiple files.
	return( $self->dump_nsd_zones( $file ) );
}

sub config {
	my($self) = @_;
	
	return($self->{'CONFIG'});
}

sub analyze_brackets {
	my($string) = @_;
	
	my @chars = split //, $string;

	my $tree = [];
	my @chunks;
	my @stack;

	my %matching = (
		'(' => ')',
		'[' => ']',
		'<' => '>',
		'{' => '}',
	);

	for my $char (@chars) {
		if(grep {$char eq $_} keys(%matching)) {
			my $temp = [];
			push @$tree, $temp;
			push @chunks, $tree;
			push @stack, $matching{$char};
			$tree = $temp;
		}
		elsif(grep {$char eq $_} values(%matching)) {
			my $expected = pop @stack;
			die "Invalid order !\n" if((!defined $expected) || ($char ne $expected));
			$tree = pop @chunks;
			die "Unmatched closing !\n" if(!ref($tree));
		}
		else {
			my $noe = scalar(@$tree);
			
			if((!$noe) || (ref($$tree[$noe-1]) eq 'ARRAY')) {
				push @$tree, ($char);
			}
			else {
				$$tree[$noe-1] .= $char;
			}
		}
	}

	die "Unbalanced !\n" if(scalar @stack);

	return($tree);
}

sub analyze_statements {
	my(@array) = @_;
	my @result;
	my $full;
	
	for my $line (@array) {
		if(!ref($line)) {
			$line =~ s/\s*\;\s*/\;/g;

			my(@parts) = split /;/, $line, -1;

			shift @parts if(!$parts[0]);

			if($parts[$#parts-1] eq '') {
				$full = 1;
				pop @parts;
			}
			else {
				$full = 0;
			}

			for my $temp (@parts) {
				if($temp) {
					$temp =~ s/^\s*//g;
					
					my @chunks = split / /, $temp;

					push @result, (\@chunks);
				}
			}
		}
		else {
			my @statements = &analyze_statements(@$line);

			my @temp;
			if(!$full) { my $temp = pop @result; @temp = @$temp; }
			push @temp, (\@statements);
			push @result, (\@temp);
		}
	}

	return(@result);
}

1;

__END__

=pod

=head1 NAME

DNS::Config::File::Nsd - Concrete adaptor class

=head1 SYNOPSIS

use DNS::Config::File::Nsd;

my $file = new DNS::Config::File::Nsd($nsd.zones_file);

# Read in an additional config file (needed before invoking ->parse() )
$file->nsdc( $nsdc.conf_file );

# Set the nsdkeysdir (tsig keys in files)
$file->nsdkeysdir( $tsigdir );

# Parse nsd.zones, nsdc.conf, and any TSIG files 
$file->parse();

# Dump the nsd.zones file (also $file->dump_nsd_zones() )
$file->dump();		

# Dump the nsdc.conf file
$file->dump_nsdc();

# Dump the tsig files.
$file->dump_tsig( $tsigdir );

# Debug the output.
$file->debug();

$file->config(new DNS::Config());


=head1 ABSTRACT

This class represents a set of configuration files for NLNetLab's
NSD (Name Server Daemon), an authoritative-only nameserver sponsored
by the RIPE NCC.

=head1 DESCRIPTION

This class, the Nsd file adaptor, knows how to read and write the
information to a file in the NSD daemon specific formats.  Note that
NSD has three places for configuration information, being:

nsd.zones - Zone name and zone file specifications for zonec(1), the
notify servers for nsd-notify(1) and the master servers for nsdc and
named-xfer.

nsdc.conf - Special (shell-script) configuration for nsdc.

NSDKEYSDIR - A directory where TSIG keys can be found, for usage by 
nsdc and named-xfer.


=head1 AUTHOR

Copyright (C)2003 Bruce Campbell. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Please address bug reports and comments to: 
bxc@users.sourceforge.net


=head1 SEE ALSO

L<DNS::Config>, L<DNS::Config::File>, L<DNS::Config::Bind9>


=cut
