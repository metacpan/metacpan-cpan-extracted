package ClearCase::CRDB;

$VERSION = '0.15';

# This schema version is stored in the flat-file form via ->store
# and compared during ->load. A warning is issued if they don't match.
my $mod_schema = 1;

# I don't know exactly what Perl version is the minimum required but I
# have a report that it works with 5.005. I use 5.8 myself.
require 5.005;

use File::Basename;
use File::Spec 0.82;
use Getopt::Long;
use Cwd;

# For convenience, load up known subclasses. We 'eval' these to ignore
# the error msg if the underlying serialization modules
# Data::Dumper/Storable/etc aren't installed.
eval { require ClearCase::CRDB::Dumper; };
eval { require ClearCase::CRDB::Storable; };

use strict;

use constant MSWIN => $^O =~ /MSWin32|Windows_NT/i ? 1 : 0;

my $prog = basename($0, qw(.pl));

# Defining multiple constants at once isn't supported before 5.8.
use constant SKIP => 0;
use constant NOTES => 1;
use constant OBJECTS => 2;
use constant VARS => 3;
use constant SCRIPT => 4;

sub new {
    my $proto = shift;
    my($class, $self);
    if ($class = ref($proto)) {
	# Make a (deep) clone of the original
	require Clone;
	Clone->VERSION(0.11);	# there's a known bug in 0.10
	return Clone::clone($proto);
    }
    $class = $proto;
    $self = {};
    bless $self, $class;
    # HACK - this doesn't actually use @_, it's just an indication
    # that we want to parse @ARGV.
    $self->init if @_;
    return $self;
}

sub usage {
    my $self = shift;
    return "TBD";
}

sub init {
    my $self = shift;
    my %opt;
    my $ext = 'crdb';
    my $delim = MSWIN ? ',;' : ',;:';

    # Any options matched here are removed from the global @ARGV.
    local $Getopt::Long::passthrough = 1;
    GetOptions(\%opt, qw(cr|cache=s do=s@ db=s@ lsprivate recurse save));

    if ($opt{do} || $opt{lsprivate} || $ENV{CRDB_DO}) {
	my @dos;
	if ($opt{do}) {
	    @dos = @{$opt{do}};
	    if (@dos == 1 && $dos[0] eq '-') {
		chomp(@dos = <STDIN>);
	    }
	} elsif ($opt{lsprivate}) {
	    @dos = qx(cleartool lsprivate -do);
	    chomp @dos;
	} elsif ($ENV{CRDB_DO}) {
	    @dos = map {split /[$delim]/} $ENV{CRDB_DO};
	}
	$self->crdo(@dos);
	if ($opt{recurse}) {
	    $self->catcr_recurse;
	} else {
	    $self->catcr_flat;
	}

	my $savefile;
	if ($opt{db}) {
	    die "$prog: Error: can write to only one database file"
							    if @{$opt{db}} != 1;
	    $savefile = $opt{db}->[0];
	} elsif ($opt{save}) {
	    $savefile = $dos[0];
	}
	if ($savefile) {
	    $savefile .= ".$ext" unless $savefile =~ m%$ext$%;
	    $self->store($savefile);
	}
    } elsif ($opt{cr}) {
	open(CR, $opt{cr}) || die "$prog: Error: $opt{cr}: $!";
	$self->catcr_handle(\*CR);
	close(CR);
	if ($opt{save}) {
	    (my $savefile = $opt{cr}) =~ s%\.\w+?$%.$ext%;
	    $self->store($savefile);
	}
    } elsif ($opt{db} || $ENV{CRDB_DB}) {
	my $dblist = $opt{db} ? join(',', @{$opt{db}}) : $ENV{CRDB_DB};
	my @dbs = map {split /[$delim]/} $dblist;
	for (@dbs) {
	    $_ .= ".$ext" unless m%$ext$%;
	}
	$self->load(@dbs);
    } else {
	my $path = $opt{dir} || $ENV{CRDB_PATH} || '.';
	my @found;
	for my $dir (split /[$delim]/, $path) {
	    push(@found, glob("$dir/.*.$ext"), glob("$dir/*.$ext"));
	}
	die "$prog: Error: no CRDB databases found" unless @found;
	my $s = @found > 1 ? 's' : '';
	$self->load(@found);
    }
}

