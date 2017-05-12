package App::Report::Generator::Command::GenReport;

use strict;
use warnings;

use vars qw(@ISA $VERSION);

=head1 NAME

App::Report::Generator::Command::GenReport - provides the command class to run report configurations.

=head1 SYNOPSIS

This module is not intended to be used directly.

=head1 DESCRIPTION

This module provides a command class for C<App::Report::Generator> to find
configuration files loadable by L<Config::Any> and run then via
L<Report::Generator>.

The configuration is searched in the configuration subdirectories
C<genreport> unless C<$ENV{APP_GENREPORT_CONFIGBASE}> is set.

You can place the configuration at any location where configuration files
could be expected, see L<File::ConfigDir> for reasonable locations. Of
course, test reports should be placed locally for the user
(e.g. C<$ENV{HOME}/genreport/test-report1.yaml>), reports which are
planned to do periodically shall be placed at a location where the cron
process could find it (C</usr/local/etc/genreport/daily.yml> or
C</opt/p5-genreport/etc/weekly.json>).

Use C<< genreport commands >> to figure out, which reports can be run.

=head1 FUNCTIONS/METHODS

=cut

use Carp qw(croak);

use File::Basename;
use File::Find::Rule;
use Config::Any;
use File::ConfigDir qw(0.003 config_dirs);

use Report::Generator;

use App::Report::Generator-command;

$VERSION = "0.002";

#sub opt_spec {
#}

#sub validate_args {
#}

my %cmdcfg;

=head2 command_names

Finds config files using L<File::ConfigDir> (C<config_dirs>),
L<Config::Any> (C<extensions>) and L<File::Find::Rule>.
The searched depth is 1 - subdirectories aren't traversed.

=cut

sub command_names
{
    my $self = $_[0];

    unless (%cmdcfg)
    {
        my $cfgapp =
          defined( $ENV{APP_GENREPORT_CONFIGBASE} ) ? $ENV{APP_GENREPORT_CONFIGBASE} : 'genreport';
        my @cfgext = map { "*." . $_ } Config::Any->extensions();
        my @cfgdirs = config_dirs($cfgapp);
        @cfgdirs or croak("No configuration directories");
        # scan config directories
        my @cfgfiles = File::Find::Rule->file()->name(@cfgext)->maxdepth(1)->in(@cfgdirs);

        @cfgfiles or croak("No configuration directories");
        # add config file base names
        foreach my $cfgfile (@cfgfiles)
        {
            my ( $cfgbasename, undef, undef ) = fileparse( $cfgfile, qr/\.[^.]*/ );
            $cmdcfg{ lc $cfgbasename } = $cfgfile;
        }
    }

    return keys %cmdcfg;
}

=head2 set_action

Takes the user desired action (base name of the configuration file).

=cut

sub set_action
{
    my ( $self, $command ) = @_;
    $self->{action} = $command;
}

=head2 execute

Executes the report generation for the given report.

=cut

sub execute
{
    my ( $self, $opt, $args ) = @_;

    # check $actual_cmd
    my $cfgfile = $cmdcfg{ $self->{action} };
    return Report::Generator->new( { cfg => $cfgfile } )->generate();
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-report-generator at rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Report-Generator>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Report::Generator

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Report-Generator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Report-Generator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Report-Generator>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Report-Generator/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
