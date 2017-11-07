package App::TemplateCMD::Command::List;

# Created on: 2008-03-26 13:44:05
# Create by:  ivanw
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use List::MoreUtils qw/uniq/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/App::TemplateCMD::Command/;

our $VERSION     = version->new('0.6.8');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

sub process {
    my ($self, $cmd, %option) = @_;
    my $out = '';

    my $filter = shift @{$option{files}};
    my $path   = $cmd->config->{path};
    my @path   = grep {-d $_} split /:/, $path;

    my @files = $cmd->list_templates();

    my @templates = uniq sort map {$_->{file}} @files;

    if ($filter) {
        @templates = grep {/$filter/} @templates;
    }

    $option{columns} ||= 6;

    my $files_per_col = @templates / $option{columns};
    $files_per_col = $files_per_col == int $files_per_col ? $files_per_col : int $files_per_col + 1;
    my @columns;
    my @max;

    for my $row ( 0 .. $files_per_col - 1 ) {
        for my $col ( 0 .. $option{columns} - 1 ) {
            next if !$templates[$row * $option{columns} + $col];
            push @{$columns[$col]}, $templates[$row * $option{columns} + $col];
            $max[$col] ||= 1;
            $max[$col] = length $templates[$row * $option{columns} + $col] if length $templates[$row * $option{columns} + $col] > $max[$col];
        }
    }

    for my $row ( 0 .. $files_per_col -1 ) {
        for my $col ( 0 .. $option{columns} - 1 ) {
            next if !$columns[$col][$row];
            $out .= $columns[$col][$row] . ' ' x ($max[$col] + 1 - length $columns[$col][$row]);
        }
        $out .= "\n";
    }

    return $out;
}

sub help {
    my ($self) = @_;

    return <<"HELP";
$0 list [filter]

filter   An optional regular expression to show only templates that match.

Lists all the templates that can be found, optionally limited by the regular
expression filter.
HELP
}

1;

__END__

=head1 NAME

App::TemplateCMD::Command::List - Command to list the available templates.

=head1 VERSION

This documentation refers to App::TemplateCMD::Command::List version 0.6.8.

=head1 SYNOPSIS

   use App::TemplateCMD::Command::List;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<process ( $cmd, %args )>

Return: A list of all templates found buy the template providers

Description: Lists all available templates.

=head2 C<help ()>

Returns the help text

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