sub crdo {
    my $self = shift;
    if (@_) {
	push(@{$self->{CRDB_CRDO}}, map {File::Spec->rel2abs($_)} @_);
	if (MSWIN) {
	    s%^[a-z]:%%i for (@{$self->{CRDB_CRDO}});
	}
    }
    return @{$self->{CRDB_CRDO}};
}

sub check {
    my $self = shift;
    $self->crdo(@_) if @_;
    my @objects = $self->crdo;
    die "Error: no derived objects specified to check" unless @objects;
    return system(qw(cleartool catcr -check -union), @objects);
}

# Useful in development; allows a pre-generated catcr output to be
# stashed in a file and passed in here repeatedly.
sub catcr_handle {
    my $self = shift;
    my $handle = shift;
    my($tgt, @notes);
    my $state = SKIP;
    for (<$handle>) {
	chomp;

	# State machine - set $state according to the CR section.
	if (m%^-{28}%) {
	    next;
        } elsif (m%^Derived object:\s+(.*)@@%) {
	    $tgt = $1;
	    $tgt =~ s%^[a-z]:%%i if MSWIN;
	    if (exists $self->{CRDB_FILES}->{$tgt} &&
		    (exists $self->{CRDB_FILES}->{$tgt}->{CR_DO} ||
		    exists $self->{CRDB_FILES}->{$tgt}->{CR_SIBLING_OF})) {
		$state = SKIP;
	    } elsif (!MSWIN && basename($tgt) eq 'core') {
		# This is a hack, but some builds produce lots of core
		# files and we generally want to ignore the spurious
		# DOs thus produced.
		$state = SKIP;
	    } else {
		$state = NOTES;
	    }
	    next;
        } elsif (m%^Target\s+(\S*)\s+built\s%) {
	    $state = SKIP if $1 eq 'ClearAudit_Shell';
	    next;
	} elsif ($state == SKIP) {
	    next;
	} elsif (($state == NOTES || $state == OBJECTS) && m%MVFS objects:%) {
	    @{$self->{CRDB_FILES}->{$tgt}->{CR_DO}->{CR_NOTES}} = @notes;
	    @notes = ();
	    $state = OBJECTS;
	    next;
	} elsif ($state == OBJECTS && m%^Variables and Options:%) {
	    $state = VARS;
	    next;
	} elsif (($state == VARS || $state == OBJECTS) && m%^Build Script:%) {
	    $state = SCRIPT;
	    next;
	}

	# Accumulate data from section according to $state.
	if ($state == NOTES) {
	    push(@notes, $_);
	    if (my($iwd) = m%^Initial working directory was (\S+)%) {
		$self->{CRDB_FILES}->{$tgt}->{CR_DO}->{CR_IWD} = $iwd;
	    }
	} elsif ($state == OBJECTS) {
	    my($path, $vers, $date, $cmnts);
	    my $inmakefile = 1;

	    if (m%^(?:directory version|view directory)\s%) {
		# We don't care about directories.
		next;
	    } elsif (($path, $vers, $date, $cmnts) =
		    m%^(?:version|derived object version)\s+(\S+?.+?)@@(\S+)\s+<(\S+)>\s*(.*)$%) {
		# We do not currently distinguish between regular elements
		# and versioned derived objects.
		$path =~ s%^[a-z]:%%i if MSWIN;
		$self->{CRDB_FILES}->{$path}->{CR_TYPE} = 'ELEM';
		$self->{CRDB_FILES}->{$path}->{CR_ELEM}->{CR_VERS} = $vers;
		$self->{CRDB_FILES}->{$path}->{CR_DATE} = $date;
	    } elsif ((($path, $date, $cmnts) =
			m%^derived object\s+(\S.+?)@@(\S+)\s*?(.*)$%) ||
		     (($path, $date, $cmnts) =
			m%^derived object\s+(\S.+?)\s+<(\S+)>\s*?(.*)$%)) {
		$path =~ s%^[a-z]:%%i if MSWIN;
		$self->{CRDB_FILES}->{$path}->{CR_TYPE} = 'DO';
		if ($date =~ s%\.(\d+)$%%) {
		    $self->{CRDB_FILES}->{$path}->{CR_DBID} = $1;
		}
		$self->{CRDB_FILES}->{$path}->{CR_DATE} = $date;
		# In the case of siblings, each secondary sibling gets
		# a pointer back to the primary, while the primary
		# gets a list of its siblings.
		if ($cmnts =~ m%new derived object%) {
		    if ($path ne $tgt) {
			$self->{CRDB_FILES}->{$path}->{CR_SIBLING_OF} = $tgt;
			$self->{CRDB_FILES}->{$tgt}->{CR_SIBLINGS}->{$path} = 1;
		    }
		}
		$inmakefile = ($cmnts =~ m%in makefile%) ? 1 : 0;
	    } elsif (($path, $vers, $cmnts) =
		    m%^derived object\s+(\S+?.+?)@@(\S+)\s*(.*)$%) {
		warn "Warning: unhandled DO type: '$_'";
	    } elsif (($path, $date, $cmnts) =
		    m%^view file\s+(\S.+\S)\s+<(\S+)>\s*(.*)$%) {
		$path =~ s%^[a-z]:%%i if MSWIN;
		$self->{CRDB_FILES}->{$path}->{CR_TYPE} = 'VP';
		$self->{CRDB_FILES}->{$path}->{CR_DATE} = $date;
	    } elsif (m%^view private object%) {
		# These seem to come up only for symlinks, which we can
		# ignore since the target be recorded elsewhere.
		next;
	    } elsif (m%^branch%) {
		# This appears to be reported only for non-visible DO's
		next;
	    } elsif (m%^file element%) {
		# This appears to be reported only for non-visible DO's
		next;
	    } elsif (m%^directory element%) {
		# This appears to be reported only for non-visible DO's
		next;
	    } elsif (m%^symbolic link%) {
		next;
	    } else {
		warn "Warning: unrecognized CR line: '$_'";
		next;
	    }
	    if (MSWIN) {
		# Must compare paths case-insensitively on Windows.
		next if lc($path) eq lc($tgt);
	    } else {
		next if $path eq $tgt;
	    }
	    # The value of the NEEDS->{path} key indicated whether
	    # the prereq is explicit in the makefile.
	    if (!exists $self->{CRDB_FILES}->{$tgt}->{CR_SIBLINGS}->{$path}) {
		$self->{CRDB_FILES}->{$tgt}->{CR_DO}->{CR_NEEDS}->{$path} = $inmakefile;
	    }
	    # If this is a younger sibling, no need to record what it
	    # contributes to - the older sibling has that data.
	    if (!exists $self->{CRDB_FILES}->{$path}->{CR_SIBLING_OF}) {
		$self->{CRDB_FILES}->{$path}->{CR_MAKES}->{$tgt} = 1;
	    }
	} elsif ($state == VARS && (my($var, $val) = m%^(.+?)=(.*)%)) {
	    $self->{CRDB_FILES}->{$tgt}->{CR_DO}->{CR_VARS}->{$var} = $val;
	} elsif ($state == SCRIPT) {
	    push(@{$self->{CRDB_FILES}->{$tgt}->{CR_DO}->{CR_SCRIPT}},
								substr($_, 1));
	} else {
	    warn "Warning: unrecognized CR line: '$_'";
        }
    }
    close ($handle);
    return $self;
}

