use Test::More 'no_plan';

# Module and version
{
  my $out = `script/cpanurl Mojolicious 3.82`;
  is($out, 'http://cpan.metacpan.org/authors/id/S/SR/SRI/Mojolicious-3.82.tar.gz' . "\n");
}
{
  my $out = `script/cpanurl LWP 6.04`;
  is($out, 'http://cpan.metacpan.org/authors/id/G/GA/GAAS/libwww-perl-6.04.tar.gz' . "\n");
}
{
  my $out = `script/cpanurl Template 2.24`;
  is($out, 'http://cpan.metacpan.org/authors/id/A/AB/ABW/Template-Toolkit-2.24.tar.gz' . "\n");
}
{
  my $out = `script/cpanurl List::Util 1.27`;
  is($out, 'http://cpan.metacpan.org/authors/id/P/PE/PEVANS/Scalar-List-Utils-1.27.tar.gz' . "\n");
}
{
  my $out = `script/cpanurl PathTools-3.40`;
  is($out, 'http://cpan.metacpan.org/authors/id/S/SM/SMUELLER/PathTools-3.40.tar.gz' . "\n");
}

# Distribution
{
  my $out = `script/cpanurl libwww-perl-6.04`;
  is($out, 'http://cpan.metacpan.org/authors/id/G/GA/GAAS/libwww-perl-6.04.tar.gz' . "\n");
}

# LWP
{
  my $out = `script/cpanurl --lwp Mojolicious 3.82`;
  is($out, 'http://cpan.metacpan.org/authors/id/S/SR/SRI/Mojolicious-3.82.tar.gz' . "\n");
}

# no LWP(HTTP::Tiny)
{
  my $out = `script/cpanurl --no-lwp Mojolicious 3.82`;
  is($out, 'http://cpan.metacpan.org/authors/id/S/SR/SRI/Mojolicious-3.82.tar.gz' . "\n");
}
{
  my $out = `script/cpanurl --no-lwp Mojolicious-3.82`;
  is($out, 'http://cpan.metacpan.org/authors/id/S/SR/SRI/Mojolicious-3.82.tar.gz' . "\n");
}

# URL
{
  my $out = `script/cpanurl http://somehost.com/Foo-0.01.tar.gz`;
  is($out, 'http://somehost.com/Foo-0.01.tar.gz' . "\n");
}
{
  my $out = `script/cpanurl https://somehost.com/Foo-0.01.tar.gz`;
  is($out, 'https://somehost.com/Foo-0.01.tar.gz' . "\n");
}

# Module file
{
  my $out = `script/cpanurl -f xt/input/module1.txt`;
  is(
    $out,
    'http://cpan.metacpan.org/authors/id/S/SR/SRI/Mojolicious-3.82.tar.gz' . "\n" .
    'http://cpan.metacpan.org/authors/id/K/KI/KIMOTO/DBIx-Custom-0.23.tar.gz' . "\n"
  );
}
{
  my $out = `script/cpanurl --file xt/input/module1.txt`;
  is(
    $out,
    'http://cpan.metacpan.org/authors/id/S/SR/SRI/Mojolicious-3.82.tar.gz' . "\n" .
    'http://cpan.metacpan.org/authors/id/K/KI/KIMOTO/DBIx-Custom-0.23.tar.gz' . "\n"
  );
}
{
  my $out = `script/cpanurl -f xt/input/module2.txt`;
  is(
    $out,
    'http://cpan.metacpan.org/authors/id/S/SR/SRI/Mojolicious-3.82.tar.gz' . "\n" .
    'http://cpan.metacpan.org/authors/id/K/KI/KIMOTO/DBIx-Custom-0.23.tar.gz' . "\n"
  );
}

# use LWP or not
{
  print STDERR "lwp:";
  local $ENV{CPANURL_DEBUG} = 1;
  `script/cpanurl Mojolicious 3.82`;
}

# No moudle
{
  my $out = `script/cpanurl NotExistModule__ 0.1`;
}