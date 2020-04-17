package Data::Record::Serialize::Role::Sink;

# ABSTRACT: Sink Role

use Moo::Role;

use namespace::clean;

our $VERSION = '0.20';

requires 'print';
requires 'say';

#pod =method B<close>
#pod
#pod   $s->close;
#pod
#pod Flush any data written to the sink and close it.  While this will be
#pod performed automatically when the object is destroyed, if the object is
#pod not destroyed prior to global destruction at the end of the program,
#pod it is quite possible that it will not be possible to perform this
#pod cleanly.  In other words, make sure that sinks are closed prior to
#pod global destruction.
#pod
#pod
#pod =cut

requires 'close';

1;

#
# This file is part of Data-Record-Serialize
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=head1 NAME

Data::Record::Serialize::Role::Sink - Sink Role

=head1 VERSION

version 0.20

=head1 DESCRIPTION

If a role consumes this, it signals that it provides sink
capabilities.

=head1 METHODS

=head2 B<close>

  $s->close;

Flush any data written to the sink and close it.  While this will be
performed automatically when the object is destroyed, if the object is
not destroyed prior to global destruction at the end of the program,
it is quite possible that it will not be possible to perform this
cleanly.  In other words, make sure that sinks are closed prior to
global destruction.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize

=head2 Source

Source is available at

  https://gitlab.com/djerius/data-record-serialize

and may be cloned from

  https://gitlab.com/djerius/data-record-serialize.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Data::Record::Serialize|Data::Record::Serialize>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
