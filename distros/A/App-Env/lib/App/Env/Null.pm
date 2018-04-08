package App::Env::Null;

# ABSTRACT: return a snapshot of the current environment

use strict;
use warnings;

our $VERSION = '0.34';

#pod =pod
#pod
#pod =begin making_pod_coverage_shut_up
#pod
#pod =item envs
#pod
#pod =end making_pod_coverage_shut_up
#pod
#pod =cut

sub envs { return \%ENV }

1;

#
# This file is part of App-Env
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=head1 NAME

App::Env::Null - return a snapshot of the current environment

=head1 VERSION

version 0.34

=head1 SYNOPSIS

  use App::Env;

  my $env = App::Env->new( 'null', { Cache => 0 } );

=head1 DESCRIPTION

This module returns a snapshot of the current environment.  It must
not be used directly; see B<App::ENV>.  No B<AppOpts> options are
recognized.

=begin making_pod_coverage_shut_up

=item envs

=end making_pod_coverage_shut_up

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Env> or by email to
L<bug-App-Env@rt.cpan.org|mailto:bug-App-Env@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/app-env>
and may be cloned from L<git://github.com/djerius/app-env.git>

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<App::Env|App::Env>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
