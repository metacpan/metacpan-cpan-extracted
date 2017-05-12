package Acme::CPANAuthors::Taiwanese;
{
  $Acme::CPANAuthors::Taiwanese::VERSION = '0.08';
}
# ABSTRACT: We are Taiwanese CPAN Authors!
use 5.008;
use strict;
use warnings;
use utf8;

use Acme::CPANAuthors::Register (
    AUDREYT   => "唐鳳",
    BLUET     => "練喆明",
    CLKAO     => "高嘉良",
    CLSUNG    => "宋政隆",
    CINDY     => "Cindy Wang",
    CORNELIUS => "林佑安",
    DRBEAN    => "高來圭",
    DRYMAN    => "陳仁乾",
    GSLIN     => "林嘉軒",
    GUGOD     => "劉康民",
    HCCHIEN   => "簡信昌",
    IJLIAO    => "廖英傑",
    IMACAT    => "依瑪貓",
    JNLIN     => "Jui-Nan Lin",
    KCWU      => "吳光哲",
    KENSHAN   => "單中杰",
    KENWU     => "莉洛",
    LEEYM     => "李彥明",
    LUKHNOS   => "劉燈",
    MINDOS    => "鄭智中",
    PENK      => "陳品勳",
    SHELLING  => "許家瑋",
    SNOWFLY   => "飄然似雪",
    VICTOR    => "謝毓庭",
    XERN      => "林永忠",
    YRCHEN    => "陳禹任",
);

1;

__END__

=head1 NAME

Acme::CPANAuthors::Taiwanese

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use Acme::CPANAuthors;
    $authors = Acme::CPANAuthors->new('Taiwanese');

    $number   = $authors->count;
    @ids      = $authors->id;
    @distros  = $authors->distributions('XERN');
    $url      = $authors->avatar_url('AUDREYT');
    $kwalitee = $authors->kwalitee('GUGOD');


=head1 DESCRIPTION

See documentation for L<Acme::CPANAuthors> for more details.

=head1 DEPENDENCIES

L<Acme::CPANAuthors>

=head1 DEVELOPMENT

Git repository: http://github.com/gugod/acme-cpanauthors-taiwanese/

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-acme-cpanauthors-taiwanese@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008,2009,2010,2011 Kang-min Liu C<< <gugod@gugod.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
