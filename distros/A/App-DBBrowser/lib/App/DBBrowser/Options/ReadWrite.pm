package # hide from PAUSE
App::DBBrowser::Options::ReadWrite;

use warnings;
use strict;
use 5.016;

use App::DBBrowser::Auxil;
use App::DBBrowser::Options::Defaults;


sub new {
    my ( $class, $info, $options ) = @_;
    bless {
        i => $info,
        o => $options
    }, $class;
}


sub write_config_file {
    my ( $sf, $lo, $plugin ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, {} );
    if ( $plugin ) {
        my $file_fs = sprintf( $sf->{i}{plugin_config_file_fmt}, $plugin );
        $ax->write_json( $file_fs, $lo  );
    }
    else {
        $ax->write_json( $sf->{i}{f_global_settings}, $lo );
    }
}


sub read_config_file {
    my ( $sf, $driver, $plugin ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, {} );
    my $op_df = App::DBBrowser::Options::Defaults->new( $sf->{i}, {} );
    my $lo = {};
    if ( $plugin ) {
        my $file_fs = sprintf( $sf->{i}{plugin_config_file_fmt}, $plugin );
        $lo = $ax->read_json( $file_fs ) // {};
        if ( ! %{$lo//{}} ) {
            $lo = $op_df->defaults( $driver );
        }

        ####### 19.02.2026 ############
        if ( exists $lo->{table}{max_width_exp} || exists $lo->{table}{min_col_width} || ! exists $lo->{table}{expanded_line_spacing}) {
            $lo->{table}{expanded_line_spacing} = 1 if ! exists $lo->{table}{expanded_line_spacing};

            $lo->{table}{expanded_max_width} = delete $lo->{table}{max_width_exp} if exists $lo->{table}{max_width_exp};
            $lo->{table}{col_trim_threshold} = delete $lo->{table}{min_col_width} if exists $lo->{table}{min_col_width};

            my $file_fs = sprintf( $sf->{i}{plugin_config_file_fmt}, $plugin );
            $sf->write_config_file( $lo, $plugin ) if -f $file_fs;
        }
        ###############################

        ####### 23.06.2026 ############
        if ( ! defined $lo->{insert}{max_cols_plain} ) {
            my $file_fs = sprintf( $sf->{i}{plugin_config_file_fmt}, $plugin );
            $lo->{insert}{max_cols_plain} = 25;
            $sf->write_config_file( $lo, $plugin ) if -f $file_fs;
        }
        ###############################

    }
    else {
        $lo = $ax->read_json( $sf->{i}{f_global_settings} ) // {};
        if ( ! %{$lo//{}} ) {
            $lo = $op_df->defaults_pre_plugin();
        }
        $sf->{i}{tc_default}{mouse} = $lo->{table}{mouse};
        $sf->{i}{tcu_default}{mouse} = $lo->{table}{mouse};
    }
    if ( defined wantarray ) {
        return $lo;
    }
    else {
        for my $section ( keys %$lo ) {
            for my $opt ( keys %{$lo->{$section}} ) {
                $sf->{o}{$section}{$opt} = $lo->{$section}{$opt};
            }
        }
    }
}





1;


__END__
