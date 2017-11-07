package App::TemplateCMD::Command::Build;

# Created on: 2008-03-26 13:43:32
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
use Template;
use Template::Provider;
use YAML qw/Load/;
use Path::Tiny;
use base qw/App::TemplateCMD::Command/;

our $VERSION     = version->new('0.6.8');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

sub process {
    my ($self, $cmd, %option) = @_;

    my $template = 'build/' . shift @{$option{files}};
    my $args     = { %{ $cmd->config }, %{ $option{args} || {} } };

    my $print = $cmd->load_cmd('print');
    my $out = $print->process( $cmd, %{ $args }, files => [$template] );

    my $structure = Load($out);

    for my $file (keys %{ $structure }) {
        my $template = $structure->{$file}{template};
        my $file = path($file);

        if ( !-e $file || $option{force} ) {
            $file->parent->mkpath();
        }

        # process the template
        my $out = $print->process(
            $cmd,
            file => $file,
            %{ $args },
            %{ $structure->{$file} },
            files => [$template]
        );
        my $fh = $file->openw;
        print {$fh} $out;
        close $fh;
    }

    return $out;
}

sub args {
    return (
        'force|f!',
    );
}

sub help {
    my ($self) = @_;

    return <<"HELP";
$0 build [options] build_template

Options
 -a --args=str   Arguments to the build template

This builds a directory structure baised on the results of a build template

HELP
}

1;

__END__

=head1 NAME

App::TemplateCMD::Command::Build - Builds a a tree of files from a build template

=head1 VERSION

This documentation refers to App::TemplateCMD::Command::Build version 0.6.8.

=head1 SYNOPSIS

   use App::TemplateCMD::Command::Build;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<process ( %args )>

Return: The processed template

Description: Processes the template for out putting

=head3 C<args ( %args )>

Return: list - A list of accepted arguments

Description: This is just a stub for other commands to override to specify their aliases

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
