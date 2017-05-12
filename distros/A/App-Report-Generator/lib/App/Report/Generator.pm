package App::Report::Generator;

use warnings;
use strict;

=head1 NAME

App::Report::Generator - Command line tool around Report::Controller

=cut

our $VERSION = '0.002';

use App::Cmd::Setup-app;

=head1 SYNOPSIS

Given a configuration file C<daily.yaml>, invoking App::Report::Controller
with:

    $ genreport daily

=head1 DESCRIPTION

This module provides a command line tool around Report::Controller.

=cut

sub _prepare_command
{
    my ( $self, $command, $opt, @args ) = @_;
    if ( my $plugin = $self->plugin_for($command) )
    {
        my ( $cmd, $opt, @args ) = $plugin->prepare( $self, @args );
        $cmd->can('set_action')
          and $cmd->set_action($command)
          ;    # when a command class can support multiple commands, we should tell the chosen
        return ( $cmd, $opt, @args );
    }
    else
    {
        return $self->_bad_command( $command, $opt, @args );
    }
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

1;    # End of App::Report::Generator
