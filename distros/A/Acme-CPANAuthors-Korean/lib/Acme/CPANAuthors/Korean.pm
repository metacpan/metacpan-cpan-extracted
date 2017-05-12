package Acme::CPANAuthors::Korean;

use strict;
use warnings;
our $VERSION = '0.16';
use utf8;

use Acme::CPANAuthors::Register (
    AANOAA    => "Hyungsuk Hong",
    AERO      => "C.H. Kang",
    AMORETTE  => "Hojung Youn",
    DALINAUM  => "김용욱 (Leonaro YongUk KIM)",
    GYPARK    => "Geunyoung Park",
    ISJOUNG   => "In Suk Joung",
    JEEN      => "Jong-jin Lee",
    JPJEON    => "Jongpil Jeon",
    KEEDI     => "Keedi Kim",
    KHS       => "HyeonSeung Kim",
    NEWBCODE  => "Yun Chang Kang",
    POTATOGIM => "Ji-Hyeon Gim",
    RAKJIN    => "Rakjin Hwang",
    SKYEND    => "J.W. Han",
    YONGBIN   => "Yongbin Yu",
    YOU       => "YOU Hyun Jo",
);

1;

__END__

=encoding utf8

=head1 NAME

Acme::CPANAuthors::Korean - We are Korean CPAN Authors! (우리는 CPAN Author 다!)

=head1 SYNOPSIS

  use Acme::CPANAuthors;
  use Acme::CPANAuthors::Korean;
  $authors = Acme::CPANAuthors->new('Korean');

  $number   = $authors->count;
  @ids      = $authors->id;
  @distors  = $authors->distributions('JEEN');
  $url      = $authors->avatar_url('KEEDI');
  $kwalitee = $authors->kwalitee('AERO');

=head1 DESCRIPTION

See documentation for L<Acme::CPANAuthors> for more details.

=head1 DEPENDENCIES

L<Acme::CPANAuthors>

=head1 DEVELOPMENT

Git repository: http://github.com/jeen/Acme-CPANAuthors-Korean/

=head1 AUTHOR

Jeen Lee E<lt>jeen@perl.krE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
