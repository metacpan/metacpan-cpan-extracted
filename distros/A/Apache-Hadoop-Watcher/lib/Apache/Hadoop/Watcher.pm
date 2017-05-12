#
# (C) 2015, Snehasis Sinha
#
package Apache::Hadoop::Watcher;

use 5.010001;
use strict;
use warnings;

use Apache::Hadoop::Watcher::Base;
use Apache::Hadoop::Watcher::Conf;
use Apache::Hadoop::Watcher::Jmx;
use Apache::Hadoop::Watcher::Yarn;

our @ISA = qw();
our $VERSION = '0.01';

1;

__END__

=head1 NAME

Apache::Hadoop::Watcher - Perl extension for Hadoop Monitoring

=head1 SYNOPSIS

  use Apache::Hadoop::Watcher;
  
=head1 DESCRIPTION

This is the envelop package for Hadoop configuration manager
and monitoring. The monitors need be implemented and thresholded
based on these packages.

=head1 SEE ALSO

  Apache::Hadoop::Watcher::Base
  Apache::Hadoop::Watcher::Conf
  Apache::Hadoop::Watcher::Jmx
  Apache::Hadoop::Watcher::Yarn

=head1 AUTHOR

Snehasis Sinha, E<lt>snehasis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Snehasis Sinha

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
