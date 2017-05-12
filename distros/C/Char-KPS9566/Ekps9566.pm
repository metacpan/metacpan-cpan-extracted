package Ekps9566;
######################################################################
#
# Ekps9566 - Run-time routines for KPS9566.pm
#
# http://search.cpan.org/dist/Char-KPS9566/
#
# Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016 INABA Hitoshi <ina@cpan.org>
######################################################################

use 5.00503;    # Galapagos Consensus 1998 for primetools
# use 5.008001; # Lancaster Consensus 2013 for toolchains

# 12.3. Delaying use Until Runtime
# in Chapter 12. Packages, Libraries, and Modules
# of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.
# (and so on)

# Version numbers should be boring
# http://www.dagolden.com/index.php/369/version-numbers-should-be-boring/
# For the impatient, the disinterested or those who just want to follow
# a recipe, my advice for all modules is this:
# our $VERSION = "0.001"; # or "0.001_001" for a dev release
# $VERSION = eval $VERSION;

BEGIN { CORE::eval q{ use vars qw($VERSION) } }
$VERSION = '1.08';
$VERSION = CORE::eval $VERSION;

BEGIN {
    if ($^X =~ / jperl /oxmsi) {
        die __FILE__, ": needs perl(not jperl) 5.00503 or later. (\$^X==$^X)\n";
    }
    if (CORE::ord('A') == 193) {
        die __FILE__, ": is not US-ASCII script (may be EBCDIC or EBCDIK script).\n";
    }
    if (CORE::ord('A') != 0x41) {
        die __FILE__, ": is not US-ASCII script (must be US-ASCII script).\n";
    }
}

BEGIN {

    # instead of utf8.pm
    CORE::eval q{
        no warnings qw(redefine);
        *utf8::upgrade   = sub { CORE::length $_[0] };
        *utf8::downgrade = sub { 1 };
        *utf8::encode    = sub {   };
        *utf8::decode    = sub { 1 };
        *utf8::is_utf8   = sub {   };
        *utf8::valid     = sub { 1 };
    };
    if ($@) {
        *utf8::upgrade   = sub { CORE::length $_[0] };
        *utf8::downgrade = sub { 1 };
        *utf8::encode    = sub {   };
        *utf8::decode    = sub { 1 };
        *utf8::is_utf8   = sub {   };
        *utf8::valid     = sub { 1 };
    }
}

# instead of Symbol.pm
BEGIN {
    my $genpkg = "Symbol::";
    my $genseq = 0;

    sub gensym () {
        my $name = "GEN" . $genseq++;

        # here, no strict qw(refs); if strict.pm exists

        my $ref = \*{$genpkg . $name};
        delete $$genpkg{$name};
        return $ref;
    }

    sub qualify ($;$) {
        my ($name) = @_;
        if (!ref($name) && (Ekps9566::index($name, '::') == -1) && (Ekps9566::index($name, "'") == -1)) {
            my $pkg;
            my %global = map {$_ => 1} qw(ARGV ARGVOUT ENV INC SIG STDERR STDIN STDOUT DATA);

            # Global names: special character, "^xyz", or other.
            if ($name =~ /^(([^\x81-\xFEa-z])|(\^[a-z_]+))\z/i || $global{$name}) {
                # RGS 2001-11-05 : translate leading ^X to control-char
                $name =~ s/^\^([a-z_])/'qq(\c'.$1.')'/eei;
                $pkg = "main";
            }
            else {
                $pkg = (@_ > 1) ? $_[1] : caller;
            }
            $name = $pkg . "::" . $name;
        }
        return $name;
    }

    sub qualify_to_ref ($;$) {

        # here, no strict qw(refs); if strict.pm exists

        return \*{ qualify $_[0], @_ > 1 ? $_[1] : caller };
    }
}

# Column: local $@
# in Chapter 9. Osaete okitai Perl no kiso
# of ISBN 10: 4798119172 | ISBN 13: 978-4798119175 MODAN Perl NYUMON
# (and so on)

# use strict; if strict.pm exists
BEGIN {
    if (CORE::eval { local $@; CORE::require strict }) {
        strict::->import;
    }
}

# P.714 29.2.39. flock
# in Chapter 29: Functions
# of ISBN 0-596-00027-8 Programming Perl Third Edition.

# P.863 flock
# in Chapter 27: Functions
# of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

sub LOCK_SH() {1}
sub LOCK_EX() {2}
sub LOCK_UN() {8}
sub LOCK_NB() {4}

# instead of Carp.pm
sub carp;
sub croak;
sub cluck;
sub confess;

# 6.18. Matching Multiple-Byte Characters
# in Chapter 6. Pattern Matching
# of ISBN 978-1-56592-243-3 Perl Perl Cookbook.
# (and so on)

# regexp of character
BEGIN { CORE::eval q{ use vars qw($your_char) } } $your_char = q{[\x81-\xFE][\x00-\xFF]|[\x00-\xFF]};
BEGIN { CORE::eval q{ use vars qw($qq_char  ) } } $qq_char   = qr/\\c[\x40-\x5F]|\\?(?:$your_char)/oxms;
BEGIN { CORE::eval q{ use vars qw($q_char   ) } } $q_char    = qr/$your_char/oxms;

#
# KPS9566 character range per length
#
my %range_tr = ();

#
# alias of encoding name
#
BEGIN { CORE::eval q{ use vars qw($encoding_alias) } }

#
# KPS9566 case conversion
#
my %lc = ();
@lc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
    qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
my %uc = ();
@uc{qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)} =
    qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
my %fc = ();
@fc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
    qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);

if (0) {
}

elsif (__PACKAGE__ =~ / \b Ekps9566 \z/oxms) {
    %range_tr = (
        1 => [ [0x00..0x80],
               [0xFF..0xFF],
             ],
        2 => [ [0x81..0xFE],[0x41..0x5A],
               [0x81..0xFE],[0x61..0x7A],
               [0x81..0xFE],[0x81..0xFE],
             ],
    );
    $encoding_alias = qr/ \b (?: euc.*kp | kp.*euc | (?:x-)?kps9566 ) \b /oxmsi;
}

else {
    croak "Don't know my package name '@{[__PACKAGE__]}'";
}

#
# @ARGV wildcard globbing
#
sub import {

    if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
        my @argv = ();
        for (@ARGV) {

            # has space
            if (/\A (?:$q_char)*? [ ] /oxms) {
                if (my @glob = Ekps9566::glob(qq{"$_"})) {
                    push @argv, @glob;
                }
                else {
                    push @argv, $_;
                }
            }

            # has wildcard metachar
            elsif (/\A (?:$q_char)*? [*?] /oxms) {
                if (my @glob = Ekps9566::glob($_)) {
                    push @argv, @glob;
                }
                else {
                    push @argv, $_;
                }
            }

            # no wildcard globbing
            else {
                push @argv, $_;
            }
        }
        @ARGV = @argv;
    }

    *Char::ord           = \&KPS9566::ord;
    *Char::ord_          = \&KPS9566::ord_;
    *Char::reverse       = \&KPS9566::reverse;
    *Char::getc          = \&KPS9566::getc;
    *Char::length        = \&KPS9566::length;
    *Char::substr        = \&KPS9566::substr;
    *Char::index         = \&KPS9566::index;
    *Char::rindex        = \&KPS9566::rindex;
    *Char::eval          = \&KPS9566::eval;
    *Char::escape        = \&KPS9566::escape;
    *Char::escape_token  = \&KPS9566::escape_token;
    *Char::escape_script = \&KPS9566::escape_script;
}

# P.230 Care with Prototypes
# in Chapter 6: Subroutines
# of ISBN 0-596-00027-8 Programming Perl Third Edition.
#
# If you aren't careful, you can get yourself into trouble with prototypes.
# But if you are careful, you can do a lot of neat things with them. This is
# all very powerful, of course, and should only be used in moderation to make
# the world a better place.

# P.332 Care with Prototypes
# in Chapter 7: Subroutines
# of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.
#
# If you aren't careful, you can get yourself into trouble with prototypes.
# But if you are careful, you can do a lot of neat things with them. This is
# all very powerful, of course, and should only be used in moderation to make
# the world a better place.

#
# Prototypes of subroutines
#
sub unimport {}
sub Ekps9566::split(;$$$);
sub Ekps9566::tr($$$$;$);
sub Ekps9566::chop(@);
sub Ekps9566::index($$;$);
sub Ekps9566::rindex($$;$);
sub Ekps9566::lcfirst(@);
sub Ekps9566::lcfirst_();
sub Ekps9566::lc(@);
sub Ekps9566::lc_();
sub Ekps9566::ucfirst(@);
sub Ekps9566::ucfirst_();
sub Ekps9566::uc(@);
sub Ekps9566::uc_();
sub Ekps9566::fc(@);
sub Ekps9566::fc_();
sub Ekps9566::ignorecase;
sub Ekps9566::classic_character_class;
sub Ekps9566::capture;
sub Ekps9566::chr(;$);
sub Ekps9566::chr_();
sub Ekps9566::filetest;
sub Ekps9566::r(;*@);
sub Ekps9566::w(;*@);
sub Ekps9566::x(;*@);
sub Ekps9566::o(;*@);
sub Ekps9566::R(;*@);
sub Ekps9566::W(;*@);
sub Ekps9566::X(;*@);
sub Ekps9566::O(;*@);
sub Ekps9566::e(;*@);
sub Ekps9566::z(;*@);
sub Ekps9566::s(;*@);
sub Ekps9566::f(;*@);
sub Ekps9566::d(;*@);
sub Ekps9566::l(;*@);
sub Ekps9566::p(;*@);
sub Ekps9566::S(;*@);
sub Ekps9566::b(;*@);
sub Ekps9566::c(;*@);
sub Ekps9566::u(;*@);
sub Ekps9566::g(;*@);
sub Ekps9566::k(;*@);
sub Ekps9566::T(;*@);
sub Ekps9566::B(;*@);
sub Ekps9566::M(;*@);
sub Ekps9566::A(;*@);
sub Ekps9566::C(;*@);
sub Ekps9566::filetest_;
sub Ekps9566::r_();
sub Ekps9566::w_();
sub Ekps9566::x_();
sub Ekps9566::o_();
sub Ekps9566::R_();
sub Ekps9566::W_();
sub Ekps9566::X_();
sub Ekps9566::O_();
sub Ekps9566::e_();
sub Ekps9566::z_();
sub Ekps9566::s_();
sub Ekps9566::f_();
sub Ekps9566::d_();
sub Ekps9566::l_();
sub Ekps9566::p_();
sub Ekps9566::S_();
sub Ekps9566::b_();
sub Ekps9566::c_();
sub Ekps9566::u_();
sub Ekps9566::g_();
sub Ekps9566::k_();
sub Ekps9566::T_();
sub Ekps9566::B_();
sub Ekps9566::M_();
sub Ekps9566::A_();
sub Ekps9566::C_();
sub Ekps9566::glob($);
sub Ekps9566::glob_();
sub Ekps9566::lstat(*);
sub Ekps9566::lstat_();
sub Ekps9566::opendir(*$);
sub Ekps9566::stat(*);
sub Ekps9566::stat_();
sub Ekps9566::unlink(@);
sub Ekps9566::chdir(;$);
sub Ekps9566::do($);
sub Ekps9566::require(;$);
sub Ekps9566::telldir(*);

sub KPS9566::ord(;$);
sub KPS9566::ord_();
sub KPS9566::reverse(@);
sub KPS9566::getc(;*@);
sub KPS9566::length(;$);
sub KPS9566::substr($$;$$);
sub KPS9566::index($$;$);
sub KPS9566::rindex($$;$);
sub KPS9566::escape(;$);

#
# Regexp work
#
BEGIN { CORE::eval q{ use vars qw(
    $KPS9566::re_a
    $KPS9566::re_t
    $KPS9566::re_n
    $KPS9566::re_r
) } }

#
# Character class
#
BEGIN { CORE::eval q{ use vars qw(
    $dot
    $dot_s
    $eD
    $eS
    $eW
    $eH
    $eV
    $eR
    $eN
    $not_alnum
    $not_alpha
    $not_ascii
    $not_blank
    $not_cntrl
    $not_digit
    $not_graph
    $not_lower
    $not_lower_i
    $not_print
    $not_punct
    $not_space
    $not_upper
    $not_upper_i
    $not_word
    $not_xdigit
    $eb
    $eB
) } }

BEGIN { CORE::eval q{ use vars qw(
    $anchor
    $matched
) } }
${Ekps9566::anchor} = qr{\G(?>[^\x81-\xFE]|[\x81-\xFE][\x00-\xFF])*?}oxms;
BEGIN { CORE::eval q{ use vars qw(
    $q_char_SADAHIRO_Tomoyuki_2002_01_17
) } }

# Quantifiers
#   {n,m}  ---  Match at least n but not more than m times
#
# n and m are limited to non-negative integral values less than a
# preset limit defined when perl is built. This is usually 32766 on
# the most common platforms.
#
# The following code is an attempt to solve the above limitations
# in a multi-byte anchoring.

# avoid "Segmentation fault" and "Error: Parse exception"

# perl5101delta
# http://perldoc.perl.org/perl5101delta.html
# In 5.10.0, the * quantifier in patterns was sometimes treated as {0,32767}
# [RT #60034, #60464]. For example, this match would fail:
#   ("ab" x 32768) =~ /^(ab)*$/

# SEE ALSO
#
# Complex regular subexpression recursion limit
# http://www.perlmonks.org/?node_id=810857
#
# regexp iteration limits
# http://www.nntp.perl.org/group/perl.perl5.porters/2009/02/msg144065.html
#
# latest Perl won't match certain regexes more than 32768 characters long
# http://stackoverflow.com/questions/26226630/latest-perl-wont-match-certain-regexes-more-than-32768-characters-long
#
# Break through the limitations of regular expressions of Perl
# http://d.hatena.ne.jp/gfx/20110212/1297512479

if (($] >= 5.010001) or
    # ActivePerl 5.6 or later (include 5.10.0)
    (defined($ActivePerl::VERSION) and ($ActivePerl::VERSION > 800)) or
    (($^O eq 'MSWin32') and ($] =~ /\A 5\.006/oxms))
) {
    my $sbcs = ''; # Single Byte Character Set
    for my $range (@{ $range_tr{1} }) {
        $sbcs .= sprintf('\\x%02X-\\x%02X', $range->[0], $range->[-1]);
    }

    if (0) {
    }

    # other encoding
    else {
        ${Ekps9566::q_char_SADAHIRO_Tomoyuki_2002_01_17} = qr{.*?[$sbcs](?:[^$sbcs][^$sbcs])*?}oxms;
        #                                                     ******* octets not in multiple octet char (always char boundary)
        #                                                               **************** 2 octet chars
    }

    ${Ekps9566::anchor_SADAHIRO_Tomoyuki_2002_01_17} =
    qr{\G(?(?=.{0,32766}\z)(?:[^\x81-\xFE]|[\x81-\xFE][\x00-\xFF])*?|(?(?=[$sbcs]+\z).*?|(?:${Ekps9566::q_char_SADAHIRO_Tomoyuki_2002_01_17})))}oxms;
#   qr{
#      \G # (1), (2)
#        (? # (3)
#          (?=.{0,32766}\z) # (4)
#                          (?:[^\x81-\xFE]|[\x81-\xFE][\x00-\xFF])*?| # (5)
#                                                                                      (?(?=[$sbcs]+\z) # (6)
#                                                                                                      .*?| #(7)
#                                                                                                          (?:${Ekps9566::q_char_SADAHIRO_Tomoyuki_2002_01_17}) # (8)
#                                                                                                                                           ))}oxms;

    # avoid: Complex regular subexpression recursion limit (32766) exceeded at here.
    local $^W = 0;

    if (((('A' x 32768).'B') !~ / ${Ekps9566::anchor}                              B /oxms) and
        ((('A' x 32768).'B') =~ / ${Ekps9566::anchor_SADAHIRO_Tomoyuki_2002_01_17} B /oxms)
    ) {
        ${Ekps9566::anchor} = ${Ekps9566::anchor_SADAHIRO_Tomoyuki_2002_01_17};
    }
    else {
        undef ${Ekps9566::q_char_SADAHIRO_Tomoyuki_2002_01_17};
    }
}

# (1)
# P.128 Start of match (or end of previous match): \G
# P.130 Advanced Use of \G with Perl
# in Chapter3: Over view of Regular Expression Features and Flavors
# of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

# (2)
# P.255 Use leading anchors
# P.256 Expose ^ and \G at the front of expressions
# in Chapter6: Crafting an Efficient Expression
# of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

# (3)
# P.138 Conditional: (? if then| else)
# in Chapter3: Over view of Regular Expression Features and Flavors
# of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

# (4)
# perlre
# http://perldoc.perl.org/perlre.html
# The "*" quantifier is equivalent to {0,} , the "+" quantifier to {1,} ,
# and the "?" quantifier to {0,1}, ., n, and m are limited to non-negative
# integral values less than a preset limit defined when perl is built.
# This is usually 32766 on the most common platforms. The actual limit
# can be seen in the error message generated by code such as this:
#  $_ **= $_ , / {$_} / for 2 .. 42;

# (5)
# P.1023 Multiple-Byte Anchoring
# in Appendix W Perl Code Examples
# of ISBN 1-56592-224-7 CJKV Information Processing

# (6)
# if string has only SBCS (Single Byte Character Set)

# (7)
# then .*? (isn't limited to 32766)

# (8)
# else KPS9566::Regexp::Const (SADAHIRO Tomoyuki)
# http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm#long
# http://search.cpan.org/~sadahiro/KPS9566-Regexp/
# $PadA  = '  (?:\A|                                           [\x00-\x80\xA0-\xDF])(?:[\x81-\xFE]{2})*?';
# $PadG  = '\G(?:                                |[\x00-\xFF]*?[\x00-\x80\xA0-\xDF])(?:[\x81-\xFE]{2})*?';
# $PadGA = '\G(?:\A|(?:[\x81-\xFE]{2})+?|[\x00-\xFF]*?[\x00-\x80\xA0-\xDF] (?:[\x81-\xFE]{2})*?)';

${Ekps9566::dot}         = qr{(?>[^\x81-\xFE\x0A]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::dot_s}       = qr{(?>[^\x81-\xFE]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::eD}          = qr{(?>[^\x81-\xFE0-9]|[\x81-\xFE][\x00-\xFF])};

# Vertical tabs are now whitespace
# \s in a regex now matches a vertical tab in all circumstances.
# http://search.cpan.org/dist/perl-5.18.0/pod/perldelta.pod#Vertical_tabs_are_now_whitespace
# ${Ekps9566::eS}          = qr{(?>[^\x81-\xFE\x09\x0A    \x0C\x0D\x20]|[\x81-\xFE][\x00-\xFF])};
# ${Ekps9566::eS}          = qr{(?>[^\x81-\xFE\x09\x0A\x0B\x0C\x0D\x20]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::eS}            = qr{(?>[^\x81-\xFE\s]|[\x81-\xFE][\x00-\xFF])};

${Ekps9566::eW}            = qr{(?>[^\x81-\xFE0-9A-Z_a-z]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::eH}            = qr{(?>[^\x81-\xFE\x09\x20]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::eV}            = qr{(?>[^\x81-\xFE\x0A\x0B\x0C\x0D]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::eR}            = qr{(?>\x0D\x0A|[\x0A\x0D])};
${Ekps9566::eN}            = qr{(?>[^\x81-\xFE\x0A]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::not_alnum}     = qr{(?>[^\x81-\xFE\x30-\x39\x41-\x5A\x61-\x7A]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::not_alpha}     = qr{(?>[^\x81-\xFE\x41-\x5A\x61-\x7A]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::not_ascii}     = qr{(?>[^\x81-\xFE\x00-\x7F]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::not_blank}     = qr{(?>[^\x81-\xFE\x09\x20]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::not_cntrl}     = qr{(?>[^\x81-\xFE\x00-\x1F\x7F]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::not_digit}     = qr{(?>[^\x81-\xFE\x30-\x39]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::not_graph}     = qr{(?>[^\x81-\xFE\x21-\x7F]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::not_lower}     = qr{(?>[^\x81-\xFE\x61-\x7A]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::not_lower_i}   = qr{(?>[^\x81-\xFE\x41-\x5A\x61-\x7A]|[\x81-\xFE][\x00-\xFF])}; # Perl 5.16 compatible
# ${Ekps9566::not_lower_i} = qr{(?>[^\x81-\xFE]|[\x81-\xFE][\x00-\xFF])};                   # older Perl compatible
${Ekps9566::not_print}     = qr{(?>[^\x81-\xFE\x20-\x7F]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::not_punct}     = qr{(?>[^\x81-\xFE\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::not_space}     = qr{(?>[^\x81-\xFE\s\x0B]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::not_upper}     = qr{(?>[^\x81-\xFE\x41-\x5A]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::not_upper_i}   = qr{(?>[^\x81-\xFE\x41-\x5A\x61-\x7A]|[\x81-\xFE][\x00-\xFF])}; # Perl 5.16 compatible
# ${Ekps9566::not_upper_i} = qr{(?>[^\x81-\xFE]|[\x81-\xFE][\x00-\xFF])};                   # older Perl compatible
${Ekps9566::not_word}      = qr{(?>[^\x81-\xFE\x30-\x39\x41-\x5A\x5F\x61-\x7A]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::not_xdigit}    = qr{(?>[^\x81-\xFE\x30-\x39\x41-\x46\x61-\x66]|[\x81-\xFE][\x00-\xFF])};
${Ekps9566::eb}            = qr{(?:\A(?=[0-9A-Z_a-z])|(?<=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF])(?=[0-9A-Z_a-z])|(?<=[0-9A-Z_a-z])(?=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF]|\z))};
${Ekps9566::eB}            = qr{(?:(?<=[0-9A-Z_a-z])(?=[0-9A-Z_a-z])|(?<=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF])(?=[\x00-\x2F\x40\x5B-\x5E\x60\x7B-\xFF]))};

# avoid: Name "Ekps9566::foo" used only once: possible typo at here.
${Ekps9566::dot}         = ${Ekps9566::dot};
${Ekps9566::dot_s}       = ${Ekps9566::dot_s};
${Ekps9566::eD}          = ${Ekps9566::eD};
${Ekps9566::eS}          = ${Ekps9566::eS};
${Ekps9566::eW}          = ${Ekps9566::eW};
${Ekps9566::eH}          = ${Ekps9566::eH};
${Ekps9566::eV}          = ${Ekps9566::eV};
${Ekps9566::eR}          = ${Ekps9566::eR};
${Ekps9566::eN}          = ${Ekps9566::eN};
${Ekps9566::not_alnum}   = ${Ekps9566::not_alnum};
${Ekps9566::not_alpha}   = ${Ekps9566::not_alpha};
${Ekps9566::not_ascii}   = ${Ekps9566::not_ascii};
${Ekps9566::not_blank}   = ${Ekps9566::not_blank};
${Ekps9566::not_cntrl}   = ${Ekps9566::not_cntrl};
${Ekps9566::not_digit}   = ${Ekps9566::not_digit};
${Ekps9566::not_graph}   = ${Ekps9566::not_graph};
${Ekps9566::not_lower}   = ${Ekps9566::not_lower};
${Ekps9566::not_lower_i} = ${Ekps9566::not_lower_i};
${Ekps9566::not_print}   = ${Ekps9566::not_print};
${Ekps9566::not_punct}   = ${Ekps9566::not_punct};
${Ekps9566::not_space}   = ${Ekps9566::not_space};
${Ekps9566::not_upper}   = ${Ekps9566::not_upper};
${Ekps9566::not_upper_i} = ${Ekps9566::not_upper_i};
${Ekps9566::not_word}    = ${Ekps9566::not_word};
${Ekps9566::not_xdigit}  = ${Ekps9566::not_xdigit};
${Ekps9566::eb}          = ${Ekps9566::eb};
${Ekps9566::eB}          = ${Ekps9566::eB};

#
# KPS9566 split
#
sub Ekps9566::split(;$$$) {

    # P.794 29.2.161. split
    # in Chapter 29: Functions
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.951 split
    # in Chapter 27: Functions
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    my $pattern = $_[0];
    my $string  = $_[1];
    my $limit   = $_[2];

    # if $pattern is also omitted or is the literal space, " "
    if (not defined $pattern) {
        $pattern = ' ';
    }

    # if $string is omitted, the function splits the $_ string
    if (not defined $string) {
        if (defined $_) {
            $string = $_;
        }
        else {
            $string = '';
        }
    }

    my @split = ();

    # when string is empty
    if ($string eq '') {

        # resulting list value in list context
        if (wantarray) {
            return @split;
        }

        # count of substrings in scalar context
        else {
            carp "Use of implicit split to \@_ is deprecated" if $^W;
            @_ = @split;
            return scalar @_;
        }
    }

    # split's first argument is more consistently interpreted
    #
    # After some changes earlier in v5.17, split's behavior has been simplified:
    # if the PATTERN argument evaluates to a string containing one space, it is
    # treated the way that a literal string containing one space once was.
    # http://search.cpan.org/dist/perl-5.18.0/pod/perldelta.pod#split's_first_argument_is_more_consistently_interpreted

    # if $pattern is also omitted or is the literal space, " ", the function splits
    # on whitespace, /\s+/, after skipping any leading whitespace
    # (and so on)

    elsif ($pattern eq ' ') {
        if (not defined $limit) {
            return CORE::split(' ', $string);
        }
        else {
            return CORE::split(' ', $string, $limit);
        }
    }

    local $q_char = $q_char;
    if (CORE::length($string) > 32766) {
        if ($string =~ /\A [\x00-\x7F]+ \z/oxms) {
            $q_char = qr{.}s;
        }
        elsif (defined ${Ekps9566::q_char_SADAHIRO_Tomoyuki_2002_01_17}) {
            $q_char = ${Ekps9566::q_char_SADAHIRO_Tomoyuki_2002_01_17};
        }
    }

    # if $limit is negative, it is treated as if an arbitrarily large $limit has been specified
    if ((not defined $limit) or ($limit <= 0)) {

        # a pattern capable of matching either the null string or something longer than the
        # null string will split the value of $string into separate characters wherever it
        # matches the null string between characters
        # (and so on)

        if ('' =~ / \A $pattern \z /xms) {
            my $last_subexpression_offsets = _last_subexpression_offsets($pattern);
            my $limit = scalar(() = $string =~ /($pattern)/oxmsg);

            # P.1024 Appendix W.10 Multibyte Processing
            # of ISBN 1-56592-224-7 CJKV Information Processing
            # (and so on)

            # the //m modifier is assumed when you split on the pattern /^/
            # (and so on)

            #                                                     V
            while ((--$limit > 0) and ($string =~ s/\A((?:$q_char)+?)$pattern//m)) {

                # if the $pattern contains parentheses, then the substring matched by each pair of parentheses
                # is included in the resulting list, interspersed with the fields that are ordinarily returned
                # (and so on)

                local $@;
                for (my $digit=1; $digit <= ($last_subexpression_offsets + 1); $digit++) {
                    push @split, CORE::eval('$' . $digit);
                }
            }
        }

        else {
            my $last_subexpression_offsets = _last_subexpression_offsets($pattern);

            #                                 V
            while ($string =~ s/\A((?:$q_char)*?)$pattern//m) {
                local $@;
                for (my $digit=1; $digit <= ($last_subexpression_offsets + 1); $digit++) {
                    push @split, CORE::eval('$' . $digit);
                }
            }
        }
    }

    elsif ($limit > 0) {
        if ('' =~ / \A $pattern \z /xms) {
            my $last_subexpression_offsets = _last_subexpression_offsets($pattern);
            while ((--$limit > 0) and (CORE::length($string) > 0)) {

                #                              V
                if ($string =~ s/\A((?:$q_char)+?)$pattern//m) {
                    local $@;
                    for (my $digit=1; $digit <= ($last_subexpression_offsets + 1); $digit++) {
                        push @split, CORE::eval('$' . $digit);
                    }
                }
            }
        }
        else {
            my $last_subexpression_offsets = _last_subexpression_offsets($pattern);
            while ((--$limit > 0) and (CORE::length($string) > 0)) {

                #                              V
                if ($string =~ s/\A((?:$q_char)*?)$pattern//m) {
                    local $@;
                    for (my $digit=1; $digit <= ($last_subexpression_offsets + 1); $digit++) {
                        push @split, CORE::eval('$' . $digit);
                    }
                }
            }
        }
    }

    if (CORE::length($string) > 0) {
        push @split, $string;
    }

    # if $_[2] (NOT "$limit") is omitted or zero, trailing null fields are stripped from the result
    if ((not defined $_[2]) or ($_[2] == 0)) {
        while ((scalar(@split) >= 1) and ($split[-1] eq '')) {
            pop @split;
        }
    }

    # resulting list value in list context
    if (wantarray) {
        return @split;
    }

    # count of substrings in scalar context
    else {
        carp "Use of implicit split to \@_ is deprecated" if $^W;
        @_ = @split;
        return scalar @_;
    }
}

#
# get last subexpression offsets
#
sub _last_subexpression_offsets {
    my $pattern = $_[0];

    # remove comment
    $pattern =~ s/\(\?\# .*? \)//oxmsg;

    my $modifier = '';
    if ($pattern =~ /\(\?\^? ([\-A-Za-z]+) :/oxms) {
        $modifier = $1;
        $modifier =~ s/-[A-Za-z]*//;
    }

    # with /x modifier
    my @char = ();
    if ($modifier =~ /x/oxms) {
        @char = $pattern =~ /\G((?>
            [^\x81-\xFE\\\#\[\(]|[\x81-\xFE][\x00-\xFF] |
            \\ $q_char      |
            \# (?>[^\n]*) $ |
            \[ (?>(?:[^\x81-\xFE\\\]]|[\x81-\xFE][\x00-\xFF]|\\\\|\\\]|$q_char)+) \] |
            \(\?            |
                $q_char
        ))/oxmsg;
    }

    # without /x modifier
    else {
        @char = $pattern =~ /\G((?>
            [^\x81-\xFE\\\[\(]|[\x81-\xFE][\x00-\xFF] |
            \\ $q_char      |
            \[ (?>(?:[^\x81-\xFE\\\]]|[\x81-\xFE][\x00-\xFF]|\\\\|\\\]|$q_char)+) \] |
            \(\?            |
                $q_char
        ))/oxmsg;
    }

    return scalar grep { $_ eq '(' } @char;
}

#
# KPS9566 transliteration (tr///)
#
sub Ekps9566::tr($$$$;$) {

    my $bind_operator   = $_[1];
    my $searchlist      = $_[2];
    my $replacementlist = $_[3];
    my $modifier        = $_[4] || '';

    if ($modifier =~ /r/oxms) {
        if ($bind_operator =~ / !~ /oxms) {
            croak "Using !~ with tr///r doesn't make sense";
        }
    }

    my @char            = $_[0] =~ /\G (?>$q_char) /oxmsg;
    my @searchlist      = _charlist_tr($searchlist);
    my @replacementlist = _charlist_tr($replacementlist);

    my %tr = ();
    for (my $i=0; $i <= $#searchlist; $i++) {
        if (not exists $tr{$searchlist[$i]}) {
            if (defined $replacementlist[$i] and ($replacementlist[$i] ne '')) {
                $tr{$searchlist[$i]} = $replacementlist[$i];
            }
            elsif ($modifier =~ /d/oxms) {
                $tr{$searchlist[$i]} = '';
            }
            elsif (defined $replacementlist[-1] and ($replacementlist[-1] ne '')) {
                $tr{$searchlist[$i]} = $replacementlist[-1];
            }
            else {
                $tr{$searchlist[$i]} = $searchlist[$i];
            }
        }
    }

    my $tr = 0;
    my $replaced = '';
    if ($modifier =~ /c/oxms) {
        while (defined(my $char = shift @char)) {
            if (not exists $tr{$char}) {
                if (defined $replacementlist[0]) {
                    $replaced .= $replacementlist[0];
                }
                $tr++;
                if ($modifier =~ /s/oxms) {
                    while (@char and (not exists $tr{$char[0]})) {
                        shift @char;
                        $tr++;
                    }
                }
            }
            else {
                $replaced .= $char;
            }
        }
    }
    else {
        while (defined(my $char = shift @char)) {
            if (exists $tr{$char}) {
                $replaced .= $tr{$char};
                $tr++;
                if ($modifier =~ /s/oxms) {
                    while (@char and (exists $tr{$char[0]}) and ($tr{$char[0]} eq $tr{$char})) {
                        shift @char;
                        $tr++;
                    }
                }
            }
            else {
                $replaced .= $char;
            }
        }
    }

    if ($modifier =~ /r/oxms) {
        return $replaced;
    }
    else {
        $_[0] = $replaced;
        if ($bind_operator =~ / !~ /oxms) {
            return not $tr;
        }
        else {
            return $tr;
        }
    }
}

#
# KPS9566 chop
#
sub Ekps9566::chop(@) {

    my $chop;
    if (@_ == 0) {
        my @char = /\G (?>$q_char) /oxmsg;
        $chop = pop @char;
        $_ = join '', @char;
    }
    else {
        for (@_) {
            my @char = /\G (?>$q_char) /oxmsg;
            $chop = pop @char;
            $_ = join '', @char;
        }
    }
    return $chop;
}

#
# KPS9566 index by octet
#
sub Ekps9566::index($$;$) {

    my($str,$substr,$position) = @_;
    $position ||= 0;
    my $pos = 0;

    while ($pos < CORE::length($str)) {
        if (CORE::substr($str,$pos,CORE::length($substr)) eq $substr) {
            if ($pos >= $position) {
                return $pos;
            }
        }
        if (CORE::substr($str,$pos) =~ /\A ($q_char) /oxms) {
            $pos += CORE::length($1);
        }
        else {
            $pos += 1;
        }
    }
    return -1;
}

#
# KPS9566 reverse index
#
sub Ekps9566::rindex($$;$) {

    my($str,$substr,$position) = @_;
    $position ||= CORE::length($str) - 1;
    my $pos = 0;
    my $rindex = -1;

    while (($pos < CORE::length($str)) and ($pos <= $position)) {
        if (CORE::substr($str,$pos,CORE::length($substr)) eq $substr) {
            $rindex = $pos;
        }
        if (CORE::substr($str,$pos) =~ /\A ($q_char) /oxms) {
            $pos += CORE::length($1);
        }
        else {
            $pos += 1;
        }
    }
    return $rindex;
}

#
# KPS9566 lower case first with parameter
#
sub Ekps9566::lcfirst(@) {
    if (@_) {
        my $s = shift @_;
        if (@_ and wantarray) {
            return Ekps9566::lc(CORE::substr($s,0,1)) . CORE::substr($s,1), @_;
        }
        else {
            return Ekps9566::lc(CORE::substr($s,0,1)) . CORE::substr($s,1);
        }
    }
    else {
        return Ekps9566::lc(CORE::substr($_,0,1)) . CORE::substr($_,1);
    }
}

#
# KPS9566 lower case first without parameter
#
sub Ekps9566::lcfirst_() {
    return Ekps9566::lc(CORE::substr($_,0,1)) . CORE::substr($_,1);
}

#
# KPS9566 lower case with parameter
#
sub Ekps9566::lc(@) {
    if (@_) {
        my $s = shift @_;
        if (@_ and wantarray) {
            return join('', map {defined($lc{$_}) ? $lc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg)), @_;
        }
        else {
            return join('', map {defined($lc{$_}) ? $lc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg));
        }
    }
    else {
        return Ekps9566::lc_();
    }
}

#
# KPS9566 lower case without parameter
#
sub Ekps9566::lc_() {
    my $s = $_;
    return join '', map {defined($lc{$_}) ? $lc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg);
}

#
# KPS9566 upper case first with parameter
#
sub Ekps9566::ucfirst(@) {
    if (@_) {
        my $s = shift @_;
        if (@_ and wantarray) {
            return Ekps9566::uc(CORE::substr($s,0,1)) . CORE::substr($s,1), @_;
        }
        else {
            return Ekps9566::uc(CORE::substr($s,0,1)) . CORE::substr($s,1);
        }
    }
    else {
        return Ekps9566::uc(CORE::substr($_,0,1)) . CORE::substr($_,1);
    }
}

#
# KPS9566 upper case first without parameter
#
sub Ekps9566::ucfirst_() {
    return Ekps9566::uc(CORE::substr($_,0,1)) . CORE::substr($_,1);
}

#
# KPS9566 upper case with parameter
#
sub Ekps9566::uc(@) {
    if (@_) {
        my $s = shift @_;
        if (@_ and wantarray) {
            return join('', map {defined($uc{$_}) ? $uc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg)), @_;
        }
        else {
            return join('', map {defined($uc{$_}) ? $uc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg));
        }
    }
    else {
        return Ekps9566::uc_();
    }
}

#
# KPS9566 upper case without parameter
#
sub Ekps9566::uc_() {
    my $s = $_;
    return join '', map {defined($uc{$_}) ? $uc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg);
}

#
# KPS9566 fold case with parameter
#
sub Ekps9566::fc(@) {
    if (@_) {
        my $s = shift @_;
        if (@_ and wantarray) {
            return join('', map {defined($fc{$_}) ? $fc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg)), @_;
        }
        else {
            return join('', map {defined($fc{$_}) ? $fc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg));
        }
    }
    else {
        return Ekps9566::fc_();
    }
}

#
# KPS9566 fold case without parameter
#
sub Ekps9566::fc_() {
    my $s = $_;
    return join '', map {defined($fc{$_}) ? $fc{$_} : $_} ($s =~ /\G ($q_char) /oxmsg);
}

#
# KPS9566 regexp capture
#
{
    # 10.3. Creating Persistent Private Variables
    # in Chapter 10. Subroutines
    # of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.

    my $last_s_matched = 0;

    sub Ekps9566::capture {
        if ($last_s_matched and ($_[0] =~ /\A (?>[1-9][0-9]*) \z/oxms)) {
            return $_[0] + 1;
        }
        return $_[0];
    }

    # KPS9566 mark last regexp matched
    sub Ekps9566::matched() {
        $last_s_matched = 0;
    }

    # KPS9566 mark last s/// matched
    sub Ekps9566::s_matched() {
        $last_s_matched = 1;
    }

    # P.854 31.17. use re
    # in Chapter 31. Pragmatic Modules
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.1026 re
    # in Chapter 29. Pragmatic Modules
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    $Ekps9566::matched = qr/(?{Ekps9566::matched})/;
}

#
# KPS9566 regexp ignore case modifier
#
sub Ekps9566::ignorecase {

    my @string = @_;
    my $metachar = qr/[\@\\|[\]{]/oxms;

    # ignore case of $scalar or @array
    for my $string (@string) {

        # split regexp
        my @char = $string =~ /\G (?>\[\^|\\$q_char|$q_char) /oxmsg;

        # unescape character
        for (my $i=0; $i <= $#char; $i++) {
            next if not defined $char[$i];

            # open character class [...]
            if ($char[$i] eq '[') {
                my $left = $i;

                # [] make die "unmatched [] in regexp ...\n"

                if ($char[$i+1] eq ']') {
                    $i++;
                }

                while (1) {
                    if (++$i > $#char) {
                        croak "Unmatched [] in regexp";
                    }
                    if ($char[$i] eq ']') {
                        my $right = $i;
                        my @charlist = charlist_qr(@char[$left+1..$right-1], 'i');

                        # escape character
                        for my $char (@charlist) {
                            if (0) {
                            }

                            # do not use quotemeta here
                            elsif ($char =~ /\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
                                $char = $1 . '\\' . $2;
                            }
                            elsif ($char =~ /\A [.|)] \z/oxms) {
                                $char = '\\' . $char;
                            }
                        }

                        # [...]
                        splice @char, $left, $right-$left+1, '(?:' . join('|', @charlist) . ')';

                        $i = $left;
                        last;
                    }
                }
            }

            # open character class [^...]
            elsif ($char[$i] eq '[^') {
                my $left = $i;

                # [^] make die "unmatched [] in regexp ...\n"

                if ($char[$i+1] eq ']') {
                    $i++;
                }

                while (1) {
                    if (++$i > $#char) {
                        croak "Unmatched [] in regexp";
                    }
                    if ($char[$i] eq ']') {
                        my $right = $i;
                        my @charlist = charlist_not_qr(@char[$left+1..$right-1], 'i');

                        # escape character
                        for my $char (@charlist) {
                            if (0) {
                            }

                            # do not use quotemeta here
                            elsif ($char =~ /\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
                                $char = $1 . '\\' . $2;
                            }
                            elsif ($char =~ /\A [.|)] \z/oxms) {
                                $char = '\\' . $char;
                            }
                        }

                        # [^...]
                        splice @char, $left, $right-$left+1, '(?!' . join('|', @charlist) . ")(?:$your_char)";

                        $i = $left;
                        last;
                    }
                }
            }

            # rewrite classic character class or escape character
            elsif (my $char = classic_character_class($char[$i])) {
                $char[$i] = $char;
            }

            # with /i modifier
            elsif ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) {
                my $uc = Ekps9566::uc($char[$i]);
                my $fc = Ekps9566::fc($char[$i]);
                if ($uc ne $fc) {
                    if (CORE::length($fc) == 1) {
                        $char[$i] = '['   . $uc       . $fc . ']';
                    }
                    else {
                        $char[$i] = '(?:' . $uc . '|' . $fc . ')';
                    }
                }
            }
        }

        # characterize
        for (my $i=0; $i <= $#char; $i++) {
            next if not defined $char[$i];

            if (0) {
            }

            # escape last octet of multiple-octet
            elsif ($char[$i] =~ /\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
                $char[$i] = $1 . '\\' . $2;
            }

            # quote character before ? + * {
            elsif (($i >= 1) and ($char[$i] =~ /\A [\?\+\*\{] \z/oxms)) {
                if ($char[$i-1] !~ /\A [\x00-\xFF] \z/oxms) {
                    $char[$i-1] = '(?:' . $char[$i-1] . ')';
                }
            }
        }

        $string = join '', @char;
    }

    # make regexp string
    return @string;
}

#
# classic character class ( \D \S \W \d \s \w \C \X \H \V \h \v \R \N \b \B )
#
sub Ekps9566::classic_character_class {
    my($char) = @_;

    return {
        '\D' => '${Ekps9566::eD}',
        '\S' => '${Ekps9566::eS}',
        '\W' => '${Ekps9566::eW}',
        '\d' => '[0-9]',

        # Before Perl 5.6, \s only matched the five whitespace characters
        # tab, newline, form-feed, carriage return, and the space character
        # itself, which, taken together, is the character class [\t\n\f\r ].

        # Vertical tabs are now whitespace
        # \s in a regex now matches a vertical tab in all circumstances.
        # http://search.cpan.org/dist/perl-5.18.0/pod/perldelta.pod#Vertical_tabs_are_now_whitespace
        #            \t  \n  \v  \f  \r space
        # '\s' => '[\x09\x0A    \x0C\x0D\x20]',
        # '\s' => '[\x09\x0A\x0B\x0C\x0D\x20]',
        '\s'   => '\s',

        '\w' => '[0-9A-Z_a-z]',
        '\C' => '[\x00-\xFF]',
        '\X' => 'X',

        # \h \v \H \V

        # P.114 Character Class Shortcuts
        # in Chapter 7: In the World of Regular Expressions
        # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

        # P.357 13.2.3 Whitespace
        # in Chapter 13: perlrecharclass: Perl Regular Expression Character Classes
        # of ISBN-13: 978-1-906966-02-7 The Perl Language Reference Manual (for Perl version 5.12.1)
        #
        # 0x00009   CHARACTER TABULATION  h s
        # 0x0000a         LINE FEED (LF)   vs
        # 0x0000b        LINE TABULATION   v
        # 0x0000c         FORM FEED (FF)   vs
        # 0x0000d   CARRIAGE RETURN (CR)   vs
        # 0x00020                  SPACE  h s

        # P.196 Table 5-9. Alphanumeric regex metasymbols
        # in Chapter 5. Pattern Matching
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        # (and so on)

        '\H' => '${Ekps9566::eH}',
        '\V' => '${Ekps9566::eV}',
        '\h' => '[\x09\x20]',
        '\v' => '[\x0A\x0B\x0C\x0D]',
        '\R' => '${Ekps9566::eR}',

        # \N
        #
        # http://perldoc.perl.org/perlre.html
        # Character Classes and other Special Escapes
        # Any character but \n (experimental). Not affected by /s modifier

        '\N' => '${Ekps9566::eN}',

        # \b \B

        # P.180 Boundaries: The \b and \B Assertions
        # in Chapter 5: Pattern Matching
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # P.219 Boundaries: The \b and \B Assertions
        # in Chapter 5: Pattern Matching
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        # \b really means (?:(?<=\w)(?!\w)|(?<!\w)(?=\w))
        #           or (?:(?<=\A|\W)(?=\w)|(?<=\w)(?=\W|\z))
        '\b' => '${Ekps9566::eb}',

        # \B really means (?:(?<=\w)(?=\w)|(?<!\w)(?!\w))
        #              or (?:(?<=\w)(?=\w)|(?<=\W)(?=\W))
        '\B' => '${Ekps9566::eB}',

    }->{$char} || '';
}

#
# prepare KPS9566 characters per length
#

# 1 octet characters
my @chars1 = ();
sub chars1 {
    if (@chars1) {
        return @chars1;
    }
    if (exists $range_tr{1}) {
        my @ranges = @{ $range_tr{1} };
        while (my @range = splice(@ranges,0,1)) {
            for my $oct0 (@{$range[0]}) {
                push @chars1, pack 'C', $oct0;
            }
        }
    }
    return @chars1;
}

# 2 octets characters
my @chars2 = ();
sub chars2 {
    if (@chars2) {
        return @chars2;
    }
    if (exists $range_tr{2}) {
        my @ranges = @{ $range_tr{2} };
        while (my @range = splice(@ranges,0,2)) {
            for my $oct0 (@{$range[0]}) {
                for my $oct1 (@{$range[1]}) {
                    push @chars2, pack 'CC', $oct0,$oct1;
                }
            }
        }
    }
    return @chars2;
}

# 3 octets characters
my @chars3 = ();
sub chars3 {
    if (@chars3) {
        return @chars3;
    }
    if (exists $range_tr{3}) {
        my @ranges = @{ $range_tr{3} };
        while (my @range = splice(@ranges,0,3)) {
            for my $oct0 (@{$range[0]}) {
                for my $oct1 (@{$range[1]}) {
                    for my $oct2 (@{$range[2]}) {
                        push @chars3, pack 'CCC', $oct0,$oct1,$oct2;
                    }
                }
            }
        }
    }
    return @chars3;
}

# 4 octets characters
my @chars4 = ();
sub chars4 {
    if (@chars4) {
        return @chars4;
    }
    if (exists $range_tr{4}) {
        my @ranges = @{ $range_tr{4} };
        while (my @range = splice(@ranges,0,4)) {
            for my $oct0 (@{$range[0]}) {
                for my $oct1 (@{$range[1]}) {
                    for my $oct2 (@{$range[2]}) {
                        for my $oct3 (@{$range[3]}) {
                            push @chars4, pack 'CCCC', $oct0,$oct1,$oct2,$oct3;
                        }
                    }
                }
            }
        }
    }
    return @chars4;
}

#
# KPS9566 open character list for tr
#
sub _charlist_tr {

    local $_ = shift @_;

    # unescape character
    my @char = ();
    while (not /\G \z/oxmsgc) {
        if (/\G (\\0?55|\\x2[Dd]|\\-) /oxmsgc) {
            push @char, '\-';
        }
        elsif (/\G \\ ([0-7]{2,3}) /oxmsgc) {
            push @char, CORE::chr(oct $1);
        }
        elsif (/\G \\x ([0-9A-Fa-f]{1,2}) /oxmsgc) {
            push @char, CORE::chr(hex $1);
        }
        elsif (/\G \\c ([\x40-\x5F]) /oxmsgc) {
            push @char, CORE::chr(CORE::ord($1) & 0x1F);
        }
        elsif (/\G (\\ [0nrtfbae]) /oxmsgc) {
            push @char, {
                '\0' => "\0",
                '\n' => "\n",
                '\r' => "\r",
                '\t' => "\t",
                '\f' => "\f",
                '\b' => "\x08", # \b means backspace in character class
                '\a' => "\a",
                '\e' => "\e",
            }->{$1};
        }
        elsif (/\G \\ ($q_char) /oxmsgc) {
            push @char, $1;
        }
        elsif (/\G ($q_char) /oxmsgc) {
            push @char, $1;
        }
    }

    # join separated multiple-octet
    @char = join('',@char) =~ /\G (?>\\-|$q_char) /oxmsg;

    # unescape '-'
    my @i = ();
    for my $i (0 .. $#char) {
        if ($char[$i] eq '\-') {
            $char[$i] = '-';
        }
        elsif ($char[$i] eq '-') {
            if ((0 < $i) and ($i < $#char)) {
                push @i, $i;
            }
        }
    }

    # open character list (reverse for splice)
    for my $i (CORE::reverse @i) {
        my @range = ();

        # range error
        if ((CORE::length($char[$i-1]) > CORE::length($char[$i+1])) or ($char[$i-1] gt $char[$i+1])) {
            croak "Invalid tr/// range \"\\x" . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]) . '"';
        }

        # range of multiple-octet code
        if (CORE::length($char[$i-1]) == 1) {
            if (CORE::length($char[$i+1]) == 1) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} chars1();
            }
            elsif (CORE::length($char[$i+1]) == 2) {
                push @range, grep {$char[$i-1] le $_}                           chars1();
                push @range, grep {$_ le $char[$i+1]}                           chars2();
            }
            elsif (CORE::length($char[$i+1]) == 3) {
                push @range, grep {$char[$i-1] le $_}                           chars1();
                push @range,                                                    chars2();
                push @range, grep {$_ le $char[$i+1]}                           chars3();
            }
            elsif (CORE::length($char[$i+1]) == 4) {
                push @range, grep {$char[$i-1] le $_}                           chars1();
                push @range,                                                    chars2();
                push @range,                                                    chars3();
                push @range, grep {$_ le $char[$i+1]}                           chars4();
            }
            else {
                croak "Invalid tr/// range (over 4octets) \"\\x" . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]) . '"';
            }
        }
        elsif (CORE::length($char[$i-1]) == 2) {
            if (CORE::length($char[$i+1]) == 2) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} chars2();
            }
            elsif (CORE::length($char[$i+1]) == 3) {
                push @range, grep {$char[$i-1] le $_}                           chars2();
                push @range, grep {$_ le $char[$i+1]}                           chars3();
            }
            elsif (CORE::length($char[$i+1]) == 4) {
                push @range, grep {$char[$i-1] le $_}                           chars2();
                push @range,                                                    chars3();
                push @range, grep {$_ le $char[$i+1]}                           chars4();
            }
            else {
                croak "Invalid tr/// range (over 4octets) \"\\x" . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]) . '"';
            }
        }
        elsif (CORE::length($char[$i-1]) == 3) {
            if (CORE::length($char[$i+1]) == 3) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} chars3();
            }
            elsif (CORE::length($char[$i+1]) == 4) {
                push @range, grep {$char[$i-1] le $_}                           chars3();
                push @range, grep {$_ le $char[$i+1]}                           chars4();
            }
            else {
                croak "Invalid tr/// range (over 4octets) \"\\x" . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]) . '"';
            }
        }
        elsif (CORE::length($char[$i-1]) == 4) {
            if (CORE::length($char[$i+1]) == 4) {
                push @range, grep {($char[$i-1] le $_) and ($_ le $char[$i+1])} chars4();
            }
            else {
                croak "Invalid tr/// range (over 4octets) \"\\x" . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]) . '"';
            }
        }
        else {
            croak "Invalid tr/// range (over 4octets) \"\\x" . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]) . '"';
        }

        splice @char, $i-1, 3, @range;
    }

    return @char;
}

#
# KPS9566 open character class
#
sub _cc {
    if (scalar(@_) == 0) {
        die __FILE__, ": subroutine cc got no parameter.\n";
    }
    elsif (scalar(@_) == 1) {
        return sprintf('\x%02X',$_[0]);
    }
    elsif (scalar(@_) == 2) {
        if ($_[0] > $_[1]) {
            die __FILE__, ": subroutine cc got \$_[0] > \$_[1] parameters).\n";
        }
        elsif ($_[0] == $_[1]) {
            return sprintf('\x%02X',$_[0]);
        }
        elsif (($_[0]+1) == $_[1]) {
            return sprintf('[\\x%02X\\x%02X]',$_[0],$_[1]);
        }
        else {
            return sprintf('[\\x%02X-\\x%02X]',$_[0],$_[1]);
        }
    }
    else {
        die __FILE__, ": subroutine cc got 3 or more parameters (@{[scalar(@_)]} parameters).\n";
    }
}

#
# KPS9566 octet range
#
sub _octets {
    my $length = shift @_;

    if ($length == 1) {
        my($a1) = unpack 'C', $_[0];
        my($z1) = unpack 'C', $_[1];

        if ($a1 > $z1) {
            croak 'Invalid [] range in regexp (CORE::ord(A) > CORE::ord(B)) ' . '\x' . unpack('H*',$a1) . '-\x' . unpack('H*',$z1);
        }

        if ($a1 == $z1) {
            return sprintf('\x%02X',$a1);
        }
        elsif (($a1+1) == $z1) {
            return sprintf('\x%02X\x%02X',$a1,$z1);
        }
        else {
            return sprintf('\x%02X-\x%02X',$a1,$z1);
        }
    }
    elsif ($length == 2) {
        my($a1,$a2) = unpack 'CC', $_[0];
        my($z1,$z2) = unpack 'CC', $_[1];
        my($A1,$A2) = unpack 'CC', $_[2];
        my($Z1,$Z2) = unpack 'CC', $_[3];

        if ($a1 == $z1) {
            return (
            #   11111111   222222222222
            #        A          A   Z
                _cc($a1) . _cc($a2,$z2), # a2-z2
            );
        }
        elsif (($a1+1) == $z1) {
            return (
            #   11111111111   222222222222
            #        A  Z          A   Z
                _cc($a1)    . _cc($a2,$Z2), # a2-
                _cc(   $z1) . _cc($A2,$z2), #   -z2
            );
        }
        else {
            return (
            #   1111111111111111   222222222222
            #        A     Z            A   Z
                _cc($a1)         . _cc($a2,$Z2), # a2-
                _cc($a1+1,$z1-1) . _cc($A2,$Z2), #   -
                _cc(      $z1)   . _cc($A2,$z2), #   -z2
            );
        }
    }
    elsif ($length == 3) {
        my($a1,$a2,$a3) = unpack 'CCC', $_[0];
        my($z1,$z2,$z3) = unpack 'CCC', $_[1];
        my($A1,$A2,$A3) = unpack 'CCC', $_[2];
        my($Z1,$Z2,$Z3) = unpack 'CCC', $_[3];

        if ($a1 == $z1) {
            if ($a2 == $z2) {
                return (
                #   11111111   22222222   333333333333
                #        A          A          A   Z
                    _cc($a1) . _cc($a2) . _cc($a3,$z3), # a3-z3
                );
            }
            elsif (($a2+1) == $z2) {
                return (
                #   11111111   22222222222   333333333333
                #        A          A  Z          A   Z
                    _cc($a1) . _cc($a2)    . _cc($a3,$Z3), # a3-
                    _cc($a1) . _cc(   $z2) . _cc($A3,$z3), #   -z3
                );
            }
            else {
                return (
                #   11111111   2222222222222222   333333333333
                #        A          A     Z            A   Z
                    _cc($a1) . _cc($a2)         . _cc($a3,$Z3), # a3-
                    _cc($a1) . _cc($a2+1,$z2-1) . _cc($A3,$Z3), #   -
                    _cc($a1) . _cc(      $z2)   . _cc($A3,$z3), #   -z3
                );
            }
        }
        elsif (($a1+1) == $z1) {
            return (
            #   11111111111   22222222222222   333333333333
            #        A  Z          A     Z          A   Z
                _cc($a1)    . _cc($a2)       . _cc($a3,$Z3), # a3-
                _cc($a1)    . _cc($a2+1,$Z2) . _cc($A3,$Z3), #   -
                _cc(   $z1) . _cc($A2,$z2-1) . _cc($A3,$Z3), #   -
                _cc(   $z1) . _cc(    $z2)   . _cc($A3,$z3), #   -z3
            );
        }
        else {
            return (
            #   1111111111111111   22222222222222   333333333333
            #        A     Z            A     Z          A   Z
                _cc($a1)         . _cc($a2)       . _cc($a3,$Z3), # a3-
                _cc($a1)         . _cc($a2+1,$Z2) . _cc($A3,$Z3), #   -
                _cc($a1+1,$z1-1) . _cc($A2,$Z2)   . _cc($A3,$Z3), #   -
                _cc(      $z1)   . _cc($A2,$z2-1) . _cc($A3,$Z3), #   -
                _cc(      $z1)   . _cc(    $z2)   . _cc($A3,$z3), #   -z3
            );
        }
    }
    elsif ($length == 4) {
        my($a1,$a2,$a3,$a4) = unpack 'CCCC', $_[0];
        my($z1,$z2,$z3,$z4) = unpack 'CCCC', $_[1];
        my($A1,$A2,$A3,$A4) = unpack 'CCCC', $_[0];
        my($Z1,$Z2,$Z3,$Z4) = unpack 'CCCC', $_[1];

        if ($a1 == $z1) {
            if ($a2 == $z2) {
                if ($a3 == $z3) {
                    return (
                    #   11111111   22222222   33333333   444444444444
                    #        A          A          A          A   Z
                        _cc($a1) . _cc($a2) . _cc($a3) . _cc($a4,$z4), # a4-z4
                    );
                }
                elsif (($a3+1) == $z3) {
                    return (
                    #   11111111   22222222   33333333333   444444444444
                    #        A          A          A  Z          A   Z
                        _cc($a1) . _cc($a2) . _cc($a3)    . _cc($a4,$Z4), # a4-
                        _cc($a1) . _cc($a2) . _cc(   $z3) . _cc($A4,$z4), #   -z4
                    );
                }
                else {
                    return (
                    #   11111111   22222222   3333333333333333   444444444444
                    #        A          A          A     Z            A   Z
                        _cc($a1) . _cc($a2) . _cc($a3)         . _cc($a4,$Z4), # a4-
                        _cc($a1) . _cc($a2) . _cc($a3+1,$z3-1) . _cc($A4,$Z4), #   -
                        _cc($a1) . _cc($a2) . _cc(      $z3)   . _cc($A4,$z4), #   -z4
                    );
                }
            }
            elsif (($a2+1) == $z2) {
                return (
                #   11111111   22222222222   33333333333333   444444444444
                #        A          A  Z          A     Z          A   Z
                    _cc($a1) . _cc($a2)    . _cc($a3)       . _cc($a4,$Z4), # a4-
                    _cc($a1) . _cc($a2)    . _cc($a3+1,$Z3) . _cc($A4,$Z4), #   -
                    _cc($a1) . _cc(   $z2) . _cc($A3,$z3-1) . _cc($A4,$Z4), #   -
                    _cc($a1) . _cc(   $z2) . _cc(    $z3)   . _cc($A4,$z4), #   -z4
                );
            }
            else {
                return (
                #   11111111   2222222222222222   33333333333333   444444444444
                #        A          A     Z            A     Z          A   Z
                    _cc($a1) . _cc($a2)         . _cc($a3)       . _cc($a4,$Z4), # a4-
                    _cc($a1) . _cc($a2)         . _cc($a3+1,$Z3) . _cc($A4,$Z4), #   -
                    _cc($a1) . _cc($a2+1,$z2-1) . _cc($A3,$Z3)   . _cc($A4,$Z4), #   -
                    _cc($a1) . _cc(      $z2)   . _cc($A3,$z3-1) . _cc($A4,$Z4), #   -
                    _cc($a1) . _cc(      $z2)   . _cc(    $z3)   . _cc($A4,$z4), #   -z4
                );
            }
        }
        elsif (($a1+1) == $z1) {
            return (
            #   11111111111   22222222222222   33333333333333   444444444444
            #        A  Z          A     Z          A     Z          A   Z
                _cc($a1)    . _cc($a2)       . _cc($a3)       . _cc($a4,$Z4), # a4-
                _cc($a1)    . _cc($a2)       . _cc($a3+1,$Z3) . _cc($A4,$Z4), #   -
                _cc($a1)    . _cc($a2+1,$Z2) . _cc($A3,$Z3)   . _cc($A4,$Z4), #   -
                _cc(   $z1) . _cc($A2,$z2-1) . _cc($A3,$Z3)   . _cc($A4,$Z4), #   -
                _cc(   $z1) . _cc(    $z2)   . _cc($A3,$z3-1) . _cc($A4,$Z4), #   -
                _cc(   $z1) . _cc(    $z2)   . _cc(    $z3)   . _cc($A4,$z4), #   -z4
            );
        }
        else {
            return (
            #   1111111111111111   22222222222222   33333333333333   444444444444
            #        A     Z            A     Z          A     Z          A   Z
                _cc($a1)         . _cc($a2)       . _cc($a3)       . _cc($a4,$Z4), # a4-
                _cc($a1)         . _cc($a2)       . _cc($a3+1,$Z3) . _cc($A4,$Z4), #   -
                _cc($a1)         . _cc($a2+1,$Z2) . _cc($A3,$Z3)   . _cc($A4,$Z4), #   -
                _cc($a1+1,$z1-1) . _cc($A2,$Z2)   . _cc($A3,$Z3)   . _cc($A4,$Z4), #   -
                _cc(      $z1)   . _cc($A2,$z2-1) . _cc($A3,$Z3)   . _cc($A4,$Z4), #   -
                _cc(      $z1)   . _cc(    $z2)   . _cc($A3,$z3-1) . _cc($A4,$Z4), #   -
                _cc(      $z1)   . _cc(    $z2)   . _cc(    $z3)   . _cc($A4,$z4), #   -z4
            );
        }
    }
    else {
        die __FILE__, ": subroutine _octets got invalid length ($length).\n";
    }
}

#
# KPS9566 range regexp
#
sub _range_regexp {
    my($length,$first,$last) = @_;

    my @range_regexp = ();
    if (not exists $range_tr{$length}) {
        return @range_regexp;
    }

    my @ranges = @{ $range_tr{$length} };
    while (my @range = splice(@ranges,0,$length)) {
        my $min = '';
        my $max = '';
        for (my $i=0; $i < $length; $i++) {
            $min .= pack 'C', $range[$i][0];
            $max .= pack 'C', $range[$i][-1];
        }

# min___max
#            FIRST_____________LAST
#       (nothing)

        if ($max lt $first) {
        }

#            **********
#       min_________max
#            FIRST_____________LAST
#            **********

        elsif (($min le $first) and ($first le $max) and ($max le $last)) {
            push @range_regexp, _octets($length,$first,$max,$min,$max);
        }

#            **********************
#            min________________max
#            FIRST_____________LAST
#            **********************

        elsif (($min eq $first) and ($max eq $last)) {
            push @range_regexp, _octets($length,$first,$last,$min,$max);
        }

#                   *********
#                   min___max
#            FIRST_____________LAST
#                   *********

        elsif (($first le $min) and ($max le $last)) {
            push @range_regexp, _octets($length,$min,$max,$min,$max);
        }

#            **********************
#       min__________________________max
#            FIRST_____________LAST
#            **********************

        elsif (($min le $first) and ($last le $max)) {
            push @range_regexp, _octets($length,$first,$last,$min,$max);
        }

#                         *********
#                         min________max
#            FIRST_____________LAST
#                         *********

        elsif (($first le $min) and ($min le $last) and ($last le $max)) {
            push @range_regexp, _octets($length,$min,$last,$min,$max);
        }

#                                    min___max
#            FIRST_____________LAST
#                              (nothing)

        elsif ($last lt $min) {
        }

        else {
            die __FILE__, ": subroutine _range_regexp panic.\n";
        }
    }

    return @range_regexp;
}

#
# KPS9566 open character list for qr and not qr
#
sub _charlist {

    my $modifier = pop @_;
    my @char = @_;

    my $ignorecase = ($modifier =~ /i/oxms) ? 1 : 0;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {

        # escape - to ...
        if ($char[$i] eq '-') {
            if ((0 < $i) and ($i < $#char)) {
                $char[$i] = '...';
            }
        }

        # octal escape sequence
        elsif ($char[$i] =~ /\A \\o \{ ([0-7]+) \} \z/oxms) {
            $char[$i] = octchr($1);
        }

        # hexadecimal escape sequence
        elsif ($char[$i] =~ /\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            $char[$i] = hexchr($1);
        }

        # \b{...}      --> b\{...}
        # \B{...}      --> B\{...}
        # \N{CHARNAME} --> N\{CHARNAME}
        # \p{PROPERTY} --> p\{PROPERTY}
        # \P{PROPERTY} --> P\{PROPERTY}
        elsif ($char[$i] =~ /\A \\ ([bBNpP]) ( \{ ([^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} ) \z/oxms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # \p, \P, \X --> p, P, X
        elsif ($char[$i] =~ /\A \\ ( [pPX] ) \z/oxms) {
            $char[$i] = $1;
        }

        elsif ($char[$i] =~ /\A \\ ([0-7]{2,3}) \z/oxms) {
            $char[$i] = CORE::chr oct $1;
        }
        elsif ($char[$i] =~ /\A \\x ([0-9A-Fa-f]{1,2}) \z/oxms) {
            $char[$i] = CORE::chr hex $1;
        }
        elsif ($char[$i] =~ /\A \\c ([\x40-\x5F]) \z/oxms) {
            $char[$i] = CORE::chr(CORE::ord($1) & 0x1F);
        }
        elsif ($char[$i] =~ /\A (\\ [0nrtfbaedswDSWHVhvR]) \z/oxms) {
            $char[$i] = {
                '\0' => "\0",
                '\n' => "\n",
                '\r' => "\r",
                '\t' => "\t",
                '\f' => "\f",
                '\b' => "\x08", # \b means backspace in character class
                '\a' => "\a",
                '\e' => "\e",
                '\d' => '[0-9]',

                # Vertical tabs are now whitespace
                # \s in a regex now matches a vertical tab in all circumstances.
                # http://search.cpan.org/dist/perl-5.18.0/pod/perldelta.pod#Vertical_tabs_are_now_whitespace
                #            \t  \n  \v  \f  \r space
                # '\s' => '[\x09\x0A    \x0C\x0D\x20]',
                # '\s' => '[\x09\x0A\x0B\x0C\x0D\x20]',
                '\s'   => '\s',

                '\w' => '[0-9A-Z_a-z]',
                '\D' => '${Ekps9566::eD}',
                '\S' => '${Ekps9566::eS}',
                '\W' => '${Ekps9566::eW}',

                '\H' => '${Ekps9566::eH}',
                '\V' => '${Ekps9566::eV}',
                '\h' => '[\x09\x20]',
                '\v' => '[\x0A\x0B\x0C\x0D]',
                '\R' => '${Ekps9566::eR}',

            }->{$1};
        }

        # POSIX-style character classes
        elsif ($ignorecase and ($char[$i] =~ /\A ( \[\: \^? (?:lower|upper) :\] ) \z/oxms)) {
            $char[$i] = {

                '[:lower:]'   => '[\x41-\x5A\x61-\x7A]',
                '[:upper:]'   => '[\x41-\x5A\x61-\x7A]',
                '[:^lower:]'  => '${Ekps9566::not_lower_i}',
                '[:^upper:]'  => '${Ekps9566::not_upper_i}',

            }->{$1};
        }
        elsif ($char[$i] =~ /\A ( \[\: \^? (?:alnum|alpha|ascii|blank|cntrl|digit|graph|lower|print|punct|space|upper|word|xdigit) :\] ) \z/oxms) {
            $char[$i] = {

                '[:alnum:]'   => '[\x30-\x39\x41-\x5A\x61-\x7A]',
                '[:alpha:]'   => '[\x41-\x5A\x61-\x7A]',
                '[:ascii:]'   => '[\x00-\x7F]',
                '[:blank:]'   => '[\x09\x20]',
                '[:cntrl:]'   => '[\x00-\x1F\x7F]',
                '[:digit:]'   => '[\x30-\x39]',
                '[:graph:]'   => '[\x21-\x7F]',
                '[:lower:]'   => '[\x61-\x7A]',
                '[:print:]'   => '[\x20-\x7F]',
                '[:punct:]'   => '[\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E]',

                # P.174 POSIX-Style Character Classes
                # in Chapter 5: Pattern Matching
                # of ISBN 0-596-00027-8 Programming Perl Third Edition.

                # P.311 11.2.4 Character Classes and other Special Escapes
                # in Chapter 11: perlre: Perl regular expressions
                # of ISBN-13: 978-1-906966-02-7 The Perl Language Reference Manual (for Perl version 5.12.1)

                # P.210 POSIX-Style Character Classes
                # in Chapter 5: Pattern Matching
                # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

                '[:space:]'   => '[\s\x0B]', # "\s" plus vertical tab ("\cK")

                '[:upper:]'   => '[\x41-\x5A]',
                '[:word:]'    => '[\x30-\x39\x41-\x5A\x5F\x61-\x7A]',
                '[:xdigit:]'  => '[\x30-\x39\x41-\x46\x61-\x66]',
                '[:^alnum:]'  => '${Ekps9566::not_alnum}',
                '[:^alpha:]'  => '${Ekps9566::not_alpha}',
                '[:^ascii:]'  => '${Ekps9566::not_ascii}',
                '[:^blank:]'  => '${Ekps9566::not_blank}',
                '[:^cntrl:]'  => '${Ekps9566::not_cntrl}',
                '[:^digit:]'  => '${Ekps9566::not_digit}',
                '[:^graph:]'  => '${Ekps9566::not_graph}',
                '[:^lower:]'  => '${Ekps9566::not_lower}',
                '[:^print:]'  => '${Ekps9566::not_print}',
                '[:^punct:]'  => '${Ekps9566::not_punct}',
                '[:^space:]'  => '${Ekps9566::not_space}',
                '[:^upper:]'  => '${Ekps9566::not_upper}',
                '[:^word:]'   => '${Ekps9566::not_word}',
                '[:^xdigit:]' => '${Ekps9566::not_xdigit}',

            }->{$1};
        }
        elsif ($char[$i] =~ /\A \\ ($q_char) \z/oxms) {
            $char[$i] = $1;
        }
    }

    # open character list
    my @singleoctet   = ();
    my @multipleoctet = ();
    for (my $i=0; $i <= $#char; ) {

        # escaped -
        if (defined($char[$i+1]) and ($char[$i+1] eq '...')) {
            $i += 1;
            next;
        }

        # make range regexp
        elsif ($char[$i] eq '...') {

            # range error
            if (CORE::length($char[$i-1]) > CORE::length($char[$i+1])) {
                croak 'Invalid [] range in regexp (length(A) > length(B)) ' . '\x' . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]);
            }
            elsif (CORE::length($char[$i-1]) == CORE::length($char[$i+1])) {
                if ($char[$i-1] gt $char[$i+1]) {
                    croak 'Invalid [] range in regexp (CORE::ord(A) > CORE::ord(B)) ' . '\x' . unpack('H*',$char[$i-1]) . '-\x' . unpack('H*',$char[$i+1]);
                }
            }

            # make range regexp per length
            for my $length (CORE::length($char[$i-1]) .. CORE::length($char[$i+1])) {
                my @regexp = ();

                # is first and last
                if (($length == CORE::length($char[$i-1])) and ($length == CORE::length($char[$i+1]))) {
                    push @regexp, _range_regexp($length, $char[$i-1], $char[$i+1]);
                }

                # is first
                elsif ($length == CORE::length($char[$i-1])) {
                    push @regexp, _range_regexp($length, $char[$i-1], "\xFF" x $length);
                }

                # is inside in first and last
                elsif ((CORE::length($char[$i-1]) < $length) and ($length < CORE::length($char[$i+1]))) {
                    push @regexp, _range_regexp($length, "\x00" x $length, "\xFF" x $length);
                }

                # is last
                elsif ($length == CORE::length($char[$i+1])) {
                    push @regexp, _range_regexp($length, "\x00" x $length, $char[$i+1]);
                }

                else {
                    die __FILE__, ": subroutine make_regexp panic.\n";
                }

                if ($length == 1) {
                    push @singleoctet, @regexp;
                }
                else {
                    push @multipleoctet, @regexp;
                }
            }

            $i += 2;
        }

        # with /i modifier
        elsif ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) {
            if ($modifier =~ /i/oxms) {
                my $uc = Ekps9566::uc($char[$i]);
                my $fc = Ekps9566::fc($char[$i]);
                if ($uc ne $fc) {
                    if (CORE::length($fc) == 1) {
                        push @singleoctet, $uc, $fc;
                    }
                    else {
                        push @singleoctet,   $uc;
                        push @multipleoctet, $fc;
                    }
                }
                else {
                    push @singleoctet, $char[$i];
                }
            }
            else {
                push @singleoctet, $char[$i];
            }
            $i += 1;
        }

        # single character of single octet code
        elsif ($char[$i] =~ /\A (?: \\h ) \z/oxms) {
            push @singleoctet, "\t", "\x20";
            $i += 1;
        }
        elsif ($char[$i] =~ /\A (?: \\v ) \z/oxms) {
            push @singleoctet, "\x0A", "\x0B", "\x0C", "\x0D";
            $i += 1;
        }
        elsif ($char[$i] =~ /\A (?: \\d | \\s | \\w ) \z/oxms) {
            push @singleoctet, $char[$i];
            $i += 1;
        }

        # single character of multiple-octet code
        else {
            push @multipleoctet, $char[$i];
            $i += 1;
        }
    }

    # quote metachar
    for (@singleoctet) {
        if ($_ eq '...') {
            $_ = '-';
        }
        elsif (/\A \n \z/oxms) {
            $_ = '\n';
        }
        elsif (/\A \r \z/oxms) {
            $_ = '\r';
        }
        elsif (/\A ([\x00-\x20\x7F-\xFF]) \z/oxms) {
            $_ = sprintf('\x%02X', CORE::ord $1);
        }
        elsif (/\A [\x00-\xFF] \z/oxms) {
            $_ = quotemeta $_;
        }
    }
    for (@multipleoctet) {
        if (/\A ([\x80-\xFF].*) ([\x00-\xFF]) \z/oxms) {
            $_ = $1 . quotemeta $2;
        }
    }

    # return character list
    return \@singleoctet, \@multipleoctet;
}

#
# KPS9566 octal escape sequence
#
sub octchr {
    my($octdigit) = @_;

    my @binary = ();
    for my $octal (split(//,$octdigit)) {
        push @binary, {
            '0' => '000',
            '1' => '001',
            '2' => '010',
            '3' => '011',
            '4' => '100',
            '5' => '101',
            '6' => '110',
            '7' => '111',
        }->{$octal};
    }
    my $binary = join '', @binary;

    my $octchr = {
        #                1234567
        1 => pack('B*', "0000000$binary"),
        2 => pack('B*', "000000$binary"),
        3 => pack('B*', "00000$binary"),
        4 => pack('B*', "0000$binary"),
        5 => pack('B*', "000$binary"),
        6 => pack('B*', "00$binary"),
        7 => pack('B*', "0$binary"),
        0 => pack('B*', "$binary"),

    }->{CORE::length($binary) % 8};

    return $octchr;
}

#
# KPS9566 hexadecimal escape sequence
#
sub hexchr {
    my($hexdigit) = @_;

    my $hexchr = {
        1 => pack('H*', "0$hexdigit"),
        0 => pack('H*', "$hexdigit"),

    }->{CORE::length($_[0]) % 2};

    return $hexchr;
}

#
# KPS9566 open character list for qr
#
sub charlist_qr {

    my $modifier = pop @_;
    my @char = @_;

    my($singleoctet, $multipleoctet) = _charlist(@char, $modifier);
    my @singleoctet   = @$singleoctet;
    my @multipleoctet = @$multipleoctet;

    # return character list
    if (scalar(@singleoctet) >= 1) {

        # with /i modifier
        if ($modifier =~ m/i/oxms) {
            my %singleoctet_ignorecase = ();
            for (@singleoctet) {
                while (s/ \A \\x(..) - \\x(..) //oxms or s/ \A \\x((..)) //oxms) {
                    for my $ord (hex($1) .. hex($2)) {
                        my $char = CORE::chr($ord);
                        my $uc = Ekps9566::uc($char);
                        my $fc = Ekps9566::fc($char);
                        if ($uc eq $fc) {
                            $singleoctet_ignorecase{unpack 'C*', $char} = 1;
                        }
                        else {
                            if (CORE::length($fc) == 1) {
                                $singleoctet_ignorecase{unpack 'C*', $uc} = 1;
                                $singleoctet_ignorecase{unpack 'C*', $fc} = 1;
                            }
                            else {
                                $singleoctet_ignorecase{unpack 'C*', $uc} = 1;
                                push @multipleoctet, join '', map {sprintf('\x%02X',$_)} unpack 'C*', $fc;
                            }
                        }
                    }
                }
                if ($_ ne '') {
                    $singleoctet_ignorecase{unpack 'C*', $_} = 1;
                }
            }
            my $i = 0;
            my @singleoctet_ignorecase = ();
            for my $ord (0 .. 255) {
                if (exists $singleoctet_ignorecase{$ord}) {
                    push @{$singleoctet_ignorecase[$i]}, $ord;
                }
                else {
                    $i++;
                }
            }
            @singleoctet = ();
            for my $range (@singleoctet_ignorecase) {
                if (ref $range) {
                    if (scalar(@{$range}) == 1) {
                        push @singleoctet, sprintf('\x%02X', @{$range}[0]);
                    }
                    elsif (scalar(@{$range}) == 2) {
                        push @singleoctet, sprintf('\x%02X\x%02X', @{$range}[0], @{$range}[-1]);
                    }
                    else {
                        push @singleoctet, sprintf('\x%02X-\x%02X', @{$range}[0], @{$range}[-1]);
                    }
                }
            }
        }

        my $not_anchor = '';
        $not_anchor = '(?![\x81-\xFE])';

        push @multipleoctet, join('', $not_anchor, '[', @singleoctet, ']' );
    }
    if (scalar(@multipleoctet) >= 2) {
        return '(?:' . join('|', @multipleoctet) . ')';
    }
    else {
        return $multipleoctet[0];
    }
}

#
# KPS9566 open character list for not qr
#
sub charlist_not_qr {

    my $modifier = pop @_;
    my @char = @_;

    my($singleoctet, $multipleoctet) = _charlist(@char, $modifier);
    my @singleoctet   = @$singleoctet;
    my @multipleoctet = @$multipleoctet;

    # with /i modifier
    if ($modifier =~ m/i/oxms) {
        my %singleoctet_ignorecase = ();
        for (@singleoctet) {
            while (s/ \A \\x(..) - \\x(..) //oxms or s/ \A \\x((..)) //oxms) {
                for my $ord (hex($1) .. hex($2)) {
                    my $char = CORE::chr($ord);
                    my $uc = Ekps9566::uc($char);
                    my $fc = Ekps9566::fc($char);
                    if ($uc eq $fc) {
                        $singleoctet_ignorecase{unpack 'C*', $char} = 1;
                    }
                    else {
                        if (CORE::length($fc) == 1) {
                            $singleoctet_ignorecase{unpack 'C*', $uc} = 1;
                            $singleoctet_ignorecase{unpack 'C*', $fc} = 1;
                        }
                        else {
                            $singleoctet_ignorecase{unpack 'C*', $uc} = 1;
                            push @multipleoctet, join '', map {sprintf('\x%02X',$_)} unpack 'C*', $fc;
                        }
                    }
                }
            }
            if ($_ ne '') {
                $singleoctet_ignorecase{unpack 'C*', $_} = 1;
            }
        }
        my $i = 0;
        my @singleoctet_ignorecase = ();
        for my $ord (0 .. 255) {
            if (exists $singleoctet_ignorecase{$ord}) {
                push @{$singleoctet_ignorecase[$i]}, $ord;
            }
            else {
                $i++;
            }
        }
        @singleoctet = ();
        for my $range (@singleoctet_ignorecase) {
            if (ref $range) {
                if (scalar(@{$range}) == 1) {
                    push @singleoctet, sprintf('\x%02X', @{$range}[0]);
                }
                elsif (scalar(@{$range}) == 2) {
                    push @singleoctet, sprintf('\x%02X\x%02X', @{$range}[0], @{$range}[-1]);
                }
                else {
                    push @singleoctet, sprintf('\x%02X-\x%02X', @{$range}[0], @{$range}[-1]);
                }
            }
        }
    }

    # return character list
    if (scalar(@multipleoctet) >= 1) {
        if (scalar(@singleoctet) >= 1) {

            # any character other than multiple-octet and single octet character class
            return '(?!' . join('|', @multipleoctet) . ')(?:[^\x81-\xFE' . join('', @singleoctet) . ']|[\x81-\xFE][\x00-\xFF])';
        }
        else {

            # any character other than multiple-octet character class
            return '(?!' . join('|', @multipleoctet) . ")(?:$your_char)";
        }
    }
    else {
        if (scalar(@singleoctet) >= 1) {

            # any character other than single octet character class
            return                                      '(?:[^\x81-\xFE' . join('', @singleoctet) . ']|[\x81-\xFE][\x00-\xFF])';
        }
        else {

            # any character
            return                                      "(?:$your_char)";
        }
    }
}

#
# open file in read mode
#
sub _open_r {
    my(undef,$file) = @_;
    $file =~ s#\A (\s) #./$1#oxms;
    return CORE::eval(q{open($_[0],'<',$_[1])}) ||
                        open($_[0],"< $file\0");
}

#
# open file in write mode
#
sub _open_w {
    my(undef,$file) = @_;
    $file =~ s#\A (\s) #./$1#oxms;
    return CORE::eval(q{open($_[0],'>',$_[1])}) ||
                        open($_[0],"> $file\0");
}

#
# open file in append mode
#
sub _open_a {
    my(undef,$file) = @_;
    $file =~ s#\A (\s) #./$1#oxms;
    return CORE::eval(q{open($_[0],'>>',$_[1])}) ||
                        open($_[0],">> $file\0");
}

#
# safe system
#
sub _systemx {

    # P.707 29.2.33. exec
    # in Chapter 29: Functions
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.
    #
    # Be aware that in older releases of Perl, exec (and system) did not flush
    # your output buffer, so you needed to enable command buffering by setting $|
    # on one or more filehandles to avoid lost output in the case of exec, or
    # misordererd output in the case of system. This situation was largely remedied
    # in the 5.6 release of Perl. (So, 5.005 release not yet.)

    # P.855 exec
    # in Chapter 27: Functions
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.
    #
    # In very old release of Perl (before v5.6), exec (and system) did not flush
    # your output buffer, so you needed to enable command buffering by setting $|
    # on one or more filehandles to avoid lost output with exec or misordered
    # output with system.

    $| = 1;

    # P.565 23.1.2. Cleaning Up Your Environment
    # in Chapter 23: Security
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.656 Cleaning Up Your Environment
    # in Chapter 20: Security
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    # local $ENV{'PATH'} = '.';
    local @ENV{qw(IFS CDPATH ENV BASH_ENV)}; # Make %ENV safer

    # P.707 29.2.33. exec
    # in Chapter 29: Functions
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.
    #
    # As we mentioned earlier, exec treats a discrete list of arguments as an
    # indication that it should bypass shell processing. However, there is one
    # place where you might still get tripped up. The exec call (and system, too)
    # will not distinguish between a single scalar argument and an array containing
    # only one element.
    #
    #     @args = ("echo surprise");  # just one element in list
    #     exec @args                  # still subject to shell escapes
    #         or die "exec: $!";      #   because @args == 1
    #
    # To avoid this, you can use the PATHNAME syntax, explicitly duplicating the
    # first argument as the pathname, which forces the rest of the arguments to be
    # interpreted as a list, even if there is only one of them:
    #
    #     exec { $args[0] } @args  # safe even with one-argument list
    #         or die "can't exec @args: $!";

    # P.855 exec
    # in Chapter 27: Functions
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.
    #
    # As we mentioned earlier, exec treats a discrete list of arguments as a
    # directive to bypass shell processing. However, there is one place where
    # you might still get tripped up. The exec call (and system, too) cannot
    # distinguish between a single scalar argument and an array containing
    # only one element.
    #
    #     @args = ("echo surprise");  # just one element in list
    #     exec @args                  # still subject to shell escapes
    #         || die "exec: $!";      #   because @args == 1
    #
    # To avoid this, use the PATHNAME syntax, explicitly duplicating the first
    # argument as the pathname, which forces the rest of the arguments to be
    # interpreted as a list, even if there is only one of them:
    #
    #     exec { $args[0] } @args  # safe even with one-argument list
    #         || die "can't exec @args: $!";

    return CORE::system { $_[0] } @_; # safe even with one-argument list
}

#
# KPS9566 order to character (with parameter)
#
sub Ekps9566::chr(;$) {

    my $c = @_ ? $_[0] : $_;

    if ($c == 0x00) {
        return "\x00";
    }
    else {
        my @chr = ();
        while ($c > 0) {
            unshift @chr, ($c % 0x100);
            $c = int($c / 0x100);
        }
        return pack 'C*', @chr;
    }
}

#
# KPS9566 order to character (without parameter)
#
sub Ekps9566::chr_() {

    my $c = $_;

    if ($c == 0x00) {
        return "\x00";
    }
    else {
        my @chr = ();
        while ($c > 0) {
            unshift @chr, ($c % 0x100);
            $c = int($c / 0x100);
        }
        return pack 'C*', @chr;
    }
}

#
# KPS9566 stacked file test expr
#
sub Ekps9566::filetest {

    my $file     = pop @_;
    my $filetest = substr(pop @_, 1);

    unless (CORE::eval qq{Ekps9566::$filetest(\$file)}) {
        return '';
    }
    for my $filetest (CORE::reverse @_) {
        unless (CORE::eval qq{ $filetest _ }) {
            return '';
        }
    }
    return 1;
}

#
# KPS9566 file test -r expr
#
sub Ekps9566::r(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -r (Ekps9566::r)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-r _,@_) : -r _;
    }

    # P.908 32.39. Symbol
    # in Chapter 32: Standard Modules
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.326 Prototypes
    # in Chapter 7: Subroutines
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    # (and so on)

    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-r $fh,@_) : -r $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-r _,@_) : -r _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-r _,@_) : -r _;
        }
        else {

            # Even if ${^WIN32_SLOPPY_STAT} is set to a true value, Ekps9566::*()
            # on Windows opens the file for the path which has 5c at end.
            # (and so on)

            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $r = -r $fh;
                close $fh;
                return wantarray ? ($r,@_) : $r;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -w expr
#
sub Ekps9566::w(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -w (Ekps9566::w)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-w _,@_) : -w _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-w $fh,@_) : -w $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-w _,@_) : -w _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-w _,@_) : -w _;
        }
        else {
            my $fh = gensym();
            if (_open_a($fh, $_)) {
                my $w = -w $fh;
                close $fh;
                return wantarray ? ($w,@_) : $w;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -x expr
#
sub Ekps9566::x(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -x (Ekps9566::x)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-x _,@_) : -x _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-x $fh,@_) : -x $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-x _,@_) : -x _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-x _,@_) : -x _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $dummy_for_underline_cache = -x $fh;
                close $fh;
            }

            # filename is not .COM .EXE .BAT .CMD
            return wantarray ? ('',@_) : '';
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -o expr
#
sub Ekps9566::o(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -o (Ekps9566::o)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-o _,@_) : -o _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-o $fh,@_) : -o $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-o _,@_) : -o _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-o _,@_) : -o _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $o = -o $fh;
                close $fh;
                return wantarray ? ($o,@_) : $o;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -R expr
#
sub Ekps9566::R(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -R (Ekps9566::R)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-R _,@_) : -R _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-R $fh,@_) : -R $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-R _,@_) : -R _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-R _,@_) : -R _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $R = -R $fh;
                close $fh;
                return wantarray ? ($R,@_) : $R;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -W expr
#
sub Ekps9566::W(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -W (Ekps9566::W)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-W _,@_) : -W _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-W $fh,@_) : -W $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-W _,@_) : -W _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-W _,@_) : -W _;
        }
        else {
            my $fh = gensym();
            if (_open_a($fh, $_)) {
                my $W = -W $fh;
                close $fh;
                return wantarray ? ($W,@_) : $W;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -X expr
#
sub Ekps9566::X(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -X (Ekps9566::X)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-X _,@_) : -X _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-X $fh,@_) : -X $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-X _,@_) : -X _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-X _,@_) : -X _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $dummy_for_underline_cache = -X $fh;
                close $fh;
            }

            # filename is not .COM .EXE .BAT .CMD
            return wantarray ? ('',@_) : '';
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -O expr
#
sub Ekps9566::O(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -O (Ekps9566::O)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-O _,@_) : -O _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-O $fh,@_) : -O $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-O _,@_) : -O _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-O _,@_) : -O _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $O = -O $fh;
                close $fh;
                return wantarray ? ($O,@_) : $O;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -e expr
#
sub Ekps9566::e(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -e (Ekps9566::e)' if @_ and not wantarray;

    local $^W = 0;

    my $fh = qualify_to_ref $_;
    if ($_ eq '_') {
        return wantarray ? (-e _,@_) : -e _;
    }

    # return false if directory handle
    elsif (defined Ekps9566::telldir($fh)) {
        return wantarray ? ('',@_) : '';
    }

    # return true if file handle
    elsif (defined fileno $fh) {
        return wantarray ? (1,@_) : 1;
    }

    elsif (-e $_) {
        return wantarray ? (1,@_) : 1;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (1,@_) : 1;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $e = -e $fh;
                close $fh;
                return wantarray ? ($e,@_) : $e;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -z expr
#
sub Ekps9566::z(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -z (Ekps9566::z)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-z _,@_) : -z _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-z $fh,@_) : -z $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-z _,@_) : -z _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-z _,@_) : -z _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $z = -z $fh;
                close $fh;
                return wantarray ? ($z,@_) : $z;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -s expr
#
sub Ekps9566::s(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -s (Ekps9566::s)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-s _,@_) : -s _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-s $fh,@_) : -s $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-s _,@_) : -s _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-s _,@_) : -s _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $s = -s $fh;
                close $fh;
                return wantarray ? ($s,@_) : $s;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -f expr
#
sub Ekps9566::f(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -f (Ekps9566::f)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-f _,@_) : -f _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-f $fh,@_) : -f $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-f _,@_) : -f _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? ('',@_) : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $f = -f $fh;
                close $fh;
                return wantarray ? ($f,@_) : $f;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -d expr
#
sub Ekps9566::d(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -d (Ekps9566::d)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-d _,@_) : -d _;
    }

    # return false if file handle or directory handle
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? ('',@_) : '';
    }
    elsif (-e $_) {
        return wantarray ? (-d _,@_) : -d _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        return wantarray ? (-d "$_/.",@_) : -d "$_/.";
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -l expr
#
sub Ekps9566::l(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -l (Ekps9566::l)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-l _,@_) : -l _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-l $fh,@_) : -l $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-l _,@_) : -l _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-l _,@_) : -l _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $l = -l $fh;
                close $fh;
                return wantarray ? ($l,@_) : $l;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -p expr
#
sub Ekps9566::p(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -p (Ekps9566::p)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-p _,@_) : -p _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-p $fh,@_) : -p $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-p _,@_) : -p _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-p _,@_) : -p _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $p = -p $fh;
                close $fh;
                return wantarray ? ($p,@_) : $p;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -S expr
#
sub Ekps9566::S(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -S (Ekps9566::S)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-S _,@_) : -S _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-S $fh,@_) : -S $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-S _,@_) : -S _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-S _,@_) : -S _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $S = -S $fh;
                close $fh;
                return wantarray ? ($S,@_) : $S;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -b expr
#
sub Ekps9566::b(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -b (Ekps9566::b)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-b _,@_) : -b _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-b $fh,@_) : -b $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-b _,@_) : -b _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-b _,@_) : -b _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $b = -b $fh;
                close $fh;
                return wantarray ? ($b,@_) : $b;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -c expr
#
sub Ekps9566::c(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -c (Ekps9566::c)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-c _,@_) : -c _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-c $fh,@_) : -c $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-c _,@_) : -c _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-c _,@_) : -c _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $c = -c $fh;
                close $fh;
                return wantarray ? ($c,@_) : $c;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -u expr
#
sub Ekps9566::u(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -u (Ekps9566::u)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-u _,@_) : -u _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-u $fh,@_) : -u $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-u _,@_) : -u _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-u _,@_) : -u _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $u = -u $fh;
                close $fh;
                return wantarray ? ($u,@_) : $u;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -g expr
#
sub Ekps9566::g(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -g (Ekps9566::g)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-g _,@_) : -g _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-g $fh,@_) : -g $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-g _,@_) : -g _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-g _,@_) : -g _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $g = -g $fh;
                close $fh;
                return wantarray ? ($g,@_) : $g;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -k expr
#
sub Ekps9566::k(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -k (Ekps9566::k)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? ('',@_) : '';
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? ('',@_) : '';
    }
    elsif ($] =~ /^5\.008/oxms) {
        return wantarray ? ('',@_) : '';
    }
    return wantarray ? ($_,@_) : $_;
}

#
# KPS9566 file test -T expr
#
sub Ekps9566::T(;*@) {

    local $_ = shift if @_;

    # Use of croak without parentheses makes die on Strawberry Perl 5.008 and 5.010, like:
    #     croak 'Too many arguments for -T (Ekps9566::T)';
    # Must be used by parentheses like:
    #     croak('Too many arguments for -T (Ekps9566::T)');

    if (@_ and not wantarray) {
        croak('Too many arguments for -T (Ekps9566::T)');
    }

    my $T = 1;

    my $fh = qualify_to_ref $_;
    if (defined fileno $fh) {

        if (defined Ekps9566::telldir($fh)) {
            return wantarray ? (undef,@_) : undef;
        }

        # P.813 29.2.176. tell
        # in Chapter 29: Functions
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # P.970 tell
        # in Chapter 27: Functions
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        # (and so on)

        my $systell = sysseek $fh, 0, 1;

        if (sysread $fh, my $block, 512) {

            # P.163 Binary file check in Little Perl Parlor 16
            # of Book No. T1008901080816 ZASSHI 08901-8 UNIX MAGAZINE 1993 Aug VOL8#8
            # (and so on)

            if ($block =~ /[\000\377]/oxms) {
                $T = '';
            }
            elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
                $T = '';
            }
        }

        # 0 byte or eof
        else {
            $T = 1;
        }

        my $dummy_for_underline_cache = -T $fh;
        sysseek $fh, $systell, 0;
    }
    else {
        if (-d $_ or -d "$_/.") {
            return wantarray ? (undef,@_) : undef;
        }

        $fh = gensym();
        if (_open_r($fh, $_)) {
        }
        else {
            return wantarray ? (undef,@_) : undef;
        }
        if (sysread $fh, my $block, 512) {
            if ($block =~ /[\000\377]/oxms) {
                $T = '';
            }
            elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
                $T = '';
            }
        }

        # 0 byte or eof
        else {
            $T = 1;
        }
        my $dummy_for_underline_cache = -T $fh;
        close $fh;
    }

    return wantarray ? ($T,@_) : $T;
}

#
# KPS9566 file test -B expr
#
sub Ekps9566::B(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -B (Ekps9566::B)' if @_ and not wantarray;
    my $B = '';

    my $fh = qualify_to_ref $_;
    if (defined fileno $fh) {

        if (defined Ekps9566::telldir($fh)) {
            return wantarray ? (undef,@_) : undef;
        }

        my $systell = sysseek $fh, 0, 1;

        if (sysread $fh, my $block, 512) {
            if ($block =~ /[\000\377]/oxms) {
                $B = 1;
            }
            elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
                $B = 1;
            }
        }

        # 0 byte or eof
        else {
            $B = 1;
        }

        my $dummy_for_underline_cache = -B $fh;
        sysseek $fh, $systell, 0;
    }
    else {
        if (-d $_ or -d "$_/.") {
            return wantarray ? (undef,@_) : undef;
        }

        $fh = gensym();
        if (_open_r($fh, $_)) {
        }
        else {
            return wantarray ? (undef,@_) : undef;
        }
        if (sysread $fh, my $block, 512) {
            if ($block =~ /[\000\377]/oxms) {
                $B = 1;
            }
            elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
                $B = 1;
            }
        }

        # 0 byte or eof
        else {
            $B = 1;
        }
        my $dummy_for_underline_cache = -B $fh;
        close $fh;
    }

    return wantarray ? ($B,@_) : $B;
}

#
# KPS9566 file test -M expr
#
sub Ekps9566::M(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -M (Ekps9566::M)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-M _,@_) : -M _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-M $fh,@_) : -M $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-M _,@_) : -M _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-M _,@_) : -M _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $M = ($^T - $mtime) / (24*60*60);
                return wantarray ? ($M,@_) : $M;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -A expr
#
sub Ekps9566::A(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -A (Ekps9566::A)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-A _,@_) : -A _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-A $fh,@_) : -A $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-A _,@_) : -A _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-A _,@_) : -A _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $A = ($^T - $atime) / (24*60*60);
                return wantarray ? ($A,@_) : $A;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 file test -C expr
#
sub Ekps9566::C(;*@) {

    local $_ = shift if @_;
    croak 'Too many arguments for -C (Ekps9566::C)' if @_ and not wantarray;

    if ($_ eq '_') {
        return wantarray ? (-C _,@_) : -C _;
    }
    elsif (defined fileno(my $fh = qualify_to_ref $_)) {
        return wantarray ? (-C $fh,@_) : -C $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-C _,@_) : -C _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return wantarray ? (-C _,@_) : -C _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $C = ($^T - $ctime) / (24*60*60);
                return wantarray ? ($C,@_) : $C;
            }
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#
# KPS9566 stacked file test $_
#
sub Ekps9566::filetest_ {

    my $filetest = substr(pop @_, 1);

    unless (CORE::eval qq{Ekps9566::${filetest}_}) {
        return '';
    }
    for my $filetest (CORE::reverse @_) {
        unless (CORE::eval qq{ $filetest _ }) {
            return '';
        }
    }
    return 1;
}

#
# KPS9566 file test -r $_
#
sub Ekps9566::r_() {

    if (-e $_) {
        return -r _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -r _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $r = -r $fh;
                close $fh;
                return $r ? 1 : '';
            }
        }
    }

# 10.10. Returning Failure
# in Chapter 10. Subroutines
# of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.
# (and so on)

# 2010-01-26 The difference of "return;" and "return undef;"
# http://d.hatena.ne.jp/gfx/20100126/1264474754
#
# "Perl Best Practices" recommends to use "return;"*1 to return nothing, but
# it might be wrong in some cases. If you use this idiom for those functions
# which are expected to return a scalar value, e.g. searching functions, the
# user of those functions will be surprised at what they return in list
# context, an empty list - note that many functions and all the methods
# evaluate their arguments in list context. You'd better to use "return undef;"
# for such scalar functions.
#
#     sub search_something {
#         my($arg) = @_;
#         # search_something...
#         if(defined $found){
#             return $found;
#         }
#         return; # XXX: you'd better to "return undef;"
#     }
#
#     # ...
#
#     # you'll get what you want, but ...
#     my $something = search_something($source);
#
#     # you won't get what you want here.
#     # @_ for doit() is (-foo => $opt), not (undef, -foo => $opt).
#     $obj->doit(search_something($source), -option=> $optval);
#
#     # you have to use the "scalar" operator in such a case.
#     $obj->doit(scalar search_something($source), ...);
#
# *1: it returns an empty list in list context, or returns undef in scalar
#     context
#
# (and so on)

    return undef;
}

#
# KPS9566 file test -w $_
#
sub Ekps9566::w_() {

    if (-e $_) {
        return -w _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -w _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_a($fh, $_)) {
                my $w = -w $fh;
                close $fh;
                return $w ? 1 : '';
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -x $_
#
sub Ekps9566::x_() {

    if (-e $_) {
        return -x _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -x _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $dummy_for_underline_cache = -x $fh;
                close $fh;
            }

            # filename is not .COM .EXE .BAT .CMD
            return '';
        }
    }
    return undef;
}

#
# KPS9566 file test -o $_
#
sub Ekps9566::o_() {

    if (-e $_) {
        return -o _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -o _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $o = -o $fh;
                close $fh;
                return $o ? 1 : '';
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -R $_
#
sub Ekps9566::R_() {

    if (-e $_) {
        return -R _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -R _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $R = -R $fh;
                close $fh;
                return $R ? 1 : '';
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -W $_
#
sub Ekps9566::W_() {

    if (-e $_) {
        return -W _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -W _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_a($fh, $_)) {
                my $W = -W $fh;
                close $fh;
                return $W ? 1 : '';
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -X $_
#
sub Ekps9566::X_() {

    if (-e $_) {
        return -X _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -X _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $dummy_for_underline_cache = -X $fh;
                close $fh;
            }

            # filename is not .COM .EXE .BAT .CMD
            return '';
        }
    }
    return undef;
}

#
# KPS9566 file test -O $_
#
sub Ekps9566::O_() {

    if (-e $_) {
        return -O _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -O _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $O = -O $fh;
                close $fh;
                return $O ? 1 : '';
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -e $_
#
sub Ekps9566::e_() {

    if (-e $_) {
        return 1;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return 1;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $e = -e $fh;
                close $fh;
                return $e ? 1 : '';
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -z $_
#
sub Ekps9566::z_() {

    if (-e $_) {
        return -z _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -z _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $z = -z $fh;
                close $fh;
                return $z ? 1 : '';
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -s $_
#
sub Ekps9566::s_() {

    if (-e $_) {
        return -s _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -s _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $s = -s $fh;
                close $fh;
                return $s;
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -f $_
#
sub Ekps9566::f_() {

    if (-e $_) {
        return -f _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $f = -f $fh;
                close $fh;
                return $f ? 1 : '';
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -d $_
#
sub Ekps9566::d_() {

    if (-e $_) {
        return -d _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        return -d "$_/." ? 1 : '';
    }
    return undef;
}

#
# KPS9566 file test -l $_
#
sub Ekps9566::l_() {

    if (-e $_) {
        return -l _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -l _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $l = -l $fh;
                close $fh;
                return $l ? 1 : '';
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -p $_
#
sub Ekps9566::p_() {

    if (-e $_) {
        return -p _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -p _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $p = -p $fh;
                close $fh;
                return $p ? 1 : '';
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -S $_
#
sub Ekps9566::S_() {

    if (-e $_) {
        return -S _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -S _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $S = -S $fh;
                close $fh;
                return $S ? 1 : '';
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -b $_
#
sub Ekps9566::b_() {

    if (-e $_) {
        return -b _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -b _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $b = -b $fh;
                close $fh;
                return $b ? 1 : '';
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -c $_
#
sub Ekps9566::c_() {

    if (-e $_) {
        return -c _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -c _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $c = -c $fh;
                close $fh;
                return $c ? 1 : '';
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -u $_
#
sub Ekps9566::u_() {

    if (-e $_) {
        return -u _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -u _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $u = -u $fh;
                close $fh;
                return $u ? 1 : '';
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -g $_
#
sub Ekps9566::g_() {

    if (-e $_) {
        return -g _ ? 1 : '';
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -g _ ? 1 : '';
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my $g = -g $fh;
                close $fh;
                return $g ? 1 : '';
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -k $_
#
sub Ekps9566::k_() {

    if ($] =~ /^5\.008/oxms) {
        return wantarray ? ('',@_) : '';
    }
    return wantarray ? ($_,@_) : $_;
}

#
# KPS9566 file test -T $_
#
sub Ekps9566::T_() {

    my $T = 1;

    if (-d $_ or -d "$_/.") {
        return undef;
    }
    my $fh = gensym();
    if (_open_r($fh, $_)) {
    }
    else {
        return undef;
    }

    if (sysread $fh, my $block, 512) {
        if ($block =~ /[\000\377]/oxms) {
            $T = '';
        }
        elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
            $T = '';
        }
    }

    # 0 byte or eof
    else {
        $T = 1;
    }
    my $dummy_for_underline_cache = -T $fh;
    close $fh;

    return $T;
}

#
# KPS9566 file test -B $_
#
sub Ekps9566::B_() {

    my $B = '';

    if (-d $_ or -d "$_/.") {
        return undef;
    }
    my $fh = gensym();
    if (_open_r($fh, $_)) {
    }
    else {
        return undef;
    }

    if (sysread $fh, my $block, 512) {
        if ($block =~ /[\000\377]/oxms) {
            $B = 1;
        }
        elsif (($block =~ tr/\000-\007\013\016-\032\034-\037\377//) * 10 > CORE::length $block) {
            $B = 1;
        }
    }

    # 0 byte or eof
    else {
        $B = 1;
    }
    my $dummy_for_underline_cache = -B $fh;
    close $fh;

    return $B;
}

#
# KPS9566 file test -M $_
#
sub Ekps9566::M_() {

    if (-e $_) {
        return -M _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -M _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $M = ($^T - $mtime) / (24*60*60);
                return $M;
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -A $_
#
sub Ekps9566::A_() {

    if (-e $_) {
        return -A _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -A _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $A = ($^T - $atime) / (24*60*60);
                return $A;
            }
        }
    }
    return undef;
}

#
# KPS9566 file test -C $_
#
sub Ekps9566::C_() {

    if (-e $_) {
        return -C _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        if (-d "$_/.") {
            return -C _;
        }
        else {
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat $fh;
                close $fh;
                my $C = ($^T - $ctime) / (24*60*60);
                return $C;
            }
        }
    }
    return undef;
}

#
# KPS9566 path globbing (with parameter)
#
sub Ekps9566::glob($) {

    if (wantarray) {
        my @glob = _DOS_like_glob(@_);
        for my $glob (@glob) {
            $glob =~ s{ \A (?:\./)+ }{}oxms;
        }
        return @glob;
    }
    else {
        my $glob = _DOS_like_glob(@_);
        $glob =~ s{ \A (?:\./)+ }{}oxms;
        return $glob;
    }
}

#
# KPS9566 path globbing (without parameter)
#
sub Ekps9566::glob_() {

    if (wantarray) {
        my @glob = _DOS_like_glob();
        for my $glob (@glob) {
            $glob =~ s{ \A (?:\./)+ }{}oxms;
        }
        return @glob;
    }
    else {
        my $glob = _DOS_like_glob();
        $glob =~ s{ \A (?:\./)+ }{}oxms;
        return $glob;
    }
}

#
# KPS9566 path globbing via File::DosGlob 1.10
#
# Often I confuse "_dosglob" and "_doglob".
# So, I renamed "_dosglob" to "_DOS_like_glob".
#
my %iter;
my %entries;
sub _DOS_like_glob {

    # context (keyed by second cxix argument provided by core)
    my($expr,$cxix) = @_;

    # glob without args defaults to $_
    $expr = $_ if not defined $expr;

    # represents the current user's home directory
    #
    # 7.3. Expanding Tildes in Filenames
    # in Chapter 7. File Access
    # of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.
    #
    # and File::HomeDir, File::HomeDir::Windows module

    # DOS-like system
    if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
        $expr =~ s{ \A ~ (?= [^/\\] ) }
                  { my_home_MSWin32() }oxmse;
    }

    # UNIX-like system
    else {
        $expr =~ s{ \A ~ ( (?:[^\x81-\xFE/]|[\x81-\xFE][\x00-\xFF])* ) }
                  { $1 ? (CORE::eval(q{(getpwnam($1))[7]})||my_home()) : my_home() }oxmse;
    }

    # assume global context if not provided one
    $cxix = '_G_' if not defined $cxix;
    $iter{$cxix} = 0 if not exists $iter{$cxix};

    # if we're just beginning, do it all first
    if ($iter{$cxix} == 0) {
            $entries{$cxix} = [ _do_glob(1, _parse_line($expr)) ];
    }

    # chuck it all out, quick or slow
    if (wantarray) {
        delete $iter{$cxix};
        return @{delete $entries{$cxix}};
    }
    else {
        if ($iter{$cxix} = scalar @{$entries{$cxix}}) {
            return shift @{$entries{$cxix}};
        }
        else {
            # return undef for EOL
            delete $iter{$cxix};
            delete $entries{$cxix};
            return undef;
        }
    }
}

#
# KPS9566 path globbing subroutine
#
sub _do_glob {

    my($cond,@expr) = @_;
    my @glob = ();
    my $fix_drive_relative_paths = 0;

OUTER:
    for my $expr (@expr) {
        next OUTER if not defined $expr;
        next OUTER if $expr eq '';

        my @matched = ();
        my @globdir = ();
        my $head    = '.';
        my $pathsep = '/';
        my $tail;

        # if argument is within quotes strip em and do no globbing
        if ($expr =~ /\A " ((?:$q_char)*?) " \z/oxms) {
            $expr = $1;
            if ($cond eq 'd') {
                if (Ekps9566::d $expr) {
                    push @glob, $expr;
                }
            }
            else {
                if (Ekps9566::e $expr) {
                    push @glob, $expr;
                }
            }
            next OUTER;
        }

        # wildcards with a drive prefix such as h:*.pm must be changed
        # to h:./*.pm to expand correctly
        if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            if ($expr =~ s# \A ((?:[A-Za-z]:)?) ([^\x81-\xFE/\\]|[\x81-\xFE][\x00-\xFF]) #$1./$2#oxms) {
                $fix_drive_relative_paths = 1;
            }
        }

        if (($head, $tail) = _parse_path($expr,$pathsep)) {
            if ($tail eq '') {
                push @glob, $expr;
                next OUTER;
            }
            if ($head =~ / \A (?:$q_char)*? [*?] /oxms) {
                if (@globdir = _do_glob('d', $head)) {
                    push @glob, _do_glob($cond, map {"$_$pathsep$tail"} @globdir);
                    next OUTER;
                }
            }
            if ($head eq '' or $head =~ /\A [A-Za-z]: \z/oxms) {
                $head .= $pathsep;
            }
            $expr = $tail;
        }

        # If file component has no wildcards, we can avoid opendir
        if ($expr !~ / \A (?:$q_char)*? [*?] /oxms) {
            if ($head eq '.') {
                $head = '';
            }
            if ($head ne '' and ($head =~ / \G ($q_char) /oxmsg)[-1] ne $pathsep) {
                $head .= $pathsep;
            }
            $head .= $expr;
            if ($cond eq 'd') {
                if (Ekps9566::d $head) {
                    push @glob, $head;
                }
            }
            else {
                if (Ekps9566::e $head) {
                    push @glob, $head;
                }
            }
            next OUTER;
        }
        Ekps9566::opendir(*DIR, $head) or next OUTER;
        my @leaf = readdir DIR;
        closedir DIR;

        if ($head eq '.') {
            $head = '';
        }
        if ($head ne '' and ($head =~ / \G ($q_char) /oxmsg)[-1] ne $pathsep) {
            $head .= $pathsep;
        }

        my $pattern = '';
        while ($expr =~ / \G ($q_char) /oxgc) {
            my $char = $1;

            # 6.9. Matching Shell Globs as Regular Expressions
            # in Chapter 6. Pattern Matching
            # of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.
            # (and so on)

            if ($char eq '*') {
                $pattern .= "(?:$your_char)*",
            }
            elsif ($char eq '?') {
                $pattern .= "(?:$your_char)?",  # DOS style
#               $pattern .= "(?:$your_char)",   # UNIX style
            }
            elsif ((my $fc = Ekps9566::fc($char)) ne $char) {
                $pattern .= $fc;
            }
            else {
                $pattern .= quotemeta $char;
            }
        }
        my $matchsub = sub { Ekps9566::fc($_[0]) =~ /\A $pattern \z/xms };

#       if ($@) {
#           print STDERR "$0: $@\n";
#           next OUTER;
#       }

INNER:
        for my $leaf (@leaf) {
            if ($leaf eq '.' or $leaf eq '..') {
                next INNER;
            }
            if ($cond eq 'd' and not Ekps9566::d "$head$leaf") {
                next INNER;
            }

            if (&$matchsub($leaf)) {
                push @matched, "$head$leaf";
                next INNER;
            }

            # [DOS compatibility special case]
            # Failed, add a trailing dot and try again, but only...

            if (Ekps9566::index($leaf,'.') == -1 and   # if name does not have a dot in it *and*
                CORE::length($leaf) <= 8 and        # name is shorter than or equal to 8 chars *and*
                Ekps9566::index($pattern,'\\.') != -1  # pattern has a dot.
            ) {
                if (&$matchsub("$leaf.")) {
                    push @matched, "$head$leaf";
                    next INNER;
                }
            }
        }
        if (@matched) {
            push @glob, @matched;
        }
    }
    if ($fix_drive_relative_paths) {
        for my $glob (@glob) {
            $glob =~ s# \A ([A-Za-z]:) \./ #$1#oxms;
        }
    }
    return @glob;
}

#
# KPS9566 parse line
#
sub _parse_line {

    my($line) = @_;

    $line .= ' ';
    my @piece = ();
    while ($line =~ /
        " ( (?>(?: [^\x81-\xFE"]  |[\x81-\xFE][\x00-\xFF] )* ) ) " (?>\s+) |
          ( (?>(?: [^\x81-\xFE"\s]|[\x81-\xFE][\x00-\xFF] )* ) )   (?>\s+)
        /oxmsg
    ) {
        push @piece, defined($1) ? $1 : $2;
    }
    return @piece;
}

#
# KPS9566 parse path
#
sub _parse_path {

    my($path,$pathsep) = @_;

    $path .= '/';
    my @subpath = ();
    while ($path =~ /
        ((?: [^\x81-\xFE\/\\]|[\x81-\xFE][\x00-\xFF] )+?) [\/\\]
        /oxmsg
    ) {
        push @subpath, $1;
    }

    my $tail = pop @subpath;
    my $head = join $pathsep, @subpath;
    return $head, $tail;
}

#
# via File::HomeDir::Windows 1.00
#
sub my_home_MSWin32 {

    # A lot of unix people and unix-derived tools rely on
    # the ability to overload HOME. We will support it too
    # so that they can replace raw HOME calls with File::HomeDir.
    if (exists $ENV{'HOME'} and $ENV{'HOME'}) {
        return $ENV{'HOME'};
    }

    # Do we have a user profile?
    elsif (exists $ENV{'USERPROFILE'} and $ENV{'USERPROFILE'}) {
        return $ENV{'USERPROFILE'};
    }

    # Some Windows use something like $ENV{'HOME'}
    elsif (exists $ENV{'HOMEDRIVE'} and exists $ENV{'HOMEPATH'} and $ENV{'HOMEDRIVE'} and $ENV{'HOMEPATH'}) {
        return join '', $ENV{'HOMEDRIVE'}, $ENV{'HOMEPATH'};
    }

    return undef;
}

#
# via File::HomeDir::Unix 1.00
#
sub my_home {
    my $home;

    if (exists $ENV{'HOME'} and defined $ENV{'HOME'}) {
        $home = $ENV{'HOME'};
    }

    # This is from the original code, but I'm guessing
    # it means "login directory" and exists on some Unixes.
    elsif (exists $ENV{'LOGDIR'} and $ENV{'LOGDIR'}) {
        $home = $ENV{'LOGDIR'};
    }

    ### More-desperate methods

    # Light desperation on any (Unixish) platform
    else {
        $home = CORE::eval q{ (getpwuid($<))[7] };
    }

    # On Unix in general, a non-existant home means "no home"
    # For example, "nobody"-like users might use /nonexistant
    if (defined $home and ! Ekps9566::d($home)) {
        $home = undef;
    }
    return $home;
}

#
# KPS9566 file lstat (with parameter)
#
sub Ekps9566::lstat(*) {

    local $_ = shift if @_;

    if (-e $_) {
        return CORE::lstat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {

        # Even if ${^WIN32_SLOPPY_STAT} is set to a true value, Ekps9566::lstat()
        # on Windows opens the file for the path which has 5c at end.
        # (and so on)

        my $fh = gensym();
        if (wantarray) {
            if (_open_r($fh, $_)) {
                my @lstat = CORE::stat $fh; # not CORE::lstat
                close $fh;
                return @lstat;
            }
        }
        else {
            if (_open_r($fh, $_)) {
                my $lstat = CORE::stat $fh; # not CORE::lstat
                close $fh;
                return $lstat;
            }
        }
    }
    return wantarray ? () : undef;
}

#
# KPS9566 file lstat (without parameter)
#
sub Ekps9566::lstat_() {

    if (-e $_) {
        return CORE::lstat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        my $fh = gensym();
        if (wantarray) {
            if (_open_r($fh, $_)) {
                my @lstat = CORE::stat $fh; # not CORE::lstat
                close $fh;
                return @lstat;
            }
        }
        else {
            if (_open_r($fh, $_)) {
                my $lstat = CORE::stat $fh; # not CORE::lstat
                close $fh;
                return $lstat;
            }
        }
    }
    return wantarray ? () : undef;
}

#
# KPS9566 path opendir
#
sub Ekps9566::opendir(*$) {

    my $dh = qualify_to_ref $_[0];
    if (CORE::opendir $dh, $_[1]) {
        return 1;
    }
    elsif (_MSWin32_5Cended_path($_[1])) {
        if (CORE::opendir $dh, "$_[1]/.") {
            return 1;
        }
    }
    return undef;
}

#
# KPS9566 file stat (with parameter)
#
sub Ekps9566::stat(*) {

    local $_ = shift if @_;

    my $fh = qualify_to_ref $_;
    if (defined fileno $fh) {
        return CORE::stat $fh;
    }
    elsif (-e $_) {
        return CORE::stat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {

        # Even if ${^WIN32_SLOPPY_STAT} is set to a true value, Ekps9566::stat()
        # on Windows opens the file for the path which has 5c at end.
        # (and so on)

        my $fh = gensym();
        if (wantarray) {
            if (_open_r($fh, $_)) {
                my @stat = CORE::stat $fh;
                close $fh;
                return @stat;
            }
        }
        else {
            if (_open_r($fh, $_)) {
                my $stat = CORE::stat $fh;
                close $fh;
                return $stat;
            }
        }
    }
    return wantarray ? () : undef;
}

#
# KPS9566 file stat (without parameter)
#
sub Ekps9566::stat_() {

    my $fh = qualify_to_ref $_;
    if (defined fileno $fh) {
        return CORE::stat $fh;
    }
    elsif (-e $_) {
        return CORE::stat _;
    }
    elsif (_MSWin32_5Cended_path($_)) {
        my $fh = gensym();
        if (wantarray) {
            if (_open_r($fh, $_)) {
                my @stat = CORE::stat $fh;
                close $fh;
                return @stat;
            }
        }
        else {
            if (_open_r($fh, $_)) {
                my $stat = CORE::stat $fh;
                close $fh;
                return $stat;
            }
        }
    }
    return wantarray ? () : undef;
}

#
# KPS9566 path unlink
#
sub Ekps9566::unlink(@) {

    local @_ = ($_) unless @_;

    my $unlink = 0;
    for (@_) {
        if (CORE::unlink) {
            $unlink++;
        }
        elsif (Ekps9566::d($_)) {
        }
        elsif (_MSWin32_5Cended_path($_)) {
            my @char = /\G (?>$q_char) /oxmsg;
            my $file = join '', map {{'/' => '\\'}->{$_} || $_} @char;
            if ($file =~ / \A (?:$q_char)*? [ ] /oxms) {
                $file = qq{"$file"};
            }
            my $fh = gensym();
            if (_open_r($fh, $_)) {
                close $fh;

                # cmd.exe on Windows NT, Windows 2000, Windows XP, Windows 2003 or later
                if ((defined $ENV{'OS'}) and ($ENV{'OS'} eq 'Windows_NT')) {
                    CORE::system 'DEL', '/F', $file, '2>NUL';
                }

                # Win95Cmd.exe on any Windows (when SET PERL5SHELL=Win95Cmd.exe /c, `var` returns "Windows 2000")
                elsif (qx{ver} =~ /\b(?:Windows 2000)\b/oms) {
                    CORE::system 'DEL', '/F', $file, '2>NUL';
                }

                # COMMAND.COM on Windows 95, Windows 98, Windows 98 Second Edition, Windows Millennium Edition
                # command.com can not "2>NUL"
                else {
                    CORE::system 'ATTRIB', '-R', $file; # clears Read-only file attribute
                    CORE::system 'DEL',          $file;
                }

                if (_open_r($fh, $_)) {
                    close $fh;
                }
                else {
                    $unlink++;
                }
            }
        }
    }
    return $unlink;
}

#
# KPS9566 chdir
#
sub Ekps9566::chdir(;$) {

    if (@_ == 0) {
        return CORE::chdir;
    }

    my($dir) = @_;

    if (_MSWin32_5Cended_path($dir)) {
        if (not Ekps9566::d $dir) {
            return 0;
        }

        if ($] =~ /^5\.005/oxms) {
            return CORE::chdir $dir;
        }
        elsif (($] =~ /^(?:5\.006|5\.008000)/oxms) and ($^O eq 'MSWin32')) {
            local $@;
            my $chdir = CORE::eval q{
                CORE::require 'jacode.pl';

                # P.676 ${^WIDE_SYSTEM_CALLS}
                # in Chapter 28: Special Names
                # of ISBN 0-596-00027-8 Programming Perl Third Edition.

                # P.790 ${^WIDE_SYSTEM_CALLS}
                # in Chapter 25: Special Names
                # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

                local ${^WIDE_SYSTEM_CALLS} = 1;
                return CORE::chdir jcode::utf8($dir,'sjis');
            };
            if (not $@) {
                return $chdir;
            }
        }

        # old idea (Win32 module required)
        elsif (0) {
            local $@;
            my $shortdir = '';
            my $chdir = CORE::eval q{
                use Win32;
                $shortdir = Win32::GetShortPathName($dir);
                if ($shortdir ne $dir) {
                    return CORE::chdir $shortdir;
                }
                else {
                    return 0;
                }
            };
            if ($@) {
                my @char = $dir =~ /\G (?>$q_char) /oxmsg;
                while ($char[-1] eq "\x5C") {
                    pop @char;
                }
                $dir = join '', @char;
                croak "Perl$] can't chdir to $dir (chr(0x5C) ended path), Win32.pm module may help you";
            }
            elsif ($shortdir eq $dir) {
                my @char = $dir =~ /\G (?>$q_char) /oxmsg;
                while ($char[-1] eq "\x5C") {
                    pop @char;
                }
                $dir = join '', @char;
                croak "Perl$] can't chdir to $dir (chr(0x5C) ended path)";
            }
            return $chdir;
        }

        # rejected idea ...
        elsif (0) {

            # MSDN SetCurrentDirectory function
            # http://msdn.microsoft.com/ja-jp/library/windows/desktop/aa365530(v=vs.85).aspx
            #
            # Data Execution Prevention (DEP)
            # http://vlaurie.com/computers2/Articles/dep.htm
            #
            # Learning x86 assembler with Perl -- Shibuya.pm#11
            # http://developer.cybozu.co.jp/takesako/2009/06/perl-x86-shibuy.html
            #
            # Introduction to Win32::API programming in Perl
            # http://d.hatena.ne.jp/TAKESAKO/20090324/1237879559
            #
            # DynaLoader - Dynamically load C libraries into Perl code
            # http://perldoc.perl.org/DynaLoader.html
            #
            # Basic knowledge of DynaLoader
            # http://blog.64p.org/entry/20090313/1236934042

            if (($] =~ /^5\.006/oxms)                     and
                ($^O eq 'MSWin32')                        and
                ($ENV{'PROCESSOR_ARCHITECTURE'} eq 'x86') and
                CORE::eval(q{CORE::require 'Dyna'.'Loader'})
            ) {
                my $x86 = join('',

                    # PUSH Iv
                    "\x68", pack('P', "$dir\\\0"),

                    # MOV eAX, Iv
                    "\xb8", pack('L',
                        *{'Dyna'.'Loader::dl_find_symbol'}{'CODE'}->(
                            *{'Dyna'.'Loader::dl_load_file'}{'CODE'}->("$ENV{'SystemRoot'}\\system32\\kernel32.dll"),
                            'SetCurrentDirectoryA'
                        )
                    ),

                    # CALL eAX
                    "\xff\xd0",

                    # RETN
                    "\xc3",
                );
                *{'Dyna'.'Loader::dl_install_xsub'}{'CODE'}->('_SetCurrentDirectoryA', unpack('L', pack 'P', $x86));
                _SetCurrentDirectoryA();
                chomp(my $chdir = qx{chdir});
                if (Ekps9566::fc($chdir) eq Ekps9566::fc($dir)) {
                    return 1;
                }
                else {
                    return 0;
                }
            }
        }

# COMMAND.COM's unhelpful tips:
# Displays a list of files and subdirectories in a directory.
# http://www.lagmonster.org/docs/DOS7/z-dir.html
#
# Syntax:
#
#   DIR [drive:] [path] [filename] [/Switches]
#
#   /Z Long file names are not displayed in the file listing
#
#  Limitations
#   The undocumented /Z switch (no long names) would appear to
#   have been not fully developed and has a couple of problems:
#
#  1. It will only work if:
#   There is no path specified (ie. for the current directory in
#   the current drive)
#   The path is specified as the root directory of any drive
#   (eg. C:\, D:\, etc.)
#   The path is specified as the current directory of any drive
#   by using the drive letter only (eg. C:, D:, etc.)
#   The path is specified as the parent directory using the ..
#   notation (eg. DIR .. /Z)
#   Any other syntax results in a "File Not Found" error message.
#
#  2. The /Z switch is compatable with the /S switch to show
#   subdirectories (as long as the above rules are followed) and
#   all the files are shown with short names only. The
#   subdirectories are also shown with short names only. However,
#   the header for each subdirectory after the first level gives
#   the subdirectory's long name.
#
#  3. The /Z switch is also compatable with the /B switch to give
#   a simple list of files with short names only. When used with
#   the /S switch as well, all files are listed with their full
#   paths. The file names themselves are all in short form, and
#   the path of those files in the current directory are in short
#   form, but the paths of any files in subdirectories are in
#   long filename form.

        my $shortdir = '';
        my $i = 0;
        my @subdir = ();
        while ($dir =~ / \G ($q_char) /oxgc) {
            my $char = $1;
            if (($char eq '\\') or ($char eq '/')) {
                $i++;
                $subdir[$i] = $char;
                $i++;
            }
            else {
                $subdir[$i] .= $char;
            }
        }
        if (($subdir[-1] eq '\\') or ($subdir[-1] eq '/')) {
            pop @subdir;
        }

        # P.504 PERL5SHELL (Microsoft ports only)
        # in Chapter 19: The Command-Line Interface
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # P.597 PERL5SHELL (Microsoft ports only)
        # in Chapter 17: The Command-Line Interface
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        # Win95Cmd.exe on any Windows (when SET PERL5SHELL=Win95Cmd.exe /c, `var` returns "Windows 2000")
        # cmd.exe on Windows NT, Windows 2000
        if (qx{ver} =~ /\b(?:Windows NT|Windows 2000)\b/oms) {
            chomp(my @dirx = grep /<DIR>/oxms, qx{dir /ad /x "$dir*" 2>NUL});
            for my $dirx (sort { CORE::length($a) <=> CORE::length($b) } @dirx) {
                if (Ekps9566::fc(CORE::substr $dirx,-CORE::length($subdir[-1]),CORE::length($subdir[-1])) eq Ekps9566::fc($subdir[-1])) {

                    # short file name (8dot3name) here-----vv
                    my $shortleafdir = CORE::substr $dirx, 39, 8+1+3;
                    $shortleafdir =~ s/ [ ]+ \z//oxms;
                    $shortdir = join '', @subdir[0..$#subdir-1], $shortleafdir;
                    last;
                }
            }
        }

        # an idea (not so portable, only Windows 2000 or later)
        elsif (0) {
            chomp($shortdir = qx{for %I in ("$dir") do \@echo %~sI 2>NUL});
        }

        # cmd.exe on Windows XP, Windows 2003 or later
        elsif ((defined $ENV{'OS'}) and ($ENV{'OS'} eq 'Windows_NT')) {
            chomp(my @dirx = grep /<DIR>/oxms, qx{dir /ad /x "$dir*" 2>NUL});
            for my $dirx (sort { CORE::length($a) <=> CORE::length($b) } @dirx) {
                if (Ekps9566::fc(CORE::substr $dirx,-CORE::length($subdir[-1]),CORE::length($subdir[-1])) eq Ekps9566::fc($subdir[-1])) {

                    # short file name (8dot3name) here-----vv
                    my $shortleafdir = CORE::substr $dirx, 36, 8+1+3;
                    $shortleafdir =~ s/ [ ]+ \z//oxms;
                    $shortdir = join '', @subdir[0..$#subdir-1], $shortleafdir;
                    last;
                }
            }
        }

        # COMMAND.COM on Windows 95, Windows 98, Windows 98 Second Edition, Windows Millennium Edition
        else {
            chomp(my @dirx = grep /<DIR>/oxms, qx{dir /ad "$dir*"});
            for my $dirx (sort { CORE::length($a) <=> CORE::length($b) } @dirx) {
                if (Ekps9566::fc(CORE::substr $dirx,-CORE::length($subdir[-1]),CORE::length($subdir[-1])) eq Ekps9566::fc($subdir[-1])) {

                    # short file name (8dot3name) here-----v
                    my $shortleafdir = CORE::substr $dirx, 0, 8+1+3;
                    CORE::substr($shortleafdir,8,1) = '.';
                    $shortleafdir =~ s/ \. [ ]+ \z//oxms;
                    $shortdir = join '', @subdir[0..$#subdir-1], $shortleafdir;
                    last;
                }
            }
        }

        if ($shortdir eq '') {
            return 0;
        }
        elsif (Ekps9566::fc($shortdir) eq Ekps9566::fc($dir)) {
            return 0;
        }
        return CORE::chdir $shortdir;
    }
    else {
        return CORE::chdir $dir;
    }
}

#
# KPS9566 chr(0x5C) ended path on MSWin32
#
sub _MSWin32_5Cended_path {

    if ((@_ >= 1) and ($_[0] ne '')) {
        if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            my @char = $_[0] =~ /\G (?>$q_char) /oxmsg;
            if ($char[-1] =~ / \x5C \z/oxms) {
                return 1;
            }
        }
    }
    return undef;
}

#
# do KPS9566 file
#
sub Ekps9566::do($) {

    my($filename) = @_;

    my $realfilename;
    my $result;
ITER_DO:
    {
        for my $prefix (@INC) {
            if ($^O eq 'MacOS') {
                $realfilename = "$prefix$filename";
            }
            else {
                $realfilename = "$prefix/$filename";
            }

            if (Ekps9566::f($realfilename)) {

                my $script = '';

                if (Ekps9566::e("$realfilename.e")) {
                    my $e_mtime      = (Ekps9566::stat("$realfilename.e"))[9];
                    my $mtime        = (Ekps9566::stat($realfilename))[9];
                    my $module_mtime = (Ekps9566::stat(__FILE__))[9];
                    if (($e_mtime < $mtime) or ($mtime < $module_mtime)) {
                        Ekps9566::unlink "$realfilename.e";
                    }
                }

                if (Ekps9566::e("$realfilename.e")) {
                    my $fh = gensym();
                    if (_open_r($fh, "$realfilename.e")) {
                        if ($^O eq 'MacOS') {
                            CORE::eval q{
                                CORE::require Mac::Files;
                                Mac::Files::FSpSetFLock("$realfilename.e");
                            };
                        }
                        elsif (exists $ENV{'CHAR_NONBLOCK'}) {

                            # P.419 File Locking
                            # in Chapter 16: Interprocess Communication
                            # of ISBN 0-596-00027-8 Programming Perl Third Edition.

                            # P.524 File Locking
                            # in Chapter 15: Interprocess Communication
                            # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

                            # (and so on)

                            CORE::eval q{ flock($fh, LOCK_SH | LOCK_NB) };
                            if ($@) {
                                carp "Can't immediately read-lock the file: $realfilename.e";
                            }
                        }
                        else {
                            CORE::eval q{ flock($fh, LOCK_SH) };
                        }
                        local $/ = undef; # slurp mode
                        $script = <$fh>;
                        if ($^O eq 'MacOS') {
                            CORE::eval q{
                                CORE::require Mac::Files;
                                Mac::Files::FSpRstFLock("$realfilename.e");
                            };
                        }
                        close $fh;
                    }
                }
                else {
                    my $fh = gensym();
                    if (_open_r($fh, $realfilename)) {
                        if ($^O eq 'MacOS') {
                            CORE::eval q{
                                CORE::require Mac::Files;
                                Mac::Files::FSpSetFLock($realfilename);
                            };
                        }
                        elsif (exists $ENV{'CHAR_NONBLOCK'}) {
                            CORE::eval q{ flock($fh, LOCK_SH | LOCK_NB) };
                            if ($@) {
                                carp "Can't immediately read-lock the file: $realfilename";
                            }
                        }
                        else {
                            CORE::eval q{ flock($fh, LOCK_SH) };
                        }
                        local $/ = undef; # slurp mode
                        $script = <$fh>;
                        if ($^O eq 'MacOS') {
                            CORE::eval q{
                                CORE::require Mac::Files;
                                Mac::Files::FSpRstFLock($realfilename);
                            };
                        }
                        close $fh;
                    }

                    if ($script =~ /^ (?>\s*) use (?>\s+) KPS9566 (?>\s*) ([^\x81-\xFE;]*) ; (?>\s*) \n? $/oxms) {
                        CORE::require KPS9566;
                        $script = KPS9566::escape_script($script);
                        my $fh = gensym();
                        if (CORE::eval q{ use Fcntl qw(O_WRONLY O_APPEND O_CREAT); 1 } and CORE::sysopen($fh,"$realfilename.e",&O_WRONLY|&O_APPEND|&O_CREAT)) {
                        }
                        else {
                            _open_a($fh, "$realfilename.e") or die __FILE__, ": Can't write open file: $realfilename.e\n";
                        }
                        if ($^O eq 'MacOS') {
                            CORE::eval q{
                                CORE::require Mac::Files;
                                Mac::Files::FSpSetFLock("$realfilename.e");
                            };
                        }
                        elsif (exists $ENV{'CHAR_NONBLOCK'}) {
                            CORE::eval q{ flock($fh, LOCK_EX | LOCK_NB) };
                            if ($@) {
                                carp "Can't immediately write-lock the file: $realfilename.e";
                            }
                        }
                        else {
                            CORE::eval q{ flock($fh, LOCK_EX) };
                        }
                        CORE::eval q{ truncate($fh, 0) };
                        seek($fh, 0, 0) or croak "Can't seek file: $realfilename.e";
                        print {$fh} $script;
                        if ($^O eq 'MacOS') {
                            CORE::eval q{
                                CORE::require Mac::Files;
                                Mac::Files::FSpRstFLock("$realfilename.e");
                            };
                        }
                        close $fh;
                    }
                }

                if (CORE::eval { local $@; CORE::require strict }) {
                    strict::->unimport;
                }
                $result = scalar CORE::eval $script;

                last ITER_DO;
            }
        }
    }

    if ($@) {
        $INC{$filename} = undef;
        return undef;
    }
    elsif (not $result) {
        return undef;
    }
    else {
        $INC{$filename} = $realfilename;
        return $result;
    }
}

#
# require KPS9566 file
#

# require
# in Chapter 3: Functions
# of ISBN 1-56592-149-6 Programming Perl, Second Edition.
#
# sub require {
#     my($filename) = @_;
#     return 1 if $INC{$filename};
#     my($realfilename, $result);
#     ITER: {
#         foreach $prefix (@INC) {
#             $realfilename = "$prefix/$filename";
#             if (-f $realfilename) {
#                 $result = CORE::eval `cat $realfilename`;
#                 last ITER;
#             }
#         }
#         die "Can't find $filename in \@INC";
#     }
#     die $@ if $@;
#     die "$filename did not return true value" unless $result;
#     $INC{$filename} = $realfilename;
#     return $result;
# }

# require
# in Chapter 9: perlfunc: Perl builtin functions
# of ISBN-13: 978-1-906966-02-7 The Perl Language Reference Manual (for Perl version 5.12.1)
#
# sub require {
#     my($filename) = @_;
#     if (exists $INC{$filename}) {
#         return 1 if $INC{$filename};
#         die "Compilation failed in require";
#     }
#     my($realfilename, $result);
#     ITER: {
#         foreach $prefix (@INC) {
#             $realfilename = "$prefix/$filename";
#             if (-f $realfilename) {
#                 $INC{$filename} = $realfilename;
#                 $result = do $realfilename;
#                 last ITER;
#             }
#         }
#         die "Can't find $filename in \@INC";
#     }
#     if ($@) {
#         $INC{$filename} = undef;
#         die $@;
#     }
#     elsif (!$result) {
#         delete $INC{$filename};
#         die "$filename did not return true value";
#     }
#     else {
#         return $result;
#     }
# }

sub Ekps9566::require(;$) {

    local $_ = shift if @_;

    if (exists $INC{$_}) {
        return 1 if $INC{$_};
        croak "Compilation failed in require: $_";
    }

    # jcode.pl
    # ftp://ftp.iij.ad.jp/pub/IIJ/dist/utashiro/perl/

    # jacode.pl
    # http://search.cpan.org/dist/jacode/

    if (/ \b (?: jcode\.pl | jacode(?>[0-9]*)\.pl ) \z /oxms) {
        return CORE::require($_);
    }

    my $realfilename;
    my $result;
ITER_REQUIRE:
    {
        for my $prefix (@INC) {
            if ($^O eq 'MacOS') {
                $realfilename = "$prefix$_";
            }
            else {
                $realfilename = "$prefix/$_";
            }

            if (Ekps9566::f($realfilename)) {
                $INC{$_} = $realfilename;

                my $script = '';

                if (Ekps9566::e("$realfilename.e")) {
                    my $e_mtime      = (Ekps9566::stat("$realfilename.e"))[9];
                    my $mtime        = (Ekps9566::stat($realfilename))[9];
                    my $module_mtime = (Ekps9566::stat(__FILE__))[9];
                    if (($e_mtime < $mtime) or ($mtime < $module_mtime)) {
                        Ekps9566::unlink "$realfilename.e";
                    }
                }

                if (Ekps9566::e("$realfilename.e")) {
                    my $fh = gensym();
                    _open_r($fh, "$realfilename.e") or croak "Can't open file: $realfilename.e";
                    if ($^O eq 'MacOS') {
                        CORE::eval q{
                            CORE::require Mac::Files;
                            Mac::Files::FSpSetFLock("$realfilename.e");
                        };
                    }
                    elsif (exists $ENV{'CHAR_NONBLOCK'}) {
                        CORE::eval q{ flock($fh, LOCK_SH | LOCK_NB) };
                        if ($@) {
                            carp "Can't immediately read-lock the file: $realfilename.e";
                        }
                    }
                    else {
                        CORE::eval q{ flock($fh, LOCK_SH) };
                    }
                    local $/ = undef; # slurp mode
                    $script = <$fh>;
                    if ($^O eq 'MacOS') {
                        CORE::eval q{
                            CORE::require Mac::Files;
                            Mac::Files::FSpRstFLock("$realfilename.e");
                        };
                    }
                    close($fh) or croak "Can't close file: $realfilename";
                }
                else {
                    my $fh = gensym();
                    _open_r($fh, $realfilename) or croak "Can't open file: $realfilename";
                    if ($^O eq 'MacOS') {
                        CORE::eval q{
                            CORE::require Mac::Files;
                            Mac::Files::FSpSetFLock($realfilename);
                        };
                    }
                    elsif (exists $ENV{'CHAR_NONBLOCK'}) {
                        CORE::eval q{ flock($fh, LOCK_SH | LOCK_NB) };
                        if ($@) {
                            carp "Can't immediately read-lock the file: $realfilename";
                        }
                    }
                    else {
                        CORE::eval q{ flock($fh, LOCK_SH) };
                    }
                    local $/ = undef; # slurp mode
                    $script = <$fh>;
                    if ($^O eq 'MacOS') {
                        CORE::eval q{
                            CORE::require Mac::Files;
                            Mac::Files::FSpRstFLock($realfilename);
                        };
                    }
                    close($fh) or croak "Can't close file: $realfilename";

                    if ($script =~ /^ (?>\s*) use (?>\s+) KPS9566 (?>\s*) ([^\x81-\xFE;]*) ; (?>\s*) \n? $/oxms) {
                        CORE::require KPS9566;
                        $script = KPS9566::escape_script($script);
                        my $fh = gensym();
                        if (CORE::eval q{ use Fcntl qw(O_WRONLY O_APPEND O_CREAT); 1 } and CORE::sysopen($fh,"$realfilename.e",&O_WRONLY|&O_APPEND|&O_CREAT)) {
                        }
                        else {
                            _open_a($fh, "$realfilename.e") or croak "Can't write open file: $realfilename.e";
                        }
                        if ($^O eq 'MacOS') {
                            CORE::eval q{
                                CORE::require Mac::Files;
                                Mac::Files::FSpSetFLock("$realfilename.e");
                            };
                        }
                        elsif (exists $ENV{'CHAR_NONBLOCK'}) {
                            CORE::eval q{ flock($fh, LOCK_EX | LOCK_NB) };
                            if ($@) {
                                carp "Can't immediately write-lock the file: $realfilename.e";
                            }
                        }
                        else {
                            CORE::eval q{ flock($fh, LOCK_EX) };
                        }
                        CORE::eval q{ truncate($fh, 0) };
                        seek($fh, 0, 0) or croak "Can't seek file: $realfilename.e";
                        print {$fh} $script;
                        if ($^O eq 'MacOS') {
                            CORE::eval q{
                                CORE::require Mac::Files;
                                Mac::Files::FSpRstFLock("$realfilename.e");
                            };
                        }
                        close($fh) or croak "Can't close file: $realfilename";
                    }
                }

                if (CORE::eval { local $@; CORE::require strict }) {
                    strict::->unimport;
                }
                $result = scalar CORE::eval $script;

                last ITER_REQUIRE;
            }
        }
        croak "Can't find $_ in \@INC";
    }

    if ($@) {
        $INC{$_} = undef;
        croak $@;
    }
    elsif (not $result) {
        delete $INC{$_};
        croak "$_ did not return true value";
    }
    else {
        return $result;
    }
}

#
# KPS9566 telldir avoid warning
#
sub Ekps9566::telldir(*) {

    local $^W = 0;

    return CORE::telldir $_[0];
}

#
# ${^PREMATCH}, $PREMATCH, $` the string preceding what was matched
#
sub Ekps9566::PREMATCH {
    if (defined($&)) {
        if (defined($1) and (CORE::substr($&,-CORE::length($1),CORE::length($1)) eq $1)) {
            return CORE::substr($&,0,CORE::length($&)-CORE::length($1));
        }
        else {
            croak 'Use of "$`", $PREMATCH, and ${^PREMATCH} need to /( capture all )/ in regexp';
        }
    }
    else {
        return '';
    }
    return $`;
}

#
# ${^MATCH}, $MATCH, $& the string that matched
#
sub Ekps9566::MATCH {
    if (defined($&)) {
        if (defined($1)) {
            return $1;
        }
        else {
            croak 'Use of "$&", $MATCH, and ${^MATCH} need to /( capture all )/ in regexp';
        }
    }
    else {
        return '';
    }
    return $&;
}

#
# ${^POSTMATCH}, $POSTMATCH, $' the string following what was matched
#
sub Ekps9566::POSTMATCH {
    return $';
}

#
# KPS9566 character to order (with parameter)
#
sub KPS9566::ord(;$) {

    local $_ = shift if @_;

    if (/\A ($q_char) /oxms) {
        my @ord = unpack 'C*', $1;
        my $ord = 0;
        while (my $o = shift @ord) {
            $ord = $ord * 0x100 + $o;
        }
        return $ord;
    }
    else {
        return CORE::ord $_;
    }
}

#
# KPS9566 character to order (without parameter)
#
sub KPS9566::ord_() {

    if (/\A ($q_char) /oxms) {
        my @ord = unpack 'C*', $1;
        my $ord = 0;
        while (my $o = shift @ord) {
            $ord = $ord * 0x100 + $o;
        }
        return $ord;
    }
    else {
        return CORE::ord $_;
    }
}

#
# KPS9566 reverse
#
sub KPS9566::reverse(@) {

    if (wantarray) {
        return CORE::reverse @_;
    }
    else {

        # One of us once cornered Larry in an elevator and asked him what
        # problem he was solving with this, but he looked as far off into
        # the distance as he could in an elevator and said, "It seemed like
        # a good idea at the time."

        return join '', CORE::reverse(join('',@_) =~ /\G ($q_char) /oxmsg);
    }
}

#
# KPS9566 getc (with parameter, without parameter)
#
sub KPS9566::getc(;*@) {

    my($package) = caller;
    my $fh = @_ ? qualify_to_ref(shift,$package) : \*STDIN;
    croak 'Too many arguments for KPS9566::getc' if @_ and not wantarray;

    my @length = sort { $a <=> $b } keys %range_tr;
    my $getc = '';
    for my $length ($length[0] .. $length[-1]) {
        $getc .= CORE::getc($fh);
        if (exists $range_tr{CORE::length($getc)}) {
            if ($getc =~ /\A ${Ekps9566::dot_s} \z/oxms) {
                return wantarray ? ($getc,@_) : $getc;
            }
        }
    }
    return wantarray ? ($getc,@_) : $getc;
}

#
# KPS9566 length by character
#
sub KPS9566::length(;$) {

    local $_ = shift if @_;

    local @_ = /\G ($q_char) /oxmsg;
    return scalar @_;
}

#
# KPS9566 substr by character
#
BEGIN {

    # P.232 The lvalue Attribute
    # in Chapter 6: Subroutines
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.336 The lvalue Attribute
    # in Chapter 7: Subroutines
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    # P.144 8.4 Lvalue subroutines
    # in Chapter 8: perlsub: Perl subroutines
    # of ISBN-13: 978-1-906966-02-7 The Perl Language Reference Manual (for Perl version 5.12.1)

    CORE::eval sprintf(<<'END', ($] >= 5.014000) ? ':lvalue' : '');
    #                       vv----------------------*******
    sub KPS9566::substr($$;$$) %s {

        my @char = $_[0] =~ /\G (?>$q_char) /oxmsg;

        # If the substring is beyond either end of the string, substr() returns the undefined
        # value and produces a warning. When used as an lvalue, specifying a substring that
        # is entirely outside the string raises an exception.
        # http://perldoc.perl.org/functions/substr.html

        # A return with no argument returns the scalar value undef in scalar context,
        # an empty list () in list context, and (naturally) nothing at all in void
        # context.

        my $offset = $_[1];
        if (($offset > scalar(@char)) or ($offset < (-1 * scalar(@char)))) {
            return;
        }

        # substr($string,$offset,$length,$replacement)
        if (@_ == 4) {
            my(undef,undef,$length,$replacement) = @_;
            my $substr = join '', splice(@char, $offset, $length, $replacement);
            $_[0] = join '', @char;

            # return $substr; this doesn't work, don't say "return"
            $substr;
        }

        # substr($string,$offset,$length)
        elsif (@_ == 3) {
            my(undef,undef,$length) = @_;
            my $octet_offset = 0;
            my $octet_length = 0;
            if ($offset == 0) {
                $octet_offset = 0;
            }
            elsif ($offset > 0) {
                $octet_offset =      CORE::length(join '', @char[0..$offset-1]);
            }
            else {
                $octet_offset = -1 * CORE::length(join '', @char[$#char+$offset+1..$#char]);
            }
            if ($length == 0) {
                $octet_length = 0;
            }
            elsif ($length > 0) {
                $octet_length =      CORE::length(join '', @char[$offset..$offset+$length-1]);
            }
            else {
                $octet_length = -1 * CORE::length(join '', @char[$#char+$length+1..$#char]);
            }
            CORE::substr($_[0], $octet_offset, $octet_length);
        }

        # substr($string,$offset)
        else {
            my $octet_offset = 0;
            if ($offset == 0) {
                $octet_offset = 0;
            }
            elsif ($offset > 0) {
                $octet_offset =      CORE::length(join '', @char[0..$offset-1]);
            }
            else {
                $octet_offset = -1 * CORE::length(join '', @char[$#char+$offset+1..$#char]);
            }
            CORE::substr($_[0], $octet_offset);
        }
    }
END
}

#
# KPS9566 index by character
#
sub KPS9566::index($$;$) {

    my $index;
    if (@_ == 3) {
        $index = Ekps9566::index($_[0], $_[1], CORE::length(KPS9566::substr($_[0], 0, $_[2])));
    }
    else {
        $index = Ekps9566::index($_[0], $_[1]);
    }

    if ($index == -1) {
        return -1;
    }
    else {
        return KPS9566::length(CORE::substr $_[0], 0, $index);
    }
}

#
# KPS9566 rindex by character
#
sub KPS9566::rindex($$;$) {

    my $rindex;
    if (@_ == 3) {
        $rindex = Ekps9566::rindex($_[0], $_[1], CORE::length(KPS9566::substr($_[0], 0, $_[2])));
    }
    else {
        $rindex = Ekps9566::rindex($_[0], $_[1]);
    }

    if ($rindex == -1) {
        return -1;
    }
    else {
        return KPS9566::length(CORE::substr $_[0], 0, $rindex);
    }
}

# when 'm//', '/' means regexp match 'm//' and '?' means regexp match '??'
# when 'div', '/' means division operator and '?' means conditional operator (condition ? then : else)
BEGIN { CORE::eval q{ use vars qw($slash) } } $slash = 'm//';

# ord() to ord() or KPS9566::ord()
BEGIN { CORE::eval q{ use vars qw($function_ord) } }     $function_ord     = 'ord';

# ord to ord or KPS9566::ord_
BEGIN { CORE::eval q{ use vars qw($function_ord_) } }    $function_ord_    = 'ord';

# reverse to reverse or KPS9566::reverse
BEGIN { CORE::eval q{ use vars qw($function_reverse) } } $function_reverse = 'reverse';

# getc to getc or KPS9566::getc
BEGIN { CORE::eval q{ use vars qw($function_getc) } }    $function_getc    = 'getc';

# P.1023 Appendix W.9 Multibyte Anchoring
# of ISBN 1-56592-224-7 CJKV Information Processing

my $anchor = '';
$anchor = q{${Ekps9566::anchor}};

BEGIN { CORE::eval q{ use vars qw($nest) } }

# regexp of nested parens in qqXX

# P.340 Matching Nested Constructs with Embedded Code
# in Chapter 7: Perl
# of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

my $qq_paren   = qr{(?{local $nest=0}) (?>(?:
                       [^\x81-\xFE\\()] |
                           \(  (?{$nest++}) |
                           \)  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!)) |
                       [\x81-\xFE][\x00-\xFF] |
                    \\ [^\x81-\xFEc] |
                    \\c[\x40-\x5F] |
                    \\ [\x81-\xFE][\x00-\xFF] |
                       [\x00-\xFF]
                 }xms;

my $qq_brace   = qr{(?{local $nest=0}) (?>(?:
                       [^\x81-\xFE\\{}] |
                           \{  (?{$nest++}) |
                           \}  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!)) |
                       [\x81-\xFE][\x00-\xFF] |
                    \\ [^\x81-\xFEc] |
                    \\c[\x40-\x5F] |
                    \\ [\x81-\xFE][\x00-\xFF] |
                       [\x00-\xFF]
                 }xms;

my $qq_bracket = qr{(?{local $nest=0}) (?>(?:
                       [^\x81-\xFE\\\[\]] |
                           \[  (?{$nest++}) |
                           \]  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!)) |
                       [\x81-\xFE][\x00-\xFF] |
                    \\ [^\x81-\xFEc] |
                    \\c[\x40-\x5F] |
                    \\ [\x81-\xFE][\x00-\xFF] |
                       [\x00-\xFF]
                 }xms;

my $qq_angle   = qr{(?{local $nest=0}) (?>(?:
                       [^\x81-\xFE\\<>] |
                           \<  (?{$nest++}) |
                           \>  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!)) |
                       [\x81-\xFE][\x00-\xFF] |
                    \\ [^\x81-\xFEc] |
                    \\c[\x40-\x5F] |
                    \\ [\x81-\xFE][\x00-\xFF] |
                       [\x00-\xFF]
                 }xms;

my $qq_scalar  = qr{(?: \{ (?:$qq_brace)*? \} |
                       (?: ::)? (?:
                             (?> [a-zA-Z_][a-zA-Z_0-9]* (?: ::[a-zA-Z_][a-zA-Z_0-9]*)* )
                                                    (?>(?:                                   \[ (?: \$\[ | \$\] | $qq_char )*? \] |           \{ (?:$qq_brace)*? \} )*)
                                      (?>(?: (?: -> )? (?: [\$\@\%\&\*]\* | \$\#\* | [\@\%]? \[ (?: \$\[ | \$\] | $qq_char )*? \] | [\@\%\*]? \{ (?:$qq_brace)*? \} ) )*)
                   ))
                 }xms;

my $qq_variable = qr{(?: \{ (?:$qq_brace)*? \}                    |
                        (?: ::)? (?:
                              (?>[0-9]+)                          |
                              [^\x81-\xFEa-zA-Z_0-9\[\]] |
                              ^[A-Z]                              |
                              (?> [a-zA-Z_][a-zA-Z_0-9]* (?: ::[a-zA-Z_][a-zA-Z_0-9]*)* )
                                                     (?>(?:                                   \[ (?: \$\[ | \$\] | $qq_char )*? \] |           \{ (?:$qq_brace)*? \} )*)
                                       (?>(?: (?: -> )? (?: [\$\@\%\&\*]\* | \$\#\* | [\@\%]? \[ (?: \$\[ | \$\] | $qq_char )*? \] | [\@\%\*]? \{ (?:$qq_brace)*? \} ) )*)
                    ))
                  }xms;

my $qq_substr  = qr{(?> Char::substr | KPS9566::substr | CORE::substr | substr ) (?>\s*) \( $qq_paren \)
                 }xms;

# regexp of nested parens in qXX
my $q_paren    = qr{(?{local $nest=0}) (?>(?:
                       [^\x81-\xFE()] |
                       [\x81-\xFE][\x00-\xFF] |
                             \(  (?{$nest++}) |
                             \)  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!)) |
                       [\x00-\xFF]
                 }xms;

my $q_brace    = qr{(?{local $nest=0}) (?>(?:
                       [^\x81-\xFE\{\}] |
                       [\x81-\xFE][\x00-\xFF] |
                             \{  (?{$nest++}) |
                             \}  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!)) |
                       [\x00-\xFF]
                 }xms;

my $q_bracket  = qr{(?{local $nest=0}) (?>(?:
                       [^\x81-\xFE\[\]] |
                       [\x81-\xFE][\x00-\xFF] |
                             \[  (?{$nest++}) |
                             \]  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!)) |
                    [\x00-\xFF]
                 }xms;

my $q_angle    = qr{(?{local $nest=0}) (?>(?:
                    [^\x81-\xFE<>] |
                    [\x81-\xFE][\x00-\xFF] |
                             \<  (?{$nest++}) |
                             \>  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!)) |
                    [\x00-\xFF]
                 }xms;

my $matched     = '';
my $s_matched   = '';
$matched        = q{$Ekps9566::matched};
$s_matched      = q{ Ekps9566::s_matched();};

my $tr_variable   = '';   # variable of tr///
my $sub_variable  = '';   # variable of s///
my $bind_operator = '';   # =~ or !~

my @heredoc = ();         # here document
my @heredoc_delimiter = ();
my $here_script = '';     # here script

#
# escape KPS9566 script
#
sub KPS9566::escape(;$) {
    local($_) = $_[0] if @_;

    # P.359 The Study Function
    # in Chapter 7: Perl
    # of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

    study $_; # Yes, I studied study yesterday.

    # while all script

    # 6.14. Matching from Where the Last Pattern Left Off
    # in Chapter 6. Pattern Matching
    # of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.
    # (and so on)

    # one member of Tag-team
    #
    # P.128 Start of match (or end of previous match): \G
    # P.130 Advanced Use of \G with Perl
    # in Chapter 3: Overview of Regular Expression Features and Flavors
    # P.255 Use leading anchors
    # P.256 Expose ^ and \G at the front expressions
    # in Chapter 6: Crafting an Efficient Expression
    # P.315 "Tag-team" matching with /gc
    # in Chapter 7: Perl
    # of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

    my $e_script = '';
    while (not /\G \z/oxgc) { # member
        $e_script .= KPS9566::escape_token();
    }

    return $e_script;
}

#
# escape KPS9566 token of script
#
sub KPS9566::escape_token {

# \n output here document

    my $ignore_modules = join('|', qw(
        utf8
        bytes
        charnames
        I18N::Japanese
        I18N::Collate
        I18N::JExt
        File::DosGlob
        Wild
        Wildcard
        Japanese
    ));

    # another member of Tag-team
    #
    # P.315 "Tag-team" matching with /gc
    # in Chapter 7: Perl
    # of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

    if (/\G ( \n ) /oxgc) { # another member (and so on)
        my $heredoc = '';
        if (scalar(@heredoc_delimiter) >= 1) {
            $slash = 'm//';

            $heredoc = join '', @heredoc;
            @heredoc = ();

            # skip here document
            for my $heredoc_delimiter (@heredoc_delimiter) {
                /\G .*? \n $heredoc_delimiter \n/xmsgc;
            }
            @heredoc_delimiter = ();

            $here_script = '';
        }
        return "\n" . $heredoc;
    }

# ignore space, comment
    elsif (/\G ((?>\s+)|\#.*) /oxgc) { return $1; }

# if (, elsif (, unless (, while (, until (, given (, and when (

    # given, when

    # P.225 The given Statement
    # in Chapter 15: Smart Matching and given-when
    # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

    # P.133 The given Statement
    # in Chapter 4: Statements and Declarations
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    elsif (/\G ( (?: if | elsif | unless | while | until | given | when ) (?>\s*) \( ) /oxgc) {
        $slash = 'm//';
        return $1;
    }

# scalar variable ($scalar = ...) =~ tr///;
# scalar variable ($scalar = ...) =~ s///;

    # state

    # P.68 Persistent, Private Variables
    # in Chapter 4: Subroutines
    # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

    # P.160 Persistent Lexically Scoped Variables: state
    # in Chapter 4: Statements and Declarations
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    # (and so on)

    elsif (/\G ( \( (?>\s*) (?: local \b | my \b | our \b | state \b )? (?>\s*) \$ $qq_scalar ) /oxgc) {
        my $e_string = e_string($1);

        if (/\G ( (?>\s*) = $qq_paren \) ) ( (?>\s*) (?: =~ | !~ ) (?>\s*) ) (?= (?: tr | y ) \b ) /oxgc) {
            $tr_variable = $e_string . e_string($1);
            $bind_operator = $2;
            $slash = 'm//';
            return '';
        }
        elsif (/\G ( (?>\s*) = $qq_paren \) ) ( (?>\s*) (?: =~ | !~ ) (?>\s*) ) (?= s \b ) /oxgc) {
            $sub_variable = $e_string . e_string($1);
            $bind_operator = $2;
            $slash = 'm//';
            return '';
        }
        else {
            $slash = 'div';
            return $e_string;
        }
    }

# $`, ${`}, $PREMATCH, ${PREMATCH}, ${^PREMATCH} --> Ekps9566::PREMATCH()
    elsif (/\G ( \$` | \$\{`\} | \$ (?>\s*) PREMATCH  \b | \$ (?>\s*) \{ (?>\s*) PREMATCH  (?>\s*) \} | \$ (?>\s*) \{\^PREMATCH\}  ) /oxmsgc) {
        $slash = 'div';
        return q{Ekps9566::PREMATCH()};
    }

# $&, ${&}, $MATCH, ${MATCH}, ${^MATCH} --> Ekps9566::MATCH()
    elsif (/\G ( \$& | \$\{&\} | \$ (?>\s*) MATCH     \b | \$ (?>\s*) \{ (?>\s*) MATCH     (?>\s*) \} | \$ (?>\s*) \{\^MATCH\}     ) /oxmsgc) {
        $slash = 'div';
        return q{Ekps9566::MATCH()};
    }

# $', ${'} --> $', ${'}
    elsif (/\G ( \$' | \$\{'\}                                                                                                     ) /oxmsgc) {
        $slash = 'div';
        return $1;
    }

# $POSTMATCH, ${POSTMATCH}, ${^POSTMATCH} --> Ekps9566::POSTMATCH()
    elsif (/\G (                 \$ (?>\s*) POSTMATCH \b | \$ (?>\s*) \{ (?>\s*) POSTMATCH (?>\s*) \} | \$ (?>\s*) \{\^POSTMATCH\} ) /oxmsgc) {
        $slash = 'div';
        return q{Ekps9566::POSTMATCH()};
    }

# scalar variable $scalar =~ tr///;
# scalar variable $scalar =~ s///;
# substr() =~ tr///;
# substr() =~ s///;
    elsif (/\G ( \$ $qq_scalar | $qq_substr ) /oxgc) {
        my $scalar = e_string($1);

        if (/\G (    (?>\s*) (?: =~ | !~ ) (?>\s*) ) (?= (?: tr | y ) \b ) /oxgc) {
            $tr_variable = $scalar;
            $bind_operator = $1;
            $slash = 'm//';
            return '';
        }
        elsif (/\G ( (?>\s*) (?: =~ | !~ ) (?>\s*) ) (?= s            \b ) /oxgc) {
            $sub_variable = $scalar;
            $bind_operator = $1;
            $slash = 'm//';
            return '';
        }
        else {
            $slash = 'div';
            return $scalar;
        }
    }

    # end of statement
    elsif (/\G ( [,;] ) /oxgc) {
        $slash = 'm//';

        # clear tr/// variable
        $tr_variable  = '';

        # clear s/// variable
        $sub_variable  = '';

        $bind_operator = '';

        return $1;
    }

# bareword
    elsif (/\G ( \{ (?>\s*) (?: tr | index | rindex | reverse ) (?>\s*) \} ) /oxmsgc) {
        return $1;
    }

# $0 --> $0
    elsif (/\G ( \$ 0 ) /oxmsgc) {
        $slash = 'div';
        return $1;
    }
    elsif (/\G ( \$ \{ (?>\s*) 0 (?>\s*) \} ) /oxmsgc) {
        $slash = 'div';
        return $1;
    }

# $$ --> $$
    elsif (/\G ( \$ \$ ) (?![\w\{]) /oxmsgc) {
        $slash = 'div';
        return $1;
    }

# $1, $2, $3 --> $2, $3, $4 after s/// with multibyte anchoring
# $1, $2, $3 --> $1, $2, $3 otherwise
    elsif (/\G \$ ((?>[1-9][0-9]*)) /oxmsgc) {
        $slash = 'div';
        return e_capture($1);
    }
    elsif (/\G \$ \{ (?>\s*) ((?>[1-9][0-9]*)) (?>\s*) \} /oxmsgc) {
        $slash = 'div';
        return e_capture($1);
    }

# $$foo[ ... ] --> $ $foo->[ ... ]
    elsif (/\G \$ ( \$ (?> [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) ( \[ .+? \] ) /oxmsgc) {
        $slash = 'div';
        return e_capture($1.'->'.$2);
    }

# $$foo{ ... } --> $ $foo->{ ... }
    elsif (/\G \$ ( \$ (?> [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) ( \{ .+? \} ) /oxmsgc) {
        $slash = 'div';
        return e_capture($1.'->'.$2);
    }

# $$foo
    elsif (/\G \$ ( \$ (?> [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) /oxmsgc) {
        $slash = 'div';
        return e_capture($1);
    }

# ${ foo }
    elsif (/\G \$ (?>\s*) \{ ( (?>\s*) (?> [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* ) (?>\s*) ) \} /oxmsgc) {
        $slash = 'div';
        return '${' . $1 . '}';
    }

# ${ ... }
    elsif (/\G \$ (?>\s*) \{ (?>\s*) ( $qq_brace ) (?>\s*) \} /oxmsgc) {
        $slash = 'div';
        return e_capture($1);
    }

# variable or function
    #                  $ @ % & *     $ #
    elsif (/\G ( (?: [\$\@\%\&\*] | \$\# | -> | \b sub \b) (?>\s*) (?: split | chop | index | rindex | lc | uc | fc | chr | ord | reverse | getc | tr | y | q | qq | qx | qw | m | s | qr | glob | lstat | opendir | stat | unlink | chdir ) ) \b /oxmsgc) {
        $slash = 'div';
        return $1;
    }
    #                $ $ $ $ $ $ $ $ $ $ $ $ $ $
    #                $ @ # \ ' " / ? ( ) [ ] < >
    elsif (/\G ( \$[\$\@\#\\\'\"\/\?\(\)\[\]\<\>] ) /oxmsgc) {
        $slash = 'div';
        return $1;
    }

# while (<FILEHANDLE>)
    elsif (/\G \b (while (?>\s*) \( (?>\s*) <[\$]?[A-Za-z_][A-Za-z_0-9]*> (?>\s*) \)) \b /oxgc) {
        return $1;
    }

# while (<WILDCARD>) --- glob

    # avoid "Error: Runtime exception" of perl version 5.005_03

    elsif (/\G \b while (?>\s*) \( (?>\s*) < ((?:[^\x81-\xFE>\0\a\e\f\n\r\t]|[\x81-\xFE][\x00-\xFF])+?) > (?>\s*) \) \b /oxgc) {
        return 'while ($_ = Ekps9566::glob("' . $1 . '"))';
    }

# while (glob)
    elsif (/\G \b while (?>\s*) \( (?>\s*) glob (?>\s*) \) /oxgc) {
        return 'while ($_ = Ekps9566::glob_)';
    }

# while (glob(WILDCARD))
    elsif (/\G \b while (?>\s*) \( (?>\s*) glob \b /oxgc) {
        return 'while ($_ = Ekps9566::glob';
    }

# doit if, doit unless, doit while, doit until, doit for, doit when
    elsif (/\G \b ( if | unless | while | until | for | when ) \b /oxgc) { $slash = 'm//'; return $1; }

# subroutines of package Ekps9566
    elsif (/\G \b (CORE:: | ->(>?\s*) (?: atan2 | [a-z]{2,})) \b       /oxgc) { $slash = 'm//'; return $1;                  }
    elsif (/\G \b Char::eval       (?= (?>\s*) \{ )                    /oxgc) { $slash = 'm//'; return 'eval';              }
    elsif (/\G \b KPS9566::eval       (?= (?>\s*) \{ )                    /oxgc) { $slash = 'm//'; return 'eval';              }
    elsif (/\G \b Char::eval    \b (?! (?>\s*) => )                    /oxgc) { $slash = 'm//'; return 'eval Char::escape'; }
    elsif (/\G \b KPS9566::eval    \b (?! (?>\s*) => )                    /oxgc) { $slash = 'm//'; return 'eval KPS9566::escape'; }
    elsif (/\G \b bytes::substr \b (?! (?>\s*) => )                    /oxgc) { $slash = 'm//'; return 'substr';            }
    elsif (/\G \b chop \b          (?! (?>\s*) => )                    /oxgc) { $slash = 'm//'; return 'Ekps9566::chop';       }
    elsif (/\G \b bytes::index \b  (?! (?>\s*) => )                    /oxgc) { $slash = 'm//'; return 'index';             }
    elsif (/\G \b Char::index \b   (?! (?>\s*) => )                    /oxgc) { $slash = 'm//'; return 'Char::index';       }
    elsif (/\G \b KPS9566::index \b   (?! (?>\s*) => )                    /oxgc) { $slash = 'm//'; return 'KPS9566::index';       }
    elsif (/\G \b index \b         (?! (?>\s*) => )                    /oxgc) { $slash = 'm//'; return 'Ekps9566::index';      }
    elsif (/\G \b bytes::rindex \b (?! (?>\s*) => )                    /oxgc) { $slash = 'm//'; return 'rindex';            }
    elsif (/\G \b Char::rindex \b  (?! (?>\s*) => )                    /oxgc) { $slash = 'm//'; return 'Char::rindex';      }
    elsif (/\G \b KPS9566::rindex \b  (?! (?>\s*) => )                    /oxgc) { $slash = 'm//'; return 'KPS9566::rindex';      }
    elsif (/\G \b rindex \b        (?! (?>\s*) => )                    /oxgc) { $slash = 'm//'; return 'Ekps9566::rindex';     }
    elsif (/\G \b lc      (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Ekps9566::lc';         }
    elsif (/\G \b lcfirst (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Ekps9566::lcfirst';    }
    elsif (/\G \b uc      (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Ekps9566::uc';         }
    elsif (/\G \b ucfirst (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Ekps9566::ucfirst';    }
    elsif (/\G \b fc      (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Ekps9566::fc';         }

    # stacked file test operators

    # P.179 File Test Operators
    # in Chapter 12: File Tests
    # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

    # P.106 Named Unary and File Test Operators
    # in Chapter 3: Unary and Binary Operators
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    # (and so on)

    elsif (/\G (-[rwxoRWXOezfdlpSbcugkTB] (?>(?:\s+ -[rwxoRWXOezfdlpSbcugkTB])+))
                                                             (?>\s*) (\") ((?:$qq_char)+?)             (\") /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1)," . e_qq('',  $2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) qq (?>\s*) (\#) ((?:$qq_char)+?)             (\#) /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) qq (?>\s*) (\() ((?:$qq_paren)+?)            (\)) /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) qq (?>\s*) (\{) ((?:$qq_brace)+?)            (\}) /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) qq (?>\s*) (\[) ((?:$qq_bracket)+?)          (\]) /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) qq (?>\s*) (\<) ((?:$qq_angle)+?)            (\>) /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) qq (?>\s*) (\S) ((?:$qq_char)+?)             (\2) /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; }

    elsif (/\G (-[rwxoRWXOezfdlpSbcugkTB] (?>(?:\s+ -[rwxoRWXOezfdlpSbcugkTB])+))
                                                             (?>\s*) (\') ((?:\\\'|\\\\|$q_char)+?)    (\') /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1)," . e_q ('',  $2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) q  (?>\s*) (\#) ((?:\\\#|\\\\|$q_char)+?)    (\#) /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) q  (?>\s*) (\() ((?:\\\)|\\\\|$q_paren)+?)   (\)) /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) q  (?>\s*) (\{) ((?:\\\}|\\\\|$q_brace)+?)   (\}) /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) q  (?>\s*) (\[) ((?:\\\]|\\\\|$q_bracket)+?) (\]) /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) q  (?>\s*) (\<) ((?:\\\>|\\\\|$q_angle)+?)   (\>) /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) q  (?>\s*) (\S) ((?:\\\2|\\\\|$q_char)+?)    (\2) /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; }

    elsif (/\G (-[rwxoRWXOezfdlpSbcugkTB] (?>(?:\s+ -[rwxoRWXOezfdlpSbcugkTB])+)) (\$ (?> \w+ (?: ::\w+)* ) (?: (?: ->)? (?: [\$\@\%\&\*]\* | \$\#\* | \( (?:$qq_paren)*? \) | [\@\%\*]? \{ (?:$qq_brace)+? \} | [\@\%]? \[ (?:$qq_bracket)+? \] ) )*) /oxgc)
                                                                                                                   { $slash = 'm//'; return "Ekps9566::filetest(qw($1),$2)"; }
    elsif (/\G (-[rwxoRWXOezfdlpSbcugkTB] (?>(?:\s+ -[rwxoRWXOezfdlpSbcugkTB])+)) \( ((?:$qq_paren)*?) \)   /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1),$2)"; }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) (?= [a-z]+)                                       /oxgc) { $slash = 'm//'; return "Ekps9566::filetest qw($1),";    }
    elsif (/\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) ((?>\w+))                                         /oxgc) { $slash = 'm//'; return "Ekps9566::filetest(qw($1),$2)"; }

    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC])            (?>\s*) (\") ((?:$qq_char)+?)                (\") /oxgc) { $slash = 'm//'; return "Ekps9566::$1(" . e_qq('',  $2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) qq (?>\s*) (\#) ((?:$qq_char)+?)                (\#) /oxgc) { $slash = 'm//'; return "Ekps9566::$1(" . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) qq (?>\s*) (\() ((?:$qq_paren)+?)               (\)) /oxgc) { $slash = 'm//'; return "Ekps9566::$1(" . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) qq (?>\s*) (\{) ((?:$qq_brace)+?)               (\}) /oxgc) { $slash = 'm//'; return "Ekps9566::$1(" . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) qq (?>\s*) (\[) ((?:$qq_bracket)+?)             (\]) /oxgc) { $slash = 'm//'; return "Ekps9566::$1(" . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) qq (?>\s*) (\<) ((?:$qq_angle)+?)               (\>) /oxgc) { $slash = 'm//'; return "Ekps9566::$1(" . e_qq('qq',$2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) qq (?>\s*) (\S) ((?:$qq_char)+?)                (\2) /oxgc) { $slash = 'm//'; return "Ekps9566::$1(" . e_qq('qq',$2,$4,$3) . ")"; }

    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC])            (?>\s*) (\') ((?:\\\'|\\\\|$q_char)+?)       (\') /oxgc) { $slash = 'm//'; return "Ekps9566::$1(" . e_q ('',  $2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) q  (?>\s*) (\#) ((?:\\\#|\\\\|$q_char)+?)       (\#) /oxgc) { $slash = 'm//'; return "Ekps9566::$1(" . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) q  (?>\s*) (\() ((?:\\\)|\\\\|$q_paren)+?)      (\)) /oxgc) { $slash = 'm//'; return "Ekps9566::$1(" . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) q  (?>\s*) (\{) ((?:\\\}|\\\\|$q_brace)+?)      (\}) /oxgc) { $slash = 'm//'; return "Ekps9566::$1(" . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) q  (?>\s*) (\[) ((?:\\\]|\\\\|$q_bracket)+?)    (\]) /oxgc) { $slash = 'm//'; return "Ekps9566::$1(" . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) q  (?>\s*) (\<) ((?:\\\>|\\\\|$q_angle)+?)      (\>) /oxgc) { $slash = 'm//'; return "Ekps9566::$1(" . e_q ('q', $2,$4,$3) . ")"; }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) q  (?>\s*) (\S) ((?:\\\2|\\\\|$q_char)+?)       (\2) /oxgc) { $slash = 'm//'; return "Ekps9566::$1(" . e_q ('q', $2,$4,$3) . ")"; }

    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s*) (\$ (?> \w+ (?: ::\w+)* ) (?: (?: ->)? (?: [\$\@\%\&\*]\* | \$\#\* | \( (?:$qq_paren)*? \) | [\@\%\*]? \{ (?:$qq_brace)+? \} | [\@\%]? \[ (?:$qq_bracket)+? \] ) )*) /oxgc)
                                                                                                                   { $slash = 'm//'; return "Ekps9566::$1($2)";             }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s*) \( ((?:$qq_paren)*?) \)                              /oxgc) { $slash = 'm//'; return "Ekps9566::$1($2)";             }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?= (?>\s+) [a-z]+)                                          /oxgc) { $slash = 'm//'; return "Ekps9566::$1";                 }
    elsif (/\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) ((?>\w+))                                            /oxgc) { $slash = 'm//'; return "Ekps9566::$1(::"."$2)";        }
    elsif (/\G -(t)                            (?>\s+) ((?>\w+))                                            /oxgc) { $slash = 'm//'; return "-t $2";                     }
    elsif (/\G \b lstat         (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(])                                /oxgc) { $slash = 'm//'; return 'Ekps9566::lstat';              }
    elsif (/\G \b stat          (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(])                                /oxgc) { $slash = 'm//'; return 'Ekps9566::stat';               }

    # "-s '' ..." means file test "-s 'filename' ..." (not means "- s/// ...")
    elsif (/\G -s                                          (?>\s*) (\") ((?:$qq_char)+?)               (\") /oxgc) { $slash = 'm//'; return '-s ' . e_qq('',  $1,$3,$2); }
    elsif (/\G -s                               (?>\s+) qq (?>\s*) (\#) ((?:$qq_char)+?)               (\#) /oxgc) { $slash = 'm//'; return '-s ' . e_qq('qq',$1,$3,$2); }
    elsif (/\G -s                               (?>\s+) qq (?>\s*) (\() ((?:$qq_paren)+?)              (\)) /oxgc) { $slash = 'm//'; return '-s ' . e_qq('qq',$1,$3,$2); }
    elsif (/\G -s                               (?>\s+) qq (?>\s*) (\{) ((?:$qq_brace)+?)              (\}) /oxgc) { $slash = 'm//'; return '-s ' . e_qq('qq',$1,$3,$2); }
    elsif (/\G -s                               (?>\s+) qq (?>\s*) (\[) ((?:$qq_bracket)+?)            (\]) /oxgc) { $slash = 'm//'; return '-s ' . e_qq('qq',$1,$3,$2); }
    elsif (/\G -s                               (?>\s+) qq (?>\s*) (\<) ((?:$qq_angle)+?)              (\>) /oxgc) { $slash = 'm//'; return '-s ' . e_qq('qq',$1,$3,$2); }
    elsif (/\G -s                               (?>\s+) qq (?>\s*) (\S) ((?:$qq_char)+?)               (\1) /oxgc) { $slash = 'm//'; return '-s ' . e_qq('qq',$1,$3,$2); }

    elsif (/\G -s                                          (?>\s*) (\') ((?:\\\'|\\\\|$q_char)+?)      (\') /oxgc) { $slash = 'm//'; return '-s ' . e_q ('',  $1,$3,$2); }
    elsif (/\G -s                               (?>\s+) q  (?>\s*) (\#) ((?:\\\#|\\\\|$q_char)+?)      (\#) /oxgc) { $slash = 'm//'; return '-s ' . e_q ('q', $1,$3,$2); }
    elsif (/\G -s                               (?>\s+) q  (?>\s*) (\() ((?:\\\)|\\\\|$q_paren)+?)     (\)) /oxgc) { $slash = 'm//'; return '-s ' . e_q ('q', $1,$3,$2); }
    elsif (/\G -s                               (?>\s+) q  (?>\s*) (\{) ((?:\\\}|\\\\|$q_brace)+?)     (\}) /oxgc) { $slash = 'm//'; return '-s ' . e_q ('q', $1,$3,$2); }
    elsif (/\G -s                               (?>\s+) q  (?>\s*) (\[) ((?:\\\]|\\\\|$q_bracket)+?)   (\]) /oxgc) { $slash = 'm//'; return '-s ' . e_q ('q', $1,$3,$2); }
    elsif (/\G -s                               (?>\s+) q  (?>\s*) (\<) ((?:\\\>|\\\\|$q_angle)+?)     (\>) /oxgc) { $slash = 'm//'; return '-s ' . e_q ('q', $1,$3,$2); }
    elsif (/\G -s                               (?>\s+) q  (?>\s*) (\S) ((?:\\\1|\\\\|$q_char)+?)      (\1) /oxgc) { $slash = 'm//'; return '-s ' . e_q ('q', $1,$3,$2); }

    elsif (/\G -s                               (?>\s*) (\$ (?> \w+ (?: ::\w+)* ) (?: (?: ->)? (?: [\$\@\%\&\*]\* | \$\#\* | \( (?:$qq_paren)*? \) | [\@\%\*]? \{ (?:$qq_brace)+? \} | [\@\%]? \[ (?:$qq_bracket)+? \] ) )*) /oxgc)
                                                                                                                   { $slash = 'm//'; return "-s $1";   }
    elsif (/\G -s                               (?>\s*) \( ((?:$qq_paren)*?) \)                             /oxgc) { $slash = 'm//'; return "-s ($1)"; }
    elsif (/\G -s                               (?= (?>\s+) [a-z]+)                                         /oxgc) { $slash = 'm//'; return '-s';      }
    elsif (/\G -s                               (?>\s+) ((?>\w+))                                           /oxgc) { $slash = 'm//'; return "-s $1";   }

    elsif (/\G \b bytes::length (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'length';                   }
    elsif (/\G \b bytes::chr    (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'chr';                      }
    elsif (/\G \b chr           (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Ekps9566::chr';               }
    elsif (/\G \b bytes::ord    (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $slash = 'div'; return 'ord';                      }
    elsif (/\G \b ord           (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $slash = 'div'; return $function_ord;              }
    elsif (/\G \b glob          (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $slash = 'm//'; return 'Ekps9566::glob';              }
    elsif (/\G \b lc \b            (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return 'Ekps9566::lc_';               }
    elsif (/\G \b lcfirst \b       (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return 'Ekps9566::lcfirst_';          }
    elsif (/\G \b uc \b            (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return 'Ekps9566::uc_';               }
    elsif (/\G \b ucfirst \b       (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return 'Ekps9566::ucfirst_';          }
    elsif (/\G \b fc \b            (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return 'Ekps9566::fc_';               }
    elsif (/\G \b lstat \b         (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return 'Ekps9566::lstat_';            }
    elsif (/\G \b stat \b          (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return 'Ekps9566::stat_';             }
    elsif (/\G    (-[rwxoRWXOezfdlpSbcugkTB] (?>(?:\s+ -[rwxoRWXOezfdlpSbcugkTB])+))
                     \b            (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return "Ekps9566::filetest_(qw($1))"; }
    elsif (/\G    -([rwxoRWXOezsfdlpSbcugkTBMAC])
                     \b            (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return "Ekps9566::${1}_";             }

    elsif (/\G    -s \b            (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return '-s ';                      }

    elsif (/\G \b bytes::length \b (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return 'length';                   }
    elsif (/\G \b bytes::chr \b    (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return 'chr';                      }
    elsif (/\G \b chr \b           (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return 'Ekps9566::chr_';              }
    elsif (/\G \b bytes::ord \b    (?! (?>\s*) => )                          /oxgc) { $slash = 'div'; return 'ord';                      }
    elsif (/\G \b ord \b           (?! (?>\s*) => )                          /oxgc) { $slash = 'div'; return $function_ord_;             }
    elsif (/\G \b glob \b          (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return 'Ekps9566::glob_';             }
    elsif (/\G \b reverse \b       (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return $function_reverse;          }
    elsif (/\G \b getc \b          (?! (?>\s*) => )                          /oxgc) { $slash = 'm//'; return $function_getc;             }
    elsif (/\G \b opendir ((?>\s*) \( (?>\s*)) (?=[A-Za-z_])                 /oxgc) { $slash = 'm//'; return "Ekps9566::opendir$1*";        }
    elsif (/\G \b opendir ((?>\s+))            (?=[A-Za-z_])                 /oxgc) { $slash = 'm//'; return "Ekps9566::opendir$1*";        }
    elsif (/\G \b unlink \b       (?! (?>\s*) => )                           /oxgc) { $slash = 'm//'; return 'Ekps9566::unlink';            }

# chdir
    elsif (/\G \b (chdir) \b       (?! (?>\s*) => ) /oxgc) {
        $slash = 'm//';

        my $e = 'Ekps9566::chdir';

        while (/\G ( (?>\s+) | \( | \#.* ) /oxgc) {
            $e .= $1;
        }

# end of chdir
        if    (/\G (?= [,;\)\}\]] )          /oxgc) { return $e;                 }

# chdir scalar value
        elsif (/\G ( [\$\@\&\*] $qq_scalar ) /oxgc) { return $e . e_string($1);  }

# chdir qq//
        elsif (/\G \b (qq) \b /oxgc) {
            if (/\G (\#) ((?:$qq_char)*?) (\#) /oxgc)                        { return $e . e_chdir('qq',$1,$3,$2);   } # qq# #  --> qr # #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G ((?>\s+)|\#.*)                         /oxgc) { $e .= $1; }
                    elsif (/\G (\()          ((?:$qq_paren)*?)   (\)) /oxgc) { return $e . e_chdir('qq',$1,$3,$2);   } # qq ( ) --> qr ( )
                    elsif (/\G (\{)          ((?:$qq_brace)*?)   (\}) /oxgc) { return $e . e_chdir('qq',$1,$3,$2);   } # qq { } --> qr { }
                    elsif (/\G (\[)          ((?:$qq_bracket)*?) (\]) /oxgc) { return $e . e_chdir('qq',$1,$3,$2);   } # qq [ ] --> qr [ ]
                    elsif (/\G (\<)          ((?:$qq_angle)*?)   (\>) /oxgc) { return $e . e_chdir('qq',$1,$3,$2);   } # qq < > --> qr < >
                    elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) /oxgc) { return $e . e_chdir('qq','{','}',$2); } # qq | | --> qr { }
                    elsif (/\G (\S)          ((?:$qq_char)*?)    (\1) /oxgc) { return $e . e_chdir('qq',$1,$3,$2);   } # qq * * --> qr * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF\n";
            }
        }

# chdir q//
        elsif (/\G \b (q) \b /oxgc) {
            if (/\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc)                    { return $e . e_chdir_q('q',$1,$3,$2);   } # q# #  --> qr # #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G ((?>\s+)|\#.*)                              /oxgc) { $e .= $1; }
                    elsif (/\G (\() ((?:\\\\|\\\)|\\\(|$q_paren)*?)   (\)) /oxgc) { return $e . e_chdir_q('q',$1,$3,$2);   } # q ( ) --> qr ( )
                    elsif (/\G (\{) ((?:\\\\|\\\}|\\\{|$q_brace)*?)   (\}) /oxgc) { return $e . e_chdir_q('q',$1,$3,$2);   } # q { } --> qr { }
                    elsif (/\G (\[) ((?:\\\\|\\\]|\\\[|$q_bracket)*?) (\]) /oxgc) { return $e . e_chdir_q('q',$1,$3,$2);   } # q [ ] --> qr [ ]
                    elsif (/\G (\<) ((?:\\\\|\\\>|\\\<|$q_angle)*?)   (\>) /oxgc) { return $e . e_chdir_q('q',$1,$3,$2);   } # q < > --> qr < >
                    elsif (/\G ([*\-:?\\^|])       ((?:$q_char)*?)    (\1) /oxgc) { return $e . e_chdir_q('q','{','}',$2); } # q | | --> qr { }
                    elsif (/\G (\S) ((?:\\\\|\\\1|     $q_char)*?)    (\1) /oxgc) { return $e . e_chdir_q('q',$1,$3,$2);   } # q * * --> qr * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF\n";
            }
        }

# chdir ''
        elsif (/\G (\') /oxgc) {
            my $q_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)    /oxgc) { $q_string .= $1; }
                elsif (/\G (\\\')    /oxgc) { $q_string .= $1; }
                elsif (/\G \'        /oxgc)                                       { return $e . e_chdir_q('',"'","'",$q_string); }
                elsif (/\G ($q_char) /oxgc) { $q_string .= $1; }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF\n";
        }

# chdir ""
        elsif (/\G (\") /oxgc) {
            my $qq_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)    /oxgc) { $qq_string .= $1; }
                elsif (/\G (\\\")    /oxgc) { $qq_string .= $1; }
                elsif (/\G \"        /oxgc)                                       { return $e . e_chdir('','"','"',$qq_string); }
                elsif (/\G ($q_char) /oxgc) { $qq_string .= $1; }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF\n";
        }
    }

# split
    elsif (/\G \b (split) \b (?! (?>\s*) => ) /oxgc) {
        $slash = 'm//';

        my $e = '';
        while (/\G ( (?>\s+) | \( | \#.* ) /oxgc) {
            $e .= $1;
        }

# end of split
        if    (/\G (?= [,;\)\}\]] )          /oxgc) { return 'Ekps9566::split' . $e;                 }

# split scalar value
        elsif (/\G ( [\$\@\&\*] $qq_scalar ) /oxgc) { return 'Ekps9566::split' . $e . e_string($1);  }

# split literal space
        elsif (/\G \b qq           (\#) [ ] (\#) /oxgc) { return 'Ekps9566::split' . $e . qq  {qq$1 $2}; }
        elsif (/\G \b qq ((?>\s*)) (\() [ ] (\)) /oxgc) { return 'Ekps9566::split' . $e . qq{$1qq$2 $3}; }
        elsif (/\G \b qq ((?>\s*)) (\{) [ ] (\}) /oxgc) { return 'Ekps9566::split' . $e . qq{$1qq$2 $3}; }
        elsif (/\G \b qq ((?>\s*)) (\[) [ ] (\]) /oxgc) { return 'Ekps9566::split' . $e . qq{$1qq$2 $3}; }
        elsif (/\G \b qq ((?>\s*)) (\<) [ ] (\>) /oxgc) { return 'Ekps9566::split' . $e . qq{$1qq$2 $3}; }
        elsif (/\G \b qq ((?>\s*)) (\S) [ ] (\2) /oxgc) { return 'Ekps9566::split' . $e . qq{$1qq$2 $3}; }
        elsif (/\G \b q            (\#) [ ] (\#) /oxgc) { return 'Ekps9566::split' . $e . qq   {q$1 $2}; }
        elsif (/\G \b q  ((?>\s*)) (\() [ ] (\)) /oxgc) { return 'Ekps9566::split' . $e . qq {$1q$2 $3}; }
        elsif (/\G \b q  ((?>\s*)) (\{) [ ] (\}) /oxgc) { return 'Ekps9566::split' . $e . qq {$1q$2 $3}; }
        elsif (/\G \b q  ((?>\s*)) (\[) [ ] (\]) /oxgc) { return 'Ekps9566::split' . $e . qq {$1q$2 $3}; }
        elsif (/\G \b q  ((?>\s*)) (\<) [ ] (\>) /oxgc) { return 'Ekps9566::split' . $e . qq {$1q$2 $3}; }
        elsif (/\G \b q  ((?>\s*)) (\S) [ ] (\2) /oxgc) { return 'Ekps9566::split' . $e . qq {$1q$2 $3}; }
        elsif (/\G                    ' [ ] '    /oxgc) { return 'Ekps9566::split' . $e . qq     {' '};  }
        elsif (/\G                    " [ ] "    /oxgc) { return 'Ekps9566::split' . $e . qq     {" "};  }

# split qq//
        elsif (/\G \b (qq) \b /oxgc) {
            if (/\G (\#) ((?:$qq_char)*?) (\#) /oxgc)                        { return e_split($e.'qr',$1,$3,$2,'');   } # qq# #  --> qr # #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G ((?>\s+)|\#.*)                         /oxgc) { $e .= $1; }
                    elsif (/\G (\()          ((?:$qq_paren)*?)   (\)) /oxgc) { return e_split($e.'qr',$1,$3,$2,'');   } # qq ( ) --> qr ( )
                    elsif (/\G (\{)          ((?:$qq_brace)*?)   (\}) /oxgc) { return e_split($e.'qr',$1,$3,$2,'');   } # qq { } --> qr { }
                    elsif (/\G (\[)          ((?:$qq_bracket)*?) (\]) /oxgc) { return e_split($e.'qr',$1,$3,$2,'');   } # qq [ ] --> qr [ ]
                    elsif (/\G (\<)          ((?:$qq_angle)*?)   (\>) /oxgc) { return e_split($e.'qr',$1,$3,$2,'');   } # qq < > --> qr < >
                    elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) /oxgc) { return e_split($e.'qr','{','}',$2,''); } # qq | | --> qr { }
                    elsif (/\G (\S)          ((?:$qq_char)*?)    (\1) /oxgc) { return e_split($e.'qr',$1,$3,$2,'');   } # qq * * --> qr * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF\n";
            }
        }

# split qr//
        elsif (/\G \b (qr) \b /oxgc) {
            if (/\G (\#) ((?:$qq_char)*?) (\#) ([imosxpadlunbB]*) /oxgc)                        { return e_split  ($e.'qr',$1,$3,$2,$4);   } # qr# #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G ((?>\s+)|\#.*)                                            /oxgc) { $e .= $1; }
                    elsif (/\G (\()          ((?:$qq_paren)*?)   (\)) ([imosxpadlunbB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # qr ( )
                    elsif (/\G (\{)          ((?:$qq_brace)*?)   (\}) ([imosxpadlunbB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # qr { }
                    elsif (/\G (\[)          ((?:$qq_bracket)*?) (\]) ([imosxpadlunbB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # qr [ ]
                    elsif (/\G (\<)          ((?:$qq_angle)*?)   (\>) ([imosxpadlunbB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # qr < >
                    elsif (/\G (\')          ((?:$qq_char)*?)    (\') ([imosxpadlunbB]*) /oxgc) { return e_split_q($e.'qr',$1, $3, $2,$4); } # qr ' '
                    elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([imosxpadlunbB]*) /oxgc) { return e_split  ($e.'qr','{','}',$2,$4); } # qr | | --> qr { }
                    elsif (/\G (\S)          ((?:$qq_char)*?)    (\1) ([imosxpadlunbB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # qr * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF\n";
            }
        }

# split q//
        elsif (/\G \b (q) \b /oxgc) {
            if (/\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc)                    { return e_split_q($e.'qr',$1,$3,$2,'');   } # q# #  --> qr # #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G ((?>\s+)|\#.*)                              /oxgc) { $e .= $1; }
                    elsif (/\G (\() ((?:\\\\|\\\)|\\\(|$q_paren)*?)   (\)) /oxgc) { return e_split_q($e.'qr',$1,$3,$2,'');   } # q ( ) --> qr ( )
                    elsif (/\G (\{) ((?:\\\\|\\\}|\\\{|$q_brace)*?)   (\}) /oxgc) { return e_split_q($e.'qr',$1,$3,$2,'');   } # q { } --> qr { }
                    elsif (/\G (\[) ((?:\\\\|\\\]|\\\[|$q_bracket)*?) (\]) /oxgc) { return e_split_q($e.'qr',$1,$3,$2,'');   } # q [ ] --> qr [ ]
                    elsif (/\G (\<) ((?:\\\\|\\\>|\\\<|$q_angle)*?)   (\>) /oxgc) { return e_split_q($e.'qr',$1,$3,$2,'');   } # q < > --> qr < >
                    elsif (/\G ([*\-:?\\^|])       ((?:$q_char)*?)    (\1) /oxgc) { return e_split_q($e.'qr','{','}',$2,''); } # q | | --> qr { }
                    elsif (/\G (\S) ((?:\\\\|\\\1|     $q_char)*?)    (\1) /oxgc) { return e_split_q($e.'qr',$1,$3,$2,'');   } # q * * --> qr * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF\n";
            }
        }

# split m//
        elsif (/\G \b (m) \b /oxgc) {
            if (/\G (\#) ((?:$qq_char)*?) (\#) ([cgimosxpadlunbB]*) /oxgc)                        { return e_split  ($e.'qr',$1,$3,$2,$4);   } # m# #  --> qr # #
            else {
                while (not /\G \z/oxgc) {
                    if    (/\G ((?>\s+)|\#.*)                                              /oxgc) { $e .= $1; }
                    elsif (/\G (\()          ((?:$qq_paren)*?)   (\)) ([cgimosxpadlunbB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # m ( ) --> qr ( )
                    elsif (/\G (\{)          ((?:$qq_brace)*?)   (\}) ([cgimosxpadlunbB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # m { } --> qr { }
                    elsif (/\G (\[)          ((?:$qq_bracket)*?) (\]) ([cgimosxpadlunbB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # m [ ] --> qr [ ]
                    elsif (/\G (\<)          ((?:$qq_angle)*?)   (\>) ([cgimosxpadlunbB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # m < > --> qr < >
                    elsif (/\G (\')          ((?:$qq_char)*?)    (\') ([cgimosxpadlunbB]*) /oxgc) { return e_split_q($e.'qr',$1, $3, $2,$4); } # m ' ' --> qr ' '
                    elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([cgimosxpadlunbB]*) /oxgc) { return e_split  ($e.'qr','{','}',$2,$4); } # m | | --> qr { }
                    elsif (/\G (\S)          ((?:$qq_char)*?)    (\1) ([cgimosxpadlunbB]*) /oxgc) { return e_split  ($e.'qr',$1, $3, $2,$4); } # m * * --> qr * *
                }
                die __FILE__, ": Search pattern not terminated\n";
            }
        }

# split ''
        elsif (/\G (\') /oxgc) {
            my $q_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)    /oxgc) { $q_string .= $1; }
                elsif (/\G (\\\')    /oxgc) { $q_string .= $1; }                               # splitqr'' --> split qr''
                elsif (/\G \'        /oxgc)                                                    { return e_split_q($e.q{ qr},"'","'",$q_string,''); } # ' ' --> qr ' '
                elsif (/\G ($q_char) /oxgc) { $q_string .= $1; }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF\n";
        }

# split ""
        elsif (/\G (\") /oxgc) {
            my $qq_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)    /oxgc) { $qq_string .= $1; }
                elsif (/\G (\\\")    /oxgc) { $qq_string .= $1; }                              # splitqr"" --> split qr""
                elsif (/\G \"        /oxgc)                                                    { return e_split($e.q{ qr},'"','"',$qq_string,''); } # " " --> qr " "
                elsif (/\G ($q_char) /oxgc) { $qq_string .= $1; }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF\n";
        }

# split //
        elsif (/\G (\/) /oxgc) {
            my $regexp = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)                  /oxgc) { $regexp .= $1; }
                elsif (/\G (\\\/)                  /oxgc) { $regexp .= $1; }                   # splitqr// --> split qr//
                elsif (/\G \/ ([cgimosxpadlunbB]*) /oxgc)                                      { return e_split($e.q{ qr}, '/','/',$regexp,$1); } # / / --> qr / /
                elsif (/\G ($q_char)               /oxgc) { $regexp .= $1; }
            }
            die __FILE__, ": Search pattern not terminated\n";
        }
    }

# tr/// or y///

    # about [cdsrbB]* (/B modifier)
    #
    # P.559 appendix C
    # of ISBN 4-89052-384-7 Programming perl
    # (Japanese title is: Perl puroguramingu)

    elsif (/\G \b ( tr | y ) \b /oxgc) {
        my $ope = $1;

        #        $1   $2               $3   $4               $5   $6
        if (/\G (\#) ((?:$qq_char)*?) (\#) ((?:$qq_char)*?) (\#) ([cdsrbB]*) /oxgc) { # tr# # #
            my @tr = ($tr_variable,$2);
            return e_tr(@tr,'',$4,$6);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G ((?>\s+)|\#.*)              /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?) (\)) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G ((?>\s+)|\#.*)                            /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) * *
                    }
                    die __FILE__, ": Transliteration replacement not terminated\n";
                }
                elsif (/\G (\{) ((?:$qq_brace)*?) (\}) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G ((?>\s+)|\#.*)                            /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } * *
                    }
                    die __FILE__, ": Transliteration replacement not terminated\n";
                }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G ((?>\s+)|\#.*)                            /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] * *
                    }
                    die __FILE__, ": Transliteration replacement not terminated\n";
                }
                elsif (/\G (\<) ((?:$qq_angle)*?) (\>) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G ((?>\s+)|\#.*)                            /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsrbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > * *
                    }
                    die __FILE__, ": Transliteration replacement not terminated\n";
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\S) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cdsrbB]*) /oxgc) { # tr * * *
                    my @tr = ($tr_variable,$2);
                    return e_tr(@tr,'',$4,$6);
                }
            }
            die __FILE__, ": Transliteration pattern not terminated\n";
        }
    }

# qq//
    elsif (/\G \b (qq) \b /oxgc) {
        my $ope = $1;

#       if (/\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { return e_qq($ope,$1,$3,$2); } # qq# #
        if (/\G (\#) /oxgc) {                                                     # qq# #
            my $qq_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                     }
                elsif (/\G (\\\#)     /oxgc) { $qq_string .= $1;                     }
                elsif (/\G (\#)       /oxgc) { return e_qq($ope,'#','#',$qq_string); }
                elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                     }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF\n";
        }

        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G ((?>\s+)|\#.*)              /oxgc) { $e .= $1; }

#               elsif (/\G (\() ((?:$qq_paren)*?) (\)) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq ( )
                elsif (/\G (\() /oxgc) {                                                           # qq ( )
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\))     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\()       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\))       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'(',')',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF\n";
                }

#               elsif (/\G (\{) ((?:$qq_brace)*?) (\}) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq { }
                elsif (/\G (\{) /oxgc) {                                                           # qq { }
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\})     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\{)       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\})       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'{','}',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF\n";
                }

#               elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq [ ]
                elsif (/\G (\[) /oxgc) {                                                             # qq [ ]
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\])     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\[)       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\])       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'[',']',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF\n";
                }

#               elsif (/\G (\<) ((?:$qq_angle)*?) (\>) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq < >
                elsif (/\G (\<) /oxgc) {                                                           # qq < >
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\>)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\<)       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\>)       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'<','>',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF\n";
                }

#               elsif (/\G (\S) ((?:$qq_char)*?) (\1) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq * *
                elsif (/\G (\S) /oxgc) {                                                          # qq * *
                    my $delimiter = $1;
                    my $qq_string = '';
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)             /oxgc) { $qq_string .= $1;                                        }
                        elsif (/\G (\\\Q$delimiter\E) /oxgc) { $qq_string .= $1;                                        }
                        elsif (/\G (\Q$delimiter\E)   /oxgc) { return $e . e_qq($ope,$delimiter,$delimiter,$qq_string); }
                        elsif (/\G ($qq_char)         /oxgc) { $qq_string .= $1;                                        }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF\n";
                }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF\n";
        }
    }

# qr//
    elsif (/\G \b (qr) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) ([imosxpadlunbB]*) /oxgc) { # qr# # #
            return e_qr($ope,$1,$3,$2,$4);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G ((?>\s+)|\#.*)                                            /oxgc) { $e .= $1; }
                elsif (/\G (\()          ((?:$qq_paren)*?)   (\)) ([imosxpadlunbB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr ( )
                elsif (/\G (\{)          ((?:$qq_brace)*?)   (\}) ([imosxpadlunbB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr { }
                elsif (/\G (\[)          ((?:$qq_bracket)*?) (\]) ([imosxpadlunbB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr [ ]
                elsif (/\G (\<)          ((?:$qq_angle)*?)   (\>) ([imosxpadlunbB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr < >
                elsif (/\G (\')          ((?:$qq_char)*?)    (\') ([imosxpadlunbB]*) /oxgc) { return $e . e_qr_q($ope,$1, $3, $2,$4); } # qr ' '
                elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([imosxpadlunbB]*) /oxgc) { return $e . e_qr  ($ope,'{','}',$2,$4); } # qr | | --> qr { }
                elsif (/\G (\S)          ((?:$qq_char)*?)    (\1) ([imosxpadlunbB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr * *
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF\n";
        }
    }

# qw//
    elsif (/\G \b (qw) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) (.*?) (\#) /oxmsgc) { # qw# #
            return e_qw($ope,$1,$3,$2);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G ((?>\s+)|\#.*)                        /oxgc)   { $e .= $1; }

                elsif (/\G (\()          ([^(]*?)           (\)) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw ( )
                elsif (/\G (\()          ((?:$q_paren)*?)   (\)) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw ( )

                elsif (/\G (\{)          ([^{]*?)           (\}) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw { }
                elsif (/\G (\{)          ((?:$q_brace)*?)   (\}) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw { }

                elsif (/\G (\[)          ([^[]*?)           (\]) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw [ ]
                elsif (/\G (\[)          ((?:$q_bracket)*?) (\]) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw [ ]

                elsif (/\G (\<)          ([^<]*?)           (\>) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw < >
                elsif (/\G (\<)          ((?:$q_angle)*?)   (\>) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw < >

                elsif (/\G ([\x21-\x3F]) (.*?)              (\1) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw * *
                elsif (/\G (\S)          ((?:$q_char)*?)    (\1) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw * *
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF\n";
        }
    }

# qx//
    elsif (/\G \b (qx) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { # qx# #
            return e_qq($ope,$1,$3,$2);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G ((?>\s+)|\#.*)                /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx ( )
                elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx { }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx [ ]
                elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx < >
                elsif (/\G (\') ((?:$qq_char)*?)    (\') /oxgc) { return $e . e_q ($ope,$1,$3,$2); } # qx ' '
                elsif (/\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx * *
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF\n";
        }
    }

# q//
    elsif (/\G \b (q) \b /oxgc) {
        my $ope = $1;

#       if (/\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc) { return e_q($ope,$1,$3,$2); } # q# #

        # avoid "Error: Runtime exception" of perl version 5.005_03
        # (and so on)

        if (/\G (\#) /oxgc) {                                                             # q# #
            my $q_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                    }
                elsif (/\G (\\\#)    /oxgc) { $q_string .= $1;                    }
                elsif (/\G (\#)      /oxgc) { return e_q($ope,'#','#',$q_string); }
                elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                    }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF\n";
        }

        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G ((?>\s+)|\#.*)                       /oxgc) { $e .= $1; }

#               elsif (/\G (\() ((?:\\\)|\\\\|$q_paren)*?) (\)) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q ( )
                elsif (/\G (\() /oxgc) {                                                                   # q ( )
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\))    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\()    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\()      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\))      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'(',')',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF\n";
                }

#               elsif (/\G (\{) ((?:\\\}|\\\\|$q_brace)*?) (\}) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q { }
                elsif (/\G (\{) /oxgc) {                                                                   # q { }
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\})    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\{)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\{)      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\})      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'{','}',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF\n";
                }

#               elsif (/\G (\[) ((?:\\\]|\\\\|$q_bracket)*?) (\]) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q [ ]
                elsif (/\G (\[) /oxgc) {                                                                     # q [ ]
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\])    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\[)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\[)      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\])      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'[',']',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF\n";
                }

#               elsif (/\G (\<) ((?:\\\>|\\\\|$q_angle)*?) (\>) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q < >
                elsif (/\G (\<) /oxgc) {                                                                   # q < >
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\>)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\<)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\<)      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\>)      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'<','>',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF\n";
                }

#               elsif (/\G (\S) ((?:\\\1|\\\\|$q_char)*?) (\1) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q * *
                elsif (/\G (\S) /oxgc) {                                                                  # q * *
                    my $delimiter = $1;
                    my $q_string = '';
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)             /oxgc) { $q_string .= $1;                                       }
                        elsif (/\G (\\\Q$delimiter\E) /oxgc) { $q_string .= $1;                                       }
                        elsif (/\G (\Q$delimiter\E)   /oxgc) { return $e . e_q($ope,$delimiter,$delimiter,$q_string); }
                        elsif (/\G ($q_char)          /oxgc) { $q_string .= $1;                                       }
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF\n";
                }
            }
            die __FILE__, ": Can't find string terminator anywhere before EOF\n";
        }
    }

# m//
    elsif (/\G \b (m) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) ([cgimosxpadlunbB]*) /oxgc) { # m# #
            return e_qr($ope,$1,$3,$2,$4);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G ((?>\s+)|\#.*)                                             /oxgc) { $e .= $1; }
                elsif (/\G (\()         ((?:$qq_paren)*?)   (\)) ([cgimosxpadlunbB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m ( )
                elsif (/\G (\{)         ((?:$qq_brace)*?)   (\}) ([cgimosxpadlunbB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m { }
                elsif (/\G (\[)         ((?:$qq_bracket)*?) (\]) ([cgimosxpadlunbB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m [ ]
                elsif (/\G (\<)         ((?:$qq_angle)*?)   (\>) ([cgimosxpadlunbB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m < >
                elsif (/\G (\?)         ((?:$qq_char)*?)    (\?) ([cgimosxpadlunbB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m ? ?
                elsif (/\G (\')         ((?:$qq_char)*?)    (\') ([cgimosxpadlunbB]*) /oxgc) { return $e . e_qr_q($ope,$1, $3, $2,$4); } # m ' '
                elsif (/\G ([*\-:\\^|]) ((?:$qq_char)*?)    (\1) ([cgimosxpadlunbB]*) /oxgc) { return $e . e_qr  ($ope,'{','}',$2,$4); } # m | | --> m { }
                elsif (/\G (\S)         ((?:$qq_char)*?)    (\1) ([cgimosxpadlunbB]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # m * *
            }
            die __FILE__, ": Search pattern not terminated\n";
        }
    }

# s///

    # about [cegimosxpradlunbB]* (/cg modifier)
    #
    # P.67 Pattern-Matching Operators
    # of ISBN 0-596-00241-6 Perl in a Nutshell, Second Edition.

    elsif (/\G \b (s) \b /oxgc) {
        my $ope = $1;

        #        $1   $2               $3   $4               $5   $6
        if (/\G (\#) ((?:$qq_char)*?) (\#) ((?:$qq_char)*?) (\#) ([cegimosxpradlunbB]*) /oxgc) { # s# # #
            return e_sub($sub_variable,$1,$2,$3,$3,$4,$5,$6);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if (/\G ((?>\s+)|\#.*) /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?) (\)) /oxgc) {
                    my @s = ($1,$2,$3);
                    while (not /\G \z/oxgc) {
                        if    (/\G ((?>\s+)|\#.*)                                       /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\:) ((?:$qq_char)*?)    (\:) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\@) ((?:$qq_char)*?)    (\@) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                    }
                    die __FILE__, ": Substitution replacement not terminated\n";
                }
                elsif (/\G (\{) ((?:$qq_brace)*?) (\}) /oxgc) {
                    my @s = ($1,$2,$3);
                    while (not /\G \z/oxgc) {
                        if    (/\G ((?>\s+)|\#.*)                                       /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\:) ((?:$qq_char)*?)    (\:) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\@) ((?:$qq_char)*?)    (\@) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                    }
                    die __FILE__, ": Substitution replacement not terminated\n";
                }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) {
                    my @s = ($1,$2,$3);
                    while (not /\G \z/oxgc) {
                        if    (/\G ((?>\s+)|\#.*)                                       /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                    }
                    die __FILE__, ": Substitution replacement not terminated\n";
                }
                elsif (/\G (\<) ((?:$qq_angle)*?) (\>) /oxgc) {
                    my @s = ($1,$2,$3);
                    while (not /\G \z/oxgc) {
                        if    (/\G ((?>\s+)|\#.*)                                       /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\:) ((?:$qq_char)*?)    (\:) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\@) ((?:$qq_char)*?)    (\@) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosxpradlunbB]*) /oxgc) { return e_sub($sub_variable,@s,$1,$2,$3,$4); }
                    }
                    die __FILE__, ": Substitution replacement not terminated\n";
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\') ((?:$qq_char)*?) (\') ((?:$qq_char)*?) (\') ([cegimosxpradlunbB]*) /oxgc) {
                    return e_sub($sub_variable,$1,$2,$3,$3,$4,$5,$6);
                }
                #           $1            $2               $3   $4               $5   $6
                elsif (/\G ([*\-:?\\^|]) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cegimosxpradlunbB]*) /oxgc) {
                    return e_sub($sub_variable,'{',$2,'}','{',$4,'}',$6); # s | | | --> s { } { }
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\$) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cegimosxpradlunbB]*) /oxgc) {
                    return e_sub($sub_variable,$1,$2,$3,$3,$4,$5,$6);
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\S) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cegimosxpradlunbB]*) /oxgc) {
                    return e_sub($sub_variable,$1,$2,$3,$3,$4,$5,$6);
                }
            }
            die __FILE__, ": Substitution pattern not terminated\n";
        }
    }

# do
    elsif (/\G \b do (?= (?>\s*) \{ )                                                         /oxmsgc) { return 'do';                }
    elsif (/\G \b do (?= (?>\s+) (?: q | qq | qx ) \b)                                        /oxmsgc) { return 'Ekps9566::do';         }
    elsif (/\G \b do (?= (?>\s+) (?>\w+))                                                     /oxmsgc) { return 'do';                }
    elsif (/\G \b do (?= (?>\s*) \$ (?> \w+ (?: ::\w+)* ) \( )                                /oxmsgc) { return 'do';                }
    elsif (/\G \b do \b                                                                       /oxmsgc) { return 'Ekps9566::do';         }

# require ignore module
    elsif (/\G \b require ((?>\s+) (?:$ignore_modules) .*? ;) ([ \t]* [#\n])                  /oxmsgc) { return "# require$1$2";     }
    elsif (/\G \b require ((?>\s+) (?:$ignore_modules) .*? ;) ([ \t]* [^\x81-\xFE#]) /oxmsgc) { return "# require$1\n$2";   }
    elsif (/\G \b require ((?>\s+) (?:$ignore_modules)) \b                                    /oxmsgc) { return "# require$1";       }

# require version number
    elsif (/\G \b require (?>\s+) ((?>0[0-7_]*))                    (?>\s*) ;                 /oxmsgc) { return "require $1;";       }
    elsif (/\G \b require (?>\s+) ((?>[1-9][0-9_]*(?:\.[0-9_]+)*))  (?>\s*) ;                 /oxmsgc) { return "require $1;";       }
    elsif (/\G \b require (?>\s+) ((?>v[0-9][0-9_]*(?:\.[0-9_]+)*)) (?>\s*) ;                 /oxmsgc) { return "require $1;";       }

# require bare package name
    elsif (/\G \b require (?>\s+) ((?>[A-Za-z_]\w* (?: :: [A-Za-z_]\w*)*)) (?>\s*) ;          /oxmsgc) { return "require $1;";       }

# require else
    elsif (/\G \b require                                       (?>\s*) ;                     /oxmsgc) { return 'Ekps9566::require;';   }
    elsif (/\G \b require \b                                                                  /oxmsgc) { return 'Ekps9566::require';    }

# use strict; --> use strict; no strict qw(refs);
    elsif (/\G \b use ((?>\s+) strict .*? ;) ([ \t]* [#\n])                                   /oxmsgc) { return "use$1 no strict qw(refs);$2";   }
    elsif (/\G \b use ((?>\s+) strict .*? ;) ([ \t]* [^\x81-\xFE#])                  /oxmsgc) { return "use$1 no strict qw(refs);\n$2"; }
    elsif (/\G \b use ((?>\s+) strict) \b                                                     /oxmsgc) { return "use$1; no strict qw(refs)";     }

# use 5.12.0; --> use 5.12.0; no strict qw(refs);
    elsif (/\G \b use (?>\s+) ((?>([1-9][0-9_]*)(?:\.([0-9_]+))*))  (?>\s*) ; /oxmsgc) {
        if (($2 >= 6) or (($2 == 5) and ($3 ge '012'))) {
            return "use $1; no strict qw(refs);";
        }
        else {
            return "use $1;";
        }
    }
    elsif (/\G \b use (?>\s+) ((?>v([0-9][0-9_]*)(?:\.([0-9_]+))*)) (?>\s*) ; /oxmsgc) {
        if (($2 >= 6) or (($2 == 5) and ($3 >= 12))) {
            return "use $1; no strict qw(refs);";
        }
        else {
            return "use $1;";
        }
    }

# ignore use module
    elsif (/\G \b use ((?>\s+) (?:$ignore_modules) .*? ;) ([ \t]* [#\n])                  /oxmsgc) { return "# use$1$2";         }
    elsif (/\G \b use ((?>\s+) (?:$ignore_modules) .*? ;) ([ \t]* [^\x81-\xFE#]) /oxmsgc) { return "# use$1\n$2";       }
    elsif (/\G \b use ((?>\s+) (?:$ignore_modules)) \b                                    /oxmsgc) { return "# use$1";           }

# ignore no module
    elsif (/\G \b no  ((?>\s+) (?:$ignore_modules) .*? ;) ([ \t]* [#\n])                  /oxmsgc) { return "# no$1$2";          }
    elsif (/\G \b no  ((?>\s+) (?:$ignore_modules) .*? ;) ([ \t]* [^\x81-\xFE#]) /oxmsgc) { return "# no$1\n$2";        }
    elsif (/\G \b no  ((?>\s+) (?:$ignore_modules)) \b                                    /oxmsgc) { return "# no$1";            }

# use without import
    elsif (/\G \b use (?>\s+) ((?>0[0-7_]*))                                                        (?>\s*) ; /oxmsgc) { return "use $1;";           }
    elsif (/\G \b use (?>\s+) ((?>[1-9][0-9_]*(?:\.[0-9_]+)*))                                      (?>\s*) ; /oxmsgc) { return "use $1;";           }
    elsif (/\G \b use (?>\s+) ((?>v[0-9][0-9_]*(?:\.[0-9_]+)*))                                     (?>\s*) ; /oxmsgc) { return "use $1;";           }
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s*)            (\()          (?>\s*) \) (?>\s*) ; /oxmsgc) { return e_use_noimport($1);  }
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) qw (?>\s*) (\()          (?>\s*) \) (?>\s*) ; /oxmsgc) { return e_use_noimport($1);  }
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) qw (?>\s*) (\{)          (?>\s*) \} (?>\s*) ; /oxmsgc) { return e_use_noimport($1);  }
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) qw (?>\s*) (\[)          (?>\s*) \] (?>\s*) ; /oxmsgc) { return e_use_noimport($1);  }
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) qw (?>\s*) (\<)          (?>\s*) \> (?>\s*) ; /oxmsgc) { return e_use_noimport($1);  }
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) qw (?>\s*) ([\x21-\x3F]) (?>\s*) \2 (?>\s*) ; /oxmsgc) { return e_use_noimport($1);  }
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) qw (?>\s*) (\S)          (?>\s*) \2 (?>\s*) ; /oxmsgc) { return e_use_noimport($1);  }

# use with import no parameter
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*))                                             (?>\s*) ; /oxmsgc) { return e_use_noparam($1);   }

# use with import parameters
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s*) (                          (\()    [^\x81-\xFE)]* \)) (?>\s*) ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s*) (                          (\')    [^\x81-\xFE']* \') (?>\s*) ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s*) (                          (\")    [^\x81-\xFE"]* \") (?>\s*) ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) ((?: q | qq | qw ) (?>\s*) (\()    [^\x81-\xFE)]* \)) (?>\s*) ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) ((?: q | qq | qw ) (?>\s*) (\{)    (?:$q_char)*?           \}) (?>\s*) ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) ((?: q | qq | qw ) (?>\s*) (\[)    (?:$q_char)*?           \]) (?>\s*) ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) ((?: q | qq | qw ) (?>\s*) (\<)    [^\x81-\xFE>]* \>) (?>\s*) ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) ((?: q | qq | qw ) (?>\s*) ([\x21-\x3F]) .*?               \3) (?>\s*) ; /oxmsgc) { return e_use($1,$2); }
    elsif (/\G \b use (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) ((?: q | qq | qw ) (?>\s*) (\S)    (?:$q_char)*?           \3) (?>\s*) ; /oxmsgc) { return e_use($1,$2); }

# no without unimport
    elsif (/\G \b no  (?>\s+) ((?>0[0-7_]*))                                                        (?>\s*) ; /oxmsgc) { return "no $1;";            }
    elsif (/\G \b no  (?>\s+) ((?>[1-9][0-9_]*(?:\.[0-9_]+)*))                                      (?>\s*) ; /oxmsgc) { return "no $1;";            }
    elsif (/\G \b no  (?>\s+) ((?>v[0-9][0-9_]*(?:\.[0-9_]+)*))                                     (?>\s*) ; /oxmsgc) { return "no $1;";            }
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s*)            (\()          (?>\s*) \) (?>\s*) ; /oxmsgc) { return e_no_nounimport($1); }
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) qw (?>\s*) (\()          (?>\s*) \) (?>\s*) ; /oxmsgc) { return e_no_nounimport($1); }
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) qw (?>\s*) (\{)          (?>\s*) \} (?>\s*) ; /oxmsgc) { return e_no_nounimport($1); }
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) qw (?>\s*) (\[)          (?>\s*) \] (?>\s*) ; /oxmsgc) { return e_no_nounimport($1); }
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) qw (?>\s*) (\<)          (?>\s*) \> (?>\s*) ; /oxmsgc) { return e_no_nounimport($1); }
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) qw (?>\s*) ([\x21-\x3F]) (?>\s*) \2 (?>\s*) ; /oxmsgc) { return e_no_nounimport($1); }
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) qw (?>\s*) (\S)          (?>\s*) \2 (?>\s*) ; /oxmsgc) { return e_no_nounimport($1); }

# no with unimport no parameter
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*))                                             (?>\s*) ; /oxmsgc) { return e_no_noparam($1);    }

# no with unimport parameters
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s*) (                          (\()    [^\x81-\xFE)]* \)) (?>\s*) ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s*) (                          (\')    [^\x81-\xFE']* \') (?>\s*) ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s*) (                          (\")    [^\x81-\xFE"]* \") (?>\s*) ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) ((?: q | qq | qw ) (?>\s*) (\()    [^\x81-\xFE)]* \)) (?>\s*) ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) ((?: q | qq | qw ) (?>\s*) (\{)    (?:$q_char)*?           \}) (?>\s*) ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) ((?: q | qq | qw ) (?>\s*) (\[)    (?:$q_char)*?           \]) (?>\s*) ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) ((?: q | qq | qw ) (?>\s*) (\<)    [^\x81-\xFE>]* \>) (?>\s*) ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) ((?: q | qq | qw ) (?>\s*) ([\x21-\x3F]) .*?               \3) (?>\s*) ; /oxmsgc) { return e_no($1,$2);  }
    elsif (/\G \b no  (?>\s+) ((?>[A-Z]\w*(?: ::\w+)*)) (?>\s+) ((?: q | qq | qw ) (?>\s*) (\S)    (?:$q_char)*?           \3) (?>\s*) ; /oxmsgc) { return e_no($1,$2);  }

# use else
    elsif (/\G \b use \b /oxmsgc) { return "use"; }

# use else
    elsif (/\G \b no  \b /oxmsgc) { return "no";  }

# ''
    elsif (/\G (?<![\w\$\@\%\&\*]) (\') /oxgc) {
        my $q_string = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)                  /oxgc) { $q_string .= $1;                   }
            elsif (/\G (\\\')                  /oxgc) { $q_string .= $1;                   }
            elsif (/\G \'                      /oxgc) { return e_q('', "'","'",$q_string); }
            elsif (/\G ($q_char)               /oxgc) { $q_string .= $1;                   }
        }
        die __FILE__, ": Can't find string terminator anywhere before EOF\n";
    }

# ""
    elsif (/\G (\") /oxgc) {
        my $qq_string = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)                  /oxgc) { $qq_string .= $1;                    }
            elsif (/\G (\\\")                  /oxgc) { $qq_string .= $1;                    }
            elsif (/\G \"                      /oxgc) { return e_qq('', '"','"',$qq_string); }
            elsif (/\G ($q_char)               /oxgc) { $qq_string .= $1;                    }
        }
        die __FILE__, ": Can't find string terminator anywhere before EOF\n";
    }

# ``
    elsif (/\G (\`) /oxgc) {
        my $qx_string = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)                  /oxgc) { $qx_string .= $1;                    }
            elsif (/\G (\\\`)                  /oxgc) { $qx_string .= $1;                    }
            elsif (/\G \`                      /oxgc) { return e_qq('', '`','`',$qx_string); }
            elsif (/\G ($q_char)               /oxgc) { $qx_string .= $1;                    }
        }
        die __FILE__, ": Can't find string terminator anywhere before EOF\n";
    }

# //   --- not divide operator (num / num), not defined-or
    elsif (($slash eq 'm//') and /\G (\/) /oxgc) {
        my $regexp = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)                  /oxgc) { $regexp .= $1;                       }
            elsif (/\G (\\\/)                  /oxgc) { $regexp .= $1;                       }
            elsif (/\G \/ ([cgimosxpadlunbB]*) /oxgc) { return e_qr('', '/','/',$regexp,$1); }
            elsif (/\G ($q_char)               /oxgc) { $regexp .= $1;                       }
        }
        die __FILE__, ": Search pattern not terminated\n";
    }

# ??   --- not conditional operator (condition ? then : else)
    elsif (($slash eq 'm//') and /\G (\?) /oxgc) {
        my $regexp = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)                  /oxgc) { $regexp .= $1;                       }
            elsif (/\G (\\\?)                  /oxgc) { $regexp .= $1;                       }
            elsif (/\G \? ([cgimosxpadlunbB]*) /oxgc) { return e_qr('m','?','?',$regexp,$1); }
            elsif (/\G ($q_char)               /oxgc) { $regexp .= $1;                       }
        }
        die __FILE__, ": Search pattern not terminated\n";
    }

# <<>> (a safer ARGV)
    elsif (/\G ( <<>> ) /oxgc)                         { $slash = 'm//'; return $1;          }

# << (bit shift)   --- not here document
    elsif (/\G ( << (?>\s*) ) (?= [0-9\$\@\&] ) /oxgc) { $slash = 'm//'; return $1;          }

# <<'HEREDOC'
    elsif (/\G ( << '([a-zA-Z_0-9]*)' ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        if ($here_script eq '') {
            $here_script = CORE::substr $_, pos $_;
            $here_script =~ s/.*?\n//oxm;
        }
        if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
            push @heredoc, $1 . qq{\n$delimiter\n};
            push @heredoc_delimiter, $delimiter;
        }
        else {
            die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF\n";
        }
        return $here_quote;
    }

# <<\HEREDOC

    # P.66 2.6.6. "Here" Documents
    # in Chapter 2: Bits and Pieces
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.73 "Here" Documents
    # in Chapter 2: Bits and Pieces
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    elsif (/\G ( << \\([a-zA-Z_0-9]+) ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        if ($here_script eq '') {
            $here_script = CORE::substr $_, pos $_;
            $here_script =~ s/.*?\n//oxm;
        }
        if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
            push @heredoc, $1 . qq{\n$delimiter\n};
            push @heredoc_delimiter, $delimiter;
        }
        else {
            die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF\n";
        }
        return $here_quote;
    }

# <<"HEREDOC"
    elsif (/\G ( << "([a-zA-Z_0-9]*)" ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        if ($here_script eq '') {
            $here_script = CORE::substr $_, pos $_;
            $here_script =~ s/.*?\n//oxm;
        }
        if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
            push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
            push @heredoc_delimiter, $delimiter;
        }
        else {
            die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF\n";
        }
        return $here_quote;
    }

# <<HEREDOC
    elsif (/\G ( << ([a-zA-Z_0-9]+) ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        if ($here_script eq '') {
            $here_script = CORE::substr $_, pos $_;
            $here_script =~ s/.*?\n//oxm;
        }
        if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
            push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
            push @heredoc_delimiter, $delimiter;
        }
        else {
            die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF\n";
        }
        return $here_quote;
    }

# <<`HEREDOC`
    elsif (/\G ( << `([a-zA-Z_0-9]*)` ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        if ($here_script eq '') {
            $here_script = CORE::substr $_, pos $_;
            $here_script =~ s/.*?\n//oxm;
        }
        if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
            push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
            push @heredoc_delimiter, $delimiter;
        }
        else {
            die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF\n";
        }
        return $here_quote;
    }

# <<= <=> <= < operator
    elsif (/\G ( <<= | <=> | <= | < ) (?= (?>\s*) [A-Za-z_0-9'"`\$\@\&\*\(\+\-] )/oxgc) {
        return $1;
    }

# <FILEHANDLE>
    elsif (/\G (<[\$]?[A-Za-z_][A-Za-z_0-9]*>) /oxgc) {
        return $1;
    }

# <WILDCARD> --- glob

    # avoid "Error: Runtime exception" of perl version 5.005_03

    elsif (/\G < ((?:[^\x81-\xFE>\0\a\e\f\n\r\t]|[\x81-\xFE][\x00-\xFF])+?) > /oxgc) {
        return 'Ekps9566::glob("' . $1 . '")';
    }

# __DATA__
    elsif (/\G ^ ( __DATA__ \n .*) \z /oxmsgc) { return $1; }

# __END__
    elsif (/\G ^ ( __END__  \n .*) \z /oxmsgc) { return $1; }

# \cD Control-D

    # P.68 2.6.8. Other Literal Tokens
    # in Chapter 2: Bits and Pieces
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.76 Other Literal Tokens
    # in Chapter 2: Bits and Pieces
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    elsif (/\G   ( \cD         .*) \z /oxmsgc) { return $1; }

# \cZ Control-Z
    elsif (/\G   ( \cZ         .*) \z /oxmsgc) { return $1; }

    # any operator before div
    elsif (/\G (
            -- | \+\+ |
            [\)\}\]]

            ) /oxgc) { $slash = 'div'; return $1; }

    # yada-yada or triple-dot operator
    elsif (/\G (
            \.\.\.

            ) /oxgc) { $slash = 'm//'; return q{die('Unimplemented')}; }

    # any operator before m//

    # //, //= (defined-or)

    # P.164 Logical Operators
    # in Chapter 10: More Control Structures
    # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

    # P.119 C-Style Logical (Short-Circuit) Operators
    # in Chapter 3: Unary and Binary Operators
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    # (and so on)

    # ~~

    # P.221 The Smart Match Operator
    # in Chapter 15: Smart Matching and given-when
    # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

    # P.112 Smartmatch Operator
    # in Chapter 3: Unary and Binary Operators
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    # (and so on)

    elsif (/\G ((?>

            !~~ | !~ | != | ! |
            %= | % |
            &&= | && | &= | &\.= | &\. | & |
            -= | -> | - |
            :(?>\s*)= |
            : |
            <<>> |
            <<= | <=> | <= | < |
            == | => | =~ | = |
            >>= | >> | >= | > |
            \*\*= | \*\* | \*= | \* |
            \+= | \+ |
            \.\. | \.= | \. |
            \/\/= | \/\/ |
            \/= | \/ |
            \? |
            \\ |
            \^= | \^\.= | \^\. | \^ |
            \b x= |
            \|\|= | \|\| | \|= | \|\.= | \|\. | \| |
            ~~ | ~\. | ~ |
            \b(?: and | cmp | eq | ge | gt | le | lt | ne | not | or | xor | x )\b |
            \b(?: print )\b |

            [,;\(\{\[]

            )) /oxgc) { $slash = 'm//'; return $1; }

    # other any character
    elsif (/\G ($q_char) /oxgc) { $slash = 'div'; return $1; }

    # system error
    else {
        die __FILE__, ": Oops, this shouldn't happen!\n";
    }
}

# escape KPS9566 string
sub e_string {
    my($string) = @_;
    my $e_string = '';

    local $slash = 'm//';

    # P.1024 Appendix W.10 Multibyte Processing
    # of ISBN 1-56592-224-7 CJKV Information Processing
    # (and so on)

    my @char = $string =~ / \G (?>[^\x81-\xFE\\]|\\$q_char|$q_char) /oxmsg;

    # without { ... }
    if (not (grep(/\A \{ \z/xms, @char) and grep(/\A \} \z/xms, @char))) {
        if ($string !~ /<</oxms) {
            return $string;
        }
    }

E_STRING_LOOP:
    while ($string !~ /\G \z/oxgc) {
        if (0) {
        }

# $`, ${`}, $PREMATCH, ${PREMATCH}, ${^PREMATCH} --> @{[Ekps9566::PREMATCH()]}
        elsif ($string =~ /\G ( \$` | \$\{`\} | \$ (?>\s*) PREMATCH  \b | \$ (?>\s*) \{ (?>\s*) PREMATCH  (?>\s*) \} | \$ (?>\s*) \{\^PREMATCH\}  ) /oxmsgc) {
            $e_string .= q{Ekps9566::PREMATCH()};
            $slash = 'div';
        }

# $&, ${&}, $MATCH, ${MATCH}, ${^MATCH} --> @{[Ekps9566::MATCH()]}
        elsif ($string =~ /\G ( \$& | \$\{&\} | \$ (?>\s*) MATCH     \b | \$ (?>\s*) \{ (?>\s*) MATCH     (?>\s*) \} | \$ (?>\s*) \{\^MATCH\}     ) /oxmsgc) {
            $e_string .= q{Ekps9566::MATCH()};
            $slash = 'div';
        }

# $', ${'} --> $', ${'}
        elsif ($string =~ /\G ( \$' | \$\{'\}                                                                                                     ) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }

# $POSTMATCH, ${POSTMATCH}, ${^POSTMATCH} --> @{[Ekps9566::POSTMATCH()]}
        elsif ($string =~ /\G (                 \$ (?>\s*) POSTMATCH \b | \$ (?>\s*) \{ (?>\s*) POSTMATCH (?>\s*) \} | \$ (?>\s*) \{\^POSTMATCH\} ) /oxmsgc) {
            $e_string .= q{Ekps9566::POSTMATCH()};
            $slash = 'div';
        }

# bareword
        elsif ($string =~ /\G ( \{ (?>\s*) (?: tr | index | rindex | reverse ) (?>\s*) \} ) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }

# $0 --> $0
        elsif ($string =~ /\G ( \$ 0 ) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }
        elsif ($string =~ /\G ( \$ \{ (?>\s*) 0 (?>\s*) \} ) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }

# $$ --> $$
        elsif ($string =~ /\G ( \$ \$ ) (?![\w\{]) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }

# $1, $2, $3 --> $2, $3, $4 after s/// with multibyte anchoring
# $1, $2, $3 --> $1, $2, $3 otherwise
        elsif ($string =~ /\G \$ ((?>[1-9][0-9]*)) /oxmsgc) {
            $e_string .= e_capture($1);
            $slash = 'div';
        }
        elsif ($string =~ /\G \$ \{ (?>\s*) ((?>[1-9][0-9]*)) (?>\s*) \} /oxmsgc) {
            $e_string .= e_capture($1);
            $slash = 'div';
        }

# $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($string =~ /\G \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) ( \[ .+? \] ) /oxmsgc) {
            $e_string .= e_capture($1.'->'.$2);
            $slash = 'div';
        }

# $$foo{ ... } --> $ $foo->{ ... }
        elsif ($string =~ /\G \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) ( \{ .+? \} ) /oxmsgc) {
            $e_string .= e_capture($1.'->'.$2);
            $slash = 'div';
        }

# $$foo
        elsif ($string =~ /\G \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) /oxmsgc) {
            $e_string .= e_capture($1);
            $slash = 'div';
        }

# ${ foo }
        elsif ($string =~ /\G \$ (?>\s*) \{ ((?> \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* )) \} /oxmsgc) {
            $e_string .= '${' . $1 . '}';
            $slash = 'div';
        }

# ${ ... }
        elsif ($string =~ /\G \$ (?>\s*) \{ (?>\s*) ( $qq_brace ) (?>\s*) \} /oxmsgc) {
            $e_string .= e_capture($1);
            $slash = 'div';
        }

# variable or function
        #                             $ @ % & *     $ #
        elsif ($string =~ /\G ( (?: [\$\@\%\&\*] | \$\# | -> | \b sub \b) (?>\s*) (?: split | chop | index | rindex | lc | uc | fc | chr | ord | reverse | getc | tr | y | q | qq | qx | qw | m | s | qr | glob | lstat | opendir | stat | unlink | chdir ) ) \b /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }
        #                           $ $ $ $ $ $ $ $ $ $ $ $ $ $
        #                           $ @ # \ ' " / ? ( ) [ ] < >
        elsif ($string =~ /\G ( \$[\$\@\#\\\'\"\/\?\(\)\[\]\<\>] ) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }

# subroutines of package Ekps9566
        elsif ($string =~ /\G \b (CORE:: | ->(>?\s*) (?: atan2 | [a-z]{2,})) \b       /oxgc) { $e_string .= $1;                  $slash = 'm//'; }
        elsif ($string =~ /\G \b Char::eval       (?= (?>\s*) \{ )                    /oxgc) { $e_string .= 'eval';              $slash = 'm//'; }
        elsif ($string =~ /\G \b KPS9566::eval       (?= (?>\s*) \{ )                    /oxgc) { $e_string .= 'eval';              $slash = 'm//'; }
        elsif ($string =~ /\G \b Char::eval \b                                        /oxgc) { $e_string .= 'eval Char::escape'; $slash = 'm//'; }
        elsif ($string =~ /\G \b KPS9566::eval \b                                        /oxgc) { $e_string .= 'eval KPS9566::escape'; $slash = 'm//'; }
        elsif ($string =~ /\G \b bytes::substr \b                                     /oxgc) { $e_string .= 'substr';            $slash = 'm//'; }
        elsif ($string =~ /\G \b chop \b                                              /oxgc) { $e_string .= 'Ekps9566::chop';       $slash = 'm//'; }
        elsif ($string =~ /\G \b bytes::index \b                                      /oxgc) { $e_string .= 'index';             $slash = 'm//'; }
        elsif ($string =~ /\G \b Char::index \b                                       /oxgc) { $e_string .= 'Char::index';       $slash = 'm//'; }
        elsif ($string =~ /\G \b KPS9566::index \b                                       /oxgc) { $e_string .= 'KPS9566::index';       $slash = 'm//'; }
        elsif ($string =~ /\G \b index \b                                             /oxgc) { $e_string .= 'Ekps9566::index';      $slash = 'm//'; }
        elsif ($string =~ /\G \b bytes::rindex \b                                     /oxgc) { $e_string .= 'rindex';            $slash = 'm//'; }
        elsif ($string =~ /\G \b Char::rindex \b                                      /oxgc) { $e_string .= 'Char::rindex';      $slash = 'm//'; }
        elsif ($string =~ /\G \b KPS9566::rindex \b                                      /oxgc) { $e_string .= 'KPS9566::rindex';      $slash = 'm//'; }
        elsif ($string =~ /\G \b rindex \b                                            /oxgc) { $e_string .= 'Ekps9566::rindex';     $slash = 'm//'; }
        elsif ($string =~ /\G \b lc      (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Ekps9566::lc';         $slash = 'm//'; }
        elsif ($string =~ /\G \b lcfirst (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Ekps9566::lcfirst';    $slash = 'm//'; }
        elsif ($string =~ /\G \b uc      (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Ekps9566::uc';         $slash = 'm//'; }
        elsif ($string =~ /\G \b ucfirst (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Ekps9566::ucfirst';    $slash = 'm//'; }
        elsif ($string =~ /\G \b fc      (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Ekps9566::fc';         $slash = 'm//'; }
        elsif ($string =~ /\G (-[rwxoRWXOezfdlpSbcugkTB] (?>(?:\s+ -[rwxoRWXOezfdlpSbcugkTB])+))
                                                                            (?>\s*) (\") ((?:$qq_char)+?)             (\") /oxgc) { $e_string .= "Ekps9566::filetest(qw($1)," . e_qq('',  $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) qq (?>\s*) (\#) ((?:$qq_char)+?)             (\#) /oxgc) { $e_string .= "Ekps9566::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) qq (?>\s*) (\() ((?:$qq_paren)+?)            (\)) /oxgc) { $e_string .= "Ekps9566::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) qq (?>\s*) (\{) ((?:$qq_brace)+?)            (\}) /oxgc) { $e_string .= "Ekps9566::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) qq (?>\s*) (\[) ((?:$qq_bracket)+?)          (\]) /oxgc) { $e_string .= "Ekps9566::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) qq (?>\s*) (\<) ((?:$qq_angle)+?)            (\>) /oxgc) { $e_string .= "Ekps9566::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) qq (?>\s*) (\S) ((?:$qq_char)+?)             (\2) /oxgc) { $e_string .= "Ekps9566::filetest(qw($1)," . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }

        elsif ($string =~ /\G (-[rwxoRWXOezfdlpSbcugkTB] (?>(?:\s+ -[rwxoRWXOezfdlpSbcugkTB])+))
                                                                            (?>\s*) (\') ((?:\\\'|\\\\|$q_char)+?)    (\') /oxgc) { $e_string .= "Ekps9566::filetest(qw($1)," . e_q ('',  $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) q  (?>\s*) (\#) ((?:\\\#|\\\\|$q_char)+?)    (\#) /oxgc) { $e_string .= "Ekps9566::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) q  (?>\s*) (\() ((?:\\\)|\\\\|$q_paren)+?)   (\)) /oxgc) { $e_string .= "Ekps9566::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) q  (?>\s*) (\{) ((?:\\\}|\\\\|$q_brace)+?)   (\}) /oxgc) { $e_string .= "Ekps9566::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) q  (?>\s*) (\[) ((?:\\\]|\\\\|$q_bracket)+?) (\]) /oxgc) { $e_string .= "Ekps9566::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) q  (?>\s*) (\<) ((?:\\\>|\\\\|$q_angle)+?)   (\>) /oxgc) { $e_string .= "Ekps9566::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) q  (?>\s*) (\S) ((?:\\\2|\\\\|$q_char)+?)    (\2) /oxgc) { $e_string .= "Ekps9566::filetest(qw($1)," . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }

        elsif ($string =~ /\G (-[rwxoRWXOezfdlpSbcugkTB] (?>(?:\s+ -[rwxoRWXOezfdlpSbcugkTB])+)) (\$ (?> \w+ (?: ::\w+)*) (?: (?: ->)? (?: [\$\@\%\&\*]\* | \$\#\* | \( (?:$qq_paren)*? \) | [\@\%\*]? \{ (?:$qq_brace)+? \} | [\@\%]? \[ (?:$qq_bracket)+? \] ) )*) /oxgc)
                                                                                                                                  { $e_string .= "Ekps9566::filetest(qw($1),$2)"; $slash = 'm//'; }
        elsif ($string =~ /\G (-[rwxoRWXOezfdlpSbcugkTB] (?>(?:\s+ -[rwxoRWXOezfdlpSbcugkTB])+)) \( ((?:$qq_paren)*?) \)   /oxgc) { $e_string .= "Ekps9566::filetest(qw($1),$2)"; $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) (?= [a-z]+)                                       /oxgc) { $e_string .= "Ekps9566::filetest qw($1),";    $slash = 'm//'; }
        elsif ($string =~ /\G ((?:-[rwxoRWXOezfdlpSbcugkTB](?>\s+)){2,}) ((?>\w+))                                         /oxgc) { $e_string .= "Ekps9566::filetest(qw($1),$2)"; $slash = 'm//'; }

        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC])            (?>\s*) (\") ((?:$qq_char)+?)                (\") /oxgc) { $e_string .= "Ekps9566::$1(" . e_qq('',  $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) qq (?>\s*) (\#) ((?:$qq_char)+?)                (\#) /oxgc) { $e_string .= "Ekps9566::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) qq (?>\s*) (\() ((?:$qq_paren)+?)               (\)) /oxgc) { $e_string .= "Ekps9566::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) qq (?>\s*) (\{) ((?:$qq_brace)+?)               (\}) /oxgc) { $e_string .= "Ekps9566::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) qq (?>\s*) (\[) ((?:$qq_bracket)+?)             (\]) /oxgc) { $e_string .= "Ekps9566::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) qq (?>\s*) (\<) ((?:$qq_angle)+?)               (\>) /oxgc) { $e_string .= "Ekps9566::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) qq (?>\s*) (\S) ((?:$qq_char)+?)                (\2) /oxgc) { $e_string .= "Ekps9566::$1(" . e_qq('qq',$2,$4,$3) . ")"; $slash = 'm//'; }

        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC])            (?>\s*) (\') ((?:\\\'|\\\\|$q_char)+?)       (\') /oxgc) { $e_string .= "Ekps9566::$1(" . e_q ('',  $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) q  (?>\s*) (\#) ((?:\\\#|\\\\|$q_char)+?)       (\#) /oxgc) { $e_string .= "Ekps9566::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) q  (?>\s*) (\() ((?:\\\)|\\\\|$q_paren)+?)      (\)) /oxgc) { $e_string .= "Ekps9566::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) q  (?>\s*) (\{) ((?:\\\}|\\\\|$q_brace)+?)      (\}) /oxgc) { $e_string .= "Ekps9566::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) q  (?>\s*) (\[) ((?:\\\]|\\\\|$q_bracket)+?)    (\]) /oxgc) { $e_string .= "Ekps9566::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) q  (?>\s*) (\<) ((?:\\\>|\\\\|$q_angle)+?)      (\>) /oxgc) { $e_string .= "Ekps9566::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) q  (?>\s*) (\S) ((?:\\\2|\\\\|$q_char)+?)       (\2) /oxgc) { $e_string .= "Ekps9566::$1(" . e_q ('q', $2,$4,$3) . ")"; $slash = 'm//'; }

        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s*) (\$ (?> \w+ (?: ::\w+)*) (?: (?: ->)? (?: [\$\@\%\&\*]\* | \$\#\* | \( (?:$qq_paren)*? \) | [\@\%\*]? \{ (?:$qq_brace)+? \} | [\@\%]? \[ (?:$qq_bracket)+? \] ) )*) /oxgc)
                                                                                                                                  { $e_string .= "Ekps9566::$1($2)";      $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s*) \( ((?:$qq_paren)*?) \)                              /oxgc) { $e_string .= "Ekps9566::$1($2)";      $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?= (?>\s+) [a-z]+)                                          /oxgc) { $e_string .= "Ekps9566::$1";          $slash = 'm//'; }
        elsif ($string =~ /\G -([rwxoRWXOezsfdlpSbcugkTBMAC]) (?>\s+) ((?>\w+))                                            /oxgc) { $e_string .= "Ekps9566::$1(::"."$2)"; $slash = 'm//'; }
        elsif ($string =~ /\G -(t)                            (?>\s+) ((?>\w+))                                            /oxgc) { $e_string .= "-t $2";              $slash = 'm//'; }
        elsif ($string =~ /\G \b lstat         (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(])                                /oxgc) { $e_string .= 'Ekps9566::lstat';       $slash = 'm//'; }
        elsif ($string =~ /\G \b stat          (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(])                                /oxgc) { $e_string .= 'Ekps9566::stat';        $slash = 'm//'; }

        # "-s '' ..." means file test "-s 'filename' ..." (not means "- s/// ...")
        elsif ($string =~ /\G -s                                         (?>\s*) (\") ((?:$qq_char)+?)                (\") /oxgc) { $e_string .= '-s ' . e_qq('',  $1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                              (?>\s+) qq (?>\s*) (\#) ((?:$qq_char)+?)                (\#) /oxgc) { $e_string .= '-s ' . e_qq('qq',$1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                              (?>\s+) qq (?>\s*) (\() ((?:$qq_paren)+?)               (\)) /oxgc) { $e_string .= '-s ' . e_qq('qq',$1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                              (?>\s+) qq (?>\s*) (\{) ((?:$qq_brace)+?)               (\}) /oxgc) { $e_string .= '-s ' . e_qq('qq',$1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                              (?>\s+) qq (?>\s*) (\[) ((?:$qq_bracket)+?)             (\]) /oxgc) { $e_string .= '-s ' . e_qq('qq',$1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                              (?>\s+) qq (?>\s*) (\<) ((?:$qq_angle)+?)               (\>) /oxgc) { $e_string .= '-s ' . e_qq('qq',$1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                              (?>\s+) qq (?>\s*) (\S) ((?:$qq_char)+?)                (\1) /oxgc) { $e_string .= '-s ' . e_qq('qq',$1,$3,$2); $slash = 'm//'; }

        elsif ($string =~ /\G -s                                         (?>\s*) (\') ((?:\\\'|\\\\|$q_char)+?)       (\') /oxgc) { $e_string .= '-s ' . e_q ('',  $1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                              (?>\s+) q  (?>\s*) (\#) ((?:\\\#|\\\\|$q_char)+?)       (\#) /oxgc) { $e_string .= '-s ' . e_q ('q', $1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                              (?>\s+) q  (?>\s*) (\() ((?:\\\)|\\\\|$q_paren)+?)      (\)) /oxgc) { $e_string .= '-s ' . e_q ('q', $1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                              (?>\s+) q  (?>\s*) (\{) ((?:\\\}|\\\\|$q_brace)+?)      (\}) /oxgc) { $e_string .= '-s ' . e_q ('q', $1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                              (?>\s+) q  (?>\s*) (\[) ((?:\\\]|\\\\|$q_bracket)+?)    (\]) /oxgc) { $e_string .= '-s ' . e_q ('q', $1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                              (?>\s+) q  (?>\s*) (\<) ((?:\\\>|\\\\|$q_angle)+?)      (\>) /oxgc) { $e_string .= '-s ' . e_q ('q', $1,$3,$2); $slash = 'm//'; }
        elsif ($string =~ /\G -s                              (?>\s+) q  (?>\s*) (\S) ((?:\\\1|\\\\|$q_char)+?)       (\1) /oxgc) { $e_string .= '-s ' . e_q ('q', $1,$3,$2); $slash = 'm//'; }

        elsif ($string =~ /\G -s                              (?>\s*) (\$ (?> \w+ (?: ::\w+)*) (?: (?: ->)? (?: [\$\@\%\&\*]\* | \$\#\* | \( (?:$qq_paren)*? \) | [\@\%\*]? \{ (?:$qq_brace)+? \} | [\@\%]? \[ (?:$qq_bracket)+? \] ))*) /oxgc)
                                                                                                                                  { $e_string .= "-s $1";   $slash = 'm//'; }
        elsif ($string =~ /\G -s                              (?>\s*) \( ((?:$qq_paren)*?) \)                              /oxgc) { $e_string .= "-s ($1)"; $slash = 'm//'; }
        elsif ($string =~ /\G -s                              (?= (?>\s+) [a-z]+)                                          /oxgc) { $e_string .= '-s';      $slash = 'm//'; }
        elsif ($string =~ /\G -s                              (?>\s+) ((?>\w+))                                            /oxgc) { $e_string .= "-s $1";   $slash = 'm//'; }

        elsif ($string =~ /\G \b bytes::length (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'length';               $slash = 'm//'; }
        elsif ($string =~ /\G \b bytes::chr    (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'chr';                  $slash = 'm//'; }
        elsif ($string =~ /\G \b chr           (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Ekps9566::chr';           $slash = 'm//'; }
        elsif ($string =~ /\G \b bytes::ord    (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'ord';                  $slash = 'div'; }
        elsif ($string =~ /\G \b ord           (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $e_string .= $function_ord;          $slash = 'div'; }
        elsif ($string =~ /\G \b glob          (?= (?>\s+)[A-Za-z_]|(?>\s*)['"`\$\@\&\*\(]) /oxgc) { $e_string .= 'Ekps9566::glob';          $slash = 'm//'; }
        elsif ($string =~ /\G \b lc \b                                                      /oxgc) { $e_string .= 'Ekps9566::lc_';               $slash = 'm//'; }
        elsif ($string =~ /\G \b lcfirst \b                                                 /oxgc) { $e_string .= 'Ekps9566::lcfirst_';          $slash = 'm//'; }
        elsif ($string =~ /\G \b uc \b                                                      /oxgc) { $e_string .= 'Ekps9566::uc_';               $slash = 'm//'; }
        elsif ($string =~ /\G \b ucfirst \b                                                 /oxgc) { $e_string .= 'Ekps9566::ucfirst_';          $slash = 'm//'; }
        elsif ($string =~ /\G \b fc \b                                                      /oxgc) { $e_string .= 'Ekps9566::fc_';               $slash = 'm//'; }
        elsif ($string =~ /\G \b lstat \b                                                   /oxgc) { $e_string .= 'Ekps9566::lstat_';            $slash = 'm//'; }
        elsif ($string =~ /\G \b stat \b                                                    /oxgc) { $e_string .= 'Ekps9566::stat_';             $slash = 'm//'; }
        elsif ($string =~ /\G    (-[rwxoRWXOezfdlpSbcugkTB] (?>(?:\s+ -[rwxoRWXOezfdlpSbcugkTB])+))
                                                                 \b                         /oxgc) { $e_string .= "Ekps9566::filetest_(qw($1))"; $slash = 'm//'; }
        elsif ($string =~ /\G    -([rwxoRWXOezsfdlpSbcugkTBMAC]) \b                         /oxgc) { $e_string .= "Ekps9566::${1}_";             $slash = 'm//'; }
        elsif ($string =~ /\G    -s                              \b                         /oxgc) { $e_string .= '-s ';                      $slash = 'm//'; }

        elsif ($string =~ /\G \b bytes::length \b                                           /oxgc) { $e_string .= 'length';                   $slash = 'm//'; }
        elsif ($string =~ /\G \b bytes::chr \b                                              /oxgc) { $e_string .= 'chr';                      $slash = 'm//'; }
        elsif ($string =~ /\G \b chr \b                                                     /oxgc) { $e_string .= 'Ekps9566::chr_';              $slash = 'm//'; }
        elsif ($string =~ /\G \b bytes::ord \b                                              /oxgc) { $e_string .= 'ord';                      $slash = 'div'; }
        elsif ($string =~ /\G \b ord \b                                                     /oxgc) { $e_string .= $function_ord_;             $slash = 'div'; }
        elsif ($string =~ /\G \b glob \b                                                    /oxgc) { $e_string .= 'Ekps9566::glob_';             $slash = 'm//'; }
        elsif ($string =~ /\G \b reverse \b                                                 /oxgc) { $e_string .= $function_reverse;          $slash = 'm//'; }
        elsif ($string =~ /\G \b getc \b                                                    /oxgc) { $e_string .= $function_getc;             $slash = 'm//'; }
        elsif ($string =~ /\G \b opendir ((?>\s*) \( (?>\s*)) (?=[A-Za-z_])                 /oxgc) { $e_string .= "Ekps9566::opendir$1*";        $slash = 'm//'; }
        elsif ($string =~ /\G \b opendir ((?>\s+))            (?=[A-Za-z_])                 /oxgc) { $e_string .= "Ekps9566::opendir$1*";        $slash = 'm//'; }
        elsif ($string =~ /\G \b unlink \b                                                  /oxgc) { $e_string .= 'Ekps9566::unlink';            $slash = 'm//'; }

# chdir
        elsif ($string =~ /\G \b (chdir) \b (?! (?>\s*) => ) /oxgc) {
            $slash = 'm//';

            $e_string .= 'Ekps9566::chdir';

            while ($string =~ /\G ( (?>\s+) | \( | \#.* ) /oxgc) {
                $e_string .= $1;
            }

# end of chdir
            if    ($string =~ /\G (?= [,;\)\}\]] )          /oxgc) { return $e_string;                               }

# chdir scalar value
            elsif ($string =~ /\G ( [\$\@\&\*] $qq_scalar ) /oxgc) { $e_string .= e_string($1);  next E_STRING_LOOP; }

# chdir qq//
            elsif ($string =~ /\G \b (qq) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) /oxgc)                             { $e_string .= e_chdir('qq',$1,$3,$2);   next E_STRING_LOOP; } # qq# #  --> qr # #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G ((?>\s+)|\#.*)                              /oxgc) { $e_string .= $1; }
                        elsif ($string =~ /\G (\()          ((?:$qq_paren)*?)   (\))      /oxgc) { $e_string .= e_chdir('qq',$1,$3,$2);   next E_STRING_LOOP; } # qq ( ) --> qr ( )
                        elsif ($string =~ /\G (\{)          ((?:$qq_brace)*?)   (\})      /oxgc) { $e_string .= e_chdir('qq',$1,$3,$2);   next E_STRING_LOOP; } # qq { } --> qr { }
                        elsif ($string =~ /\G (\[)          ((?:$qq_bracket)*?) (\])      /oxgc) { $e_string .= e_chdir('qq',$1,$3,$2);   next E_STRING_LOOP; } # qq [ ] --> qr [ ]
                        elsif ($string =~ /\G (\<)          ((?:$qq_angle)*?)   (\>)      /oxgc) { $e_string .= e_chdir('qq',$1,$3,$2);   next E_STRING_LOOP; } # qq < > --> qr < >
                        elsif ($string =~ /\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1)      /oxgc) { $e_string .= e_chdir('qq','{','}',$2); next E_STRING_LOOP; } # qq | | --> qr { }
                        elsif ($string =~ /\G (\S)          ((?:$qq_char)*?)    (\1)      /oxgc) { $e_string .= e_chdir('qq',$1,$3,$2);   next E_STRING_LOOP; } # qq * * --> qr * *
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF\n";
                }
            }

# chdir q//
            elsif ($string =~ /\G \b (q) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc)                    { $e_string .= e_chdir_q('q',$1,$3,$2);   next E_STRING_LOOP; } # q# #  --> qr # #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G ((?>\s+)|\#.*)                              /oxgc) { $e_string .= $1; }
                        elsif ($string =~ /\G (\() ((?:\\\\|\\\)|\\\(|$q_paren)*?)   (\)) /oxgc) { $e_string .= e_chdir_q('q',$1,$3,$2);   next E_STRING_LOOP; } # q ( ) --> qr ( )
                        elsif ($string =~ /\G (\{) ((?:\\\\|\\\}|\\\{|$q_brace)*?)   (\}) /oxgc) { $e_string .= e_chdir_q('q',$1,$3,$2);   next E_STRING_LOOP; } # q { } --> qr { }
                        elsif ($string =~ /\G (\[) ((?:\\\\|\\\]|\\\[|$q_bracket)*?) (\]) /oxgc) { $e_string .= e_chdir_q('q',$1,$3,$2);   next E_STRING_LOOP; } # q [ ] --> qr [ ]
                        elsif ($string =~ /\G (\<) ((?:\\\\|\\\>|\\\<|$q_angle)*?)   (\>) /oxgc) { $e_string .= e_chdir_q('q',$1,$3,$2);   next E_STRING_LOOP; } # q < > --> qr < >
                        elsif ($string =~ /\G ([*\-:?\\^|])       ((?:$q_char)*?)    (\1) /oxgc) { $e_string .= e_chdir_q('q','{','}',$2); next E_STRING_LOOP; } # q | | --> qr { }
                        elsif ($string =~ /\G (\S) ((?:\\\\|\\\1|     $q_char)*?)    (\1) /oxgc) { $e_string .= e_chdir_q('q',$1,$3,$2);   next E_STRING_LOOP; } # q * * --> qr * *
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF\n";
                }
            }

# chdir ''
            elsif ($string =~ /\G (\') /oxgc) {
                my $q_string = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\\\\)    /oxgc) { $q_string .= $1; }
                    elsif ($string =~ /\G (\\\')    /oxgc) { $q_string .= $1; }
                    elsif ($string =~ /\G \'        /oxgc)                                       { $e_string .= e_chdir_q('',"'","'",$q_string); next E_STRING_LOOP; }
                    elsif ($string =~ /\G ($q_char) /oxgc) { $q_string .= $1; }
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF\n";
            }

# chdir ""
            elsif ($string =~ /\G (\") /oxgc) {
                my $qq_string = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\\\\)    /oxgc) { $qq_string .= $1; }
                    elsif ($string =~ /\G (\\\")    /oxgc) { $qq_string .= $1; }
                    elsif ($string =~ /\G \"        /oxgc)                                       { $e_string .= e_chdir('','"','"',$qq_string); next E_STRING_LOOP; }
                    elsif ($string =~ /\G ($q_char) /oxgc) { $qq_string .= $1; }
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF\n";
            }
        }

# split
        elsif ($string =~ /\G \b (split) \b (?! (?>\s*) => ) /oxgc) {
            $slash = 'm//';

            my $e = '';
            while ($string =~ /\G ( (?>\s+) | \( | \#.* ) /oxgc) {
                $e .= $1;
            }

# end of split
            if    ($string =~ /\G (?= [,;\)\}\]] )          /oxgc) { return 'Ekps9566::split' . $e;                                           }

# split scalar value
            elsif ($string =~ /\G ( [\$\@\&\*] $qq_scalar ) /oxgc) { $e_string .= 'Ekps9566::split' . $e . e_string($1);  next E_STRING_LOOP; }

# split literal space
            elsif ($string =~ /\G \b qq           (\#) [ ] (\#) /oxgc) { $e_string .= 'Ekps9566::split' . $e . qq  {qq$1 $2}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b qq ((?>\s*)) (\() [ ] (\)) /oxgc) { $e_string .= 'Ekps9566::split' . $e . qq{$1qq$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b qq ((?>\s*)) (\{) [ ] (\}) /oxgc) { $e_string .= 'Ekps9566::split' . $e . qq{$1qq$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b qq ((?>\s*)) (\[) [ ] (\]) /oxgc) { $e_string .= 'Ekps9566::split' . $e . qq{$1qq$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b qq ((?>\s*)) (\<) [ ] (\>) /oxgc) { $e_string .= 'Ekps9566::split' . $e . qq{$1qq$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b qq ((?>\s*)) (\S) [ ] (\2) /oxgc) { $e_string .= 'Ekps9566::split' . $e . qq{$1qq$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q            (\#) [ ] (\#) /oxgc) { $e_string .= 'Ekps9566::split' . $e . qq   {q$1 $2}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q  ((?>\s*)) (\() [ ] (\)) /oxgc) { $e_string .= 'Ekps9566::split' . $e . qq {$1q$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q  ((?>\s*)) (\{) [ ] (\}) /oxgc) { $e_string .= 'Ekps9566::split' . $e . qq {$1q$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q  ((?>\s*)) (\[) [ ] (\]) /oxgc) { $e_string .= 'Ekps9566::split' . $e . qq {$1q$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q  ((?>\s*)) (\<) [ ] (\>) /oxgc) { $e_string .= 'Ekps9566::split' . $e . qq {$1q$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G \b q  ((?>\s*)) (\S) [ ] (\2) /oxgc) { $e_string .= 'Ekps9566::split' . $e . qq {$1q$2 $3}; next E_STRING_LOOP; }
            elsif ($string =~ /\G                    ' [ ] '    /oxgc) { $e_string .= 'Ekps9566::split' . $e . qq     {' '};  next E_STRING_LOOP; }
            elsif ($string =~ /\G                    " [ ] "    /oxgc) { $e_string .= 'Ekps9566::split' . $e . qq     {" "};  next E_STRING_LOOP; }

# split qq//
            elsif ($string =~ /\G \b (qq) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) /oxgc)                        { $e_string .= e_split($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq# #  --> qr # #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G ((?>\s+)|\#.*)                         /oxgc) { $e_string .= $e . $1; }
                        elsif ($string =~ /\G (\()          ((?:$qq_paren)*?)   (\)) /oxgc) { $e_string .= e_split($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq ( ) --> qr ( )
                        elsif ($string =~ /\G (\{)          ((?:$qq_brace)*?)   (\}) /oxgc) { $e_string .= e_split($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq { } --> qr { }
                        elsif ($string =~ /\G (\[)          ((?:$qq_bracket)*?) (\]) /oxgc) { $e_string .= e_split($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq [ ] --> qr [ ]
                        elsif ($string =~ /\G (\<)          ((?:$qq_angle)*?)   (\>) /oxgc) { $e_string .= e_split($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq < > --> qr < >
                        elsif ($string =~ /\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= e_split($e.'qr','{','}',$2,''); next E_STRING_LOOP; } # qq | | --> qr { }
                        elsif ($string =~ /\G (\S)          ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= e_split($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # qq * * --> qr * *
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF\n";
                }
            }

# split qr//
            elsif ($string =~ /\G \b (qr) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) ([imosxpadlunbB]*) /oxgc)                        { $e_string .= e_split  ($e.'qr',$1,$3,$2,$4);   next E_STRING_LOOP; } # qr# #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G ((?>\s+)|\#.*)                                            /oxgc) { $e_string .= $e . $1; }
                        elsif ($string =~ /\G (\()          ((?:$qq_paren)*?)   (\)) ([imosxpadlunbB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr ( )
                        elsif ($string =~ /\G (\{)          ((?:$qq_brace)*?)   (\}) ([imosxpadlunbB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr { }
                        elsif ($string =~ /\G (\[)          ((?:$qq_bracket)*?) (\]) ([imosxpadlunbB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr [ ]
                        elsif ($string =~ /\G (\<)          ((?:$qq_angle)*?)   (\>) ([imosxpadlunbB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr < >
                        elsif ($string =~ /\G (\')          ((?:$qq_char)*?)    (\') ([imosxpadlunbB]*) /oxgc) { $e_string .= e_split_q($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr ' '
                        elsif ($string =~ /\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([imosxpadlunbB]*) /oxgc) { $e_string .= e_split  ($e.'qr','{','}',$2,$4); next E_STRING_LOOP; } # qr | | --> qr { }
                        elsif ($string =~ /\G (\S)          ((?:$qq_char)*?)    (\1) ([imosxpadlunbB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # qr * *
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF\n";
                }
            }

# split q//
            elsif ($string =~ /\G \b (q) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc)                    { $e_string .= e_split_q($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q# #  --> qr # #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G ((?>\s+)|\#.*)                              /oxgc) { $e_string .= $e . $1; }
                        elsif ($string =~ /\G (\() ((?:\\\\|\\\)|\\\(|$q_paren)*?)   (\)) /oxgc) { $e_string .= e_split_q($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q ( ) --> qr ( )
                        elsif ($string =~ /\G (\{) ((?:\\\\|\\\}|\\\{|$q_brace)*?)   (\}) /oxgc) { $e_string .= e_split_q($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q { } --> qr { }
                        elsif ($string =~ /\G (\[) ((?:\\\\|\\\]|\\\[|$q_bracket)*?) (\]) /oxgc) { $e_string .= e_split_q($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q [ ] --> qr [ ]
                        elsif ($string =~ /\G (\<) ((?:\\\\|\\\>|\\\<|$q_angle)*?)   (\>) /oxgc) { $e_string .= e_split_q($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q < > --> qr < >
                        elsif ($string =~ /\G ([*\-:?\\^|])       ((?:$q_char)*?)    (\1) /oxgc) { $e_string .= e_split_q($e.'qr','{','}',$2,''); next E_STRING_LOOP; } # q | | --> qr { }
                        elsif ($string =~ /\G (\S) ((?:\\\\|\\\1|     $q_char)*?)    (\1) /oxgc) { $e_string .= e_split_q($e.'qr',$1,$3,$2,'');   next E_STRING_LOOP; } # q * * --> qr * *
                    }
                    die __FILE__, ": Can't find string terminator anywhere before EOF\n";
                }
            }

# split m//
            elsif ($string =~ /\G \b (m) \b /oxgc) {
                if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) ([cgimosxpadlunbB]*) /oxgc)                        { $e_string .= e_split  ($e.'qr',$1,$3,$2,$4);   next E_STRING_LOOP; } # m# #  --> qr # #
                else {
                    while ($string !~ /\G \z/oxgc) {
                        if    ($string =~ /\G ((?>\s+)|\#.*)                                              /oxgc) { $e_string .= $e . $1; }
                        elsif ($string =~ /\G (\()          ((?:$qq_paren)*?)   (\)) ([cgimosxpadlunbB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m ( ) --> qr ( )
                        elsif ($string =~ /\G (\{)          ((?:$qq_brace)*?)   (\}) ([cgimosxpadlunbB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m { } --> qr { }
                        elsif ($string =~ /\G (\[)          ((?:$qq_bracket)*?) (\]) ([cgimosxpadlunbB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m [ ] --> qr [ ]
                        elsif ($string =~ /\G (\<)          ((?:$qq_angle)*?)   (\>) ([cgimosxpadlunbB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m < > --> qr < >
                        elsif ($string =~ /\G (\')          ((?:$qq_char)*?)    (\') ([cgimosxpadlunbB]*) /oxgc) { $e_string .= e_split_q($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m ' ' --> qr ' '
                        elsif ($string =~ /\G ([*\-:?\\^|]) ((?:$qq_char)*?)    (\1) ([cgimosxpadlunbB]*) /oxgc) { $e_string .= e_split  ($e.'qr','{','}',$2,$4); next E_STRING_LOOP; } # m | | --> qr { }
                        elsif ($string =~ /\G (\S)          ((?:$qq_char)*?)    (\1) ([cgimosxpadlunbB]*) /oxgc) { $e_string .= e_split  ($e.'qr',$1, $3, $2,$4); next E_STRING_LOOP; } # m * * --> qr * *
                    }
                    die __FILE__, ": Search pattern not terminated\n";
                }
            }

# split ''
            elsif ($string =~ /\G (\') /oxgc) {
                my $q_string = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\\\\)    /oxgc) { $q_string .= $1; }
                    elsif ($string =~ /\G (\\\')    /oxgc) { $q_string .= $1; } # splitqr'' --> split qr''
                    elsif ($string =~ /\G \'        /oxgc)                      { $e_string .= e_split_q($e.q{ qr},"'","'",$q_string,''); next E_STRING_LOOP; } # ' ' --> qr ' '
                    elsif ($string =~ /\G ($q_char) /oxgc) { $q_string .= $1; }
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF\n";
            }

# split ""
            elsif ($string =~ /\G (\") /oxgc) {
                my $qq_string = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\\\\)    /oxgc) { $qq_string .= $1; }
                    elsif ($string =~ /\G (\\\")    /oxgc) { $qq_string .= $1; } # splitqr"" --> split qr""
                    elsif ($string =~ /\G \"        /oxgc)                       { $e_string .= e_split($e.q{ qr},'"','"',$qq_string,''); next E_STRING_LOOP; } # " " --> qr " "
                    elsif ($string =~ /\G ($q_char) /oxgc) { $qq_string .= $1; }
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF\n";
            }

# split //
            elsif ($string =~ /\G (\/) /oxgc) {
                my $regexp = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\\\\)                  /oxgc) { $regexp .= $1; }
                    elsif ($string =~ /\G (\\\/)                  /oxgc) { $regexp .= $1; } # splitqr// --> split qr//
                    elsif ($string =~ /\G \/ ([cgimosxpadlunbB]*) /oxgc)                    { $e_string .= e_split($e.q{ qr}, '/','/',$regexp,$1); next E_STRING_LOOP; } # / / --> qr / /
                    elsif ($string =~ /\G ($q_char)               /oxgc) { $regexp .= $1; }
                }
                die __FILE__, ": Search pattern not terminated\n";
            }
        }

# qq//
        elsif ($string =~ /\G \b (qq) \b /oxgc) {
            my $ope = $1;
            if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { # qq# #
                $e_string .= e_qq($ope,$1,$3,$2);
            }
            else {
                my $e = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G ((?>\s+)|\#.*)                /oxgc) { $e .= $1; }
                    elsif ($string =~ /\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq ( )
                    elsif ($string =~ /\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq { }
                    elsif ($string =~ /\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq [ ]
                    elsif ($string =~ /\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq < >
                    elsif ($string =~ /\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF\n";
            }
        }

# qx//
        elsif ($string =~ /\G \b (qx) \b /oxgc) {
            my $ope = $1;
            if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { # qx# #
                $e_string .= e_qq($ope,$1,$3,$2);
            }
            else {
                my $e = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G ((?>\s+)|\#.*)                /oxgc) { $e .= $1; }
                    elsif ($string =~ /\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx ( )
                    elsif ($string =~ /\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx { }
                    elsif ($string =~ /\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx [ ]
                    elsif ($string =~ /\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx < >
                    elsif ($string =~ /\G (\') ((?:$qq_char)*?)    (\') /oxgc) { $e_string .= $e . e_q ($ope,$1,$3,$2); next E_STRING_LOOP; } # qx ' '
                    elsif ($string =~ /\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF\n";
            }
        }

# q//
        elsif ($string =~ /\G \b (q) \b /oxgc) {
            my $ope = $1;
            if ($string =~ /\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc) { # q# #
                $e_string .= e_q($ope,$1,$3,$2);
            }
            else {
                my $e = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G ((?>\s+)|\#.*)                              /oxgc) { $e .= $1; }
                    elsif ($string =~ /\G (\() ((?:\\\\|\\\)|\\\(|$q_paren)*?)   (\)) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q ( )
                    elsif ($string =~ /\G (\{) ((?:\\\\|\\\}|\\\{|$q_brace)*?)   (\}) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q { }
                    elsif ($string =~ /\G (\[) ((?:\\\\|\\\]|\\\[|$q_bracket)*?) (\]) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q [ ]
                    elsif ($string =~ /\G (\<) ((?:\\\\|\\\>|\\\<|$q_angle)*?)   (\>) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q < >
                    elsif ($string =~ /\G (\S) ((?:\\\\|\\\1|     $q_char)*?)    (\1) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q * *
                }
                die __FILE__, ": Can't find string terminator anywhere before EOF\n";
            }
        }

# ''
        elsif ($string =~ /\G (?<![\w\$\@\%\&\*]) (\') ((?:\\\'|\\\\|$q_char)*?) (\')           /oxgc) { $e_string .= e_q('',$1,$3,$2);  }

# ""
        elsif ($string =~ /\G (\") ((?:$qq_char)*?) (\")                                        /oxgc) { $e_string .= e_qq('',$1,$3,$2); }

# ``
        elsif ($string =~ /\G (\`) ((?:$qq_char)*?) (\`)                                        /oxgc) { $e_string .= e_qq('',$1,$3,$2); }

# <<>> (a safer ARGV)
        elsif ($string =~ /\G ( <<>> )                                                          /oxgc) { $e_string .= $1;                }

# <<= <=> <= < operator
        elsif ($string =~ /\G ( <<= | <=> | <= | < ) (?= (?>\s*) [A-Za-z_0-9'"`\$\@\&\*\(\+\-] )/oxgc) { $e_string .= $1;                }

# <FILEHANDLE>
        elsif ($string =~ /\G (<[\$]?[A-Za-z_][A-Za-z_0-9]*>)                         /oxgc) { $e_string .= $1;                }

# <WILDCARD>   --- glob
        elsif ($string =~ /\G < ((?:$q_char)+?) > /oxgc) {
            $e_string .= 'Ekps9566::glob("' . $1 . '")';
        }

# << (bit shift)   --- not here document
        elsif ($string =~ /\G ( << (?>\s*) ) (?= [0-9\$\@\&] ) /oxgc)                        { $slash = 'm//'; $e_string .= $1; }

# <<'HEREDOC'
        elsif ($string =~ /\G ( << '([a-zA-Z_0-9]*)' ) /oxgc) {
            $slash = 'm//';
            my $here_quote = $1;
            my $delimiter  = $2;

            # get here document
            if ($here_script eq '') {
                $here_script = CORE::substr $_, pos $_;
                $here_script =~ s/.*?\n//oxm;
            }
            if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
                push @heredoc, $1 . qq{\n$delimiter\n};
                push @heredoc_delimiter, $delimiter;
            }
            else {
                die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF\n";
            }
            $e_string .= $here_quote;
        }

# <<\HEREDOC
        elsif ($string =~ /\G ( << \\([a-zA-Z_0-9]+) ) /oxgc) {
            $slash = 'm//';
            my $here_quote = $1;
            my $delimiter  = $2;

            # get here document
            if ($here_script eq '') {
                $here_script = CORE::substr $_, pos $_;
                $here_script =~ s/.*?\n//oxm;
            }
            if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
                push @heredoc, $1 . qq{\n$delimiter\n};
                push @heredoc_delimiter, $delimiter;
            }
            else {
                die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF\n";
            }
            $e_string .= $here_quote;
        }

# <<"HEREDOC"
        elsif ($string =~ /\G ( << "([a-zA-Z_0-9]*)" ) /oxgc) {
            $slash = 'm//';
            my $here_quote = $1;
            my $delimiter  = $2;

            # get here document
            if ($here_script eq '') {
                $here_script = CORE::substr $_, pos $_;
                $here_script =~ s/.*?\n//oxm;
            }
            if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
                push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
                push @heredoc_delimiter, $delimiter;
            }
            else {
                die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF\n";
            }
            $e_string .= $here_quote;
        }

# <<HEREDOC
        elsif ($string =~ /\G ( << ([a-zA-Z_0-9]+) ) /oxgc) {
            $slash = 'm//';
            my $here_quote = $1;
            my $delimiter  = $2;

            # get here document
            if ($here_script eq '') {
                $here_script = CORE::substr $_, pos $_;
                $here_script =~ s/.*?\n//oxm;
            }
            if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
                push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
                push @heredoc_delimiter, $delimiter;
            }
            else {
                die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF\n";
            }
            $e_string .= $here_quote;
        }

# <<`HEREDOC`
        elsif ($string =~ /\G ( << `([a-zA-Z_0-9]*)` ) /oxgc) {
            $slash = 'm//';
            my $here_quote = $1;
            my $delimiter  = $2;

            # get here document
            if ($here_script eq '') {
                $here_script = CORE::substr $_, pos $_;
                $here_script =~ s/.*?\n//oxm;
            }
            if ($here_script =~ s/\A (.*?) \n $delimiter \n //xms) {
                push @heredoc, e_heredoc($1) . qq{\n$delimiter\n};
                push @heredoc_delimiter, $delimiter;
            }
            else {
                die __FILE__, ": Can't find string terminator $delimiter anywhere before EOF\n";
            }
            $e_string .= $here_quote;
        }

        # any operator before div
        elsif ($string =~ /\G (
            -- | \+\+ |
            [\)\}\]]

            ) /oxgc) { $slash = 'div'; $e_string .= $1; }

        # yada-yada or triple-dot operator
        elsif ($string =~ /\G (
            \.\.\.

            ) /oxgc) { $slash = 'm//'; $e_string .= q{die('Unimplemented')}; }

        # any operator before m//
        elsif ($string =~ /\G ((?>

            !~~ | !~ | != | ! |
            %= | % |
            &&= | && | &= | &\.= | &\. | & |
            -= | -> | - |
            :(?>\s*)= |
            : |
            <<>> |
            <<= | <=> | <= | < |
            == | => | =~ | = |
            >>= | >> | >= | > |
            \*\*= | \*\* | \*= | \* |
            \+= | \+ |
            \.\. | \.= | \. |
            \/\/= | \/\/ |
            \/= | \/ |
            \? |
            \\ |
            \^= | \^\.= | \^\. | \^ |
            \b x= |
            \|\|= | \|\| | \|= | \|\.= | \|\. | \| |
            ~~ | ~\. | ~ |
            \b(?: and | cmp | eq | ge | gt | le | lt | ne | not | or | xor | x )\b |
            \b(?: print )\b |

            [,;\(\{\[]

            )) /oxgc) { $slash = 'm//'; $e_string .= $1; }

        # other any character
        elsif ($string =~ /\G ($q_char) /oxgc) { $e_string .= $1; }

        # system error
        else {
            die __FILE__, ": Oops, this shouldn't happen!\n";
        }
    }

    return $e_string;
}

#
# character class
#
sub character_class {
    my($char,$modifier) = @_;

    if ($char eq '.') {
        if ($modifier =~ /s/) {
            return '${Ekps9566::dot_s}';
        }
        else {
            return '${Ekps9566::dot}';
        }
    }
    else {
        return Ekps9566::classic_character_class($char);
    }
}

#
# escape capture ($1, $2, $3, ...)
#
sub e_capture {

    return join '', '${Ekps9566::capture(', $_[0], ')}';
    return join '', '${',                $_[0],  '}';
}

#
# escape transliteration (tr/// or y///)
#
sub e_tr {
    my($variable,$charclass,$e,$charclass2,$modifier) = @_;
    my $e_tr = '';
    $modifier ||= '';

    $slash = 'div';

    # quote character class 1
    $charclass  = q_tr($charclass);

    # quote character class 2
    $charclass2 = q_tr($charclass2);

    # /b /B modifier
    if ($modifier =~ tr/bB//d) {
        if ($variable eq '') {
            $e_tr = qq{tr$charclass$e$charclass2$modifier};
        }
        else {
            $e_tr = qq{$variable${bind_operator}tr$charclass$e$charclass2$modifier};
        }
    }
    else {
        if ($variable eq '') {
            $e_tr = qq{Ekps9566::tr(\$_,' =~ ',$charclass,$e$charclass2,'$modifier')};
        }
        else {
            $e_tr = qq{Ekps9566::tr($variable,'$bind_operator',$charclass,$e$charclass2,'$modifier')};
        }
    }

    # clear tr/// variable
    $tr_variable = '';
    $bind_operator = '';

    return $e_tr;
}

#
# quote for escape transliteration (tr/// or y///)
#
sub q_tr {
    my($charclass) = @_;

    # quote character class
    if ($charclass !~ /'/oxms) {
        return e_q('',  "'", "'", $charclass); # --> q' '
    }
    elsif ($charclass !~ /\//oxms) {
        return e_q('q',  '/', '/', $charclass); # --> q/ /
    }
    elsif ($charclass !~ /\#/oxms) {
        return e_q('q',  '#', '#', $charclass); # --> q# #
    }
    elsif ($charclass !~ /[\<\>]/oxms) {
        return e_q('q', '<', '>', $charclass); # --> q< >
    }
    elsif ($charclass !~ /[\(\)]/oxms) {
        return e_q('q', '(', ')', $charclass); # --> q( )
    }
    elsif ($charclass !~ /[\{\}]/oxms) {
        return e_q('q', '{', '}', $charclass); # --> q{ }
    }
    else {
        for my $char (qw( ! " $ % & * + . : = ? @ ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
            if ($charclass !~ /\Q$char\E/xms) {
                return e_q('q', $char, $char, $charclass);
            }
        }
    }

    return e_q('q', '{', '}', $charclass);
}

#
# escape q string (q//, '')
#
sub e_q {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    my @char = $string =~ / \G (?>$q_char) /oxmsg;
    for (my $i=0; $i <= $#char; $i++) {

        # escape last octet of multiple-octet
        if ($char[$i] =~ /\A ([\x80-\xFF].*) (\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }
        elsif (defined($char[$i+1]) and ($char[$i+1] eq '\\') and ($char[$i] =~ /\A ([\x80-\xFF].*) (\\) \z/xms)) {
            $char[$i] = $1 . '\\' . $2;
        }
    }
    if (defined($char[-1]) and ($char[-1] =~ /\A ([\x80-\xFF].*) (\\) \z/xms)) {
        $char[-1] = $1 . '\\' . $2;
    }

    return join '', $ope, $delimiter, @char,   $end_delimiter;
    return join '', $ope, $delimiter, $string, $end_delimiter;
}

#
# escape qq string (qq//, "", qx//, ``)
#
sub e_qq {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    my $left_e  = 0;
    my $right_e = 0;

    # split regexp
    my @char = $string =~ /\G((?>
        [^\x81-\xFE\\\$]|[\x81-\xFE][\x00-\xFF] |
        \\x\{ (?>[0-9A-Fa-f]+) \}            |
        \\o\{ (?>[0-7]+)       \}            |
        \\N\{ (?>[^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} |
        \\ $q_char                           |
        \$` | \$\{`\} | \$ (?>\s*) PREMATCH  | \$ (?>\s*) \{ (?>\s*) PREMATCH  (?>\s*) \} | \$ (?>\s*) \{\^PREMATCH\}  |
        \$& | \$\{&\} | \$ (?>\s*) MATCH     | \$ (?>\s*) \{ (?>\s*) MATCH     (?>\s*) \} | \$ (?>\s*) \{\^MATCH\}     |
                        \$ (?>\s*) POSTMATCH | \$ (?>\s*) \{ (?>\s*) POSTMATCH (?>\s*) \} | \$ (?>\s*) \{\^POSTMATCH\} |
        \$ (?>\s* [0-9]+)                    |
        \$ (?>\s*) \{ (?>\s* [0-9]+ \s*) \}  |
        \$ \$ (?![\w\{])                     |
        \$ (?>\s*) \$ (?>\s*) $qq_variable   |
           $q_char
    ))/oxmsg;

    for (my $i=0; $i <= $#char; $i++) {

        # "\L\u" --> "\u\L"
        if (($char[$i] eq '\L') and ($char[$i+1] eq '\u')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # "\U\l" --> "\l\U"
        elsif (($char[$i] eq '\U') and ($char[$i+1] eq '\l')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # octal escape sequence
        elsif ($char[$i] =~ /\A \\o \{ ([0-7]+) \} \z/oxms) {
            $char[$i] = Ekps9566::octchr($1);
        }

        # hexadecimal escape sequence
        elsif ($char[$i] =~ /\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            $char[$i] = Ekps9566::hexchr($1);
        }

        # \N{CHARNAME} --> N{CHARNAME}
        elsif ($char[$i] =~ /\A \\ ( N\{ ([^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} ) \z/oxms) {
            $char[$i] = $1;
        }

        if (0) {
        }

        # escape last octet of multiple-octet
        # my $metachar = qr/[\@\\\|]/oxms; # '|' is for qx//, ``, open(), and system()
        # variable $delimiter and $end_delimiter can be ''
        elsif ($char[$i] =~ /\A ([\x80-\xFF].*) ([\@\\\|$delimiter$end_delimiter]) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # \F
        #
        # P.69 Table 2-6. Translation escapes
        # in Chapter 2: Bits and Pieces
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.
        # (and so on)

        # \u \l \U \L \F \Q \E
        elsif ($char[$i] =~ /\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\u') {

            # "STRING @{[ LIST EXPR ]} MORE STRING"

            # P.257 Other Tricks You Can Do with Hard References
            # in Chapter 8: References
            # of ISBN 0-596-00027-8 Programming Perl Third Edition.

            # P.353 Other Tricks You Can Do with Hard References
            # in Chapter 8: References
            # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

            # (and so on)

            $char[$i] = '@{[Ekps9566::ucfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\l') {
            $char[$i] = '@{[Ekps9566::lcfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Ekps9566::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Ekps9566::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\F') {
            $char[$i] = '@{[Ekps9566::fc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
        elsif ($char[$i] eq '\Q') {
            while (1) {
                if (++$i > $#char) {
                    last;
                }
                if ($char[$i] eq '\E') {
                    last;
                }
            }
        }
        elsif ($char[$i] eq '\E') {
        }

        # $0 --> $0
        elsif ($char[$i] =~ /\A \$ 0 \z/oxms) {
        }
        elsif ($char[$i] =~ /\A \$ \{ (?>\s*) 0 (?>\s*) \} \z/oxms) {
        }

        # $$ --> $$
        elsif ($char[$i] =~ /\A \$\$ \z/oxms) {
        }

        # $1, $2, $3 --> $2, $3, $4 after s/// with multibyte anchoring
        # $1, $2, $3 --> $1, $2, $3 otherwise
        elsif ($char[$i] =~ /\A \$ ((?>[1-9][0-9]*)) \z/oxms) {
            $char[$i] = e_capture($1);
        }
        elsif ($char[$i] =~ /\A \$ \{ (?>\s*) ((?>[1-9][0-9]*)) (?>\s*) \} \z/oxms) {
            $char[$i] = e_capture($1);
        }

        # $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($char[$i] =~ /\A \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) ( \[ (?:$qq_bracket)*? \] ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
        }

        # $$foo{ ... } --> $ $foo->{ ... }
        elsif ($char[$i] =~ /\A \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) ( \{ (?:$qq_brace)*? \} ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
        }

        # $$foo
        elsif ($char[$i] =~ /\A \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) \z/oxms) {
            $char[$i] = e_capture($1);
        }

        # $`, ${`}, $PREMATCH, ${PREMATCH}, ${^PREMATCH} --> Ekps9566::PREMATCH()
        elsif ($char[$i] =~ /\A ( \$` | \$\{`\} | \$ (?>\s*) PREMATCH  | \$ (?>\s*) \{ (?>\s*) PREMATCH (?>\s*) \}  | \$ (?>\s*) \{\^PREMATCH\}  ) \z/oxmsgc) {
            $char[$i] = '@{[Ekps9566::PREMATCH()]}';
        }

        # $&, ${&}, $MATCH, ${MATCH}, ${^MATCH} --> Ekps9566::MATCH()
        elsif ($char[$i] =~ /\A ( \$& | \$\{&\} | \$ (?>\s*) MATCH     | \$ (?>\s*) \{ (?>\s*) MATCH     (?>\s*) \} | \$ (?>\s*) \{\^MATCH\}     ) \z/oxmsgc) {
            $char[$i] = '@{[Ekps9566::MATCH()]}';
        }

        # $POSTMATCH, ${POSTMATCH}, ${^POSTMATCH} --> Ekps9566::POSTMATCH()
        elsif ($char[$i] =~ /\A (                 \$ (?>\s*) POSTMATCH | \$ (?>\s*) \{ (?>\s*) POSTMATCH (?>\s*) \} | \$ (?>\s*) \{\^POSTMATCH\} ) \z/oxmsgc) {
            $char[$i] = '@{[Ekps9566::POSTMATCH()]}';
        }

        # ${ foo } --> ${ foo }
        elsif ($char[$i] =~ /\A \$ (?>\s*) \{ (?> \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* ) \}                                \z/oxms) {
        }

        # ${ ... }
        elsif ($char[$i] =~ /\A \$ (?>\s*) \{ ( .+ ) \} \z/oxms) {
            $char[$i] = e_capture($1);
        }
    }

    # return string
    if ($left_e > $right_e) {
        return join '', $ope, $delimiter, @char, '>]}' x ($left_e - $right_e), $end_delimiter;
    }
    return     join '', $ope, $delimiter, @char,                               $end_delimiter;
}

#
# escape qw string (qw//)
#
sub e_qw {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    # choice again delimiter
    my %octet = map {$_ => 1} ($string =~ /\G ([\x00-\xFF]) /oxmsg);
    if (not $octet{$end_delimiter}) {
        return join '', $ope, $delimiter, $string, $end_delimiter;
    }
    elsif (not $octet{')'}) {
        return join '', $ope, '(',        $string, ')';
    }
    elsif (not $octet{'}'}) {
        return join '', $ope, '{',        $string, '}';
    }
    elsif (not $octet{']'}) {
        return join '', $ope, '[',        $string, ']';
    }
    elsif (not $octet{'>'}) {
        return join '', $ope, '<',        $string, '>';
    }
    else {
        for my $char (qw( ! " $ % & * + - . / : = ? @ ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
            if (not $octet{$char}) {
                return join '', $ope,      $char, $string, $char;
            }
        }
    }

    # qw/AAA BBB C'CC/ --> ('AAA', 'BBB', 'C\'CC')
    my @string = CORE::split(/\s+/, $string);
    for my $string (@string) {
        my @octet = $string =~ /\G ([\x00-\xFF]) /oxmsg;
        for my $octet (@octet) {
            if ($octet =~ /\A (['\\]) \z/oxms) {
                $octet = '\\' . $1;
            }
        }
        $string = join '', @octet;
    }
    return join '', '(', (join ', ', map { "'$_'" } @string), ')';
}

#
# escape here document (<<"HEREDOC", <<HEREDOC, <<`HEREDOC`)
#
sub e_heredoc {
    my($string) = @_;

    $slash = 'm//';

    my $metachar = qr/[\@\\|]/oxms; # '|' is for <<`HEREDOC`

    my $left_e  = 0;
    my $right_e = 0;

    # split regexp
    my @char = $string =~ /\G((?>
        [^\x81-\xFE\\\$]|[\x81-\xFE][\x00-\xFF] |
        \\x\{ (?>[0-9A-Fa-f]+) \}            |
        \\o\{ (?>[0-7]+)       \}            |
        \\N\{ (?>[^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} |
        \\ $q_char                           |
        \$` | \$\{`\} | \$ (?>\s*) PREMATCH  | \$ (?>\s*) \{ (?>\s*) PREMATCH  (?>\s*) \} | \$ (?>\s*) \{\^PREMATCH\}  |
        \$& | \$\{&\} | \$ (?>\s*) MATCH     | \$ (?>\s*) \{ (?>\s*) MATCH     (?>\s*) \} | \$ (?>\s*) \{\^MATCH\}     |
                        \$ (?>\s*) POSTMATCH | \$ (?>\s*) \{ (?>\s*) POSTMATCH (?>\s*) \} | \$ (?>\s*) \{\^POSTMATCH\} |
        \$ (?>\s* [0-9]+)                    |
        \$ (?>\s*) \{ (?>\s* [0-9]+ \s*) \}  |
        \$ \$ (?![\w\{])                     |
        \$ (?>\s*) \$ (?>\s*) $qq_variable   |
           $q_char
    ))/oxmsg;

    for (my $i=0; $i <= $#char; $i++) {

        # "\L\u" --> "\u\L"
        if (($char[$i] eq '\L') and ($char[$i+1] eq '\u')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # "\U\l" --> "\l\U"
        elsif (($char[$i] eq '\U') and ($char[$i+1] eq '\l')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # octal escape sequence
        elsif ($char[$i] =~ /\A \\o \{ ([0-7]+) \} \z/oxms) {
            $char[$i] = Ekps9566::octchr($1);
        }

        # hexadecimal escape sequence
        elsif ($char[$i] =~ /\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            $char[$i] = Ekps9566::hexchr($1);
        }

        # \N{CHARNAME} --> N{CHARNAME}
        elsif ($char[$i] =~ /\A \\ ( N\{ ([^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} ) \z/oxms) {
            $char[$i] = $1;
        }

        if (0) {
        }

        # escape character
        elsif ($char[$i] =~ /\A ([\x80-\xFF].*) ($metachar) \z/oxms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # \u \l \U \L \F \Q \E
        elsif ($char[$i] =~ /\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\u') {
            $char[$i] = '@{[Ekps9566::ucfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\l') {
            $char[$i] = '@{[Ekps9566::lcfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Ekps9566::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Ekps9566::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\F') {
            $char[$i] = '@{[Ekps9566::fc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
        elsif ($char[$i] eq '\Q') {
            while (1) {
                if (++$i > $#char) {
                    last;
                }
                if ($char[$i] eq '\E') {
                    last;
                }
            }
        }
        elsif ($char[$i] eq '\E') {
        }

        # $0 --> $0
        elsif ($char[$i] =~ /\A \$ 0 \z/oxms) {
        }
        elsif ($char[$i] =~ /\A \$ \{ (?>\s*) 0 (?>\s*) \} \z/oxms) {
        }

        # $$ --> $$
        elsif ($char[$i] =~ /\A \$\$ \z/oxms) {
        }

        # $1, $2, $3 --> $2, $3, $4 after s/// with multibyte anchoring
        # $1, $2, $3 --> $1, $2, $3 otherwise
        elsif ($char[$i] =~ /\A \$ ((?>[1-9][0-9]*)) \z/oxms) {
            $char[$i] = e_capture($1);
        }
        elsif ($char[$i] =~ /\A \$ \{ (?>\s*) ((?>[1-9][0-9]*)) (?>\s*) \} \z/oxms) {
            $char[$i] = e_capture($1);
        }

        # $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($char[$i] =~ /\A \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) ( \[ (?:$qq_bracket)*? \] ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
        }

        # $$foo{ ... } --> $ $foo->{ ... }
        elsif ($char[$i] =~ /\A \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) ( \{ (?:$qq_brace)*? \} ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
        }

        # $$foo
        elsif ($char[$i] =~ /\A \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) \z/oxms) {
            $char[$i] = e_capture($1);
        }

        # $`, ${`}, $PREMATCH, ${PREMATCH}, ${^PREMATCH} --> Ekps9566::PREMATCH()
        elsif ($char[$i] =~ /\A ( \$` | \$\{`\} | \$ (?>\s*) PREMATCH  | \$ (?>\s*) \{ (?>\s*) PREMATCH  (?>\s*) \} | \$ (?>\s*) \{\^PREMATCH\}  ) \z/oxmsgc) {
            $char[$i] = '@{[Ekps9566::PREMATCH()]}';
        }

        # $&, ${&}, $MATCH, ${MATCH}, ${^MATCH} --> Ekps9566::MATCH()
        elsif ($char[$i] =~ /\A ( \$& | \$\{&\} | \$ (?>\s*) MATCH     | \$ (?>\s*) \{ (?>\s*) MATCH     (?>\s*) \} | \$ (?>\s*) \{\^MATCH\}     ) \z/oxmsgc) {
            $char[$i] = '@{[Ekps9566::MATCH()]}';
        }

        # $POSTMATCH, ${POSTMATCH}, ${^POSTMATCH} --> Ekps9566::POSTMATCH()
        elsif ($char[$i] =~ /\A (                 \$ (?>\s*) POSTMATCH | \$ (?>\s*) \{ (?>\s*) POSTMATCH (?>\s*) \} | \$ (?>\s*) \{\^POSTMATCH\} ) \z/oxmsgc) {
            $char[$i] = '@{[Ekps9566::POSTMATCH()]}';
        }

        # ${ foo } --> ${ foo }
        elsif ($char[$i] =~ /\A \$ (?>\s*) \{ (?> \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* ) \}                                \z/oxms) {
        }

        # ${ ... }
        elsif ($char[$i] =~ /\A \$ (?>\s*) \{ ( .+ ) \} \z/oxms) {
            $char[$i] = e_capture($1);
        }
    }

    # return string
    if ($left_e > $right_e) {
        return join '', @char, '>]}' x ($left_e - $right_e);
    }
    return     join '', @char;
}

#
# escape regexp (m//, qr//)
#
sub e_qr {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $modifier =~ tr/p//d;
    if ($modifier =~ /([adlu])/oxms) {
        my $line = 0;
        for (my $i=0; my($package,$filename,$use_line,$subroutine) = caller($i); $i++) {
            if ($filename ne __FILE__) {
                $line = $use_line + (CORE::substr($_,0,pos($_)) =~ tr/\n//) + 1;
                last;
            }
        }
        die qq{Unsupported modifier "$1" used at line $line.\n};
    }

    $slash = 'div';

    # literal null string pattern
    if ($string eq '') {
        $modifier =~ tr/bB//d;
        $modifier =~ tr/i//d;
        return join '', $ope, $delimiter, $end_delimiter, $modifier;
    }

    # /b /B modifier
    elsif ($modifier =~ tr/bB//d) {

        # choice again delimiter
        if ($delimiter =~ / [\@:] /oxms) {
            my @char = $string =~ /\G ([\x00-\xFF]) /oxmsg;
            my %octet = map {$_ => 1} @char;
            if (not $octet{')'}) {
                $delimiter     = '(';
                $end_delimiter = ')';
            }
            elsif (not $octet{'}'}) {
                $delimiter     = '{';
                $end_delimiter = '}';
            }
            elsif (not $octet{']'}) {
                $delimiter     = '[';
                $end_delimiter = ']';
            }
            elsif (not $octet{'>'}) {
                $delimiter     = '<';
                $end_delimiter = '>';
            }
            else {
                for my $char (qw( ! " $ % & * + - . / = ? ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
                    if (not $octet{$char}) {
                        $delimiter     = $char;
                        $end_delimiter = $char;
                        last;
                    }
                }
            }
        }

        if (($ope =~ /\A m? \z/oxms) and ($delimiter eq '?')) {
            return join '', $ope, $delimiter,        $string,      $matched, $end_delimiter, $modifier;
        }
        else {
            return join '', $ope, $delimiter, '(?:', $string, ')', $matched, $end_delimiter, $modifier;
        }
    }

    my $ignorecase = ($modifier =~ /i/oxms) ? 1 : 0;
    my $metachar = qr/[\@\\|[\]{^]/oxms;

    # split regexp
    my @char = $string =~ /\G((?>
        [^\x81-\xFE\\\$\@\[\(]|[\x81-\xFE][\x00-\xFF] |
        \\x   (?>[0-9A-Fa-f]{1,2}) |
        \\    (?>[0-7]{2,3})       |
        \\c   [\x40-\x5F]          |
        \\x\{ (?>[0-9A-Fa-f]+) \}  |
        \\o\{ (?>[0-7]+)       \}  |
        \\[bBNpP]\{ (?>[^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} |
        \\  $q_char                |
        \$` | \$\{`\} | \$ (?>\s*) PREMATCH  | \$ (?>\s*) \{ (?>\s*) PREMATCH  (?>\s*) \} | \$ (?>\s*) \{\^PREMATCH\}  |
        \$& | \$\{&\} | \$ (?>\s*) MATCH     | \$ (?>\s*) \{ (?>\s*) MATCH     (?>\s*) \} | \$ (?>\s*) \{\^MATCH\}     |
                        \$ (?>\s*) POSTMATCH | \$ (?>\s*) \{ (?>\s*) POSTMATCH (?>\s*) \} | \$ (?>\s*) \{\^POSTMATCH\} |
        [\$\@] $qq_variable        |
        \$ (?>\s* [0-9]+)          |
        \$ (?>\s*) \{ (?>\s* [0-9]+ \s*) \}  |
        \$ \$ (?![\w\{])           |
        \$ (?>\s*) \$ (?>\s*) $qq_variable   |
        \[\^                       |
        \[\:   (?>[a-z]+) :\]      |
        \[\:\^ (?>[a-z]+) :\]      |
        \(\?                       |
            $q_char
    ))/oxmsg;

    # choice again delimiter
    if ($delimiter =~ / [\@:] /oxms) {
        my %octet = map {$_ => 1} @char;
        if (not $octet{')'}) {
            $delimiter     = '(';
            $end_delimiter = ')';
        }
        elsif (not $octet{'}'}) {
            $delimiter     = '{';
            $end_delimiter = '}';
        }
        elsif (not $octet{']'}) {
            $delimiter     = '[';
            $end_delimiter = ']';
        }
        elsif (not $octet{'>'}) {
            $delimiter     = '<';
            $end_delimiter = '>';
        }
        else {
            for my $char (qw( ! " $ % & * + - . / = ? ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
                if (not $octet{$char}) {
                    $delimiter     = $char;
                    $end_delimiter = $char;
                    last;
                }
            }
        }
    }

    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {

        # "\L\u" --> "\u\L"
        if (($char[$i] eq '\L') and ($char[$i+1] eq '\u')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # "\U\l" --> "\l\U"
        elsif (($char[$i] eq '\U') and ($char[$i+1] eq '\l')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # octal escape sequence
        elsif ($char[$i] =~ /\A \\o \{ ([0-7]+) \} \z/oxms) {
            $char[$i] = Ekps9566::octchr($1);
        }

        # hexadecimal escape sequence
        elsif ($char[$i] =~ /\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            $char[$i] = Ekps9566::hexchr($1);
        }

        # \b{...}      --> b\{...}
        # \B{...}      --> B\{...}
        # \N{CHARNAME} --> N\{CHARNAME}
        # \p{PROPERTY} --> p\{PROPERTY}
        # \P{PROPERTY} --> P\{PROPERTY}
        elsif ($char[$i] =~ /\A \\ ([bBNpP]) ( \{ ([^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} ) \z/oxms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # \p, \P, \X --> p, P, X
        elsif ($char[$i] =~ /\A \\ ( [pPX] ) \z/oxms) {
            $char[$i] = $1;
        }

        if (0) {
        }

        # escape last octet of multiple-octet
        elsif ($char[$i] =~ /\A \\? ([\x80-\xFF].*) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # join separated multiple-octet
        elsif ($char[$i] =~ /\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms) {
            if (   ($i+3 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+3]) == 3) and (CORE::eval(sprintf '"%s%s%s%s"', @char[$i..$i+3]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 3;
            }
            elsif (($i+2 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+2]) == 2) and (CORE::eval(sprintf '"%s%s%s"',   @char[$i..$i+2]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 2;
            }
            elsif (($i+1 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, $char[$i+1      ]) == 1) and (CORE::eval(sprintf '"%s%s"',     @char[$i..$i+1]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 1;
            }
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;

            # [] make die "Unmatched [] in regexp ...\n"
            # (and so on)

            if ($char[$i+1] eq ']') {
                $i++;
            }

            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp\n";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    if (grep(/\A [\$\@]/oxms,@char[$left+1..$right-1]) >= 1) {
                        splice @char, $left, $right-$left+1, sprintf(q{@{[Ekps9566::charlist_qr(%s,'%s')]}}, join(',', map {qq_stuff($delimiter,$end_delimiter,$_)} @char[$left+1..$right-1]), $modifier);
                    }
                    else {
                        splice @char, $left, $right-$left+1, Ekps9566::charlist_qr(@char[$left+1..$right-1], $modifier);
                    }

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;

            # [^] make die "Unmatched [] in regexp ...\n"
            # (and so on)

            if ($char[$i+1] eq ']') {
                $i++;
            }

            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp\n";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    if (grep(/\A [\$\@]/oxms,@char[$left+1..$right-1]) >= 1) {
                        splice @char, $left, $right-$left+1, sprintf(q{@{[Ekps9566::charlist_not_qr(%s,'%s')]}}, join(',', map {qq_stuff($delimiter,$end_delimiter,$_)} @char[$left+1..$right-1]), $modifier);
                    }
                    else {
                        splice @char, $left, $right-$left+1, Ekps9566::charlist_not_qr(@char[$left+1..$right-1], $modifier);
                    }

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($ignorecase and ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) and (Ekps9566::uc($char[$i]) ne Ekps9566::fc($char[$i]))) {
            if (CORE::length(Ekps9566::fc($char[$i])) == 1) {
                $char[$i] = '['   . Ekps9566::uc($char[$i])       . Ekps9566::fc($char[$i]) . ']';
            }
            else {
                $char[$i] = '(?:' . Ekps9566::uc($char[$i]) . '|' . Ekps9566::fc($char[$i]) . ')';
            }
        }

        # \u \l \U \L \F \Q \E
        elsif ($char[$i] =~ /\A [<>] \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\u') {
            $char[$i] = '@{[Ekps9566::ucfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\l') {
            $char[$i] = '@{[Ekps9566::lcfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Ekps9566::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Ekps9566::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\F') {
            $char[$i] = '@{[Ekps9566::fc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
        elsif ($char[$i] eq '\Q') {
            while (1) {
                if (++$i > $#char) {
                    last;
                }
                if ($char[$i] eq '\E') {
                    last;
                }
            }
        }
        elsif ($char[$i] eq '\E') {
        }

        # $0 --> $0
        elsif ($char[$i] =~ /\A \$ 0 \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ /\A \$ \{ (?>\s*) 0 (?>\s*) \} \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$ --> $$
        elsif ($char[$i] =~ /\A \$\$ \z/oxms) {
        }

        # $1, $2, $3 --> $2, $3, $4 after s/// with multibyte anchoring
        # $1, $2, $3 --> $1, $2, $3 otherwise
        elsif ($char[$i] =~ /\A \$ ((?>[1-9][0-9]*)) \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ /\A \$ \{ (?>\s*) ((?>[1-9][0-9]*)) (?>\s*) \} \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($char[$i] =~ /\A \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) ( \[ (?:$qq_bracket)*? \] ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo{ ... } --> $ $foo->{ ... }
        elsif ($char[$i] =~ /\A \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) ( \{ (?:$qq_brace)*? \} ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo
        elsif ($char[$i] =~ /\A \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $`, ${`}, $PREMATCH, ${PREMATCH}, ${^PREMATCH} --> Ekps9566::PREMATCH()
        elsif ($char[$i] =~ /\A ( \$` | \$\{`\} | \$ (?>\s*) PREMATCH  | \$ (?>\s*) \{ (?>\s*) PREMATCH  (?>\s*) \} | \$ (?>\s*) \{\^PREMATCH\}  ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(Ekps9566::PREMATCH())]}';
            }
            else {
                $char[$i] = '@{[Ekps9566::PREMATCH()]}';
            }
        }

        # $&, ${&}, $MATCH, ${MATCH}, ${^MATCH} --> Ekps9566::MATCH()
        elsif ($char[$i] =~ /\A ( \$& | \$\{&\} | \$ (?>\s*) MATCH     | \$ (?>\s*) \{ (?>\s*) MATCH     (?>\s*) \} | \$ (?>\s*) \{\^MATCH\}     ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(Ekps9566::MATCH())]}';
            }
            else {
                $char[$i] = '@{[Ekps9566::MATCH()]}';
            }
        }

        # $POSTMATCH, ${POSTMATCH}, ${^POSTMATCH} --> Ekps9566::POSTMATCH()
        elsif ($char[$i] =~ /\A (                 \$ (?>\s*) POSTMATCH | \$ (?>\s*) \{ (?>\s*) POSTMATCH (?>\s*) \} | \$ (?>\s*) \{\^POSTMATCH\} ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(Ekps9566::POSTMATCH())]}';
            }
            else {
                $char[$i] = '@{[Ekps9566::POSTMATCH()]}';
            }
        }

        # ${ foo }
        elsif ($char[$i] =~ /\A \$ (?>\s*) \{ ((?> \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* )) \}                              \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # ${ ... }
        elsif ($char[$i] =~ /\A \$ (?>\s*) \{ ( .+ ) \} \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ /\A [\$\@].+ /oxms) {
            $char[$i] = e_string($char[$i]);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ /\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] =~ /\A (?:[\x00-\xFF]|\\[0-7]{2,3}|\\x[0-9-A-Fa-f]{1,2}) \z/oxms) {
            }
            elsif (($ope =~ /\A m? \z/oxms) and ($delimiter eq '?')) {
                my $char = $char[$i-1];
                if ($char[$i] eq '{') {
                    die __FILE__, qq{: "MULTIBYTE{n}" should be "(MULTIBYTE){n}" in m?? (and shift \$1,\$2,\$3,...) ($char){n}\n};
                }
                else {
                    die __FILE__, qq{: "MULTIBYTE$char[$i]" should be "(MULTIBYTE)$char[$i]" in m?? (and shift \$1,\$2,\$3,...) ($char)$char[$i]\n};
                }
            }
            else {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    # make regexp string
    $modifier =~ tr/i//d;
    if ($left_e > $right_e) {
        if (($ope =~ /\A m? \z/oxms) and ($delimiter eq '?')) {
            return join '', $ope, $delimiter, $anchor,        @char, '>]}' x ($left_e - $right_e),      $matched, $end_delimiter, $modifier;
        }
        else {
            return join '', $ope, $delimiter, $anchor, '(?:', @char, '>]}' x ($left_e - $right_e), ')', $matched, $end_delimiter, $modifier;
        }
    }
    if (($ope =~ /\A m? \z/oxms) and ($delimiter eq '?')) {
        return     join '', $ope, $delimiter, $anchor,        @char,                                    $matched, $end_delimiter, $modifier;
    }
    else {
        return     join '', $ope, $delimiter, $anchor, '(?:', @char,                               ')', $matched, $end_delimiter, $modifier;
    }
}

#
# double quote stuff
#
sub qq_stuff {
    my($delimiter,$end_delimiter,$stuff) = @_;

    # scalar variable or array variable
    if ($stuff =~ /\A [\$\@] /oxms) {
        return $stuff;
    }

    # quote by delimiter
    my %octet = map {$_ => 1} ($stuff =~ /\G ([\x00-\xFF]) /oxmsg);
    for my $char (qw( ! " $ % & * + - . / : = ? @ ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
        next if $char eq $delimiter;
        next if $char eq $end_delimiter;
        if (not $octet{$char}) {
            return join '', 'qq', $char, $stuff, $char;
        }
    }
    return join '', 'qq', '<', $stuff, '>';
}

#
# escape regexp (m'', qr'', and m''b, qr''b)
#
sub e_qr_q {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $modifier =~ tr/p//d;
    if ($modifier =~ /([adlu])/oxms) {
        my $line = 0;
        for (my $i=0; my($package,$filename,$use_line,$subroutine) = caller($i); $i++) {
            if ($filename ne __FILE__) {
                $line = $use_line + (CORE::substr($_,0,pos($_)) =~ tr/\n//) + 1;
                last;
            }
        }
        die qq{Unsupported modifier "$1" used at line $line.\n};
    }

    $slash = 'div';

    # literal null string pattern
    if ($string eq '') {
        $modifier =~ tr/bB//d;
        $modifier =~ tr/i//d;
        return join '', $ope, $delimiter, $end_delimiter, $modifier;
    }

    # with /b /B modifier
    elsif ($modifier =~ tr/bB//d) {
        return e_qr_qb($ope,$delimiter,$end_delimiter,$string,$modifier);
    }

    # without /b /B modifier
    else {
        return e_qr_qt($ope,$delimiter,$end_delimiter,$string,$modifier);
    }
}

#
# escape regexp (m'', qr'')
#
sub e_qr_qt {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;

    my $ignorecase = ($modifier =~ /i/oxms) ? 1 : 0;

    # split regexp
    my @char = $string =~ /\G((?>
        [^\x81-\xFE\\\[\$\@\/] |
        [\x81-\xFE][\x00-\xFF] |
        \[\^                            |
        \[\:   (?>[a-z]+) \:\]          |
        \[\:\^ (?>[a-z]+) \:\]          |
        [\$\@\/]                        |
        \\     (?:$q_char)              |
               (?:$q_char)
    ))/oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape last octet of multiple-octet
        elsif ($char[$i] =~ /\A ([\x80-\xFF].*) ([\\|\[\{\^]|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp\n";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, Ekps9566::charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp\n";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, Ekps9566::charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # escape $ @ / and \
        elsif ($char[$i] =~ /\A [\$\@\/\\] \z/oxms) {
            $char[$i] = '\\' . $char[$i];
        }

        # rewrite character class or escape character
        elsif (my $char = character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($ignorecase and ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) and (Ekps9566::uc($char[$i]) ne Ekps9566::fc($char[$i]))) {
            if (CORE::length(Ekps9566::fc($char[$i])) == 1) {
                $char[$i] = '['   . Ekps9566::uc($char[$i])       . Ekps9566::fc($char[$i]) . ']';
            }
            else {
                $char[$i] = '(?:' . Ekps9566::uc($char[$i]) . '|' . Ekps9566::fc($char[$i]) . ')';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ /\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] =~ /\A [\x00-\xFF] \z/oxms) {
            }
            else {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    $delimiter     = '/';
    $end_delimiter = '/';

    $modifier =~ tr/i//d;
    return join '', $ope, $delimiter, $anchor, '(?:', @char, ')', $matched, $end_delimiter, $modifier;
}

#
# escape regexp (m''b, qr''b)
#
sub e_qr_qb {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;

    # split regexp
    my @char = $string =~ /\G ((?>[^\\]|\\\\|[\x00-\xFF])) /oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # remain \\
        elsif ($char[$i] eq '\\\\') {
        }

        # escape $ @ / and \
        elsif ($char[$i] =~ /\A [\$\@\/\\] \z/oxms) {
            $char[$i] = '\\' . $char[$i];
        }
    }

    $delimiter     = '/';
    $end_delimiter = '/';
    return join '', $ope, $delimiter, '(?:', @char, ')', $matched, $end_delimiter, $modifier;
}

#
# escape regexp (s/here//)
#
sub e_s1 {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $modifier =~ tr/p//d;
    if ($modifier =~ /([adlu])/oxms) {
        my $line = 0;
        for (my $i=0; my($package,$filename,$use_line,$subroutine) = caller($i); $i++) {
            if ($filename ne __FILE__) {
                $line = $use_line + (CORE::substr($_,0,pos($_)) =~ tr/\n//) + 1;
                last;
            }
        }
        die qq{Unsupported modifier "$1" used at line $line.\n};
    }

    $slash = 'div';

    # literal null string pattern
    if ($string eq '') {
        $modifier =~ tr/bB//d;
        $modifier =~ tr/i//d;
        return join '', $ope, $delimiter, $end_delimiter, $modifier;
    }

    # /b /B modifier
    elsif ($modifier =~ tr/bB//d) {

        # choice again delimiter
        if ($delimiter =~ / [\@:] /oxms) {
            my @char = $string =~ /\G ([\x00-\xFF]) /oxmsg;
            my %octet = map {$_ => 1} @char;
            if (not $octet{')'}) {
                $delimiter     = '(';
                $end_delimiter = ')';
            }
            elsif (not $octet{'}'}) {
                $delimiter     = '{';
                $end_delimiter = '}';
            }
            elsif (not $octet{']'}) {
                $delimiter     = '[';
                $end_delimiter = ']';
            }
            elsif (not $octet{'>'}) {
                $delimiter     = '<';
                $end_delimiter = '>';
            }
            else {
                for my $char (qw( ! " $ % & * + - . / = ? ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
                    if (not $octet{$char}) {
                        $delimiter     = $char;
                        $end_delimiter = $char;
                        last;
                    }
                }
            }
        }

        my $prematch = '';
        $prematch = q{(\G[\x00-\xFF]*?)};
        return join '', $ope, $delimiter, $prematch, '(?:', $string, ')', $matched, $end_delimiter, $modifier;
    }

    my $ignorecase = ($modifier =~ /i/oxms) ? 1 : 0;
    my $metachar = qr/[\@\\|[\]{^]/oxms;

    # split regexp
    my @char = $string =~ /\G((?>
        [^\x81-\xFE\\\$\@\[\(]|[\x81-\xFE][\x00-\xFF] |
        \\                               (?>[1-9][0-9]*)            |
        \\g (?>\s*)                      (?>[1-9][0-9]*)            |
        \\g (?>\s*) \{ (?>\s*)           (?>[1-9][0-9]*) (?>\s*) \} |
        \\g (?>\s*) \{ (?>\s*) - (?>\s*) (?>[1-9][0-9]*) (?>\s*) \} |
        \\x                              (?>[0-9A-Fa-f]{1,2})       |
        \\                               (?>[0-7]{2,3})             |
        \\c                              [\x40-\x5F]                |
        \\x\{                            (?>[0-9A-Fa-f]+)        \} |
        \\o\{                            (?>[0-7]+)              \} |
        \\[bBNpP]\{                      (?>[^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} |
        \\ $q_char                           |
        \$` | \$\{`\} | \$ (?>\s*) PREMATCH  | \$ (?>\s*) \{ (?>\s*) PREMATCH  (?>\s*) \} | \$ (?>\s*) \{\^PREMATCH\}  |
        \$& | \$\{&\} | \$ (?>\s*) MATCH     | \$ (?>\s*) \{ (?>\s*) MATCH     (?>\s*) \} | \$ (?>\s*) \{\^MATCH\}     |
                        \$ (?>\s*) POSTMATCH | \$ (?>\s*) \{ (?>\s*) POSTMATCH (?>\s*) \} | \$ (?>\s*) \{\^POSTMATCH\} |
        [\$\@] $qq_variable                  |
        \$ (?>\s* [0-9]+)                    |
        \$ (?>\s*) \{ (?>\s* [0-9]+ \s*) \}  |
        \$ \$ (?![\w\{])                     |
        \$ (?>\s*) \$ (?>\s*) $qq_variable   |
        \[\^                                 |
        \[\:   (?>[a-z]+) :\]                |
        \[\:\^ (?>[a-z]+) :\]                |
        \(\?                                 |
            $q_char
    ))/oxmsg;

    # choice again delimiter
    if ($delimiter =~ / [\@:] /oxms) {
        my %octet = map {$_ => 1} @char;
        if (not $octet{')'}) {
            $delimiter     = '(';
            $end_delimiter = ')';
        }
        elsif (not $octet{'}'}) {
            $delimiter     = '{';
            $end_delimiter = '}';
        }
        elsif (not $octet{']'}) {
            $delimiter     = '[';
            $end_delimiter = ']';
        }
        elsif (not $octet{'>'}) {
            $delimiter     = '<';
            $end_delimiter = '>';
        }
        else {
            for my $char (qw( ! " $ % & * + - . / = ? ^ ` | ~ ), "\x00".."\x1F", "\x7F", "\xFF") {
                if (not $octet{$char}) {
                    $delimiter     = $char;
                    $end_delimiter = $char;
                    last;
                }
            }
        }
    }

    # count '('
    my $parens = grep { $_ eq '(' } @char;

    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {

        # "\L\u" --> "\u\L"
        if (($char[$i] eq '\L') and ($char[$i+1] eq '\u')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # "\U\l" --> "\l\U"
        elsif (($char[$i] eq '\U') and ($char[$i+1] eq '\l')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # octal escape sequence
        elsif ($char[$i] =~ /\A \\o \{ ([0-7]+) \} \z/oxms) {
            $char[$i] = Ekps9566::octchr($1);
        }

        # hexadecimal escape sequence
        elsif ($char[$i] =~ /\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            $char[$i] = Ekps9566::hexchr($1);
        }

        # \b{...}      --> b\{...}
        # \B{...}      --> B\{...}
        # \N{CHARNAME} --> N\{CHARNAME}
        # \p{PROPERTY} --> p\{PROPERTY}
        # \P{PROPERTY} --> P\{PROPERTY}
        elsif ($char[$i] =~ /\A \\ ([bBNpP]) ( \{ ([^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} ) \z/oxms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # \p, \P, \X --> p, P, X
        elsif ($char[$i] =~ /\A \\ ( [pPX] ) \z/oxms) {
            $char[$i] = $1;
        }

        if (0) {
        }

        # escape last octet of multiple-octet
        elsif ($char[$i] =~ /\A \\? ([\x80-\xFF].*) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # join separated multiple-octet
        elsif ($char[$i] =~ /\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms) {
            if (   ($i+3 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+3]) == 3) and (CORE::eval(sprintf '"%s%s%s%s"', @char[$i..$i+3]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 3;
            }
            elsif (($i+2 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+2]) == 2) and (CORE::eval(sprintf '"%s%s%s"',   @char[$i..$i+2]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 2;
            }
            elsif (($i+1 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, $char[$i+1      ]) == 1) and (CORE::eval(sprintf '"%s%s"',     @char[$i..$i+1]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 1;
            }
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp\n";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    if (grep(/\A [\$\@]/oxms,@char[$left+1..$right-1]) >= 1) {
                        splice @char, $left, $right-$left+1, sprintf(q{@{[Ekps9566::charlist_qr(%s,'%s')]}}, join(',', map {qq_stuff($delimiter,$end_delimiter,$_)} @char[$left+1..$right-1]), $modifier);
                    }
                    else {
                        splice @char, $left, $right-$left+1, Ekps9566::charlist_qr(@char[$left+1..$right-1], $modifier);
                    }

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp\n";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    if (grep(/\A [\$\@]/oxms,@char[$left+1..$right-1]) >= 1) {
                        splice @char, $left, $right-$left+1, sprintf(q{@{[Ekps9566::charlist_not_qr(%s,'%s')]}}, join(',', map {qq_stuff($delimiter,$end_delimiter,$_)} @char[$left+1..$right-1]), $modifier);
                    }
                    else {
                        splice @char, $left, $right-$left+1, Ekps9566::charlist_not_qr(@char[$left+1..$right-1], $modifier);
                    }

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($ignorecase and ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) and (Ekps9566::uc($char[$i]) ne Ekps9566::fc($char[$i]))) {
            if (CORE::length(Ekps9566::fc($char[$i])) == 1) {
                $char[$i] = '['   . Ekps9566::uc($char[$i])       . Ekps9566::fc($char[$i]) . ']';
            }
            else {
                $char[$i] = '(?:' . Ekps9566::uc($char[$i]) . '|' . Ekps9566::fc($char[$i]) . ')';
            }
        }

        # \u \l \U \L \F \Q \E
        elsif ($char[$i] =~ /\A [<>] \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\u') {
            $char[$i] = '@{[Ekps9566::ucfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\l') {
            $char[$i] = '@{[Ekps9566::lcfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Ekps9566::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Ekps9566::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\F') {
            $char[$i] = '@{[Ekps9566::fc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
        elsif ($char[$i] eq '\Q') {
            while (1) {
                if (++$i > $#char) {
                    last;
                }
                if ($char[$i] eq '\E') {
                    last;
                }
            }
        }
        elsif ($char[$i] eq '\E') {
        }

        # \0 --> \0
        elsif ($char[$i] =~ /\A \\ (?>\s*) 0 \z/oxms) {
        }

        # \g{N}, \g{-N}

        # P.108 Using Simple Patterns
        # in Chapter 7: In the World of Regular Expressions
        # of ISBN 978-0-596-52010-6 Learning Perl, Fifth Edition

        # P.221 Capturing
        # in Chapter 5: Pattern Matching
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        # \g{-1}, \g{-2}, \g{-3} --> \g{-1}, \g{-2}, \g{-3}
        elsif ($char[$i] =~ /\A \\g (?>\s*) \{ (?>\s*) - (?>\s*) ((?>[1-9][0-9]*)) (?>\s*) \} \z/oxms) {
        }

        # \g{1}, \g{2}, \g{3} --> \g{2}, \g{3}, \g{4} (only when multibyte anchoring is enable)
        elsif ($char[$i] =~ /\A \\g (?>\s*) \{ (?>\s*) ((?>[1-9][0-9]*)) (?>\s*) \} \z/oxms) {
            if ($1 <= $parens) {
                $char[$i] = '\\g{' . ($1 + 1) . '}';
            }
        }

        # \g1, \g2, \g3 --> \g2, \g3, \g4 (only when multibyte anchoring is enable)
        elsif ($char[$i] =~ /\A \\g (?>\s*) ((?>[1-9][0-9]*)) \z/oxms) {
            if ($1 <= $parens) {
                $char[$i] = '\\g' . ($1 + 1);
            }
        }

        # \1, \2, \3 --> \2, \3, \4 (only when multibyte anchoring is enable)
        elsif ($char[$i] =~ /\A \\ (?>\s*) ((?>[1-9][0-9]*)) \z/oxms) {
            if ($1 <= $parens) {
                $char[$i] = '\\' . ($1 + 1);
            }
        }

        # $0 --> $0
        elsif ($char[$i] =~ /\A \$ 0 \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ /\A \$ \{ (?>\s*) 0 (?>\s*) \} \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$ --> $$
        elsif ($char[$i] =~ /\A \$\$ \z/oxms) {
        }

        # $1, $2, $3 --> $2, $3, $4 after s/// with multibyte anchoring
        # $1, $2, $3 --> $1, $2, $3 otherwise
        elsif ($char[$i] =~ /\A \$ ((?>[1-9][0-9]*)) \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ /\A \$ \{ (?>\s*) ((?>[1-9][0-9]*)) (?>\s*) \} \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($char[$i] =~ /\A \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) ( \[ (?:$qq_bracket)*? \] ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo{ ... } --> $ $foo->{ ... }
        elsif ($char[$i] =~ /\A \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) ( \{ (?:$qq_brace)*? \} ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo
        elsif ($char[$i] =~ /\A \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $`, ${`}, $PREMATCH, ${PREMATCH}, ${^PREMATCH} --> Ekps9566::PREMATCH()
        elsif ($char[$i] =~ /\A ( \$` | \$\{`\} | \$ (?>\s*) PREMATCH  | \$ (?>\s*) \{ (?>\s*) PREMATCH  (?>\s*) \} | \$ (?>\s*) \{\^PREMATCH\}  ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(Ekps9566::PREMATCH())]}';
            }
            else {
                $char[$i] = '@{[Ekps9566::PREMATCH()]}';
            }
        }

        # $&, ${&}, $MATCH, ${MATCH}, ${^MATCH} --> Ekps9566::MATCH()
        elsif ($char[$i] =~ /\A ( \$& | \$\{&\} | \$ (?>\s*) MATCH     | \$ (?>\s*) \{ (?>\s*) MATCH     (?>\s*) \} | \$ (?>\s*) \{\^MATCH\}     ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(Ekps9566::MATCH())]}';
            }
            else {
                $char[$i] = '@{[Ekps9566::MATCH()]}';
            }
        }

        # $POSTMATCH, ${POSTMATCH}, ${^POSTMATCH} --> Ekps9566::POSTMATCH()
        elsif ($char[$i] =~ /\A (                 \$ (?>\s*) POSTMATCH | \$ (?>\s*) \{ (?>\s*) POSTMATCH (?>\s*) \} | \$ (?>\s*) \{\^POSTMATCH\} ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(Ekps9566::POSTMATCH())]}';
            }
            else {
                $char[$i] = '@{[Ekps9566::POSTMATCH()]}';
            }
        }

        # ${ foo }
        elsif ($char[$i] =~ /\A \$ (?>\s*) \{ ((?> \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* )) \}                              \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # ${ ... }
        elsif ($char[$i] =~ /\A \$ (?>\s*) \{ ( .+ ) \} \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ /\A [\$\@].+ /oxms) {
            $char[$i] = e_string($char[$i]);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ /\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] =~ /\A (?:[\x00-\xFF]|\\[0-7]{2,3}|\\x[0-9-A-Fa-f]{1,2}) \z/oxms) {
            }
            else {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    # make regexp string
    my $prematch = '';
    if ($] >= 5.010) {
        $prematch = "(?<_PREMATCH>$anchor)";
    }
    else {
        $prematch =             "($anchor)";
    }
    $modifier =~ tr/i//d;
    if ($left_e > $right_e) {
        return join '', $ope, $delimiter, $prematch, '(?:', @char, '>]}' x ($left_e - $right_e), ')', $matched, $end_delimiter, $modifier;
    }
    return     join '', $ope, $delimiter, $prematch, '(?:', @char,                               ')', $matched, $end_delimiter, $modifier;
}

#
# escape regexp (s'here'' or s'here''b)
#
sub e_s1_q {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $modifier =~ tr/p//d;
    if ($modifier =~ /([adlu])/oxms) {
        my $line = 0;
        for (my $i=0; my($package,$filename,$use_line,$subroutine) = caller($i); $i++) {
            if ($filename ne __FILE__) {
                $line = $use_line + (CORE::substr($_,0,pos($_)) =~ tr/\n//) + 1;
                last;
            }
        }
        die qq{Unsupported modifier "$1" used at line $line.\n};
    }

    $slash = 'div';

    # literal null string pattern
    if ($string eq '') {
        $modifier =~ tr/bB//d;
        $modifier =~ tr/i//d;
        return join '', $ope, $delimiter, $end_delimiter, $modifier;
    }

    # with /b /B modifier
    elsif ($modifier =~ tr/bB//d) {
        return e_s1_qb($ope,$delimiter,$end_delimiter,$string,$modifier);
    }

    # without /b /B modifier
    else {
        return e_s1_qt($ope,$delimiter,$end_delimiter,$string,$modifier);
    }
}

#
# escape regexp (s'here'')
#
sub e_s1_qt {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;

    my $ignorecase = ($modifier =~ /i/oxms) ? 1 : 0;

    # split regexp
    my @char = $string =~ /\G((?>
        [^\x81-\xFE\\\[\$\@\/] |
        [\x81-\xFE][\x00-\xFF] |
        \[\^                            |
        \[\:   (?>[a-z]+) \:\]          |
        \[\:\^ (?>[a-z]+) \:\]          |
        [\$\@\/]                        |
        \\     (?:$q_char)              |
               (?:$q_char)
    ))/oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape last octet of multiple-octet
        elsif ($char[$i] =~ /\A ([\x80-\xFF].*) ([\\|\[\{\^]|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp\n";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, Ekps9566::charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp\n";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, Ekps9566::charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # escape $ @ / and \
        elsif ($char[$i] =~ /\A [\$\@\/\\] \z/oxms) {
            $char[$i] = '\\' . $char[$i];
        }

        # rewrite character class or escape character
        elsif (my $char = character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($ignorecase and ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) and (Ekps9566::uc($char[$i]) ne Ekps9566::fc($char[$i]))) {
            if (CORE::length(Ekps9566::fc($char[$i])) == 1) {
                $char[$i] = '['   . Ekps9566::uc($char[$i])       . Ekps9566::fc($char[$i]) . ']';
            }
            else {
                $char[$i] = '(?:' . Ekps9566::uc($char[$i]) . '|' . Ekps9566::fc($char[$i]) . ')';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ /\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] =~ /\A [\x00-\xFF] \z/oxms) {
            }
            else {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    $modifier =~ tr/i//d;
    $delimiter     = '/';
    $end_delimiter = '/';
    my $prematch = '';
    if ($] >= 5.010) {
        $prematch = "(?<_PREMATCH>$anchor)";
    }
    else {
        $prematch =             "($anchor)";
    }
    return join '', $ope, $delimiter, $prematch, '(?:', @char, ')', $matched, $end_delimiter, $modifier;
}

#
# escape regexp (s'here''b)
#
sub e_s1_qb {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;

    # split regexp
    my @char = $string =~ /\G (?>[^\\]|\\\\|[\x00-\xFF]) /oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # remain \\
        elsif ($char[$i] eq '\\\\') {
        }

        # escape $ @ / and \
        elsif ($char[$i] =~ /\A [\$\@\/\\] \z/oxms) {
            $char[$i] = '\\' . $char[$i];
        }
    }

    $delimiter     = '/';
    $end_delimiter = '/';
    my $prematch = '';
    $prematch = q{(\G[\x00-\xFF]*?)};
    return join '', $ope, $delimiter, $prematch, '(?:', @char, ')', $matched, $end_delimiter, $modifier;
}

#
# escape regexp (s''here')
#
sub e_s2_q {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    my @char = $string =~ / \G (?>[^\x81-\xFE\\]|\\\\|$q_char) /oxmsg;
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape last octet of multiple-octet
        elsif ($char[$i] =~ /\A ([\x80-\xFF].*) (\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }
        elsif (defined($char[$i+1]) and ($char[$i+1] eq '\\') and ($char[$i] =~ /\A ([\x80-\xFF].*) (\\) \z/xms)) {
            $char[$i] = $1 . '\\' . $2;
        }

        # not escape \\
        elsif ($char[$i] =~ /\A \\\\ \z/oxms) {
        }

        # escape $ @ / and \
        elsif ($char[$i] =~ /\A [\$\@\/\\] \z/oxms) {
            $char[$i] = '\\' . $char[$i];
        }
    }
    if (defined($char[-1]) and ($char[-1] =~ /\A ([\x80-\xFF].*) (\\) \z/xms)) {
        $char[-1] = $1 . '\\' . $2;
    }

    return join '', $ope, $delimiter, @char,   $end_delimiter;
}

#
# escape regexp (s/here/and here/modifier)
#
sub e_sub {
    my($variable,$delimiter1,$pattern,$end_delimiter1,$delimiter2,$replacement,$end_delimiter2,$modifier) = @_;
    $modifier ||= '';

    $modifier =~ tr/p//d;
    if ($modifier =~ /([adlu])/oxms) {
        my $line = 0;
        for (my $i=0; my($package,$filename,$use_line,$subroutine) = caller($i); $i++) {
            if ($filename ne __FILE__) {
                $line = $use_line + (CORE::substr($_,0,pos($_)) =~ tr/\n//) + 1;
                last;
            }
        }
        die qq{Unsupported modifier "$1" used at line $line.\n};
    }

    if ($variable eq '') {
        $variable      = '$_';
        $bind_operator = ' =~ ';
    }

    $slash = 'div';

    # P.128 Start of match (or end of previous match): \G
    # P.130 Advanced Use of \G with Perl
    # in Chapter 3: Overview of Regular Expression Features and Flavors
    # P.312 Iterative Matching: Scalar Context, with /g
    # in Chapter 7: Perl
    # of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

    # P.181 Where You Left Off: The \G Assertion
    # in Chapter 5: Pattern Matching
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    # P.220 Where You Left Off: The \G Assertion
    # in Chapter 5: Pattern Matching
    # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

    my $e_modifier = $modifier =~ tr/e//d;
    my $r_modifier = $modifier =~ tr/r//d;

    my $my = '';
    if ($variable =~ s/\A \( (?>\s*) ( (?>(?: local \b | my \b | our \b | state \b )?) .+ ) \) \z/$1/oxms) {
        $my = $variable;
        $variable =~ s/ (?: local \b | my \b | our \b | state \b ) (?>\s*) //oxms;
        $variable =~ s/ = .+ \z//oxms;
    }

    (my $variable_basename = $variable) =~ s/ [\[\{].* \z//oxms;
    $variable_basename =~ s/ \s+ \z//oxms;

    # quote replacement string
    my $e_replacement = '';
    if ($e_modifier >= 1) {
        $e_replacement = e_qq('', '', '', $replacement);
        $e_modifier--;
    }
    else {
        if ($delimiter2 eq "'") {
            $e_replacement = e_s2_q('qq', '/',         '/',             $replacement);
        }
        else {
            $e_replacement = e_qq  ('qq', $delimiter2, $end_delimiter2, $replacement);
        }
    }

    my $sub = '';

    # with /r
    if ($r_modifier) {
        if (0) {
        }

        # s///gr with multibyte anchoring
        elsif ($modifier =~ /g/oxms) {
            $sub = sprintf(
                #                              1                                              2   3                                 4   5
                q<CORE::eval{local $KPS9566::re_t=%s; local $KPS9566::re_a=''; while($KPS9566::re_t =~ %s){%s local $^W=0; local $KPS9566::re_r=%s; %s$KPS9566::re_t="$KPS9566::re_a${1}$KPS9566::re_r$'"; pos($KPS9566::re_t)=length "$KPS9566::re_a${1}$KPS9566::re_r"; $KPS9566::re_a=substr($KPS9566::re_t,0,pos($KPS9566::re_t)); } return $KPS9566::re_t}>,

                $variable,                                                       #  1
                ($delimiter1 eq "'") ?                                           #  2
                e_s1_q('m', $delimiter1, $end_delimiter1, $pattern, $modifier) : #  :
                e_s1  ('m', $delimiter1, $end_delimiter1, $pattern, $modifier),  #  :
                $s_matched,                                                      #  3
                $e_replacement,                                                  #  4
                '$KPS9566::re_r=CORE::eval $KPS9566::re_r; ' x $e_modifier,            #  5
            );
        }

        # s///gr without multibyte anchoring
        elsif ($modifier =~ /g/oxms) {
            $sub = sprintf(
                #                              1                        2   3                                 4   5
                q<CORE::eval{local $KPS9566::re_t=%s; while($KPS9566::re_t =~ %s){%s local $^W=0; local $KPS9566::re_r=%s; %s$KPS9566::re_t="$`$KPS9566::re_r$'"; pos($KPS9566::re_t)=length "$`$KPS9566::re_r"; } return $KPS9566::re_t}>,

                $variable,                                                       #  1
                ($delimiter1 eq "'") ?                                           #  2
                e_s1_q('m', $delimiter1, $end_delimiter1, $pattern, $modifier) : #  :
                e_s1  ('m', $delimiter1, $end_delimiter1, $pattern, $modifier),  #  :
                $s_matched,                                                      #  3
                $e_replacement,                                                  #  4
                '$KPS9566::re_r=CORE::eval $KPS9566::re_r; ' x $e_modifier,            #  5
            );
        }

        # s///r
        else {

            my $prematch = q{$`};
            if ($] >= 5.010) {
                $prematch = q{$+{_PREMATCH}};
            }
            else {
                $prematch = q{${1}};
            }

            $sub = sprintf(
                #  1     2                3                                 4   5  6                    7
                q<(%s =~ %s) ? CORE::eval{%s local $^W=0; local $KPS9566::re_r=%s; %s"%s$KPS9566::re_r$'" } : %s>,

                $variable,                                                       #  1
                ($delimiter1 eq "'") ?                                           #  2
                e_s1_q('m', $delimiter1, $end_delimiter1, $pattern, $modifier) : #  :
                e_s1  ('m', $delimiter1, $end_delimiter1, $pattern, $modifier),  #  :
                $s_matched,                                                      #  3
                $e_replacement,                                                  #  4
                '$KPS9566::re_r=CORE::eval $KPS9566::re_r; ' x $e_modifier,            #  5
                $prematch,                                                       #  6
                $variable,                                                       #  7
            );
        }

        # $var !~ s///r doesn't make sense
        if ($bind_operator =~ / !~ /oxms) {
            $sub = q{die("$0: Using !~ with s///r doesn't make sense"), } . $sub;
        }
    }

    # without /r
    else {
        if (0) {
        }

        # s///g with multibyte anchoring
        elsif ($modifier =~ /g/oxms) {
            $sub = sprintf(
                #                                                             1     2   3                                 4   5 6                                      7                                                           8        9                           10
                q<CORE::eval{local $KPS9566::re_n=0; local $KPS9566::re_a=''; while(%s =~ %s){%s local $^W=0; local $KPS9566::re_r=%s; %s%s="$KPS9566::re_a${1}$KPS9566::re_r$'"; pos(%s)=length "$KPS9566::re_a${1}$KPS9566::re_r"; $KPS9566::re_a=substr(%s,0,pos(%s)); $KPS9566::re_n++} return %s$KPS9566::re_n}>,

                $variable,                                                       #  1
                ($delimiter1 eq "'") ?                                           #  2
                e_s1_q('m', $delimiter1, $end_delimiter1, $pattern, $modifier) : #  :
                e_s1  ('m', $delimiter1, $end_delimiter1, $pattern, $modifier),  #  :
                $s_matched,                                                      #  3
                $e_replacement,                                                  #  4
                '$KPS9566::re_r=CORE::eval $KPS9566::re_r; ' x $e_modifier,            #  5
                $variable,                                                       #  6
                $variable,                                                       #  7
                $variable,                                                       #  8
                $variable,                                                       #  9

# Binary "!~" is just like "=~" except the return value is negated in the logical sense.
# It returns false if the match succeeds, and true if it fails.
# (and so on)

                ($bind_operator =~ / !~ /oxms) ? '!' : '',                       # 10
            );
        }

        # s///g without multibyte anchoring
        elsif ($modifier =~ /g/oxms) {
            $sub = sprintf(
                #                                       1     2   3                                 4   5 6                         7                                                 8
                q<CORE::eval{local $KPS9566::re_n=0; while(%s =~ %s){%s local $^W=0; local $KPS9566::re_r=%s; %s%s="$`$KPS9566::re_r$'"; pos(%s)=length "$`$KPS9566::re_r"; $KPS9566::re_n++} return %s$KPS9566::re_n}>,

                $variable,                                                       #  1
                ($delimiter1 eq "'") ?                                           #  2
                e_s1_q('m', $delimiter1, $end_delimiter1, $pattern, $modifier) : #  :
                e_s1  ('m', $delimiter1, $end_delimiter1, $pattern, $modifier),  #  :
                $s_matched,                                                      #  3
                $e_replacement,                                                  #  4
                '$KPS9566::re_r=CORE::eval $KPS9566::re_r; ' x $e_modifier,            #  5
                $variable,                                                       #  6
                $variable,                                                       #  7
                ($bind_operator =~ / !~ /oxms) ? '!' : '',                       #  8
            );
        }

        # s///
        else {

            my $prematch = q{$`};
            if ($] >= 5.010) {
                $prematch = q{$+{_PREMATCH}};
            }
            else {
                $prematch = q{${1}};
            }

            $sub = sprintf(

                ($bind_operator =~ / =~ /oxms) ?

                #  1 2 3                4                                 5   6 7   8
                q<(%s%s%s) ? CORE::eval{%s local $^W=0; local $KPS9566::re_r=%s; %s%s="%s$KPS9566::re_r$'"; 1 } : undef> :

                #  1 2 3                    4                                 5   6 7   8
                q<(%s%s%s) ? 1 : CORE::eval{%s local $^W=0; local $KPS9566::re_r=%s; %s%s="%s$KPS9566::re_r$'"; undef }>,

                $variable,                                                       #  1
                $bind_operator,                                                  #  2
                ($delimiter1 eq "'") ?                                           #  3
                e_s1_q('m', $delimiter1, $end_delimiter1, $pattern, $modifier) : #  :
                e_s1  ('m', $delimiter1, $end_delimiter1, $pattern, $modifier),  #  :
                $s_matched,                                                      #  4
                $e_replacement,                                                  #  5
                '$KPS9566::re_r=CORE::eval $KPS9566::re_r; ' x $e_modifier,            #  6
                $variable,                                                       #  7
                $prematch,                                                       #  8
            );
        }
    }

    # (my $foo = $bar) =~ s///   -->   (my $foo = $bar, CORE::eval { ... })[1]
    if ($my ne '') {
        $sub = "($my, $sub)[1]";
    }

    # clear s/// variable
    $sub_variable = '';
    $bind_operator = '';

    return $sub;
}

#
# escape chdir (qq//, "")
#
sub e_chdir {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    if ($^W) {
        if (Ekps9566::_MSWin32_5Cended_path($string)) {
            if ($] !~ /^5\.005/oxms) {
                warn <<END;
@{[__FILE__]}: Can't chdir to '$string'

chdir does not work with chr(0x5C) at end of path
http://bugs.activestate.com/show_bug.cgi?id=81839
END
            }
        }
    }

    return e_qq($ope,$delimiter,$end_delimiter,$string);
}

#
# escape chdir (q//, '')
#
sub e_chdir_q {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    if ($^W) {
        if (Ekps9566::_MSWin32_5Cended_path($string)) {
            if ($] !~ /^5\.005/oxms) {
                warn <<END;
@{[__FILE__]}: Can't chdir to '$string'

chdir does not work with chr(0x5C) at end of path
http://bugs.activestate.com/show_bug.cgi?id=81839
END
            }
        }
    }

    return e_q($ope,$delimiter,$end_delimiter,$string);
}

#
# escape regexp of split qr//
#
sub e_split {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $modifier =~ tr/p//d;
    if ($modifier =~ /([adlu])/oxms) {
        my $line = 0;
        for (my $i=0; my($package,$filename,$use_line,$subroutine) = caller($i); $i++) {
            if ($filename ne __FILE__) {
                $line = $use_line + (CORE::substr($_,0,pos($_)) =~ tr/\n//) + 1;
                last;
            }
        }
        die qq{Unsupported modifier "$1" used at line $line.\n};
    }

    $slash = 'div';

    # /b /B modifier
    if ($modifier =~ tr/bB//d) {
        return join '', 'split', $ope, $delimiter, $string, $end_delimiter, $modifier;
    }

    my $ignorecase = ($modifier =~ /i/oxms) ? 1 : 0;
    my $metachar = qr/[\@\\|[\]{^]/oxms;

    # split regexp
    my @char = $string =~ /\G((?>
        [^\x81-\xFE\\\$\@\[\(]|[\x81-\xFE][\x00-\xFF] |
        \\x   (?>[0-9A-Fa-f]{1,2}) |
        \\    (?>[0-7]{2,3})       |
        \\c   [\x40-\x5F]          |
        \\x\{ (?>[0-9A-Fa-f]+) \}  |
        \\o\{ (?>[0-7]+)       \}  |
        \\[bBNpP]\{ (?>[^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} |
        \\  $q_char                |
        \$` | \$\{`\} | \$ (?>\s*) PREMATCH  | \$ (?>\s*) \{ (?>\s*) PREMATCH  (?>\s*) \} | \$ (?>\s*) \{\^PREMATCH\}  |
        \$& | \$\{&\} | \$ (?>\s*) MATCH     | \$ (?>\s*) \{ (?>\s*) MATCH     (?>\s*) \} | \$ (?>\s*) \{\^MATCH\}     |
                        \$ (?>\s*) POSTMATCH | \$ (?>\s*) \{ (?>\s*) POSTMATCH (?>\s*) \} | \$ (?>\s*) \{\^POSTMATCH\} |
        [\$\@] $qq_variable        |
        \$ (?>\s* [0-9]+)          |
        \$ (?>\s*) \{ (?>\s* [0-9]+ \s*) \}  |
        \$ \$ (?![\w\{])           |
        \$ (?>\s*) \$ (?>\s*) $qq_variable   |
        \[\^                       |
        \[\:   (?>[a-z]+) :\]      |
        \[\:\^ (?>[a-z]+) :\]      |
        \(\?                       |
            $q_char
    ))/oxmsg;

    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {

        # "\L\u" --> "\u\L"
        if (($char[$i] eq '\L') and ($char[$i+1] eq '\u')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # "\U\l" --> "\l\U"
        elsif (($char[$i] eq '\U') and ($char[$i+1] eq '\l')) {
            @char[$i,$i+1] = @char[$i+1,$i];
        }

        # octal escape sequence
        elsif ($char[$i] =~ /\A \\o \{ ([0-7]+) \} \z/oxms) {
            $char[$i] = Ekps9566::octchr($1);
        }

        # hexadecimal escape sequence
        elsif ($char[$i] =~ /\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            $char[$i] = Ekps9566::hexchr($1);
        }

        # \b{...}      --> b\{...}
        # \B{...}      --> B\{...}
        # \N{CHARNAME} --> N\{CHARNAME}
        # \p{PROPERTY} --> p\{PROPERTY}
        # \P{PROPERTY} --> P\{PROPERTY}
        elsif ($char[$i] =~ /\A \\ ([bBNpP]) ( \{ ([^\x81-\xFE0-9\}][^\x81-\xFE\}]*) \} ) \z/oxms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # \p, \P, \X --> p, P, X
        elsif ($char[$i] =~ /\A \\ ( [pPX] ) \z/oxms) {
            $char[$i] = $1;
        }

        if (0) {
        }

        # escape last octet of multiple-octet
        elsif ($char[$i] =~ /\A \\? ([\x80-\xFF].*) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # join separated multiple-octet
        elsif ($char[$i] =~ /\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms) {
            if (   ($i+3 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+3]) == 3) and (CORE::eval(sprintf '"%s%s%s%s"', @char[$i..$i+3]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 3;
            }
            elsif (($i+2 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, @char[$i+1..$i+2]) == 2) and (CORE::eval(sprintf '"%s%s%s"',   @char[$i..$i+2]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 2;
            }
            elsif (($i+1 <= $#char) and (grep(/\A (?: \\ [0-7]{2,3} | \\x [0-9A-Fa-f]{1,2}) \z/oxms, $char[$i+1      ]) == 1) and (CORE::eval(sprintf '"%s%s"',     @char[$i..$i+1]) =~ /\A $q_char \z/oxms)) {
                $char[$i] .= join '', splice @char, $i+1, 1;
            }
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp\n";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    if (grep(/\A [\$\@]/oxms,@char[$left+1..$right-1]) >= 1) {
                        splice @char, $left, $right-$left+1, sprintf(q{@{[Ekps9566::charlist_qr(%s,'%s')]}}, join(',', map {qq_stuff($delimiter,$end_delimiter,$_)} @char[$left+1..$right-1]), $modifier);
                    }
                    else {
                        splice @char, $left, $right-$left+1, Ekps9566::charlist_qr(@char[$left+1..$right-1], $modifier);
                    }

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp\n";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    if (grep(/\A [\$\@]/oxms,@char[$left+1..$right-1]) >= 1) {
                        splice @char, $left, $right-$left+1, sprintf(q{@{[Ekps9566::charlist_not_qr(%s,'%s')]}}, join(',', map {qq_stuff($delimiter,$end_delimiter,$_)} @char[$left+1..$right-1]), $modifier);
                    }
                    else {
                        splice @char, $left, $right-$left+1, Ekps9566::charlist_not_qr(@char[$left+1..$right-1], $modifier);
                    }

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # P.794 29.2.161. split
        # in Chapter 29: Functions
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # P.951 split
        # in Chapter 27: Functions
        # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

        # said "The //m modifier is assumed when you split on the pattern /^/",
        # but perl5.008 is not so. Therefore, this software adds //m.
        # (and so on)

        # split(m/^/) --> split(m/^/m)
        elsif (($char[$i] eq '^') and ($modifier !~ /m/oxms)) {
            $modifier .= 'm';
        }

        # /i modifier
        elsif ($ignorecase and ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) and (Ekps9566::uc($char[$i]) ne Ekps9566::fc($char[$i]))) {
            if (CORE::length(Ekps9566::fc($char[$i])) == 1) {
                $char[$i] = '['   . Ekps9566::uc($char[$i])       . Ekps9566::fc($char[$i]) . ']';
            }
            else {
                $char[$i] = '(?:' . Ekps9566::uc($char[$i]) . '|' . Ekps9566::fc($char[$i]) . ')';
            }
        }

        # \u \l \U \L \F \Q \E
        elsif ($char[$i] =~ /\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\u') {
            $char[$i] = '@{[Ekps9566::ucfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\l') {
            $char[$i] = '@{[Ekps9566::lcfirst qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Ekps9566::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Ekps9566::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\F') {
            $char[$i] = '@{[Ekps9566::fc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
        elsif ($char[$i] eq '\Q') {
            while (1) {
                if (++$i > $#char) {
                    last;
                }
                if ($char[$i] eq '\E') {
                    last;
                }
            }
        }
        elsif ($char[$i] eq '\E') {
        }

        # $0 --> $0
        elsif ($char[$i] =~ /\A \$ 0 \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ /\A \$ \{ (?>\s*) 0 (?>\s*) \} \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$ --> $$
        elsif ($char[$i] =~ /\A \$\$ \z/oxms) {
        }

        # $1, $2, $3 --> $2, $3, $4 after s/// with multibyte anchoring
        # $1, $2, $3 --> $1, $2, $3 otherwise
        elsif ($char[$i] =~ /\A \$ ((?>[1-9][0-9]*)) \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }
        elsif ($char[$i] =~ /\A \$ \{ (?>\s*) ((?>[1-9][0-9]*)) (?>\s*) \} \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo[ ... ] --> $ $foo->[ ... ]
        elsif ($char[$i] =~ /\A \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) ( \[ (?:$qq_bracket)*? \] ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo{ ... } --> $ $foo->{ ... }
        elsif ($char[$i] =~ /\A \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) ( \{ (?:$qq_brace)*? \} ) \z/oxms) {
            $char[$i] = e_capture($1.'->'.$2);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $$foo
        elsif ($char[$i] =~ /\A \$ ((?> \$ [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* )) \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $`, ${`}, $PREMATCH, ${PREMATCH}, ${^PREMATCH} --> Ekps9566::PREMATCH()
        elsif ($char[$i] =~ /\A ( \$` | \$\{`\} | \$ (?>\s*) PREMATCH  | \$ (?>\s*) \{ (?>\s*) PREMATCH  (?>\s*) \} | \$ (?>\s*) \{\^PREMATCH\}  ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(Ekps9566::PREMATCH())]}';
            }
            else {
                $char[$i] = '@{[Ekps9566::PREMATCH()]}';
            }
        }

        # $&, ${&}, $MATCH, ${MATCH}, ${^MATCH} --> Ekps9566::MATCH()
        elsif ($char[$i] =~ /\A ( \$& | \$\{&\} | \$ (?>\s*) MATCH     | \$ (?>\s*) \{ (?>\s*) MATCH     (?>\s*) \} | \$ (?>\s*) \{\^MATCH\}     ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(Ekps9566::MATCH())]}';
            }
            else {
                $char[$i] = '@{[Ekps9566::MATCH()]}';
            }
        }

        # $POSTMATCH, ${POSTMATCH}, ${^POSTMATCH} --> Ekps9566::POSTMATCH()
        elsif ($char[$i] =~ /\A (                 \$ (?>\s*) POSTMATCH | \$ (?>\s*) \{ (?>\s*) POSTMATCH (?>\s*) \} | \$ (?>\s*) \{\^POSTMATCH\} ) \z/oxmsgc) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(Ekps9566::POSTMATCH())]}';
            }
            else {
                $char[$i] = '@{[Ekps9566::POSTMATCH()]}';
            }
        }

        # ${ foo }
        elsif ($char[$i] =~ /\A \$ (?>\s*) \{ ((?> \s* [A-Za-z_][A-Za-z0-9_]*(?: ::[A-Za-z_][A-Za-z0-9_]*)* \s* )) \}                            \z/oxms) {
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $1 . ')]}';
            }
        }

        # ${ ... }
        elsif ($char[$i] =~ /\A \$ (?>\s*) \{ ( .+ ) \} \z/oxms) {
            $char[$i] = e_capture($1);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ /\A [\$\@].+ /oxms) {
            $char[$i] = e_string($char[$i]);
            if ($ignorecase) {
                $char[$i] = '@{[Ekps9566::ignorecase(' . $char[$i] . ')]}';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ /\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] =~ /\A (?:[\x00-\xFF]|\\[0-7]{2,3}|\\x[0-9-A-Fa-f]{1,2}) \z/oxms) {
            }
            else {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    # make regexp string
    $modifier =~ tr/i//d;
    if ($left_e > $right_e) {
        return join '', 'Ekps9566::split', $ope, $delimiter, @char, '>]}' x ($left_e - $right_e), $end_delimiter, $modifier;
    }
    return     join '', 'Ekps9566::split', $ope, $delimiter, @char,                               $end_delimiter, $modifier;
}

#
# escape regexp of split qr''
#
sub e_split_q {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $modifier =~ tr/p//d;
    if ($modifier =~ /([adlu])/oxms) {
        my $line = 0;
        for (my $i=0; my($package,$filename,$use_line,$subroutine) = caller($i); $i++) {
            if ($filename ne __FILE__) {
                $line = $use_line + (CORE::substr($_,0,pos($_)) =~ tr/\n//) + 1;
                last;
            }
        }
        die qq{Unsupported modifier "$1" used at line $line.\n};
    }

    $slash = 'div';

    # /b /B modifier
    if ($modifier =~ tr/bB//d) {
        return join '', 'split', $ope, $delimiter, $string, $end_delimiter, $modifier;
    }

    my $ignorecase = ($modifier =~ /i/oxms) ? 1 : 0;

    # split regexp
    my @char = $string =~ /\G((?>
        [^\x81-\xFE\\\[]       |
        [\x81-\xFE][\x00-\xFF] |
        \[\^                            |
        \[\:   (?>[a-z]+) \:\]          |
        \[\:\^ (?>[a-z]+) \:\]          |
        \\     (?:$q_char)              |
               (?:$q_char)
    ))/oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        if (0) {
        }

        # escape last octet of multiple-octet
        elsif ($char[$i] =~ /\A ([\x80-\xFF].*) ([\\|\[\{\^]|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp\n";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, Ekps9566::charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            if ($char[$i+1] eq ']') {
                $i++;
            }
            while (1) {
                if (++$i > $#char) {
                    die __FILE__, ": Unmatched [] in regexp\n";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, Ekps9566::charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = character_class($char[$i],$modifier)) {
            $char[$i] = $char;
        }

        # split(m/^/) --> split(m/^/m)
        elsif (($char[$i] eq '^') and ($modifier !~ /m/oxms)) {
            $modifier .= 'm';
        }

        # /i modifier
        elsif ($ignorecase and ($char[$i] =~ /\A [\x00-\xFF] \z/oxms) and (Ekps9566::uc($char[$i]) ne Ekps9566::fc($char[$i]))) {
            if (CORE::length(Ekps9566::fc($char[$i])) == 1) {
                $char[$i] = '['   . Ekps9566::uc($char[$i])       . Ekps9566::fc($char[$i]) . ']';
            }
            else {
                $char[$i] = '(?:' . Ekps9566::uc($char[$i]) . '|' . Ekps9566::fc($char[$i]) . ')';
            }
        }

        # quote character before ? + * {
        elsif (($i >= 1) and ($char[$i] =~ /\A [\?\+\*\{] \z/oxms)) {
            if ($char[$i-1] =~ /\A [\x00-\xFF] \z/oxms) {
            }
            else {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }
    }

    $modifier =~ tr/i//d;
    return join '', 'Ekps9566::split', $ope, $delimiter, @char, $end_delimiter, $modifier;
}

#
# escape use without import
#
sub e_use_noimport {
    my($module) = @_;

    my $expr = _pathof($module);

    my $fh = gensym();
    for my $realfilename (_realfilename($expr)) {

        if (Ekps9566::_open_r($fh, $realfilename)) {
            local $/ = undef; # slurp mode
            my $script = <$fh>;
            close($fh) or die __FILE__, ": Can't close file: $realfilename\n";

            if ($script =~ /^ (?>\s*) use (?>\s+) KPS9566 (?>\s*) ([^\x81-\xFE;]*) ; (?>\s*) \n? $/oxms) {
                return qq<BEGIN { Ekps9566::require '$expr'; }>;
            }
            last;
        }
    }

    return qq<use $module ();>;
}

#
# escape no without unimport
#
sub e_no_nounimport {
    my($module) = @_;

    my $expr = _pathof($module);

    my $fh = gensym();
    for my $realfilename (_realfilename($expr)) {

        if (Ekps9566::_open_r($fh, $realfilename)) {
            local $/ = undef; # slurp mode
            my $script = <$fh>;
            close($fh) or die __FILE__, ": Can't close file: $realfilename\n";

            if ($script =~ /^ (?>\s*) use (?>\s+) KPS9566 (?>\s*) ([^\x81-\xFE;]*) ; (?>\s*) \n? $/oxms) {
                return qq<BEGIN { Ekps9566::require '$expr'; }>;
            }
            last;
        }
    }

    return qq<no $module ();>;
}

#
# escape use with import no parameter
#
sub e_use_noparam {
    my($module) = @_;

    my $expr = _pathof($module);

    my $fh = gensym();
    for my $realfilename (_realfilename($expr)) {

        if (Ekps9566::_open_r($fh, $realfilename)) {
            local $/ = undef; # slurp mode
            my $script = <$fh>;
            close($fh) or die __FILE__, ": Can't close file: $realfilename\n";

            if ($script =~ /^ (?>\s*) use (?>\s+) KPS9566 (?>\s*) ([^\x81-\xFE;]*) ; (?>\s*) \n? $/oxms) {

                # P.326 UNIVERSAL: The Ultimate Ancestor Class
                # in Chapter 12: Objects
                # of ISBN 0-596-00027-8 Programming Perl Third Edition.

                # P.435 UNIVERSAL: The Ultimate Ancestor Class
                # in Chapter 12: Objects
                # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

                # (and so on)

                return qq[BEGIN { Ekps9566::require '$expr'; $module->import() if $module->can('import'); }];
            }
            last;
        }
    }

    return qq<use $module;>;
}

#
# escape no with unimport no parameter
#
sub e_no_noparam {
    my($module) = @_;

    my $expr = _pathof($module);

    my $fh = gensym();
    for my $realfilename (_realfilename($expr)) {

        if (Ekps9566::_open_r($fh, $realfilename)) {
            local $/ = undef; # slurp mode
            my $script = <$fh>;
            close($fh) or die __FILE__, ": Can't close file: $realfilename\n";

            if ($script =~ /^ (?>\s*) use (?>\s+) KPS9566 (?>\s*) ([^\x81-\xFE;]*) ; (?>\s*) \n? $/oxms) {
                return qq[BEGIN { Ekps9566::require '$expr'; $module->unimport() if $module->can('unimport'); }];
            }
            last;
        }
    }

    return qq<no $module;>;
}

#
# escape use with import parameters
#
sub e_use {
    my($module,$list) = @_;

    my $expr = _pathof($module);

    my $fh = gensym();
    for my $realfilename (_realfilename($expr)) {

        if (Ekps9566::_open_r($fh, $realfilename)) {
            local $/ = undef; # slurp mode
            my $script = <$fh>;
            close($fh) or die __FILE__, ": Can't close file: $realfilename\n";

            if ($script =~ /^ (?>\s*) use (?>\s+) KPS9566 (?>\s*) ([^\x81-\xFE;]*) ; (?>\s*) \n? $/oxms) {
                return qq[BEGIN { Ekps9566::require '$expr'; $module->import($list) if $module->can('import'); }];
            }
            last;
        }
    }

    return qq<use $module $list;>;
}

#
# escape no with unimport parameters
#
sub e_no {
    my($module,$list) = @_;

    my $expr = _pathof($module);

    my $fh = gensym();
    for my $realfilename (_realfilename($expr)) {

        if (Ekps9566::_open_r($fh, $realfilename)) {
            local $/ = undef; # slurp mode
            my $script = <$fh>;
            close($fh) or die __FILE__, ": Can't close file: $realfilename\n";

            if ($script =~ /^ (?>\s*) use (?>\s+) KPS9566 (?>\s*) ([^\x81-\xFE;]*) ; (?>\s*) \n? $/oxms) {
                return qq[BEGIN { Ekps9566::require '$expr'; $module->unimport($list) if $module->can('unimport'); }];
            }
            last;
        }
    }

    return qq<no $module $list;>;
}

#
# file path of module
#
sub _pathof {
    my($expr) = @_;

    if ($^O eq 'MacOS') {
        $expr =~ s#::#:#g;
    }
    else {
        $expr =~ s#::#/#g;
    }
    $expr .= '.pm' if $expr !~ / \.pm \z/oxmsi;

    return $expr;
}

#
# real file name of module
#
sub _realfilename {
    my($expr) = @_;

    if ($^O eq 'MacOS') {
        return map {"$_$expr"} @INC;
    }
    else {
        return map {"$_/$expr"} @INC;
    }
}

#
# instead of Carp::carp
#
sub carp {
    my($package,$filename,$line) = caller(1);
    print STDERR "@_ at $filename line $line.\n";
}

#
# instead of Carp::croak
#
sub croak {
    my($package,$filename,$line) = caller(1);
    print STDERR "@_ at $filename line $line.\n";
    die "\n";
}

#
# instead of Carp::cluck
#
sub cluck {
    my $i = 0;
    my @cluck = ();
    while (my($package,$filename,$line,$subroutine) = caller($i)) {
        push @cluck, "[$i] $filename($line) $package::$subroutine\n";
        $i++;
    }
    print STDERR CORE::reverse @cluck;
    print STDERR "\n";
    carp @_;
}

#
# instead of Carp::confess
#
sub confess {
    my $i = 0;
    my @confess = ();
    while (my($package,$filename,$line,$subroutine) = caller($i)) {
        push @confess, "[$i] $filename($line) $package::$subroutine\n";
        $i++;
    }
    print STDERR CORE::reverse @confess;
    print STDERR "\n";
    croak @_;
}

1;

__END__

=pod

=head1 NAME

Ekps9566 - Run-time routines for KPS9566.pm

=head1 SYNOPSIS

  use Ekps9566;

    Ekps9566::split(...);
    Ekps9566::tr(...);
    Ekps9566::chop(...);
    Ekps9566::index(...);
    Ekps9566::rindex(...);
    Ekps9566::lc(...);
    Ekps9566::lc_;
    Ekps9566::lcfirst(...);
    Ekps9566::lcfirst_;
    Ekps9566::uc(...);
    Ekps9566::uc_;
    Ekps9566::ucfirst(...);
    Ekps9566::ucfirst_;
    Ekps9566::fc(...);
    Ekps9566::fc_;
    Ekps9566::ignorecase(...);
    Ekps9566::capture(...);
    Ekps9566::chr(...);
    Ekps9566::chr_;
    Ekps9566::X ...;
    Ekps9566::X_;
    Ekps9566::glob(...);
    Ekps9566::glob_;
    Ekps9566::lstat(...);
    Ekps9566::lstat_;
    Ekps9566::opendir(...);
    Ekps9566::stat(...);
    Ekps9566::stat_;
    Ekps9566::unlink(...);
    Ekps9566::chdir(...);
    Ekps9566::do(...);
    Ekps9566::require(...);
    Ekps9566::telldir(...);

  # "no Ekps9566;" not supported

=head1 ABSTRACT

This module has run-time routines for use KPS9566 software automatically, you
do not have to use.

=head1 BUGS AND LIMITATIONS

I have tested and verified this software using the best of my ability.
However, a software containing much regular expression is bound to contain
some bugs. Thus, if you happen to find a bug that's in KPS9566 software and not
your own program, you can try to reduce it to a minimal test case and then
report it to the following author's address. If you have an idea that could
make this a more useful tool, please let everyone share it.

=head1 HISTORY

This Ekps9566 module first appeared in ActivePerl Build 522 Built under
MSWin32 Compiled at Nov 2 1999 09:52:28

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.
For any questions, use E<lt>ina@cpan.orgE<gt> so we can share
this file.

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 EXAMPLES

=over 2

=item Split string

  @split = Ekps9566::split(/pattern/,$string,$limit);
  @split = Ekps9566::split(/pattern/,$string);
  @split = Ekps9566::split(/pattern/);
  @split = Ekps9566::split('',$string,$limit);
  @split = Ekps9566::split('',$string);
  @split = Ekps9566::split('');
  @split = Ekps9566::split();
  @split = Ekps9566::split;

  This subroutine scans a string given by $string for separators, and splits the
  string into a list of substring, returning the resulting list value in list
  context or the count of substring in scalar context. Scalar context also causes
  split to write its result to @_, but this usage is deprecated. The separators
  are determined by repeated pattern matching, using the regular expression given
  in /pattern/, so the separators may be of any size and need not be the same
  string on every match. (The separators are not ordinarily returned; exceptions
  are discussed later in this section.) If the /pattern/ doesn't match the string
  at all, Ekps9566::split returns the original string as a single substring, If it
  matches once, you get two substrings, and so on. You may supply regular
  expression modifiers to the /pattern/, like /pattern/i, /pattern/x, etc. The
  //m modifier is assumed when you split on the pattern /^/.

  If $limit is specified and positive, the subroutine splits into no more than that
  many fields (though it may split into fewer if it runs out of separators). If
  $limit is negative, it is treated as if an arbitrarily large $limit has been
  specified If $limit is omitted or zero, trailing null fields are stripped from
  the result (which potential users of pop would do wel to remember). If $string
  is omitted, the subroutine splits the $_ string. If /pattern/ is also omitted or
  is the literal space, " ", the subroutine split on whitespace, /\s+/, after
  skipping any leading whitespace.

  A /pattern/ of /^/ is secretly treated if it it were /^/m, since it isn't much
  use otherwise.

  String of any length can be split:

  @chars  = Ekps9566::split(//,  $word);
  @fields = Ekps9566::split(/:/, $line);
  @words  = Ekps9566::split(" ", $paragraph);
  @lines  = Ekps9566::split(/^/, $buffer);

  A pattern capable of matching either the null string or something longer than
  the null string (for instance, a pattern consisting of any single character
  modified by a * or ?) will split the value of $string into separate characters
  wherever it matches the null string between characters; nonnull matches will
  skip over the matched separator characters in the usual fashion. (In other words,
  a pattern won't match in one spot more than once, even if it matched with a zero
  width.) For example:

  print join(":" => Ekps9566::split(/ */, "hi there"));

  produces the output "h:i:t:h:e:r:e". The space disappers because it matches
  as part of the separator. As a trivial case, the null pattern // simply splits
  into separate characters, and spaces do not disappear. (For normal pattern
  matches, a // pattern would repeat the last successfully matched pattern, but
  Ekps9566::split's pattern is exempt from that wrinkle.)

  The $limit parameter splits only part of a string:

  my ($login, $passwd, $remainder) = Ekps9566::split(/:/, $_, 3);

  We encourage you to split to lists of names like this to make your code
  self-documenting. (For purposes of error checking, note that $remainder would
  be undefined if there were fewer than three fields.) When assigning to a list,
  if $limit is omitted, Perl supplies a $limit one larger than the number of
  variables in the list, to avoid unneccessary work. For the split above, $limit
  would have been 4 by default, and $remainder would have received only the third
  field, not all the rest of the fields. In time-critical applications, it behooves
  you not to split into more fields than you really need. (The trouble with
  powerful languages it that they let you be powerfully stupid at times.)

  We said earlier that the separators are not returned, but if the /pattern/
  contains parentheses, then the substring matched by each pair of parentheses is
  included in the resulting list, interspersed with the fields that are ordinarily
  returned. Here's a simple example:

  Ekps9566::split(/([-,])/, "1-10,20");

  which produces the list value:

  (1, "-", 10, ",", 20)

  With more parentheses, a field is returned for each pair, even if some pairs
  don't match, in which case undefined values are returned in those positions. So
  if you say:

  Ekps9566::split(/(-)|(,)/, "1-10,20");

  you get the value:

  (1, "-", undef, 10, undef, ",", 20)

  The /pattern/ argument may be replaced with an expression to specify patterns
  that vary at runtime. As with ordinary patterns, to do run-time compilation only
  once, use /$variable/o.

  As a special case, if the expression is a single space (" "), the subroutine
  splits on whitespace just as Ekps9566::split with no arguments does. Thus,
  Ekps9566::split(" ") can be used to emulate awk's default behavior. In contrast,
  Ekps9566::split(/ /) will give you as many null initial fields as there are
  leading spaces. (Other than this special case, if you supply a string instead
  of a regular expression, it'll be interpreted as a regular expression anyway.)
  You can use this property to remove leading and trailing whitespace from a
  string and to collapse intervaning stretches of whitespace into a single
  space:

  $string = join(" ", Ekps9566::split(" ", $string));

  The following example splits an RFC822 message header into a hash containing
  $head{'Date'}, $head{'Subject'}, and so on. It uses the trick of assigning a
  list of pairs to a hash, because separators altinate with separated fields, It
  users parentheses to return part of each separator as part of the returned list
  value. Since the split pattern is guaranteed to return things in pairs by virtue
  of containing one set of parentheses, the hash assignment is guaranteed to
  receive a list consisting of key/value pairs, where each key is the name of a
  header field. (Unfortunately, this technique loses information for multiple lines
  with the same key field, such as Received-By lines. Ah well)

  $header =~ s/\n\s+/ /g; # Merge continuation lines.
  %head = ("FRONTSTUFF", Ekps9566::split(/^(\S*?):\s*/m, $header));

  The following example processes the entries in a Unix passwd(5) file. You could
  leave out the chomp, in which case $shell would have a newline on the end of it.

  open(PASSWD, "/etc/passwd");
  while (<PASSWD>) {
      chomp; # remove trailing newline.
      ($login, $passwd, $uid, $gid, $gcos, $home, $shell) =
          Ekps9566::split(/:/);
      ...
  }

  Here's how process each word of each line of each file of input to create a
  word-frequency hash.

  while (<>) {
      for my $word (Ekps9566::split()) {
          $count{$word}++;
      }
  }

  The inverse of Ekps9566::split is join, except that join can only join with the
  same separator between all fields. To break apart a string with fixed-position
  fields, use unpack.

  Processing long $string (over 32766 octets) requires Perl 5.010001 or later.

=item Transliteration

  $tr = Ekps9566::tr($variable,$bind_operator,$searchlist,$replacementlist,$modifier);
  $tr = Ekps9566::tr($variable,$bind_operator,$searchlist,$replacementlist);

  This is the transliteration (sometimes erroneously called translation) operator,
  which is like the y/// operator in the Unix sed program, only better, in
  everybody's humble opinion.

  This subroutine scans a KPS9566 string character by character and replaces all
  occurrences of the characters found in $searchlist with the corresponding character
  in $replacementlist. It returns the number of characters replaced or deleted.
  If no KPS9566 string is specified via =~ operator, the $_ variable is translated.
  $modifier are:

  ---------------------------------------------------------------------------
  Modifier   Meaning
  ---------------------------------------------------------------------------
  c          Complement $searchlist.
  d          Delete found but unreplaced characters.
  s          Squash duplicate replaced characters.
  r          Return transliteration and leave the original string untouched.
  ---------------------------------------------------------------------------

  To use with a read-only value without raising an exception, use the /r modifier.

  print Ekps9566::tr('bookkeeper','=~','boep','peob','r'); # prints 'peekkoobor'

=item Chop string

  $chop = Ekps9566::chop(@list);
  $chop = Ekps9566::chop();
  $chop = Ekps9566::chop;

  This subroutine chops off the last character of a string variable and returns the
  character chopped. The Ekps9566::chop subroutine is used primary to remove the newline
  from the end of an input recoed, and it is more efficient than using a
  substitution. If that's all you're doing, then it would be safer to use chomp,
  since Ekps9566::chop always shortens the string no matter what's there, and chomp
  is more selective. If no argument is given, the subroutine chops the $_ variable.

  You cannot Ekps9566::chop a literal, only a variable. If you Ekps9566::chop a list of
  variables, each string in the list is chopped:

  @lines = `cat myfile`;
  Ekps9566::chop(@lines);

  You can Ekps9566::chop anything that is an lvalue, including an assignment:

  Ekps9566::chop($cwd = `pwd`);
  Ekps9566::chop($answer = <STDIN>);

  This is different from:

  $answer = Ekps9566::chop($tmp = <STDIN>); # WRONG

  which puts a newline into $answer because Ekps9566::chop returns the character
  chopped, not the remaining string (which is in $tmp). One way to get the result
  intended here is with substr:

  $answer = substr <STDIN>, 0, -1;

  But this is more commonly written as:

  Ekps9566::chop($answer = <STDIN>);

  In the most general case, Ekps9566::chop can be expressed using substr:

  $last_code = Ekps9566::chop($var);
  $last_code = substr($var, -1, 1, ""); # same thing

  Once you understand this equivalence, you can use it to do bigger chops. To
  Ekps9566::chop more than one character, use substr as an lvalue, assigning a null
  string. The following removes the last five characters of $caravan:

  substr($caravan, -5) = '';

  The negative subscript causes substr to count from the end of the string instead
  of the beginning. To save the removed characters, you could use the four-argument
  form of substr, creating something of a quintuple Ekps9566::chop;

  $tail = substr($caravan, -5, 5, '');

  This is all dangerous business dealing with characters instead of graphemes. Perl
  doesn't really have a grapheme mode, so you have to deal with them yourself.

=item Index string

  $byte_pos = Ekps9566::index($string,$substr,$byte_offset);
  $byte_pos = Ekps9566::index($string,$substr);

  This subroutine searches for one string within another. It returns the byte position
  of the first occurrence of $substring in $string. The $byte_offset, if specified,
  says how many bytes from the start to skip before beginning to look. Positions are
  based at 0. If the substring is not found, the subroutine returns one less than the
  base, ordinarily -1. To work your way through a string, you might say:

  $byte_pos = -1;
  while (($byte_pos = Ekps9566::index($string, $lookfor, $byte_pos)) > -1) {
      print "Found at $byte_pos\n";
      $byte_pos++;
  }

=item Reverse index string

  $byte_pos = Ekps9566::rindex($string,$substr,$byte_offset);
  $byte_pos = Ekps9566::rindex($string,$substr);

  This subroutine works just like Ekps9566::index except that it returns the byte
  position of the last occurrence of $substring in $string (a reverse Ekps9566::index).
  The subroutine returns -1 if $substring is not found. $byte_offset, if specified,
  is the rightmost byte position that may be returned. To work your way through a
  string backward, say:

  $byte_pos = length($string);
  while (($byte_pos = KPS9566::rindex($string, $lookfor, $byte_pos)) >= 0) {
      print "Found at $byte_pos\n";
      $byte_pos--;
  }

=item Lower case string

  $lc = Ekps9566::lc($string);
  $lc = Ekps9566::lc_;

  This subroutine returns a lowercased version of KPS9566 $string (or $_, if
  $string is omitted). This is the internal subroutine implementing the \L escape
  in double-quoted strings.

  You can use the Ekps9566::fc subroutine for case-insensitive comparisons via KPS9566
  software.

=item Lower case first character of string

  $lcfirst = Ekps9566::lcfirst($string);
  $lcfirst = Ekps9566::lcfirst_;

  This subroutine returns a version of KPS9566 $string with the first character
  lowercased (or $_, if $string is omitted). This is the internal subroutine
  implementing the \l escape in double-quoted strings.

=item Upper case string

  $uc = Ekps9566::uc($string);
  $uc = Ekps9566::uc_;

  This subroutine returns an uppercased version of KPS9566 $string (or $_, if
  $string is omitted). This is the internal subroutine implementing the \U escape
  in interpolated strings. For titlecase, use Ekps9566::ucfirst instead.

  You can use the Ekps9566::fc subroutine for case-insensitive comparisons via KPS9566
  software.

=item Upper case first character of string

  $ucfirst = Ekps9566::ucfirst($string);
  $ucfirst = Ekps9566::ucfirst_;

  This subroutine returns a version of KPS9566 $string with the first character
  titlecased and other characters left alone (or $_, if $string is omitted).
  Titlecase is "Camel" for an initial capital that has (or expects to have)
  lowercase characters following it, not uppercase ones. Exsamples are the first
  letter of a sentence, of a person's name, of a newspaper headline, or of most
  words in a title. Characters with no titlecase mapping return the uppercase
  mapping instead. This is the internal subroutine implementing the \u escape in
  double-quoted strings.

  To capitalize a string by mapping its first character to titlecase and the rest
  to lowercase, use:

  $titlecase = Ekps9566::ucfirst(substr($word,0,1)) . Ekps9566::lc(substr($word,1));

  or

  $string =~ s/(\w)((?>\w*))/\u$1\L$2/g;

  Do not use:

  $do_not_use = Ekps9566::ucfirst(Ekps9566::lc($word));

  or "\u\L$word", because that can produce a different and incorrect answer with
  certain characters. The titlecase of something that's been lowercased doesn't
  always produce the same thing titlecasing the original produces.

  Because titlecasing only makes sense at the start of a string that's followed
  by lowercase characters, we can't think of any reason you might want to titlecase
  every character in a string.

  See also P.287 A Case of Mistaken Identity
  in Chapter 6: Unicode
  of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

=item Fold case string

  P.860 fc
  in Chapter 27: Functions
  of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

  $fc = Ekps9566::fc($string);
  $fc = Ekps9566::fc_;

  New to KPS9566 software, this subroutine returns the full Unicode-like casefold of
  KPS9566 $string (or $_, if omitted). This is the internal subroutine implementing
  the \F escape in double-quoted strings.

  Just as title-case is based on uppercase but different, foldcase is based on
  lowercase but different. In ASCII there is a one-to-one mapping between only
  two cases, but in other encoding there is a one-to-many mapping and between three
  cases. Because that's too many combinations to check manually each time, a fourth
  casemap called foldcase was invented as a common intermediary for the other three.
  It is not a case itself, but it is a casemap.

  To compare whether two strings are the same without regard to case, do this:

  Ekps9566::fc($a) eq Ekps9566::fc($b)

  The reliable way to compare string case-insensitively was with the /i pattern
  modifier, because KPS9566 software has always used casefolding semantics for
  case-insensitive pattern matches. Knowing this, you can emulate equality
  comparisons like this:

  sub fc_eq ($$) {
      my($a,$b) = @_;
      return $a =~ /\A\Q$b\E\z/i;
  }

=item Make ignore case string

  @ignorecase = Ekps9566::ignorecase(@string);

  This subroutine is internal use to m/ /i, s/ / /i, split / /i, and qr/ /i.

=item Make capture number

  $capturenumber = Ekps9566::capture($string);

  This subroutine is internal use to m/ /, s/ / /, split / /, and qr/ /.

=item Make character

  $chr = Ekps9566::chr($code);
  $chr = Ekps9566::chr_;

  This subroutine returns a programmer-visible character, character represented by
  that $code in the character set. For example, Ekps9566::chr(65) is "A" in either
  ASCII or KPS9566, not Unicode. For the reverse of Ekps9566::chr, use KPS9566::ord.

=item File test subroutine Ekps9566::X

  The following all subroutines function when the pathname ends with chr(0x5C) on
  MSWin32.

  A file test subroutine is a unary function that takes one argument, either a
  filename or a filehandle, and tests the associated file to see whether something
  is true about it. If the argument is omitted, it tests $_. Unless otherwise
  documented, it returns 1 for true and "" for false, or the undefined value if
  the file doesn't exist or is otherwise inaccessible. Currently implemented file
  test subroutines are listed in:

  Available in MSWin32, MacOS, and UNIX-like systems
  ------------------------------------------------------------------------------
  Subroutine and Prototype   Meaning
  ------------------------------------------------------------------------------
  Ekps9566::r(*), Ekps9566::r_()   File or directory is readable by this (effective) user or group
  Ekps9566::w(*), Ekps9566::w_()   File or directory is writable by this (effective) user or group
  Ekps9566::e(*), Ekps9566::e_()   File or directory name exists
  Ekps9566::x(*), Ekps9566::x_()   File or directory is executable by this (effective) user or group
  Ekps9566::z(*), Ekps9566::z_()   File exists and has zero size (always false for directories)
  Ekps9566::f(*), Ekps9566::f_()   Entry is a plain file
  Ekps9566::d(*), Ekps9566::d_()   Entry is a directory
  ------------------------------------------------------------------------------
  
  Available in MacOS and UNIX-like systems
  ------------------------------------------------------------------------------
  Subroutine and Prototype   Meaning
  ------------------------------------------------------------------------------
  Ekps9566::R(*), Ekps9566::R_()   File or directory is readable by this real user or group
                             Same as Ekps9566::r(*), Ekps9566::r_() on MacOS
  Ekps9566::W(*), Ekps9566::W_()   File or directory is writable by this real user or group
                             Same as Ekps9566::w(*), Ekps9566::w_() on MacOS
  Ekps9566::X(*), Ekps9566::X_()   File or directory is executable by this real user or group
                             Same as Ekps9566::x(*), Ekps9566::x_() on MacOS
  Ekps9566::l(*), Ekps9566::l_()   Entry is a symbolic link
  Ekps9566::S(*), Ekps9566::S_()   Entry is a socket
  ------------------------------------------------------------------------------
  
  Not available in MSWin32 and MacOS
  ------------------------------------------------------------------------------
  Subroutine and Prototype   Meaning
  ------------------------------------------------------------------------------
  Ekps9566::o(*), Ekps9566::o_()   File or directory is owned by this (effective) user
  Ekps9566::O(*), Ekps9566::O_()   File or directory is owned by this real user
  Ekps9566::p(*), Ekps9566::p_()   Entry is a named pipe (a "fifo")
  Ekps9566::b(*), Ekps9566::b_()   Entry is a block-special file (like a mountable disk)
  Ekps9566::c(*), Ekps9566::c_()   Entry is a character-special file (like an I/O device)
  Ekps9566::u(*), Ekps9566::u_()   File or directory is setuid
  Ekps9566::g(*), Ekps9566::g_()   File or directory is setgid
  Ekps9566::k(*), Ekps9566::k_()   File or directory has the sticky bit set
  ------------------------------------------------------------------------------

  The tests -T and -B takes a try at telling whether a file is text or binary.
  But people who know a lot about filesystems know that there's no bit (at least
  in UNIX-like operating systems) to indicate that a file is a binary or text file
  --- so how can Perl tell?
  The answer is that Perl cheats. As you might guess, it sometimes guesses wrong.

  This incomplete thinking of file test operator -T and -B gave birth to UTF8 flag
  of a later period.

  The Ekps9566::T, Ekps9566::T_, Ekps9566::B, and Ekps9566::B_ work as follows. The first block
  or so of the file is examined for strange chatracters such as
  [\000-\007\013\016-\032\034-\037\377] (that don't look like KPS9566). If more
  than 10% of the bytes appear to be strange, it's a *maybe* binary file;
  otherwise, it's a *maybe* text file. Also, any file containing ASCII NUL(\0) or
  \377 in the first block is considered a binary file. If Ekps9566::T or Ekps9566::B is
  used on a filehandle, the current input (standard I/O or "stdio") buffer is
  examined rather than the first block of the file. Both Ekps9566::T and Ekps9566::B
  return 1 as true on an empty file, or on a file at EOF (end-of-file) when testing
  a filehandle. Both Ekps9566::T and Ekps9566::B doesn't work when given the special
  filehandle consisting of a solitary underline. Because Ekps9566::T has to read to
  do the test, you don't want to use Ekps9566::T on special files that might hang or
  give you other kinds or grief. So on most occasions you'll want to test with a
  Ekps9566::f first, as in:

  next unless Ekps9566::f($file) && Ekps9566::T($file);

  Available in MSWin32, MacOS, and UNIX-like systems
  ------------------------------------------------------------------------------
  Subroutine and Prototype   Meaning
  ------------------------------------------------------------------------------
  Ekps9566::T(*), Ekps9566::T_()   File looks like a "text" file
  Ekps9566::B(*), Ekps9566::B_()   File looks like a "binary" file
  ------------------------------------------------------------------------------

  File ages for Ekps9566::M, Ekps9566::M_, Ekps9566::A, Ekps9566::A_, Ekps9566::C, and Ekps9566::C_
  are returned in days (including fractional days) since the script started running.
  This start time is stored in the special variable $^T ($BASETIME). Thus, if the
  file changed after the script, you would get a negative time. Note that most time
  values (86,399 out of 86,400, on average) are fractional, so testing for equality
  with an integer without using the int function is usually futile. Examples:

  next unless Ekps9566::M($file) > 0.5;     # files are older than 12 hours
  &newfile if Ekps9566::M($file) < 0;       # file is newer than process
  &mailwarning if int(Ekps9566::A_) == 90;  # file ($_) was accessed 90 days ago today

  Available in MSWin32, MacOS, and UNIX-like systems
  ------------------------------------------------------------------------------
  Subroutine and Prototype   Meaning
  ------------------------------------------------------------------------------
  Ekps9566::M(*), Ekps9566::M_()   Modification age (measured in days)
  Ekps9566::A(*), Ekps9566::A_()   Access age (measured in days)
                             Same as Ekps9566::M(*), Ekps9566::M_() on MacOS
  Ekps9566::C(*), Ekps9566::C_()   Inode-modification age (measured in days)
  ------------------------------------------------------------------------------

  The Ekps9566::s, and Ekps9566::s_ returns file size in bytes if succesful, or undef
  unless successful.

  Available in MSWin32, MacOS, and UNIX-like systems
  ------------------------------------------------------------------------------
  Subroutine and Prototype   Meaning
  ------------------------------------------------------------------------------
  Ekps9566::s(*), Ekps9566::s_()   File or directory exists and has nonzero size
                             (the value is the size in bytes)
  ------------------------------------------------------------------------------

=item Filename expansion (globbing)

  @glob = Ekps9566::glob($string);
  @glob = Ekps9566::glob_;

  This subroutine returns the value of $string with filename expansions the way a
  DOS-like shell would expand them, returning the next successive name on each
  call. If $string is omitted, $_ is globbed instead. This is the internal
  subroutine implementing the <*> and glob operator.
  This subroutine function when the pathname ends with chr(0x5C) on MSWin32.

  For ease of use, the algorithm matches the DOS-like shell's style of expansion,
  not the UNIX-like shell's. An asterisk ("*") matches any sequence of any
  character (including none). A question mark ("?") matches any one character or
  none. A tilde ("~") expands to a home directory, as in "~/.*rc" for all the
  current user's "rc" files, or "~jane/Mail/*" for all of Jane's mail files.

  Note that all path components are case-insensitive, and that backslashes and
  forward slashes are both accepted, and preserved. You may have to double the
  backslashes if you are putting them in literally, due to double-quotish parsing
  of the pattern by perl.

  The Ekps9566::glob subroutine grandfathers the use of whitespace to separate multiple
  patterns such as <*.c *.h>. If you want to glob filenames that might contain
  whitespace, you'll have to use extra quotes around the spacy filename to protect
  it. For example, to glob filenames that have an "e" followed by a space followed
  by an "f", use either of:

  @spacies = <"*e f*">;
  @spacies = Ekps9566::glob('"*e f*"');
  @spacies = Ekps9566::glob(q("*e f*"));

  If you had to get a variable through, you could do this:

  @spacies = Ekps9566::glob("'*${var}e f*'");
  @spacies = Ekps9566::glob(qq("*${var}e f*"));

  Another way on MSWin32

  # relative path
  @relpath_file = split(/\n/,`dir /b wildcard\\here*.txt 2>NUL`);

  # absolute path
  @abspath_file = split(/\n/,`dir /s /b wildcard\\here*.txt 2>NUL`);

  # on COMMAND.COM
  @relpath_file = split(/\n/,`dir /b wildcard\\here*.txt`);
  @abspath_file = split(/\n/,`dir /s /b wildcard\\here*.txt`);

=item Statistics about link

  @lstat = Ekps9566::lstat($file);
  @lstat = Ekps9566::lstat_;

  Like Ekps9566::stat, returns information on file, except that if file is a symbolic
  link, Ekps9566::lstat returns information about the link; Ekps9566::stat returns
  information about the file pointed to by the link. If symbolic links are
  unimplemented on your system, a normal Ekps9566::stat is done instead. If file is
  omitted, returns information on file given in $_. Returns values (especially
  device and inode) may be bogus.
  This subroutine function when the filename ends with chr(0x5C) on MSWin32.

=item Open directory handle

  $rc = Ekps9566::opendir(DIR,$dir);

  This subroutine opens a directory named $dir for processing by readdir, telldir,
  seekdir, rewinddir, and closedir. The subroutine returns true if successful.
  Directory handles have their own namespace from filehandles.
  This subroutine function when the directory name ends with chr(0x5C) on MSWin32.

=item Statistics about file

  $stat = Ekps9566::stat(FILEHANDLE);
  $stat = Ekps9566::stat(DIRHANDLE);
  $stat = Ekps9566::stat($expr);
  $stat = Ekps9566::stat_;
  @stat = Ekps9566::stat(FILEHANDLE);
  @stat = Ekps9566::stat(DIRHANDLE);
  @stat = Ekps9566::stat($expr);
  @stat = Ekps9566::stat_;

  In scalar context, this subroutine returns a Boolean value that indicates whether
  the call succeeded. In list context, it returns a 13-element list giving the
  statistics for a file, either the file opened via FILEHANDLE or DIRHANDLE, or
  named by $expr. It's typically used as followes:

  ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
      $atime,$mtime,$ctime,$blksize,$blocks) = Ekps9566::stat($expr);

  Not all fields are supported on all filesystem types; unsupported fields return
  0. Here are the meanings of the fields:

  -------------------------------------------------------------------------
  Index  Field      Meaning
  -------------------------------------------------------------------------
    0    $dev       Device number of filesystem
                    drive number for MSWin32
                    vRefnum for MacOS
    1    $ino       Inode number
                    zero for MSWin32
                    fileID/dirID for MacOS
    2    $mode      File mode (type and permissions)
    3    $nlink     Nunmer of (hard) links to the file
                    usually one for MSWin32 --- NTFS filesystems may
                    have a value greater than one
                    1 for MacOS
    4    $uid       Numeric user ID of file's owner
                    zero for MSWin32
                    zero for MacOS
    5    $gid       Numeric group ID of file's owner
                    zero for MSWin32
                    zero for MacOS
    6    $rdev      The device identifier (special files only)
                    drive number for MSWin32
                    NULL for MacOS
    7    $size      Total size of file, in bytes
    8    $atime     Last access time since the epoch
                    same as $mtime for MacOS
    9    $mtime     Last modification time since the epoch
                    since 1904-01-01 00:00:00 for MacOS
   10    $ctime     Inode change time (not creation time!) since the epoch
                    creation time instead of inode change time for MSWin32
                    since 1904-01-01 00:00:00 for MacOS
   11    $blksize   Preferred blocksize for file system I/O
                    zero for MSWin32
   12    $blocks    Actual number of blocks allocated
                    zero for MSWin32
                    int(($size + $blksize-1) / $blksize) for MacOS
  -------------------------------------------------------------------------

  $dev and $ino, token together, uniquely identify a file on the same system.
  The $blksize and $blocks are likely defined only on BSD-derived filesystems.
  The $blocks field (if defined) is reported in 512-byte blocks. The value of
  $blocks * 512 can differ greatly from $size for files containing unallocated
  blocks, or "hole", which aren't counted in $blocks.

  If Ekps9566::stat is passed the special filehandle consisting of an underline, no
  actual stat(2) is done, but the current contents of the stat structure from
  the last Ekps9566::stat, Ekps9566::lstat, or Ekps9566::stat-based file test subroutine
  (such as Ekps9566::r, Ekps9566::w, and Ekps9566::x) are returned.

  Because the mode contains both the file type and its permissions, you should
  mask off the file type portion and printf or sprintf using a "%o" if you want
  to see the real permissions:

  $mode = (Ekps9566::stat($expr))[2];
  printf "Permissions are %04o\n", $mode & 07777;

  If $expr is omitted, returns information on file given in $_.
  This subroutine function when the filename ends with chr(0x5C) on MSWin32.

=item Deletes a list of files.

  $unlink = Ekps9566::unlink(@list);
  $unlink = Ekps9566::unlink($file);
  $unlink = Ekps9566::unlink;

  Delete a list of files. (Under Unix, it will remove a link to a file, but the
  file may still exist if another link references it.) If list is omitted, it
  unlinks the file given in $_. The subroutine returns the number of files
  successfully deleted.
  This subroutine function when the filename ends with chr(0x5C) on MSWin32.

=item Changes the working directory.

  $chdir = Ekps9566::chdir($dirname);
  $chdir = Ekps9566::chdir;

  This subroutine changes the current process's working directory to $dirname, if
  possible. If $dirname is omitted, $ENV{'HOME'} is used if set, and $ENV{'LOGDIR'}
  otherwise; these are usually the process's home directory. The subroutine returns
  true on success, false otherwise (and puts the error code into $!).

  chdir("$prefix/lib") || die "Can't cd to $prefix/lib: $!";

  This subroutine has limitation on the MSWin32. See also BUGS AND LIMITATIONS.

=item Do file

  $return = Ekps9566::do($file);

  The do FILE form uses the value of FILE as a filename and executes the contents
  of the file as a Perl script. Its primary use is (or rather was) to include
  subroutines from a Perl subroutine library, so that:

  Ekps9566::do('stat.pl');

  is rather like: 

  scalar CORE::eval `cat stat.pl`;   # `type stat.pl` on Windows

  except that Ekps9566::do is more efficient, more concise, keeps track of the current
  filename for error messages, searches all the directories listed in the @INC
  array, and updates %INC if the file is found.
  It also differs in that code evaluated with Ekps9566::do FILE can not see lexicals in
  the enclosing scope, whereas code in CORE::eval FILE does. It's the same, however,
  in that it reparses the file every time you call it -- so you might not want to do
  this inside a loop unless the filename itself changes at each loop iteration.

  If Ekps9566::do can't read the file, it returns undef and sets $! to the error. If 
  Ekps9566::do can read the file but can't compile it, it returns undef and sets an
  error message in $@. If the file is successfully compiled, do returns the value of
  the last expression evaluated.

  Inclusion of library modules (which have a mandatory .pm suffix) is better done
  with the use and require operators, which also Ekps9566::do error checking and raise
  an exception if there's a problem. They also offer other benefits: they avoid
  duplicate loading, help with object-oriented programming, and provide hints to the
  compiler on function prototypes.

  But Ekps9566::do FILE is still useful for such things as reading program configuration
  files. Manual error checking can be done this way:

  # read in config files: system first, then user
  for $file ("/usr/share/proggie/defaults.rc", "$ENV{HOME}/.someprogrc") {
      unless ($return = Ekps9566::do($file)) {
          warn "couldn't parse $file: $@" if $@;
          warn "couldn't Ekps9566::do($file): $!" unless defined $return;
          warn "couldn't run $file"            unless $return;
      }
  }

  A long-running daemon could periodically examine the timestamp on its configuration
  file, and if the file has changed since it was last read in, the daemon could use
  Ekps9566::do to reload that file. This is more tidily accomplished with Ekps9566::do than
  with Ekps9566::require.

=item Require file

  Ekps9566::require($file);
  Ekps9566::require();

  This subroutine asserts a dependency of some kind on its argument. If an argument is
  not supplied, $_ is used.

  Ekps9566::require loads and executes the Perl code found in the separate file whose
  name is given by the $file. This is similar to using a Ekps9566::do on a file, except
  that Ekps9566::require checks to see whether the library file has been loaded already
  and raises an exception if any difficulties are encountered. (It can thus be used
  to express file dependencies without worrying about duplicate compilation.) Like
  its cousins Ekps9566::do, Ekps9566::require knows how to search the include path stored
  in the @INC array and to update %INC on success.

  The file must return true as the last value to indicate successful execution of any
  initialization code, so it's customary to end such a file with 1 unless you're sure
  it'll return true otherwise.

=item Current position of the readdir

  $telldir = Ekps9566::telldir(DIRHANDLE);

  This subroutine returns the current position of the readdir routines on DIRHANDLE.
  This value may be given to seekdir to access a particular location in a directory.
  The subroutine has the same caveats about possible directory compaction as the
  corresponding system library routine. This subroutine might not be implemented
  everywhere that readdir is. Even if it is, no calculation may be done with the
  return value. It's just an opaque value, meaningful only to seekdir.

=cut
