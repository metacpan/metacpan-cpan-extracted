#!/usr/bin/env perl

use strict;
use warnings;

use Path::Class qw( dir );
use File::Spec::Functions qw( splitpath splitdir );
use File::Find::Rule qw();
use Module::Info qw();
use Data::Dumper qw( Dumper );
use CPAN qw();
use BackPAN::Index qw();
use List::MoreUtils qw( uniq );
use List::Util qw( reduce );
use ExtUtils::Installed qw();
use Module::Extract::VERSION qw();
use Module::Build::ModuleInfo qw();
use Text::Trim qw( trim );
use Config;
#use Module::Build::Version;

main( @ARGV );
# TODO add cli opts to add/remove paths to search

sub main {
    my @args = @_;

    my %opts; # fill from @args using Getopts::Long

    my @search_dirs = determine_search_dirs( %opts );
    my @pm_files = find_pm_files( @search_dirs );

    # turn pm file paths into module/package names. there may be duplicate
    # entries, for example from modules installed both as a vendor package
    # and from CPAN (and therefore in different paths), but we just need
    # the name for now and will decide later *which* one is important.
    my @module_names =
        uniq map { join( '::', splitdir( substr( $_, 0, -3 ) ) ) } @pm_files;

    # get a hash of {mod_name => Module::Info obj} and an array with the 
    # names of modules that module::info couldn't load/parse.
    my ($mi_objs, $non_loadable_mod_names) =
        load_module_info_objs( \@module_names, \@search_dirs );

    # try to match installed modules to their CPAN distributions and get a
    ## bunch of other info on the possible dists and the modules. also, track
    # modules that will be skipped for various reasons. (eg, no matching dist,
    # couldn't parse out needed info, core/vendor-packaged modules, etc...)
    my ($dist_info, $skipped_modules) = 
        collect_module_dist_info( $mi_objs, \@search_dirs );

    # use all this data to guess what CPAN releases are installed on this 
    # machine. If we can find a matching dist name and version on the backpan
    # we'll assume there's a match.
    #
    # $bp_releases is a hash of { dist name => [ dist file paths...] }
    # $no_release_matched is an array of dist names where no matches were found
    # $dist_info will have additional bits of data added, in case we really
    # need to do more processing for some reason :)
    my ($bp_releases, $no_release_matched) = find_backpan_releases( $dist_info );

    print Dumper $bp_releases, {
        no_match => $no_release_matched,
        skipped  => $skipped_modules,
        bad_names => $non_loadable_mod_names,
    };
    my $total_releases = do {
        no warnings 'once';
        reduce { $a + $b }
            map { scalar @$_ } values %$bp_releases;
    };
    print "TOTAL RELEASES MATCHED: $total_releases\n";

    return 1;
}






# we want to only search dirs that will be useful... therefore, we need to
#  a. weed out obvious dead-ends like duplicate and non-existent paths.
#  b. resolve all paths and make them absolute, so the output data is sane.
sub determine_search_dirs {
    my %opts = @_;

    my @search_dirs =
        grep { -e } uniq
            map { dir($_)->absolute } #->resolve }
                @INC;

    # no need to return Path::Class: objects
    return map { "$_" } @search_dirs;
}


# find all the pm files, relative to each directory 
# (for easier translation into module/package names)
sub find_pm_files {
    my @search_dirs = @_;

    my @pm_files;
    for my $dir ( @search_dirs ) {
        push @pm_files, File::Find::Rule
            ->extras( { follow => 1 } )
            ->relative
            ->file
            ->name( '*.pm' )
            ->in( $dir );
    }
    return @pm_files;
}


# next, construct a Module::Info object for each module but keep
# track of invalid names and mods M::I couldn't load (we won't
# do anything with them, but it may be useful to know)
sub load_module_info_objs {
    my ($module_names, $search_dirs) = @_;
    my @bad_modules;
    my %module_data =
        map  { @$_ }
        # filter out modules that couldn't be found/parsed
        grep { defined $_->[1]{mod_info} ? 1 : 0 * push @bad_modules, $_->[0] }
        # get info on the specific module that would be loaded by perl
        map  { [ $_, { mod_info => Module::Info->new_from_module( $_, @$search_dirs ) } ] }
        # filter out invalid module names
        grep { $_ !~ /[^\w\:]/ ? 1 : 0 * push @bad_modules, $_ }
        @$module_names;

    return \%module_data, \@bad_modules;
}

