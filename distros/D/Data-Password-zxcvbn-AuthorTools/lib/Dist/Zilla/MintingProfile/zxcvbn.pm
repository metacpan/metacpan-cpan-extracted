package Dist::Zilla::MintingProfile::zxcvbn;
use Moose;
with 'Dist::Zilla::Role::MintingProfile';

use File::ShareDir::Tarball 'dist_dir';
use Path::Tiny;

use namespace::autoclean;
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: dzil minting profile for zxcvbn distributions

sub profile_dir {
    my ($self, $profile_name) = @_;

    my $dist_dir = eval { dist_dir('Data-Password-zxcvbn-AuthorTools') } || path(__FILE__)->parent(5)->child('share');
    my $profile_dir = path( $dist_dir )->child( 'minting-profiles', $profile_name );

    return $profile_dir if -d $profile_dir;

    confess "Can't find profile $profile_name via $self (checked '$profile_dir')";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::zxcvbn - dzil minting profile for zxcvbn distributions

=head1 VERSION

version 1.0.2

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
