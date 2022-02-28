use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use File::Path qw(remove_tree);
use File::Temp qw(tempdir);
use App::perlmv;
use Test::More;

our $Perl;
our $Bin;
our $Dir;

sub prepare_for_testing {
    # clean for -T
    ($Perl) = $^X =~ /(.+)/;
    $ENV{PATH} = "/usr/bin:/bin";
    $ENV{ENV} = "";

    # weird, why is directory still getting cleaned up even though cwd is still
    # at $Dir? this is not how things behave in, say, Git::Bunch test. i've also
    # tried File::chdir to no avail. so currently we turn off CLEANUP option
    # when debugging
    $Dir = tempdir(CLEANUP=>$ENV{DEBUG_KEEP_TEMPDIR} ? 0 : 1);
    $ENV{TESTING_HOME} = $Dir;
    note "Dir=$Dir";
    chdir $Dir or die "Can't chdir $Dir: $!";
}

sub end_testing {
    if (Test::More->builder->is_passing) {
        note "all tests successful, deleting test data dir";
        chdir '/';
    } else {
        # don't delete test data dir if there are errors
        diag "there are failing tests, not deleting test data dir $Dir";
        # weird, why is directory still getting cleaned up even though cwd is
        # still at $Dir? this is not how things behave in, say, Git::Bunch test.
        # i've also tried File::chdir to no avail. so currently we turn off
        # CLEANUP option when debugging
    }
}

# each rename will be tested twice, first using the command line
# script and then using method

sub test_perlmv {
    my ($files_before, $opts, $files_after, $test_name, $hook_before, $hook_after) = @_;

    for my $which ("method", "binary") {
        my $subdir = "rand".int(90_000_000*rand()+10_000_000);
        mkdir $subdir or die "Can't mkdir $ENV{TESTING_HOME}/$subdir: $!";
        note "subdir=$subdir";
        chdir $subdir or die "Can't chdir $ENV{TESTING_HOME}/$subdir: $!";
        if ($hook_before) {
            $hook_before->();
        } else {
            create_files(@$files_before);
        }
        run_perlmv($opts, [map {ref($_) ? $_->{name}:$_} @$files_before],
                   $which);
        if ($hook_after) {
            $hook_after->();
        } else {
            files_are($files_after, "$test_name ($which)");
        }
        remove_files();
        chdir '..' or die "Can't chdir ..: $!";
        if (Test::More->builder->is_passing) {
            remove_tree($subdir) or die "Can't rmdir $ENV{TESTING_HOME}/$subdir: $!";
        } else {
            note"there are failing tests, not deleting test data subdir $Dir/$subdir";
        }
    }
}

sub run_perlmv {
    my ($opts, $files, $which) = @_;
    $which //= "method";

    if ($which eq 'binary') {
        my $cmd = "perlrename";
        if ($opts->{mode}) {
            if    ($opts->{mode} eq 'm') { $cmd = "perlmv" }
            elsif ($opts->{mode} eq 'c') { $cmd = "perlcp" }
            elsif ($opts->{mode} eq 's') { $cmd = "perlln_s" }
            elsif ($opts->{mode} eq 'l') { $cmd = "perlln" }
        }
        $cmd = "$Bin/../script/$cmd";
        my @cmd = ($Perl, "-I", "$Bin/../lib", $cmd);
        for (keys %$opts) {
            my $v = $opts->{$_};
            if    ($_ eq 'code')          { push @cmd, "-e", $v }
            elsif ($_ eq 'compile')       { push @cmd, "-c" }
            elsif ($_ eq 'dry_run')       { push @cmd, "-d" }
            elsif ($_ eq 'mode')          { } # already processed above
            elsif ($_ eq 'extra_opt')     { } # will be processed later
            elsif ($_ eq 'extra_arg')     { } # will be processed later
            elsif ($_ eq 'before_rmtree') { } # will be processed later
            elsif ($_ eq 'overwrite')     { push @cmd, "-o" }
            elsif ($_ eq 'parents')       { push @cmd, "-p" }
            elsif ($_ eq 'recursive')     { push @cmd, "-R" }
            elsif ($_ eq 'reverse_order') { push @cmd, "-r" }
            elsif ($_ eq 'no_sort')       { push @cmd, "-T" }
            elsif ($_ eq 'verbose')       { push @cmd, "-v" }
            elsif ($_ eq 'codes')         {
                push @cmd, (map {ref($_) ? ("-x", $$_) : ("-e", $_)} @$v);
            } else {
                die "BUG: Can't handle opts{$_} yet!";
            }
        }
        if ($opts->{extra_opt}) { push @cmd, $opts->{extra_opt} }
        do { /(.*)/; push @cmd, $1 } for @$files;
        if ($opts->{extra_arg}) { push @cmd, $opts->{extra_arg} }
        print "#DEBUG: system(", join(", ", @cmd), ")\n";
        system @cmd;
        die "Can't system(", join(" ", @cmd), "): $?" if $?;
    } else {
        my $pmv = App::perlmv->new;
        for (keys %$opts) {
            my $v = $opts->{$_};
            if ($_ eq 'extra_opt') {
                push @{ $pmv->{codes} }, $pmv->get_scriptlet_code($v);
            } elsif ($_ eq 'extra_arg') {
                # later, below
            } elsif ($_ eq 'reverse_order') {
                $pmv->{sort_mode} = -1;
            } elsif ($_ eq 'no_sort') {
                $pmv->{sort_mode} = 0;
            } elsif ($_ eq 'code') {
                push @{ $pmv->{codes} }, $v;
            } else {
                $pmv->{$_} = $v;
            }
        }
        local $pmv->{codes} = [map { ref($_) eq 'SCALAR' ? $pmv->get_scriptlet_code($$_) : $_ } @{ $pmv->{codes} }];
        if ($opts->{compile}) {
            $pmv->compile_code($_) for @{$pmv->{codes}};
        } elsif ($opts->{write}) {
            $pmv->store_scriptlet($opts->{write}, $pmv->{codes}[0]);
        } elsif ($opts->{delete}) {
            $pmv->delete_user_scriptlet($opts->{delete});
        } else {
            $files = [@$files];
            push @$files, $opts->{extra_arg} if $opts->{extra_arg};
            $pmv->rename(@$files);
        }
    }
    $opts->{before_rmtree}->() if $opts->{before_rmtree};
}

# to avoid filesystem differences, we always sort and convert to
# lowercase first, and we never play with case-sensitivity.

sub create_files {
    for (@_) {
        if (ref $_) {
            if (defined $_->{link_target}) {
                symlink $_->{link_target}, $_->{name};
            }
        } else {
            open my($fh), ">", lc($_);
        }
    }
}


sub remove_files {
    for (<*>) { my ($f) = /(.+)/; unlink $f }
}
sub files {
    my @res = sort { $a cmp $b } map { lc } <*>;
    print "#DEBUG: files() = ", join(", ", map {"'$_'"} @res), "\n";
    @res;
}

sub files_are {
    my ($files, $test_name) = @_;
    my @rfiles = files();
    my $rfiles = "[" . join(", ", @rfiles) . "]";
    if (ref($files) eq 'CODE') {
        ok($files->(\@rfiles), $test_name);
    } else {
        $files = "[" . join(", ", @$files) . "]";
        # compare as string, e.g. "[1, 2, 3]" vs "[1, 2, 3]" so
        # differences are clearly shown in test output (instead of
        # is_deeply output, which i'm not particularly fond of)
        is($rfiles, $files, $test_name);
    }
}

1;
