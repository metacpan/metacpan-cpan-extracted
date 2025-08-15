package Acme::AutoLoad;

use strict;
use warnings;
use base qw(Exporter);

our $VERSION = '0.09';

our $last_fetched = "";
our $lib = "lib";
our $hook = \&inc;

sub ignore {}
sub import {
  warn "DEBUG: Congratulations! Acme::AutoLoad has been loaded.\n" if $ENV{AUTOLOAD_DEBUG};
  $lib = $ENV{AUTOLOAD_LIB} if $ENV{AUTOLOAD_LIB};
  if ($lib =~ m{^[^/]}) {
    eval {
      require Cwd;
      $lib = Cwd::abs_path($lib);
    };
  }
  push @INC, $lib, $hook if $hook;
  $hook = undef;
  return \&ignore;
}

sub mkbase {
  my $path = shift;
  if ($path =~ s{/+[^/]*$ }{}x) {
    return 1 if -d $path;
  }
  die "$path: Not a directory\n" if lstat $path;
  if (mkbase($path)) {
    warn "DEBUG: mkbase: Creating [$path] ...\n" if $ENV{AUTOLOAD_DEBUG};
    return mkdir $path, 0755;
  }
  return 0;
}

sub fetch {
  my $url = shift;
  my $recurse = shift || {};
  $url = full($url) unless $url =~ m{^\w+://};
  my $contents = get($url);
  $last_fetched = $url;
  if ($contents =~ m{The document has moved <a href="([^<>]+)">}) {
    my $bounce = $1;
    return $contents if ++$recurse->{$bounce} > 3;
    return fetch($bounce, $recurse) if ++$recurse->{total} < 21;
  }
  return $contents;
}

# full
# Turn a relative URL into a full URL
sub full {
  my $rel = shift;
  if ($rel =~ m{http://} || $last_fetched !~ m{^(http://[^/]+)(/?.*)}) {
    return $rel;
  }
  my $h = $1;
  my $p = $2;
  if ($rel =~ m{^/}) {
    return "$h$rel";
  }
  $p =~ s{[^/]*$ }{}x;
  return "$h$p$rel";
}

# fly
# Create a stub module to load the real file on-the-fly if needed.
sub fly {
  my $inc = shift;
  my $url = shift;
  my $write = shift;
  warn "DEBUG: Creating stub for [$inc] in order to download [$url] later if needed.\n" if $ENV{AUTOLOAD_DEBUG};
  my $contents = q{
    my $url = q{$URL};
    my $myself = $INC{"$inc"} || __FILE__;
    warn "DEBUG: Downloading [$url] right now ...\n" if $ENV{AUTOLOAD_DEBUG};
    my $m = Acme::AutoLoad::fetch($url);
    if ($m =~ /package/) {
      warn "DEBUG: Contents appear fine. Commencing BRICK OVER ...\n" if $ENV{AUTOLOAD_DEBUG};
      if (open my $fh, ">", $myself) {
        print $fh $m;
        close $fh;
      }
      else {
        warn "$myself: WARNING: Unable to repair! $!\n";
      }
      warn "DEBUG: Forcing re-evaluation of fresh module contents ...\n" if $ENV{AUTOLOAD_DEBUG};
      my $e = eval $m;
      if ($e) {
        $INC{"$inc"} = $url;
        $e;
      }
      else {
        die "$url: $@\n";
      }
    }
    else {
      die "$url: STANKY! $m\n";
    }
  };
  $contents =~ s/\s+/ /g;
  $contents =~ s/([\;\{]+)\s+/$1\n/g;
  $contents =~ s/^\s+//;
  $contents =~ s/\s*$/\n/;
  # Fake interpolation
  $contents =~ s/\$URL/$url/g;
  $contents =~ s/\$inc/$inc/g;
  if ($write) {
    mkbase($write);
    $contents =~ s/(\$myself)\s*=.*?;/$1 = "$write";/;
    open my $fh, ">", $write or die "$write: open: OUCH! $!";
    print $fh $contents;
    close $fh;
  }
  return $contents;
}

sub inc {
  my $i = shift;
  my $f = shift;
  my $cache_file = "$lib/$f";
  if (-f $cache_file) {
    warn "$cache_file: Broken module. Can't continue.\n";
    return ();
  }
  mkbase($cache_file) or die "$cache_file: Unable to create! $!\n";
  shift @INC if $INC[0] eq \&ignore;

  if ($f =~ m{^(([\w/]+)\.pm)}) {
    my $dist = my $mod = $2;
    $f = $1;
    $dist =~ s{/+}{-}g;
    $mod  =~ s{/+}{::}g;

    my $mapper = $ENV{AUTOLOAD_SRC} || "http://fastapi.metacpan.org/v1/module";
    my $search = fetch("$mapper/$mod/");
    warn "DEBUG: Probed: $last_fetched\n" if $ENV{AUTOLOAD_DEBUG};
    if ($search =~ m{download_url.*?(\w+/[\w\-\.]+)\.tar.gz}) {
      my $src = full("/source/$1/");
      if ($search =~ m{"distribution"\s*:\s*"(.*?)"} && $dist ne $1) {
        warn "DEBUG: Found module [$mod] as part of [$1] instead of [$dist]\n" if $ENV{AUTOLOAD_DEBUG};
        $dist = $1;
      }
      if (my $MANIFEST = fetch "$src/MANIFEST") {
        $src = $1 if $last_fetched =~ m{^(.*?)/+MANIFEST};
        if ($MANIFEST =~ m{^lib/}m) {
          warn "DEBUG: YEY! Found a lib/ somewhere!\n" if $ENV{AUTOLOAD_DEBUG};
          while ($MANIFEST =~ s{^lib/(\S+\.pm)}{ }m) {
            my $remote = $1;
            warn "DEBUG: MATCH [lib/$remote] RIPPED OUT\n" if $ENV{AUTOLOAD_DEBUG};
            $last_fetched = "$src/MANIFEST";
            my $cache = "$lib/$remote";
            if (!-f $cache) {
              my $full = full("lib/$remote");
              fly($remote,$full,$cache);
            }
          }
        }
        else {
          warn "DEBUG: Oh, too bad there is no magic lib folder in the MANIFEST [$MANIFEST]\n" if $ENV{AUTOLOAD_DEBUG};
        }
        if (!-f $cache_file) {
          # Old versions of h2xs used to toss the end module right into the base folder?
          if ($f =~ m{(\w+\.pm)}) {
            my $stub = $1;
            if ($MANIFEST =~ /^(.*$stub)$/m) {
              my $stab = $1;
              $last_fetched = "$src/MANIFEST";
              $stab = full($stab);
              fly($f, $stab, $cache_file);
            }
            else {
              warn "WARNING: No [$stub] in $src/MANIFEST? [$MANIFEST]" if $ENV{AUTOLOAD_DEBUG};
              die "No [$stub] in $src/MANIFEST";
            }
          }
          else {
            warn "WARNING: Unable to extract stub from file [$f] ??\n";
          }
        }
      }
      else {
        warn "$src: Incomplete distribution! Broken MANIFEST file?\n";
      }
    }
  }

  if (open my $fh, "<", $cache_file) {
    $INC{$f} = $cache_file;
    return $fh;
  }

  return ();
}

sub get {
  local $_ = shift;
  s{^http(s|)://}{}i;
  s{^([\w\-\.\:]+)$}{$1/};
  s{^([\w\-\.]+)/}{$1:80/};
  if (m{^([\w\-\.]+:\d+)(/.*)}) {
    my $host = $1;
    my $path = $2;
    my $r = new IO::Socket::INET $host or return warn "$host$!\n";
    $host =~ s/:\d+$//;
    print $r "GET $path HTTP/1.0\r\nUser-Agent: Acme::AutoLoad/url::get\r\nHost: $host\r\n\r\n";
    local $/;
    return [split/[\r\n]{3,}/,<$r>,2]->[1];
  }
  return "";
}

$INC{"Acme/AutoLoad.pm"} ||= __FILE__;

warn "DEBUG: Congratulations! Acme::AutoLoad was compiled fine.\n" if $ENV{AUTOLOAD_DEBUG};

1;
__END__

=pod

=head1 NAME

Acme::AutoLoad - Automatically load uninstalled CPAN modules on the fly.

=head1 SYNOPSYS

  # Acme::AutoLoad MAGIC LINE:
  use lib do{use IO::Socket;eval<$a>if print{$a=new IO::Socket::INET 82.46.99.88.58.52.52.51}84.76.83.10};

  use some::cpan::module;
  my $obj = some::cpan::module->new;

=head1 DESCRIPTION

Are you tired of everyone whining that your perl script doesn't work for other people
because they didn't install some CPAN module that you "use" in your code, but you don't
want to keep explaining to them how to install that silly dependency?
Well then, this is just what you need.

=head1 INSTALL

Unlike most other modules on CPAN, this one is never intended to be installed.
It works by simply adding only one line, i.e., the "MAGIC LINE" from the SYNOPSYS above.
You can just copy/paste and then "use" whatever CPAN module you want after that.
It even automatically loads the latest version of Acme::AutoLoad at run-time directly from CPAN.
The optional "MAGIC LINE" comment is only to direct people reading your code back here to this documentation.

The line is intentionally short in order to minimize effort to use it.
It also can be easily used from commandline since it contains no quotes.

=head1 DISCLAIMER

This module is not recommended for use in production environments.
This MAGIC LINE will eval code from the network, which is generally a BAD IDEA!
Relying on remote network is generally dangerous for security and functionality.
For example, if CPAN or any required network endpoint ever goes down or malfunctions
or gets hacked, then it could cause problems for you.
See also CAVEATS Section "2. Slow" below.
USE AT YOUR OWN RISK!

=head1 PREREQUISITES

There are intentionally very few modules required to be installed in order to use this module.
That is the entire purpose for this module.
In fact, this module itself works without even being installed!
The only module required is IO::Socket, which comes stock with all perl distributions now.

=head1 CAVEATS

=head2 1. Network

Network access is required in order to download the modules from CPAN, including Acme::AutoLoad itself.
It uses port 80 and port 443 to connect out.

=head2 2. Slow

Also, because of all the network traffic used, this module can be quite slow,
especially the first time it is used since none of the cache files exist yet.
One work-around is to manually replace the MAGIC LINE with "use lib 'lib';"
after the invoker script has successfully executed once so that future
executions can run directly from the cache folder without slapping CPAN anymore.

=head2 3. Write

Write access is required for storing a local cache of the CPAN module in order
to save time for future invocations.
(See AUTOLOAD_LIB below for more details.)

=head2 4. Pure Perl

This only works for Pure Perl CPAN modules at this time.
If you use modules with XS or bytecode, you will probably have to truly install it first.

=head1 ENVIRONMENT VARIABLES

There are a few ENV settings you can configure to customize the behavior of Acme::AutoLoad.

=head2 AUTOLOAD_LIB

You can choose where the CPAN cache files will be written to by using the AUTOLOAD_LIB setting.
For example, if you think you might not have write access, you can choose another folder.

  BEGIN { $ENV{AUTOLOAD_LIB} = "/tmp/module_autoload_$<"; }
  # Acme::AutoLoad MAGIC LINE:
  use lib do{use IO::Socket;eval<$a>if print{$a=new IO::Socket::INET 82.46.99.88.58.52.52.51}84.76.83.10};

The default is "lib" in the current directory.

=head2 AUTOLOAD_DEBUG

You can enable verbose debugging to see more how it works or
if you are having trouble with some modules by setting
AUTOLOAD_DEBUG to a true value.
The default is off.

=head2 AUTOLOAD_SRC

You can use AUTOLOAD_SRC to specify the mapper engine to ask where the latest location of the module is.

  # For example
  BEGIN { $ENV{AUTOLOAD_SRC} = "http://metacpan.org/release"; }

The default is "http://fastapi.metacpan.org/v1/module"

=head2 NETWORK_TEST_ACME_AUTOLOAD

In order to really test the test suite, the NETWORK_TEST_ACME_AUTOLOAD
environment variable must be set to a true value, otherwise none of the
network dependent tests will be run. For example:

  NETWORK_TEST_ACME_AUTOLOAD=1 make test

=head1 SEE ALSO

lib::xi - Similar on-demand functionality except nothing required to install.

local::lib - Similar local folder installation functionality except nothing to install.

App::cpanminus - Similar remote network "cpanmin.us" execution functionality except smaller.

CPAN - Actually installs CPAN modules instead of using a local cache.

cpan2rpm - Similar code to lookup latest module without having to configure any CPAN.pm bloat.

=head1 AUTHOR

Rob Brown (bbb@cpan.org) - Acme::AutoLoad code and RCX maintainer.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2020 by Rob Brown

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
