package App::TimeTracker::Constants;

# ABSTRACT: App::TimeTracker pre-defined constants
our $VERSION = '3.009'; # VERSION

use strict;
use warnings;
use 5.010;

use Exporter;
use parent qw(Exporter);

our @EXPORT      = qw();
our @EXPORT_OK   = qw(MISSING_PROJECT_HELP_MSG);

use constant MISSING_PROJECT_HELP_MSG =>
    "Could not find project; did you forget to run `tracker init`?\n" .
    "If not, use --project or chdir into the project directory.";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TimeTracker::Constants - App::TimeTracker pre-defined constants

=head1 VERSION

version 3.009

=head1 DESCRIPTION

Pre-defined constants used without the module's internals.

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
