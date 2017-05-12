package Acme::Hidek;

use 5.008_001;
use utf8;
use Mouse;
use Time::Piece;
use Time::HiRes qw(sleep);

if ($^O eq 'MSWin32') {
   require 'Win32/Console/ANSI.pm';
   binmode STDOUT, ":raw :encoding(cp932)";
}
elsif($ENV{CONSOLE_ENCODING}) {
    binmode STDOUT, ":raw :encoding($ENV{CONSOLE_ENCODING})";
}

our $VERSION = '44.0';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use constant {
    BIRTH_YEAR  => 1970,
    BIRTH_MONTH => 9,
    BIRTH_DAY   => 2,
};

has agef => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    default => sub {
        my($self) = @_;
        return +(Time::Piece->localtime - $self->birthdate)->years;
    },
);

has age => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub {
        my($self) = @_;
        return int( $self->agef );
    },
);

has birthdate => (
    is       => 'ro',
    isa      => 'Object',
    lazy     => 1,
    default  => sub { Time::Piece->strptime("1970/9/2", "%Y/%m/%d") },
    init_arg => undef,
);

sub is_birthday {
    my $now = Time::Piece->new;
    return $now->mday == BIRTH_DAY && $now->mon == BIRTH_MONTH;
}

sub ossan40 {
    my @aa = (
        <<'OPPAI'
　　　 _ 　∩
　　(　゜∀゜)彡　${WORD}
　　(　 　　|　
　 　|　　　|　
　 　し ⌒Ｊ

 contributed by @mattn_jp.
OPPAI
        , <<'OPPAI'
　　　 _ 　∩
　　(　゜∀゜)彡　${WORD}
　　(　 ⊂彡
　 　|　　　|　
　 　し ⌒Ｊ

 contributed by @mattn_jp.
OPPAI
        , <<'OPPAI'
　　　 _ 　
　　(　゜∀゜)　　${WORD}
　　(　 ⊂彡
　 　|　　　|　
　 　し ⌒Ｊ

 contributed by @mattn_jp.
OPPAI
    );

    my $a;
    for (1..5) {
        $a = $aa[0]; $a =~ s!\${WORD}!おっ！!;
        print "\e[2J$a"; sleep 0.1;
        $a = $aa[1]; $a =~ s!\${WORD}!おっ！!;
        print "\e[2J$a"; sleep 0.1;
        $a = $aa[2]; $a =~ s!\${WORD}!おっ！!;
        print "\e[2J$a"; sleep 0.5;

        $a = $aa[2]; $a =~ s!\${WORD}!おっさん！!;
        print "\e[2J$a"; sleep 0.1;
        $a = $aa[1]; $a =~ s!\${WORD}!おっさん！!;
        print "\e[2J$a"; sleep 0.1;
        $a = $aa[0]; $a =~ s!\${WORD}!おっさん！!;
        print "\e[2J$a"; sleep 0.5;
    }
}

sub ossan41 {
    my @aa = (
        <<'OPPAI'
　　／⌒ヽ
　 ∩ ＾ω＾）　な　ん　だ
　 |　　 ⊂ﾉ
　｜　　 _⊃
　 し ⌒

 contributed by @mattn_jp.
OPPAI
        , <<'OPPAI'
　　／⌒ヽ
　（＾ω＾ ∩　４　１　か
　 t⊃　　｜
　⊂_ 　　｜
　　　⌒ J

 contributed by @mattn_jp.
OPPAI
        , <<'OPPAI'
　　 　 ／⌒ヽ
　　　( 　　　　)　　おっおっおっ
　　 ／　　、 つ
　 （_(__ ⌒)ﾉ
　　 ∪ (ノ

 contributed by @mattn_jp.
OPPAI
    );

    for (0..9) {
        my $a = $aa[$_ % 3];
        print "\e[2J$a"; sleep 1;
    }
}

no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Acme::Hidek - Virtual net personality Hidek

=head1 VERSION

This document describes Acme::Hidek version 44.0.

=head1 SYNOPSIS

    use Acme::Hidek;

    my $hidek = Acme::Hidek->new();

    $hidek->birthdate;   # => 1970/9/2 (Time::Piece object)
    $hidek->is_birthday; # true if the day is 9/2
    $hidek->age;         # the current age (integer)
    $hidek->agef;        # the current age (float)

    $hidek->we_love_hidek(); # => say congratulations to stdout

=head1 DESCRIPTION

Acme::Hidek provides APIs to access the information on hidek.

This module is written to congratulate the 40th birthday of hidek.
Happy birthday hidek!

=head1 DEPENDENCIES

Perl 5.8.1 or later, and a C compiler.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<http://hidek.info>

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic> for details.

=cut
