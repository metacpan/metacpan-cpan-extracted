package App::Acmeman;
use strict;
use warnings;
use Net::ACME2::LetsEncrypt;
use Crypt::Format;
use Crypt::OpenSSL::PKCS10 qw(:const);
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::X509;
use File::Basename;
use File::Path qw(make_path);
use DateTime::Format::Strptime;
use LWP::UserAgent;
use LWP::Protocol::https;
use Socket qw(inet_ntoa);
use Sys::Hostname;
use Pod::Usage;
use Pod::Man;
use Getopt::Long qw(:config gnu_getopt no_ignore_case);
use POSIX qw(strftime time floor);
use App::Acmeman::Config;
use App::Acmeman::Domain qw(:files);
use Data::Dumper;
use Text::ParseWords;
use App::Acmeman::Log qw(:all :sysexits);
use feature 'state';

our $VERSION = '3.02';

my $progdescr = "manages ACME certificates";

my $letsencrypt_root_cert_url =
    'https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem';

sub new {
    my $class = shift;
    my $self = bless {
	_progname => basename($0),
        _acme_host => 'production',
        _command => 'renew',
	_option => {
	    config_file => '/etc/acmeman.conf'
	},
	_domains => []
    }, $class;
    GetOptions(
	'h' => sub {
	          pod2usage(-message => "$self->{_progname}: $progdescr",
                            -exitstatus => EX_OK);
        },
        'help' => sub {
                  pod2usage(-exitstatus => EX_OK, -verbose => 2);
        },
        'usage' => sub {
                  pod2usage(-exitstatus => EX_OK, -verbose => 0);
        },
        'debug|d+' => \$self->{_option}{debug},
        'dry-run|n' => \$self->{_option}{dry_run},
	'stage|s' => sub { $self->{_acme_host} = 'staging' },
        'force|F' => \$self->{_option}{force},
        'time-delta|D=n' => \$self->{_option}{time_delta},
	'setup|S' => sub { $self->{_command} = 'setup' },
	'alt-names|a' => \$self->{_option}{check_alt_names},
	'config-file|f=s' => \$self->{_option}{config_file},
	'version' => sub {
	    print "$0 version $VERSION\n";
	    exit(EX_OK)
	}
    ) or exit(EX_USAGE);
    ++$self->{_option}{debug} if $self->dry_run_option;
    debug_level($self->{_option}{debug});

    $self->add_selected_domains(@ARGV);

    $self->{_cf} = new App::Acmeman::Config($self->option('config_file'));
    my $v;
    if ($v = $self->option('time_delta')) {
	$self->cf->set(qw(core time-delta), $v);
    }
    if ($v = $self->option('check_alt_names')) {
	$self->cf->set(qw(core check-alt-names), $v);
    }
    if ($v = $self->option('debug')) {
	$self->cf->set(qw(core verbose), $v);
    } else {
	$self->option('debug', $self->cf->get(qw(core verbose)));
    }
	
    debug_level($self->cf->core->verbose);

    return $self;
}

sub run {
    my $self = shift;
    $self->${ \$self->{_command} }();
}

sub cf { shift->{_cf} }
sub progname { shift->{_progname} }
sub acme_host { shift->{_acme_host} }

sub option {
    my ($self,$opt) = @_;
    return $self->{_option}{$opt};
}

sub force_option { shift->option('force') }
sub dry_run_option { shift->option('dry_run') }