sub catcr_cmd {
    my $self = shift;
    my $cmd = shift;

    # The preferred directory for temp files.
    my $tmpd = MSWIN ?
	    ($ENV{TEMP} || $ENV{TMP} || ( -d "$ENV{SYSTEMDRIVE}/temp" ?
		"$ENV{SYSTEMDRIVE}/temp" : $ENV{SYSTEMDRIVE}))
	:
	    ($ENV{TMPDIR} || '/tmp');
    $tmpd =~ s%\\%/%g;

    # The command line here can get awfully long, enough to blow the
    # limit on some systems. So we hack around it by reading stdin.
    my $dolist = "$tmpd/dolist.$$.tmp";
    if (open(DOLIST, ">$dolist")) {
	print DOLIST $cmd;
	print DOLIST " '$_'" for @{[$self->crdo]};
	print DOLIST "\n";
	close(DOLIST);
    } else {
	warn "Warning: $dolist: $!";
	return;
    }
    my $handle;
    open($handle, "cleartool <$dolist |") || die "Error: $dolist: $!";
    $self->catcr_handle($handle);
    unlink $dolist;
    return $self;
}

sub catcr_flat {
    my $self = shift;
    $self->crdo(@_) if @_;
    my $cmd = "catcr -l";
    return $self->catcr_cmd($cmd);
}

