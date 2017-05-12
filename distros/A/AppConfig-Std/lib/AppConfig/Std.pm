#=======================================================================
#
# AppConfig::Std - subclass of AppConfig to provide standard tool config
#
# This is a perl module which implements a specialisation of
# Andy Wardley's AppConfig module. It basically provides five standard
# command-line arguments:
#
#   -help       display a short help statement
#   -doc        display the full documentation (formatted pod)
#   -version    display the version of the script
#   -verbose    turn on verbose output
#   -debug      turn on debugging output
#
# The -help and -doc functionality is provided by Brad Appleton's
# Pod::Usage module. I wrote this module because I was cutting &
# pasting code between scripts.
#
# Written by Neil Bowers <neil@bowers.com>
#
# Copyright (C) 2002-2013 Neil Bowers.
# Copyright (C) 1998-2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
#=======================================================================

package AppConfig::Std;
$AppConfig::Std::VERSION = '1.10';
use 5.006;
use strict;
use warnings;

use AppConfig;
# we also make use of Pod::Usage, but require it if needed

use vars qw(@ISA $VERSION);

@ISA     = qw(AppConfig);

#=======================================================================
#
# new() - constructor
#
# The constructor:
#   > invokes the AppConfig constructor with standard config
#   > blesses the instance into this package
#   > defines the -help, -doc, -version, and -debug options
#       > configures with any additional options passed to constructor
#
#=======================================================================
sub new
{
    my $class = shift;
    my $cfg   = shift;

    my $self;


    $self = bless AppConfig->new({
                               GLOBAL => { ARGCOUNT => 1
                                         }}), $class;

    $self->define('help',    { ARGCOUNT => 0 } );
    $self->define('doc',     { ARGCOUNT => 0 } );
    $self->define('version', { ARGCOUNT => 0 } );
    $self->define('verbose', { ARGCOUNT => 0 } );
    $self->define('debug',   { ARGCOUNT => 0 } );

    $self->_configure($cfg) if defined $cfg;

    return $self;
}


#=======================================================================
#
# args() - parse command-line arguments (@ARGV)
#
# We over-ride the args() method, to handle the -doc, -help
# and -version command-line switches.
#
#=======================================================================
sub args
{
    my $self = shift;
    my $ref  = shift;

    my $result;


    #-------------------------------------------------------------------
    # Use AppConfig's args() method to parse the command-line.
    #-------------------------------------------------------------------
    $result = $self->SUPER::args($ref);

    #-------------------------------------------------------------------
    # If the command-line was successfully parsed (returned TRUE),
    # then check for the standard command-line switches.
    #-------------------------------------------------------------------
    if ($result) {
        $self->_handle_std_opts();
    }

    return $result;
}


#=======================================================================
#
# getopt() - parse command-line arguments (@ARGV)
#
# We over-ride the getopt() method, to handle the -doc, -help
# and -version command-line switches.
#
#=======================================================================
sub getopt
{
    my $self = shift;
    my $ref  = shift;

    my $result;


    #-------------------------------------------------------------------
    # Use AppConfig's getopt() method to parse the command-line.
    #-------------------------------------------------------------------
    $result = $self->SUPER::getopt($ref);

    #-------------------------------------------------------------------
    # If the command-line was successfully parsed (returned TRUE),
    # then check for the standard command-line switches.
    #-------------------------------------------------------------------
    if ($result) {
        $self->_handle_std_opts();
    }

    return $result;
}


#=======================================================================
#
# _handle_std_opts() - handle the standard options defined by us
#
#=======================================================================
sub _handle_std_opts
{
    my $self = shift;


    #-------------------------------------------------------------------
    # We only load Pod::Usage if we're gonna use it.
    # Because we're require'ing, the functions don't get exported
    # to us, hence the explicit namespace reference.
    #-------------------------------------------------------------------
    require Pod::Usage if $self->doc || $self->help;
    Pod::Usage::pod2usage({-verbose => 2, -exitval => 0}) if $self->doc();
    Pod::Usage::pod2usage({-verbose => 1, -exitval => 0}) if $self->help();
    _show_version() if $self->version();
}


#=======================================================================
#
# _show_version()
#
# Display the version number of the script. This assumes that
# the invoking script has defined $VERSION.
#
#=======================================================================
sub _show_version
{
    print "$main::VERSION\n";
    exit 0;
}


1;

__END__

=head1 NAME

AppConfig::Std - subclass of AppConfig that provides standard options

