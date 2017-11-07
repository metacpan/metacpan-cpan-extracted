package App::TemplateCMD::Command;

# Created on: 2008-09-04 04:26:46
# Create by:  ivan
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/Exporter/;

our $VERSION     = version->new('0.6.8');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();
#our @EXPORT      = qw//;

sub args {
    return (
        'path|p=s',
    );
}

sub default {
}

sub get_template {

    my ($self, $template, $cmd) = @_;

    # try to get the template directly by name
    for my $provider (@{ $cmd->{providers} }) {
        if ($provider->{INCLUDE_PATH}) {
            for my $path (@{ $provider->{INCLUDE_PATH} }) {
                my ($data, $error) = $provider->_load( "$path/$template" );

                if ($data->{text}) {
                    # return the found template info
                    return ($data, $provider, $error, [$template]);
                }
            }
        }
        else {
            my ($data, $error) = $provider->_load( $template );

            if ($data->{text}) {
                # return the found template info
                return ($data, $provider, $error, [$template]);
            }
        }

        if ($cmd->{verbose}) {
            print "$template was not found with provider " . ( ref $provider ) . "\n";
        }
    }

    # now try to get the template assumin it is missing its suffix
    my @files = map {$_->{file}} $cmd->list_templates();

    # get all templates that start with the template name provided
    my @templates = grep { m{^$template [.] .+ $}xms } @files;

    if (@templates) {
        for my $provider (@{ $cmd->{providers} }) {
            my ($data, $error) = $provider->_load( $templates[0] );

            if ($data->{text}) {
                # return the found template info
                return ($data, $provider, $error, \@templates);
            }
        }
    }

    # no template found
    croak "The template $template was not found!";
}

1;

__END__

=head1 NAME

App::TemplateCMD::Command - The base class for command modules

=head1 VERSION

This documentation refers to App::TemplateCMD::Command version 0.6.8.

=head1 SYNOPSIS

   use App::TemplateCMD::Command;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<args ()>

Stub for returning command specific arguments

=head3 C<default ()>

Stub for returning default values for values of command line inputs

=head3 C<get_template ( $template, $cmd )>

Arg: C<$template> - type (detail) - description

Arg: C<$cmd> - type (detail) - description

Return: ($data, $provider, $error, $templates)

Description: Gets the data for a template

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Ivan Wills (14 Mullion Close, NSW, Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
