package App::Env::Null;

use strict;
use warnings;

our $VERSION = '0.33';

=pod

=begin making_pod_coverage_shut_up

=item envs

=end making_pod_coverage_shut_up

=cut

sub envs { return \%ENV }

1;

__END__

=head1 NAME

App::Env::Null - snapshot of the current environment

=head1 SYNOPSIS

  use App::Env;

  my $env = App::Env->new( 'null', { Cache => 0 } );

=head1 DESCRIPTION

This module returns a snapshot of the current environment.  It must
not be used directly; see B<App::ENV>.  No B<AppOpts> options are
recognized.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 The Smithsonian Astrophysical Observatory

App::Env::Null is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>

