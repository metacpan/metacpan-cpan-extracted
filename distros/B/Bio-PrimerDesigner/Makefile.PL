# $Id: Makefile.PL,v 1.6 2004/03/04 23:26:20 kclark Exp $

use strict;
use ExtUtils::MakeMaker;
use Cwd;
use File::Spec::Functions 'catfile';

my $USAGE = join( "\n",
    '',
    'Bio::PrimerDesign Install Help',
    '',
    'To customize your installation, please specify any of ',
    'the following arguments:',
    '  URL (the URL to use for remote program access)',
    'e.g., "perl Makefile.PL URL=http://my.org/cgi-bin/primer_designer.cgi"',
    '',
    '',
);

my $OPTION_NAMES = join( '|', 'URL' );
my %OPTIONS;

#
# Clear out @ARGV so this script's args don't get confused, 
# push back any args not ours.
#
my @argv = @ARGV;
@ARGV    = ();
foreach ( @argv ) {
    if ( /^--?h(elp)?/i ) {
        print $USAGE;
        exit(0);
    }
    elsif ( /($OPTION_NAMES)=(.+)/og ) {
        $OPTIONS{$1} = $2;
    }
    else {
        push @ARGV, $_;
    }
}

#
# Record any args for use in configuring modules later.
#
my $install_conf = catfile( cwd(), 'install.conf' );
open F,">$install_conf" or die "Can't write $install_conf: $!\n";
foreach ( keys %OPTIONS ) {
    print F "$_=$OPTIONS{$_}\n";
}
close F;

WriteMakefile(
    NAME                 => 'Bio::PrimerDesigner',
    VERSION_FROM         => 'lib/Bio/PrimerDesigner.PMS',
    AUTHOR               => 'Sheldon McKay <smckay@bcgsc.bc.ca>',
    ABSTRACT             => 'Design PCR primers using primer3 and epcr',
    PREREQ_PM            => {
        'Test::More'     => 0,
        'Class::Base'    => 0,
        'HTTP::Request'  => 0,
        'HTTP::Response' => 0,
        'LWP::UserAgent' => 0,
    },
    PL_FILES             => {
        'bin/primer_designer.PLS'     => 'bin/primer_designer.pl',
        'bin/primer_designer.cgi.PLS' => 'bin/primer_designer.cgi',
        'lib/Bio/PrimerDesigner.PMS'  => 'lib/Bio/PrimerDesigner.pm',
    },
    EXE_FILES            => [
        'bin/primer_designer.pl',
    ],
    clean                => {
        FILES            => 'install.conf $(DISTNAME)-$(VERSION).tar.gz',
    },
);
