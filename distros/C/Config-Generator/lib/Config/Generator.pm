#+##############################################################################
#                                                                              #
# File: Config/Generator.pm                                                    #
#                                                                              #
# Description: shared variables for the Config::Generator modules              #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Config::Generator;
use strict;
use warnings;
our $VERSION  = "1.1";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.22 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Export qw(export_control);

#
# global variables
#

our(%Config, $HomeDir, @IncPath, $NoAction, $RootDir, $Verbosity);

%Config = ();
$HomeDir = "";
@IncPath = ();
$NoAction = 0;
$RootDir = "";
$Verbosity = 0;

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++,
         qw(%Config $HomeDir @IncPath $NoAction $RootDir $Verbosity));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__END__

=head1 NAME

Config::Generator - shared variables for the Config::Generator modules

=head1 DESCRIPTION

This module contains all the global variables used by the Config::Generator
modules.

=over

=item %Config

the configuration data

=item $HomeDir

the directory where the C<cfg>, C<lib> and C<tpl> sub-directories may be
located

=item @IncPath

the include path to use when looking for files

=item $NoAction

true if running in "no action" mode

=item $RootDir

the path to prepend to all the paths being used

=item $Verbosity

the amount of verbosity:

=over

=item C<0>: print nothing, only warnings and errors

=item C<1>: also print the changes that have been made

=item C<2>: also print the things that have been checked

=back

=back

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2013-2016
