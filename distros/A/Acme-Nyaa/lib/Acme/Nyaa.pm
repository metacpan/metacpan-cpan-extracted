package Acme::Nyaa;
use strict;
use warnings;
use utf8;
use 5.010001;
use Encode;
use Module::Load;

use version; our $VERSION = qv('0.0.10');
my $Default = 'ja';

sub new {
    # Constructor of Acme::Nyaa
    my $class = shift;
    my $argvs = { @_ };

    return $class if ref $class eq __PACKAGE__;
    $argvs->{'objects'} = [];
    $argvs->{'language'} ||= $Default;
    $argvs->{'loaded-languages'} = [];
    $argvs->{'objectid'} = int rand 2**24;
    $argvs->{'encoding'} = q();
    $argvs->{'utf8flag'} = undef;

    my $nyaan = bless $argvs, __PACKAGE__;
    my $klass = $nyaan->loadmodule( $argvs->{'language'} );
    my $this1 = $nyaan->findobject( $klass, 1 );

    $nyaan->{'subclass'} = $klass;
    return $nyaan;
}

sub subclass {
    my $self = shift;
    return $self->{'subclass'};
}

sub language {
    my $self = shift;
    my $lang = shift // $self->{'language'};

    return $self->{'language'} if $lang eq $self->{'language'};
    return $self->{'language'} unless $lang =~ m/\A[a-zA-Z]{2}\z/;

    my $nekoobject = undef;
    my $referclass = $self->loadmodule( $lang );
    return $self->{'language'} unless length $referclass;
    return $self->{'language'} if $referclass eq $self->subclass;

    $nekoobject = $self->findobject( $referclass, 1 );
    return $self->{'language'} unless ref $nekoobject eq $referclass;

    $self->{'language'} = $lang;
    $self->{'subclass'} = $referclass;
    return $self->{'language'};
}

sub objects {
    my $self = shift;
    $self->{'objects'} ||= [];
    return $self->{'objects'};
}

sub cat {
    my $self = shift;
    my $text = shift // return q();
    my $neko = $self->findobject( $self->subclass, 1 );

    return $text unless ref $neko;
    return $neko->cat( $text );
}

sub neko {
    my $self = shift;
    my $text = shift // return q();
    my $neko = $self->findobject( $self->subclass, 1 );

    return $text unless ref $neko;
    return $neko->neko( $text );
}

sub nyaa {
    my $self = shift;
    my $text = shift // q();
    my $neko = $self->findobject( $self->subclass, 1 );

    return $text unless ref $neko;
    return $neko->nyaa( $text );
}

sub straycat {
    my $self = shift;
    my $text = shift // return q();
    my $neko = $self->findobject( $self->subclass, 1 );

    return $text unless ref $neko;
    return $neko->straycat( $text );
}

sub loadmodule {
    my $self = shift;
    my $lang = shift;
    my $list = $self->{'loaded-languages'};

    my $referclass = __PACKAGE__.'::'.ucfirst( lc $lang );
    my $alterclass = __PACKAGE__.'::'.ucfirst( $Default );

    return q() unless length $lang;
    return $referclass if( grep { lc $lang eq $_ } @$list );

    eval {
        Module::Load::load $referclass; 
        push @$list, lc $lang;
    };

    return $referclass unless $@;
    return $alterclass if( grep { 'ja' eq $_ } @$list );

    Module::Load::load $alterclass;
    push @$list, $Default;
    return $alterclass;
}

sub findobject {
    my $self = shift;
    my $name = shift;
    my $new1 = shift || 0;
    my $this = undef;
    my $objs = $self->{'objects'} || [];

    return unless length $name;

    for my $e ( @$objs ) {

        next unless ref($e) eq $name;
        $this = $e;
    }
    return $this if ref $this;
    return unless $new1;

    $this = $name->new;
    push @$objs, $this;
    return $this;
}

sub reckon {
    # Implement at sub class
    my $self = shift;
    return $self->{'encoding'};
}

sub toutf8 {
    my $self = shift;
    my $argv = shift;
    my $text = undef;

    $text = ref $argv ? $$argv : $argv;
    return $text unless length $text;

    $self->reckon( \$text );
    return $text if $self->{'utf8flag'};
    return $text unless $self->{'encoding'};

    if( not $self->{'encoding'} =~ m/(?:ascii|utf8)/ ) {
        Encode::from_to( $text, $self->{'encoding'}, 'utf8' );
    }

    $text = Encode::decode_utf8 $text unless utf8::is_utf8 $text;
    return $text;
}

