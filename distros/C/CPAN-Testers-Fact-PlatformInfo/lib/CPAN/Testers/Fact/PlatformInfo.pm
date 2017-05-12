package CPAN::Testers::Fact::PlatformInfo;

use strict;
use warnings;

our $VERSION = '1.03';

# ABSTRACT: platform information on which a CPAN Testers smoker is running.

use Carp ();

use Metabase::Fact::Hash 0.016;
our @ISA = qw/Metabase::Fact::Hash/;

sub required_keys { }   # all keys are optional
sub optional_keys { qw/archname osname osvers oslabel is32bit is64bit osflag codename kernel/ }

sub content_metadata {
  my ($self) = @_;
  my $content = $self->content;
  return {
    archname    => $content->{archname} ,
    osname      => $content->{osname}   ,
    osvers      => $content->{osvers}   ,
    oslabel     => $content->{oslabel}  ,
    is32bit     => $content->{is32bit}  ,
    is64bit     => $content->{is64bit}  ,
    osflag      => $content->{osflag}   ,
    codename    => $content->{codename} ,
    kernel      => $content->{kernel}   ,
  }
}

sub content_metadata_types {
  return {
    archname    => '//str',
    osname      => '//str',
    osvers      => '//str',
    oslabel     => '//str',
    is32bit     => '//bool',
    is64bit     => '//bool',
    osflag      => '//str',
    codename    => '//str',
    kernel      => '//str',
  }
}

1;

__END__

=head1 NAME

CPAN::Testers::Fact::PlatformInfo - platform information on which a CPAN Testers smoker is running

=head1 VERSION

version 1.01

=head1 SYNOPSIS

  # assume $report is a hash of a test report created using a CPAN Testers
  # smoker, which generates metadata for the platform.
  
  my $fact = CPAN::Testers::Fact::PlatformInfo->new(
    resource => 'cpan:///distfile/RJBS/CPAN-Metabase-Fact-0.001.tar.gz',
    content     => {
      osname        => $report->{platform_info}{osname}     ,
      archname      => $report->{platform_info}{archname}   ,
      osvers        => $report->{platform_info}{osvers}     ,
      oslabel       => $report->{platform_info}{oslabel}    ,
      is32bit       => $report->{platform_info}{is32bit}    ,
      is64bit       => $report->{platform_info}{is64bit}    ,
      osflag        => $report->{platform_info}{osflag}     ,
      codename      => $report->{platform_info}{codename}   ,
      kernel        => $report->{platform_info}{kernel}
    },
  );

=head1 DESCRIPTION

Stores the platform information of the machine ruuning the CPAN Testers 
smoker.

=head1 METHODS

=over 4

=item required_keys

All keys are optional, but here in case some become mandatory.

=item optional_keys

Returns a list of theoptional keys.

=item content_metadata

The metadata values accessor.

=item content_metadata_types

The metadata values descriptors.

=back

=head1 USAGE

See L<Metabase::Fact>.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=CPAN-Testers-Fact-PlatformInfo>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHORS

  Barbie (BARBIE) <barbie@cpan.org>
  Brian McCauley (NOBULL) <nobull67@gmail.com>
  Colin Newell (NEWELLC) F<http://colinnewell.wordpress.com/>
  Jon 'JJ' Allen (JONALLEN) <jj@jonallen.info>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2011-2014 Birmingham Perl Mongers

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