sub resolve {
    my ($self, $host) = @_;
    if (my @addrs = gethostbyname($host)) {
	return map { inet_ntoa($_) } @addrs[4 .. $#addrs];
    } else {
	error("$host doesn't resolve");
    }
    return ();
}

sub myip {
    my ($self, $host) = @_;
    state $ips;
    unless ($ips) {
	$ips = {};
	my $addhost;
	
	if ($self->cf->is_set(qw(core my-ip))) {
	    $addhost = 0;
	    foreach my $ip ($self->cf->get(qw(core my-ip))) {
		if ($ip eq '$hostip') {
		    $addhost = 1;
		} else {
		    $ips->{$ip} = 1;
		}
	    }
	} else {
	    $addhost = 1;
	}
	
	if ($addhost) {
	    foreach my $ip ($self->resolve(hostname())) {
		$ips->{$ip} = 1;
	    }
	}
    }
    return $ips->{$host};
}

sub host_ns_ok {
    my ($self, $host) = @_;
    foreach my $ip ($self->resolve($host)) {
	return 1 if $self->myip($ip);
    }
    return 0
}

sub prep_dir {
    my ($self, $name) = @_;
    my $dir = dirname($name);
    if (! -d $dir) {
	debug(3, "creating directory $dir");
	my @created = make_path("$dir", { error => \my $err } );
	if (@$err) {
	    for my $diag (@$err) {
		my ($file, $message) = %$diag;
		if ($file eq '') {
		    error($message);
		} else {
		    error("mkdir $file: $message");
		}
	    }
	    exit(EX_CANTCREAT);
	}
    }
}

sub get_root_cert {
    my $self = shift;
    my $name = shift;

    $self->prep_dir($name) unless $self->dry_run_option;

    debug(1, "downloading $letsencrypt_root_cert_url to \"$name\"");
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($letsencrypt_root_cert_url);
    if ($response->is_success) {
	unless ($self->dry_run_option) {
	    open(my $fd, '>', $name)
		or abend(EX_CANTCREAT,
		         "can't open \"$name\" for writing: $!");
	    print $fd $response->decoded_content;
	    close $fd;
	}
    } else {
	error("error downloading certificate from $letsencrypt_root_cert_url");
	abend(EX_NOINPUT, $response->status_line);
    }
}

sub setup {
    my $self = shift;
    
    $self->prep_dir($self->cf->get(qw(core rootdir)).'/file');

    $self->get_root_cert('/etc/ssl/acme/lets-encrypt-x3-cross-signed.pem');

    foreach my $src ($self->cf->get(qw(core source))) {
	unless ($src->setup(dry_run => $self->dry_run_option,
			    force => $self->force_option)) {
	    exit(1);
	}
    }

    exit(EX_OK);
}

sub collect {
    my $self = shift;
    my $err;
    my $node = $self->cf->getnode('domain') or return;
    my $subs = $node->as_hash;
    while (my ($k, $v) = each %$subs) {
	my $dom;
	my $ft;

        my $alt = [grep { !$self->cf->get(qw(core check-dns))
			     || $self->host_ns_ok($_) }
                         ($k, ($v->{alt} ? @{$v->{alt}} : ()))];
	if (@$alt) {
	    $k = shift @$alt;
	    $alt = undef unless @$alt;
	} else {
	    error("ignoring $k: none of its names resolves to our IP");
	    next;
	}

	if (exists($v->{files})) {
	    if (my $fref = $self->cf->getnode('files', $v->{files})) {
		$dom = new App::Acmeman::Domain(
		    cn => $k,
		    alt => $alt,
		    postrenew => $v->{postrenew},
		    %{$fref->as_hash});
	    } else {
		error("files.$v->{files} is referenced from [domain $k], but never declared");
		++$err;
		next;
	    }
	} else {
	    $dom = new App::Acmeman::Domain(
		cn => $k,
		alt => $alt,
 	        postrenew => $v->{postrenew},
		%{$self->cf->getnode('files',
				     $self->cf->get(qw(core files)))->as_hash});
	}
	$self->domains($dom);
    }
    exit(1) if $err;
}

sub domains {
    my $self = shift;
    if (@_) {
	push @{$self->{_domains}}, @_;
    }
    return @{$self->{_domains}};
}

sub coalesce {
    my $self = shift;
    debug(2, "coalescing virtual hosts");
    my $i = 0;
    my @domlist;
    foreach my $ent (sort { $a->{domain} cmp $b->{domain} }
		     map { { ord => $i++, domain => $_ } } $self->domains) {
	if (@domlist && $domlist[-1]->{domain}->cn eq $ent->{domain}->cn) {
	    $domlist[-1]->{domain} += $ent->{domain};
	} else {
	    push @domlist, $ent;
	}
    }
    @{$self->{_domains}} =
	map { $_->{domain} } sort { $a->{ord} <=> $b->{ord} } @domlist;
}

sub add_selected_domains {
    my $self = shift;
    if (@_) {
	@{$self->{_selection}}{map { lc } @_} = (1) x @_;
    }
}

sub selected_domains {
    my $self = shift;
    return $self->domains unless $self->{_selection};
    return grep { $self->{_selection}{$_} } $self->domains;
}

sub renew {
    my $self = shift;

    $self->collect;
    unless ($self->selected_domains) {
	debug(1, "nothing to do");
	exit(0);
    }
    $self->coalesce;

    my $renewed = 0;
    foreach my $vhost ($self->selected_domains) {
	if ($self->force_option || $self->domain_cert_expires($vhost)) {
	    if ($self->register_domain_certificate($vhost)) {
		if (my $cmd = $vhost->postrenew) {
		    $self->runcmd($cmd);
		} else {
		    $renewed++;
		}
	    }
	}
    }

    if ($renewed) {
	if ($self->cf->is_set(qw(core postrenew))) {
	    foreach my $cmd ($self->cf->get(qw(core postrenew))) {
		$self->runcmd($cmd);
	    }
        } else {
	    error("certificates changed, but no postrenew command is defined (core.postrenew)");
        }
    }
}

sub domain_cert_expires {
    my ($self, $domain) = @_;
    my $crt = $domain->certificate_file;
    if (-f $crt) {
	my $x509 = Crypt::OpenSSL::X509->new_from_file($crt);

	my $exts = $x509->extensions_by_name();
	if (exists($exts->{subjectAltName})) {
	    my $msg = $self->cf->get(qw(core check-alt-names))
		        ? 'will renew' : 'use -a to trigger renewal';
	    my @names = map { s/^DNS://; $_ } 
                          split /,\s*/, $exts->{subjectAltName}->to_string();
	    my @missing;
	    foreach my $vh (sort { length($b) <=> length($a) } $domain->names) {
                unless (grep { $_ eq $vh } @names) {
		    push @missing, $vh;
		}
	    }
	    if (@missing) {
		debug(1, "$crt: the following SANs are missing: "
		         . join(', ', @missing)
		         . "; $msg");
		return 1 if $self->cf->get(qw(core check-alt-names));
	    }
	}
	    
	my $expiry = $x509->notAfter();

	my $strp = DateTime::Format::Strptime->new(
	    pattern => '%b %d %H:%M:%S %Y %Z',
	    time_zone => 'GMT'
	);
	my $ts = $strp->parse_datetime($expiry)->epoch;
	my $now = time();
	if ($now < $ts) {
	    my $hours = floor(($ts - $now) / 3600);
	    my $in;
	    if ($hours > 24) {
		my $days = floor($hours / 24);
		$in = "in $days days";
	    } elsif ($hours == 24) {
		$in = "in one day";
	    } else {
		$in = "today";
	    }
	    debug(2, "$crt expires on $expiry, $in");
	    if ($now + $self->cf->get(qw(core time-delta)) < $ts) {
		return 0;
	    } else {
		debug(2, "will renew $crt (expires on $expiry, $in)");
	    }
	} else {
	    debug(2, "will renew $crt");
	}
    }
    return 1;
}

sub debug_to_loglevel {
    my $self = shift;
    my @lev = ('err', 'info', 'debug');
    my $v = $self->cf->core->verbose;
    return $lev[$v > $#lev ? $#lev : $v];
}

sub save_challenge {
    my ($self,$challenge) = @_;
    my $file = File::Spec->catfile($self->cf->get(qw(core rootdir)), $challenge->get_path);
    if (open(my $fh, '>', $file)) {
	print $fh $self->acme->make_key_authorization($challenge);
	close $fh;
	debug(3, "wrote challenge file $file");
    } else {
	error("can't open $file for writing: $!");
	die;
    }
}   

sub account_key {
    my $self = shift;

    unless ($self->{_account_key}) {
	my $keyfile = $self->cf->get('account', 'key');
	if (-r $keyfile) {
	    if (open(my $fh, '<', $keyfile)) {
		local $/ = undef;
		$self->{_account_key} = Crypt::OpenSSL::RSA->new_private_key(<$fh>);
		close $fh;
	    } else {
		error("can't open $keyfile for reading: $!");
	    }
	} else {
	    $self->{_account_key} = Crypt::OpenSSL::RSA->generate_key($self->cf->get('core', 'key-size'));
	}
    }
    return $self->{_account_key};
}

sub account_key_id {
    my $self = shift;
    
    my $idfile = $self->cf->get('account', 'id');
    if (my $val = shift) {
	$self->{_account_key_id} = $val;
	$self->prep_dir($idfile);
	if (open(my $fh, '>', $idfile)) {
	    print $fh $val;
	    close $fh;
	} else {
	    error("can't open $idfile for writing: $!");
	}
    } elsif (!$self->{_account_key_id}) {
	if (-r $idfile) {
	    if (open(my $fh, '<', $idfile)) {
		chomp($self->{_account_key_id} = <$fh>);
		close $fh;
		debug(3, "using key_id $self->{_account_key_id}");
	    } else {
		error("can't open $idfile for reading: $!");
	    }
	}
    }
    return $self->{_account_key_id};
}

sub acme {
    my $self = shift;
    unless ($self->{_acme}) {
	my $acme = Net::ACME2::LetsEncrypt->new(
	    environment => $self->acme_host,
	    key => $self->account_key->get_private_key_string(),
	    key_id => $self->account_key_id
        );
	$self->{_acme} = $acme;

	unless ($acme->key_id()) {
	    # Create new account
	    debug(3, "creating account");
	    my $terms_url = $acme->get_terms_of_service();
	    $acme->create_account(termsOfServiceAgreed => 1);
	    debug(3, "saving account credentials");
	    $self->account_key_id($acme->key_id());
	    my $keyfile = $self->cf->get('account', 'key');
	    if (open(my $fh, '>', $keyfile)) {
	        print $fh $self->account_key->get_private_key_string();
	        close $fh;
	    } else {
		error("can't open $keyfile for writing: $!");
	    }
	}
    }
    return $self->{_acme};
}

sub register_domain_certificate {
    my ($self,$domain) = @_;
    
    my $key_size = $self->cf->get('domain', $domain, 'key-size')
	              || $self->cf->get('core', 'key-size');

    if ($self->cf->core->verbose > 0) {
	my $crt = $domain->certificate_file;
	my $alt = join(',', $domain->alt);
	if (-f $crt) {
	    debug(1, "renewing $crt: CN=$domain, alternatives=$alt, key_size=$key_size");
	} else {
	    debug(1, "issuing $crt: CN=$domain, alternatives=$alt, key_size=$key_size");
	}
    }

    return 1 if $self->dry_run_option;

    my $acme = $self->acme;
	
    # Create order
    my $order = $acme->create_order(
                  identifiers => [
                     map { { type => 'dns', value => $_ } } $domain->names
                  ]
    );
    debug(3, "$domain: created order");

    foreach my $authz (map { $acme->get_authorization($_) } $order->authorizations()) {
    
	my ($challenge) = grep { $_->type() eq 'http-01' } $authz->challenges();
	if (!$challenge) {
	    error("$domain: no challenge of acceptable type received");
	    return 0;
	}

	debug(3, "$domain: serving challenge");
	$self->save_challenge($challenge);
	$acme->accept_challenge($challenge);

	my $ret;
	while (($ret = $acme->poll_authorization($authz)) eq 'pending') {
	    sleep 1
	}
	if ($ret ne 'valid') {
	    error("$domain: can't renew certificate: authorization: $ret");
	    return 0;
	}
    }
    
    my $csr = $self->make_csr($domain, $key_size);

    my $status = $acme->finalize_order($order, $csr->get_pem_req());
    while ($status eq 'pending') {
	sleep 1;
	$status = $order->status()
    }

    unless ($status eq 'valid') {
	error("$domain: can't renew certificate: finalize: $status");
	return 0;
    }
    my $chain = $acme->get_certificate_chain($order);

    if (my $filename = $domain->file(KEY_FILE)) {
	debug(3, "writing $filename");
	$self->prep_dir($filename);
	my $u = umask(077);
	$csr->write_pem_pk($filename);
	umask($u);

	my $cert;
        if ($chain =~ /(^-+BEGIN\s+CERTIFICATE-+$
                       .+?
                       ^-+END\s+CERTIFICATE-+$)
                       (.+)/msx) {
	    $cert = $1;
	    ($chain = $2) =~ s/^\s+//s;
	} else {
	    $cert = $chain; # FIXME: not sure if that's right
	}
	
	if ($filename = $domain->file(CA_FILE)) {
	    $self->save_crt($domain, CA_FILE, $chain);
	}
	$self->save_crt($domain, CERT_FILE, $cert);
    } else {
        $filename = $domain->certificate_file;
        debug(3, "writing $filename");
        $self->prep_dir($filename);
        my $u = umask(077);
        open(my $fd, '>', $filename)
	    or abend(EX_CANTCREAT, "can't open $filename for writing: $!");
        print $fd $chain;
        print $fd "\n";
        print $fd $csr->get_pem_pk();
        print $fd "\n";
        umask($u);
    }
    
    return 1;
}

sub make_csr {
    my ($self, $dom, $keysize) = @_;
    my $req = Crypt::OpenSSL::PKCS10->new($keysize);
    $req->set_subject("/CN=".$dom->cn);
    $req->add_ext(Crypt::OpenSSL::PKCS10::NID_subject_alt_name,
		  join(',', map { "DNS:$_" } $dom->alt))
	if $dom->alt > 0;
    $req->add_ext_final();
    $req->sign();
    return $req;
}

sub save_crt {
    my ($self, $domain, $type, $pem) = @_;

    if (my $filename = $domain->file($type)) {
	debug(3, "writing $filename");
	$self->prep_dir($filename);
	open(my $fd, '>', $filename);
        print $fd $pem;
	close $fd;
	return $filename;
    }
}

sub runcmd {
    my ($self,$cmd) = @_;
    debug(3, "running $cmd");
    unless ($self->dry_run_option) {
	system($cmd);
	if ($? == -1) {
	    error("$cmd: failed to execute: $!");
	} elsif ($? & 127) {
	    error("$cmd: died on signal ".($? & 127));
	} elsif (my $code = ($? >> 8)) {
	    error("$cmd: exited with code $code");
	}
    }
}

1;
