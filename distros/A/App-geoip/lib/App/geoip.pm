#!/pro/bin/perl

use 5.14.0;
use warnings;

our $VERSION = "0.13";
our $CMD = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD [--fetch] [--no-update] [--dist] [--whois] ip|host ...";
    say "   -f   --fetch        Fetch new ZIP sources";
    say "        --no-update    Do not update the database on new data";
    say "   -s   --short        Skip location and flags";
    say "   -d   --dist         Show distance in KM between here and there";
    say "                       will only work if LWP::UserAgent and";
    say "                       HTML::TreeBuilder are installed";
    say "   -w   --whois        Show whois information";
    say "                       will only work if Net::Whois::IP is installed";
    say "   -j   --json         Output information in JSON";
    say "   -J   --json-pretty  Output information in JSON";
    say "   -lL  --local=L      Specify local location LAT/LON";
    say "   -D   --DB=dsn       Specify geoip database DSN default: dbi:Pg:geoip";
    say "                       may be specified in \$GEOIP_DBI_DSN";
    say "        --country=c    Find CIRDR's for country c";
    say "$CMD --man will show the full manual";
    exit $err;
    } # usage

# Required modules
use DBI;
use Socket;
use Net::CIDR;
use Data::Dumper;
use Math::Trig;
use LWP::Simple;
use Archive::Zip;
use Text::CSV_XS qw( csv );
use JSON::PP;
use Pod::Usage;
use Getopt::Long qw(:config bundling);

# Optional modules
my $gis = eval {
    require GIS::Distance;
    GIS::Distance->new;
    };
my $use_data_peek = eval {
    require Data::Peek;
    1;
    };
my $whois = eval {
    require Net::Whois::IP;
    \&Net::Whois::IP::whoisip_query;
    };

my %conf = (
    update		=> 1,
    distance		=> 0,
    whois		=> 0,
    short		=> 0,
    json		=> 0,
    json_pretty		=> 0,
    local_location	=> undef,
    dsn			=> $ENV{GEOIP_DBI_DSN} || "dbi:Pg:dbname=geoip",
    );
getconf ();

GetOptions (
    "help|?"		=> sub { usage (0); },
    "V|version"		=> sub { say "$CMD [$VERSION]"; exit 0; },

    "u|update!"		=> \$conf{update},
    "f|fetch!"		=> \$conf{fetch},
    "d|dist|distance!"	=> \$conf{distance},
    "w|whois!"		=> \$conf{whois},
    "s|short!"		=> \$conf{short},
    "j|json!"		=> \$conf{json},
    "J|json-pretty!"	=> \ my $opt_J,
    "l|local=s"		=> \$conf{local_location},

    "D|DB=s"		=> \$conf{dsn},

    # Queries
      "country=s"	=> \ my $query_c,

    "v|verbose:1"	=> \(my $opt_v = 0),
      "man"		=> sub { pod2usage (-verbose => 2, -exitstatus => 0); },
    ) or usage (1);

$opt_v >= 7 and _dump ("Configuration", \%conf);

if (defined $opt_J) {
    if ($opt_J) {
	$conf{json_pretty}++;
	$conf{json}++;
	}
    else {
	$conf{json_pretty} = 0;
	}
    }
$conf{json} and $opt_J = $conf{json_pretty};

my $dbh = eval {
    my %seen;
    my $fail = sub { my $e = DBI->errstr or return; !$seen{$e}++ and warn "$e\n"; };
    local $SIG{__WARN__} = $fail;
    local $SIG{__DIE__}  = $fail;
    DBI->connect ($conf{dsn}, undef, undef, {
	AutoCommit		=> 0,
	RaiseError		=> 1,
	PrintError		=> 1,
	ShowErrorStatement	=> 1,
	});
    } or die "Cannot continue without a working database\n";

sub _dump {
    my ($label, $ref) = @_;
    print STDERR $use_data_peek
	? Data::Peek::DDumper ({ $label => $ref })
	: Data::Dumper->Dump ([$ref], [$label]);
    } # _dump

# Based on GeoIP2 CSV databases
#  City:   http://geolite.maxmind.com/download/geoip/database/GeoLite2-City-CSV.zip
#  Country http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country-CSV.zip
#  ASN     http://geolite.maxmind.com/download/geoip/database/GeoLite2-ASN-CSV.zip

my $idx_type = $conf{dsn} =~ m/:Pg/     ? "using btree" : "";
my $truncate = $conf{dsn} =~ m/:SQLite/ ? "delete from" : "truncate table";

