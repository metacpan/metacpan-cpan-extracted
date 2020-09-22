use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Schema;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0105';

use parent 'DBIx::Class::Schema';
use Carp qw/croak/;

use experimental qw/postderef signatures/;

our $dbix_class_smooth_methods_created = 0;

sub connection($self, @rest) {
    $self = $self->next::method(@rest);

    if(!$dbix_class_smooth_methods_created) {
        $self->_dbix_class_smooth_create_methods();
    }
    return $self;
}

sub _dbix_class_smooth_create_methods($self) {
    no strict 'refs';
    for my $source (sort $self->sources) {
        (my $method = $source) =~ s{::}{_}g;

        if($self->can($method)) {
            croak(caller(1) . " already has a method named <$method>.");
        }

        *{ caller(1) . "::$method" } = sub {
            my $rs = shift->resultset($source);

            return !scalar @_                  ? $rs
                 : defined $_[0] && !ref $_[0] ? $rs->find(@_)
                 : ref $_[0] eq 'ARRAY'        ? $rs->find(@$_[1..$#_], { key => $_->[0] })
                 :                               $rs->search(@_)
                 ;
        };
    }
    $dbix_class_smooth_methods_created = 1;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::Schema - Short intro

=head1 VERSION

Version 0.0105, released 2020-09-20.

=head1 SYNOPSIS

    # in MyApp::Schema, instead of inheriting from DBIx::Class::Schema
    use parent 'DBIx::Class::Smooth::Schema';

=head1 DESCRIPTION

DBIx::Class::Smooth::Schema adds method accessors for all resultsets.

In short, instead of this:

    my $schema = MyApp::Schema->connect(...);
    my $result = $schema->resultset('Author');

You can do this:

    my $schema = MyApp::Schema->connect(...);
    my $result = $schema->Author;

=head2 What is returned?

The resultset methods can be called in four different ways.

=head3 Without arguments

    # $schema->resultset('Author')
    $schema->Author;

=head3 With a scalar

    # $schema->resultset('Author')->find(5)
    $schema->Author(5);

=head3 With an array reference

    # $schema->resultset('Book')->find({ author => 'J.R.R Tolkien', title => 'The Hobbit' }, { key => 'book_author_title' });
    $schema->Book([book_author_title => { author => 'J.R.R Tolkien', title => 'The Hobbit' }]);

=head3 With anything else

    # $schema->resultset('Author')->search({ last_name => 'Tolkien'}, { order_by => { -asc => 'first_name' }});
    $schema->Author({ last_name => 'Tolkien'}, { order_by => { -asc => 'first_name' }});

=head1 SEE ALSO

=over 4

=item *

L<DBIx::Class::Smooth>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-DBIx-Class-Smooth>

=head1 HOMEPAGE

L<https://metacpan.org/release/DBIx-Class-Smooth>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
