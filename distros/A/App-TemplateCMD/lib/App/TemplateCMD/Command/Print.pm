package App::TemplateCMD::Command::Print;

# Created on: 2008-03-26 13:43:32
# Create by:  ivanw
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp qw/carp croak cluck confess longmess/;
use List::MoreUtils qw/uniq/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Template;
use Template::Provider;
use IPC::Open2;
use base qw/App::TemplateCMD::Command/;

our $VERSION     = version->new('0.6.8');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

sub process {
    my ($self, $cmd, %option) = @_;

    my $template = shift @{$option{files}};
    my $args     = $cmd->conf_join(
        $cmd->conf_join( ( $cmd->config || {} ), ( $option{args} || {} ) ),
        \%option
    );

    confess "No template passed!\n" if !$template;

    my $out = '';
    $cmd->{template}->process( $template, $args, \$out );
    warn  $cmd->{template}->error . "\n" if $cmd->{template}->error && $cmd->{template}->error !~ /^file error - .*: not a file$/;

    if (!$out) {
        my @files = uniq sort map {$_->{file}} $cmd->list_templates();

        my @templates = grep { m{^$template [.] .+ $}xms } @files;

        if (@templates) {
            $cmd->{template}->process( $templates[0], $args, \$out );
            warn  $cmd->{template}->error . "\n" if $cmd->{template}->error && $cmd->{template}->error !~ /^file error - .*: not a file$/;
        }
    }

    $out =~ s/^\0=__/__/gxms if $out;

    if ( $option{args}{tidy} ) {
        if ( $option{args}{tidy} eq 'perl' ) {
            eval { require Perl::Tidy };
            if ($EVAL_ERROR) {
                warn "Perl::Tidy is not installed, carn't tidy perl code\n";
            }
            else {
                my $tidied;
                eval {
                    local @ARGV;
                    Perl::Tidy::perltidy( source => \$out, destination => \$tidied );
                    $out = $tidied;
                };
                if ($EVAL_ERROR) {
                    warn "perltidy errored with: $EVAL_ERROR\n";
                }
            }
        }
        else {
            warn "$option{args}{tidy}tidy";
            my $pid = open2( my $fh_out, my $fh_in, "$option{args}{tidy}tidy" );
            sleep 1;
            print {$fh_in} $out;
            sleep 1;
            $out = <$fh_out>;
            waitpid( $pid, 0 );
            warn "exit status: " . $? >> 8;
        }
    }

    return $out;
}

sub help {
    my ($self) = @_;

    return <<"HELP";
$0 print [options] template [--out|-o file] [[-a|--args] key=value]

 -a --args[=]str  Specify arguments to pass on to the template. The format of
                  the arguments is key=value where key is the name of a template
                  variable. Arguments can be specified without explicit using
                  this option.
 -o --out[=]file  Specify a file to wright the out put to

Standard arguments:
 tidy=command     Specify tidy program which will post process the output.
                  If command equals perl the Perl::Tidy module is used directly

This command processes the template for saving or inserting/appending to
another file.

The arguments --args parameter passes parameters onto the individual templates
along with any variables set in the configuration file.

Also see:
$0 help templates
$0 help config

HELP
}

1;

__END__

=head1 NAME

App::TemplateCMD::Command::Print - Prints a parsed template out to screen or file

=head1 VERSION

This documentation refers to App::TemplateCMD::Command::Print version 0.6.8.

=head1 SYNOPSIS

   use App::TemplateCMD::Command::Print;

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