unless (grep m/\b country \b/ix => $dbh->tables (undef, undef, undef, undef)) {
    say "Create table stamps";
    $dbh->do (qq; create table stamps (                                                                                                                                       
	name		text		not null	primary key,
	stamp		bigint);
	);
    say "Create table continent";
    $dbh->do (qq; create table continent (                                                                                                                                       
	id		char (4)	not null	primary key,
	name		text);
	);
    say "Create table country";
    $dbh->do (qq; create table country (                                                                                                                                       
	id		bigint		not null	primary key,
	name		text		not null,
	iso		text,
	continent	char (4),
	eu		smallint);
	);
    say "Create table ipv4"; # Country based
    $dbh->do (qq; create table ipv4 (                                                                                                                                       
	cidr		cidr		not null	primary key,
	id		bigint,
	ip_from		text		not null,
	ip_to		text		not null,
	ip_from_n	bigint		not null,
	ip_to_n		bigint		not null,
	reg_country_id	bigint,
	rep_country_id	bigint,
	anon_proxy	smallint,
	satellite	smallint);
	);
    $dbh->do (qq; create index i_ipv4_ip on ipv4 $idx_type (ip_from_n, ip_to_n););
    say "Create table provider";
    $dbh->do (qq; create table provider (                                                                                                                                       
	cidr		cidr		not null	primary key,
	id		bigint,
	name		text,
	ip_from		text,
	ip_to		text,
	ip_from_n	bigint,
	ip_to_n		bigint);
	);
    $dbh->do (qq; create index i_provider_ip on provider $idx_type (ip_from_n, ip_to_n););
    say "Create table city";
    $dbh->do (qq; create table city (                                                                                                                                       
	id		bigint		not null	primary key,
	name		text,
	country_id	bigint,
	metro_code	text,
	tz		text,
	eu		smallint);
	);
    say "Create table ipc4"; # City based
    $dbh->do (qq; create table ipc4 (                                                                                                                                       
	cidr		cidr		not null	primary key,
	id		bigint,
	ip_from		text		not null,
	ip_to		text		not null,
	ip_from_n	bigint		not null,
	ip_to_n		bigint		not null,
	reg_country_id	bigint,
	rep_country_id	bigint,
	anon_proxy	smallint,
	satellite	smallint,
	postal_code	text,
	latitude	text,
	longitude	text,
	accuracy	text );
	);
    $dbh->do (qq; create index i_ipc4_ip on ipv4 $idx_type (ip_from_n, ip_to_n););
    $dbh->commit;

    # grant connect on database geoip             to other_user;
    # grant select on all tables in schema public to other_user;
    }

my %cont; # Continents

my %stmp;
{   my $sth = $dbh->prepare ("select name, stamp from stamps");
    $sth->execute;
    while (my @s = $sth->fetchrow_array) {
	$stmp{$s[0]} = $s[1];
	}
    }

sub dtsz {
    my $f = shift;
    -f $f or return "-";
    my @s = stat $f;
    my @d = localtime $s[9];
    sprintf "%4d-%02d-%02d %02d:%02d:%02d %9d",
	$d[5] + 1900, ++$d[4], @d[3,2,1,0], $s[7];
    } # dtsz

if ($conf{fetch}) {
    my $key = $conf{license_key} or die "No license key in config file\n";
    my $base = "https://download.maxmind.com/app/geoip_download?edition_id=";
    foreach my $db (qw(	GeoLite2-ASN-CSV
			GeoLite2-Country-CSV
			GeoLite2-City-CSV
			)) {
	my $f = "$db.zip";
	printf STDERR     "%34s %s\n",     dtsz ($f), $f;
	my $url = join "&" => "$base$db", "license_key=$key", "suffix=zip";
	$opt_v > 5 and warn "Fetching $url ...\n";
	my $c = mirror ($url, $f);
	printf STDERR "%4d %29s %s\n", $c, dtsz ($f), $f;
	}
    }

