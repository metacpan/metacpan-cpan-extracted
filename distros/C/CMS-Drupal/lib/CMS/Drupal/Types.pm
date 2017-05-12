package CMS::Drupal::Types;
$CMS::Drupal::Types::VERSION = '0.94';
# ABSTRACT: A Perl type library for working with Drupal

use strict;
use warnings;

use Type::Library -base, -declare => qw/ DBName
                                         DBDriver
                                         DBUsername
                                         DBPassword
                                         DBHost
                                         DBPort
                                         DBPrefix /;
use Type::Utils qw/ :all /;
use Types::Standard qw/ Optional Maybe Str StrMatch Int slurpy Dict /;

declare DBName, as Str, where { length > 0 },
  message { 'You must supply the database name. ' };

declare DBDriver, as StrMatch[ qr{ ^(mysql|Pg|SQLite)$ }x ],
  message { 'You must supply the name of a valid installed dbi:dbd driver (mysql, Pg, or SQLite). ' };

declare DBUsername, as Optional[Str],
  message { 'The username must be a string. ' };

declare DBPassword, as Optional[Str],
  message { 'The password must be a string. ' };

declare DBHost, as Optional[Str],
  message { 'The hostname must be a string. ' };

declare DBPort, as Optional[Int],
  message { 'The port number must be an integer. ' };

declare DBPrefix, as Optional[Str],
  message { return 'The table prefix must be a string. ' };

1; ## return true to end package CMS::Drupal::Types

__END__

=pod

=encoding UTF-8

=head1 NAME

CMS::Drupal::Types - A Perl type library for working with Drupal

=head1 VERSION

version 0.94

=head1 SYNOPSIS

  use Types::Standard;
  use CMS::Drupal::Types qw/ :all /;

=head1 USAGE

You can use this module to import Type::Tiny-style types relevant to Drupal
into your program. Use the syntax shown above and the types will be available
as object attributes.

If you want to use the types to validate parameters passed to a method or a sub, use the following syntax as an example:

  use CMS::Drupal::Types qw/ DBName DBDriver DBUsername DBPassword /;
  use Types::Standard    qw/ Optional Maybe Str StrMatch Int slurpy Dict /;
  use Type::Params       qw/ compile /;

  sub my_sub {
    my $args = { @_ };
    my %types = (
      'database' => DBName,
      'driver'   => DBDriver,
      'username' => DBUsername,
      'password' => DBPassword,
    );
   
    for( keys %$args ) {
      my $validate = compile( slurpy Dict [ $_ => $types{$_} ]);
      my ($param) = $validate->( $_ => $args->{$_} );
      print "$_: '$args->{$_}' passed";
    }
  }

=head2 TYPES

B<DBName>
 Must be a non-empty string.

B<DBDriver>
 Must be one of 'mysql', 'Pg', or 'SQLite'.

B<DBUsername>
 Must be a string if present. May be empty. May be omitted.

B<DBPassword>
 Must be a string if present. May be empty. May be omitted.

B<DBHost>
 Must be a string if present. May be empty. May be omitted.

B<DBPort>
 Must be an integer if present. May be empty. May be omitted.

B<DBPrefix>
 Must be a non-empty string if present. May be omitted.

=head1 SEE ALSO

=over 4

=item *

L<CMS::Drupal|CMS::Drupal>

=item *

L<Type::Tiny|Type::Tiny>

=item *

L<Type::Library|Type::Library>

=item *

L<Types::Standard|Types::Standard>

=item *

L<Type::Params|Type::Params>

=back

=head1 AUTHOR

Nick Tonkin <tonkin@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nick Tonkin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
