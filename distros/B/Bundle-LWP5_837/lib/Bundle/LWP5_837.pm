package Bundle::LWP5_837;
$VERSION='0.01'
__END__

=head1 NAME

Bundle::LWP5_837 - Bundle listing just LWP version 5.837

=head1 VERSION

0.01

=head1 SYNOPSIS

In your F<Makefile.PL>:

  ...
  PREREQ_PM => {
    $] < 5.008008 && !eval{require LWP} ? ( 'Bundle::LWP5_837' => 0 )
                                        : (  LWP               => 0 )
  }
  ...

=head1 DESCRIPTION

LWP version 6 requires perl 5.8.8 or higher. If your modules still run on
5.8.7 or lower and you want installation to be seamless, you can use this
single-distribution bundle to install the previous version (5.837) on older
perls.

=head1 CONTENTS

GAAS/libwww-perl-5.837.tar.gz

=head1 AUTHOR & COPYRIGHT

(For this tiny little bundle, not for LWP)

Copyright (C) 2011, Father Chrysostomos (org.cpan@sprout backwards)

This program is free software; you may redistribute it, modify it or
both under the same terms as perl.

=head1 SEE ALSO

L<LWP>
