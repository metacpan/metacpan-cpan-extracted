package Acme::CPANAuthors::Chinese;

use strict;
use warnings;
use utf8;

our $VERSION = '0.41';

use Acme::CPANAuthors::Register (
    ABBYPAN     => 'Abby Pan',
    AGENT       => 'Agent Zhang (章亦春)',
    ALEXE       => 'Alexe',
    CARMARK     => 'Lei Xue',
    CHAOSLAW    => '王晓哲',
    CHENGANG    => '陈钢',
    CHENRYN     => 'Jeff Rao',
    CHENYR      => 'Chen Yirong (春江)',
    CHINAXING   => '陈云星',
    CHUNZI      => 'Chunzi',
    CHYLLI      => 'chylli',
    CNANGEL     => '李俊良',
    CNHACKTNT   => '王晖',
    DOGGY       => 'Pan Fan (nightsailer)',
    DONGXU      => 'Dongxu Ma <马东旭>',
    FAYLAND     => 'Fayland 林',
    FKIORI      => '陈正伟',
    FLW         => '王兴华',
    FOOLFISH    => '錢宇/Qian Yu',
    FUKAI       => '扶凯',
    HGNENG      => '黄冠能',
    HOOWA       => '孙冰',
    ISLUE       => '胡海麟',
    JOEJIANG    => '蒋永清',
    JOKERGOO    => 'Zuguang Gu',
    JWU         => '吴健源',
    JZHANG      => '张军',
    KAILI       => '李凯',
    LAOMOI      => 'xiaoshengcaicai',
    LENIK       => '谢继雷',
    LIJINFENG   => 'Li Jinfeng',
    LZH         => 'Li ZHOU',
    MAIN        => '吴健源',
    MCCHEUNG    => 'MC Cheung',
    NSNAKE      => '徐昊',
    ORANGE      => '桔子',
    PANGJ       => 'Jeff Pang',
    PANYU       => 'PAN YU',
    PEKINGSAM   => 'Yan Xueqing',
    # PYH         => '彭勇华',  ## Dups of YHPENG
    QJZHOU      => 'Qing-Jie Zhou',
    QSUN        => '孙泉',
    RANN        => '灿烂微笑 / Ran Ningyu',
    REDICAPS    => 'woosley.xu(徐洲)',
    ROOTKWOK    => '郭樂聰', # HK, he posted to ChinaUnix Perl board
    SAL         => 'Sal Zhong (仲伟祥)',
    SHUCAO      => 'Shu Cao',
    SJDY        => 'Perfi Wang',
    SUNNAVY     => '孙海军',
    SUNTONG     => 'Tong Sun',
    SWANSUN     => 'swansun huang',
    SWUECHO     => '武浩',
    TADEG       => 'tadegenban 陈',
    TOMORROW    => ' 舌尖上的牛氓 ',
    WEIQK       => '万朝伟',
    YEWENBIN    => '叶文彬',
    YHPENG      => 'Ken Peng',
    XIAODONG    => 'Xiaodong Xu',
    XIAOLAN     => '傅小兰',
    XINMING     => '鹄驿懿',
    XINZHENG    => '郑 鑫',
    XUDAYE      => 'Achilles Xu',
    XUERON      => 'Xueron Nee',
    ZHUZHU      => 'Zhu Zhu',
);

1;

__END__

=encoding utf8

=head1 NAME

Acme::CPANAuthors::Chinese - We are Chinese CPAN authors

=head1 SYNOPSIS

   use Acme::CPANAuthors;
   use Acme::CPANAuthors::Chinese;

   my $authors = Acme::CPANAuthors->new('Chinese');

   my $number   = $authors->count;
   my @ids      = $authors->id;
   my @distros  = $authors->distributions('AGENT');
   my $url      = $authors->avatar_url('FAYLAND');
   my $kwalitee = $authors->kwalitee('YEWENBIN');


=head1 DESCRIPTION

CPAN 中国作者

This class is used to provide a hash of Chinese CPAN author's PAUSE id/name to Acme::CPANAuthors.

=head1 MAINTENANCE

If you are a Chinese CPAN author not listed here, please send me your id/name via email or RT so we can always keep this module up to date. If there's a mistake and you're listed here but are not Chinese (or just don't want to be listed), sorry for the inconvenience: please contact me and I'll remove the entry right away.

=head1 SEE ALSO

L<Acme::CPANAuthors> - Main class to manipulate this one

L<Acme::CPANAuthors::Japanese> - Code and documentation nearly taken verbatim from it

L<Acme::CPANAuthors::Brazilian> - inspired me directly

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2012 Fayland Lam, PerlChina all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
