#!/opt/bin/perl -w
############################################################
# This script generates an RSS file for recent CPAN uploads
# As well as the database name, user, and password to connect
# to the database, it requires the host name that links
# to the recent uploads will point to. Some editing of these
# links in the sections below will probably be required to
# reflect local installations.
############################################################
use strict;
use DBI;
use XML::RSS;
use HTTP::Date;
my ($db, $user, $passwd, $help, $CPAN, $file);
my $rc = GetOptions('db=s' => \$db,
                    'user=s' => \$user,
                    'passwd=s' => \$passwd,
                    'host=s' => \$CPAN,
                    'file=s' => \$file,
                    'help' => \$help);

if ($help or not ($db and $user and $passwd and $CPAN and $file)) {
    print <<"END";

    Generate RSS feed
Usage: 
   $^X $0 --db database --user me --passwd qpwoeiruty --host http://me.cpan.org/ --file /usr/local/httpd/htdocs/cpan.xml
   $^X $0 --help
END
    exit(1);
}

my $rss = XML::RSS->new(version => '1.0');
$rss->channel(
              title => 'Recent CPAN uploads',
              link => "$CPAN/recent",
              description => 'Recent CPAN uploads',
              dc => {
                     date       => time2str(time),
                     language   => 'en-us',
                    },
             );
$rss->image(
            title  => "browse and search CPAN",
            url    => "$CPAN/cpan.jpg",
            link   => "$CPAN/search",
           );

my $age = 1;
my $dbh = DBI->connect("DBI:mysql:$db", $user, $passwd) or
  die "Cannot connect to database: $DBI::errstr";
recent($age);

sub recent {
  my ($age) = @_;
  my $date = localtime;
  $date =~ s/^\w+\s+(\w+)\s+(\d+).*\s(\d+)$/$1 $2, $3/;
  (my $day = $date) =~ s!.*(\d+),.*!$1!;
  my $sql_statement = "SELECT distinct dist_name,dist_abs,DATE_FORMAT(birth, '%e %b %Y'),cpanid,fullname,dist_vers"
    . " FROM dists,auths "
      . " WHERE (to_days(now()) - to_days(birth)) <= $age "
	. " AND dists.auth_id = auths.auth_id "
	  . " ORDER BY birth desc,dist_name";
  my $sth = $dbh->prepare($sql_statement) or die $dbh->errstr;
  $sth->execute or ($sth->finish, die $dbh->errstr);
  while(my ($packname, $packdesc, $birth, $cpanid, $authname, $version) 
        = $sth->fetchrow_array) {
    my $heading = $packdesc ? "$packname-$version - $packdesc" : "$packname-$version";
    my $who = $authname ? "$cpanid ($authname)" : $cpanid;
    next unless ($heading and $birth and $who);

    $rss->add_item(
                   title       => "$packname-$version uploaded on $birth",
                   link        => "$CPAN/dist/$packname",
                   description => $heading,
                   dc => {
                          creator  => "$authname ($cpanid)",
                         },
                  );
  }
}

$rss->save($file) or die "Cannot save to $file: $!";
