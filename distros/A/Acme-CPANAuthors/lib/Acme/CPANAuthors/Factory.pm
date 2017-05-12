package Acme::CPANAuthors::Factory;

use strict;
use warnings;
use Acme::CPANAuthors;

sub create {
  my ($class, %data) = @_;

  my @categories = keys %data;
  my %authors = map { %{ $data{$_} } } @categories;

  return bless {
    categories => \@categories,
    authors => \%authors,
  }, 'Acme::CPANAuthors';
}

1;
__END__

=head1 NAME

Acme::CPANAuthors::Factory

=head1 SYNOPSIS

    use Acme::CPANAuthors::Factory;

    my $authors = Acme::CPANAuthors::Factory->create(
        Purple => {
            ETHER => 'Karen Etheridge',
            ISHIGAKI => 'Kenichi Ishigaki',
        },
    );
    my $number = $authors->count;
    # and all other methods described in Acme::CPANAuthors...

=head1 DESCRIPTION

Use this class when you have a list of authors that you want to manipulate,
but you only have the list of names at runtime (where
L<Acme::CPANAuthors::Register> is not very convenient).

An L<Acme::CPANAuthors> object will be created for you, containing the same
data as if you had registered a new class at compile time.

However, you cannot call C<< Acme::CPANAuthors->new >> with your category and
get back a new object; it still only knows about modules on disk.

=head1 METHOD

=head2 create

takes a hash reference to create an Acme::CPANAuthors object.

=head1 AUTHOR

This class was written by Karen Etheridge (ether), E<lt>ether at cpan.orgE<gt>

L<Acme::CPANAuthors> is by Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2012 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
