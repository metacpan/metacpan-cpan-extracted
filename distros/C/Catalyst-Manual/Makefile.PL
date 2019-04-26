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
        # r/w: catagits@git.shadowcat.co.uk:Catalyst-Manual.git
        url => 'git://git.shadowcat.co.uk/catagits/Catalyst-Manual.git',
        web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=catagits/Catalyst-Manual.git',
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
      'Jonathan Rockway <jon@jrock.us>',
      'Jesse Sheidlower <jester@panix.com>',
      'Brian Cassidy <bricas@cpan.org>',
      'Caleb Cushing <xenoterracide@gmail.com>',
      'Dan Dascalescu <bigbang7@gmail.com>',
      'Rafael Kitover <rkitover@cpan.org>',
      'Jason Felds <wolfman.ncsu2000@gmail.com>',
      'Frederik Schwarzer <schwarzerf@gmail.com>',
      'Jonathan Yu <jawnsy@cpan.org>',
      'Breno G. de Oliveira <garu@cpan.org>',
      'Matt S Trout <mst@shadowcat.co.uk>',
      'Lars Dɪᴇᴄᴋᴏᴡ 迪拉斯 <daxim@cpan.org>',
      'Jess Robinson <cpan@desert-island.me.uk>',
      'Florian Ragwitz <rafl@debian.org>',
      'Eden Cardim <e.cardim@shadowcat.co.uk>',
      'Andrew Rodland <arodland@cpan.org>',
      'Justin Hunter <justin.d.hunter@gmail.com>',
      'Matthew Horsfall <wolfsage@gmail.com>',
      'Ricardo SIGNES <rjbs@cpan.org>',
      'Robert \'phaylon\' Sedlacek <rs@474.at>',
      'Shlomi Fish <shlomif@iglu.org.il>',
      'Jay Kuri <jayk@cpan.org>',
      'u-foka <no@se.com>',
      'Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>',
      'Alexander Hartmaier <abraxxa@cpan.org>',
      'Peter Karman <perl@peknet.com>',
      'Andreas Marienborg <andreas.marienborg@gmail.com>',
      'Gerda Shank <gshank@cpan.org>',
      'Ian Wells <ijw@cack.org.uk>',
      'Mark A. Stratman <stratman@gmail.com>',
      'sockmonk <wes.sheldahl@gmail.com>',
      'Mateu X. Hunter <hunter@missoula.org>',
      'Ash Berlin <ash@cpan.org>',
      'Marcus Ramberg <marcus@nordaaker.com>',
      'Andy Grundman <andy@hybridized.org>',
      'kostya <kostya@cpan.org>',
      'Matthias Dietrich <perl@rb.ly>',
      'Paul Waring <paul@xk7.net>',
      'kthakore <thakore.kartik@gmail.com>',
      'Ronald J Kimball <rjk@tamias.net>',
      'Tom Feist <shabble@metavore.org>',
      'Ton Voon <ton.voon@opsera.com>',
      'Zsolt Zemancsik <darwick@cyberground.hu>',
      'Iñigo Tejedor Arrondo <poisonbit@gmail.com>',
      'Eric A. Zarko <ezarko@cpan.org>',
      'Jay Hannah <jay@jays.net>',
      'Eisenberger Tamás <tamas@eisenberger.hu>',
      'Edwin de Graaf <egraaf@egraaf.org>',
      'Jonathan "Duke" Leto <jonathan@leto.net>',
      'Jonathan Otsuka <djgoku@gmail.com>',
      'Alastair McGowan-Douglas <altreus@cpan.org>',
      'Dominic Humphries <djh@thermeon.eu>',
      'antgel <no@se.com>',
      'KMX <kmx@cpan.org>',
      'David Steinbrunner <dsteinbrunner@pobox.com>',
      'David Schmidt <davewood@gmx.at>',
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

