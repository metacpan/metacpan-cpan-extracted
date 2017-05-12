#
# This file is part of App-KeePass2
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package App::KeePass2::Icons;

# ABSTRACT: Built in icon pack from app KeePass2
use strict;
use warnings;

our $VERSION = '0.04';    # VERSION
use utf8::all;
use Moo::Role;

has '_icons' => ( is => 'lazy', );

has '_icon_id_to_key' => ( is => 'lazy', );

sub _build__icons {
    return {
        key         => { id => 0,  utf8 => "🔑" },
        internet    => { id => 1,  utf8 => "🌍" },
        warning     => { id => 2,  utf8 => "🚧" },
        network     => { id => 3,  utf8 => "💻" },
        note        => { id => 4,  utf8 => "📝" },
        talk        => { id => 5,  utf8 => "💬" },
        cube        => { id => 6,  utf8 => "⬜" },
        note2       => { id => 7,  utf8 => "📄" },
        internet2   => { id => 8,  utf8 => "🌎" },
        card        => { id => 9,  utf8 => "💳" },
        note3       => { id => 10, utf8 => "📄" },
        camera      => { id => 11, utf8 => "📷" },
        wifi        => { id => 12, utf8 => "📡" },
        key2        => { id => 13, utf8 => "🔐" },
        wire        => { id => 14, utf8 => "🔌" },
        scan        => { id => 15, utf8 => "📇" },
        internet3   => { id => 16, utf8 => "🌏" },
        disk        => { id => 17, utf8 => "💿" },
        computer    => { id => 18, utf8 => "💻" },
        email       => { id => 19, utf8 => "📨" },
        setting     => { id => 20, utf8 => "🔧" },
        note4       => { id => 21, utf8 => "📃" },
        server      => { id => 22, utf8 => "💻" },
        screen      => { id => 23, utf8 => "💻" },
        wire2       => { id => 24, utf8 => "⚡" },
        email2      => { id => 25, utf8 => "📨" },
        disk2       => { id => 26, utf8 => "💾" },
        network2    => { id => 27, utf8 => "💻" },
        video       => { id => 28, utf8 => "📹" },
        key3        => { id => 29, utf8 => "🔐" },
        terminal    => { id => 30, utf8 => "📺" },
        printer     => { id => 31, utf8 => "📠" },
        cube2       => { id => 32, utf8 => "🔳" },
        cube3       => { id => 33, utf8 => "🔲" },
        key4        => { id => 34, utf8 => "🔐" },
        network3    => { id => 35, utf8 => "💻" },
        zip         => { id => 36, utf8 => "💼" },
        pourcentage => { id => 37, utf8 => "%" },
        smb         => { id => 38, utf8 => "💻" },
        time        => { id => 39, utf8 => "⏰" },
        search      => { id => 40, utf8 => "🔍" },
        dress       => { id => 41, utf8 => "👗" },
        memory      => { id => 42, utf8 => "📼" },
        bin         => { id => 43, utf8 => "🚽" },
        sticker     => { id => 44, utf8 => "📋" },
        forbid      => { id => 45, utf8 => "❌" },
        help        => { id => 46, utf8 => "❓" },
        pack        => { id => 47, utf8 => "🎒" },
        folder      => { id => 48, utf8 => "📕" },
        folder2     => { id => 49, utf8 => "📗" },
        zip2        => { id => 50, utf8 => "👜" },
        unlock      => { id => 51, utf8 => "🔓" },
        lock        => { id => 52, utf8 => "🔒" },
        valid       => { id => 53, utf8 => "☑" },
        ink         => { id => 54, utf8 => "✒" },
        picture     => { id => 55, utf8 => "🎑" },
        note5       => { id => 56, utf8 => "📑" },
        card2       => { id => 57, utf8 => "💴" },
        key5        => { id => 58, utf8 => "🔐" },
        tools       => { id => 59, utf8 => "🔧" },
        home        => { id => 60, utf8 => "🏡" },
        star        => { id => 61, utf8 => "⭐" },
        linux       => { id => 62, utf8 => "🐧" },
        ink2        => { id => 63, utf8 => "🔏" },
        apple       => { id => 64, utf8 => "🍏" },
        word        => { id => 65, utf8 => "W" },
        dollar      => { id => 66, utf8 => "💰" },
        card3       => { id => 67, utf8 => "💵" },
        phone       => { id => 68, utf8 => "📱" },
    };
}

sub _build__icon_id_to_key {
    my ($self) = @_;
    my @res;

    for my $key ( keys %{ $self->_icons } ) {
        $res[ $self->_icons->{$key}->{id} ] = $key;
    }

    return \@res;
}

sub get_icon_id_from_key {
    my ( $self, $key ) = @_;
    return $self->_icons->{$key}->{id} // 0;
}

sub get_icon_key_from_id {
    my ( $self, $id ) = @_;
    return $self->_icon_id_to_key->[$id];
}

sub get_icon_char_from_key {
    my ( $self, $key ) = @_;
    return $self->_icons->{$key}->{utf8} // 0;
}

1;

__END__

=pod

=head1 NAME

App::KeePass2::Icons - Built in icon pack from app KeePass2

=head1 VERSION

version 0.04

=head1 METHODS

=head2 get_icon_id_from_key

Return the id of the icon base on his name

=head2 get_icon_key_from_id

Return key of icon base on his id

=head2 get_icon_char_from_key

Return the icon from his name

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://tasks.celogeek.com/projects/app-keepass2/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
