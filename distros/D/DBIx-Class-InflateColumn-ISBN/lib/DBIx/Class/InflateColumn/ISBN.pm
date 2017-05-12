package DBIx::Class::InflateColumn::ISBN;

use warnings;
use strict;

our $VERSION = '0.04000';

use base qw/DBIx::Class/;
__PACKAGE__->mk_classdata('isbn_class');
__PACKAGE__->isbn_class('Business::ISBN');

=head1 NAME

DBIx::Class::InflateColumn::ISBN - Auto-create Business::ISBN objects from columns.

=head1 VERSION

Version 0.04000

=head1 SYNOPSIS

Load this component and declare columns as ISBNs with the appropriate format.

    package Library;
    __PACKAGE__->load_components(qw/InflateColumn::ISBN Core/);
    __PACKAGE__->add_columns(
        isbn => {
            data_type => 'varchar',
            size => 13,
            is_nullable => 0,
            is_isbn => 1,
            as_string => 0,
        }
    );

It has to be a varchar rather than a simple integer given that it is possible
for ISBNs to contain the character X. Old style ISBNs are 10 characters, not
including hyphens, but new style ones are 13 characters.

The C<as_string> attribute is optional, and if set to 1 then values will be
stored in the database with hyphens in the appopriate places. In this case, an
extra 3 characters will be required.

Then you can treat the specified column as a Business::ISBN object.

    print 'ISBN: ', $book->isbn->as_string;
    print 'Publisher code: ', $book->isbn->publisher_code;

=head1 METHODS

=head2 isbn_class

=over

=item Arguments: $class

=back

Gets/sets the address class that the columns should be inflated into.
The default class is Business::ISBN and only that is currently supported.

=head2 register_column

Chains with L<DBIx::Class::Row/register_column>, and sets up ISBN columns
appropriately. This would not normally be called directly by end users.

=cut

sub register_column {
    my ($self, $column, $info, @rest) = @_;
    $self->next::method($column, $info, @rest);

    return unless defined $info->{'is_isbn'};

    if ( $info->{'size'} && ($info->{'size'} < 10 ||
      ($info->{'as_string'} && $info->{'size'} < 13)) ) {
        $self->throw_exception("ISBN field datatype is too small");
    }
    $self->throw_exception("ISBN field datatype must not be integer")
        if ($info->{'data_type'} eq 'integer');

    my $isbn_class = $info->{'isbn_class'} || $self->isbn_class || 'Business::ISBN';

    eval "use $isbn_class";
    $self->throw_exception("Error loading $isbn_class: $@") if $@;

    $self->inflate_column(
        $column => {
            inflate => sub {
                return $isbn_class->new(sprintf("%010s", shift));
            },
            deflate => sub {
                $info->{'as_string'} ? shift->as_string : shift->isbn;
            },
        }
    );
}

=head1 AUTHOR

K. J. Cheetham C<< <jamie @ shadowcatsystems.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dbix-class-inflatecolumn-ISBN at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-InflateColumn-ISBN>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::InflateColumn::ISBN

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-InflateColumn-ISBN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-InflateColumn-ISBN>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-InflateColumn-ISBN>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-InflateColumn-ISBN>

=back

=head1 SEE ALSO

L<Business::ISBN>

L<DBIx::Class::InflateColumn>

L<WWW::Scraper::ISBN>

=head1 COPYRIGHT & LICENSE

Copyright 2007 K. J. Cheetham, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of DBIx::Class::InflateColumn::ISBN
