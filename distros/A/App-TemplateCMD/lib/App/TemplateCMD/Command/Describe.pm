package App::TemplateCMD::Command::Describe;

# Created on: 2008-03-26 13:43:56
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

our $VERSION     = version->new('0.6.11');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

sub process {

    my ( $self, $cmd, %option ) = @_;
    my $template = shift @{$option{files}};

    my ($data, $provider, $error, $templates) = $self->get_template($template, $cmd);
    die "Could not find the template $template\n" if !$data->{text};

    my @vars = $data->{text} =~ /\[[%]-? (?!\#) \s* ([A-Z]+) \s* (.+?) \s* -?[%]\]/gxms;
    my %vars;
    for ( my $i = 0; $i < @vars; $i += 2 ) {
        $vars{$vars[$i]}{ $vars[$i+1] } = 1;
    }

    my $includes = join "\n    ", sort keys %{ $vars{INCLUDE} };
    my $vars     = join "\n    ", uniq sort grep {$_!~/^(?: END | CASE )$/xms} $data->{text} =~ /\[ [%] -? (?!\#) \s* (\w+?) \s* -?[%]\]/gxms;
    my $description = join "\n",  $data->{text} =~ /\[[%]\#= (.*?) -?[%]\]/gxms;

    $includes    ||= '(none)';
    $vars        ||= '(none)';
    $description &&= "\n$description\n";

    return <<"DESCRIPTION";
Details for '$template'
Location:
    $provider

Included templates:
    $includes

Variables used:
    $vars
$description
DESCRIPTION
}

sub help {
    my ($self) = @_;

    return <<"HELP";
$0 describe template

This command gives full details of a template, the variables it uses and
where the template is stored.
HELP
}

1;

__END__

=head1 NAME

App::TemplateCMD::Command::Describe - Command to describe a template (variables used, location etc)

=head1 VERSION

This documentation refers to App::TemplateCMD::Command::Describe version 0.6.11.

=head1 SYNOPSIS

   use App::TemplateCMD::Command::Describe;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<process ( $cmd, %option )>

Return: The description of the template

Description: Describes the template name found in $option{files}[0]

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
