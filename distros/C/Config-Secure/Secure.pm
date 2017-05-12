package Config::Secure;

use 5.00503;
use strict;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $OPENED);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Config::Secure ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} }, qw(get_fh get_conf write_conf));

@EXPORT = qw(
	
);
$VERSION = '0.0.1';


# Preloaded methods go here.
use Fcntl;

#F_SETFD w/ fcntl() and $^F

BEGIN {
    $0 = $ENV{PSC_CONFIG_CMD} if $ENV{PSC_CONFIG_CMD};
    $OPENED = 0;
}

# This routine opens the file, then memoizes itself 
sub get_fh {    
    local $^W = 0;
    my($fh,$type);

    if($ENV{PSC_CONFIG_FH} >= 0) {
	$type = int $ENV{PSC_CONFIG_WRITE};
	my $rw = ($type ? '+' : '');
	open $fh, "${rw}<&=$ENV{PSC_CONFIG_FH}" 
	    or die "Could not open conf filehandle: $!";
	$OPENED = 1;
    } else {
	*get_fh = sub {};
        warn "No conf file available: $!";
	return;
    }

    fcntl($fh, F_GETFL, $_);
    *get_fh = sub {
	return($fh,$type);
    };
    get_fh();
}

# read conf and make it a data structure
sub get_conf {
    my ($fh,$type) = get_fh();
    my (%conf,%loader_comments);
    unless($fh) {
	warn("get_conf failed... no filehandle");
	return;
    }
    local $_;
    while(<$fh>) {
	my($k,$v);
	next if /^\s+\#/;
	chomp;
	if(/^\#\s*(?:([^:]+):)?/) {
	    push @{$loader_comments{$1}}, $_;
	} elsif((($k,$v) = split /:\s*/, $_, 2) == 2) {
	    if($conf{$k}) {
		if(ref $conf{$k}) {
		    push @{$conf{$k}}, $v;
		} else {
		    $conf{$k} = [$conf{$k}, $v];
		}
	    } else {
		$conf{$k} = $v;
	    }
	}
    }
    # save the comments for the nice people
    *_comments = sub {
	\%loader_comments;
    };

    return wantarray ? %conf : \%conf;
}

# write conf data back to file, if it is writeable
sub write_conf {
    my ($fh,$type) = get_fh();
    unless($type) {
	warn("Conf file not writeable\n");
	return;
    }
    my %conf;
    if(@_ == 1) {
	if(ref $_[0] eq 'HASH') {
	    %conf = %{$_[0]};
	} else {
	    warn "Need to pass write_conf a hash or hash ref";
	    return;
	}
    } else {
	if(@_ % 2) {
	    warn "Odd number of arguments to write_hash. Need to pass write_conf a hash or hash ref";
	    return;
	}
	%conf = @_;
    }

    seek($fh, 0, 0);
    my $c = &_comments;
    # write general comments at top
    for my $comment (@{$c->{''}}) { 
	print $fh "$comment\n"; 
    }
    print $fh "\n";
    for my $k (sort keys %conf) {
	$c->{$k}[0] ||= "# $k: ";
	# write comments for indivisual keys
	for my $comment (@{$c->{$k}}) { 
	    print $fh "$comment\n"; 
	}
	if(ref $conf{$k}) {
	    for my $a (@{$conf{$k}}) {
		print $fh "$k: $a\n";
	    }
	} else {
	    print $fh "$k: $conf{$k}\n";
	}
	print $fh "\n";
    }
    truncate $fh, tell $fh;
    1;
}

# close your file handles!
END {
    if($OPENED) {
	my $fh = (get_fh())[0];
	close $fh if $fh;
    }
}

1;


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Config::Secure - Perl extension for scripts run with PSC

=head1 SYNOPSIS

  use Config::Secure qw(get_conf write_conf);
  
  my %conf = get_conf();
  my $pass = $conf{pass};
  print "Last edited ".scalar(localtime($conf{lastedited}))."\n";
  $conf{lastedited} = time; 
  write_conf(\%conf);

=head1 DESCRIPTION

Config::Secure is a module for reading config data passed in by
Perl Secure Conf (PSC) which can be found at http://psc.sourceforge.net/
It is really not useful unless your script is called through PSC.

PSC is a setuid C program which opens a protected conf file, drops
its permissions, and then runs an unprotected perl script. 
Theoretically that perl script uses this module, and this module
then opens the filehandle and parses the data to return it to
you in a nice hash (or hashref). If the conf file is writeable
by the setuid user, you may also use write_conf to write back to
the conf file. For more info on PSC, see its documentation.

This module expects conf files to be in the form of
key: value
lines beginning with a # are comment lines. I have done my best
to maintain conf file comments on writeback. If you want to have
comments and write to your conf file, use the form of

# foo: this is a comment on foo
foo: bar

that way your comments will stay associated with their proper
keys.

You may have more than one value for a certain key, if you do this
the value in the hash will automagically change from a scalar value
to a hashref containing all the values in the order they were defined
in the file. It is up to you to catch this if you put in multiple
values for one key.

If you do not wish to use Config::Secure's get and write functions
you are free to write your own, though I would suggest you still
use Config::Secure to initialize your program. If you wish to do
this I have provided the get_fh method. Calling get_fh returns you
the filehandle to the file, and a flag as to whether or not you
may write to it. Use it as follows:

  my($fh,$writeable) = Config::Secure::get_fh();

You may then do whatever you want with the file.

Config::Secure does a neat little trick for you, it sets
$0 to contain the path to the psc link that was called
to invoke the script. This makes it easier to replace any
existing scripts that may rely on $0. Keep in mind, though,
that FindBin will point to the actual script, not the same
as the PSC link.

=head1 METHODS

  get_conf() - returns hash ref in scalar context, list in
               list context (for assigning to hashes)
               returns nothing on failure

  write_conf() - take a hash or hash ref as argument. Will
                 write what it understands to conf file.
                 returns 1 on success

  get_fh() - returns filehandle and writeable flag on success,
             nothing on failure

=head2 EXPORT

None by default.

Exportable methods are get_conf, write_conf and get_fh

=head1 AUTHOR

Anthony Ball <ant_psc@suave.net>

=head1 SEE ALSO

L<perl>.

=cut


