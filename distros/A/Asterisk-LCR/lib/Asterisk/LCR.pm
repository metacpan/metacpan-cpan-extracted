package Asterisk::LCR;
use warnings;
use strict;

our $VERSION = '0.08';

1;

__END__

=head1 NAME

Asterisk::LCR - Least Cost Routing for Asterisk


=head1 SYNOPSIS

Asterisk::LCR is an open-source, Perl-based collection of tools to help you
manage efficiently multiple VoIP providers with your Asterisk installation.

It attempts to be sort of clean, simple and well documented.

Speaking of documentation, it's probably best if you go read
http://ykoz.net/intl/lcr/ since I maintain it there.


=head1 CONFIGURATION

Once Asterisk::LCR is installed, you need to write a configuration file.

  $] cat /etc/asterisk-lcr.cfg
  
  # Asterisk::LCR supports pluggable storage backend, so it's possible
  # to write MySQL or other storage backend mechanisms one day.
  [storage]
  package  = Asterisk::LCR::Storage::DiskBlob.pm
  
  # Asterisk::LCR supports pluggable rates comparing backend, so you
  # could write one which simulates costs against actual traffic for
  # example.
  [comparer]
  package  = Asterisk::LCR::Comparer::XERAND
  currency = eur
  
  # Asterisk::LCR supports pluggable dialing strategies. Currently there is
  # 'MinCost' which tries the absolutely cheapest route, and 'MinTime' which
  # tries the $n cheapest providers simultaneously.
  [dialer]
  package  = Asterisk::LCR::Dialer::MinCost
  locale   = fr 
  
  # Finally, you need to define which providers rates you want to import. 
  [import:voipjet]
  package  = Asterisk::LCR::Importer::VoIPJet
  dial     = us IAX2/login@voipjet/REPLACEME
  
  [import:nufone]
  package  = Asterisk::LCR::Importer::NuFone
  dial     = us IAX2/login@NuFone/REPLACEME

Let's examine the few sections of this configuration file:


=head2 comparer section

There needs to be a configuration section named [comparer], which defines what
comparing strategy to use.

  [comparer]
  package  = Asterisk::LCR::Comparer::XERAND
  currency = eur

You can switch comparing strategies using the 'package' attribute. At the
moment of this writing there are only two packages:

You can write you own comparer modules by subclassing the
L<Asterisk::LCR::Comparer> package.


=head3 comparer - Asterisk::LCR::Comparer::Dummy

Compares rates without paying attentions to details like currency, connection charge or per minute billing.

Pretty dumb, but useful to see how things work and for debugging.


=head3 comparer - Asterisk::LCR::Comparer::XERAND

Compares rates by converting currency using XE's website.

Then, compares, say, a 30/6 with a 1/1 rate by running a simulation of how much
it would actually cost with calls of random value between 0 and 200 seconds.


=head2 dialer section

You can choose between two strategies:


=head3 dialer - Asterisk::LCR::Dialer::MinCost

This strategy minimizes cost by trying from cheapest to most expensive provider
for any given route, in the limit of 3 providers.

  [dialer]
  package  = Asterisk::LCR::Dialer::MinCost
  locale   = fr
  limit    = 3

=head3 dialer - Asterisk::LCR::Dialer::MinTime

This strategy minimizes PDD (Post-Dialing-Delay) by trying dialing out the 3
cheapest providers at the same time.

  [dialer]
  package  = Asterisk::LCR::Dialer::MinCost
  locale   = fr
  limit    = 3


=head2 import modules

ATTENTION: ALL import sections must be named [import:<something>] and ALL of
them must have a unique name.

These modules are used to import / download rates from various providers. The
following modules are available.


=head3 import - Asterisk::LCR::Import::VoIPJet

Import module for VoIPJet.

  [import:voipjet]
  package  = Asterisk::LCR::Importer::VoIPJet
  dial     = us IAX2/login@voipjet/REPLACEME

Note the 'dial' parameter which is a dial template. In this example, 'us'
indicate that VoIPJet uses US style dialing and IAX2/login@voipjet/REPLACEME is
a dial template which needs to be replaced with your own login. REPLACEME is
automagically replaced with the right "stuff" when the dialplan is generated.

This dial template assumes that voipjet's peer definition is placed under
[voipjet] in iax.conf.

Supported providers:

=over

=item Asterisk::LCR::Importer::NuFone

=item Asterisk::LCR::Importer::PlainVoIP

=item Asterisk::LCR::Importer::RichMedium

=item Asterisk::LCR::Importer::VoIPJet

=back

Providers! Send a mail to jhiver@ykoz.net to arrange for your rates to be
readily importable into Asterisk::LCR. 


=head1 USAGE

First you need to create a working directory in which you will use the LCR tools.

mkdir /tmp/lcrstuff

Once you have written your configuration file, you can do three things:

=head2 STEP 1 : Import your provider's rates

  cd /tmp/lcr
  asterisk-lcr-import

This will import all the providers you have defined in the [provider:something]
sections and write them onto disk in a canonical format.


=head2 STEP 2 : Generate the LCR database tree

  cd /tmp/lcr
  asterisk-lcr-build

This will generate a <prefix> => [ list of sorted rates ] tree from the rates
which you have imported.


=head2 STEP 3 : Generate your optimized dialplan

  cd /tmp/lcr
  asterisk-lcr-dialplan >/etc/asterisk/lcr-dialplan.conf

This will generate an optimized dialplan which you can cut and paste (or more
likely include) in your Asterisk's dialplan.


=head1 Locales

Asterisk::LCR is capable of generating dialplans which implement your local
dialing conventions.

Locales are located in text files which can be found in this distribution under
./lib/Asterisk/LCR/Locale/

At the time of this writing there are two implemented translation tables:
us.txt (for US-style dialing) and fr.txt (for France + overseas departments
dialing).

Feel free to submit your own translations tables to me! I will add them in the
distribution.

US Locale translation tables:

  "011"   ""         # International prefixes are removed
  "1"     "1"        # If it start with a '1', then it's all good


FR Locale translation tables:

The remains of what used to be the 'French Empire' make things a little more complicated...

  # local prefix  <tab>   global number replacement
  
  "00"    ""         # international prefix is replaced by nothing, i.e 0044X. => 44X.
  
  "0262"  "262262"   # These prefixes are for overseas department, which within France are
  "0692"  "262692"   # dialed as a national number but have separate country codes at the
  "0590"  "590590"   # international telephony level
  "0690"  "590690"
  "0594"  "594594"
  "0694"  "594694"
  "0596"  "596596"
  "0696"  "596696"
  
  "0"     "33"       # 0X. => 0033X.


=head1 LICENSE

  Copyright 2006 - Jean-Michel Hiver - All Rights Reserved

  Asterisk::LCR is under the GPL license. See the LICENSE file for details.

  Mailing list: not yet. Someone fancy setting one up for me?
  Contact: jhiver@ykoz.net
