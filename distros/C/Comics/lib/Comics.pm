#! perl

# Author          : Johan Vromans
# Created On      : Fri Oct 21 09:18:23 2016
# Last Modified By: Johan Vromans
# Last Modified On: Fri Nov 16 10:49:04 2018
# Update Count    : 389
# Status          : Unknown, Use with caution!

use 5.012;
use strict;
use warnings;
use utf8;
use Carp;

package Comics;

use Comics::Version;

our $VERSION = $Comics::Version::VERSION;

package main;

################ Common stuff ################

use strict;
use warnings;
use FindBin;
use File::Spec;
use File::Path qw();

BEGIN {
    # Add private library if it exists.
    if ( -d "$FindBin::Bin/../lib" ) {
	unshift( @INC, "$FindBin::Bin/../lib" );
    }
}

# Package name.
my $my_package = 'Sciurix';
# Program name.
my $my_name = "comics";

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $spooldir = File::Spec->catdir( File::Spec->tmpdir, "Comics" );
my $statefile;
my $refresh;
my $activate = 0;		# enable/disable
my $force;			# process disabled modules as well
my $rebuild;			# rebuild index, no fetching
my $list;			# produce listing
my $verbose = 1;		# verbose processing
my $reuse = 0;			# reuse existing fetch results

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Extra command line arguments are taken to be plugin names.
# If specified, only named plugins are included.
my $pluginfilter;

################ Presets ################

################ The Process ################

# Statistics.
our $stats;

sub init {
    $stats =
      { tally => 0,
	fail => [],
	loaded => 0,
	uptodate => 0,
	excluded => 0,
	disabled => 0,
      };

    # Process command line options.
    app_options();

    # Post-processing.
    $trace |= ($debug || $test);
    $verbose = 255 if $debug;
    $spooldir .= "/";
    $spooldir =~ s;/+$;/;;

    File::Path::make_path( $spooldir, { verbose => 1 } )
	unless -d $spooldir;

    $statefile = spoolfile(".state.json");

    $pluginfilter = ".";
    if ( @ARGV ) {
	$pluginfilter = "^(?:" . join("|", @ARGV) . ")\\.pm\$";
    }
    $pluginfilter = qr($pluginfilter)i;

}

sub main {

    # Initialize.
    init();

    # Restore state of previous run.
    get_state();

    # Load the plugins.
    load_plugins();

    # Non-aggregating command: list.
    if ( $list ) {
	list_plugins();
	return;
    }

    # Non-aggregating command: enable/disable.
    if ( $activate ) {
	save_state();
	return unless $rebuild;
    }

    unless ( $rebuild ) {
	# Run the plugins to fetch new images.
	run_plugins();

	# Save the state.
	save_state();
    }

    # Gather the HTML fragments into a single index.html.
    build();

    # Show processing statistics.
    statistics();
}

################ State subroutines ################

use JSON;

my $state;

sub get_state {
    if ( open( my $fd, '<', $statefile ) ) {
	my $data = do { local $/; <$fd>; };
	$state = JSON->new->decode($data);
	if ( $refresh ) {
	    delete( $_->{md5} )
	      foreach values( %{ $state->{comics} } );
	}
    }
    else {
	$state = { comics => { } };

    }
}

sub save_state {
    unlink($statefile."~");
    rename( $statefile, $statefile."~" );
    open( my $fd, '>', $statefile );
    print $fd JSON->new->canonical->pretty(1)->encode($state);
    close($fd);
}

################ Plugin subroutines ################

my @plugins;

