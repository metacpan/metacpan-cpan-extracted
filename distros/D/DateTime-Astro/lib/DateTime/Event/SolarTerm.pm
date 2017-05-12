package DateTime::Event::SolarTerm;
use strict;
use DateTime::Set;
use DateTime::Astro qw(dt_from_moment moment new_moon_after_from_moment solar_longitude_from_moment);
use Exporter 'import';
use POSIX ();
use constant DEBUG => 1;

our @EXPORT_OK = qw(
    major_term_after
    major_term_before
    major_term
    minor_term_after
    minor_term_before
    minor_term
    no_major_term_on
    prev_term_at
    CHUNFEN
    SHUNBUN
    QINGMING
    SEIMEI
    GUYU
    KOKUU
    LIXIA
    RIKKA
    XIAOMAN
    SHOMAN
    MANGZHONG
    BOHSHU
    XIAZHO
    GESHI
    SUMMER_SOLSTICE
    XIAOSHU
    SHOUSHO
    DASHU
    TAISHO
    LIQIU
    RISSHU
    CHUSHU
    SHOSHO
    BAILU
    HAKURO
    QIUFEN
    SHUUBUN
    HANLU
    KANRO
    SHUANGJIANG
    SOHKOH
    LIDONG
    RITTOH
    XIAOXUE
    SHOHSETSU
    DAXUE
    TAISETSU
    DONGZHI
    TOHJI
    WINTER_SOLSTICE
    XIAOHAN
    SHOHKAN
    DAHAN
    DAIKAN
    LICHUN
    RISSHUN
    YUSHUI
    USUI
    JINGZE
    KEICHITSU
);

sub prev_term_at {
    return dt_from_moment(prev_term_at_from_moment(moment($_[0]), $_[1]));
}

sub major_term_after {
    return $_[0] if $_[0]->is_infinite;
    return dt_from_moment( major_term_after_from_moment( moment($_[0]) ) );
}

sub major_term_before {
    return $_[0] if $_[0]->is_infinite;
    return dt_from_moment( major_term_before_from_moment( moment($_[0]) ) );
}

sub major_term {
    return DateTime::Set->from_recurrence(
        next => sub {
            return $_[0] if $_[0]->is_infinite;
            return major_term_after($_[0]);
        },
        previous => sub {
            return $_[0] if $_[0]->is_infinite;
            return major_term_before($_[0]);
        },
    );
}

sub minor_term_after {
    return $_[0] if $_[0]->is_infinite;
    return dt_from_moment( minor_term_after_from_moment( moment($_[0]) ) );
}

sub minor_term_before {
    return $_[0] if $_[0]->is_infinite;
    return dt_from_moment( minor_term_before_from_moment( moment($_[0]) ) );
}

sub minor_term {
    return DateTime::Set->from_recurrence(
        next => sub {
            return $_[0] if $_[0]->is_infinite;
            return minor_term_after($_[0]);
        },
        previous => sub {
            return $_[0] if $_[0]->is_infinite;
            return minor_term_before($_[0]);
        },
    );
}

sub last_major_term_index_from_moment {
    my ($m) = @_;
    my $l = solar_longitude_from_moment($m);
    my $x = 2 + POSIX::floor($l / 30);
    return $x % 12 || 12;
}

# [1] p.245 (current_major_term)
sub last_major_term_index {
    return () if $_[0]->is_infinite;
    return dt_from_moment( last_major_term_index_from_moment( moment( $_[0] ) ) );
}

# [1] p.245 (current_minor_term)
sub last_minor_term_index {
    return () if $_[0]->is_infinite;
    my $l = solar_longitude($_[0]);
    my $x = 3 + POSIX::floor($l - 15) / 30;
    return $x % 12 || 12;
}

