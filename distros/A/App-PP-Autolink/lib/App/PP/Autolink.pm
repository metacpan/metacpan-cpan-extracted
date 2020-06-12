#  logic initially based on pp_simple.pl
#  Should cache the Module::Scandeps result
#  and then clean it up after using it.

package App::PP::Autolink;

use strict;
use warnings;
use 5.010;

use Carp;
use English qw / -no_match_vars /;

use File::Which      qw( which );
use Capture::Tiny    qw/ capture /;
use List::Util       1.45 qw( uniq any );
use File::Find::Rule qw/ rule find /;
use Path::Tiny       qw/ path /;
#use File::Temp       qw/ tempfile /;
use Module::ScanDeps;
use Env qw /@PATH/;

use Config;
use Getopt::ArgvFile default=>1;
use Getopt::Long qw / GetOptionsFromArray :config pass_through /;

our $VERSION = '2.03';

use constant CASE_INSENSITIVE_OS => ($^O eq 'MSWin32');

my $RE_DLL_EXT = qr/\.$Config::Config{so}$/i;
if ($^O eq 'darwin') {
    $RE_DLL_EXT = qr/\.($Config::Config{so}|bundle)$/i;
}

my $ldd_exe = which('ldd');


sub new {
    my ($class, @args) = @_;
    
    my $self = bless {}, $class;
    
    $self->{autolink_list_method}
      = $^O eq 'MSWin32' ? 'get_autolink_list'
      : $^O eq 'darwin'  ? 'get_autolink_list_macos'
      : $ldd_exe         ? 'get_autolink_list_ldd'
      #  objdump behaves differently on linux (centos at least)
      : die 'Unable to generate autolink list';
    
    #  slightly messy, but issues with pass_through and --no-x
    $self->{no_execute_flag} = not grep {$_ eq '-x'} @args;
    
    #  Should trap any scandeps args (if diff from pp).
    my @args_array = @args;
    my @argv_linkers;

    GetOptionsFromArray (
        \@args_array,
        "link|l=s" => \@argv_linkers,
    );
    $self->{argv_linkers} = \@argv_linkers;
    $self->{args_to_pass_to_pp}  = \@args_array;
    
    #  pp allows multiple .pl files.
    my $script_fullname = $args[-1] or die 'no input file specified';
    $self->{script_fullname} = $script_fullname;

    $self->{alien_sys_installs} = [];

    return $self;
}

sub build {
    my ($self) = @_;

    #  reassemble the arg list
    my $argv_linkers = $self->{argv_linkers};
    my $args_array   = $self->{args_to_pass_to_pp};
    my @args_for_pp = (
        (map {("--link" => $_)} @$argv_linkers),
        @$args_array,
    );

    my $method   = $self->{autolink_list_method};
    my @dll_list = $self->$method;
    my $alien_sys_installs = $self->{alien_sys_installs};
    
    # two-step process to get unique paths
    my %tmp   = map {($_ => '--link')} (@dll_list, @$alien_sys_installs);
    my @links = reverse %tmp;

    say 'Alien sys dlls added: ' . join ' ', @$alien_sys_installs;
    say 'Detected link list: '   . join ' ', @links;

    my @command = (
        'pp',
        @links,
        #"--cachedeps=$cache_file",
        @args_for_pp,
    );

    say 'CMD:' . join ' ', @command;
    system (@command) == 0
      or die "system @command failed: $?";

    return;
}