sub catcr_recurse {
    my $self = shift;
    $self->crdo(@_) if @_;
    my $cmd = "catcr -r -l";
    return $self->catcr_cmd($cmd);
}

# Backward compatibility.
sub catcr {
    my $self = shift;
    return $self->catcr_recurse(@_);
}

# Internal func to recursively merge two hash refs
sub hash_merge {
    my($to, $from, @source) = @_;
    for (keys %{$from}) {
	if (! $to->{$_}) {
	    $to->{$_} = $from->{$_};
	    next;
	}
	my($ttype, $ftype) = (ref $to->{$_}, ref $from->{$_});
	if ($ttype ne $ftype) {
	    warn "Warning: key type conflict: @source: $_ $ttype/$ftype"
	} elsif (! $ttype) {
	    warn "Warning: @source: $_: can't merge non-references";
	} elsif ($ttype eq 'ARRAY') {
	    push(@{$to->{$_}}, @{$from->{$_}});
	} elsif ($ttype eq 'HASH') {
	    hash_merge($to->{$_}, $from->{$_}, @source);
	} else {
	    warn "Warning: @source: $_: can't merge type: $ttype";
	}
    }
}

sub store {
    my $self = shift;
    my $file = shift || '-';
    $self->{CRDB_SCHEMA} = $mod_schema;
    my $d = Data::Dumper->new([$self], ['_DO']);
    $d->Indent(1);
    open(DUMP, ">$file") || die "$file: $!\n";
    printf DUMP "# Produced by Perl module %s using %s format.\n",
							    ref $self, ref $d;
    print DUMP "# It is valid Perl syntax and may be read into memory via\n";
    print DUMP "# 'do <file>' or by eval-ing its contents.\n\n";
    print DUMP $d->Dumpxs;
    close(DUMP);
    return $self;
}

sub load {
    my $self = shift;
    for my $db (@_) {
	my $hashref;
	die "Error: $db: incorrect format" if -e $db && -B $db;
	$hashref = do $db;	# eval's $db and returns the obj ref
	if (!defined($hashref)) {
	    warn "Error: $db: " . (-r $db ? $@ : $!);
	    return undef;
	}
	my $file_schema = $hashref->{CRDB_SCHEMA};
	die "Error: $db: stored schema ($file_schema) != current ($mod_schema)"
					unless $file_schema == $mod_schema;
	$self->hash_merge($hashref, @{$hashref->{CRDB_CRDO}});
    }
    return $self;
}

sub iwd {
    my $self = shift;
    if (@_ == 1) {
	my $do = $self->primary_sibling(shift);
	return $self->{CRDB_FILES}->{$do}->{CR_DO}->{CR_IWD};
    } elsif (@_ == 0) {
	my %iwds;
	for (keys %{$self->{CRDB_FILES}}) {
	    next unless exists $self->{CRDB_FILES}->{$_}->{CR_DO};
	    my $iwd = $self->iwd($_);	# recursion of a sort
	    $iwds{$iwd}++ if $iwd;
	}
	return sort keys %iwds;
    }
    return undef;
}

sub files {
    my $self = shift;
    return keys %{$self->{CRDB_FILES}};
}

sub type_is {
    my $self = shift;
    my $type = shift;
    return grep {
	exists $self->{CRDB_FILES}->{$_} &&
	$self->{CRDB_FILES}->{$_}->{CR_TYPE} eq $type
    } keys %{$self->{CRDB_FILES}};
}

sub versioned_elements {
    my $self = shift;
    return $self->type_is('ELEM');
}

sub derived_objects {
    my $self = shift;
    return $self->type_is('DO');
}

sub view_privates {
    my $self = shift;
    return $self->type_is('VP');
}

sub targets {
    my $self = shift;
    my $siblings_too = shift;
    my $key = $siblings_too ? 'CR_DBID' : 'CR_DO';
    return grep {exists $self->{CRDB_FILES}->{$_}->{$key}}
						    keys %{$self->{CRDB_FILES}};
}

