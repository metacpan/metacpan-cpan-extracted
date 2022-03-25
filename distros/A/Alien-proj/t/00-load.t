use strict;
use warnings;
use Test::More;
use Test::Alien;
use File::Which;
use Config;
use Path::Tiny;

BEGIN {
    use_ok('Alien::proj') or BAIL_OUT('Failed to load Alien::proj');
}

alien_ok 'Alien::proj';

diag(
    sprintf(
        'Testing Alien::proj %s, Perl %s, %s',
        $Alien::proj::VERSION, $], $^X
    )
);


diag '';
diag 'Install type is ' . Alien::proj->install_type;
diag 'Proj version is ' . Alien::proj->version;
diag 'Aliens:';
my %alien_versions;
foreach my $alien (qw /Alien::sqlite Alien::libtiff Alien::curl/) {
    my $have = eval "require $alien";
    next if !$have;
    diag sprintf "%s: version: %s, install type: %s", $alien, $alien->version, $alien->install_type;
    $alien_versions{$alien} = $alien->version;
}

if ($^O =~ /darwin/) {
    diag '$ENV{DYLD_LIBRARY_PATH} = ' . ($ENV{DYLD_LIBRARY_PATH} // '');
}
elsif ($^O !~ /mswin/i) {
    diag '$ENV{LD_LIBRARY_PATH} = ' . ($ENV{LD_LIBRARY_PATH} // '');
}

diag_dynamic_libs();

done_testing();


my $RE_DLL_EXT = qr/\.$Config::Config{so}$/i;
if ($^O eq 'darwin') {
    $RE_DLL_EXT = qr/\.($Config::Config{so}|bundle)$/i;
}

sub diag_dynamic_libs {
    diag "Dynamic lib dependencies:\n";
    if ($^O =~ /darwin/i) {
        _diag_dynamic_libs_otool();
    }
    elsif ($^O =~ /mswin/i) {
        #  do nothing - deps are handled via the path
        diag "are not diagnosed on windows";
    }
    else {
        _diag_dynamic_libs_ldd();
    }
}


sub _diag_dynamic_libs_ldd {
    my $LDD = which('ldd')
      or diag "ldd not found, skipping dynamic lib summary";
    my @target_libs = Alien::proj->dynamic_libs;
    my %seen;
    
    while (my $lib = shift @target_libs) {
        #say "ldd $lib";
        my $out = qx /$LDD $lib/;
        warn qq["ldd $lib" failed\n]
          if not $? == 0;
        diag "$lib:";
        diag $out;

        #  much of this logic is from PAR::Packer
        #  https://github.com/rschupp/PAR-Packer/blob/04a133b034448adeb5444af1941a5d7947d8cafb/myldr/find_files_to_embed/ldd.pl#L47
        my %dlls = $out =~ /^ \s* (\S+) \s* => \s* ( \/ \S+ ) /gmx;
 
      DLL:
        foreach my $name (keys %dlls) {
            if ($seen{$name}) {
                delete $dlls{$name};
                next DLL;
            }
             
            $seen{$name}++;
 
            my $path = path($dlls{$name})->realpath;
             
            #say "Checking $name => $path";
             
            if (not -r $path) {
                warn qq[# ldd reported strange path: $path\n];
                delete $dlls{$name};
            }
            elsif (
                 $path =~ m{^(?:/usr)?/lib(?:32|64)?/}  #  system lib
              or $name =~ m{^lib(?:c|gcc_s|stdc\+\+)\.}  
              ) {
                delete $dlls{$name};
            }
        }
        push @target_libs, values %dlls;
    }
}

sub _diag_dynamic_libs_otool {
    my $OTOOL = which('otool')  or diag "otool not found, skipping dynamic lib summary";
    my @target_libs = Alien::proj->dynamic_libs;
    my %seen;
    while (my $lib = shift @target_libs) {
        #say "otool -L $lib";
        my @lib_arr = qx /$OTOOL -L $lib/;
        note qq["otool -L $lib" failed\n]
          if not $? == 0;
        diag "$lib:";
        diag join "", @lib_arr;
        shift @lib_arr;  #  first result is dylib we called otool on
        
        # follow any aliens or non-system paths
        foreach my $line (@lib_arr) {
            $line =~ /^\s+(.+?)\s/;
            my $dylib = $1;
            next if $seen{$dylib};
            next if $dylib =~ m{^/System};  #  skip system libs
            next if $dylib =~ m{^/usr/lib/libSystem};
            next if $dylib =~ m{^/usr/lib/};
            next if $dylib =~ m{^\@rpath};
            $seen{$dylib}++;
            #  add this dylib to the search set
            push @target_libs, $dylib;
        }
    }
}
