package My::Builder;

use strict;
use warnings;

use Module::Build;
our @ISA = 'Module::Build';

sub new {
    my $class = shift @_;

    {
        my $B_Utils_required = 0.05;
        eval {
            require B::Utils;
        };
        if ( $@ or B::Utils->VERSION < $B_Utils_required ) {

            # If I don't have B::Utils then I must have ExtUtils::Depends
            my $ExtUtils_Depends_required = 0.302; #minimum version that works on Win32+gcc
            eval {
                require ExtUtils::Depends;
            };
            if ( $@ or ExtUtils::Depends->VERSION < $ExtUtils_Depends_required ) {
                print "ExtUtils::Depends $ExtUtils_Depends_required is required to configure our B::Utils dependency, please install it manually or upgrade your CPAN/CPANPLUS\n";
                exit(0);
            }
        };
    }

    # Handle both: `./Build.PL DDS' and `./Build.PL NODDS'
    #
    my $create_dds_alias;
    if ( @ARGV && $ARGV[0] =~ /^(?:NO)?DDS$/i ) {
        my $arg = uc shift @ARGV;
        $create_dds_alias = 'DDS' eq $arg;
    }

    print "Installing Data::Dump::Streamer\n";

    if ( ! defined $create_dds_alias
         && -e '.answer'
         && open my $fh, "<", '.answer') {
        print "I will install (or not) the DDS shortcut as you requested previously.\n";
        print "If you wish to override the previous answer then state so explicitly\n";
        print "by saying 'perl Build.PL [NO]DDS'\n";
        my $cached_value = <$fh>;
        chomp $cached_value;
        print "Previous answer was: $cached_value\n";
        
        $create_dds_alias = 'yes' eq lc $cached_value;
    }
    
    if ( ! defined $create_dds_alias ) {
        my $default =
            ( 0 == system( qq($^X -e "chdir '/';exit( eval { require DDS } ? 0: 1 )") )
              || ( -e "./lib/DDS.pm") )
            ? 'yes'
            : 'no';
        print "\n";
        print "I can install a shortcut so you can use the package 'DDS'\n";
        print "as though it was 'Data::Dump::Streamer'. This is handy for oneliners.\n";
        print "*Note* that if you select 'no' below and you already\n";
        print "have it installed then it will be removed.\n";
        print "\n";
        my $yn = !! $class->y_n("Would you like me to install the shortcut? (yes/no)",
                                $default);
        if (open my $fh, ">", '.answer') {
            print $fh $yn ? "yes\n" : "no\n";
            close $fh;
        }
        $create_dds_alias = $yn;
    }

    my $self = $class->SUPER::new( @_ );

    if ( $create_dds_alias  ) {
        print "I will also install DDS as an alias.\n";
        open my $ofh, ">", "./lib/DDS.pm"
            or die "Failed to open ./lib/DDS.pm: $!";
        print { $ofh } DDS();
        close $ofh;

        $self->add_to_cleanup( './lib/DDS.pm' );
    }
    else {
        unlink "./lib/DDS.pm";
    }

    return $self;
}

sub DDS {
    my $text = <<'EOF_DDS';
##This all has to be one line for MakeMaker version scanning.
#use Data::Dump::Streamer (); BEGIN{ *DDS:: = \%Data::Dump::Streamer:: } $VERSION=$DDS::VERSION;
#1;
#
#=head1 NAME
#
#DDS - Alias for Data::Dump::Streamer
#
#=head1 SYNOPSIS
#
#  perl -MDDS -e "Dump \%INC"
#
#=head1 DESCRIPTION
#
#See L<Data::Dump::Streamer>.
#
#=head1 VERSION
#
# $Id: Makefile.PL 30 2006-04-16 15:33:25Z demerphq $
#
#=cut
#
EOF_DDS
    $text =~ s/^#//gm;
    return $text;
}



1;
