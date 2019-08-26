package App::Acmeman;
use strict;
use warnings;
use Protocol::ACME;
use Protocol::ACME::Challenge::LocalFile;
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
use Getopt::Long qw(:config gnu_getopt no_ignore_case auto_version);
use POSIX qw(strftime time floor);
use App::Acmeman::Config;
use App::Acmeman::Domain qw(:files);
use Data::Dumper;
use Text::ParseWords;
use App::Acmeman::Log qw(:all :sysexits);
use feature 'state';

our $VERSION = '2.00';

my $progdescr = "manages ACME certificates";

my %acme_endpoint = (prod => 'acme-v01.api.letsencrypt.org',  
                     staging => 'acme-staging.api.letsencrypt.org');
my $letsencrypt_root_cert_url =
    'https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem';

sub new {
    my $class = shift;
    my $self = bless {
	_progname => basename($0),
        _acme_host => 'prod',
        _command => 'renew',
	_option => {
	    config_file => '/etc/acmeman.conf'
	},
	_domains => []
    }, $class;
    GetOptions(
	   "h" => sub {
                    pod2usage(-message => "$self->{_progname}: $progdescr",
                              -exitstatus => EX_OK);
           },
           "help" => sub {
                    pod2usage(-exitstatus => EX_OK, -verbose => 2);
           },
           "usage" => sub {
                    pod2usage(-exitstatus => EX_OK, -verbose => 0);
           },
           "debug|d+" => \$self->{_option}{debug},
           "dry-run|n" => \$self->{_option}{dry_run},
	   "stage|s" => sub { $self->{_acme_host} = 'staging' },
           "force|F" => \$self->{_option}{force},
           "time-delta|D=n" => \$self->{_option}{time_delta},
	   "setup|S" => sub { $self->{_command} = 'setup' },
	   "alt-names|a" => \$self->{_option}{check_alt_names},
	   "config-file|f=s" => \$self->{_option}{config_file},
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
sub acme_host { $acme_endpoint{shift->{_acme_host}} }

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

sub challenge { shift->{_challenge} }

sub renew {
    my $self = shift;

    $self->collect;
    unless ($self->selected_domains) {
	debug(1, "nothing to do");
	exit(0);
    }
    $self->coalesce;
    
    $self->{_challenge} = Protocol::ACME::Challenge::LocalFile->new({
	www_root => $self->cf->get(qw(core rootdir))
    });

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
    my $account_key = Crypt::OpenSSL::RSA->generate_key($key_size);

    my $acme = Protocol::ACME->new(
    	host => $self->acme_host,
    	account_key => { buffer => $account_key->get_private_key_string(),
			 format => 'PEM' },
    	loglevel => $self->debug_to_loglevel()
    );

    eval {
	$acme->directory();
	$acme->register();
	$acme->accept_tos();

        foreach my $name ($domain->names) {
   	    $acme->authz($name);
  	    $acme->handle_challenge($self->challenge);
	    $acme->check_challenge();
	    $acme->cleanup_challenge($self->challenge);
        }

	my $csr = $self->make_csr($domain, $key_size);
        my $cert = $acme->sign({ format => 'PEM',
				 buffer => $csr->get_pem_req() });
        my $chain = $acme->chain();

        if (my $filename = $domain->file(KEY_FILE)) {
	    debug(3, "writing $filename");
	    $self->prep_dir($filename);
	    my $u = umask(077);
	    $csr->write_pem_pk($filename);
	    umask($u);

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
		or abend(EX_CANTCREAT,
		         "can't open $filename for writing: $!");
	    print $fd Crypt::Format::der2pem($cert, 'CERTIFICATE');
	    print $fd "\n";
	    print $fd Crypt::Format::der2pem($chain, 'CERTIFICATE');
	    print $fd "\n";
	    print $fd $csr->get_pem_pk();
	    print $fd "\n";
	    umask($u);
	}
    };
    if ($@) {
    	if (UNIVERSAL::isa($@, 'Protocol::ACME::Exception')) {
    	    error("$domain: can't renew certificate: $@->{status}");
            if (exists($@->{error})) {
    	        error("$domain: $@->{error}{status} $@->{error}{detail}");
    	    } else {
    	        error("$domain: $@->{detail} $@->{type}");
            }
        } elsif (ref($@) eq '') {
            chomp $@;
            error("$domain: failed to renew certificate: $@");
    	} else {
            error("$domain: failed to renew certificate");
            print STDERR Dumper([$@]);
    	}
        return 0;  
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
    my $self = shift;
    my $domain = shift;
    my $type = shift;

    if (my $filename = $domain->file($type)) {
	debug(3, "writing $filename");
	$self->prep_dir($filename);
	open(my $fd, '>', $filename);

	foreach my $der (@_) {
	    my $pem = Crypt::Format::der2pem($der, 'CERTIFICATE');
	    print $fd $pem;
	    print $fd "\n";
	}
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
