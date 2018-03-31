package Data::Record::Serialize::Sink::null;

# ABSTRACT: send output to nowhere.

use Moo::Role;

use namespace::clean;

our $VERSION = '0.15';

#pod =for Pod::Coverage
#pod  print
#pod  say
#pod  close
#pod
#pod =cut

sub print { }
sub say   { }
sub close { }


with 'Data::Record::Serialize::Role::Sink';

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

Data::Record::Serialize::Sink::null - send output to nowhere.

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( sink => 'null', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Sink::stream> sends data to the bitbucket.

It performs the L<Data::Record::Serialize::Role::Sink> role.

=for Pod::Coverage print
 say
 close

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