sub collect_module_dist_info {
    my ($module_info_objs, $search_dirs) = @_;

    my %dist_info;       # info on dists that our modules match
    my %skipped_modules = (  # info on modules we skip
        is_core         => [], # perl core, not from CPAN
        is_vendor       => [], # NOTE: right now these end up in no_dist_found.
        no_dist_found   => [], # CPAN couldn't match a dist
        bad_dist_name   => [], # dist found, but bad/weird file name (rare)
    );

    # an ExtUtils::Installed object for getting info on modules
    # installed via CPAN or manually with the "mantra". not
    # sure if the info we get from this is useful yet.
    my $eui_obj = ExtUtils::Installed->new( inc_override => $search_dirs );

    # note: $mod_data will have various bits of additional
    # info added to it as we inspect the module.
    MODULE:
    for my $mod_data ( values %$module_info_objs ) {

        my $mi_obj   = $mod_data->{mod_info};
        my $mod_name = $mi_obj->name;
        my $mod_file = $mi_obj->file;

        # make mi use version.pm objects (or not)
        $mi_obj->use_version( 1 );

        # skip core mods
        if ( $mi_obj->is_core ) {
            push @{ $skipped_modules{is_core} }, $mod_name;
            next MODULE;
        }

        ## skip vendor mods
        #for my $dir ( @Config{qw(installvendorarch installvendorlib)} ) {
        #    if ( dir($dir)->subsumes($mod_file) ) {
        #        push @{ $skipped_modules{is_vendor} }, $mod_name;
        #        next MODULE;
        #    }
        #}

        # look for a version in the module file
        $mod_data->{mi_mod_inst_ver} = $mi_obj->version;

        # supposedly this uses the same method of version
        # extraction as mldistwatch
        $mod_data->{mev_mod_inst_ver} =
            Module::Extract::VERSION->parse_version_safely( $mod_file );

        # this is (kinda) how Module::Build gets the version... but messier and not really.
        if ( eval { "$mod_data->{mi_mod_inst_ver}" } and my $pm_info =
            eval { Module::Build::ModuleInfo->new_from_file( $mi_obj->file ) }
        ) {
            if (my $ver = $pm_info->version() ) {
                $mod_data->{mb_mod_inst_ver} = 
                    ! UNIVERSAL::can($ver, 'is_qv') ? 
                        $ver : $ver->is_qv ? 
                            $ver->normal : $ver->stringify;
            }
        }

        # what does EU(I|MM) think the version is?
        $mod_data->{eu_mod_inst_ver} = eval { $eui_obj->version( $mod_name ) };


        # see if the cpan client knows about this module
        my $cpan_mod = CPAN::Shell->expand( "Module", $mod_name );
        if ( ! $cpan_mod ) {
            push @{ $skipped_modules{no_dist_found} }, $mod_name;
            next MODULE;
        }
        $mod_data->{cpan_mod_obj} = $cpan_mod;

        # the cpan client may have yet another way of getting the version.
        $mod_data->{cpan_mod_inst_ver} = $cpan_mod->inst_version;

        # what does cpan think the latest version of this module is?
        $mod_data->{cpan_mod_latest_ver} = $cpan_mod->cpan_version;

        # also see what dist file cpan thinks this module belongs to
        my $cpan_file = $cpan_mod->cpan_file;
        $mod_data->{cpan_dist_latest_file} = $cpan_file;

        # try parse the dist file path for more info...
        # NOTE: seems that some values of $cpan_file are arbitrary text, but $di
        # objs are still created? perhaps the CPAN::Module docs can tell me more.
        my $di = CPAN::DistnameInfo->new( $cpan_file );
        if ( ! $di || ! $di->dist ) {
            # if no val for dist(), probably hit a weird filename.
            push @{ $skipped_modules{bad_dist_name} }, $mod_name;
            next MODULE;
        }
        $mod_data->{cpan_dist_info} = $di;

        my $dist_name = $di->dist;
        my $latest_dist_ver  = $di->version;
        $mod_data->{cpan_dist_name}       = $dist_name;
        $mod_data->{cpan_dist_latest_ver} = $latest_dist_ver;

        push @{ $dist_info{$dist_name}{$latest_dist_ver}{module_data} }, $mod_data;
    }

    return \%dist_info, \%skipped_modules;
}


# use the info we have to:
#  a. guess which version of the dist is installed
#  b. look for a release (dist-name + version) in the backpan index.
sub find_backpan_releases {
    my ($dist_info) = @_;

    # releases we were able to match are hits
    # dists where we couldn't find a match are misses
    my %bp_hits;    # dist_name => file_path
    my @bp_misses;  # dist_name

    my $bp = BackPAN::Index->new();

    DIST:
    for my $dist_name ( keys %$dist_info ) {
        #next unless $dist_name eq "CPAN-Mini";
        for my $latest_dist_ver ( keys %{ $dist_info->{$dist_name} } ) {

            my $release_data = $dist_info->{$dist_name}{$latest_dist_ver};

            # THEORY: if we look at all the latest CPAN::Module objects 
            # in this release (supposedly the latest from CPAN) and at 
            # least one module has the same version as the dist, then 
            # we can assume that the "installed version" of that same
            # module is the version of the dist we want to find as a 
            # release on the backpan.

            my @version_types = qw( mb_mod_inst_ver mev_mod_inst_ver cpan_mod_inst_ver mi_mod_inst_ver );
            my @version_guesses;
            for my $mod_data ( @{ $release_data->{module_data} } ) {
                next unless $latest_dist_ver eq $mod_data->{cpan_mod_latest_ver};
                push @version_guesses, grep { $_ and $_ ne 'undef' } 
                    @{$mod_data}{@version_types};
            }
            @version_guesses = reverse uniq sort @version_guesses;

            if ( ! @version_guesses ) {
                # if we couldn't find a correlation between the dist version
                # and any of the module versions, move on.
                #printf "%-30s %-15s [no matching module versions]\n", $dist_name, $latest_dist_ver;
                push @bp_misses, $dist_name;
                next DIST;
            }

            #printf "%-30s %-15s [%s] ", $dist_name, $latest_dist_ver, join ' ', @version_guesses;

            # maybe we have to latest CPAN version?
            if( grep { $_ eq $latest_dist_ver } @version_guesses ) {
                #print "[LATEST]\n";
                next DIST;
            }

            for my $ver_guess ( @version_guesses ) {
                if( my $bp_release = $bp->release( $dist_name, $ver_guess ) ) {
                    my $rel_path = $bp_release->path;
                    push @{ $bp_hits{ $dist_name } ||= [] }, "$rel_path";
                    #print "[FOUND: " . join( ' ', $rel_path ). "]\n";
                    next DIST;
                }
            }
            #print "[NOT FOUND]\n";
            push @bp_misses, $dist_name;
        }
    }
    return \%bp_hits, \@bp_misses;
}