=head1 SYNOPSIS

    use AppConfig::Std;

    $config = AppConfig::Std->new();

    # all AppConfig methods supported
    $config->define('foo');            # define variable foo
    $config->set('foo', 25);           # setting a variable
    $val = $config->get('foo');        # getting variable
    $val = $config->foo();             # shorthand for getting

    $config->args(\@ARGV);             # parse command-line
    $config->file(".myconfigrc")       # read config file

=head1 DESCRIPTION

B<AppConfig::Std> is a Perl module that provides a set of
standard configuration variables and command-line switches.
It is implemented as a subclass of AppConfig; AppConfig provides
a general mechanism for handling global configuration variables.

The features provided by AppConfig::Std are:

=over 4

=item *

Standard command-line arguments: -help, -doc, -version,
-verbose, and -debug. AppConfig::Std handles the -help, -doc,
and -version switches for you, so you don't need to duplicate
that code in all of your scripts.
These are described below.

=item *

The ARGCOUNT default is set to 1. This means that by default
all switches are expected to take a value. To change this,
set the ARGCOUNT parameter when defining the variable:

    $config->define('verbose', { ARGCOUNT => 0 } );

=back

Please read the copious documentation for AppConfig to
find out what else you can do with this module.

=head1 STANDARD OPTIONS

The module adds five standard configuration variables
and command-line switches. You can define additional
variables as you would with AppConfig.

=head2 HELP

The B<-help> switch will result in a short help message.
This is generated using Pod::Usage, which displays the B<OPTIONS>
section of your pod. The script will exit with an exit value of 0.

=head2 DOC

The B<-doc> switch will result in the entire documentation
being formatted to the screen.
This is also done with Pod::Usage.
The script will exit with an exit value of 0.

=head2 VERSION

The B<-version> switch will display the version of the invoking script.
This assumes that you have defined C<$VERSION> in your script
with something like the following:

    use vars qw( $VERSION );
    $VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

The script will exit with an exit value of 0.

=head2 DEBUG

The B<-debug> switch just sets the B<debug> variable.
This is useful for displaying information in debug mode:

    $foobar->dump() if $config->debug;

=head2 VERBOSE

The B<-verbose> switch just sets the B<verbose> variable.
This is useful for displaying verbose information as
a script runs:

    print STDERR "Running foobar\n" if $config->verbose;

=head1 TODO

Please let me know if you have ideas for additional switches,
or other modifications. Things currently being mulled:

=over 4

=item *

Support brief switches, such as B<-h> as well as B<-help>.
This could be a config option for the constructor.

=item *

Include a sample script called B<mkscript>, which would create
a template script along with Makefile.PL, MANIFEST, etc.
Kinda of a h2xs for scripts.

=back

=head1 EXAMPLE

The following is the outline of a simple script that illustrates
use of the AppConfig::Std module:

    #!/usr/bin/perl -w
    use strict;
    use AppConfig::Std;

    use vars qw( $VERSION );
    $VERSION = '1.0';

    my $config = AppConfig::Std->new();

    # parse command-line and handle std switches
    $config->args(\@ARGV);

    exit 0;

    __END__

    =head1 NAME

    standard pod format documentation

The pod documentation is expected to have the NAME, SYNOPSIS,
DESCRIPTION, and OPTIONS sections. See the documentation
for C<pod2man> for more details.

=head1 SEE ALSO

L<AppConfig> -
Andy Wardley's module for unifying command-line switches and
cofiguration files into the notion of configuration variables.
AppConfig::Std requires version 1.52+ of the module,
which is available from CPAN.

L<Pod::Usage> -
Brad Appleton's module for extracting usage information out
of a file's pod. This is used for the B<-doc> and B<-help> switches.
Available from CPAN as part of the PodParser distribution.

L<perlpod|https://metacpan.org/pod/distribution/perl/pod/perlpod.pod> -
documentation from the perl distribution that describes
the pod format.

L<pod2man|https://metacpan.org/pod/distribution/podlators/scripts/pod2man> -
particularly the NOTES section in the documentation
which describes the sections you should include in your documentation.
AppConfig::Std uses Pod::Usage, which assumes well-formed pod.


=head1 REPOSITORY

L<https://github.com/neilb/AppConfig-Std>

=head1 AUTHOR

Neil Bowers E<lt>neil@bowers.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2002-2013 Neil Bowers.

Copyright (c) 1998-2001 Canon Research Centre Europe. All rights reserved.

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

