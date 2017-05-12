package Config::File;
use warnings;
use strict;
use Carp;
use Exporter;
use IO::File;

use vars qw($VERSION @ISA @EXPORT_OK);
@ISA = qw/Exporter/;
@EXPORT_OK = qw/read_config_file/;
$VERSION='1.50';


sub read_config_file($) {
    my ($conf, $file, $fh, $line_num);
    $file = shift;
    $fh = IO::File->new($file, 'r') or
        croak "Can't read configuration in $file: $!\n";

    while (++$line_num and my $line = $fh->getline) {
        my ($orig_line, $conf_ele, $conf_data);
        chomp $line;
	$orig_line = $line;

        next if $line =~ m/^\s*#/;
        $line =~ s/(?<!\\)#.*$//;
        $line =~ s/\\#/#/g;
        next if $line =~ m/^\s*$/;
        $line =~ s{\$(\w+)}{
            exists($conf->{$1}) ? $conf->{$1} : "\$$1"
            }gsex;
        

	unless ($line =~ m/\s*([^\s=]+)\s*=\s*(.*?)\s*$/) {
	    warn "Line format invalid at line $line_num: '$orig_line'";
	    next;
	}

        ($conf_ele, $conf_data) = ($1, $2);
        unless ($conf_ele =~ /^[\]\[A-Za-z0-9_-]+$/) {
            warn "Invalid characters in key $conf_ele at line $line_num" .
		" - Ignoring";
            next;
        }
        $conf_ele = '$conf->{' . join("}->{", split /[][]+/, $conf_ele) . "}";
        $conf_data =~ s!([\\\'])!\\$1!g;
        eval "$conf_ele = '$conf_data'";
    }
    $fh->close;

    return $conf;
}

1;

__END__

=pod

=head1 NAME

Config::File - Parse a simple configuration file

=head1 SYNOPSIS

use Config::File;

my $config_hash = Config::File::read_config_file($configuration_file);

=head1 DESCRIPTION

C<read_config_file> parses a simple configuration file and stores its
values in an anonymous hash reference. The syntax of the configuration
file is as follows:

    # This is a comment
    VALUE_ONE = foo
    VALUE_TWO = $VALUE_ONE/bar
    VALUE_THREE = The value contains a \# (hash). # This is a comment.

Options can be clustered when creating groups:

    CLUSTER_ONE[data] = data cluster one
    CLUSTER_ONE[value] = value cluster one
    CLUSTER_TWO[data] = data cluster two
    CLUSTER_TWO[value] = value cluster two

Then values can be fetched using this syntax:

    $hash_config->{CLUSTER_ONE}{data};

There can be as many sub-options in a cluster as needed.

    BIG_CLUSTER[part1][part2][part3] = data

is fetched by:
    $hash_config->{BIG_CLUSTER}{part1}{part2}{part3};

There are a couple of restrictions as for the names of the keys. First of all,
all the characters should be alphabetic, numeric, underscores or hyphens, with
square brackets allowed for the clustering. That is, the keys should conform
to /^[A-Za-z0-9_-]+$/

This means also that no space is allowed in the key part of the line.

    CLUSTER_ONE[data] = data cluster one      # Right
    CLUSTER_ONE[ data ] = data cluster one    # Wrong


=head1 Function C<read_config_file>

=head2 Syntax

    Config::File::read_config_file($file);

=head2 Arguments

C<$file> is the configuration file.

=head2 Return value

This function returns a hash reference. Each key of the hash is a
value defined in the configuration file.

=head2 Description

C<read_config_file> parses a configuration file a sets up some values 
in a hash reference.

=head1 NOTES

=head2 Function not exported by default

In versions up to 1.0, the function read_config_file was exported to the
calling program's namespace - Starting in version 1.1, nothing is exported
by default. You can either fully qualify read_config_file or explicitly
import it into your namespace:

=over 4

=item Fully qualifying read_config_file

  use Config::File;

  my $config_hash = Config::File::read_config_file($configuration_file);

=item Explicitly importing read_config_file

  use Config::File qw(read_config_file);

  my $config_hash = read_config_file($configuration_file);

=back

=head2 Migrated away from ConfigFile into Config::File

As of version 1.4, in order to include this module in the CPAN, I decided to
move away from the highly unstandard name of ConfigFile and rename the module
to Config::File. A small redirecting module is put in place, so current code
using this module does not break, but the ConfigFile namespace usage is
deprecated (and will thus issue a warning). Please update your code!

=head1 AUTHOR

Development was started by Sebastien J. Gross <seb@sjgross.org>, and since 
2003 it is maintained by Gunnar Wolf <gwolf@gwolf.org>.

All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the terms of the GPL.

=head1 VERSION

Version 1.4
Copyright (c) 2002 Sebastien J. Gross. All rights reserved.
Copyright (c) 2003-2009 Gunnar Wolf. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the terms of the GPL v2 (or later, at your choice).

=cut
