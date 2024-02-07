use strict;
use warnings;
use 5.006;

my %META = (
  name => 'Catalyst-Manual',
  license => 'perl_5',
  author => [
    'Catalyst Contributors, see Catalyst.pm',
    'Kieren Diment <zarquon@cpan.org>',
  ],
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
  # perl -MData::Dumper -e'$Data::Dumper::Indent = $Data::Dumper::Terse = $Data::Dumper::Trailingcomma = 1; print Dumper([map /^\s*\d+\s+(.*)/, `git shortlog -e -s -n`]);'
  x_contributors => [
    'Kennedy Clark <hkclark@gmail.com>',
    'Tomas Doran <bobtfish@bobtfish.net>',
    'Kieren Diment <diment@gmail.com>',
    'Karen Etheridge <ether@cpan.org>',
    'Graham Knop <haarg@haarg.org>',
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
    'Lars Dɪᴇᴄᴋᴏᴡ 迪拉斯 <daxim@cpan.org>',
    'Matt S Trout <mst@shadowcat.co.uk>',
    'Florian Ragwitz <rafl@debian.org>',
    'Jess Robinson <cpan@desert-island.me.uk>',
    'Matthew Horsfall <wolfsage@gmail.com>',
    'Andrew Rodland <andrew@cleverdomain.org>',
    'Artem Konev <artem.konev@nginx.com>',
    'Eden Cardim <edencardim@gmail.com>',
    'Justin Hunter <justin.d.hunter@gmail.com>',
    'Ricardo Signes <rjbs@semiotic.systems>',
    'Robert \'phaylon\' Sedlacek <rs@474.at>',
    'Shlomi Fish <shlomif@iglu.org.il>',
    'antgel <no@se.com>',
    'Alexander Hartmaier <abraxxa@cpan.org>',
    'Andreas Marienborg <omega@palle.net>',
    'Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>',
    'Gerda Shank <gerda.shank@gmail.com>',
    'Ian Wells <ijw@cack.org.uk>',
    'Jay Hannah <jay@jays.net>',
    'Jay Kuri <jayk@cpan.org>',
    'Mark A. Stratman <stratman@gmail.com>',
    'Mateu X. Hunter <hunter@missoula.org>',
    'Nick Tonkin <1nickt@users.noreply.github.com>',
    'Peter Karman <perl@peknet.com>',
    'Wes Sheldahl <wes.sheldahl@gmail.com>',
    'Alastair McGowan-Douglas <altreus@cpan.org>',
    'Andy Grundman <andy@hybridized.org>',
    'Ash Berlin <ash@cpan.org>',
    'David Schmidt <mail@davidschmidt.at>',
    'David Steinbrunner <dsteinbrunner@pobox.com>',
    'Dominic Humphries <djh@thermeon.eu>',
    'Edwin de Graaf <egraaf@egraaf.org>',
    'Eisenberger Tamás <tamas@eisenberger.hu>',
    'Eric A. Zarko <ezarko@cpan.org>',
    'Iñigo Tejedor Arrondo <poisonbit@gmail.com>',
    'Jonathan "Duke" Leto <jonathan@leto.net>',
    'Jonathan Otsuka <djgoku@gmail.com>',
    'Kartik Thakore <thakore.kartik@gmail.com>',
    'Kostya Ten <kostya@cpan.org>',
    'Lilly An <lilly@ziprecruiter.com>',
    'Marcus Ramberg <marcus@nordaaker.com>',
    'Matthias Dietrich <perl@rb.ly>',
    'Paul Waring <paul@xk7.net>',
    'Ronald J Kimball <rjk@tamias.net>',
    'Tom Feist <shabble@metavore.org>',
    'Ton Voon <ton.voon@opsera.com>',
    'Zsolt Zemancsik <darwick@cyberground.hu>',
    'kmx <kmx@cpan.org>',
  ],
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
);

my %MM_ARGS = ();

## BOILERPLATE ###############################################################
require ExtUtils::MakeMaker;
(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;
my $mymeta        = $eumm_version >= 6.57_02;
my $mymeta_broken = $mymeta && $eumm_version < 6.57_07;

($MM_ARGS{NAME} = $META{name}) =~ s/-/::/g;
($MM_ARGS{VERSION_FROM} = "lib/$MM_ARGS{NAME}.pm") =~ s{::}{/}g;
$META{license} = [ $META{license} ]
  if $META{license} && !ref $META{license};
$MM_ARGS{LICENSE} = $META{license}[0]
  if $META{license} && $eumm_version >= 6.30;
$MM_ARGS{NO_MYMETA} = 1
  if $mymeta_broken;
$MM_ARGS{META_ADD} = { 'meta-spec' => { version => 2 }, %META }
  unless -f 'META.yml';
$MM_ARGS{PL_FILES} ||= {};
$MM_ARGS{NORECURS} = 1
  if not exists $MM_ARGS{NORECURS};

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  my $r = $MM_ARGS{$key} = {
    %{$META{prereqs}{$_}{requires} || {}},
    %{delete $MM_ARGS{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

$MM_ARGS{MIN_PERL_VERSION} = delete $MM_ARGS{PREREQ_PM}{perl} || 0;

delete $MM_ARGS{MIN_PERL_VERSION}
  if $eumm_version < 6.47_01;
$MM_ARGS{BUILD_REQUIRES} = {%{$MM_ARGS{BUILD_REQUIRES}}, %{delete $MM_ARGS{TEST_REQUIRES}}}
  if $eumm_version < 6.63_03;
$MM_ARGS{PREREQ_PM} = {%{$MM_ARGS{PREREQ_PM}}, %{delete $MM_ARGS{BUILD_REQUIRES}}}
  if $eumm_version < 6.55_01;
delete $MM_ARGS{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

ExtUtils::MakeMaker::WriteMakefile(%MM_ARGS);
## END BOILERPLATE ###########################################################
