[![Actions Status](https://github.com/kan/p5-acme-prettycure/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/kan/p5-acme-prettycure/actions?workflow=ci)
# NAME

Acme::PrettyCure - All about Japanese battle heroine "Pretty Cure"

# SYNOPSIS

```perl
use Acme::PrettyCure;

# retrieve member on their teams
my @allstar =  Acme::PrettyCure->girls('AllStar');    # retrieve all
my @allstar1 = Acme::PrettyCure->girls('AllStarDX1'); # retrieve first .. fresh
my @allstar2 = Acme::PrettyCure->girls('AllStarDX2'); # retrieve first .. heart_catch
my @first    = Acme::PrettyCure->girls;
my @mh       = Acme::PrettyCure->girls('MaxHeart');
my @ss       = Acme::PrettyCure->girls('SplashStar');
my @five     = Acme::PrettyCure->girls('Five');

my $hc = Acme::PrettyCure->now; # retrieve active team members
```

# DESCRIPTION

"Acme::PrettyCure" is most famous Japanese battle heroine.

http://en.wikipedia.org/wiki/Pretty\_Cure

# REQUIREMENTS（動作環境）

**最新の安定版の Perl だけ** を対象にしています（今は Perl 5.44）。

このモジュールのコンセプトは「最新の Perl の機能を、無駄に惜しげもなく使う」ことです。`feature 'class'` やシグネチャなど、新しい Perl で入った機能や試験的な機能を、必要かどうかにかかわらず使っていきます。そのため、古い Perl で動くようにはしません。

- 新しい安定版の Perl が出たら（例年、夏ごろ）、それに合わせて対象を上げます。前の版の Perl で動き続けることは保証しません。
- CI では、最新の安定版に加えて、開発版（今は 5.45.x）でもテストしています。試験的な機能の仕様が変わるのを、早めに見つけるためです。
- 今の版は、まだ古い Perl でも動くコードのままです。これから順に、新しい機能を使う形へ書き換えていきます。

# METHODS

## girls

```perl
my @precures = Acme::PrettyCure->girls('AllStar');
```

returns `Acme::PrettyCure::Girl::Role` act objects.

## members

```
alias of girls.
```

## tv\_series

```perl
my @tv_series_names = Acme::PrettyCure->tv_series;
```

## all\_series

tv series with all movies.

```perl
my @all_series_names = Acme::PrettyCure->all_series;
```

## now

```
returns team girls when now on air.
```

# AUTHOR

Kan Fushihara &lt;kan.fushihara at gmail.com>

Kazuhiro Osawa <ko@yappo.ne.jp>

Makamaka Hannyaharamitu &lt;makamaka\[at\]cpan.org>

# SEE ALSO

`Acme::MorningMusume`, `Acme::AKB48`

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