sub get_autolink_list {
    my ($self) = @_;
    
    my $argv_linkers = $self->{argv_linkers};

    my $OBJDUMP   = which('objdump')  or die "objdump not found";
    
    my @exe_path = @PATH;
    
    my @system_paths;

    if ($OSNAME =~ /MSWin32/i) {
        #  skip anything under the C:\Windows folder
        #  and no longer existant folders 
        my $system_root = $ENV{SystemRoot};
        @system_paths = grep {$_ =~ m|^\Q$system_root\E|i} @exe_path;
        @exe_path = grep {(-e $_) and $_ !~ m|^\Q$system_root\E|i} @exe_path;
        #say "PATHS: " . join ' ', @exe_path;
    }
    #  what to skip for linux or mac?
    
    #  get all the DLLs in the path - saves repeated searching lower down
    my @dll_files = File::Find::Rule->file()
                            ->name( "*.$Config::Config{so}" )
                            ->maxdepth(1)
                            ->in( @exe_path );

    if (CASE_INSENSITIVE_OS) {
        @dll_files = map {lc $_} @dll_files;
    }

    my %dll_file_hash;
    foreach my $file (@dll_files) {
        my $basename = path($file)->basename;
        $dll_file_hash{$basename} //= $file;  #  we only want the first in the path
    }


    #  lc is dirty and underhanded
    #  - need to find a different approach to get
    #  canonical file name while handling case,
    #  poss Win32::GetLongPathName
    my @dlls = @$argv_linkers;
    push @dlls,
      $self->get_dep_dlls;

    if (CASE_INSENSITIVE_OS) {
        @dlls = map {lc $_} @dlls;
    }
    #say join "\n", @dlls;
    
    my $re_skippers = $self->get_dll_skipper_regexp();
    my %full_list;
    my %searched_for;
    my $iter = 0;
    
    my @missing;

  DLL_CHECK:
    while (1) {
        $iter++;
        say "DLL check iter: $iter";
        #say join ' ', @dlls;
        my ( $stdout, $stderr, $exit ) = capture {
            system( $OBJDUMP, '-p', @dlls );
        };
        if( $exit ) {
            $stderr =~ s{\s+$}{};
            warn "(@dlls):$exit: $stderr ";
            exit;
        }
        @dlls = $stdout =~ /DLL.Name:\s*(\S+)/gmi;
        
        if (CASE_INSENSITIVE_OS) {
            @dlls = map {lc $_} @dlls;
        }

        #  extra grep appears wasteful but useful for debug 
        #  since we can easily disable it
        @dlls
          = sort
            grep {!exists $full_list{$_}}
            grep {$_ !~ /$re_skippers/}
            uniq
            @dlls;
        
        if (!@dlls) {
            say 'no more DLLs';
            last DLL_CHECK;
        }
                
        my @dll2;
        foreach my $file (@dlls) {
            next if $searched_for{$file};
        
            if (exists $dll_file_hash{$file}) {
                push @dll2, $dll_file_hash{$file};
            }
            else {
                push @missing, $file;
            }
    
            $searched_for{$file}++;
        }
        @dlls = uniq @dll2;
        my $key_count = keys %full_list;
        @full_list{@dlls} = (1) x @dlls;
        
        #  did we add anything new?
        last DLL_CHECK if $key_count == scalar keys %full_list;
    }
    
    my @l2 = sort keys %full_list;
    
    if (@missing) {
        my @missing2;
      MISSING:
        foreach my $file (uniq @missing) {
            next MISSING
              if any {-e "$_/$file"} @system_paths;
            push @missing2, $file;
        }
        
        say STDERR "\nUnable to locate these DLLS, packed script might not work: "
        . join  ' ', sort {$a cmp $b} @missing2;
        say '';
    }

    return wantarray ? @l2 : \@l2;
}

sub get_autolink_list_macos {
    my ($self) = @_;
    
    my $argv_linkers = $self->{argv_linkers};

    my $OTOOL = which('otool')  or die "otool not found";
    
    my @bundle_list = $self->get_dep_dlls;
    my @libs_to_pack;
    my %seen;

    my @target_libs = (
        @$argv_linkers,
        @bundle_list,
        #'/usr/local/opt/libffi/lib/libffi.6.dylib',
        #($pixbuf_query_loader,
        #find_so_files ($gdk_pixbuf_dir) ) if $pack_gdkpixbuf,
    );
    while (my $lib = shift @target_libs) {
        say "otool -L $lib";
        my @lib_arr = qx /otool -L $lib/;
        warn qq["otool -L $lib" failed\n]
          if not $? == 0;
        shift @lib_arr;  #  first result is dylib we called otool on
        foreach my $line (@lib_arr) {
            $line =~ /^\s+(.+?)\s/;
            my $dylib = $1;
            next if $seen{$dylib};
            next if $dylib =~ m{^/System};  #  skip system libs
            #next if $dylib =~ m{^/usr/lib/system};
            next if $dylib =~ m{^/usr/lib/libSystem};
            next if $dylib =~ m{^/usr/lib/};
            next if $dylib =~ m{\Qdarwin-thread-multi-2level/auto/share/dist/Alien\E};  #  another alien
            say "adding $dylib for $lib";
            push @libs_to_pack, $dylib;
            $seen{$dylib}++;
            #  add this dylib to the search set
            push @target_libs, $dylib;
        }
    }

    @libs_to_pack = sort @libs_to_pack;
    
    return wantarray ? @libs_to_pack : \@libs_to_pack;
}

