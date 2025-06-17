use utf8;
package CPAN::Testers::Schema::Result::PerlVersion;
our $VERSION = '0.028';
# ABSTRACT: Metadata about Perl versions

#pod =head1 SYNOPSIS
#pod
#pod     my $perl = $schema->resultset( 'PerlVersion' )->find( '5.26.0' );
#pod     say "Stable" unless $perl->devel;
#pod
#pod     $schema->resultset( 'PerlVersion' )->find_or_create({
#pod         version => '5.30.0',    # Version reported by Perl
#pod         perl => '5.30.0',       # Parsed Perl version string
#pod         patch => 0,             # Has patches applied
#pod         devel => 0,             # Is development version (odd minor version)
#pod     });
#pod
#pod     # Fill in metadata automatically
#pod     $schema->resultset( 'PerlVersion' )->find_or_create({
#pod         version => '5.31.0 patch 1231',
#pod         # devel will be set to 1
#pod         # patch will be set to 1
#pod         # perl will be set to 5.31.0
#pod     });
#pod
#pod =head1 DESCRIPTION
#pod
#pod This table holds metadata about known Perl versions. Through this table we can
#pod quickly list which Perl versions are stable/development.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<DBIx::Class::Row>, L<CPAN::Testers::Schema>
#pod
#pod =cut

use CPAN::Testers::Schema::Base 'Result';

table 'perl_version';

#pod =attr version
#pod
#pod The Perl version reported by the tester. This is the primary key.
#pod
#pod =cut

primary_column version => {
    data_type => 'varchar',
    size => 255,
    is_nullable => 0,
};

#pod =attr perl
#pod
#pod The parsed version of Perl in C<REVISION.VERSION.SUBVERSION> format.
#pod
#pod If not specified when creating a new row, the Perl version will be parsed
#pod and this field updated accordingly.
#pod
#pod =cut

column perl => {
    data_type => 'varchar',
    size => 32,
    is_nullable => 1,
};

#pod =attr patch
#pod
#pod If true (C<1>), this Perl has patches applied. Defaults to false (C<0>).
#pod
#pod If not specified when creating a new row, the Perl version will be parsed
#pod and this field updated accordingly.
#pod
#pod =cut

column patch => {
    data_type => 'tinyint',
    size => 1,
    default_value => 0,
};

#pod =attr devel
#pod
#pod If true (C<1>), this Perl is a development Perl version. Development Perl
#pod versions have an odd C<VERSION> field (the second number) like C<5.27.0>,
#pod C<5.29.0>, C<5.31.0>, etc... Release candidates (like C<5.28.0 RC0>) are
#pod also considered development versions.
#pod
#pod If not specified when creating a new row, the Perl version will be parsed
#pod and this field updated accordingly.
#pod
#pod =cut

column devel => {
    data_type => 'tinyint',
    size => 1,
    default_value => 0,
};

#pod =method new
#pod
#pod The constructor will automatically fill in any missing information based
#pod on the supplied C<version> field.
#pod
#pod =cut

sub new( $class, $attrs ) {
    if ( !$attrs->{perl} ) {
        ( $attrs->{perl} ) = $attrs->{version} =~ m{^v?(\d+\.\d+\.\d+)};
    }
    if ( !$attrs->{patch} ) {
        $attrs->{patch} = ( $attrs->{version} =~ m{patch} ) ? 1 : 0;
    }
    if ( !$attrs->{devel} ) {
        my ( $version ) = $attrs->{version} =~ m{^v?\d+\.(\d+)};
        $attrs->{devel} =
            (
                ( $version >= 7 && $version % 2 ) ||
                $attrs->{version} =~ m{^v?\d+\.\d+\.\d+ RC\d+}
            ) ? 1 : 0;
    }
    return $class->next::method( $attrs );
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Schema::Result::PerlVersion - Metadata about Perl versions

=head1 VERSION

version 0.028

=head1 SYNOPSIS

    my $perl = $schema->resultset( 'PerlVersion' )->find( '5.26.0' );
    say "Stable" unless $perl->devel;

    $schema->resultset( 'PerlVersion' )->find_or_create({
        version => '5.30.0',    # Version reported by Perl
        perl => '5.30.0',       # Parsed Perl version string
        patch => 0,             # Has patches applied
        devel => 0,             # Is development version (odd minor version)
    });

    # Fill in metadata automatically
    $schema->resultset( 'PerlVersion' )->find_or_create({
        version => '5.31.0 patch 1231',
        # devel will be set to 1
        # patch will be set to 1
        # perl will be set to 5.31.0
    });

=head1 DESCRIPTION

This table holds metadata about known Perl versions. Through this table we can
quickly list which Perl versions are stable/development.

=head1 ATTRIBUTES

=head2 version

The Perl version reported by the tester. This is the primary key.

=head2 perl

The parsed version of Perl in C<REVISION.VERSION.SUBVERSION> format.

If not specified when creating a new row, the Perl version will be parsed
and this field updated accordingly.

=head2 patch

If true (C<1>), this Perl has patches applied. Defaults to false (C<0>).

If not specified when creating a new row, the Perl version will be parsed
and this field updated accordingly.

=head2 devel

If true (C<1>), this Perl is a development Perl version. Development Perl
versions have an odd C<VERSION> field (the second number) like C<5.27.0>,
C<5.29.0>, C<5.31.0>, etc... Release candidates (like C<5.28.0 RC0>) are
also considered development versions.

If not specified when creating a new row, the Perl version will be parsed
and this field updated accordingly.

=head1 METHODS

=head2 new

The constructor will automatically fill in any missing information based
on the supplied C<version> field.

=head1 SEE ALSO

L<DBIx::Class::Row>, L<CPAN::Testers::Schema>

=head1 AUTHORS

=over 4

=item *

Oriol Soriano <oriolsoriano@gmail.com>

=item *

Doug Bell <preaction@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Oriol Soriano, Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
