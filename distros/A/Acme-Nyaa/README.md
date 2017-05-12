# NAME

Acme::Nyaa - Convert texts like which a cat is talking in Japanese

# SYNOPSIS

    use Acme::Nyaa;
    my $kijitora = Acme::Nyaa->new;

    print $kijitora->cat( \'猫がかわいい。' );  # => 猫がかわいいニャー。
    print $kijitora->neko( \'神と和解せよ' );   # => ネコと和解せよ



# DESCRIPTION
  

Acme::Nyaa is a converter which translate Japanese texts to texts like which a cat talking.
Language modules are available only Japanese ([Acme::Nyaa::Ja](http://search.cpan.org/perldoc?Acme::Nyaa::Ja)) for now.

Nyaa is `ニャー`, Cats living in Japan meows `nyaa`.

# CLASS METHODS

## __new( \[_%argv_\] )__

new() is a constructor of Acme::Nyaa

    my $kijitora = Acme::Nyaa->new();

# INSTANCE METHODS

## __cat( _\\$text_ )__

cat() is a converter that appends string `ニャー` at the end of each sentence.

    my $kijitora = Acme::Nyaa->new;
    my $nekotext = '猫がかわいい。';
    print $kijitora->cat( \$nekotext );
    # 猫がかわいいニャー。

## __neko( _\\$text_ )__

neko() is a converter that replace a noun with `ネコ`.

    my $kijitora = Acme::Nyaa->new;
    my $nekotext = '神のさばきは突然にくる';
    print $kijitora->neko( \$nekotext );
    # ネコのさばきは突然にくる

## __nyaa( \[_\\$text_\] )__

nyaa() returns string: `ニャー`.

    my $kijitora = Acme::Nyaa->new;
    print $kijitora->nyaa();        # ニャー
    print $kijitora->nyaa('京都');  # 京都ニャー

## __straycat( _\\@array-ref_ | _\\$scalar-ref_ \[,1\] )__

straycat() converts multi-lined sentences. If 2nd argument is given then
this method also replace each noun with `ネコ`.

    my $nekoobject = Acme::Nyaa->new;
    my $filehandle = IO::File->new( 't/a-part-of-i-am-a-cat.ja.txt', 'r' );
    my @nekobuffer = <$filehandle>;
    print $nekoobject->straycat( \@nekobuffer );

    # 吾輩は猫であるニャん。名前はまだ無いニャー。
    # どこで生まれたか頓と見當がつかぬニャーー! 何ても暗薄いじめじめした所でニャーニャー泣いて
    # 居た事丈は記憶して居るニャーん。吾輩はこゝで始めて人間といふものを見たニャーーーー! 然もあとで聞くと
    # それは書生といふ人間で一番獰惡な種族であつたさうだニャん。此書生といふのは時々我々を捕
    # へて煮て食ふといふ話であるニャー!



# SAMPLE APPLICATION

## nyaaproxy

nyaaproxy is a sample application based on Plack using Acme::Nyaa. Start nyaaproxy
by plackup command like the following and open URL such as 
`http://127.0.0.1:2222/http://ja.wikipedia.org/wiki/ネコ`.

    $ plackup -o 127.0.0.1 -p 2222 -a eg/nyaaproxy.psgi

# REPOSITORY

https://github.com/azumakuniyuki/p5-Acme-Nyaa

## INSTALL FROM REPOSITORY

    % sudo cpanm Module::Install
    % cd /usr/local/src
    % git clone git://github.com/azumakuniyuki/p5-Acme-Nyaa.git
    % cd ./p5-Acme-Nyaa
    % perl Makefile.PL && make && make test && sudo make install

# AUTHOR

azumakuniyuki <perl.org \[at\] azumakuniyuki.org>

# SEE ALSO

[Acme::Nyaa::Ja](http://search.cpan.org/perldoc?Acme::Nyaa::Ja) - Japanese module for Acme::Nyaa

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
