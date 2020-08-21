package App::mkpkgconfig::PkgConfig::Entry;
use strict;
use warnings;

# ABSTRACT: Base class for PkgConfig Keywords and Variables

use Syntax::Construct qw( non-destructive-subst );

our $VERSION = 'v2.0.0';

use Regexp::Common 'balanced';









sub new {
    my ( $class, $name, $value ) = @_;

    bless { name => $name,
            value => $value,
            depends => _parse_dependencies( $value ),
            }, $class;
}







sub name            { return $_[0]->{name} }







sub value           { return $_[0]->{value} }









sub depends         { return @{ $_[0]->{depends} } }

sub _parse_dependencies {
    my @depends =
            map { s/(?:^[{])|(?:[}]$)//gr }
            $_[0] =~ /(?<!\$)\$$RE{balanced}{-parens => '{}'}/g;

    my %depends;
    @depends{@depends} = ();

    return [ keys %depends ];
}

package App::mkpkgconfig::PkgConfig::Entry::Variable;

use parent -norequire => 'App::mkpkgconfig::PkgConfig::Entry';

package App::mkpkgconfig::PkgConfig::Entry::Keyword;

use parent -norequire => 'App::mkpkgconfig::PkgConfig::Entry';

1;

#
# This file is part of App-mkpkgconfig
#
# This software is Copyright (c) 2020 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

App::mkpkgconfig::PkgConfig::Entry - Base class for PkgConfig Keywords and Variables

=head1 VERSION

version v2.0.0

=head1 DESCRIPTION

B<PkgConfig::Entry> is the base class for C<PkgConfig> variables and keywords.

Don't instantiate this class; instead, instantiate C<PkgConfig::Entry::Variable> and
instantiate C<PkgConfig::Entry::Keyword>.  They have the same API as C<PkgConfig::Entry>

=head1 ATTRIBUTES

=head2 name

The entry's name.

=head2 value

The entry's value.

=head1 METHODS

=head2 new

  $pkg = App::mkpkgconfig::PkgConfig::Entry->new( $name, $value );

Create a new PkgConfig::Entry object.

=head2 depends

  @depends = $entry->depends;

Returns a list of the names of the variables that the entry depends upon.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-app-mkpkgconfig@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=App-mkpkgconfig

=head2 Source

Source is available at

  https://gitlab.com/djerius/app-mkpkgconfig

and may be cloned from

  https://gitlab.com/djerius/app-mkpkgconfig.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<script::mkpkgconfig|script::mkpkgconfig>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