sub get_autolink_list_ldd {
    my ($self) = @_;
    
    my $argv_linkers = $self->{argv_linkers};
    
    my @bundle_list = $self->get_dep_dlls;
    my @libs_to_pack;
    my %seen;

    my @target_libs = (
        @$argv_linkers,
        @bundle_list,
    );
    while (my $lib = shift @target_libs) {
        say "ldd $lib";
        my $out = qx /ldd $lib/;
        warn qq["ldd $lib" failed\n]
          if not $? == 0;
          
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
                 $path =~ m{^(?:/usr)?/lib(?:32|64)/}  #  system lib
              or $path =~ m{\Qdarwin-thread-multi-2level/auto/share/dist/Alien\E}  #  alien in share
              or $name =~ m{^lib(?:c|gcc_s|stdc\+\+)\.}  #  should already be packed?
              ) {
                #warn "skipping $name => $path";
                #warn "re1" if $path =~ m{^(?:/usr)?/lib(?:32|64)/};
                #warn "re2" if $path =~ m{\Qdarwin-thread-multi-2level/auto/share/dist/Alien\E};
                #warn "re3" if $name =~ m{^lib(?:gcc_s|stdc\+\+)\.};
                delete $dlls{$name};
            }
        }
        push @target_libs, values %dlls;
        push @libs_to_pack, values %dlls;
    }

    @libs_to_pack = sort @libs_to_pack;
    
    return wantarray ? @libs_to_pack : \@libs_to_pack;
}


#  needed for gdkpixbuf, when we support it 
sub find_so_files {
    my ($self, $target_dir) = @_;
    return if !defined $target_dir;

    my @files = File::Find::Rule->extras({ follow => 1, follow_skip=>2 })
                             ->file()
                             ->name( qr/\.so$/ )
                             ->in( $target_dir );
    return wantarray ? @files : \@files;
}


sub get_dll_skipper_regexp {
    my ($self) = @_;
    
    #  PAR packs these automatically these days.
    my @skip = qw /
        perl5\d\d
        libstdc\+\+\-6
        libgcc_s_seh\-1
        libwinpthread\-1
        libgcc_s_sjlj\-1
    /;
    my $sk = join '|', @skip;
    my $qr_skip = qr /^(?:$sk)$RE_DLL_EXT$/;
    return $qr_skip;
}

