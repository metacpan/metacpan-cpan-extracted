package App::Project::Doctor::Check::Role;

# ---------------------------------------------------------------------------
# Backward-compatibility shim.
#
# This file used to define a Moose-style role interface for check plugins.
# The role model was replaced with a simpler traditional OO base class
# (App::Project::Doctor::Check::Base).  This shim is kept so that any
# external code that loaded Check::Role by name continues to work.
# ---------------------------------------------------------------------------

# Enforce strict variable scoping to catch typos at compile time.
use strict;
# Emit runtime warnings for common mistakes (undef in string, etc.).
use warnings;
# Make all built-in I/O functions throw exceptions instead of returning errors.
use autodie qw(:all);

# Inherit everything from Check::Base.  The -norequire flag tells 'parent'
# NOT to automatically 'require' Check::Base; we do that ourselves in Doctor.pm
# before calling ->new on any check plugin.
use parent -norequire, 'App::Project::Doctor::Check::Base';

# Module version used by CPAN and 'use Module 0.02' guards.
our $VERSION = '0.02';

# Return true so Perl knows this file loaded without errors.
1;

__END__

=head1 NAME

App::Project::Doctor::Check::Role - Deprecated shim; use Check::Base instead

=head1 DESCRIPTION

Inherits from L<App::Project::Doctor::Check::Base>.  Present for backward
compatibility only.  New code should C<use parent 'App::Project::Doctor::Check::Base'>.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