sub load_plugins {

    opendir( my $dh, $INC[0] . "/Comics/Plugin" )
      or die( $INC[0] . "/Comics/Plugin: $!\n");

    while ( my $m = readdir($dh) ) {
	next unless $m =~ /^[0-9A-Z].*\.pm$/;
	next if $m eq 'Base.pm';
	$stats->{loaded}++;
	$stats->{excluded}++, next unless $m =~ $pluginfilter;

	debug("Loading $m...");
	$m =~ s/\.pm$//;
	# If the module is already loaded, remove it first.
	# Otherwise the require won't produce the __PACKAGE__ result.
	delete $INC{"Comics/Plugin/$m.pm"};
	my $pkg = eval { require "Comics/Plugin/$m.pm" };
	die("Comics/Plugin/$m.pm: $@\n") unless $pkg;
	unless ( $pkg eq "Comics::Plugin::$m" ) {
	    warn("Skipped $m.pm (defines $pkg, should be Comics::Plugin::$m)\n");
	    next;
	}
	my $comic = $pkg->register;
	next unless $comic;

	push( @plugins, $comic );
	my $tag = $comic->{tag};

	# 'disabled' means that this plugin is permanently disabled.
	my $activate = $comic->{disabled} ? -1 : $activate;

	# 'ondemand' means that this plugin is initially disabled, but
	# can be enabled if desired.
	if ( !$activate && $comic->{ondemand}
	     && !exists( $state->{comics}->{$tag} ) ) {
	    $activate = -1;
	}

	if ( $activate > 0 ) {
	    delete( $state->{comics}->{$tag}->{disabled} )
	}
	elsif ( $activate < 0 ) {
	    $state->{comics}->{$tag}->{disabled} = 1;
	    delete( $state->{comics}->{$tag}->{md5} );
	    for ( qw( html jpg png gif ) ) {
		next unless unlink( spoolfile( $tag . "." . $_ ) );
		debug( "Removed: ", spoolfile( $tag . "." . $_ ) );
		$rebuild++;
	    }
	    for ( $state->{comics}->{$tag}->{c_img} ) {
		next unless defined;
		next unless unlink( spoolfile($_) );
		debug( "Removed: ", spoolfile($_) );
		$rebuild++;
	    }
	}

	if ( $state->{comics}->{$tag}->{disabled} ) {
	    $stats->{disabled}++;
	    debug("Comics::Plugin::$m: Disabled");
	}

    }

    if ( $stats->{loaded} == $stats->{excluded} ) {
	warn( "No matching plugins found\n" );
    }
}