sub terminals {
    my $self = shift;
    return grep {
	 exists $self->{CRDB_FILES}->{$_}->{CR_DO} &&
	!exists $self->{CRDB_FILES}->{$_}->{CR_MAKES}
    } keys %{$self->{CRDB_FILES}};
}

sub vars {
    my $self = shift;
    my $do = shift;
    if (wantarray) {
	return keys %{$self->{CRDB_FILES}->{$do}->{CR_DO}->{CR_VARS}};
    } else {
	return $self->{CRDB_FILES}->{$do}->{CR_DO}->{CR_VARS};
    }
}

sub val {
    my $self = shift;
    my($do, $var) = @_;
    return undef unless exists $self->{CRDB_FILES}->{$do}->{CR_DO}->{CR_VARS};
    return $self->{CRDB_FILES}->{$do}->{CR_DO}->{CR_VARS}->{$var};
}

sub notes {
    my $self = shift;
    my $do = shift;
    return undef unless exists $self->{CRDB_FILES}->{$do}->{CR_DO}->{CR_NOTES};
    return @{$self->{CRDB_FILES}->{$do}->{CR_DO}->{CR_NOTES}};
}

sub script {
    my $self = shift;
    my $do = $self->primary_sibling(shift);
    return undef
	    if !exists $self->{CRDB_FILES}->{$do}->{CR_DO}->{CR_SCRIPT};
    my @script = @{$self->{CRDB_FILES}->{$do}->{CR_DO}->{CR_SCRIPT}};
    return @script;
}

sub matches {
    my $self = shift;
    my @matched;
    for my $re (@_) {
	push(@matched, grep m%$re%, keys %{$self->{CRDB_FILES}});
    }
    return @matched;
}
*matches_do = \&matches;

sub needs {
    my $self = shift;
    my @results;
    for my $do (@_) {
	next unless exists $self->{CRDB_FILES}->{$do};
	push(@results, keys %{$self->{CRDB_FILES}->{$do}->{CR_DO}->{CR_NEEDS}});
    }
    return @results;
}
*needs_do = \&needs;

sub makes {
    my $self = shift;
    my @results;
    for my $do (@_) {
	push(@results, keys %{$self->{CRDB_FILES}->{$do}->{CR_MAKES}})
					if exists $self->{CRDB_FILES}->{$do};
    }
    return @results;
}
*makes_do = \&makes;

sub unmentioned {
    my $self = shift;
    my @results;
    for my $do (@_) {
	for my $prq (keys %{$self->{CRDB_FILES}->{$do}->{CR_DO}->{CR_NEEDS}}) {
	    next if $self->{CRDB_FILES}->{$do}->{CR_DO}->{CR_NEEDS}->{$prq};
	    push(@results, $prq)
	}
    }
    return @results;
}

# If the supplied path is a sibling DO, replace it with the "primary"
# DO record which contains the useful data such as iwd, script, etc.
sub primary_sibling {
    my $self = shift;
    my $do = shift;
    $do = $self->{CRDB_FILES}->{$do}->{CR_SIBLING_OF}
	if exists $self->{CRDB_FILES}->{$do}->{CR_SIBLING_OF};
    return $do;
}

sub sibling_of {
    my $self = shift;
    my $do = shift;
    return $self->{CRDB_FILES}->{$do}->{CR_SIBLING_OF};
}

sub siblings {
    my $self = shift;
    my $do = shift;
    if (!exists $self->{CRDB_FILES}->{$do}->{CR_SIBLINGS} &&
	    exists $self->{CRDB_FILES}->{$do}->{CR_SIBLING_OF}) {
	$do = $self->{CRDB_FILES}->{$do}->{CR_SIBLING_OF};
    }
    if (exists $self->{CRDB_FILES}->{$do}->{CR_SIBLINGS}) {
	return keys %{$self->{CRDB_FILES}->{$do}->{CR_SIBLINGS}};
    } else {
	return ();
    }
}

sub recognizes {
    my $self = shift;
    my $do = shift;
    return exists $self->{CRDB_FILES}->{$do};
}

sub iwd_targets {
    my $self = shift;
    my $iwd = shift;
    my @tgts = grep {
	exists($self->{$_}->{CR_IWD}) && $self->{$_}->{CR_IWD} eq $iwd
    } keys %$self;
    return @tgts;
}

