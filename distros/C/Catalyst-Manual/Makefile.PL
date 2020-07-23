use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %WriteMakefileArgs = (
  NAME => 'Catalyst::Manual',
  VERSION_FROM => 'lib/Catalyst/Manual.pm',
  AUTHOR => [ 'Catalyst Contributors, see Catalyst.pm', 'Kieren Diment <zarquon@cpan.org>' ],

  META_MERGE => {
    'meta-spec' => { version => 2 },
    dynamic_config => 0,
    resources => {
      repository => {
        url => 'https://github.com/perl-catalyst/Catalyst-Manual.git',
        web => 'https://github.com/perl-catalyst/Catalyst-Manual',
        type => 'git',
      },
      bugtracker => {
        mailto => 'bug-Catalyst-Manual@rt.cpan.org',
        web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-Manual',
      },
      x_IRC => 'irc://irc.perl.org/#catalyst',
      x_MailingList => 'http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/catalyst',
    },
    x_contributors => [ # manually added, from git shortlog -e -s -n
      'Kennedy Clark <hkclark@gmail.com>',
      'Tomas Doran <bobtfish@bobtfish.net>',
      'Kieren Diment <diment@gmail.com>',
      'Karen Etheridge <ether@cpan.org>',
      'Graham Knop <haarg@haarg.org>',
      'Jonathan Rockway <jon@jrock.us>',
      'Jesse Sheidlower <jester@panix.com>',
      'Brian Cassidy <bricas@cpan.org>',
      'Caleb Cushing <xenoterracide@gmail.com>',
      'Rafael Kitover <rkitover@cpan.org>',
      'Dan Dascalescu <bigbang7@gmail.com>',
      'Jason Felds <wolfman.ncsu2000@gmail.com>',
      'Frederik Schwarzer <schwarzerf@gmail.com>',
      'Jonathan Yu <jawnsy@cpan.org>',
      'Matt S Trout <mst@shadowcat.co.uk>',
      'Breno G. de Oliveira <garu@cpan.org>',
      'Lars Dɪᴇᴄᴋᴏᴡ 迪拉斯 <daxim@cpan.org>',
      'Matthew Horsfall <wolfsage@gmail.com>',
      'Florian Ragwitz <rafl@debian.org>',
      'Jess Robinson <cpan@desert-island.me.uk>',
      'Eden Cardim <e.cardim@shadowcat.co.uk>',
      'Ricardo SIGNES <rjbs@cpan.org>',
      'Shlomi Fish <shlomif@iglu.org.il>',
      'Andrew Rodland <arodland@cpan.org>',
      'Robert \'phaylon\' Sedlacek <rs@474.at>',
      'Justin Hunter <justin.d.hunter@gmail.com>',
      'Nick Tonkin <1nickt@users.noreply.github.com>',
      'Alexander Hartmaier <abraxxa@cpan.org>',
      'Andreas Marienborg <andreas.marienborg@gmail.com>',
      'Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>',
      'Gerda Shank <gshank@cpan.org>',
      'Ian Wells <ijw@cack.org.uk>',
      'Jay Kuri <jayk@cpan.org>',
      'Mark A. Stratman <stratman@gmail.com>',
      'Mateu X. Hunter <hunter@missoula.org>',
      'Peter Karman <perl@peknet.com>',
      'sockmonk <wes.sheldahl@gmail.com>',
      'u-foka <no@se.com>',
      'Jay Hannah <jay.hannah@iinteractive.com>',
      'Eric A. Zarko <ezarko@cpan.org>',
      'Lilly An <lilly@ziprecruiter.com>',
      'Marcus Ramberg <marcus@nordaaker.com>',
      'antgel <no@se.com>',
      'kostya <kostya@cpan.org>',
      'Eisenberger Tamás <tamas@eisenberger.hu>',
      'Edwin de Graaf <egraaf@egraaf.org>',
      'Matthias Dietrich <perl@rb.ly>',
      'Alastair McGowan-Douglas <altreus@cpan.org>',
      'Paul Waring <paul@xk7.net>',
      'kthakore <thakore.kartik@gmail.com>',
      'Dominic Humphries <djh@thermeon.eu>',
      'David Steinbrunner <dsteinbrunner@pobox.com>',
      'David Schmidt <davewood@gmx.at>',
      'Ronald J Kimball <rjk@tamias.net>',
      'Ash Berlin <ash@cpan.org>',
      'Tom Feist <shabble@metavore.org>',
      'Andy Grundman <andy@hybridized.org>',
      'Ton Voon <ton.voon@opsera.com>',
      'Zsolt Zemancsik <darwick@cyberground.hu>',
      'Jonathan Otsuka <djgoku@gmail.com>',
      'Jonathan "Duke" Leto <jonathan@leto.net>',
      'KMX <kmx@cpan.org>',
      'Jay Hannah <jay@jays.net>',
      'Iñigo Tejedor Arrondo <poisonbit@gmail.com>',
    ],
  },

  META_ADD => {
    prereqs => {
      configure => {
        requires => {
          'ExtUtils::MakeMaker' => '0',
        },
      },
      runtime => {
        requires => {
          perl => '5.006',
        },
      },
      test => {
        requires => {
          'Test::More' => '0.88',
        },
      },
      develop => {
        requires => {
          'Pod::Simple' => '3.11', # L<Foo|http://foo.com> support
          'Test::Pod' => '1.14',
          'Test::Pod::Coverage' => '1.04',
        },
      },
    },
  },

  realclean => { FILES => [ 'Distar/', 'MANIFEST*' ] },
);

my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  next unless exists $WriteMakefileArgs{META_ADD}{prereqs}{$_}
           or exists $WriteMakefileArgs{$key};
  my $r = $WriteMakefileArgs{$key} = {
    %{$WriteMakefileArgs{META_ADD}{prereqs}{$_}{requires} || {}},
    %{delete $WriteMakefileArgs{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

# dynamic prereqs get added here.

$WriteMakefileArgs{MIN_PERL_VERSION} = delete $WriteMakefileArgs{PREREQ_PM}{perl} || 0;

$WriteMakefileArgs{BUILD_REQUIRES} = {
    %{$WriteMakefileArgs{BUILD_REQUIRES} || {}},
    %{delete $WriteMakefileArgs{TEST_REQUIRES}}
} if $eumm_version < 6.63_03;

$WriteMakefileArgs{PREREQ_PM} = {
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{delete $WriteMakefileArgs{BUILD_REQUIRES}}
} if $eumm_version < 6.55_01;

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

delete $WriteMakefileArgs{MIN_PERL_VERSION}
  if $eumm_version < 6.48;

delete @WriteMakefileArgs{qw(META_ADD META_MERGE)}
  if $eumm_version < 6.46;

delete $WriteMakefileArgs{LICENSE}
  if $eumm_version < 6.31;

WriteMakefile(%WriteMakefileArgs);