sub list_plugins {

    my $lpl = length("Comics::Plugin::");
    my $lft = length("Comics::Fetcher::");
    my ( $l_name, $l_plugin, $l_fetcher ) = ( 0, 0, $lft+8 );

    my @tm;
    @plugins =
      sort { ($state->{comics}->{$a->{tag}}->{disabled} // 0) <=>
               ($state->{comics}->{$b->{tag}}->{disabled} // 0) ||
	     $b->{update}         <=>  $a->{update} ||
	     $a->{name}           cmp  $b->{name}
	   }
	map {
	    $_->{update} = $state->{comics}->{ $_->{tag} }->{update} ||= 0;
	    @tm = localtime($_->{update});
	    $_->{updated} = sprintf( "%04d-%02d-%02d %02d:%02d:%02d",
				     1900+$tm[5], 1+$tm[4], @tm[3,2,1,0] );
	    $l_name = length($_->{name}) if $l_name < length($_->{name});
	    $l_plugin = length(ref($_)) if $l_plugin < length(ref($_));
	    $_;
	} @plugins;

    $l_plugin -= $lpl;
    $l_fetcher -= $lft;
    my $fmt = "%-${l_name}s   %-${l_plugin}s   %-${l_fetcher}s   %-8s   %s\n";
    foreach my $comic ( @plugins ) {

	my $st = $state->{comics}->{ $comic->{tag} };
	no strict 'refs';
	printf( $fmt,
		$comic->{name},
		substr( ref($comic), $lpl ),
		substr( ${ref($comic)."::"}{ISA}[0], $lft ),
		$st->{disabled} ? "disabled" : "enabled",
		$comic->{update} ? $comic->{updated} : "",
	      );
    }

}

use LWP::UserAgent;

our $ua;
our $uuid;

sub run_plugins {

    unless ( $ua ) {
	$ua = LWP::UserAgent::Custom->new;
	$uuid = uuid();
    }

    foreach my $comic ( @plugins ) {
	warn("Plugin: ", $comic->{name}, "\n") if $verbose > 1;

	# Force existence of this comic's state otherwise
	# it will be autovivified within the fetch method
	# and never get outside.
	$state->{comics}->{$comic->{tag}} ||= {};

	# Make the state accessible.
	$comic->{state} = $state->{comics}->{$comic->{tag}};

	# Skip is disabled.
	next if $comic->{state}->{disabled} && !$force;

	# Run it, trapping errors.
	$stats->{tally}++;
	unless ( eval { $comic->fetch($reuse); 1 } ) {
	    $comic->{state}->{fail} = $@;
	    debug($comic->{state}->{fail});
	    push( @{ $stats->{fail} },
		  [ $comic->{name}, $comic->{state}->{fail} ] );
	}
    }
}

################ Index subroutines ################

sub build {

    # Change to the spooldir and collect all HTML fragments.
    chdir($spooldir) or die("$spooldir: $!\n");
    opendir( my $dir, "." );
    my @files = grep { /^[^._].+(?<!index)\.(?:html)$/ } readdir($dir);
    close($dir);
    warn("Number of images = ", scalar(@files), "\n") if $debug;
    $stats->{tally} = $stats->{uptodate} = @files if $rebuild;

    # Sort the fragments on last modification date.
    @files =
      map { $_->[0] }
	sort { $b->[1] <=> $a->[1] }
	  grep { $force || ! $state->{comics}->{$_->[2]}->{disabled} }
	    map { ( my $t = $_ ) =~ s/\.\w+$//;
		  [ $_, (stat($_))[9], $t  ] }
	      @files;

    if ( $debug > 1 ) {
	warn("Images (sorted):\n");
	warn("   $_\n") for @files;
    }

    # Creat icon.
    unless ( -s "comics.png" ) {
	require Comics::Utils::Icon;
	open( my $fd, '>:raw', "comics.png" );
	print $fd Comics::Utils::Icon::icon();
	close($fd);
    }

    # Create a new index.html.
    open( my $fd, '>:utf8', "index.html" );
    preamble($fd);
    htmlstats($fd);
    for ( @files ) {
	open( my $hh, '<:utf8', $_ )
	  or die("$_: $!");
	print { $fd } <$hh>;
	close($hh);
    }
    postamble($fd);
    close($fd);
}

sub preamble {
    my ( $fd ) = @_;
    print $fd <<EOD;
<html>
<head>
<title>Comics!</title>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8">
<style type="text/css">
body {
    font-family : Verdana, Arial, Helvetica, sans-serif;
    text-align: center;
    margin-top: 0px;
    margin-right: 0px;
    margin-bottom: 10px;
    margin-left: 0px;
    font-size:12pt;
}
.toontable {
    background-color: #eee;
    padding: 9px;
    margin: 18px;
    border: 1px solid #ddd;
}
.toonimage {
    background-color: white;
    border: 0px;
}
a {
    text-decoration: none;
    color: black;
}
</style>
</head>
<body bgcolor='#ffffff'>
<a name="top"></a>
<div align="center">
EOD
}

sub postamble {
    my ( $fd ) = @_;
    print $fd <<EOD;
</div>
</body>
</html>
EOD
}

sub htmlstats {
    my ( $fd ) = @_;
    print $fd <<EOD;
<table width="100%" class="toontable" cellpadding="5" cellspacing="0">
  <tr><td nowrap align="center">
<p style="margin-left:5px"><a href="http://johan.vromans.org/software/sw_comics.html" target="_blank"><img src="comics.png" width="100" height="100" alt="[Comics]" align="middle"><font size="+4"><bold>Comics</bold></font></a><br>
<font size="-2">Comics $VERSION, last run: @{[ "".localtime() ]}<br>@{[ statmsg(1) ]}</font><br>
</p>      </td>
  </tr>
</table>
EOD
}

################ Statistics subroutines ################

sub statistics {
    return unless $verbose;
    warn( statmsg(), "\n" );
}

sub statmsg {
    my ( $html ) = @_;
    my $loaded = $stats->{loaded};
    my $tally = $stats->{tally};
    my $uptodate = $stats->{uptodate};
    my $fail = @{ $stats->{fail} };
    my $disabled = $stats->{disabled};
    my $excluded = $stats->{excluded};
    my $new = $stats->{tally} - $stats->{uptodate} - $fail;
    my $res = "Number of comics = $loaded (".
      "$new new, " .
	"$uptodate uptodate";
    $res .= ", $disabled disabled" if $disabled;
    $res .= ", $excluded excluded" if $excluded;
    if ( $fail ) {
	if ( $html ) {
	    $res .= ", <span title=\"";
	    for ( @{ $stats->{fail} } ) {
		my $t = $_->[1];
		$t =~ s/ at .*//s;
		$res .= $_->[0] . " ($t)&#10;";
	    }
	    $res .= "\">$fail fail</span>";
	}
	else {
	    $res .= ", $fail fail";
	}
    }
    return "$res)";
}

################ Miscellaneous ################

sub spoolfile {
    my ( $file ) = @_;
    File::Spec->catfile( $spooldir, $file );
}

sub uuid {
    my @chars = ( 'a'..'f', 0..9 );
    my @string;
    push( @string, $chars[int(rand(16))]) for (1..32);
    splice( @string,  8, 0, '-');
    splice( @string, 13, 0, '-');
    splice( @string, 18, 0, '-');
    splice( @string, 23, 0, '-');
    return join('', @string);
}

sub debug {
    return unless $debug;
    warn(@_,"\n");
}

sub debugging {
    $debug;
}

################ Command line handling ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally
    my $man = 0;		# handled locally

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        Pod::Usage->import;
        &pod2usage;
    };

    # Process options.
    if ( @ARGV > 0 ) {
	GetOptions('spooldir=s' => \$spooldir,
		   'refresh'	=> \$refresh,
		   'rebuild'    => \$rebuild,
		   'enable'	=> \$activate,
		   'disable'	=> sub { $activate = -1 },
		   'list'	=> \$list,
		   'force'	=> \$force,
		   'reuser'	=> \$reuse,
		   'ident'	=> \$ident,
		   'verbose+'	=> \$verbose,
		   'quiet'	=> sub { $verbose = 0 },
		   'trace'	=> \$trace,
		   'help|?'	=> \$help,
		   'man'	=> \$man,
		   'debug'	=> \$debug)
	  or $pod2usage->(2);
    }
    if ( $ident or $help or $man ) {
	print STDERR ("This is $my_name version $VERSION\n");
    }
    if ( $man or $help ) {
	$pod2usage->(1) if $help;
	$pod2usage->(VERBOSE => 2) if $man;
    }
}

