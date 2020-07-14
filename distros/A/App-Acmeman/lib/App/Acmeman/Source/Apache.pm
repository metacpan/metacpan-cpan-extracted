package App::Acmeman::Source::Apache;

use strict;
use warnings;
use Carp;
use feature 'state';
use File::Path qw(make_path);
use File::Spec;
use App::Acmeman::Apache::Layout;
use App::Acmeman::Log qw(:all);
use parent 'App::Acmeman::Source';
use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt no_ignore_case);
use Apache::Defaults;
use Apache::Config::Preproc;
use Text::ParseWords;

sub new {
    my $class = shift;
    my $server_root;
    GetOptionsFromArray(\@_,
			'server-root=s' => \$server_root);
    my $layout = detect App::Acmeman::Apache::Layout(@_);
    my $self = bless { _layout => $layout }, $class;
    $self->server_root($server_root) if $server_root;
    return $self;
}

sub layout { shift->{_layout} }

sub scan {
    my ($self) = @_;
    debug(2, 'assuming Apache layout "'.$self->layout->name.'"');
    $self->set(qw(core postrenew), $self->layout->restart_command)
        unless $self->is_set(qw(core postrenew));
    return $self->examine_http_config($self->layout->config_file);
}

sub dequote {
    my ($self, $arg) = @_;
    if (defined($arg) && $arg =~ s{^"(.*?)"$}{$1}) {
	$arg =~ s{\\([\\"])}{$1}g;
    }
    return $arg;
}

sub examine_http_config {
    my ($self, $file) = @_;

    my $app = new Apache::Config::Preproc(
        $file,
        -expand => [ 'compact',
                     { 'include' => [ server_root => $self->server_root ] },
                     { 'macro' => [
			   'keep' => [ qw(LetsEncryptChallenge
                                          LetsEncryptReference
                                          LetsEncryptSSL)
			             ]
		       ]
		     }
	           ])
	or do {
	    error($Apache::Admin::Config::ERROR);
	    return 0;
        };

    foreach my $sect ($app->section(-name => "macro")) {
	if ($sect->value =~ m{^(?ix)letsencryptssl
                                    \s+
                                    (.+)}
	    && ! $self->is_set(qw(files apache))) {
	    $self->set(qw(files apache argument), $1);
	    map {
		if ($_->name =~ m{^(?ix)
                                  SSLCertificate((?:Key)|(?:Chain))?File}) {
		    my %t = (
			'' => 'certificate-file',
			key => 'key-file',
			chain => 'ca-file'
  		    );
		    $self->set(qw(files apache), $t{lc($1||'')},
			       $self->dequote($_->value));
		}
	    } $sect->directive();
        } elsif ($sect->value =~ m{^(?ix)letsencryptchallenge$}) {
	    foreach my $alias ($sect->directive('alias')) {
		if ($alias->value =~ m{^/.well-known/acme-challenge\s+(.+)}) {
		    my $dir = $self->dequote($1);
		    $dir =~ s{/.well-known/acme-challenge$}{};
		    $self->set(qw(core rootdir), $dir);
		    debug(3, "ACME challenge root dir: $dir");
		}
	    }
	}
    }
    
    foreach my $sect ($app->section(-name => "virtualhost")) {
	 my ($server_name) = (map {
				  (my $s = $self->dequote($_->value)) =~ s{^https?://}{};
				  $s
			      } $sect->directive('servername'));
	 my @server_aliases = map { quotewords('\s+', 0,
					       $self->dequote($_->value)) }
	                      $sect->directive('serveralias');
	 my @d = map {
	     if ($_->value =~ m{^(?ix)
                                (?:letsencrypt(challenge|ssl|reference))
                                (?:\s+(.+))?}) {
		 [lc($1),$self->dequote($2)]
	     } else {
		 ()
             }
	 } $sect->directive('use');

	 if (grep { $_->[0] eq 'challenge' } @d) {
	     unless ($server_name) {
		 $server_name = shift @server_aliases;
	     }
	     $self->define_domain($server_name);
	     $self->define_alias($server_name, @server_aliases);
	     debug(3, "will handle ".join(',', $server_name, @server_aliases));
	 } elsif (my ($ref) = map { $_->[1] }
		              grep { $_->[0] eq 'reference' } @d) {
	     $self->set('domain', $ref, 'files', 'apache');
	     $self->define_alias($ref, $server_name, @server_aliases);
         }			    
    }
    return 1;	
}

sub server_root {
    my $self = shift;
    if (my $v = shift) {
	croak "too many arguments" if $@;
	$self->{_server_root} = $v;
    }
    return $self->{_server_root} || $self->layout->apache->server_root;
}

sub mkpath {
    my ($self, $dir) = @_;
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
	return 0;
    }
    return 1;
}

sub setup {
    my ($self, %args) = @_;
    my $filename = $self->layout->incdir() . "/httpd-letsencrypt.conf";
    if (-e $filename) {
	if ($args{force}) {
	    error("the file \"$filename\" already exists",
	 	  prefix => 'warning');
	} else {
	    error("the file \"$filename\" already exists");
	    error("use --force to continue");
	    return 0;
	}
    }
    my $www_root = $self->get(qw(core rootdir));
    debug(2, "writing $filename");
    unless ($args{dry_run}) {
	my $challenge_dir = "$www_root/.well-known/acme-challenge";
	my $acme_dir = "/etc/ssl/acme";

	foreach my $dir ($self->layout->incdir(), $challenge_dir, $acme_dir) {
	    unless ($self->mkpath($dir)) {
		return 0;
	    }
	}

	$self->layout->pre_setup;

	open(my $fd, '>', $filename)
	    or croak "can't open \"$filename\" for writing: $!";
	print $fd <<EOT;
<Macro LetsEncryptChallenge>
    Alias /.well-known/acme-challenge $challenge_dir
    <Directory $challenge_dir>
        Options None
        Require all granted
    </Directory>
    <IfModule mod_rewrite.c>
        RewriteEngine On
	RewriteRule /.well-known/acme-challenge - [L]
    </IfModule>
</Macro>

<Macro LetsEncryptReference \$domain>
    Use LetsEncryptChallenge
    Alias /.dummy/\$domain /dev/null
</Macro>

<Macro LetsEncryptSSL \$domain>
    SSLEngine on
    SSLProtocol all -SSLv2 -SSLv3
    SSLHonorCipherOrder on
    SSLCipherSuite ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:!DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA
    SSLCertificateFile $acme_dir/\$domain/cert.pem
    SSLCertificateKeyFile $acme_dir/\$domain/privkey.pem
    SSLCACertificateFile $acme_dir/lets-encrypt-x3-cross-signed.pem
</Macro>

<Macro LetsEncryptServer \$domain>
    ServerName \$domain
    Use LetsEncryptSSL \$domain
</Macro>

EOT
;
	close $fd;
	error("created file \"$filename\"", prefix => 'note');
	
	$self->layout->post_setup($filename);
    }

    my $pfx = "please,";
    unless ($self->is_letsencryptssl_defined) {
	error("please, make sure your Apache configuration includes this file",
	      prefix => 'note');
	$pfx = "and";
    }
    
    unless ($self->layout->apache_modules('macro')) {
	error("$pfx enable mod_macro",
	      prefix => 'note');
    }
    return 1;
}

# Check if LetsEncryptSSL macro is defined
sub is_letsencryptssl_defined {
    my ($self) = @_;
    my $app = new Apache::Config::Preproc(
	$self->layout->config_file,
	-expand => [ 'compact',
		     { 'include' => [ server_root => $self->server_root ] },
		     { 'macro' => [
			   'keep' => [ qw(LetsEncryptChallenge
                                          LetsEncryptReference
                                          LetsEncryptSSL)
			   ]
		       ]
		     }
	]);
    if ($app) {
	return grep { $_->value =~ m{^(?i)letsencryptssl\s+} }
	   $app->section(-name => "macro");
    } else {
	debug(1, $Apache::Admin::Config::ERROR);
	return undef
    }
}

1;