sub utf8to {
    my $self = shift;
    my $argv = shift;
    my $text = undef;

    $text = ref $argv ? $$argv : $argv;
    return $text unless $self->{'encoding'};
    return $text unless length $text;

    $text = Encode::encode_utf8 $text if utf8::is_utf8 $text;
    if( $self->{'encoding'} ne 'utf8' ) {
        Encode::from_to( $text, 'utf8', $self->{'encoding'} );
    }

    return $text;
}

1;
__END__

=encoding utf8

=head1 NAME

Acme::Nyaa - Convert texts like which a cat is talking in Japanese

=head1 SYNOPSIS

    use Acme::Nyaa;
    my $kijitora = Acme::Nyaa->new;

    print $kijitora->cat( \'猫がかわいい。' );  # => 猫がかわいいニャー。
    print $kijitora->neko( \'神と和解せよ' );   # => ネコと和解せよ


=head1 DESCRIPTION
  
Acme::Nyaa is a converter which translate Japanese texts to texts like which a cat talking.
Language modules are available only Japanese (L<Acme::Nyaa::Ja>) for now.

Nyaa is C<ニャー>, Cats living in Japan meows C<nyaa>.

=head1 CLASS METHODS

=head2 B<new( [I<%argv>] )>

new() is a constructor of Acme::Nyaa

    my $kijitora = Acme::Nyaa->new();

=head1 INSTANCE METHODS

=head2 B<cat( I<\$text> )>

cat() is a converter that appends string C<ニャー> at the end of each sentence.

    my $kijitora = Acme::Nyaa->new;
    my $nekotext = '猫がかわいい。';
    print $kijitora->cat( \$nekotext );
    # 猫がかわいいニャー。

=head2 B<neko( I<\$text> )>

neko() is a converter that replace a noun with C<ネコ>.

    my $kijitora = Acme::Nyaa->new;
    my $nekotext = '神のさばきは突然にくる';
    print $kijitora->neko( \$nekotext );
    # ネコのさばきは突然にくる

=head2 B<nyaa( [I<\$text>] )>

nyaa() returns string: C<ニャー>.

    my $kijitora = Acme::Nyaa->new;
    print $kijitora->nyaa();        # ニャー
    print $kijitora->nyaa('京都');  # 京都ニャー

=head2 B<straycat( I<\@array-ref> | I<\$scalar-ref> [,1] )>

straycat() converts multi-lined sentences. If 2nd argument is given then
this method also replace each noun with C<ネコ>.

    my $nekoobject = Acme::Nyaa->new;
    my $filehandle = IO::File->new( 't/a-part-of-i-am-a-cat.ja.txt', 'r' );
    my @nekobuffer = <$filehandle>;
    print $nekoobject->straycat( \@nekobuffer );

    # 吾輩は猫であるニャん。名前はまだ無いニャー。
    # どこで生まれたか頓と見當がつかぬニャーー! 何ても暗薄いじめじめした所でニャーニャー泣いて
    # 居た事丈は記憶して居るニャーん。吾輩はこゝで始めて人間といふものを見たニャーーーー! 然もあとで聞くと
    # それは書生といふ人間で一番獰惡な種族であつたさうだニャん。此書生といふのは時々我々を捕
    # へて煮て食ふといふ話であるニャー!


=head1 SAMPLE APPLICATION

=head2 nyaaproxy

nyaaproxy is a sample application based on Plack using Acme::Nyaa. Start nyaaproxy
by plackup command like the following and open URL such as 
C<http://127.0.0.1:2222/http://ja.wikipedia.org/wiki/ネコ>.

    $ plackup -o 127.0.0.1 -p 2222 -a eg/nyaaproxy.psgi

=head1 REPOSITORY

https://github.com/azumakuniyuki/p5-Acme-Nyaa

=head2 INSTALL FROM REPOSITORY

    % sudo cpanm Module::Install
    % cd /usr/local/src
    % git clone git://github.com/azumakuniyuki/p5-Acme-Nyaa.git
    % cd ./p5-Acme-Nyaa
    % perl Makefile.PL && make && make test && sudo make install

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 SEE ALSO

L<Acme::Nyaa::Ja> - Japanese module for Acme::Nyaa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

