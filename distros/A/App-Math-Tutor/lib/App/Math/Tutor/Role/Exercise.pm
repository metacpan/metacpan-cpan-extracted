package App::Math::Tutor::Role::Exercise;

use warnings;
use strict;

=head1 NAME

App::Math::Tutor::Role::Exercise - basic role for getting exercises

=cut

use Moo::Role;
use MooX::Options;

use Carp qw(croak);
use Cwd qw(abs_path getcwd);
use File::Spec     ();
use File::ShareDir ();
use Template       ();

our $VERSION = '0.005';

=head1 ATTRIBUTES

=head2 quantity

Specifies number of calculations to generate

=cut

option quantity => (
    is       => "ro",
    doc      => "Specifies number of exercises to generate",
    long_doc => "Specify number of exercises to generate. In "
      . "case of several kind of exercises, \$quantity exercises "
      . "are generated per kind.",
    format  => "i",
    short   => "n",
    default => sub { 15 },
);

=head2 exercises

Lazy hash containing the exercises to fill into the template.

Expected attribute:

=over 4

=item section

The caption of the section containing the challenges. The solutions section
will reuse the section caption prepended by I<Solution:>.

=item caption

Table caption for challenges table. The solutions table will be prepended
by the word I<Solution>.

=item label

Label of the table containing the challenges - the solutions table will
be the given label prepended by I<solution>.

=item header

List of table headers - one header per column

=item challenges

List of challenges to exercise

=item solutions

List of solutions of challenges

=item usepackages

List of additional package names to pass to \usepackage

=item headeritems

List of additional lines to put to document header

=back

=cut

has exercises => (
    is => "lazy",
    # requires _build_exercises
);

=head2 output_name

Lazy string representing the basename without extension of the output
file. The default builder returns the names of all commands in chain
joined with empty string.

=cut

has output_name => (
    is => "lazy",
);

sub _build_output_name
{
    join( "", map { $_->command_name || "" } @{ $_[0]->command_chain } );
}

=head2 output_type

Lazy string representing the extension of the output file. The default
builder returns 'pdf'. Permitted to be set via MooX::Options.

=cut

option output_type => (
    is     => "lazy",
    doc    => "Specifies the output type (tex, pdf, ps)",
    format => "s",
    short  => "t",
);

sub _build_output_type { 'pdf' }

=head2 output_location

Lazy string representing the location of the output file in file system. The
default builder returns the full qualified path name to the current working
directory. Permitted to be set via MooX::Options.

=cut

option output_location => (
    is     => "lazy",
    doc    => "Specifies the output location",
    format => "s",
    short  => "o",
);

sub _build_output_location { abs_path(getcwd) }

=head1 REQUIRED ATTRIBUTES

=head2 template_filename

The basename of the template file for processing to get the exercises.

=cut

requires "template_filename";

sub execute
{
    my $self = shift;

    my $exercises = $self->exercises;

    my $sharedir = File::ShareDir::dist_dir("App-Math-Tutor");
    my $ttcpath = File::Spec->catfile( $sharedir, $self->template_filename . ".tt2" );

    my $template = Template->new(
        {
            ABSOLUTE => 1,
        }
    );
    my $rc = $template->process(
        $ttcpath,
        {
            exercises => $exercises,
            output    => {
                format => $self->output_type,
            },
        },
        File::Spec->catfile( $self->output_location, join( ".", $self->output_name, $self->output_type ) ),
    );
    $rc or croak( $template->error() );

    0;
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
