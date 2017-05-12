package CPAN::Testers::WWW::Reports::Report;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.06';

#----------------------------------------------------------------------------
# Library Modules

use Carp;
our $AUTOLOAD;

#----------------------------------------------------------------------------
# Variables

my @methods = (
    "ostext",       "osvers",   "perl",        "platform",
    "version",      "csspatch", "distversion", "id",
    "status",       "state",    "cssperl",     "dist",
    "distribution", "osname",   "guid",        "grade",
    "archname",     "action",   "url"
);
my %permitted_methods = map { $_ => 1 } @methods;

#----------------------------------------------------------------------------
# The Application Programming Interface

sub new {
    my ( $class, $self ) = @_;

    bless $self, 'CPAN::Testers::WWW::Reports::Report';

    $self->{_permitted} = \%permitted_methods;

    return $self;
}

sub DESTROY {}

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self)
        or croak "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;    # strip fully-qualified portion

    unless ( exists $self->{_permitted}->{$name} ) {
        croak "Can't access `$name' field in class $type";
    }

    if (@_) {
        return $self->{$name} = shift;
    } else {
        return $self->{$name};
    }
}

1;

__END__

=head1 NAME

CPAN::Testers::WWW::Reports::Report

=head1 SYNOPSIS

  use CPAN::Testers::WWW::Reports::Parser;

  my $obj = CPAN::Testers::WWW::Reports::Parser->new(
        format  => 'YAML',  # or 'JSON'
        file    => $file    # or data => $data
        objects => 1,       # Optional, works with $obj->report()
  );

  # iterator, accessing aternate field names
  while( my $report = $obj->report() ) {
      $report->action();
      $report->archname();
      $report->csspatch(); 
      $report->cssperl();
      $report->dist();
      $report->distribution(); 
      $report->distversion(); 
      $report->grade();
      $report->guid();
      $report->id();
      $report->osname();
      $report->ostext();       
      $report->osvers();
      $report->perl();        
      $report->platform();
      $report->state();    
      $report->status();     
      $report->url();      
      $report->version();      
  }

=head1 DESCRIPTION

This distribution is used to extract the data from either a JSON or a YAML file
containing metadata regarding reports submitted by CPAN Testers, and available 
from the CPAN Testers website.

=head1 INTERFACE

=head2 The Constructor

=over

=item * new

Instatiates the object CPAN::Testers::WWW::Reports::Report:

  my $report = CPAN::Testers::WWW::Reports::Report->new(\%report);

=back

=head2 Report Methods

All the following methods are available as per the hash API listed in 
CPAN::Testers::WWW::Reports::Parser.

=over

=item * action

=item * archname

=item * csspatch

=item * cssperl

=item * dist

=item * distribution

=item * distversion

=item * grade

=item * guid

=item * id

=item * osname

=item * ostext

=item * osvers

=item * perl

=item * platform

=item * state

=item * status

=item * url

=item * version

=back

=head1 CPAN TESTERS FUND

CPAN Testers wouldn't exist without the help and support of the Perl 
community. However, since 2008 CPAN Testers has grown far beyond the 
expectations of it's original creators. As a consequence it now requires
considerable funding to help support the infrastructure.

In early 2012 the Enlightened Perl Organisation very kindly set-up a
CPAN Testers Fund within their donatation structure, to help the project
cover the costs of servers and services.

If you would like to donate to the CPAN Testers Fund, please follow the link
below to the Enlightened Perl Organisation's donation site.

F<https://members.enlightenedperl.org/drupal/donate-cpan-testers>

If your company would like to support us, you can donate financially via the
fund link above, or if you have servers or services that we might use, please
send an email to admin@cpantesters.org with details.

Our full list of current sponsors can be found at our I <3 CPAN Testers site.

F<http://iheart.cpantesters.org>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT: http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-WWW-Reports-Parser

=head1 SEE ALSO

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>,
F<http://blog.cpantesters.org/>

=head1 AUTHOR

  Barbie <barbie@cpan.org> 2009-present

  Original code for this module submitted by 
  Leo Lapworth (Ranguard) <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2014 Barbie <barbie@cpan.org>

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
