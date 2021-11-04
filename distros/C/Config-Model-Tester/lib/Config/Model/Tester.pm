#
# This file is part of Config-Model-Tester
#
# This software is Copyright (c) 2013-2020 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Tester 4.007;
# ABSTRACT: Test framework for Config::Model

use warnings;
use strict;
use locale;
use utf8;
use 5.12.0;

use Test::More;
use Log::Log4perl 1.11 qw(:easy :levels);
use Path::Tiny;
use File::Copy::Recursive qw(fcopy rcopy dircopy);

use Test::Warn;
use Test::Exception;
use Test::File::Contents ;
use Test::Differences;
use Test::Memory::Cycle ;

use Config::Model::Tester::Setup qw/init_test setup_test_dir/;

# use eval so this module does not have a "hard" dependency on Config::Model
# This way, Config::Model can build-depend on Config::Model::Tester without
# creating a build dependency loop.
eval {
    require Config::Model;
    require Config::Model::Lister;
    require Config::Model::Value;
    require Config::Model::BackendMgr;
} ;

use vars qw/@ISA @EXPORT/;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(run_tests);

$File::Copy::Recursive::DirPerms = oct(755);

sub setup_test {
    my ( $test_group, $t_name, $wr_root, $trace, $test_suite_data, $t_data ) = @_;

    # cleanup before tests
    $wr_root->remove_tree();
    $wr_root->mkpath( { mode => oct(755) } );
    my ($conf_dir, $conf_file_name, $home_for_test)
        = @$test_suite_data{qw/conf_dir conf_file_name home_for_test/};

    if ($conf_dir and $home_for_test) {
        $conf_dir =~ s!~/!$home_for_test/!;
        $test_suite_data->{conf_dir} = $conf_dir;
    }

    my $wr_dir    = $wr_root->child($test_group)->child('test-' . $t_name);
    my $wr_dir2   = $wr_root->child($test_group)->child('test-' . $t_name.'-w');
    $wr_dir->mkpath;
    $wr_dir2->mkpath;

    my $conf_file ;
    $conf_file = $wr_dir->child($conf_dir,$conf_file_name)
        if $conf_dir and $conf_file_name;

    my $ex_dir = $t_data->{data_from_group} // $test_group;
    my $ex_path = path('t')->child('model_tests.d', "$ex_dir-examples");
    my $ex_data = $ex_path->child($t_data->{data_from} // $t_name);

    my @file_list;

    if (my $setup = $t_data->{setup}) {
        foreach my $file (keys %$setup) {
            my $map = $setup->{$file} ;
            my $destination_str
                = ref ($map) eq 'HASH' ? $map->{$^O} // $map->{default}
                : ref ($map) eq 'ARRAY' ? $map->[-1]
                :                        $map;
            if (not defined $destination_str) {
                die "$test_group $t_name setup error: cannot find destination for test file $file" ;
            }
            $destination_str =~ s!~/!$home_for_test/! if $home_for_test;
            my $destination = $wr_dir->child($destination_str) ;
            $destination->parent->mkpath( { mode => oct(755) }) ;
            my $data_file = $ex_data->child($file);
            die "cannot find $data_file" unless $data_file->exists;
            my $data = $data_file->slurp() ;
            $destination->spew( $data );
            if (ref $map eq 'ARRAY') {
                my @tmp = @$map;
                pop @tmp; # remove destination
                foreach my $link_str (@tmp) {
                    $link_str =~ s!~/!$home_for_test/! if $home_for_test;
                    my $link = $wr_dir->child($link_str);
                    $link->parent->mkpath( { mode => oct(755) }) ;
                    symlink $destination->absolute->stringify, $link->stringify;
                }
            }
            @file_list = list_test_files ($wr_dir);
        }
    }
    elsif ( $ex_data->is_dir ) {
        # copy whole dir
        my $destination_dir = $conf_dir ? $wr_dir->child($conf_dir) : $wr_dir ;
        $destination_dir->mkpath( { mode => oct(755) });
        say "dircopy ". $ex_data->stringify . '->'. $destination_dir->stringify
            if $trace ;
        dircopy( $ex_data->stringify, $destination_dir->stringify )
          || die "dircopy $ex_data -> $destination_dir failed:$!";
        @file_list = list_test_files ($destination_dir);
    }
    elsif ( $ex_data->exists ) {
        # either one if true if $conf_file is undef
        die "test data is missing global \$conf_dir" unless defined $conf_dir;
        die "test data is missing global \$conf_file_name" unless defined $conf_file;

        # just copy file
        say "file copy ". $ex_data->stringify . '->'. $conf_file->stringify
            if $trace ;
        fcopy( $ex_data->stringify, $conf_file->stringify )
          || die "copy $ex_data -> $conf_file failed:$!";
    }
    else {
        note ('starting test without original config data, i.e. from scratch');
    }
    ok( 1, "Copied $test_group example $t_name" );

    return ( $wr_dir, $wr_dir2, $conf_file, $ex_data, @file_list );
}

#
# New subroutine "list_test_files" extracted - Thu Nov 17 17:27:20 2011.
#
sub list_test_files {
    my $debian_dir = shift;
    my @file_list ;

    my $iter = $debian_dir->iterator({ recurse => 1 });
    my $debian_str = $debian_dir->stringify;

	while ( my $child = $iter->() ) {
		next if $child->is_dir ;

		push @file_list, '/' . $child->relative($debian_str)->stringify;
	};

    # don't use return sort -> undefined behavior in scalar context.
    my @res = sort @file_list;
    return @res;
}

sub write_config_file {
    my ($conf_dir,$wr_dir,$t) = @_;

    if ($t->{config_file}) {
        my $file = $conf_dir ? "$conf_dir/" : '';
        $file .= $t->{config_file} ;
        $wr_dir->child($file)->parent->mkpath({mode => oct(755)} ) ;
    }
}

sub check_load_warnings {
    my ($root,$t) = @_ ;

    if ( my $info = $t->{log4perl_load_warnings} or $::_use_log4perl_to_warn) {
        my $tw = Test::Log::Log4perl->expect( @{ $info // [] } );
        $root->init;
    }
    elsif ( ($t->{no_warnings} or exists $t->{load_warnings}) and not defined $t->{load_warnings}) {
        local $Config::Model::Value::nowarning = 1;
        $root->init;
        note("load_warnings param is DEPRECATED. Please use log4perl_load_warnings");
        ok( 1,"Read configuration and created instance with init() method without warning check" );
    }
    else {
        warnings_like { $root->init; } $t->{load_warnings},
            "Read configuration and created instance with init() method with warning check ";
    }
}

sub run_update {
    my ($inst, $dir, $t) = @_;
    my %args = %{$t->{update}};

    my $ret = delete $args{returns};

    local $Config::Model::Value::nowarning = $args{no_warnings} || $t->{no_warnings} || 0;

    my $res ;
    if ( my $info = $t->{log4perl_update_warnings}) {
        my $tw = Test::Log::Log4perl->expect( $info );
        note("updating config with log4perl warning check and args: ". join(' ',%args));
        $res = $inst->update( from_dir => $dir, %args ) ;
    }
    elsif (my $uw = delete $args{update_warnings}) {
        note("update_warnings param is DEPRECATED. Please use log4perl_update_warnings");
        note("updating config with warning check and args: ". join(' ',%args));
        warnings_like { $res = $inst->update( from_dir => $dir, %args ); } $uw,
            "Updated configuration with warning check ";
    }
    else {
        note("updating config with no warning check and args: ". join(' ',%args));
        $res = $inst->update( from_dir => $dir, %args ) ;
    }

    if (defined $ret) {
        is($res,$ret,"updated configuration, got expected return value");
    }
    else {
        ok(1,"dumped configuration");
    }
}

sub load_instructions {
    my ($root,$steps,$trace) = @_ ;

    print "Loading $steps\n" if $trace ;
    $root->load( $steps );
    ok( 1, "load called" );
}

sub apply_fix {
    my $inst = shift;
    local $Config::Model::Value::nowarning = 1;
    $inst->apply_fixes;
    ok( 1, "apply_fixes called" );
}

sub dump_tree {
    my ($test_group, $root, $mode, $no_warnings, $t, $test_logs, $trace) = @_;

    print "dumping tree ...\n" if $trace;
    my $dump  = '';
    my $risky = sub {
        $dump = $root->dump_tree( mode => $mode );
    };

    if ( defined $t->{dump_errors} ) {
        my $nb = 0;
        my @tf = @{ $t->{dump_errors} };
        while (@tf) {
            my $qr = shift @tf;
            throws_ok { &$risky } $qr, "Failed dump $nb of $test_group config tree";
            my $fix = shift @tf;
            $root->load($fix);
            ok( 1, "Fixed error nb " . $nb++ );
        }
    }

    if ( $test_logs and (my $info = $t->{log4perl_dump_warnings} or $::_use_log4perl_to_warn)) {
        note("checking logged warning while dumping");
        my $tw = Test::Log::Log4perl->expect( @{$info // [] } );
        $risky->();
    }
    elsif ( not $test_logs or $no_warnings ) {
        local $Config::Model::Value::nowarning = 1;
        &$risky;
        ok( 1, "Ran dump_tree (no warning check)" );
    }
    elsif ( exists $t->{dump_warnings} and not defined $t->{dump_warnings} ) {
        local $Config::Model::Value::nowarning = 1;
        &$risky;
        ok( 1, "Ran dump_tree with DEPRECATED dump_warnings parameter (no warning check)" );
    }
    else {
        note("dump_warnings parameter is DEPRECATED") if $t->{dump_warnings};
        warnings_like { &$risky; } $t->{dump_warnings}, "Ran dump_tree";
    }
    ok( $dump, "Dumped $test_group config tree in $mode mode" );

    print $dump if $trace;
    return $dump;
}

sub check_data {
    my ($label, $root, $c, $nw) = @_;

    local $Config::Model::Value::nowarning = $nw || 0;
    my @checks = ref $c eq 'ARRAY' ? @$c
        : map { ( $_ => $c->{$_})} sort keys %$c ;

    while (@checks) {
        my $path       = shift @checks;
        my $v          = shift @checks;
        check_one_item($label, $root,$path, $v);
    }
}

sub check_one_item {
    my ($label, $root,$path, $check_data_l) = @_;

    my @checks = ref $check_data_l eq 'ARRAY' ? @$check_data_l : ($check_data_l);

    foreach my $check_data (@checks) {
        my $check_v_l  = ref $check_data eq 'HASH' ? delete $check_data->{value} : $check_data;
        my @check_args = ref $check_data eq 'HASH' ? %$check_data : ();
        my $check_str  = @check_args ? " (@check_args)" : '';
        my $obj = $root->grab( step => $path, type => ['leaf','check_list'], @check_args );
        my $got = $obj->fetch(@check_args);

        my @check_v = ref($check_v_l) eq 'ARRAY' ? @$check_v_l : ($check_v_l);
        foreach my $check_v (@check_v) {
            if (ref $check_v eq 'Regexp') {
                like( $got, $check_v, "$label check '$path' value with regexp$check_str" );
            }
            else {
                is( $got, $check_v, "$label check '$path' value$check_str" );
            }
        }
    }
}

sub check_annotation {
    my ($root, $t) = @_;

    my $annot_check = $t->{verify_annotation};
    foreach my $path (keys %$annot_check) {
        my $note = $annot_check->{$path};
        is( $root->grab($path)->annotation, $note, "check $path annotation" );
    }
}

sub has_key {
    my ($root, $c, $nw) = @_;

    _test_key($root, $c, $nw, 0);
}

sub has_not_key {
    my ($root, $c, $nw) = @_;

    _test_key($root, $c, $nw, 1);
}

sub _test_key {
    my ($root, $c, $nw, $invert) = @_;

    my @checks = ref $c eq 'ARRAY' ? @$c
        : map { ( $_ => $c->{$_})} sort keys %$c ;

    while (@checks) {
        my $path       = shift @checks;
        my $spec       = shift @checks;
        my @key_checks = ref $spec eq 'ARRAY' ? @$spec: ($spec);

        my $obj = $root->grab( step => $path, type => 'hash' );
        my @keys = $obj->fetch_all_indexes;
        my $res = 0;
        foreach my $check (@key_checks) {
            my @match  ;
            foreach my $k (@keys) {
                if (ref $check eq 'Regexp') {
                    push @match, $k if $k =~ $check;
                }
                else {
                    push @match, $k if $k eq $check;
                }
            }
            if ($invert) {
                is(scalar @match,0, "check $check matched no key" );
            }
            else {
                ok(scalar @match, "check $check matched with keys @match" );
            }
        }
    }
}

sub write_data_back {
    my ($test_group, $inst, $t) = @_;
    local $Config::Model::Value::nowarning = $t->{no_warnings} || 0;
    $inst->write_back( force => 1 );
    ok( 1, "$test_group write back done" );
}

sub check_file_mode {
    my ($wr_dir, $t) = @_;

    if ($^O eq 'MSWin32' and my $fm = $t->{file_mode}) {
        note("skipping file mode tests on Windows");
        return;
    }

    if (my $fm = $t->{file_mode}) {
        foreach my $f (keys %$fm) {
            my $expected_mode = $fm->{$f} ;
            my $stat = $wr_dir->child($f)->stat;
            ok($stat ,"stat found file $f");
            if ($stat) {
                my $mode = $stat->mode & oct(7777) ;
                is($mode, $expected_mode, sprintf("check $f mode (got %o vs %o)",$mode,$expected_mode));
            }
        }
    }
}

sub check_file_content {
    my ($wr_dir, $t) = @_;

    if (my $fc = $t->{file_contents} || $t->{file_content}) {
        foreach my $f (keys %$fc) {
            my $t = $fc->{$f} ;
            my @tests = ref $t eq 'ARRAY' ? @$t : ($t) ;
            foreach my $subtest (@tests) {
                file_contents_eq_or_diff $wr_dir->child($f)->stringify,  $subtest, { encoding => 'UTF-8' },
                    "check that $f contains $subtest";
            }
        }
    }

    if (my $fc = $t->{file_contents_like}) {
        foreach my $f (keys %$fc) {
            my $t = $fc->{$f} ;
            my @tests = ref $t eq 'ARRAY' ? @$t : ($t) ;
            foreach my $subtest (@tests) {
                file_contents_like $wr_dir->child($f)->stringify,  $subtest, { encoding => 'UTF-8' },
                    "check that $f matches regexp $subtest";
            }
        }
    }

    if (my $fc = $t->{file_contents_unlike}) {
        foreach my $f (keys %$fc) {
            my $t = $fc->{$f} ;
            my @tests = ref $t eq 'ARRAY' ? @$t : ($t) ;
            foreach my $subtest (@tests) {
                file_contents_unlike $wr_dir->child($f)->stringify,  $subtest, { encoding => 'UTF-8' },
                    "check that $f does not match regexp $subtest";
            }
        }
    }
}

sub check_added_or_removed_files {
    my ( $conf_dir, $wr_dir, $t, @file_list) = @_;

    # copy whole dir
    my $destination_dir
        = $t->{setup} ? $wr_dir
        : $conf_dir   ? $wr_dir->child($conf_dir)
        :               $wr_dir ;
    my @new_file_list = list_test_files($destination_dir) ;
    $t->{file_check_sub}->( \@file_list ) if defined $t->{file_check_sub};
    eq_or_diff( \@new_file_list, [ sort @file_list ], "check added or removed files" );
}

sub create_second_instance {
    my ($model, $test_group, $t_name, $wr_dir, $wr_dir2, $test_suite_data, $t, $config_dir_override) = @_;

    # create another instance to read the conf file that was just written
    dircopy( $wr_dir->stringify, $wr_dir2->stringify )
        or die "can't copy from $wr_dir to $wr_dir2: $!";

    my @options;
    push @options, backend_arg => $t->{backend_arg} if $t->{backend_arg};

    my $i2_test = $model->instance(
        root_class_name => $test_suite_data->{model_to_test},
        root_dir        => $wr_dir2->stringify,
        config_file     => $t->{config_file} ,
        instance_name   => "$test_group-$t_name-w",
        application     => $test_suite_data->{app_to_test},
        check           => $t->{load_check2} || 'yes',
        config_dir      => $config_dir_override,
        @options
    );

    ok( $i2_test, "Created instance $test_group-test-$t_name-w" );

    local $Config::Model::Value::nowarning = $t->{no_warnings} || 0;
    my $i2_root = $i2_test->config_root;
    $i2_root->init;

    return $i2_root;
}

sub create_test_class {
    my ($model, $config_classes) = @_;
    return unless $config_classes;

    foreach my $c ( @$config_classes) {
        my @parms = ref($c) eq 'HASH' ? %$c : @$c;
        $model->create_config_class(@parms);
    }
}

our ($model, $conf_file_name, $conf_dir, $model_to_test, $app_to_test, $home_for_test, @tests, $skip);

sub load_test_suite_data {
    my ($model_obj, $test_group, $test_group_conf) = @_;

    local ($model, $conf_file_name, $conf_dir, $model_to_test, $app_to_test, $home_for_test, @tests, $skip);

    $skip = 0;
    undef $conf_file_name ;
    undef $conf_dir ;
    undef $home_for_test ;
    undef $model_to_test ; # deprecated
    undef $app_to_test;
    $model = $model_obj; # $model is used by Config::Model tests

    note("Beginning $test_group test ($test_group_conf)");

    my $result;
    unless ( $result = do "./$test_group_conf" ) {
        warn "couldn't parse $test_group_conf: $@" if $@;
        warn "couldn't do $test_group_conf: $!" unless defined $result;
        warn "couldn't run $test_group_conf" unless $result;
    }

    my $test_suite_data;
    if (ref($result) eq 'ARRAY') {
        # simple list of tests
        $test_suite_data = { tests => $result };
    }
    elsif (ref($result) eq 'HASH') {
        $test_suite_data = $result;
    }
    else {
        note(qq!warning: $test_group_conf should return a data structure instead of "1;". !
                 . qq!See Config::Model::Tester for details!);
        $test_suite_data = {
            tests => [ @tests ],
            skip => $skip,
            conf_file_name  => $conf_file_name ,
            conf_dir  => $conf_dir ,
            home_for_test  => $home_for_test ,
            model_to_test => $model_to_test,
            app_to_test => $app_to_test,
        };
    }

    create_test_class($model, $test_suite_data->{config_classes});

    $test_suite_data->{app_to_test} ||= $test_group;

    if ($test_suite_data->{skip}) {
        note("Skipped $test_group test ($test_group_conf)");
        return;
    }

    my ($trash, $appli_info, $applications) = Config::Model::Lister::available_models(1);
    $test_suite_data->{appli_info} = $appli_info;

    # even undef, this resets the global variable there
    Config::Model::BackendMgr::_set_test_home($test_suite_data->{home_for_test}) ;

    if (not defined $test_suite_data->{model_to_test}) {
        $test_suite_data->{model_to_test} = $applications->{$test_suite_data->{app_to_test}};
        if (not defined $test_suite_data->{model_to_test}) {
            my @k = sort values %$applications;
            my @files = map { $_->{_file} // 'unknown' } values %$appli_info ;
            die "Cannot find application or model for $test_group in files >@files<. Known applications are",
                sort keys %$applications, ". Known models are >@k<. ".
                "Check your test name (the file ending with -test-conf.pl) or set app_to_test parameter\n";
        }
    }

    return $test_suite_data;
}

sub run_model_test {
    my ($test_group, $test_group_conf, $do, $model, $trace, $wr_root, $test_logs) = @_ ;

    my $test_suite_data = load_test_suite_data($model,$test_group, $test_group_conf);
    my $appli_info = $test_suite_data->{appli_info};

    my $config_dir_override = $appli_info->{$test_group}{config_dir}; # may be undef

    my $note ="$test_group uses ".$test_suite_data->{model_to_test}." model";
    my $conf_file_name = $test_suite_data->{conf_file_name};
    $note .= " on file $conf_file_name" if defined $conf_file_name;
    note($note);

    my $idx = 0;
    foreach my $t (@{$test_suite_data->{tests}}) {
        translate_test_data($t);
        my $t_name = $t->{name} || "t$idx";
        if ( defined $do and $t_name !~ /$do/) {
            $idx++;
            next;
        }
        note("Beginning subtest $test_group $t_name");

        my ($wr_dir, $wr_dir2, $conf_file, $ex_data, @file_list)
            = setup_test ($test_group, $t_name, $wr_root,$trace, $test_suite_data, $t);

        write_config_file($test_suite_data->{conf_dir},$wr_dir,$t);

        my $inst_name = "$test_group-" . $t_name;

        die "Duplicated test name $t_name for app $test_group\n"
            if $model->has_instance ($inst_name);

        my @options;
        push @options, backend_arg => $t->{backend_arg} if $t->{backend_arg};

        # eventually, we may end up with several instances of Dpkg
        # model in the same process. So we can't play with chdir
        my $inst = $model->instance(
            root_class_name => $test_suite_data->{model_to_test},
            # need to keed root_dir to handle config files like
            # /etc/foo.ini (absolute path, like in /etc/)
            root_dir        => $wr_dir->stringify,
            instance_name   => $inst_name,
            application     => $test_suite_data->{app_to_test},
            config_file     => $t->{config_file} ,
            check           => $t->{load_check} || 'yes',
            config_dir      => $config_dir_override,
            @options
        );

        my $root = $inst->config_root;

        check_load_warnings ($root,$t) if $test_logs;

        run_update($inst,$wr_dir,$t) if $t->{update};

        load_instructions ($root,$t->{load},$trace) if $t->{load} ;

        dump_tree ('before fix '.$test_group , $root, 'full', $t->{no_warnings}, $t->{check_before_fix}, $test_logs, $trace)
            if $t->{check_before_fix};

        apply_fix($inst) if  $t->{apply_fix};

        dump_tree ($test_group, $root, 'full', $t->{no_warnings}, $t->{full_dump}, $test_logs, $trace) ;

        my $dump = dump_tree ($test_group, $root, 'custom', $t->{no_warnings}, {}, $test_logs, $trace) ;

        check_data("first", $root, $t->{check}, $t->{no_warnings}) if $t->{check};

        has_key     ( $root, $t->{has_key}, $t->{no_warnings}) if $t->{has_key} ;
        has_not_key ( $root, $t->{has_not_key}, $t->{no_warnings}) if $t->{has_not_key} ;

        check_annotation($root,$t) if $t->{verify_annotation};

        write_data_back ($test_group, $inst, $t) ;

        check_file_content($wr_dir,$t) ;

        check_file_mode($wr_dir,$t) ;

        check_added_or_removed_files ($test_suite_data->{conf_dir}, $wr_dir, $t, @file_list) if $ex_data->is_dir;

        my $i2_root = create_second_instance ($model, $test_group, $t_name, $wr_dir, $wr_dir2, $test_suite_data, $t, $config_dir_override);

        load_instructions ($i2_root,$t->{load2},$trace) if $t->{load2} ;

        my $p2_dump = dump_tree("second $test_group", $i2_root, 'custom', $t->{no_warnings},{}, $test_logs, $trace) ;

        unified_diff;
        eq_or_diff(
            [ split /\n/,$p2_dump ],
            [ split /\n/,$dump ],
            "compare original $test_group custom data with 2nd instance custom data",
        );

        ok( -s "$wr_dir2/$test_suite_data->{conf_dir}/$test_suite_data->{conf_file_name}" ,
            "check that original $test_group file was not clobbered" )
                if defined $test_suite_data->{conf_file_name} ;

        check_data("second", $i2_root, $t->{wr_check}, $t->{no_warnings}) if $t->{wr_check} ;

        note("End of subtest $test_group $t_name");

        $idx++;
    }
    note("End of $test_group test");

}

sub translate_test_data {
    my $t = shift;
    map {$t->{full_dump}{$_} = delete $t->{$_} if $t->{$_}; } qw/dump_warnings dump_errors/;
}

sub create_model_object {
    my $new_model ;
    eval { $new_model = Config::Model->new(); } ;
    if ($@) {
        # necessary to run smoke test (no Config::Model to avoid dependency loop)
        plan skip_all => 'Config::Model is not loaded' ;
        return;
    }
    return $new_model;
}

sub run_tests {
    my ( $test_only_app, $do, $trace, $wr_root );
    my $model;
    my $test_logs;
    if (@_) {
        my $arg;
        note ("Calling run_tests with argument is deprecated");
        ( $arg, $test_only_app, $do ) = @_;

        my $log = 0;

        $trace = ($arg =~ /t/) ? 1 : 0;
        $log  = 1 if $arg =~ /l/;

        my $log4perl_user_conf_file = ($ENV{HOME} || '') . '/.log4config-model';

        if ( $log and -e $log4perl_user_conf_file ) {
            Log::Log4perl::init($log4perl_user_conf_file);
        }
        else {
            Log::Log4perl->easy_init( $log ? $WARN : $ERROR );
        }

        Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

        ok( 1, "compiled" );

        # pseudo root where config files are written by config-model
        $wr_root = path('wr_root');
    }
    else {
        my $opts;
        ($model, $trace, $opts) = init_test();
        $test_logs = $opts->{log} ? 0 : 1;
        ( $test_only_app, $do)  = @ARGV;
        # pseudo root where config files are written by config-model
        $wr_root = setup_test_dir();
    }

    my @group_of_tests = grep { /-test-conf.pl$/ } glob("t/model_tests.d/*");

    foreach my $test_group_conf (@group_of_tests) {
        my ($test_group) = ( $test_group_conf =~ m!\.d/([\w\-]+)-test-conf! );
        next if ( $test_only_app and $test_only_app ne $test_group ) ;
        $model = create_model_object();
        return unless $model;
        run_model_test($test_group, $test_group_conf, $do, $model, $trace, $wr_root, $test_logs) ;
    }

    memory_cycle_ok($model,"test memory cycle") ;

    done_testing;

}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Tester - Test framework for Config::Model

=head1 VERSION

version 4.007

=head1 SYNOPSIS

In your test file (typically C<t/model_test.t>):

 use warnings;
 use strict;

 use Config::Model::Tester ;
 use ExtUtils::testlib;

 run_tests() ;

Run tests with:

 perl t/model_test.t [ --log ] [--error] [--trace] [ subtest [ test_case ] ]

=head1 DESCRIPTION

This class provides a way to test configuration models with tests files.
This class was designed to tests several models and run several tests
cases per model.

A specific layout for test files must be followed.

=head2 Sub test specification

Each subtest is defined in a file like:

 t/model_tests.d/<app-name>-test-conf.pl

This file specifies that C<app-name> (which is defined in
C<lib/Config/Model/*.d> directory) is used for the test cases defined
in the C<*-test-conf.pl> file. The model to test is inferred from the
application name to test.

This file contains a list of test case (explained below) and expects a
set of files used as test data. The layout of these test data files is
explained in next section.

=head2 Simple test file layout

Each test case is represented by a configuration file (not
a directory) in the C<*-examples> directory. This configuration file
is used by the model to test and is copied as
C<$confdir/$conf_file_name> using the test data structure explained
below.

In the example below, we have 1 app model to test: C<lcdproc> and 2 tests
cases. The app name matches the file specified in
C<lib/Config/Model/*.d> directory. In this case, the app name matches
C<lib/Config/Model/system.d/lcdproc>

 t
 |-- model_test.t
 \-- model_tests.d           # do not change directory name
     |-- lcdproc-test-conf.pl   # subtest specification for lcdproc app
     \-- lcdproc-examples
         |-- t0              # test case t0
         \-- LCDD-0.5.5      # test case for older LCDproc

Subtest specification is written in C<lcdproc-test-conf.pl> file (i.e. this
module looks for files named like C<< <app-name>-test-conf.pl> >>).

Subtests data is provided in files in directory C<lcdproc-examples> (
i.e. this modules looks for test data in directory
C<< <model-name>-examples> >>. C<lcdproc-test-conf.pl> contains
instructions so that each file is used as a C</etc/LCDd.conf>
file during each test case.

C<lcdproc-test-conf.pl> can contain specifications for more test
cases. Each test case requires a new file in C<lcdproc-examples>
directory.

See L</Examples> for a link to the actual LCDproc model tests

=head2 Test file layout for multi-file configuration

When a configuration is spread over several files, each test case is
provided in a sub-directory. This sub-directory is copied in
C<conf_dir> (a test parameter as explained below)

In the example below, the test specification is written in
C<dpkg-test-conf.pl>. Dpkg layout requires several files per test case.
C<dpkg-test-conf.pl> contains instructions so that each directory
under C<dpkg-examples> is used.

 t/model_tests.d
 \-- dpkg-test-conf.pl         # subtest specification
 \-- dpkg-examples
     \-- libversion            # example subdir, used as test case name
         \-- debian            # directory for used by test case
             |-- changelog
             |-- compat
             |-- control
             |-- copyright
             |-- rules
             |-- source
             |   \-- format
             \-- watch

See L</Examples> for a link to the (many) Dpkg model tests

=head2 More complex file layout

Each test case is a sub-directory on the C<*-examples> directory and
contains several files. The destination of the test files may depend
on the system (e.g. the OS). For instance, system wide C<ssh_config>
is stored in C</etc/ssh> on Linux, and directly in C</etc> on MacOS.

These files are copied in a test directory using a C<setup> parameter
in test case specification.

Let's consider this example of 2 tests cases for ssh:

 t/model_tests.d/
 |-- ssh-test-conf.pl
 |-- ssh-examples
     \-- basic
         |-- system_ssh_config
         \-- user_ssh_config

Unfortunately, C<user_ssh_config> is a user file, so you need to specify
where is located the home directory of the test with another global parameter:

  home_for_test => '/home/joe' ;

For Linux only, the C<setup> parameter is:

 setup => {
   system_ssh_config => '/etc/ssh/ssh_config',
   user_ssh_config   => "~/.ssh/config"
 }

On the other hand, system wide config file is different on MacOS and
the test file must be copied in the correct location. When the value
of the C<setup> hash is another hash, the key of this other hash is
used as to specify the target location for other OS (as returned by
Perl C<$^O> variable:

      setup => {
        'system_ssh_config' => {
            'darwin' => '/etc/ssh_config',
            'default' => '/etc/ssh/ssh_config',
        },
        'user_ssh_config' => "~/.ssh/config"
      }

C<systemd> is another beast where configuration files can be symlinks
to C</dev/null> or other files. To emulate this situation, use an array as setup target:

  setup => {
      # test data file => [ link (may be repeated), ..       link(s) target contains test data ]
      'ssh.service' => [ '/etc/systemd/system/sshd.service', '/lib/systemd/system/ssh.service' ]
  }

This will result in a symlink like:

   wr_root/model_tests/test-sshd-service/etc/systemd/system/sshd.service
   -> /absolute_path_to/wr_root/model_tests/test-sshd-service/lib/systemd/system/ssh.service

See the actual L<Ssh and Sshd model tests|https://github.com/dod38fr/config-model-openssh/tree/master/t/model_tests.d>

=head2 Basic test specification

Each model subtest is specified in C<< <app>-test-conf.pl >>. This
file must return a data structure containing the test
specifications. Each test data structure contains global parameters
(Applied to all tests cases) and test cases parameters (parameters are
applied to the test case)

 use strict;
 use warnings;
 {
   # global parameters

   # config file name (used to copy test case into test wr_root/model_tests directory)
   conf_file_name => "fstab",
   # config dir where to copy the file (optional)
   conf_dir => "etc",
   # home directory for this test
   home_for_test => '/home/joe'

   tests =>  [
     {
       # test case 1
       name => 'my_first_test',
       # other test case parameters
     },
     {
       # test case 2
       name => 'my_second_test',
       # other test case parameters
     },
     # ...
   ],
 };

 # do not add 1; at the end of the file

In the example below, C<t0> file is copied in C<wr_root/model_tests/test-t0/etc/fstab>.

 use strict;
 use warnings;
 {
   # list of tests.
   tests => [
     {
       # test name
       name => 't0',
       # add optional specification here for t0 test
     },
     {
       name => 't1',
       # add optional specification here for t1 test
     },
   ]
 };

You can suppress warnings by specifying C<< no_warnings => 1 >> in
each test case. On the other hand, you may also want to check for
warnings specified to your model. In this case, you should avoid
specifying C<no_warnings> here and specify warning tests or warning
filters as mentioned below.

See actual L<fstab test|https://github.com/dod38fr/config-model/blob/master/t/model_tests.d/fstab-test-conf.pl>.

=head2 Skip a test

A test file can be skipped using C<skip> global test parameter.

In this example, test is skipped when not running on a Debian system:

 eval { require AptPkg::Config; };
 my $skip = ( $@ or not -r '/etc/debian_version' ) ? 1 : 0;

 {
   skip => $skip,
   tests => [ ] ,
 };

=head2 Internal tests or backend tests

Some tests require the creation of a configuration class dedicated
for test (typically to test corner cases on a backend).

This test class can be created directly in the test specification by
specifying tests classes in C<config_classes> global test parameter in an
array ref. Each array element is a data structure that use
L<create_config_class|Config::Model/create_config_class> parameters.
See for instance the
L<layer test|https://github.com/dod38fr/config-model/blob/master/t/model_tests.d/layer-test-conf.pl>
or the
L<test for shellvar backend|https://github.com/dod38fr/config-model/blob/master/t/model_tests.d/backend-shellvar-test-conf.pl>.

In this case, no application exist for such classes so the model to
test must be specified in a global test parameter:

  return {
    config_classes => [ { name => "Foo", element => ... } , ... ],
    model_to_test => "Foo",
    tests => [ ... ]
  };

=head2 Test specification with arbitrary file names

In some models, like C<Multistrap>, the config file is chosen by the
user. In this case, the file name must be specified for each tests
case:

 {
   tests => [ {
       name        => 'arm',
       config_file => '/home/foo/my_arm.conf',
       check       => {},
    }]
 };

See the actual L<multistrap test|https://github.com/dod38fr/config-model/blob/master/t/model_tests.d/multistrap-test-conf.pl>.

=head2 Backend argument

Some application like systemd requires a backend argument specified by
user (e.g. a service name for systemd). The parameter C<backend_arg>
can be specified to emulate this behavior.

=head2 Re-use test data

When the input data for test is quite complex (several files), it may
be interesting to re-use these data for other test cases. Knowing that
test names must be unique, you can re-use test data with C<data_from>
parameter. For instance:

  tests => [
    {
        name  => 'some-test',
        # ...
    },
    {
        name  => 'some-other-test',
        data_from  => 'some-test',    # re-use data from test above
        # ...
    },
  ]

See
L<plainfile backend test|https://github.com/dod38fr/config-model/blob/master/t/model_tests.d/backend-plainfile-test-conf.pl>
for a real life example.

Likewise, it may be useful to re-use test data from another group of
test. Lets see this example from C<systemd-service-test-conf.pl>:

    {
        name => 'transmission',
        data_from_group => 'systemd', # i.e from ../systemd-examples
    }

C<data_from> and C<data_from_group> can be together.

=head2 Test scenario

Each subtest follow a sequence explained below. Each step of this
sequence may be altered by adding test case parameters in
C<< <model-to-test>-test-conf.pl >>:

=over

=item *

Setup test in C<< wr_root/model_tests/<subtest name>/ >>. If your configuration file layout depend
on the target system, you will have to specify the path using C<setup> parameter.
See L</"More complex file layout">.

=item *

Create configuration instance, load config data and check its validity. Use
C<< load_check => 'no' >> if your file is not valid.

=item *

Check for config data warnings. You should pass the list of expected warnings that are
emitted through L<Log::Log4perl>. The array ref is passed as is to the C<expect> function
of L<Test::Log::Lo4Perl/expect>. E.g:

    log4perl_load_warnings => [
         [ 'Tree.Node', (warn => qr/deprecated/) x 2 ]  ,
         [ 'Tree.Element.Value' , ( warn => qr/skipping/) x 2 ]
    ]

The Log classes are specified in C<cme/Logging>.

Log levels below "warn" are ignored.

Note that log tests are disabled when C<--log> option is used, hence
all warnings triggered by the tests are shown.

L<Config::Model> is currently transitioning from traditional "warn" to
warn logs. To avoid breaking all tests based on this module, the
warnings are emitted through L<Log::Log4perl> only when
C<$::_use_log4perl_to_warn> is set. This hack will be removed once all
warnings checks in tests are ported to log4perl checks.

=item *

DEPRECATED. Check for config data warning. You should pass the list of expected warnings.
E.g.

    load_warnings => [ qr/Missing/, (qr/deprecated/) x 3 , ],

Use an empty array_ref to mask load warnings.

=item *

Optionally run L<update|App::Cme::Command::update> command:

 update => {
    returns => 'foo' , # optional
    no_warnings => [ 0 | 1 ], # default 0
    quiet => [ 0 | 1], # default 0, passed to update method
    load4perl_update_warnings => [ ... ] # Test::Log::Log4perl::expect arguments
 }

Where:

=over

=item *

C<returns> is the expected return value (optional).

=item *

C<no_warnings> can be used to suppress the warnings coming from
L<Config::Model::Value>. Note that C<< no_warnings => 1 >> may be
useful for less verbose test.

=item *

C<quiet> to suppress progress messages during update.

=item *

C<log4perl_update_warnings> is used to check the warnings produced
during update. The argument is passed to C<expect> function of
L<Test::Log::Log4perl>. See C<load_warnings> parameter above for more
details.

=item *

DEPRECATED. C<update_warnings> is an array ref of quoted regexp (See qr operator)
to check the warnings produced during update. Please use C<log4perl_update_warnings>
instead.

=back

All other arguments are passed to C<update> method.

=item *

Optionally load configuration data. You should design this config data to
suppress any error or warning mentioned above. E.g:

    load => 'binary:seaview Synopsis="multiplatform interface for sequence alignment"',

See L<Config::Model::Loader> for the syntax of the string accepted by C<load> parameter.

=item *

Optionally, run a check before running apply_fix (if any). This step is useful to check
warning messages:

   check_before_fix => {
      dump_errors   => [ ... ] # optional, see below
      log4perl_dump_warnings => [ ... ] # optional, see below
   }

Use C<dump_errors> if you expect issues:

  check_before_fix => {
    dump_errors =>  [
        # the issues  and a way to fix the issue using Config::Model::Node::load
        qr/mandatory/ => 'Files:"*" Copyright:0="(c) foobar"',
        qr/mandatory/ => ' License:FOO text="foo bar" ! Files:"*" License short_name="FOO" '
    ],
  }

Likewise, specify any expected warnings:

  check_before_fix => {
        log4perl_dump_warnings => [ ... ],
  }

C<log4perl_dump_warnings> passes the array ref content to C<expect>
function of L<Test::Log::Log4perl>.

Both C<log4perl_dump_warnings> and C<dump_errors> can be specified in C<check_before_fix> hash.

=item *

Optionally, call L<apply_fixes|Config::Model::Instance/apply_fixes>:

    apply_fix => 1,

=item *

Call L<dump_tree|Config::Model::Node/dump_tree> to check the validity of the
data after optional C<apply_fix>. This step is not optional.

As with C<check_before_fix>, both C<dump_errors> or
C<log4perl_dump_warnings> can be specified in C<full_dump> parameter:

 full_dump => {
     log4perl_dump_warnings => [ ... ], # optional
     dump_errors            => [ ... ], # optional
 }

=item *

Run specific content check to verify that configuration data was retrieved
correctly:

    check => {
        'fs:/proc fs_spec' => "proc",
        'fs:/proc fs_file' => "/proc",
        'fs:/home fs_file' => "/home",
    },

The keys of the hash points to the value to be checked using the
syntax described in L<Config::Model::Role::Grab/grab>.

Multiple check on the same item can be applied with a array ref:

    check => [
        Synopsis => 'fix undefined path_max for st_size zero',
        Description => [ qr/^The downstream/,  qr/yada yada/ ]
    ]

You can run check using different check modes (See L<Config::Model::Value/fetch>)
by passing a hash ref instead of a scalar :

    check  => {
        'sections:debian packages:0' => { mode => 'layered', value => 'dpkg-dev' },
        'sections:base packages:0'   => { mode => 'layered', value => "gcc-4.2-base' },
    },

The whole hash content (except "value") is passed to  L<grab|Config::Model::Role::Grab/grab>
and L<fetch|Config::Model::Value/fetch>

A regexp can also be used to check value:

   check => {
      "License text" => qr/gnu/i,
   }

And specification can nest hash or array style:

   check => {
      "License:0 text" => qr/gnu/i,
      "License:1 text" => [ qr/gnu/i, qr/Stallman/ ],
      "License:2 text" => { mode => 'custom', value => [ qr/gnu/i , qr/Stallman/ ] },
      "License:3 text" => [ qr/General/], { mode => 'custom', value => [ qr/gnu/i , qr/Stallman/ ] },
   }

=item *

Verify if a hash contains one or more keys (or keys matching a regexp):

 has_key => [
    'sections' => 'debian', # sections must point to a hash element
    'control' => [qw/source binary/],
    'copyright Files' => qr/.c$/,
    'copyright Files' => [qr/\.h$/], qr/\.c$/],
 ],

=item *

Verify that a hash does B<not> have a key (or a key matching a regexp):

 has_not_key => [
    'copyright Files' => qr/.virus$/ # silly, isn't ?
 ],

=item *

Verify annotation extracted from the configuration file comments:

    verify_annotation => {
            'source Build-Depends' => "do NOT add libgtk2-perl to build-deps (see bug #554704)",
            'source Maintainer' => "what a fine\nteam this one is",
        },

=item *

Write back the config data in C<< wr_root/model_tests/<subtest name>/ >>.
Note that write back is forced, so the tested configuration files are
written back even if the configuration values were not changed during the test.

You can skip warning when writing back with the global :

    no_warnings => 1,

=item *

Check the content of the written files(s) with L<Test::File::Contents>. Tests can be grouped
in an array ref:

   file_contents => {
            "/home/foo/my_arm.conf" => "really big string" ,
            "/home/bar/my_arm.conf" => [ "really big string" , "another"], ,
        }

   file_contents_like => {
            "/home/foo/my_arm.conf" => [ qr/should be there/, qr/as well/ ] ,
   }

   file_contents_unlike => {
            "/home/foo/my_arm.conf" => qr/should NOT be there/ ,
   }

=item *

Check the mode of the written files:

  file_mode => {
     "~/.ssh/ssh_config"     => oct(600), # better than 0600
     "debian/stuff.postinst" => oct(755),
  }

Only the last four octets of the mode are tested. I.e. the test is done with
C< $file_mode & oct(7777) >

Note: this test is skipped on Windows

=item *

Check added or removed configuration files. If you expect changes,
specify a subref to alter the file list:

    file_check_sub => sub {
        my $list_ref = shift ;
        # file added during tests
        push @$list_ref, "/debian/source/format" ;
    },

Note that actual and expected file lists are sorted before check,
adding a file can be done with C<push>.

=item *

Copy all config data from C<< wr_root/model_tests/<subtest name>/ >>
to C<< wr_root/model_tests/<subtest name>-w/ >>. This steps is necessary
to check that configuration written back has the same content as
the original configuration.

=item *

Create a second configuration instance to read the conf file that was just copied
(configuration data is checked.)

=item *

You can skip the load check if the written file still contain errors (e.g.
some errors were ignored and cannot be fixed) with C<< load_check2 => 'no' >>

=item *

Optionally load configuration data in the second instance. You should
design this config data to suppress any error or warning that occur in
the step below. E.g:

    load2 => 'binary:seaview',

See L<Config::Model::Loader> for the syntax of the string accepted by C<load2> parameter.

=item *

Compare data read from original data.

=item *

Run specific content check on the B<written> config file to verify that
configuration data was written and retrieved correctly:

    wr_check => {
        'fs:/proc fs_spec' =>          "proc" ,
        'fs:/proc fs_file' =>          "/proc",
        'fs:/home fs_file' =>          "/home",
    },

Like the C<check> item explained above, you can run C<wr_check> using
different check modes.

=back

=head2 Running the test

Run all tests with one of these commands:

 prove -l t/model_test.t :: [ --trace ] [ --log ] [ --error ] [ <model_name> [ <regexp> ]]
 perl -Ilib t/model_test.t  [ --trace ] [ --log ] [ --error ] [ <model_name> [ <regexp> ]]

By default, all tests are run on all models.

You can pass arguments to C<t/model_test.t>:

=over

=item *

Optional parameters: C<--trace> to get test traces. C<--error> to get stack trace in case of
errors, C<--log> to have logs. E.g.

  # run with log and error traces
  prove -lv t/model_test.t :: --error --logl

=item *

The model name to tests. E.g.:

  # run only fstab tests
  prove -lv t/model_test.t :: fstab

=item *

A regexp to filter subtest E.g.:

  # run only fstab tests foobar subtest
  prove -lv t/model_test.t :: fstab foobar

  # run only fstab tests foo subtest
  prove -lv t/model_test.t :: fstab '^foo$'

=back

=head1 Examples

Some of these examples may still use global variables (which is
deprecated). Such files may be considered as buggy after Aug
2019. Please warn the author if you find one.

=over

=item *

L<LCDproc|http://lcdproc.org> has a single configuration file:
C</etc/LCDd.conf>. Here's LCDproc test
L<layout|https://github.com/dod38fr/config-model-lcdproc/tree/master/t/model_tests.d>
and the L<test specification|https://github.com/dod38fr/config-model-lcdproc/blob/master/t/model_tests.d/lcdd-test-conf.pl>

=item *

Dpkg packages are constructed from several files. These files are handled like
configuration files by L<Config::Model::Dpkg|https://salsa.debian.org/perl-team/modules/packages/libconfig-model-dpkg-perl>. The
L<test layout|https://salsa.debian.org/perl-team/modules/packages/libconfig-model-dpkg-perl/-/tree/master/t/model_tests.d>
features test with multiple file in
L<dpkg-examples|https://salsa.debian.org/perl-team/modules/packages/libconfig-model-dpkg-perl/-/tree/master/t/model_tests.d/dpkg-examples>.
The test is specified in L<https://salsa.debian.org/perl-team/modules/packages/libconfig-model-dpkg-perl/-/blob/master/t/model_tests.d/dpkg-test-conf.pl>

=item *

L<multistrap-test-conf.pl|https://github.com/dod38fr/config-model/blob/master/t/model_tests.d/multistrap-test-conf.pl>
and L<multistrap-examples|https://github.com/dod38fr/config-model/tree/master/t/model_tests.d/multistrap-examples>
specify a test where the configuration file name is not imposed by the
application. The file name must then be set in the test specification.

=item *

L<backend-shellvar-test-conf.pl|https://github.com/dod38fr/config-model/blob/master/t/model_tests.d/backend-shellvar-test-conf.pl>
is a more complex example showing how to test a backend. The test is done creating a dummy model within the test specification.

=back

=head1 CREDITS

In alphabetical order:

=over 4

=item *

Cyrille Bollu

=back

Many thanks for your help.

=head1 SEE ALSO

=over 4

=item *

L<Config::Model>

=item *

L<Test::More>

=back

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013-2020 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Config-Model-Tester>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Config-Model-Tester>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Config-Model-Tester>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Config::Model::Tester>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<ddumont at cpan.org>, or through
the web interface at L<https://github.com/dod38fr/config-model-tester/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/dod38fr/config-model-tester.git>

  git clone git://github.com/dod38fr/config-model-tester.git

=cut
