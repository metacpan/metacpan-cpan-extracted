package Data::Record::Serialize::Sink::null;

# ABSTRACT: send output to nowhere.

use v5.12;
use Moo::Role;

use namespace::clean;

our $VERSION = '2.02';








## no critic( Subroutines::ProhibitBuiltinHomonyms )
## no critic( NamingConventions::ProhibitAmbiguousNames )

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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory bitbucket

=head1 NAME

Data::Record::Serialize::Sink::null - send output to nowhere.

=head1 VERSION

version 2.02

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( sink => 'null', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Sink::stream> sends data to the bitbucket.

It performs the L<Data::Record::Serialize::Role::Sink> role.

=head1 INTERNALS

=for Pod::Coverage print
 say
 close

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>

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