my $zcfn = "GeoLite2-Country-CSV.zip";
if ($conf{update} && -s $zcfn and ($stmp{$zcfn} // -1) < (stat $zcfn)[9]) {
    my $zip = Archive::Zip->new;
    $zip->read ($zcfn)		and die "Cannot unzip $zcfn\n";
    my @cmn = $zip->memberNames	or  die "$zcfn hasd no members\n";

    say "Reading Country       info ...";
    my %ctry;
    $dbh->do ("$truncate continent");
    foreach my $cnm (grep m{\bGeoLite2-Country-Locations-en.csv$}i => @cmn) {
	my $m = $zip->memberNamed ($cnm)	or next;
	my $c = $m->contents			or next;
	# geoname_id,locale_code,continent_code,continent_name,country_iso_code,country_name,is_in_european_union
	# 49518,en,AF,Africa,RW,Rwanda,0
	csv (in => \$c, headers => "auto", out => undef, on_in => sub {
	    $cont{$_{continent_code}} ||= $_{continent_name};
	    my $id = $_{geoname_id} or return;
	    my $ctry = {
		id		=> $id,
		name		=> $_{country_name},
		iso		=> $_{country_iso_code},
		continent	=> $_{continent_code},
		eu		=> $_{is_in_european_union},
		};
	    $ctry{$id} //= $ctry;
	    #$ctry{$_{country_iso_code}} //= $ctry;
	    });
	}
    {	$dbh->do ("$truncate continent");
	$dbh->commit;
	my $sti = $dbh->prepare ("insert into continent values (?, ?)");
	$sti->execute ($_, $cont{$_}) for keys %cont;
	$sti->finish;
	$dbh->commit;
	}
    {	$dbh->do ("$truncate country");
	$dbh->commit;
	my $sti = $dbh->prepare ("insert into country values (?, ?, ?, ?, ?)");
	$sti->execute (@{$_}{qw( id name iso continent eu )}) for values %ctry;
	$sti->finish;
	$dbh->commit;
	}

    say "Reading Country  IPv4 info ...";
    foreach my $cnm (grep m{\bGeoLite2-Country-Blocks-IPv4.csv$}i => @cmn) {
	my $m = $zip->memberNamed ($cnm)	or next;
	my $c = $m->contents			or next;
	# network,geoname_id,registered_country_geoname_id,represented_country_geoname_id,is_anonymous_proxy,is_satellite_provider
	# 1.0.0.0/24,2077456,2077456,,0,0
	$dbh->do ("$truncate ipv4");
	$dbh->commit;
	my $n;
	my $sti = $dbh->prepare ("insert into ipv4 values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
	csv (in => \$c, headers => "auto", out => undef, on_in => sub {
	    ++$n % 1000 or print STDERR " $n\r";
	    my $cidr = $_{network};
	    my @rng = Net::CIDR::cidr2range ($cidr);
	    my ($f, $t) = split m/\s*-\s*/ => $rng[0];
	    my ($F, $T) = map { unpack "L>", inet_aton $_ } $f, $t;
	    my $rec = {
		cidr		=> $cidr,
		id		=> $_{geoname_id} || undef,
		ip_from		=> $f,
		ip_to		=> $t,
		ip_from_n	=> $F,
		ip_to_n		=> $T,
		reg_country_id	=> $_{registered_country_geoname_id}  || undef,
		rep_country_id	=> $_{represented_country_geoname_id} || undef,
		anon_proxy	=> $_{is_anonymous_proxy},
		satellite	=> $_{is_satellite_provider},
		};
	    $sti->execute (@{$rec}{qw( cidr id ip_from ip_to ip_from_n ip_to_n
		reg_country_id rep_country_id anon_proxy satellite )});
	    });
	$sti->finish;
	$dbh->commit;
	}
    my $t = (stat $zcfn)[9];
    if ($stmp{$zcfn}) {
	$dbh->do ("update stamps set stamp = $t where name = '$zcfn'");
	}
    else {
	$dbh->do ("insert into stamps values ('$zcfn', $t)");
	}
    $dbh->commit;
    }
else {
    my $sth = $dbh->prepare ("select * from continent");
    $sth->execute;
    while (my $r = $sth->fetch) {
	$cont{$r->[0]} = $r->[1];
	}
    }

$zcfn = "GeoLite2-ASN-CSV.zip";
if ($conf{update} && -s $zcfn and ($stmp{$zcfn} // -1) < (stat $zcfn)[9]) {
    my $zip = Archive::Zip->new;
    $zip->read ($zcfn)		and die "Cannot unzip $zcfn\n";
    my @cmn = $zip->memberNames	or  die "$zcfn hasd no members\n";

    say "Reading Provider IPv4 info ...";
    foreach my $cnm (grep m{\bGeoLite2-ASN-Blocks-IPv4.csv$}i => @cmn) {
	my $m = $zip->memberNamed ($cnm)	or next;
	my $c = $m->contents			or next;
	# network,autonomous_system_number,autonomous_system_organization
	# 1.0.0.0/24,13335,"Cloudflare, Inc."
	$dbh->do ("$truncate provider");
	$dbh->commit;
	my $n;
	my $sti = $dbh->prepare ("insert into provider values (?, ?, ?, ?, ?, ?, ?)");
	csv (in => \$c, headers => "auto", out => undef, on_in => sub {
	    ++$n % 1000 or print STDERR " $n\r";
	    my $cidr = $_{network};
	    my @rng = Net::CIDR::cidr2range ($cidr);
	    my ($f, $t) = split m/\s*-\s*/ => $rng[0];
	    my ($F, $T) = map { unpack "L>", inet_aton $_ } $f, $t;
	    my $rec = {
		cidr		=> $cidr,
		id		=> $_{autonomous_system_number} || undef, # All NULL
		name		=> $_{autonomous_system_organization},
		ip_from		=> $f,
		ip_to		=> $t,
		ip_from_n	=> $F,
		ip_to_n		=> $T,
		};
	    $sti->execute (@{$rec}{qw( cidr id name ip_from ip_to ip_from_n ip_to_n )});
	    });
	$sti->finish;
	$dbh->commit;
	}
    my $t = (stat $zcfn)[9];
    if ($stmp{$zcfn}) {
	$dbh->do ("update stamps set stamp = $t where name = '$zcfn'");
	}
    else {
	$dbh->do ("insert into stamps values ('$zcfn', $t)");
	}
    $dbh->commit;
    }

$zcfn = "GeoLite2-City-CSV.zip";
if ($conf{update} && -s $zcfn and ($stmp{$zcfn} // -1) < (stat $zcfn)[9]) {
    my $zip = Archive::Zip->new;
    $zip->read ($zcfn)		and die "Cannot unzip $zcfn\n";
    my @cmn = $zip->memberNames	or  die "$zcfn hasd no members\n";

    say "Reading City          info ...";
    my (%country, %city);
    {	my $sth = $dbh->prepare ("select id, name from country");
	$sth->execute;
	while (my $r = $sth->fetch) { $country{$r->[1]} = $r->[0] }
	}
    foreach my $cnm (grep m{\bGeoLite2-City-Locations-en.csv$}i => @cmn) {
	my $m = $zip->memberNamed ($cnm)	or next;
	my $c = $m->contents			or next;
	# geoname_id,locale_code,continent_code,continent_name,country_iso_code,
	#   country_name,subdivision_1_iso_code,subdivision_1_name,
	#   subdivision_2_iso_code,subdivision_2_name,city_name,metro_code,
	#   time_zone,is_in_european_union
	# 5819,en,EU,Europe,CY,Cyprus,02,Limassol,,,Souni,,Asia/Nicosia,1
	$dbh->do ("$truncate city");
	$dbh->commit;
	my $n;
	my $sti = $dbh->prepare ("insert into city values (?, ?, ?, ?, ?, ?)");
	csv (in => \$c, headers => "auto", out => undef, on_in => sub {
	    ++$n % 1000 or print STDERR " $n\r";
	    my $rec = {
		id		=> $_{geoname_id},
		name		=> $_{city_name},
		country_id	=> $country{$_{country_name}},
		metro_code	=> $_{metro_code},
		tz		=> $_{time_zone},
		eu		=> $_{is_in_european_union},
		};
	    # Subdivisions to store?
	    $sti->execute (@{$rec}{qw( id name country_id metro_code tz eu )});
	    });
	$sti->finish;
	$dbh->commit;
	}
    say "Reading City     IPv4 info ...";
    foreach my $cnm (grep m{\bGeoLite2-City-Blocks-IPv4.csv$}i => @cmn) {
	my $m = $zip->memberNamed ($cnm)	or next;
	my $c = $m->contents			or next;
	# network,geoname_id,registered_country_geoname_id,
	#   represented_country_geoname_id,is_anonymous_proxy,
	#   is_satellite_provider,postal_code,latitude,longitude,accuracy_radius
	# 1.0.0.0/24,2062391,2077456,,0,0,5412,-34.1551,138.7482,1000
	$dbh->do ("$truncate ipc4");
	$dbh->commit;
	my $n;
	my $sti = $dbh->prepare ("insert into ipc4 values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
	csv (in => \$c, headers => "auto", out => undef, on_in => sub {
	    ++$n % 1000 or print STDERR " $n\r";
	    my $cidr = $_{network};
	    my @rng = Net::CIDR::cidr2range ($cidr);
	    my ($f, $t) = split m/\s*-\s*/ => $rng[0];
	    my ($F, $T) = map { unpack "L>", inet_aton $_ } $f, $t;
	    my $rec = {
		cidr		=> $cidr,
		id		=> $_{geoname_id} || undef,
		ip_from		=> $f,
		ip_to		=> $t,
		ip_from_n	=> $F,
		ip_to_n		=> $T,
		reg_country_id	=> $_{registered_country_geoname_id}  || undef,
		rep_country_id	=> $_{represented_country_geoname_id} || undef,
		anon_proxy	=> $_{is_anonymous_proxy},
		satellite	=> $_{is_satellite_provider},
		postal_code	=> $_{postal_code},
		latitude	=> $_{latitude},
		longitude	=> $_{longitude},
		accuracy	=> $_{accuracy_radius},
		};
	    $sti->execute (@{$rec}{qw( cidr id ip_from ip_to ip_from_n ip_to_n
		reg_country_id rep_country_id anon_proxy satellite postal_code
		latitude longitude accuracy )});
	    });
	$sti->finish;
	$dbh->commit;
	}
    my $t = (stat $zcfn)[9];
    if ($stmp{$zcfn}) {
	$dbh->do ("update stamps set stamp = $t where name = '$zcfn'");
	}
    else {
	$dbh->do ("insert into stamps values ('$zcfn', $t)");
	}
    $dbh->commit;
    }

binmode STDERR, ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

if ($query_c) {
    @ARGV = ();
    my %ctry;
    my $sth = $dbh->prepare ("select id, name, continent from country");
    $sth->execute;
    $sth->bind_columns (\my ($id, $name, $cont));
    while ($sth->fetch) {
	$name =~ m/^ $query_c $/ix and $ctry{full}{$id} = [ $name, $cont, 0, 0 ];
	$name =~ m/  $query_c  /ix and $ctry{part}{$id} = [ $name, $cont, 0, 0 ];
	}
    $sth->finish;
    if    (keys %{$ctry{full}}) {
	%ctry = %{$ctry{full}};
	}
    elsif (keys %{$ctry{part}}) {
	%ctry = %{$ctry{part}};
	}
    else {
	$dbh->rollback;
	die "No matching country found for $query_c\n";
	}

    $sth = $dbh->prepare (join " " =>
	"select   cidr, reg_country_id, ip_from_n, ip_to_n",
	"from     ipv4",
	"order by reg_country_id, cidr");
    $sth->execute;
    $sth->bind_columns (\my $cidr, \$id, \my $from, \my $to);
    while ($sth->fetch) {
	defined $id or next;
	my $c = $ctry{$id} or next;
	say $cidr;
	$c->[2]++;
	$c->[3] += $to - $from + 1;
	}
    $sth->finish;
    $dbh->rollback;

    if ($opt_v) {
	my @w = (6, 10, 40, 15);
	printf STDERR "%s\n%$w[0]s %$w[1]s %-$w[2]s %s\n%s %s %s %s\n",
	    "Selected CIDR's", "# CIDR", "# IP", "Country", "Continent",
	    map { "-" x $_ } @w;
	printf STDERR "%$w[0]d %$w[1]d %-$w[2].$w[2]s %s\n",
	    @{$_}[2, 3, 0], $cont{$_->[1]} for
		sort { $a->[0] cmp $b->[0] } values %ctry;
	}

    exit 0;
    }

my %seen;
my %found;
while (@ARGV) {
    my $ip = shift or next;

    my $host;
    if ($ip =~ m/^\d{1,3}(?:\.\d{1,3}){3}$/ and my $n = inet_aton ($ip)) {
	$seen{$ip}++;
	# We might not have DNS when working off-line
	$host = gethostbyaddr ($n, AF_INET) and $seen{$host}++;
	}
    else {
	my ($name, $aliases, $type, $len, @addr) = gethostbyname ($ip);
	unless (@addr) {
	    warn "Cannot get the IP for $ip\n";
	    next;
	    }
	$host = $name;
	$ip = inet_ntoa (shift @addr);
	$seen{$ip}++;
	$seen{$host}++;
	push @ARGV, grep { $_ && !$seen{$_}++ }
	    (map { inet_ntoa $_ } @addr),
	    split m/\s+/ => $aliases;
	}

    $found{$ip} and next;

    my $in = unpack "L>" => inet_aton ($ip);
    #say "Look up $ip ($in) ...";

    my $sth = $dbh->prepare ("select * from ipv4 where ip_from_n <= $in and ip_to_n >= $in");
    my $stc = $dbh->prepare ("select * from country where id = ?");
    my $stC = $dbh->prepare ("select * from city    where id = ?");
    my $prov = do {
	my $stp = $dbh->prepare ("select name from provider where ip_from_n <= $in and ip_to_n >= $in");
	$stp->execute;
	my @p; while (my $p = $stp->fetch) { push @p, $p->[0]; }
	join " \x{2227} " => @p;
	};
    my $st4 = $dbh->prepare ("select * from ipc4 where ip_from_n <= $in and ip_to_n >= $in");
    $sth->execute;
    while (my $i = $sth->fetchrow_hashref) {
	$i->{provider} = $prov;
	$i->{ip}       = $ip;
	$i->{ip_n}     = $in;
	$i->{hostname} = $host // "(hostname not found)";
	foreach my $tp ("reg", "rep") {
	    if (my $cid = delete $i->{"${tp}_country_id"}) {
		$stc->execute ($cid);
		my $c = $stc->fetchrow_hashref or next;
		$i->{"${tp}_ctry_$_"} = $c->{$_} for keys %$c;
		delete $i->{"${tp}_ctry_id"};
		}
	    else {
		$i->{"${tp}_ctry_$_"} = "" for qw( iso name continent );
		}
	    $i->{"${tp}_continent"} = $cont{delete $i->{"${tp}_ctry_continent"}} || "";
	    }
	$st4->execute;
	if (my $c = $st4->fetchrow_hashref) {
	    $stc->execute (delete $c->{reg_country_id});
	    if (my $ctry = $stc->fetchrow_hashref) {
		$c->{country} = $ctry->{name};
		}
	    $i->{$_} = $c->{$_} for qw( postal_code latitude longitude accuracy );
	    $stC->execute (delete $c->{id});
	    if (my $city = $stC->fetchrow_hashref) {
		$i->{"city_$_"} = $city->{$_} for qw( name tz metro_code );
		}
	    $stC->finish;
	    }
	$st4->finish;
	$found{$ip} //= $i;
	}
    $stc->finish;
    }

my $here;
if (($conf{local_location} // "") =~ m{^(-?\d+\.\d+)\s*[,/]\s*(-?\d+\.\d+)\s*$}) {
    $here = { Latitude => $1, Longitude => $2 };
    }
elsif ($conf{distance} and eval { require LWP::UserAgent; require HTML::TreeBuilder; }) {
    my $ua = LWP::UserAgent->new (
	max_redirect => 2,
	agent        => "geoip/$VERSION",
	parse_head   => 0,
	timeout      => 10,
	cookie_jar   => {},
	);
    $ua->env_proxy;
    warn "Using GeoIP to determine own location\n";
    $here = {};
    my %cls = (
	lat	=> "Latitude",
	lng	=> "Longitude",
	ip	=> "IP",
	city	=> "City",
	company	=> "Provider",
	);
    foreach my $url (qw( https://iplocation.com https://geoiptool.com )) {
	my $rsp = $ua->request (HTTP::Request->new (GET => $url));
	if ($rsp->is_success) {
	    $opt_v > 1 and warn "$url: OK\n";
	    my $tree = HTML::TreeBuilder->new ();
	    if ($tree->parse_content ($rsp->content)) {
		foreach my $e ($tree->look_down (_tag => "div", class => "data-item")) {
		    my $di = $e->as_text or next;
		    $di =~ m/^\s*(\S[^:]+?)\s*:\s*(.*?)\s*$/ and $here->{$1} //= $2;
		    }
		foreach my $e ($tree->look_down (_tag => "td",
				class => qr{^(?:lat|lng|ip|city|company)$})) {
		    my $di = $e->as_text =~ s/^\s+//r =~ s/\s+$//r or next;
		    my $cl = $cls{$e->attr ("class")} or next;
		    $here->{$cl} //= $di;
		    }
		}
	    }
	elsif ($opt_v) {
	    printf STDERR "%-25s : %s\n", $url, $rsp->status_line;
	    }
	defined $here->{Longitude} and last;
	}
    unless (exists $here->{Longitude}) {
	# If I did not get info, use the database:
	# 1: dig -4 a +short myip.opendns.com @resolver1.opendns.com
	# 2: https://tools.tracemyip.org - only returns IP, no coordinates
	#    <div class="tsTxt14 txtBld"><span class="txtBld tsTxt14 sModPrW"><a href="/lookup/1.2.3.4">1.2.3.4</a></span></div>
	}
    defined $here->{Longitude} or $here = undef;
    $opt_v > 4 and _dump ("Here", $here);
    }

my @json;
for (sort { $a->{ip_from_n} <=> $b->{ip_to_n} ||
	    $a->{ip_n}      <=> $b->{ip_n}
	  } values %found) {
    $opt_v > 6 and _dump ("Processing", $_);
    my ($lat, $lon, $acc) = ($_->{latitude}, $_->{longitude}, $_->{accuracy});
    $_->{city} = join ", " => grep m/\S/ => map { $_ || "" }
	$_->{city_name}, $_->{city_metro_code}, $_->{postal_code};
    $_->{city_tz} ||= "";
    my %json = %$_;

    unless ($conf{json}) {
	say "GeoIP data for $_->{ip} - $_->{hostname}:";
	say "   CIDR      : $_->{cidr}";
	say "   IP range  : $_->{ip_from} - $_->{ip_to}";
	say "   Provider  : $_->{provider}";
	say "   City      : $_->{city}";
	say "   Country   : $_->{reg_ctry_iso}  $_->{reg_ctry_name}";
	say "   Continent : $_->{reg_continent}";
	say "   Timezone  : $_->{city_tz}";
	}

    if (!$conf{short} && ($lat || $lon)) {
	my ($lat_dms, $lon_dms) = map { dec2dms ($_) } $lat, $lon;
	@json{qw( latitude_dms longitude_dms )} = ($lat_dms, $lon_dms);
	$conf{json} or printf "   Location  : %9.4f / %9.4f %-6s %14s / %14s\n",
	    $lat, $lon, "($acc)", $lat_dms, $lon_dms;
	# OSM max zoom = 19, Google Maps max zoom = 21
	my $z = 16 - int log $acc;
	my @map = (
	    "https://www.openstreetmap.org/#map=$z/$lat/$lon",
	    "https://www.google.com/maps/place/\@$lat,$lon,${z}z",
	    );
	$json{map_urls} = \@map;
	$conf{json} or say "               $_" for @map;

	if ($here) {
	    my ($llat, $llon) = ($here->{Latitude}, $here->{Longitude});
	    my ($llat_dms, $llon_dms) = map { dec2dms ($_) } $llat, $llon;
	    my ($dist, $unit) = (distance ($lat, $lon, $llat, $llon), "km");
	    ($conf{distance} || "km") eq "miles" and
		($dist, $unit) = ($dist * 0.62137119, "mile");
	    @json{qw( local_latitude local_longitude
		      local_latidue_dms local_longitude_dms
		      distance distance_unit )} =
		($llat, $llon, $llat_dms, $llon_dms, $dist, $unit);
	    $conf{json} or printf "   Location  : %9.4f / %9.4f %-6s %14s / %14s\n",
		$llat, $llon, "", $llat_dms, $llon_dms;
	    $conf{json} or printf "   Distance  : \x{00b1} %.2f%s\n", $dist, $unit;
	    }
	}
    if (!$conf{short} && $conf{whois} && $whois and my $wi = $whois->($_->{ip})) {
	my $address = join " " => grep { length } map { $wi->{$_} } qw(
	    Address PostalCode StateProv Country address );
	my %w = (
	    ID      => $wi->{OrgId}         || $wi->{"admin-c"},
	    Name    => $wi->{OrgNOCName}    || $wi->{OrgName}      || $wi->{descr},
	    Phone   => $wi->{OrgNOCPhone}   || $wi->{OrgTechPhone} || $wi->{phone},
	    EMail   => $wi->{OrgTechEmail}  || $wi->{OrgNOCEmail}  || $wi->{"e-mail"},
	    Abuse   => $wi->{OrgAbuseEmail} || $wi->{"abuse-mailbox"},
	    Address => $address,
	    );

	$opt_v > 8 and _dump ("WhoIs", { wi => $wi, w => \%w });
	my @wi = map { sprintf "     %-7s : %s", $_, $w{$_} }
	         grep { length $w{$_} } qw( Name ID Phone EMail Abuse Address );
	$json{whois} = \%w;
	!$conf{json} && @wi and say for "   Whois information:", @wi;
	}
    if ($conf{json}) {
	push @json, \%json;
	}
    elsif (!$conf{short}) {
	say "   EU member : ", $_->{reg_ctry_eu} ? "Yes" : "No";
	say "   Satellite : ", $_->{satellite}   ? "Yes" : "No";
	say "   Anon Proxy: ", $_->{anon_proxy}  ? "Yes" : "No";
	}
    }

$dbh->rollback;
$dbh->disconnect;

if ($conf{json}) {
    say $opt_J
	? JSON::PP->new->pretty->allow_nonref->encode (\@json)
	: JSON::PP->new->ascii ->allow_nonref->encode (\@json);
    }

sub dec2dms {
    my $dec = shift or return "";

    my $deg = int $dec;
    my $dm  = abs ($dec - $deg) * 60;
    my $min = int $dm;
    my $sec = ($dm - $min) * 60;
    sprintf "%d\x{00b0}%02d'%05.2f\"", $deg, $min, $sec;
    } # dec2dms

sub distance {
    my ($lat_c, $lon_c, $lat_s, $lon_s) = @_;

    $gis and
	return $gis->distance ($lat_c, $lon_c, $lat_s, $lon_s)->meters / 1000.;

    my $rad = 6371; # km

    # Convert angles from degrees to radians
    my $dlat = deg2rad ($lat_s - $lat_c);
    my $dlon = deg2rad ($lon_s - $lon_c);

    my $x = sin ($dlat / 2) * sin ($dlat / 2) +
	    cos (deg2rad ($lat_c)) * cos (deg2rad ($lat_s)) *
		sin ($dlon / 2) * sin ($dlon / 2);

    return $rad * 2 * atan2 (sqrt ($x), sqrt (1 - $x)); # km
    } # distance

sub getconf {
    my $home = $ENV{HOME} || $ENV{USERPROFILE} || $ENV{HOMEPATH};
    foreach my $rcf (grep { -s }
            "$home/geoip.rc", "$home/.geoiprc", "$home/.config/geoip") {
        my $mode = (stat $rcf)[2];
        $mode & 022 and next;
        open my $fh, "<", $rcf or next;
        while (<$fh>) {
            m/^\s*[;#]/ and next;
            my ($k, $v) = (m/^\s*([-\w]+)\s*[:=]\s*(.*\S)/) or next;
            $conf{ lc $k
                =~ s{-}{_}gr
                =~ s{^use_}{}ir
                =~ s{^(json_)?(?:unicode|utf-?8?)$}{utf8}ir
                =~ s{^dist$}{distance}ir
              } = $v
                =~ s{(?:U\+?|\\[Uu])([0-9A-Fa-f]{2,7})}{chr hex $1}ger
                =~ s{^(?:no|false)$}{0}ir
                =~ s{^(?:yes|true)$}{1}ir;
            }
	}
    } # getconf

__END__

=encoding utf-8

=head1 NAME

geoip - a tool to show geological data based on hostname or IP address(es)

=head1 SYNOPSIS

 geoip --help

 geoip --fetch [--no-update]

 geoip [options] host|IP ...

=head1 DESCRIPTION

This tool uses a database to use the (pre-fetched) GeoIP2 data from MaxMind
to show related geographical information for IP addresses. This information
can optionally be extended with information from online WHOIS services and
or derived data, like distance to the location of the server this tool runs
on or a configured local location.

The output is plain text or JSON. JSON may be short or formatted.

=head2 Configuration

The tool allows the use of configuration files. It tests for existence of
the files listed here. All existing files is read (in this order) if it is
only writable by the author

   $home/geoip.rc
   $home/.geoiprc
   $home/.config/geoip

The format of the file is

  # Comment
  ; Comment
  option : value
  option = value

where the C<:> and C<=> are equal and whitespace around them is optional
and ignored. The values C<False> and C<No> (case insensitive) are the same
as C<0> and the values C<True> and C<Yes> are equal to C<1>. For readability
you can prefix C<use_> to most options (it is ignored). The use of C<-> in
option names is allowed and will be translated to C<_>.

The recognized options and the command line equivalences are

=over 2

=item fetch

command line option : C<-f> or C<--fetch>

default value       : False

Fetch new databases from the MaxMind site.

=item update

command line option : C<-u> or C<--update>

default value       : True

Only in effect when used with C<--fetch>: when new data files from MaxMind
have successfully been fetched and any of these is newer that what the
database contains, update the database with the new data.

=item distance

command line option : C<-d> or C<--distance>

default value       : False

If both the location of the tool I<and> the location of the requested IP
are known, calculate the distance between them. The default is to show
the distance in kilometers. Choosing a configuration of C<miles> instead
of C<True>, C<Yes>, or C<1> will show the distance in miles. There is no
command line option for miles.

The location of the tool is either locally stored in your configuration
(see C<--local-location>) or fetched using the result of the urls
L<C<iplocation.com>|https://iplocation.com> or
L<C<geoiptool>|https://geoiptool.com>. This will - of course - not work
if there is no network connection or outside traffic is not allowed.

=item whois

command line option : C<-w> or C<--whois>

default value       : False

If L<Net::Whois::IP> is installed, and this option is true, this module
will be used to retrieve the C<whois> information. This will not work if
there is no network connection or outside traffic is not allowed.

=item short

command line option : C<-s> or C<--short>

default value       : False

This option will disable the output of less-informative information like
location, EU-membership, satellite and proxy. This option, if True, will also 
implicitly disable the C<distance> and C<whois> information.

=item dsn

command line option : C<-Ddsn> or C<--DB=dsn>

default value       : C<$ENV{EOIP_DBI_DSN}> or C<dbi:Pg:geoip>

See L</DATABASE> for the (documented) list of supported database types.

If the connection works, the tables used by this tool will be created if
not yet present.

The order of usage is:

 1. Command line argument (C<--DB=dsn>)
 2. The C<GEOIP_DBI_DSN> environment variable
 3. The value for C<dsn> in the configuration file(s)
 4. C<dbi:Pg:dbname=geoip>

=item json

command line option : C<-j> or C<--json>

default value       : False

The default output for the information is plain text. With this option,
the output will be in JSON format. The default is not prettified.

=item json-pretty

command line option : C<-J> or C<--json-pretty>

default value       : False

If set from the command-line, this implies the C<--json> option.

With this option, JSON output is done I<pretty> (indented).

=item local-location

command line option : C<-l lat/lon> or C<--local=lat/lon>

default value       : Undefined

Sets the local location coordinates for use with distances.

When running the tool from a different location than where the IP access is
to be analyzed for or when the network connection will not report a location
that would make sense (like working from a cloud or running over one or more
VPN connections), one can set the location of the base in decimal notation.
(degree-minute-second-notation is not yet supported).

This is also useful when there is no outbound connection possible or when you
do not move location and you want to restrict network requests.

The notation is decimal (with a C<.>, no localization support) where latitude
and longitude are separated by a C</> or a C<,>, like C<-l 12.345678/-9.876543>
or C<--local=12,3456,45,6789>.

=item maxmind-account

command line option : none

default value       : Undefined

Currently not (yet) used. Documentation only.

=item license-id

command line option : none

default value       : Undefined

Currently not (yet) used. Documentation only.

=item license-key

command line option : none

default value       : Undefined

As downloads are only allowed/possible using a valid MaxMind account, you need
to provide a valid license key in your configuration file. If you do not have
an account, you can sign up L<here|https://www.maxmind.com/en/geolite2/signup>.

=back

=head1 DATABASE

Currently PostgreSQL and SQLite have been tested, but others may (or may not)
work just as well. YMMV. Note that the database need to know the C<CIDR>
field type and is able to put a primary key on it.

MariaDB and MySQL are not supported, as they do not support the concept of
CIDR type fields.

The advantage of PostgreSQL over SQLite is that you can use it with multiple
users at the same time, and that you can share the database with other hosts
on the same network behind a firewall.

The advantage of SQLite over PostgreSQL is that it is a single file that you
can copy or move to your liking. This file will be somewhere around 500 Mb.

=head1 EXAMPLES

=head2 Configuration

 $ cat ~/.config/geoip
 use_distance    : True
 json-pretty     : yes

=head2 Basic use

 $ geoip --short 1.2.3.4

=head2 For automation

 $ geoip --json --no-json-pretty 1.2.3.4

=head2 Full report

 $ geoip --dist --whois 1.2.3.4

=head2 Selecting CIDR's for countries

=head3 List all CIDR's for Vatican City

 $ geoip --country=Vatican > vatican-city.cidr

=head3 Statistics

If you enable verbosity, the selected statistics will be presented at the
end of the CIDR-list: number of CIDR's, number of enclosed IP's, name of
the country and the continent. As the country name is just a perl regex,
you can select all countries with C<.>, or all countries that start with
a C<V>:

 $ geoip --country=^V -v >/dev/null
 Selected CIDR's
 # CIDR       # IP Country               Continent
 ------ ---------- --------------------- ---------------
     21      18176 Vanuatu               Oceania
    321      13056 Vatican City          Europe
    272    6798500 Venezuela             South America
    612   16014080 Vietnam               Asia

=head1 TODO

=over 2

=item IPv6

The ZIP files also contain IPv6 information, but it is not (yet) converted
to the database, nor supported in analysis.

=item Modularization

Split up the different parts of the script to modules: fetch, extract,
check, database, external tools, reporting.

=item CPAN

Turn this into something like App::geoip, complete with Makefile.PL

=back

=head1 SEE ALSO

L<DBI>, L<Net::CIDR>, L<Math::Trig>, L<LWP::Simple>, L<Archive::ZIP>,
L<Text::CSV_XS>, L<JSON::PP>, L<GIS::Distance>, L<Net::Whois::IP>,
L<HTML::TreeBuilder>, L<Data::Dumper>, L<Data::Peek>, L<Socket>

L<Geo::Coder::HostIP>, L<Geo::IP>, L<Geo::IP2Location>, L<Geo::IP2Proxy>,
L<Geo::IP6>, L<Geo::IPfree>, L<Geo::IP::RU::IpGeoBase>, L<IP::Country>,
L<IP::Country::DB_File>, L<IP::Country::DNSBL>, L<IP::Info>, L<IP::Location>,
L<IP::QQWry>, L<IP::World>, L<Metabrik::Lookup::Iplocation>, L<Pcore::GeoIP>

Check L<CPAN|https://metacpan.org/search?q=geoip> for more.

=head1 THANKS

Thanks to cavac for the inspiration

=head1 AUTHOR

H.Merijn Brand F<E<lt>h.m.brand@xs4all.nlE<gt>>, aka Tux.

=head1 COPYRIGHT AND LICENSE

The GeoLite2 end-user license agreement, which incorporates components of the
Creative Commons Attribution-ShareAlike 4.0 International License 1) can be found
L<here|https://www.maxmind.com/en/geolite2/eula> 2). The attribution requirement
may be met by including the following in all advertising and documentation
mentioning features of or use of this database.

This tool uses, but does not include, the GeoLite2 data created by MaxMind,
available from [http://www.maxmind.com](http://www.maxmind.com).

 Copyright (C) 2018-2020 H.Merijn Brand.  All rights reserved.

This library is free software;  you can redistribute and/or modify it under
the same terms as Perl itself.
See L<https://opensource.org/licenses/Artistic-2.0|here> 3).

 1) https://creativecommons.org/licenses/by-sa/4.0/
 2) https://www.maxmind.com/en/geolite2/eula
 3) https://opensource.org/licenses/Artistic-2.0

=for elvis
:ex:se gw=75|color guide #ff0000:

=cut
