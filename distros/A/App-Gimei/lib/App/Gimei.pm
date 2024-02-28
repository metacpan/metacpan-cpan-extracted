use v5.36;

package App::Gimei;

use version; our $VERSION = version->declare("v0.2.6");

1;
__END__

=encoding utf-8

=head1 NAME

App::Gimei - a CLI for Data::Gimei

=head1 SYNOPSIS

    > gimei [OPTIONS] [ARGS]

    > gimei
    松島 孝太
    > gimei name:kanji name:katakana
    谷川 加愛, タニガワ クレア
    > gimei -sep '/' address:prefecture-kanji address:town-kanji
    埼玉県/桜ケ丘町
    > gimei -n 3 name name:hiragana
    山本 公史, やまもと ひろし
    久保田 大志, くぼた たいし
    堀口 光太郎, ほりぐち こうたろう

Omitting ARGS is equivalent to specifying name:kanji.

=head2 OPTIONS

    -sep string
        specify string used to separate fields(default: ", ").
    -n number
        display number record(s).
    -h|help
        display usage and exit.
    -v|version
        display version and exit.

=head2 ARGS

    [WORD_TYPE] [: WORD_SUBTYPE] [- RENDERING]

    WORD_TYPE:               'name' or 'address'
    WORD_SUBTYPE('name'):    'last', 'first' or 'sex'
    WORD_SUBTYPE('address'): 'prefecture', 'city' or 'town'
    RENDERING:               'kanji', 'hiragana', 'katakana' or 'romaji'

- WORD_TYPE 'address' does not support RENDERING romaji.
- WORD_SUBTYPE('name') 'sex' ignore RENDERING.

=head1 DESCRIPTION

App::Gimei is a CLI for Data::Gimei generates fake data that people's name in Japanese.

=head1 INSTALL

This app is available on CPAN. You can install this app by following the step below.

    $ cpanm App::Gimei

=head1 DOCUMENTATION

After installing, you can find documentation for this module with the perldoc command.

    $ perldoc App::Gimei

You can also look for information at:

    GitHub Repository (report bugs here)
        https://github.com/youpong/App-Gimei

    Search CPAN
        https://metacpan.org/pod/App::Gimei

=head1 LICENSE

MIT License

=head1 AUTHOR

NAKAJIMA Yusaku E<lt>youpong@cpan.orgE<gt>

=cut

