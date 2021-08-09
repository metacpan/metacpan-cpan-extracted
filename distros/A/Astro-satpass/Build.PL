use 5.006002;

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Build;
use My::Module::Meta;
use My::Module::Recommend;
use Module::Build;
use Config;
use FileHandle;

(my $mbv = Module::Build->VERSION) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %args = (
    add_to_cleanup	=> [],
    build_requires	=> $meta->build_requires(),
    configure_requires	=> $meta->configure_requires(),
    dist_abstract	=> $meta->abstract(),
    dist_author	=> $meta->author(),
    dist_name	=> $meta->dist_name(),
    license	=> $meta->license(),
    module_name	=> $meta->module_name(),
    requires	=> $meta->requires(
	perl	=> $meta->requires_perl(),
    ),
    script_files	=> [],
);

$mbv >= 0.26
    and $args{get_options} = {
	n	=> { type => '!' },
	y	=> { type => '!' },
    };

if ( $mbv >= 0.28 ) {
    $args{meta_merge} = $meta->meta_merge();
    $args{no_index} = $meta->no_index();
    $args{meta_add} = {
	$meta->provides(),
    },
}

# Don't require Module::Build if we are making a distribution, since the
# user may choose to use ExtUtils::MakeMaker.
$mbv >= 0.34
    and $args{auto_configure_requires} = !$meta->distribution();

My::Module::Recommend->recommend();

my $bldr = My::Module::Build->new( %args );

my %opt = $bldr->args();

my @exe_files;
my @clean_files;

print <<"EOD";

The following executable can be installed:

  satpass is a scriptable program to predict satellite passes
    over a given observer.

If you do not want this, run Makefile.PL with the -n option. If you want
to install without being asked, run Makefile.PL with the -y option.

>>>> NOTICE <<<<\a\a\a

As of release 0.066, this script no longer asks whether
the satpass script should be installed, since it is being deprecated
(slowly) in favor of Astro::App::Satpass2. If you want the satpass
script installed, you should run this script with the -y option. You can
make this the default in your CPAN client by installing the preferences
file eg/Astro-Coord-ECI.yml in .cpan/prefs.

EOD

my @possible_exes = qw{satpass};
if ( $opt{n} ) {
    print "Because you have asserted -n, the executables will not be installed.\n\n";
} elsif ( $opt{y} ) {
    print "Because you have asserted -y, the executables will be installed.\n\n";
    @exe_files = @possible_exes;
}

if (@exe_files) {
    if ($^O eq 'MSWin32') {
	@exe_files = map {"script/$_"} @exe_files;
	foreach (@exe_files) {`pl2bat $_`}
	@clean_files = @exe_files =
	    grep {-e $_} map {"$_.bat"} @exe_files;
    } elsif ($^O eq 'VMS') {
	foreach my $fni (map {"[.script]$_"} @exe_files) {
	    my $fno = "$fni.com";
	    my $fhi = FileHandle->new ("<$fni") or die <<eod;
Error - Unable to open $fni
        $!
eod
	    my $fho = FileHandle->new (">$fno") or die <<eod;
Error - Unable to open $fno
        $!
eod
	    print $fho "$Config{startperl}\n";
	    while (<$fhi>) {print $fho $_}
	    }
	@clean_files = @exe_files = map {"[.script]$_.com"} @exe_files;
    } else {
	@exe_files = map {"script/$_"} @exe_files;
    }
}

$bldr->add_to_cleanup( @{ $meta->add_to_cleanup() }, @clean_files );
$bldr->script_files( \@exe_files );

$bldr->create_build_script ();

# ex: set textwidth=72 :
