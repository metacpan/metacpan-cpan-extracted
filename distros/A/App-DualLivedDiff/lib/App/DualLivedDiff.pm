package App::DualLivedDiff;
use strict;
use warnings;

our $VERSION = '1.07';

use Getopt::Long;
use Parse::CPAN::Meta ();
use LWP::Simple;
use File::Temp ();
use File::Spec;
use Archive::Extract;
use File::Find ();
use CPAN ();

our $diff_cmd = 'diff';
our @exclude_files = (
  qr(\.{1,2}$),
  qr(\.svn$),
  qr(\.git$),
);

sub usage {
  print "@_\n\n" if @_;
  print <<HERE;
Usage: $0 -d source-dist -b /path/to/blead/checkout
Does a diff FROM a dual lived module distribution TO blead perl

-b/--blead   blead perl path
-d/--dual    dual lived module distribution path, archive, URL,
             or module- or distribution name (default: .)
-r/--reverse reverses the diff (blead to lib)
-c/--config  name of the configuration file with file mappings
             (defaults to .dualLivedDiffConfig in the module path or current path)
-o/--output  file name for output (defaults to STDOUT)
             useful to separate diff from CPAN.pm output
-p/--paths   show the "dual"-lived module paths or the "blead" paths?
             defaults to "blead" or to "dual" if in --reverse mode
-w/--ignore-all-space (same as for normal gnu diff)

Check perldoc "App::DualLivedDiff" for more info on the usage.
The "diff" command is assumed to be in your PATH and will be run with the
-u and -N options by default.
HERE
  exit(1);
}

my (
  $bleadpath, $dualmodule, $reverse,
  $default_config_file, $config_file,
  $output_file, $paths, $ignore_space
);

sub run {
  $bleadpath           = undef;
  $dualmodule          = '.';
  $reverse             = 0;
  $default_config_file = '.dualLivedDiffConfig';
  $config_file         = $default_config_file;
  $output_file         = undef;
  $paths               = undef;
  $ignore_space        = undef;
  GetOptions(
    'b|blead=s'                  => \$bleadpath,
    'h|help'                     => \&usage,
    'r|reverse'                  => \$reverse,
    'd|dual=s'                   => \$dualmodule,
    'c|conf|config|configfile=s' => \$config_file,
    'o|out|output=s'             => \$output_file,
    'p|path|paths=s'             => \$paths,
    'w|ignore-all-space'         => \$ignore_space,
  );

  if (defined $output_file) {
    open my $fh, '>', $output_file or die "Could not open file '$output_file' for writing: $!";
    $output_file = $fh;
  }

  usage() if not defined $bleadpath or not -d $bleadpath;

  if (not defined $paths) {
    $paths = $reverse ? "blead" : "dual";
  }
  else {
    if ($paths =~ /^blead$/i) {
      $paths = 'blead';
    } elsif ($paths =~ /^dual$/i) {
      $paths = 'dual';
    } else {
      die "Invalid path setting: --paths must be either 'dual' or 'blead'!\n";
    }
  }

  my $workdir         = get_dual_lived_distribution_dir($dualmodule);
  my $config          = get_config($workdir, $config_file);

  my $files           = $config->{"files"} || {};
  my $exclude_regexes = [ map {qr/$_/} @{$config->{"exclude-regexes"} || []} ];
  my $dirs_flat       = $config->{"dirs-flat"} || {};
  my $dirs_recursive  = $config->{"dirs-recursive"} || {};
  
  my $blead_module_base_path = $config->{"base-path-in-blead"};

  my $pathspec = {
    blead_path => $bleadpath,
    source_path => $workdir,
    blead_module_path => $blead_module_base_path,
  };

  foreach my $source_file (keys %$files) {
    # commented out since explicitly mapped files trump exclusion
    #if (grep {$source_file =~ $_} @$exclude_regexes) { next; }
    my $blead_file = $files->{$source_file};
    $pathspec->{blead_file} = $blead_file;
    $pathspec->{source_file} = $source_file;

    my $absolute_source_file = File::Spec->catdir($workdir, $source_file);

    if (-f $absolute_source_file) {
      file_diff( $output_file, $pathspec, $paths );
    }
    elsif (-d $absolute_source_file) {
      warn "'$absolute_source_file' is not a file but a directory. Use the 'dirs-flat' or 'dirs-recursive' config options instead!";
      next;
    }
    else {
      warn "Explicitly mapped file '$source_file' missing from dual lived module source tree!";
      next;
    }
  }

  foreach my $source_dir (keys %$dirs_flat) {
    if (grep {$source_dir =~ $_} @$exclude_regexes) {
      warn "Explicitly mapped directory '$source_dir' is also excluded explicitly. Skipping it.";
      next;
    }
    my $blead_dir = $dirs_flat->{$source_dir};
    $pathspec->{blead_file} = $blead_dir;
    $pathspec->{source_file} = $source_dir;

    my $absolute_source_dir = File::Spec->catdir($workdir, $source_dir);
    if (-f $absolute_source_dir) {
      warn "'$absolute_source_dir' is not a directory but a file. Use the 'files' config option instead!";
      next;
    }
    elsif (-d $absolute_source_dir) {
      dir_diff( $output_file, $pathspec, $paths, 0, $exclude_regexes );
    }
    else {
      warn "Explicitly mapped directory '$source_dir' missing from dual lived module source tree!";
      next;
    }
  }

  foreach my $source_dir (keys %$dirs_recursive) {
    if (grep {$source_dir =~ $_} @$exclude_regexes) {
      warn "Explicitly mapped directory '$source_dir' is also excluded explicitly. Skipping it.";
      next;
    }
    my $blead_dir = $dirs_recursive->{$source_dir};
    $pathspec->{blead_file} = $blead_dir;
    $pathspec->{source_file} = $source_dir;

    my $absolute_source_dir = File::Spec->catdir($workdir, $source_dir);
    if (-f $absolute_source_dir) {
      warn "'$absolute_source_dir' is not a directory but a file. Use the 'files' config option instead!";
      next;
    }
    elsif (-d $absolute_source_dir) {
      dir_diff( $output_file, $pathspec, $paths, 1, $exclude_regexes );
    }
    else {
      warn "Explicitly mapped directory '$source_dir' missing from dual lived module source tree!";
      next;
    }
  }
}

