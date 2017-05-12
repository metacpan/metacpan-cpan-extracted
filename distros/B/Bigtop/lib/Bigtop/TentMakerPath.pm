package Bigtop::TentMakerPath;
use strict;

sub get_template_path {
    return '/usr/local/share/TentMaker';
}

1;

=head1 NAME

Bigtop::TentMakerPath - keeps track of where the tentmaker templates live

=head1 SYNOPSIS

In tentmaker:

    use Bigtop::TentMakerPath;

    my $tent_path = Bigtop::TentMakerPath->get_template_path();

=head1 DESCRIPTION

Duing initial perl Build.PL, the user is asked to supply a path for
tentmaker's templates.  If they do that, this module is written and
later installed, to keep track of where the user wanted the templates.
Then, tentmaker can call get_template_path to find out where they are.

=head1 METHODS

=over 4

=item get_template_path

Returns the path, specified by the installing user, to the tentmaker templates.

=back

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
