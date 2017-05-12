package Apache::EnvDir;

use Apache ();
use Apache::Log ();
use Apache::Constants qw(OK DECLINED);
use Apache::ModuleConfig ();
use DynaLoader ();
use strict;
use warnings;

our $VERSION = '1.00';

sub MyLogger::log_error {
  my $self = shift;
  print STDERR shift, "\n";
}

if($ENV{MOD_PERL}) {
  our @ISA = qw(DynaLoader);
  __PACKAGE__->bootstrap($VERSION);
}

sub EnvDir ($$$;$) {
  my($cfg, $parms, $dirname, $prefix) = @_;
  $dirname = Apache->server_root_relative($dirname) unless $dirname =~ m|^/|;
  $cfg->{EnvDir}{$dirname} = {};
  return _loadenv($cfg->{EnvDir}{$dirname}, $dirname, $prefix, "MyLogger");
}

sub handler {
  my $r = shift;
  
  my $cfg = Apache::ModuleConfig->get($r) || return DECLINED;
  my $envdircfg = $cfg->{EnvDir};
  return DECLINED unless $envdircfg;

  foreach my $dirname (keys %$envdircfg) {
    my $dircfg = $envdircfg->{$dirname};
 
    _loadenv($dircfg, $dirname, $dircfg->{prefix}, $r);

    foreach my $file (keys %{$dircfg->{file}}) {
      $r->subprocess_env(join("", $dircfg->{prefix}, $file),
                         $dircfg->{file}{$file}[1]);
    }
  }
  return OK;
}

sub _loadenv {
  my($dircfg, $dirname, $prefix, $r) = @_;
  my $changeflag = 0;
    
  local *DIR;
  local *FILE;
  local $/ = undef;
  die "couldn't find directory called $dirname\n" unless (-d $dirname && -x _);

  # First time through, this creates an anonymous hash.
  # On subsequent runs, the hash is cleared if $dirname's
  # mtime has changed. This is how you get Apache::EnvDir
  # to notice that files have gone away.
  $dircfg->{mtime} ||= 0;
  %$dircfg = () if (stat(_))[9] > $dircfg->{mtime};

  $prefix ||= "";
  $dircfg->{prefix} = $prefix;
  $dircfg->{mtime} = (stat(_))[9];

  local *DIR;
  opendir(DIR, $dirname) || die "couldn't open $dirname\n";

  local *FILE;
  foreach my $file (readdir DIR) {
    my $path = join("/", $dirname, $file);

    # Only do files.
    next unless (-f $path && -r _);

    # Skip files that havn't changed.
    $dircfg->{file}{$file} ||= [0,""];
    next unless (stat(_))[9] > $dircfg->{file}{$file}[0];

    $changeflag++;
    $dircfg->{file}{$file}[0] = (stat(_))[9];

    if(open FILE, $path) {
      $dircfg->{file}{$file}[1] = <FILE>;
      $dircfg->{file}{$file}[1] =~ s/[\r\n]$//g;
      close(FILE);
    } else {
      $r->log_error("couldn't open $path") if $r;
    }
  }
  closedir(DIR);
  return $changeflag;
}

1;
 
__END__

=head1 NAME 

Apache::EnvDir - Dynamically set environment variables via a directory of files

=head1 SYNOPSIS

httpd.conf:

  PerlModule Apache::EnvDir
  PerlPostReadRequestHandler Apache::EnvDir

  EnvDir /path/to/dir/of/files PREFIX

=head1 DESCRIPTION

Apache::EnvDir creates environment variables using a directory of files. The
environment is dynamic -- changes to the files are reflected immediately
within Apache -- which allows data to be passed into the Apache environment
without restarting the webserver.

The module should be installed as a PostReadRequest handler to allow its
changes to be seen by other modules such as mod_cgi and mod_include.

=head1 OPTIONS

Apart from installing the module, loading it into mod_perl, and registering
it as a handler, there is only one configuration option

=over 4

=item EnvDir

This directive takes either one or two arguments. The first argument is
always a directory path (either absolute or relative to ServerRoot). Any
files found in this directory will be turned into environment variables.
The filename (minus any directory information) will become the variable
name and the contents of the file become the value of the variable.

If EnvDir is called with two arguments, the second argument is used as a
variable name prefix and will be prepended to the filename when
constructing the environment variable name.

  EnvDir /path/to/dir FOO_

If /path/to/dir contains a file named BAR, an environment variable
named FOO_BAR will be created within Apache. The contents of FOO_BAR will
be the contents of the file BAR. If BAR's contents change while Apache
is running, the contents of FOO_BAR will change as well.

If a file is added to the directory, a new variable is immediately
created. If a file is removed, the variable will be removed.

=back

=head1 NOTES

This is alpha software, and as such has not been tested on multiple
platforms or environments. This version of Apache::EnvDir requires
Apache 1.3 and mod_perl. It does not currently run in Apache 2 or
mod_perl 2.

=head1 SEE ALSO

perl(1), mod_perl(3), Apache(3), mod_env

=head1 AUTHOR

Michael Cramer <cramer@webkist.com>

=head1 COPYRIGHT

Copyright (c) 2003, Michael Cramer
All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
1;