sub absify {
    my $self = shift;
    my($iwd, $orig) = @_;

    my $line = '';
    my @chunks = split ' ', $orig;
    for my $i (0 .. $#chunks) {
	my $chunk = $chunks[$i];
	if ($chunk =~ m%^[\\/]%) {
	    $line .= $chunk;
	    next;
	} else {
	    if ($chunk =~ m%^-%) {
		if ($chunk =~ s%^(-[ILR])%%) {
		    $line .= $1;
		    if ($chunk =~ m%^[\\/]%) {
			$line .= $chunk;
			next;
		    }
		} else {
		    $line .= $chunk;
		    next;
		}
	    }
	}
	my $full = File::Spec->canonpath("$iwd/$chunk");
	if ($self->recognizes($full)) {
	    $line .= $full;
	} elsif (-d $full) {
	    $line .= $full;
	} elsif (-e $full) {
	    $line .= File::Spec->join(Cwd::abs_path(dirname $full),
		basename $full);;
	    #warn "Warning: not recognized: $full\n";
	} else {
	    $line .= $chunk;
	    #warn "Unrecognized: '$chunk'\n";
	}
    } continue {
	$line .= ' ' if $i < $#chunks;
    }
    return $line;
}

1;

__END__

=head1 NAME

ClearCase::CRDB - Class for ClearCase config-record analysis

=head1 SYNOPSIS

    my $crdb = ClearCase::CRDB->new(@ARGV);	# Initialize object
    $crdb->check;				# Do a CR sanity check
    $crdb->catcr;				# Analyze the recursive CR
    $crdb->store($filename);			# Dump CR to $filename

=head1 DESCRIPTION

A ClearCase::CRDB object represents the (potentially recursive)
I<configuration record> (hereafter C<I<CR>>) of a set of I<derived
objects> (hereafter C<I<DOs>>).  It provides methods for easy
extraction of parts of the CR such as the build script, MVFS files used
in the creation of a given DO, make macros employed, etc. This is the
same data available from ClearCase in raw textual form via C<cleartool
catcr>; it's just broken down for easier access and analysis.

An example of what can be done with ClearCase::CRDB is the provided
I<whouses> script which, given a particular DO, can show recursively
which files it depends on or which files depend on it.

Since recursively deriving a CR database can be a slow process for
large build systems and can burden the VOB database, the methods
C<ClearCase::CRDB-E<gt>store> and C<ClearCase::CRDB-E<gt>load> are
provided. These allow the derived CR data to be stored in its processed
form to a persistent storage such as a flat file or database and
re-loaded from there. For example, this data might be derived once per
day as part of a nightly build process and would then be available for
use during the day without causing additional VOB load.

The provided C<ClearCase::CRDB-E<gt>store> and
C<ClearCase::CRDB-E<gt>load> methods save to a flat file in
human-readable text format. Different formats may be used by
subclassing these two methods. An example subclass
C<ClearCase::CRDB::Storable> is provided; this uses the Perl module
I<Storable> which is a binary format. If you wanted to store to a
relational database this is how you'd do it, using Perl's DBI modules.

=head2 CONSTRUCTOR

Use C<ClearCase::CRDB-E<gt>new> to construct a CRDB object. I<If @ARGV
is passed in, the constructor will automatically parse certain standard
flags from @ARGV and use them to initialize the object.> See the
B<usage> method for details.

=head2 INSTANCE METHODS

Following is a brief description of each supported method. Examples
are given for all methods that take parameters; if no example is
given, usage may be assumed to look like:

    my $result = $obj->method;

Also, if the return value is described in plural terms it may be
assumed that the method returns a list.

=over 4

=item * usage

Returns a string detailing the internal standard command-line flags
parsed by the C<-E<gt>new> constructor for use in the script's usage
message.

=item * crdo

