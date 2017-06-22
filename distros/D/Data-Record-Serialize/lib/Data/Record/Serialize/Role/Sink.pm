package Data::Record::Serialize::Role::Sink;

# ABSTRACT: Sink Role

use Moo::Role;

use namespace::clean;

our $VERSION = '0.12';

requires 'print';
requires 'say';
requires 'close';

1;

=pod

=head1 NAME

Data::Record::Serialize::Role::Sink - Sink Role

=head1 VERSION

version 0.12

=head1 DESCRIPTION

If a role consumes this, it signals that it provides sink
capabilities.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>.

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

__END__

#pod =head1 DESCRIPTION
#pod
#pod If a role consumes this, it signals that it provides sink
#pod capabilities.