################ Documentation ################

=head1 NAME

Comics - Comics aggregator in the style of Gotblah

=head1 SYNOPSIS

  perl -MComics -e 'main()' -- [options] [plugin ...]

or

  perl Comics.pm [options] [plugin ...]

If the associated C<collect> tool has been installed properly:

  collect [options] [plugin ...]

   Options:
     --spooldir=XXX	where resultant images and index must be stored
     --enable		enables the plugins (no aggregation)
     --disable		disables the plugins (no aggregation)
     --list		lists the plugins (no aggregation)
     --rebuild		rebuild index.html, no fetching
     --refresh		consider all images as new
     --ident		shows identification
     --help		shows a brief help message and exits
     --man              shows full documentation and exits
     --verbose		provides more verbose information
     --quiet		provides no information unless failure

=head1 OPTIONS

=over 8

=item B<--spooldir=>I<XXX>

Designates the spool area. Downloaded comics and index files are
written here.

=item B<--enable>

The plugins that are named on the command line will be enabled for
future runs of the aggregator. Default is to enable all plugins.

Note that when this command is used, the program exits after enabling
the plugins. No aggregation takes place.

=item B<--disable>

The plugins that are named on the command line will be disabled for
future runs of the aggregator. Default is to disable all plugins.

Note that when this command is used, the program exits after disabling
the plugins. No aggregation takes place.

