package Dancer2::UserAdmin;

our $VERSION = '0.9902';

use Moo;

1; # return true

__END__

=pod

=head1 VERSION

version 0.9902

=head1 NAME

Dancer2::UserAdmin - Administration for registered users and site memberships

=head1 DESCRIPTION

This package provides user administration for your Dancer2 app. Create and
manage users, grant user roles, add time-limited renewable memberships to
the site, and use those properties for content access, communications, etc.

The user object is available throughout your application code, and the user's
memberships (if you have implemented that feature) are available as sub-objects.
The package makes use of C<DBIx::Class> to create the objects from your database.

You can choose to use only the Users administration plugin, or both. The
Memberships plugin cannot be used without the Users plugin.

=head1 CONFIGURATION

=head1 AUTHOR

Nick Tonkin <tonkin@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Nick Tonkin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
