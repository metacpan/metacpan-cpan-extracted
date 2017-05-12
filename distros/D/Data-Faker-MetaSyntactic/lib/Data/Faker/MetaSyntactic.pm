package Data::Faker::MetaSyntactic;
$Data::Faker::MetaSyntactic::VERSION = '1.000';
use strict;
use warnings;

use Data::Faker;
our @ISA = qw( Data::Faker );

use Acme::MetaSyntactic ();

my $meta = Acme::MetaSyntactic->new('any');

# register default plugin
__PACKAGE__->register_plugin( meta => sub { $meta->name() } );

# record one plugin per existing theme
for my $theme ( $meta->themes ) {
    __PACKAGE__->register_plugin(
        "meta_$theme" => sub { $meta->name($theme) } );
}

1;

__END__

=head1 NAME

Data::Faker::MetaSyntactic - Data::Faker plugin for metasyntactic data

=head1 SYNOPSIS

    use Data::Faker 'MetaSyntactic';

    my $faker = Data::Faker->new();

    # using themes from Acme-MetatSyntactic-Themes
    say "First name        ", ucfirst $faker->meta_crypto;
    say "Favorite colour:  ", $faker->meta_colours;
    say "Favorite flavour: ", $faker->meta_ben_and_jerry;
    say "Random stuff:     ", join " ", map $faker->meta, 1 .. 4;

=head1 DESCRIPTION

L<Data::Faker> I<creates fake (but reasonable) data that can be used for things
such as filling databases with fake information during development of
database related applications.>

This module is a plugin that taps into the data provided by L<Acme::MetaSyntactic>.

See L<Data::Faker> for details.

=head1 DATA PROVIDERS

Each and every installed L<Acme::MetaSyntactic> theme can be a data
provider. If theme name is C<$theme>, the corresponding  data provider
is named C<meta_I<$theme>>.

For example, data from theme C<foo> will be provided via C<meta_foo>.

The C<meta> provider is a synonym for C<meta_any>, which gets data from
a random theme.

=head1 SEE ALSO

L<Data::Faker>,
L<Acme::MetaSyntactic>,
L<Task::MetaSyntactic>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2014 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