Sets or gets the list of derived objects under consideration, e.g.:

    $obj->crdo(qw(do_1 do_2);	# give the object a list of DO's
    my @dos = $obj->crdo;	# gets the list of DO's

This method is invoked automatically by the constructor if derived
objects are passed to it.

=item * catcr

Invokes I<cleartool catcr> on the DO set and breaks the resultant
textual data apart into various fields which may then be accessed by
the methods below. This method is invoked automatically by the
constructor (see) if derived objects are specified.

=item * check

Checks the set of derived objects for consistency. For instance, it
checks for multiple versions of the same element, or multiple
references to the same element under different names, in the set of
config records.

=item * store

Writes the processed config record data to the specified file (default
= stdout).

=item * load

Reads processed config record data from the specified files.

=item * needs

Takes a list of derived objects, returns the list of prerequisite
derived objects (the derived objects on which they depend). For
example, if C<foo.c> includes C<foo.h> and compiles to C<foo.o> which
then links to the executable C<foo>, the C<-E<gt>needs> method when
given C<foo.o> would return the list C<('foo.c', 'foo.h')>. In other
words it returns "upstream dependencies" or prerequisite derived
objects.

=item * makes

Takes a list of derived objects, returns the list of derived objects
which use them. This is the reverse of C<needs>. Given the
C<needs> example above, the C<-E<gt>makes> method when given
C<foo.o> would return C<foo>. In other words it returns "downstream
dependencies".

=item * unmentioned

Takes a list of derived objects, returns the list of prerequisite
DOs which were B<not> mentioned in the makefile. Useful for finding
makefile bugs.

=item * iwd

Each target in a CR has an "initial working directory" or I<iwd>. If
passed a DO, this method returns the I<iwd> of that derived object.
With no parameters it returns the list of I<iwds> mentioned in the CR.

=item * files

Returns the complete set of files mentioned in the CR.

=item * targets

Returns the subset of files mentioned in the CR which are targets.
Takes one optional boolean parameter, which if true causes sibling
derived objects to be returned also.

=item * terminals

Returns the subset of targets which are terminal, i.e. those which do
not contribute to other derived objects.

=item * vars

In a list context, returns the set of make macros used in the build
script for the specified DO, e.g.:

    my @list = $obj->vars("path-to-derived-object");

In scalar context, returns a ref to the hash mapping vars to values:

    my $vhash = $obj->vars("path-to-derived-object");
    for my $var (keys %$vhash) {
	print "$var=", $vhash->{$var}, "\n";
    }

=item * val

Returns the value of the specified make macro as used in the build script
for the specified DO:

    my $value = $obj->val("path-to-derived-object", "CC");

=item * notes

Returns the set of "build notes" for the specified DO as a list. This
is the section of the CR which looks like:

    Target foo built by ...
    Host "host" running ...
    Reference Time ...
    View was ...
    Initial working directory was ...

E.g.

    my @notes = $obj->notes("path-to-derived-object");

=item * script

Returns the build script for the specified DO:

    my $script = $obj->script("path-to-derived-object");

=back

There are also some undocumented methods in the source. This is
deliberate; they're experimental.

=head1 AUTHOR

David Boyce <dsbperl AT cleartool.com>

=head1 COPYRIGHT

Copyright (c) 2000-2005 David Boyce. All rights reserved.  This Perl
program is free software; you may redistribute and/or modify it under
the same terms as Perl itself.

=head1 STATUS

This is currently ALPHA code and thus I reserve the right to change the
API incompatibly. At some point I'll bump the version suitably and
remove this warning, which will constitute an (almost) ironclad promise
to leave the interface alone.

=head1 PORTING

This module has been at least slightly tested, at various points in its
lifecycle, on almost all CC platforms including Solaris 2.6-8, HP-UX 10
and 11, and Windows NT4 and Win2K SP2 using perl 5.004_04 through 5.6.1
and CC4.1 through 5.0.  However, I tend to use the latest of everything
(CC5.0, Solaris8, Win2KSP2, Perl5.6.1 at this writing) and cannot
regression-test with anything earlier. Also, note that I rarely use
this on Windows so it may be buggier there.

=head1 BUGS

NOTE: A bug in CC 5.0 causes CRDB's "make test" to dump core. This bug
is in clearmake, not CRDB, and in any case affects only its test
suite.  The first CC 5.0 patch contains a fix, so you probably don't
want to use CC 5.0 unpatched. If you do, ignore the core dump in
the test suite and force the install anyway.

Please send bug reports or patches to the address above.

=head1 SEE ALSO

perl(1), ct+config_record(1), clearmake(1) et al
