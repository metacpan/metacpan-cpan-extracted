package Bigtop::ScriptHelp::Style;
use strict; use warnings;

use File::Spec;

sub get_style {
    my $class = shift;
    my $style = shift || 'Kickstart';

    my $style_module_file = File::Spec->catfile(
        'Bigtop', 'ScriptHelp', 'Style', "$style.pm"
    );

    require $style_module_file;

    my $style_package = 'Bigtop::ScriptHelp::Style::' . $style;

    return $style_package->new();
}

sub new {
    my $class = shift;

    return bless {}, $class;
}

1;

=head1 NAME

Bigtop::ScriptHelp::Style - Factory for scripts' command line and standard in handlers

=head1 SYNOPSIS

    use Bigtop::ScriptHelp;
    use Bigtop::ScriptHelp::Style;

    my $style = ...

    my $style_helper = Bigtop::ScriptHelp::Style->get_style( $style );

    # pass this style as the first parameter to
    #   Bigtop::ScriptHelp->get_big_default
    #   Bigtop::ScriptHelp->augment_tree

=head1 DESCRIPTION

This module factors command line argument and standard in handling out of
scripts and ScriptHelp.  It is a simple factory.  Call C<get_style>
with the name of a style module, to receive a style suitable for passing
to C<<Bigtop::ScriptHelp->get_big_default>> and
C<<Bigtop::ScriptHelp->augment_tree>>.  All styles live in the
Bigtop::ScriptHelp::Style:: namespace.  The default style is 'Kickstart'.

Each stye must implement C<get_db_layout> which is the only method called by
C<Bigtop::ScriptHelp> methods.  See below for what it receives and returns.

=head1 METHODS

=over 4

=item get_style

Factory method.

Parameter: style name.  This must be the name of a module in the
Bigtop::ScriptHelp::Style:: namespace.

Returns: and object of the named style which responds to C<get_db_layout>.

=item new

Trivial constructor used internally to make an object solely to provide
dispatching to C<get_db_layout>.  All Styles should subclass from this
class, but they are welcome to override or augment C<new>.

=back

=head1 SUBCLASS METHODS

All subclasses should live in the Bigtop::ScriptHelp::Style:: namespace
and implement one method:

=over 4

=item get_db_layout

Parameters:

=over 4

=item invocant

usually useless

=item art

all command line args joined by spaces.  Note that flags should have already
been consumed by some script.

=item tables

a hash reference keyed by existing table name, the values are always 1

=back

Returns: a single hash reference with these keys:

=over 4

=item all_tables

the tables hash from the passed in parameters with an extra key for each
new table

=item new_tables

an array reference of new tables names

=item joiners

( Optional )

an array reference of new three way join tables

=item foreigners

( Optional )

a hash reference keyed by table name storing an array reference of
the table's new foreign keys

=back

=back

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
