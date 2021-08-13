use 5.008;

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Build;
use My::Module::Meta;
use My::Module::Recommend;
use Module::Build;
use Config;

( my $mbv = Module::Build->VERSION() ) =~ s/_//g;

my $meta = My::Module::Meta->new();

My::Module::Recommend->recommend();

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

$mbv >= 0.34
    and $args{auto_configure_requires} = 0;	# Don't require Module::Build

my $bldr = My::Module::Build->new( %args );

my %opt = $bldr->args();

my ( @exe_files, @clean_files );

print <<EOD;

The simbadc script is a simple wrapper for Astro::SIMBAD::Client, which
may be used interactively or as a Unix filter.

>>>> NOTICE <<<<\a\a\a

As of version 0.032_01 the simbadc script is installed by default. If
you do not wish it installed. run this script with the -n option. The -y
option is still accepted for backward compatibility.

EOD

if ( $opt{n} ) {
    print "Because you have asserted -n, simbadc will not be installed.\n";
} else {
    push @exe_files, 'simbadc';
}

if ($^O eq 'MSWin32') {
    @exe_files = map { "script/$_" } @exe_files;
    foreach (@exe_files) {`pl2bat $_`}
    @clean_files = @exe_files = grep {-e $_} map {"$_.bat"} @exe_files;
} elsif ($^O eq 'VMS') {
    foreach my $fni (map { "[.script]$_" } @exe_files) {
	my $fno = "$fni.com";
	open (my $fhi, '<', $fni) or die "Unable to open $fni: $!\n";
	open (my $fho, '>', $fno) or die "Unable to open $fno: $!\n";
	print $fho "$Config{startperl}\n";
	while (<$fhi>) {print $fho $_}
	close $fho;
	close $fhi;
    }
    @clean_files = @exe_files = map { "[.script]$_.com" } @exe_files;
} else {
    @exe_files = map {"script/$_"} @exe_files;
}

$bldr->add_to_cleanup( [
	@{ $meta->add_to_cleanup() },
	@clean_files,
    ],
);
@exe_files and $bldr->script_files (\@exe_files);

$bldr->create_build_script ();

# ex: set textwidth=72 :