# given a source specification, get the path to an extracted distribution
sub get_dual_lived_distribution_dir {
  my $source = shift;
  usage("Bad source of the dual lived module distribution '$source'")
    if not defined $source;
  
  my $distfile;
  if (-d $source) {
    # already extracted or checkout
    return $source;
  }
  elsif (-f $source) {
    # distribution file
    $distfile = $source;
  }
  elsif ($source =~ m{^(?:ftp|https?)://}) {
    $distfile = download_distribution($source);
  }
  elsif ($source =~ m{^[^:/]+://}) {
    die "Support for VCS checkout and fancy protocols not implemented";
  }
  else {
    # fallback, treat as module or distribution
    my $url = module_or_dist_to_url($source);
    die "Could not find CPAN module of that name ($source)" if not defined $url;
    $distfile = download_distribution($url);
  }

  # extract distribution
  my $tmpdir = File::Temp::tempdir( CLEANUP => 1 );
  my $ae = Archive::Extract->new( archive => $distfile );
  $ae->extract( to => $tmpdir )
    or die "Failed to extract distribution '$distfile' to temp. dir: " . $ae->error();

  # find the extracted distribution dir
  opendir my $dh, $tmpdir
    or die "Could not opendir '$tmpdir': $!";
  my @stuff = readdir($dh);
  my @files = grep {-f File::Spec->catfile($tmpdir, $_)} @stuff;
  my @dirs  = grep {!/^\.\.?$/ and -d File::Spec->catdir($tmpdir, $_)} @stuff;
  closedir $dh;

  if (@files or @dirs != 1) {
    die "Failed to find extracted distribution directory in '$tmpdir'. Found ".scalar(@files)." files and ".scalar(@dirs)." dirs";
  }

  return File::Spec->catdir($tmpdir, shift(@dirs)); 
}

sub download_distribution {
  my $url = shift;
  my $disttmpdir = File::Temp::tempdir( CLEANUP => 1 );
  $url =~ m{/([^/]+)$} or die;
  my $file = File::Spec->catfile($disttmpdir, $1);
  if (is_success(getstore( $url, $file ))) {
    return $file;
  }
  else {
    die "Could not fetch '$url'";
  }
}

# find and load the configuration file
sub get_config {
  my $source_dir = shift;
  my $config_file = shift;
  my $yaml;
  if (-f $config_file) {
    $yaml = Parse::CPAN::Meta::LoadFile($config_file);
  }
  elsif ( -f File::Spec->catfile($source_dir, $config_file) ) {
    $yaml = Parse::CPAN::Meta::LoadFile(
      File::Spec->catfile($source_dir, $config_file)
    );
  }
  elsif ( -f File::Spec->catfile($source_dir, $default_config_file) ) {
    $yaml = Parse::CPAN::Meta::LoadFile(
      File::Spec->catfile($source_dir, $default_config_file)
    );
  }
  else {
    die "Could not find nor load configuration file";
  }

  $yaml = $yaml->[0] if ref($yaml) eq 'ARRAY';

  return $yaml;
}

# given the two base dirs and two relative paths, transform a
# directory mapping into file mappings recursively
sub dirs_to_filemapping {
  my $pathspec        = shift;
  my $recursive       = shift;
  
  my $full_source_dir = File::Spec->catdir($pathspec->{source_path}, $pathspec->{source_file});
  my $full_blead_dir  = get_full_blead_path($pathspec, $pathspec->{blead_file});

  if (not -d $full_blead_dir) {
    warn "Specified directory '$pathspec->{blead_file}' could not be found in blead perl source tree (as $full_blead_dir)!";
    return();
  }
  if (not -d $full_source_dir) {
    warn "Specified directory '$pathspec->{source_file}' could not be found in dual lived module source tree (as $full_source_dir)!";
    return();
  }

  my @source_files = $recursive ? recur_get_all_files($full_source_dir) : get_all_files($full_source_dir);
  if (!@source_files) {
    warn "Specified source directory '$pathspec->{source_file}' does not contain any files!";
    return({});
  }

  my $mapping = {};
  $mapping->{File::Spec->catfile($pathspec->{source_file}, $_)} = File::Spec->catfile($pathspec->{blead_file}, $_)
    for @source_files;

  return $mapping;
}

# get all files in a path with relative paths
sub recur_get_all_files {
  my $path = shift;

  my @files;
  return() if not -d $path;
  
  File::Find::find(
    {
      preprocess => sub {
        my @return;
        FILE: foreach my $file (@_) {
          foreach my $exclude_regex (@exclude_files) {
            next FILE if $file =~ $exclude_regex;
          }
          push @return, $file;
        }
        return(@return);
      },
      wanted => sub {
        foreach my $exclude_regex (@exclude_files) {
          return if $_ =~ $exclude_regex;
        }
        return unless -f $_;
        s{^\Q$path\E[\\/]*}{};
        push @files, $_;
      },
      no_chdir => 1,
    },
    $path
  );
  return(@files);
}

# get all files in a path with relative paths
sub get_all_files {
  my $path = shift;

  return() if not -d $path;
  
  opendir my $dh, $path or die "Could not open path '$path': $!";
  my @files = readdir($dh);
  closedir $dh;

  my @use_files;
  FILE: foreach my $file (@files) {
    foreach my $exclude_regex (@exclude_files) {
      next FILE if $file =~ $exclude_regex;
    }
    push @use_files, $file if -f File::Spec->catfile($path, $file);
  }

  return(@use_files);
}

# produce the diff of a full directory
sub dir_diff {
  my $output_file     = shift;
  my $pathspec        = shift;
  my $paths           = shift;
  my $recursive       = shift;
  my $exclude_regexes = shift;

  my $map = dirs_to_filemapping( $pathspec, $recursive );

  foreach my $source_file (keys %$map) {
    next if grep {$source_file =~ $_} @$exclude_regexes;
    my $pathspec = {%$pathspec};
    $pathspec->{source_file} = $source_file;
    $pathspec->{blead_file} = $map->{$source_file};
    file_diff( $output_file, $pathspec, $paths );
  }
}

# produce the diff of a single file
sub file_diff {
  my $output_file     = shift;
  my $pathspec        = shift;
  my $paths           = shift;

  my $absolute_source_file = File::Spec->catfile($pathspec->{source_path}, $pathspec->{source_file});
  my $absolute_blead_file  = get_full_blead_path( $pathspec, $pathspec->{blead_file} );
  #warn "Diffing '$absolute_source_file' to '$absolute_blead_file'";

  my @cmd = ($diff_cmd, ($ignore_space ? ('-w') : ()), qw(-u -N));
  if ($reverse) {
    push @cmd, $absolute_blead_file, $absolute_source_file;
  }
  else {
    push @cmd, $absolute_source_file, $absolute_blead_file;
  }
  my $result = `@cmd`;
  my $blead_prefix = quotemeta($reverse ? '---' : '+++');
  my $source_prefix = quotemeta($reverse ? '+++' : '---');

  my $patched_filename;
  my $bleadpath_patched_filename =
    defined($pathspec->{blead_module_path})
    ? File::Spec->catfile( $pathspec->{blead_module_path}, $pathspec->{blead_file} )
    : $pathspec->{blead_file};

  if ($paths eq 'dual') {
    $patched_filename = $pathspec->{source_file};
  } elsif ($paths eq 'blead') {
    $patched_filename = $bleadpath_patched_filename;
   } else {
    $patched_filename = $reverse ? $bleadpath_patched_filename : $pathspec->{source_file};
  }
  #my $patched_filename = $reverse ? $source_file : $blead_file;

  #$result =~ s{^($blead_prefix\s*)(\S+)}{$1 . remove_path_prefix($2, $blead_base_dir)}gme;
  #$result =~ s{^($source_prefix\s*)(\S+)}{$1 . remove_path_prefix($2, $source_base_dir)}gme;
  
  $result =~ s{^($blead_prefix\s+)(\S+)}{$1 . $patched_filename}gme;
  $result =~ s{^($source_prefix\s+)(\S+)}{$1 . $patched_filename}gme;

  if (defined $output_file) {
    print $output_file $result;
  }
  else {
    print $result;
  }
}

# remove a prefix from a path
sub remove_path_prefix {
  my $path   = shift;
  my $prefix = shift;
  $path =~ s/^\Q$prefix\E//;
  $path =~ s/^[\/\\]+//;
  return $path;
}

# turn something that may look like a module or
# distribution into an URL using CPAN
sub module_or_dist_to_url {
  my $module_name = shift;
  #my $use_dev_versions = shift;

  my $distro;
  if ($module_name =~ /[\/.]/) {
    my $dist = CPAN::Shell->expandany($module_name);
    if (not defined $dist) {
      warn "Could not find distribution '$module_name' on CPAN\n";
      return();
    }
    $dist = $dist->distribution() if ref($dist) eq 'CPAN::Module';
    if (not ref($dist) eq 'CPAN::Distribution') {
      warn "Could not find distribution '$module_name' on CPAN\n";
      return();
    }
    $distro = $dist->pretty_id();
    warn "Assuming you specified a distribution name. Found the '$distro' distribution on CPAN\n";
  }
  else {
    my $module = CPAN::Shell->expand("Module", $module_name);
    if (not defined $module) {
      warn "Could not find module '$module_name' on CPAN\n";
      return();
    }
    $distro = $module->distribution()->pretty_id();
    warn "Assuming you specified a module name. Found the '$distro' distribution on CPAN\n";
  }

  $distro =~ /^([^\/]+)/ or die;
  $distro = substr($1, 0, 1) . "/" . substr($1, 0, 2) . "/" . $distro;

  my $mirrors = $CPAN::Config->{urllist};
  if (not defined $mirrors or not ref($mirrors) eq 'ARRAY' or not @$mirrors) {
    warn "Could not determine CPAN mirror";
    return();
  }

  my $url = $mirrors->[0];
  $url =~ s/\/+$//;
  return $url . '/authors/id/' . $distro;
}

sub get_full_blead_path {
  my $pathspec = shift;
  my $path = shift;
  if (defined $pathspec->{blead_module_path}) {
    return File::Spec->catdir($pathspec->{blead_path}, $pathspec->{blead_module_path}, $path);
  }
  else {
    return File::Spec->catdir($pathspec->{blead_path}, $path);
  }
}

1;
__END__

=head1 NAME

App::DualLivedDiff - Diff between the perl core and dual-lived modules' CPAN distributions

=head1 SYNOPSIS

Example: Filter::Simple.

Given a simple YAML file F<.dualLivedDiffConfig> in the current working directory
or the Filter::Simple CPAN distribution:

  ---
  exclude-regexes:
    - ^(?:\./)?MANIFEST$
    - ^(?:\./)?META.yml$
  files:
    lib/Filter/Simple.pm: lib/Filter/Simple.pm
    Changes: lib/Filter/Simple/Changes
  dirs-flat:
    t/: lib/Filter/Simple/t/
  dirs-recursive:
    t/lib/Filter/Simple/: t/lib/Filter/Simple/

By running the following command, you can get the diff between your blead perl checkout and
the CPAN distribution:

  dualLivedDiff --dual http://search.cpan.org/CPAN/authors/id/S/SM/SMUELLER/Filter-Simple-0.84.tar.gz --blead $HOME/perl-ssh

Or this if you have CPAN.pm configured:

  dualLivedDiff --dual SMUELLER/Filter-Simple-0.84.tar.gz --blead $HOME/perl-ssh

Or this if you want to search for a given module name:

  dualLivedDiff --dual Filter::Simple --blead $HOME/perl-ssh

You can use the C<base-path-in-blead> option in the YAML config file to set a base path
within the blead-perl checkout. Example of the configuration for the Attribute::Handlers
dual-lived module/distribution which lives entirely within F<ext/Attribute-Handlers>:

  ---
  base-path-in-blead: ext/Attribute-Handlers
  files:
    Changes: Changes
    README: README
  dirs-recursive:
    lib/: lib/
    t/: t/
    demo/: demo/

Run the "dualLivedDiff" program to get an overview of the command line options.

=head1 DESCRIPTION

Very early version of a tool to automatically generate diffs/patches between CPAN distributions
of dual lived Perl modules and the perl core. The code isn't beautiful. It's a hack.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

