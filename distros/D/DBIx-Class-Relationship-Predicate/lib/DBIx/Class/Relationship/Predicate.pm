package DBIx::Class::Relationship::Predicate;

use warnings;
use strict;
use parent 'DBIx::Class';
use Sub::Name ();

our $VERSION = '0.07'; # VERSION

# ABSTRACT: Predicates for relationship accessors


sub register_relationship {
    my ($class, $rel, $info) = @_;
    my $attrs = $info->{'attrs'};
    if (my $acc_type = $attrs->{'accessor'}) {
        if ( defined($attrs->{'predicate'}) || !exists($attrs->{'predicate'}) ) {
            $class->add_relationship_predicate(
                $rel, $acc_type, $attrs->{'predicate'}
            );
        }
    }
    $class->next::method($rel, $info);
}

sub add_relationship_predicate {
    my ( $class, $relname, $accessor_type, $predicate ) = @_;
    $predicate ||= "has_${relname}";
    my $name = join '::', $class, $predicate;

    my $predicate_meth;
    if ( $accessor_type =~ m{single|filter}i ) {
        $predicate_meth = Sub::Name::subname($name, sub {
            return defined(shift->$relname);
        });
    } elsif ( $accessor_type eq 'multi' ) {
        $predicate_meth = Sub::Name::subname($name, sub {
            return shift->$relname->count;
        });
    }

    {
        no strict 'refs';
        no warnings 'redefine';
        *$name = $predicate_meth;
    }
}


1;

__END__

=pod

=head1 NAME

DBIx::Class::Relationship::Predicate - Predicates for relationship accessors

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    package My::Schema::Result::Foo;

    __PACKAGE__->load_components(qw( Relationship::Predicate ... Core ));

    ...

    __PACKAGE__->belongs_to('baz' => 'My::Schema::Result::Baz',  'baz_id');

    __PACKAGE__->might_have(
        'buzz' => 'My::Schema::Result::Buzz',
        { 'foreign.foo_id' => 'self.id' },
        { 'predicate' => 'got_a_buzz' },
    );

    __PACKAGE__->has_many(
        'foo_baz' => 'My::Schema::Result::FooBaz',
        { 'foreign.foo_id' => 'self.id' },
        { 'predicate' => undef },
    );

    __PACKAGE__->has_many('bars' => 'My::Schema::Result::Bar', 'foo_id');

    1;

=head1 DESCRIPTION

L<DBIx::Class> component to automatically create predicates for relationship accessors in a result class.
By default, it creates C<"has_${rel_accessor_name}"> methods and injects into the class,
thus for that case we would have 'has_baz', 'has_buzz' and 'has_bars' methods on C<$foo> row object. You can
define the name for each one (or also disable its creation using C<undef> as value) by setting 'predicate'
key in the relationship's attrs hashref.

   __PACKAGEE_->might_have(
       'buzz' => 'My::Schema::Result::Buzz', 'foo_id',
       { 'predicate' => 'got_a_buzz' }
   );

   or

   __PACKAGEE_->might_have(
       'buzz' => 'My::Schema::Result::Buzz', 'foo_id',
       { 'predicate' => undef }
   );

=head1 AUTHOR

Wallace Reis, C<< <wreis at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-relationship-predicate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Relationship-Predicate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Relationship::Predicate

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Relationship-Predicate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-Relationship-Predicate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Relationship-Predicate>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-Relationship-Predicate/>

=back

=head1 COPYRIGHT

Copyright 2009 Wallace Reis.

=head1 LICENSE

This library is free software and may be distributed under the same terms as perl itself.

=head1 AUTHOR

Wallace Reis <wreis@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Wallace Reis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
