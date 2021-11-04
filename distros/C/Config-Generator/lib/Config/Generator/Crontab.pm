#+##############################################################################
#                                                                              #
# File: Config/Generator/Crontab.pm                                            #
#                                                                              #
# Description: Config::Generator crontab support                               #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Config::Generator::Crontab;
use strict;
use warnings;
our $VERSION  = "1.1";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use Config::Generator qw(%Config);
use Config::Generator::Random qw(random_integer);
use Config::Generator::Template qw(process_template);

#
# format a crontab (/etc/cron.d/* syntax)
#

sub format_crontab (%) {
    my(%entry) = @_;
    my($contents, %map, $line);

    $contents = "";
    foreach my $name (sort(keys(%entry))) {
        next if $name eq "mailto";
        %map = ();
        foreach my $time (24, 60) {
            $map{"rnd$time"} = random_integer($time, "cron.$name");
        }
        $line = process_template($entry{$name}, \%map, \%Config);
        dief("unexpected character in cron entry: %s", $line)
            if $line =~ /[\x00-\x1f\x7f\x80-\xff]/;
        dief("unexpected cron entry: %s", $line)
            unless $line =~ /^\s*([\*\d\-\,]+(\/\d+)?\s+){5}[\w\-]+\s+\S/;
        $contents .= "$line\n";
    }
    return("") unless length($contents);
    $contents = "MAILTO=$entry{mailto}\n" . $contents
        if defined($entry{mailto});
    return($contents);
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, qw(format_crontab));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

Config::Generator::Crontab - Config::Generator crontab support

=head1 DESCRIPTION

This module eases the generation of crontabs.

A crontab is represented by a hash with one optional special key (C<mailto>
representing who should receive the cron reports) and the other keys for the
cron entries themselves. For instance:

  $cron{mailto}    = "john.doe\@acme.org";
  $cron{hourlyfoo} = "<{rnd60}> * * * * foo --option 3";
  $cron{dailybar}  = "<{rnd60}> <{rnd24}> * * * bar";
  $contents = format_crontab(%cron);

The "<{rnd*}>" tokens will be replaced by pseudo-random numbers in the given
range (24 or 60), provided by the L<Config::Generator::Random> module.

=head1 FUNCTIONS

This module provides the following functions (none of them being exported by
default):

=over

=item format_crontab(HASH)

transform the crontab abstraction represented by the given HASH into a string
suitable to be saved under the C</etc/cron.d> directory

=back

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2013-2016
