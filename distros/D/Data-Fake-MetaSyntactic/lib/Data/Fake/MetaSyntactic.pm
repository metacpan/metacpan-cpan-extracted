package Data::Fake::MetaSyntactic;
$Data::Fake::MetaSyntactic::VERSION = '1.001';
use strict;
use warnings;
use Exporter 5.57 qw( import );

our @EXPORT = qw( fake_meta fake_metatheme fake_metacategory );

use Acme::MetaSyntactic ();
my @themes = grep $_ ne 'any', Acme::MetaSyntactic->themes;

sub fake_meta {
    my ($theme) = @_;
    $theme ||= fake_metatheme()->();

    my $meta = Acme::MetaSyntactic->new;
    return sub {
        $meta->name( ref $theme eq 'CODE' ? $theme->() : $theme );
    };
}

sub fake_metatheme {
    return sub { $themes[ rand @themes ] };
}

sub fake_metacategory {
    my ($theme) = @_;
    $theme ||= fake_metatheme()->();

    return ref $theme eq 'CODE'
        ? sub {
            my @categories = _categories( $theme->() );
            $categories[ rand @categories ];
        }
        : do {
            my @categories = _categories($theme);
            sub { $categories[ rand @categories ] };
        };
}

sub _categories {
    my ($theme) = @_;
    require "Acme/MetaSyntactic/$theme.pm";
    return (
        $theme => map "$theme/$_",
        eval { "Acme::MetaSyntactic::$theme"->categories }
    );
}

1;

__END__

=head1 NAME

Data::Fake::MetaSyntactic - Fake metasyntactic data generators
 
=head1 SYNOPSIS
 
    use Data::Fake::MetaSyntactic;

    fake_metatheme()->();       # foo,    donmartin,  weekdays,    etc.
    fake_metacategory()->();    # foo/fr, donmartin,  weekdays/nl, etc.
    fake_meta()->();            # titi,   GING_GOYNG, vrijdag,     etc.

=head1 DESCRIPTION
 
This module provides fake data generators for L<Acme::MetaSyntactic>.
 
All functions are exported by default.
 
=head1 FUNCTIONS
 
=head2 fake_meta
 
    $generator = fake_name( $theme );
 
Returns a generator that provides a randomly selected item from the
given L<Acme::MetaSyntactic> theme.

The theme name can be given in the form C<theme/category> if the correspnding
L<Acme::MetaSyntactic> theme supports categories.

C<$theme> can be a code reference that returns a theme name when executed.

If no C<$theme> is given, a random theme is picked for the generator
among the installed ones.

=head2 fake_metatheme
 
    $generator = fake_metatheme();
 
Returns a generator that provides a random L<Acme::MetaSyntactic> theme name,
among the installed ones.

=head2 fake_metacategory

    $generator = fake_metacategory( $theme );

Returns a generator that provides a random category from an installed
L<Acme::MetaSyntactic> theme. The theme itself is a category of its own.
The categories returned by the generator can be passed to L</fake_meta>.

C<$theme> can be a code reference that returns a theme name when executed.

If no C<$theme> is given, a random theme is picked for the generator
among the installed ones.

=head1 EXAMPLES

=over 4

=item *

Generate a random item from a given theme:

    $generator = fake_meta( $theme );

=item *

Generate a random item from a randomly selected theme:

    $generator = fake_meta();

=item *

Generate a random item from a different random theme each time:

    $generator = fake_meta( fake_metatheme() );

All themes have a default category. Since C<fake_metatheme()> returns
a generator that only produces theme names, that implies the default
category is always used in that case.

=item *

Generate a random item from a random category from a given theme:

    $generator = fake_meta( fake_metacategory( $theme ) );

=item *

Generate a random item from a randomly selected theme, with
a random category each time:

    $generator = fake_meta( fake_metacategory() );

=item *

Generate a random item from a different random theme/category each time:

    $generator = fake_meta( fake_metacategory( fake_metatheme() ) );

=back

=head1 TRIVIA

IRC is one my source of inspiration (actually, the people on it).
It seems L<Acme::MetaSyntactic> also inspires sillyness in people:

    #perl-qa on 2015-02-03 (UTC times)
    04:23 <@xdg> BooK, I invite you to read this talk I gave and then contribute Data::Fake::MetaSyntactic.  :-) http://tinyurl.com/pd5agr6 [ http://www.dagolden.com/wp-content/uploads/2009/04/Taking-Your-Perl-to-Eleven.pdf ]
    07:14 <@BooK> xdg: but I did Data::Faker::MetaSyntactic already!?
    07:35 <@BooK> ooh, different module
    08:03 <@BooK> xdg: I love it. will make the module

=head1 SEE ALSO

L<Data::Fake>, L<Acme::MetaSyntactic>, L<Task::MetaSyntactic>.

=head1 AUTHOR
 
Philippe Bruhat (BooK), <book@cpan.org>.
 
=head1 COPYRIGHT

Copyright 2015 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