=item B<--list>

Provides information on the selected (default: all) plugins.

Note that when this command is used, no aggregation takes place.

=item B<--rebuild>

Recreates index.html in the spooldir without fetching new comics.

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

Provides more verbose information. This option may be repeated for
even more verbose information.

=item B<--quiet>

Silences verbose information.

=item I<plugin>

If present, process only the specified plugins.

This is used for disabling and enabling plugins, but it can also be
used to test individual plugins.

=back

=head1 DESCRIPTION

The normal task of this program is to perform aggregation. it will
load the available plugins and run all of them.

The plugins will examine the contents of comics sites and update the
'cartoon of the day' in the spool area.

Upon completion, an index.html is generated in the spool area to view
the comics collection.

It is best to run this program from the spool area itself.

=head2 Special commands

Note that no aggregation is performed when using any of these commands.

With command line option B<--list> a listing of the plugins is produced.

Plugins can be enabled and disabled with B<--enable> and B<--disable>
respectively.

=head1 PLUGINS

B<Important:> This program assumes that the plugins can be found in
C<../lib> relative to the location of the executable file.

All suitable C<Comics::Plugin::>I<plugin>C<.pm> files are examined
and loaded.

Plugins are derived from Fetcher classes, see below.

See L<Comics::Plugin::Sigmund> for a fully commented plugin.

=head1 FETCHERS

Fetchers implement different fetch strategies. Currently provided are:

L<Comics::Fetcher::Cascade> - fetch a comic by loading and examining a series of URLs.

L<Comics::Fetcher::Direct> - fetch a comic by URL.

L<Comics::Fetcher::Single> - fetch a comic by examining the comic's home page.

L<Comics::Fetcher::GoComics> - fetch a comic from a GoComics site.

=cut

package LWP::UserAgent::Custom;
use parent qw(LWP::UserAgent);

use HTTP::Cookies;
my $cookie_jar;

sub new {
    my ( $pkg ) = @_;
    my $self = $pkg->SUPER::new();
    bless $self, $pkg;

    $self->agent('Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:60.0) Gecko/20100101 Firefox/60.0');
    $self->timeout(10);
    $cookie_jar ||= HTTP::Cookies->new
      (
       file	       => ::spoolfile(".lwp_cookies.dat"),
       autosave	       => 1,
       ignore_discard  => 1,
      );
    $self->cookie_jar($cookie_jar);

    return $self;
}

sub get {
    my ( $self, $url ) = @_;

    my $res;

    my $sleep = 1;
    for ( 0..4 ) {
	$res = $self->SUPER::get($url);
	$cookie_jar->save;
	last if $res->is_success;
	# Some sites block LWP queries. Show why.
	if ( $res->status_line =~ /^403/ ) {
	    use Data::Dumper;
	    warn(Dumper($res));
	    exit;
	}
	last if $res->status_line !~ /^5/; # not temp fail
	print STDERR "Retry..." if $verbose;
	sleep $sleep;
	$sleep += $sleep;
    }

    return $res;
}

1;

=head1 AUTHOR

Johan Vromans, C<< <JV at CPAN dot org> >>

=head1 SUPPORT

Development of this module takes place on GitHub:
https://github.com/sciurius/comics .

You can find documentation for this module with the perldoc command.

    perldoc Comics

Please report any bugs or feature requests using the issue tracker on
GitHub.

=head1 ACKNOWLEDGEMENTS

The people behind Gotblah, for creating the original tool.

=head1 LICENSE

Copyright (C) 2016,2018 Johan Vromans,

This module is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

package main;

unless ( caller ) {
    main();
}

1;
