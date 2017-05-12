package Class::DBI::Loader::Oracle;

use warnings;
use strict;
use DBI;
use Carp;
require Class::DBI::Oracle;
use base 'Class::DBI::Loader::Generic';
use vars '$VERSION';
$VERSION = '0.02';

sub _db_class { return 'Class::DBI::Oracle' }

sub _tables {
    my $self = shift;

    my $user = uc $self->{_datasource}->[1];
    # handle user strings of the form user@sid or user/password@sid
    # we want only the user (schema) name
    $user =~ s/^(\w+)[@\/]?.*$/$1/;

    my $dbh = DBI->connect(@{$self->{_datasource}}) or croak($DBI::errstr);
    my @tables;
    for my $table ( $dbh->tables(undef, $user, '%', 'TABLE') ) { #catalog, schema, table, type
        my $quoter = $dbh->get_info(29);
        $table =~ s/$quoter//g;

        # remove "user." (schema) prefixes
        $table =~ s/\w+\.//;

        $table = lc $table;
        push @tables, $1
          if $table =~ /\A(\w+)\z/;
    }
    $dbh->disconnect;
    return @tables;
}

=head1 NAME

Class::DBI::Loader::Oracle - Class::DBI::Loader Oracle Implementation.

=head1 SYNOPSIS

  use Class::DBI::Loader;

  # $loader is a Class::DBI::Loader::Oracle
  my $loader = Class::DBI::Loader->new(
    dsn       => $dsn,      # "dbi:Oracle:", "dbi:Oracle:DB", ...
    user      => $user,     # "user", "user@DB", "user/pass", ...
    password  => $password, # "pass", "", ...
    namespace => "Data",
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

=head1 DESCRIPTION

See L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>.

=head1 SEE ALSO

L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>

=head1 TODO

This module needs a new maintainer, because I no longer use L<Class::DBI> and
have no further interest in maintaining this module. And yes, this includes the
RT wishlist request for relationships support.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-dbi-loader-oracle@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-DBI-Loader-Oracle>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Special thanks to Frank Carnovale and Ian VanDerPoel for sharing their code, upon which this module is based. Thanks also to Jay Strauss, Johan Lindstrom and Dan Sully for their helpful comments.

=head1 AUTHOR

David Naughton, C<< <naughton@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2005 David Naughton, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Class::DBI::Loader::Oracle
