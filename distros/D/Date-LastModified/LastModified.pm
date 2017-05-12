package Date::LastModified;
# ------ Return last-modified date from set of files, dirs, DBIs, etc.


# ------ pragmas
use 5.006;
use strict;
use warnings;
use AppConfig qw(:argcount);
use Date::Parse;
use File::Find;
use File::stat;


# ------ set up exported names
require Exporter;
our @ISA = qw(Exporter);	# we are an Exporter
our %EXPORT_TAGS		# but we export nothing
 = ( 'all' => [ qw() ] );
our @EXPORT_OK			# but we export nothing
 = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT			# but we export nothing
 = qw();


# ------ version information
our $VERSION = '0.60';		# our version number


# ------ define functions


# ------ return last-modified date for a file
sub dlm_file {
    my $file = shift;       # file to examine
    my $st   = stat($file); # file status info

    return $st->mtime;
}


# ------ package for directory handling
{
    package Date::LastModified::Directory;
    use File::stat;

    my $last = 0;           # last modification date

    # ------ reset last modification date
    sub reset_last {
        $last = 0;
    }

    # ------ return last modification date
    sub get_last {
        return $last;
    }

    # ------ File::Find "wanted" function
    sub wanted {
        my $st = stat($_);  # file status info

        return if (m#/..$/# || m#^..$#);
        if ($st->mtime > $last) {
            $last = $st->mtime;
        }
    }
}


# ------ return last-modified date for a directory
sub dlm_dir {
    my $dir = shift;        # directory to examine

    # NOTE: "no_chdir" is friendly to Win32
    Date::LastModified::Directory::reset_last();
    find(
     { wanted   => \&Date::LastModified::Directory::wanted,
       no_chdir => 1 },
      $dir);
    return Date::LastModified::Directory::get_last;
}


# ------ phrasebook for extracting Unix time from database
my $unix_time =
    {   "Oracle" =>                 # Oracle database
        {   "time"                  # time extraction phrase
            => "TO_CHAR(..., 'YYYY-MM-DD HH24:MI:SS')",
            "parse_date"            # have to parse date to get Unix time
            => 1
        },
        "mysql" =>                  # MySQL database
        {   "time"                  # time extraction phrase
            => "UNIX_TIMESTAMP(...)",
            "parse_date"            # have to parse date to get Unix time
            => 0
        },
        "SQLite" =>                 # SQLite database
        {   "time"                  # time extraction phrase
            => "...",               # SQLite is typeless
            "parse_date"            # have to parse date to get Unix time
            => 1
        },
        "SQL92" =>                  # pseudo-entry for SQL92 databases
        {   "time"                  # time extraction phrase
            => "CAST(... AS CHAR)",
            "parse_date"            # have to parse date to get Unix time
            => 1
        }
    };


# ------ DBI error handler
sub dbi_error {
    my $err = "";                   # error string

    if (defined($err) && $err !~ m/^\s*$/) {
        die "Database fatal error: $err\n";
    }
}


# ------ return last-modified date from a database table via DBI
sub dlm_dbi {
    my $dbi         = shift;        # DBI database connection info
    my $cfg         = "";           # DB username/password config object
    my $column      = "";           # column name for date
    my $dbh         = "";           # database handle
    my $dbd         = "";           # database driver
    my $connect     = "";           # DBI database connect string
    my $last        = "";           # last-modified date
    my $passfile    = "";           # password filename
    my $password    = "";           # database password
    my $sql         = "";           # SQL template for extracting date
    my $sth         = "";           # database statement handle
    my $table       = "";           # table with last-modified date
    my $time_phrase = "";           # time extraction SQL phrase
    my @tokens      = ();           # tokens from DB extract-date string
    my $username    = "";           # database username

    # ------ extract database connection information
    @tokens = split(',', $dbi);
    if (scalar(@tokens) >= 5) {
        ($connect,$username,$password,$table,$column) = @tokens;
    } elsif (scalar(@tokens) == 4) {
        ($connect,$passfile,$table,$column)           = @tokens;
    } else {
        die "Sorry, I can't find my database connection info in '$dbi'\n";
    }
    if ($passfile !~ m/^\s*$/) {
        $cfg
         = new AppConfig( {
         CREATE => 1,
         ERROR  =>
          \&AppConfig_err,
         } );
        $cfg->define("DbUsername",
         { ARGCOUNT => ARGCOUNT_ONE } );
        $cfg->define("DbPassword",
         { ARGCOUNT => ARGCOUNT_ONE } );
        if (!$cfg->file($passfile)) {
            die "can't read '$passfile'\n";
        }
        $username = $cfg->get("DbUsername");
        $password = $cfg->get("DbPassword");
    }

    # ------ connect to specified database
    $dbh = DBI->connect($connect,$username,$password);
    if (!defined($dbh)) {
        die "cannot connect to '$connect' for $table/$column because: $DBI::errstr\n";
    }

    # ------ extract last-modified date from specified table and column
    (undef,$dbd,undef) = split(':', $connect, 3);
    $time_phrase = $unix_time->{$dbd}->{"time"};
    $time_phrase =~ s/\.\.\./$column/;
    $sql =<<endSQL;
 SELECT
  $time_phrase
 FROM
  $table
 ORDER BY
  $column
 DESC
endSQL
    $sth = $dbh->prepare($sql);
    dbi_error($DBI::errstr);
    $sth->execute();
    dbi_error($DBI::errstr);
    ($last) = $sth->fetchrow_array();
    dbi_error($sth->errstr);

    # ------ return last-modified data as a Unix time
    if ($unix_time->{$dbd}->{"parse_date"}) {
        $last = str2time($last);
    }
    return $last;
}



# ------ define private package variables
my $strategy			# date resources strategy
 = [
     { "name"     => "file",	    # file handler
       "last_mod" => \&dlm_file,	# return last-modified date
     },
     { "name"     => "dir",	        # directory handler
       "last_mod" => \&dlm_dir,		# return last-modified date
     },
     { "name"     => "dbi",	        # DBI handler
       "last_mod" => \&dlm_dbi,	    # return last-modified date
     },
   ];


# ------ empty error function for AppConfig
sub AppConfig_err {
}


# ------ constructor
sub new {
    my $class       = shift;    # our classname
    my $resources   = shift;    # hashref of date resources
                                # OR scalar with config filename
    my $cfg                     # configuration object
     = new AppConfig( {
     CREATE => 1,               # create variables without predefinitions
     ERROR  =>
      \&AppConfig_err,          # error handler (empty)
     } );
    my $self        = {};	# my blessed self
    my $tactic      = "";	# tactic in resource handler strategy
    my $tactic_cnt  = 0;	# total # of tactics we use
    my $tactic_name = "";	# name of tactic in strategy

    # ------ bless ourself into our class
    bless $self, $class;

    # ------ setup where last-modified came from
    $self->{"From"} = undef;

    # ------ use passed-in date resources
    if (ref($resources) eq "HASH") {
        foreach $tactic (@$strategy) {
            $self->{"Resources"}->{$tactic->{"name"}}
             = $resources->{$tactic->{"name"}};
        }

    # ------ use date resources from config file
    } else {

        # ------ set up variables we know about
        foreach $tactic (@$strategy) {
            $cfg->define("dlm_$tactic->{name}",
             { ARGCOUNT => ARGCOUNT_LIST } );
        }

        # ------ read configuration file
        if (!$cfg->file($resources)) {
            die "can't read '$resources'\n";
        }
        foreach $tactic (@$strategy) {
            $self->{"Resources"}->{$tactic->{"name"}}
             = $cfg->get("dlm_$tactic->{name}");
        }
    }

    # ------ ensure we got something to work with
    foreach $tactic_name (keys(%{$self->{"Resources"}})) {
        $tactic = $self->{"Resources"}->{$tactic_name};
        if (ref($tactic) eq "ARRAY") {
            $tactic_cnt += scalar(@{$tactic});
        }
    }
    if ($tactic_cnt < 1) {
        die "no resources to use by Date::LastModified\n";
    }

    # ------ everything OK so return my blessed self
    return $self;
}


# ------ return last-modified date of one or more resources
sub last {
    my $self        = shift;    # my blessed self
    my $current     = 0;        # current date from a resource
    my $func        = undef;    # function to find last-modified date
    my $latest      = 0;        # last-modified date of all resources
    my $resource    = "";       # resource to examine
    my $tactic      = "";		# tactic in resource handler strategy
    my $tactic_name = "";		# name of tactic in strategy

    $current = $latest = 0;
    $self->{"From"} = undef;
    foreach $tactic_name (keys(%{$self->{"Resources"}})) {
        $tactic = $self->{"Resources"}->{$tactic_name};
        $func = undef;
        if (ref($tactic) eq "ARRAY" && scalar(@$tactic) > 0) {
            foreach $tactic (@$strategy) {
                if ($tactic->{"name"} eq $tactic_name) {
                    $func = $tactic->{"last_mod"};
                }
            }
            if (!defined($func)) {
                die "missing last_mod function for '$tactic_name'\n";
            }
            foreach $resource (@{$tactic}) {
                $current = &$func($resource);
                if ($current > $latest) {
                    $self->{"From"} = "$tactic_name: $resource";
                    $latest = $current;
                }
            }
        }
    }

    return $latest;
}

# ------ return where last-modified date came from
sub from {
    my $self = shift;           # our blessed self

    return $self->{"From"};
}

1;
__END__



=head1 NAME

Date::LastModified - Return last-modified date from a set of resources

=head1 SYNOPSIS

  use Date::LastModified;
  my $dlm = new Date::LastModified("CFGFILE");
  my $dlm = new Date::LastModified(
   { "dlm_file" => [ "/www/data/index.html", "/www/data/iso9001/index.html" ] } );

  $time   = $dlm->last;     # return last-modified time() format
  $string = $dlm->from;     # return last-modified resource info

=head1 DESCRIPTION

Date::LastModified extracts the last modification date from
one or more resources, which can be files ("dlm_file"),
directories ("dlm_dir"), or DBI-compatible databases
("dlm_dbi").  It should be possible to subclass
Date::LastModified to add other resource types, like web
pages or external sensors.

Date::LastModified uses AppConfig to parse the configuration file.
To pass resources directly, specify them with a hashref to new()
where the value is an array ref:

=over 4

=item dlm_file

Looks at the file's last-modified date.

=item dlm_dir

Looks at all the files in that directory and its subdirectories,
using the latest file.

=item dlm_dbi

Looks at the database table and uses the last date for the
specified field.

=back

The time()-compatible time of the latest resource is returned
by last().

Once last() has been called, you can obtain which resource
was the last-modified by calling from().  If last() has not
been called, from() returns undef.

=head2 CONFIGURATION FILES

Date::LastModified uses AppConfig to parse the configuration file,
so you can specify the resources in one of two ways, either
directly:

    dlm_file = /etc/passwd
    dlm_dir  = /www/data

or in a section:

    [dlm]
    file = /etc/passwd
    dir  = /www/data

Both styles result in the same outcome.  The section style is
useful if Date::LastModified will be used in a larger program
that requires other configuration file info.

=head2 EXTRACTING A TIME()

The $unix_time hashref supports a phrasebook pattern for
extracting a time() from the database for comparisons.  This
hashref is where you can add database drivers, although these
drivers are already supported:

    Oracle (V7 & V8)
    MySQL  (V3)
    SQLite (V2)

There is also a pseudo-entry "SQL92" that should have the correct
syntax for SQL92-compatible databases like Oracle9i.


=head2 EXPORT

None by default.

=head1 TESTING

DBI tests assume that the database(s) are updated regularly
but not every minute or every second.

=head1 AUTHOR

Mark Leighton Fisher, E<lt>mark-fisher@mindspring.com<gt>

=head1 SEE ALSO

L<perl>.

=cut
