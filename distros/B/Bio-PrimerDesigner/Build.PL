# $Id: Build.PL 26 2008-11-10 20:36:37Z kyclark $

use strict;
use warnings;
use Cwd;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use File::Spec::Functions 'catfile';

eval { require Module::Build };
if ( $@ =~ /Can\'t locate/ ) {
    print qq[Please install "Module::Build" before continuing.\n];
    exit(0);
}

my $help = '';
my $url  = '';
GetOptions(
    'h|help' => \$help,
    'url:s'  => \$url,
);

if ( $help ) {
    pod2usage({ -exitval => 0 });
}

#
# Write any local config info to the Config file
#
if ( $url && $url !~ m{^http://} ) {
    $url = 'http://' . $url;
}

my $cwd       = cwd;
my $tmpl_file = catfile( $cwd, 'templates', 'Config.pm' );
open my $in_fh, '<', $tmpl_file or die "Can't read $tmpl_file: $!\n";
my $tmpl      = join('', <$in_fh>);
my $config    = sprintf( $tmpl, "  local_url => '$url'," );
close $in_fh;

my $config_pm = catfile( cwd(), 'lib', 'Bio', 'PrimerDesigner', 'Config.pm' );
open my $out_fh, '>', $config_pm or die "Can't write '$config': $!\n";
print $out_fh $config;
close $out_fh;

# 
# Here we make the Build script
# 
my $builder = Module::Build->new(
    create_readme        => 1,
    dist_name            => 'Bio-PrimerDesigner',
    dist_abstract        => 'Design PCR primers using primer3 and epcr',
    dist_author          => 'Sheldon McKay <mckays@cshl.edu>; Ken Youens-Clark <kclark@cshl.edu>',
    module_name          => 'Bio::PrimerDesigner',
    dist_version         => 0.04,
    license              => 'gpl',
    script_files         => [ 'scripts/primer_designer' ],
    requires             => {
        'Class::Base'         => 0,
        'HTTP::Request'       => 0,
        'HTTP::Response'      => 0,
        'LWP::UserAgent'      => 0,
        'Readonly'            => 0,
    },
    test_requires        => {
        'Test::More'          => 0,
        'Test::Pod::Coverage' => 0,
        'Test::Pod'           => 0,
    },
);

my $tarball = $builder->dist_dir . '.tar.gz';

$builder->add_to_cleanup( $tarball, 'lib/Bio/PrimerDesigner/Config.pm' );

$builder->create_build_script;

print "Now run './Build' and './Build install'\n";

exit 0;

__END__

=pod

=head1 NAME

Build.PL - Installer for Bio::PrimerDesigner

=head1 SYNOPSIS

  perl Build.PL [options]

Options:

  -h|--help   Show usage
  --url       The URL to use for remote program access, e.g.,
              http://my.org/cgi-bin/primer_designer.cgi

=head1 AUTHOR

Ken Youens-Clark E<lt>kclark@cpan.orgE<gt>.

=cut