#  find dependent dlls
#  could also adapt some of Module::ScanDeps::_compile_or_execute
#  as it handles more edge cases
sub get_dep_dlls {
    my ($self) = @_;

    my $script = $self->{script_fullname};
    my $no_execute_flag = $self->{no_execute_flag};
    my $alien_sys_installs = $self->{alien_sys_installs};
    my $cache_file = $self->{cache_file};

    #  This is clunky:
    #  make sure $script/../lib is in @INC
    #  assume script is in a bin folder
    my $rlib_path = (path ($script)->parent->parent->stringify) . '/lib';
    #say "======= $rlib_path/lib ======";
    local @INC = (@INC, $rlib_path)
      if -d $rlib_path;
    
    my $deps_hash = scan_deps(
        files   => [ $script ],
        recurse => 1,
        execute => !$no_execute_flag,
        cache_file => $cache_file,
    );
    
    #my @lib_paths 
    #  = map {path($_)->absolute}
    #    grep {defined}  #  needed?
    #    @Config{qw /installsitearch installvendorarch installarchlib/};
    #say join ' ', @lib_paths;
    my @lib_paths
      = reverse sort {length $a <=> length $b}
        map {path($_)->absolute}
        @INC;

    my $paths = join '|', map {quotemeta} @lib_paths;
    my $inc_path_re = qr /^($paths)/i;
    #say $inc_path_re;

    #say "DEPS HASH:" . join "\n", keys %$deps_hash;
    my %dll_hash;
    my @aliens;
    foreach my $package (keys %$deps_hash) {
        my $details = $deps_hash->{$package};
        my @uses = @{$details->{uses} // []};
        if ($details->{key} =~ m{^Alien/.+\.pm$}) {
            push @aliens, $package;
        }
        next if !@uses;
        
        foreach my $dll (grep {$_ =~ $RE_DLL_EXT} @uses) {
            my $dll_path = $deps_hash->{$package}{file};
            #  Remove trailing component of path after /lib/
            if ($dll_path =~ m/$inc_path_re/) {
                $dll_path = $1 . '/' . $dll;
            }
            else {
                #  fallback, get everything after /lib/
                $dll_path =~ s|(?<=/lib/).+?$||;
                $dll_path .= $dll;
            }
            #say $dll_path;
            croak "either cannot find or cannot read $dll_path "
                . "for package $package"
              if not -r $dll_path;
            $dll_hash{$dll_path}++;
        }
    }
    #  handle aliens
  ALIEN:
    foreach my $package (@aliens) {
        next if $package =~ m{^Alien/(Base|Build)};
        my $package_inc_name = $package;
        $package =~ s{/}{::}g;
        $package =~ s/\.pm$//;
        if (!$INC{$package_inc_name}) {
            #  if the execute flag was off then try to load the package
            eval "require $package";
            if ($@) {
                say "Unable to require $package, skipping (error is $@)";
                next ALIEN;
            }
        }
        # some older aliens might do different things
        next ALIEN if !$package->isa ('Alien::Base');  
        say "Finding dynamic libs for $package";
        foreach my $path ($package->dynamic_libs) {
            $dll_hash{$path}++;
        }
        if ($package->install_type eq 'system') {
            push @$alien_sys_installs, $package->dynamic_libs;
        }
    } 
    
    my @dll_list = sort keys %dll_hash;
    return wantarray ? @dll_list : \@dll_list;
}


1;

__END__

=head1 NAME

pp_autolink - Run the pp (PAR Packager) utility while automatically finding dynamic libs to link

=head1 SYNOPSIS

pp_autolink S<--link some_dll> S<pp_opts> S<[ I<scriptfile> ]>

=head1 EXAMPLES

Note: As with L<pp>, when running on Microsoft Windows, the F<a.out> below will be
replaced by F<a.exe> instead.

    #  Pack 'hello.pl' into executable 'a.out'
    % pp_autolink hello.pl
    
    #  Pack 'hello.pl' into executable 'hello'
    #  (or 'hello.exe' on Win32)
    % pp_autolink -o hello hello.pl
                                
    #  pack hello.pl and its dependent dynamic libs,
    #  as well as some.dylib and other.dylib,
    #  and their dependent dynamic libs
    % pp_autolink --link some.dylib --link other.dylib -o hello hello.pl
    
    #  Args other than --link are passed on to the pp call
    #  e.g., extra modules in the include path
    #  (these are not currently checked by pp_autolink)
    % pp_autolink -M Foo::Bar hello      

    #  pp_autolink also supports the @file syntax for args
    #  Pack 'hello.pl' but read _additional_
    #  options from file 'file'
    % pp_autolink @file hello.pl         

=head1 DESCRIPTION

I<L<pp>> creates standalone executables from Perl programs.
However, it does not pack dynamic libs by default, and a general
source of angst is that dynamic libs have dependencies that must
be traced and also packed for the packed executable to be usable on
a "clean" system.

F<pp_autolink> is an attempt to automate this packing process.

All F<pp_autolink> does is recursively check all dynamic libs used by a perl script
and add them to the L<pp> call using C<--link> command line arguments.

Depending on your system it will use the I<ldd>, I<objdump> or I<otool>
utilities to find dependent libs.

It will also check dynamic libs used by Aliens if they are detected
and inherit from L<Alien::Base>.

Note that testing is currently very threadbare,
so please report issues.  Pull requests are very welcome.

=head1 OPTIONS

As with L<pp>, options are available in a I<short> form and a I<long> form.  For
example, these lines are equivalent:

    % pp_autolink -l some.dll output.exe input.pl
    % pp_autolink --link some.dll --output output.exe input.pl

All other options are passed on to the pp call.
See the L<pp|pp documentation> for full details.  


=head1 ENVIRONMENT

=over 4

=item PP_OPTS

The PP_OPTS environment variable, used by L<pp>, is ignored.
Since all pp_autolink does is wrangle dynamic libs and then add them to a pp call,
it will still be used for the final executable. 


=back

=head1 SEE ALSO

L<pp>, L<PAR>, L<PAR::Packer>, L<Module::ScanDeps>

L<Getopt::Long>, L<Getopt::ArgvFile>

=head1 ACKNOWLEDGMENTS

The initial version of pp_autolink was adapted
from the L<pp_simple|https://www.perlmonks.org/?node_id=1148802> utility.


=head1 AUTHORS

Shawn Laffan E<lt>shawnlaffan@gmail.comE<gt>,


Please submit bug reports to L<https://github.com/shawnlaffan/perl-pp-autolink/issues>.

=head1 COPYRIGHT

Copyright 2017-2020 by Shawn Laffan
E<lt>shawnlaffan@gmail.comE<gt>.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See F<LICENSE>.

=cut
