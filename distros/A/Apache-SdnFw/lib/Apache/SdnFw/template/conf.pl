if (not -e "$ENV{HTTPD_ROOT}/logs/SITENAME") {
    die "Need '$ENV{HTTPD_ROOT}/logs/SITENAME' for logging.";
}

# now put it all together
my $common = <<END;
    Errorlog        logs/SITENAME/error_log
    CustomLog       logs/SITENAME/access_log sdnfw
    DocumentRoot    "/data/SITENAME/content"
    DirectoryIndex  index.html
	PerlPassEnv		HTTPD_ROOT
    PerlSetVar  	HTTPD_ROOT $ENV{HTTPD_ROOT}
	SetEnv			HTMLDOC_NOCGI yes
	SetEnv			BASE_URL /SITENAME
	SetEnv			OBJECT_BASE SITENAME
END

my %config;
if (-f "$ENV{HTTPD_ROOT}/conf/SITENAME.conf") {
	open F, "$ENV{HTTPD_ROOT}/conf/SITENAME.conf";
	while (my $l = <F>) {
		chomp $l;
		next if ($l =~ m/^#/);
		if ($l =~ m/^([^=]+)=(.+)$/) {
			$common .= "	SetEnv	$1	$2\n";
			$config{$1} = $2;
		}
	}
	close F;
}

$config{SERVER_NAME} = 'sf.smalldognet.com' unless($config{SERVER_NAME});
$common .= "	PerlInitHandler +Apache::StatINC\n" if ($config{STATINC});

$common .= <<END;
    PerlRequire 	"$ENV{HTTPD_ROOT}/SITENAME/startup.pl"

	ServerName		$config{SERVER_NAME}

	<Location /SITENAME>
		SetHandler		perl-script
    	PerlHandler     Apache::SdnFw
	</Location>

	Options -Indexes

	RewriteEngine	on
	RewriteRule ^(.+)-r[0-9]+(\.[^/]+)\$	\$1\$2	[R]
END

print <<END;
<VirtualHost $ENV{IP_ADDR}:$ENV{HTTP_PORT}>
$common
</VirtualHost>
END
