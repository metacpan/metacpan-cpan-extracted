package App::Env::Null;

# ABSTRACT: return a snapshot of the current environment

use strict;
use warnings;

our $VERSION = '1.02';











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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

App::Env::Null - return a snapshot of the current environment

=head1 VERSION

version 1.02

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

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-app-env@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=App-Env

=head2 Source

Source is available at

  https://gitlab.com/djerius/App-Env

and may be cloned from

  https://gitlab.com/djerius/App-Env.git

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
