package Apache::Yaalr;

use 5.008008;
use strict;
use warnings;
use Carp qw(croak);

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw( @potential_confs );
our $VERSION = '0.03.3 ';

my (@potential_confs, @dirs);
my @mac = qw( /etc/apache /etc/apache2 /etc/httpd /usr/local/apache2 /Library/WebServer/ );
my @lin = qw( /etc/apache /etc/apache2/sites-avilable/ /etc/httpd /usr/local/apache2 /etc/apache-perl );

sub new {
  my $package = shift;
  return bless({}, $package);
}

sub os { # operating system best guess, we'll need this later
  my $self = shift;
  my $uname = `which uname`;
  my @os;

  if ($uname) {
    push @os, `uname -a` or croak "Cannot execute uname -a";
  } elsif ($^O) {
    push @os, "$^O unknown";
  } else {
    push @os, "unknown unknown";
  }
  return @os;
}


# This is for getting info from a user supplied Apache2 config file
sub apache2_conf {
  my ($self, $file) = @_;
  croak("$file does not exist.") unless (-e $file);
  croak("$file not readable.") unless (-r $file);
  my ($str, $line, $format);
  my (@formats, @format_string);
  open FH, $file or croak "Cannot open configuration file: $file";

  while (<FH>) {
    if (/LogFormat/) {
      push @formats, $_;
    }
  }
  close FH;
  # here we need to scoop up everything in sites-available
  croak("Format not found\n") unless (($#formats) >= 0) ;

  for (@formats) {
    my @format_string = split / /, $_;
    $format = pop @format_string;
    $str = \@format_string;
  }
  return ($file, \$format, $str);
}


sub httpd_conf { # get LogFormat and type of log from user supplied httpd.conf file 
  my $self = shift;
  my $file = shift;
  croak("$file does not exist.") unless (-e $file);
  # check the basename here to make sure we have a httpd.conf file
  my ($str, $line, $log_type, $location, $format);
  my ( @formats, @custom, @format_string,);
  open FH, $file or croak "Cannot open configuration file: $file";

  while (<FH>) {
    if (/LogFormat/) {
      push @formats, $_;
    }
    if (/CustomLog/) {
      push @custom, $_;
    }
  }
  close FH;

  croak("Format not found\n") unless (($#formats) && ($#custom) >= 0) ;

  for $line (@custom) {
    if ($line !~ /#/) {   # this is a hack, it gets commented-out lines
      my ($CustomLog, $location, $log_type) = split / /, $line;
      $log_type =~ s/ //g;
      for (@formats) {
	my @format_string = split / /, $_;
	$format = pop @format_string;
	if ($format =~ /$log_type/) {
	  shift @format_string;
	  $str = \@format_string;
	  last; # no need to check further
	}
      }
      chomp($log_type);
      return ($file, $log_type, $location, $str);
    }
  }
}

sub find_conf {
  my $self = shift;

  use File::Find qw(find);
  if ($^O =~ /darwin/) {

    # grep for potential apache dirs on the system - note that apache2 does things differently!!

	@dirs = grep {-d} @mac;
	croak "no suitable directories" unless @dirs;

	find(\&httpd, @dirs);
	find(\&apache2, @dirs);	

	# return an array of files
	return @potential_confs;

      } elsif ($^O =~ /linux/) {
	@dirs = grep {-d} @lin;
	croak "no suitable directories" unless @dirs;

	find(\&httpd, @dirs);
	find(\&apache2, @dirs);	

	# return an array of files
	return @potential_confs;
      } else {
	croak "Cannot determine operating system.";
      }
}
sub httpd { 
  /^httpd.conf$/ &&
    -r &&
      push @potential_confs, $File::Find::name;
}

sub apache2 { 
  /^apache2.conf$/ &&
    -r &&
      push @potential_confs, $File::Find::name;
}


1;

__END__

=head1 NAME

Apache::Yaalr - Perl module for Yet Another Apache Log Reader

=head1 SYNOPSIS

    use Apache::Yaalr qw( @potential_confs );

    my $a = Apache::Yaalr->new();

    # get operating system information
    my @os = $a->os();

    # Get information from an apache2 configuration
    my ($file, $format, $str) = $a->apache2_conf("/etc/apache2/apache2.conf");

    $a->os();          - an estimation of the operating system using uname -a if uname exists. 
                         Otherwise this uses $^O. If it cannot find the hostname or 
                         operating system, it returns unknown.

    $a->apache2_conf("/etc/apache2/apache2.conf");     <= This is not yet complete EXPERIMENTAL!

                       - this allows you to pass an apache2 configuration set and find out
                         the format string from the format you are using, as well as the 
                         type of log that has been assigned, (i.e. agent, common, combined, etc.)

=head1 DESCRIPTION

The goal of Yaalr (Yet Another Apache Log Reader) is to read Apache access logs and report 
back. Since the Apache web server can have its access log in different places
depending on operating system, Yaalr does its best to find out what type of operating 
system is being used and then find the configuration files to extract the location of the log
files. Along the way a lot of other potentially useful information is gathered which can also 
be accessed through the above interface. 

=head1 EXAMPLES

use Apache::Yaalr qw( @potential_confs );

my $a = Apache::Yaalr->new();
my @os = $a->os();

# break apart the array from $^0 or uname

my ($os, $name, $rest) = split / /, $os[0];
print "\n\tLocal hostname: $name\n\tOperating system: $os\n";

=head1 SEE ALSO

More information can be found regarding Yaalr here: http://yaalr.sourceforge.net

Also Apache(1)

=head1 AUTHOR

Jeremiah Foster, E<lt>jeremiah@jeremiahfoster.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 - 2008 by Jeremiah Foster

=head1 LICENSE

This software is dual licensed under the terms of the Artistic License
and the GPL-1 as described below.

License: Artistic
    This program is free software; you can redistribute it and/or modify
    it under the terms of the Artistic License, which comes with Perl.

    On Debian GNU/Linux systems, the complete text of the Artistic License
    can be found in /usr/share/common-licenses/Artistic

License: GPL-1+
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by 
    the Free Software Foundation; either version 1, or (at your option)
    any later version.

    On Debian GNU/Linux systems, the complete text of the GNU General
    Public License can be found in `/usr/share/common-licenses/GPL'

=cut