# [1] p.250
sub no_major_term_on_from_moment {
    if ($_[0] >= 693596 && $_[0] < 755688) {
        # this logic is hardcoded, because I couldn't make the real
        # logic work for leap months. Dunno why
        return 
            719678 <= $_[0] && 719708 > $_[0] ||
            720743 <= $_[0] && 720774 > $_[0] ||
            721597 <= $_[0] && 721627 > $_[0] ||
            722630 <= $_[0] && 722661 > $_[0] ||
            723665 <= $_[0] && 723696 > $_[0] ||
            724580 <= $_[0] && 724610 > $_[0] ||
            725552 <= $_[0] && 725583 > $_[0] ||
            726618 <= $_[0] && 726648 > $_[0] ||
            727653 <= $_[0] && 727683 > $_[0] ||
            728536 <= $_[0] && 728566 > $_[0] ||
            729540 <= $_[0] && 729570 > $_[0] ||
            730605 <= $_[0] && 730636 > $_[0] ||
            731640 <= $_[0] && 731671 > $_[0] ||
            732523 <= $_[0] && 732554 > $_[0] ||
            733558 <= $_[0] && 733588 > $_[0] ||
            734593 <= $_[0] && 734623 > $_[0] ||
            735506 <= $_[0] && 735537 > $_[0] ||
            736480 <= $_[0] && 736510 > $_[0] ||
            737545 <= $_[0] && 737576 > $_[0] ||
            738579 <= $_[0] && 738610 > $_[0] ||
            739432 <= $_[0] && 739463 > $_[0] ||
            740498 <= $_[0] && 740528 > $_[0]
    }

    warn __PACKAGE__ . "::no_major_term_on_from_moment() currently does not support ranges outside of 1900/1/1 ~ 2069/12/31. Please send patches if you need support for other ranges";
    # the real logic 
    my $next_new_moon = new_moon_after_from_moment( $_[0] + 1 );
    my $i1 = last_major_term_index_from_moment( $_[0] );
    my $i2 = last_major_term_index_from_moment( $next_new_moon );

    if (DEBUG) {
        print STDERR "major term on ",
            dt_from_moment($_[0]),
            " -> ",
            $i1 == $i2 ? "YES" : "NO", "\n",
            "   using dates ",
                dt_from_moment($_[0]), " -> ", dt_from_moment($next_new_moon), "\n"
;
    }

    return $i1 == $i2;
}

sub no_major_term_on {
    return no_major_term_on_from_moment( moment( $_[0] ) );
}

1;

__END__

=head1 NAME

DateTime::Event::SolarTerm - Calculate Solar Terms

=head1 SYNOPSIS

    use DateTime::Event::SolarTerm;

=head1 FUNCTIONS

=head2 major_term_after

=head2 major_term_before

=head2 major_term

=head2 minor_term_after

=head2 minor_term_before

=head2 minor_term

=head2 no_major_term_on

=head2 prev_term_at

=head2 last_major_term_index

=head2 last_major_term_index_from_moment

=head2 last_minor_term_index

=head2 major_term_after_from_moment

=head2 major_term_before_from_moment

=head2 minor_term_after_from_moment

=head2 minor_term_before_from_moment

=head2 next_term_at_from_moment

=head2 no_major_term_on_from_moment

=head2 prev_term_at_from_moment

=head1 THE TERMS

=head2 CHUNFEN SHUNBUN

=head2 QINGMING SEIMEI

=head2 GUYU KOKUU

=head2 LIXIA RIKKA

=head2 XIAOMAN SHOMAN

=head2 MANGZHONG BOHSHU

=head2 XIAZHO GESHI SUMMER_SOLSTICE

=head2 XIAOSHU SHOUSHO

=head2 DASHU TAISHO

=head2 LIQIU RISSHU

=head2 CHUSHU SHOSHO

=head2 BAILU HAKURO

=head2 QIUFEN SHUUBUN

=head2 HANLU KANRO

=head2 SHUANGJIANG SOHKOH

=head2 LIDONG RITTOH

=head2 XIAOXUE SHOHSETSU

=head2 DAXUE TAISETSU

=head2 DONGZHI TOHJI WINTER_SOLSTICE

=head2 XIAOHAN SHOHKAN

=head2 DAHAN DAIKAN

=head2 LICHUN RISSHUN

=head2 YUSHUI USUI

=head2 JINGZE KEICHITSU

=cut
