use 5.006;    # our
use strict;
use warnings;

package CPAN::Testers::TailLog::Result;

our $VERSION = '0.001001';

# ABSTRACT: A single log entry from metabase.cpantesters.org

# AUTHORITY

sub new { bless $_[1], $_[0] }

sub accepted     { $_[0]->{accepted} }
sub filename     { $_[0]->{filename} }
sub grade        { $_[0]->{grade} }
sub perl_version { $_[0]->{perl_version} }
sub platform     { $_[0]->{platform} }
sub reporter     { $_[0]->{reporter} }
sub submitted    { $_[0]->{submitted} }
sub uuid         { $_[0]->{uuid} }

1;

=pod

=encoding UTF-8

=head1 NAME

CPAN::Testers::TailLog::Result - A single log entry from
metabase.cpantesters.org

=head1 DESCRIPTION

All propteries in this object are verbatim strings from upstream, with unicode
text (not bytes) where relevant.

=head1 METHODS

=head2 accepted

The time the report was accepted to C<Metabase>, verbatim.

  # {YYYY}-{MM}-{DD}T{HH}:{MM}:{SS}Z
  my $time = $result->accepted

=head2 filename

The CPAN relative path to the filename the test report is for

  # {CPANAUTHOR}/{PATH}
  my $text = $result->filename

=head2 grade

The status of the test report

  # pass|fail|na|unknown
  my $grade = $result->grade

=head2 perl_version

The version of Perl the test ran on

  # perl-vX.YY.Z
  my $pv = $result->perl_version

=head2 platform

The OS/Architecture the test ran on

  # eg: x86_64-gnukfreebsd
  my $pf = $result->platform

=head2 reporter

The person who submitted the report

  # "AuthörName"
  my $name = $result->reporter;

=head2 submitted

The submission time of the report

  # {YYYY}-{MM}-{DD}T{HH}:{MM}:{SS}Z
  my $time = $result->submitted

=head2 uuid

The unique identifier of the report

  # {HEX(8)}-{HEX(4)}-{HEX(4)}-{HEX(4)}-{HEX(12)}
  my $id = $result->uuid

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 LICENSE

This software is copyright (c) 2016 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

