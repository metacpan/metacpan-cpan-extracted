package CPAN::Testers::WWW::Reports::Parser;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.06';

#----------------------------------------------------------------------------
# Library Modules

use Carp;

#----------------------------------------------------------------------------
# Variables

my $WEB = 'http://www.cpantesters.org/cpan/report/';
my @valid_fields = qw(  id distribution dist distname version distversion perl 
                        state status grade action osname ostext osvers platform 
                        archname url csspatch cssperl guid );
my %valid_fields = map {$_ => 1} @valid_fields;

#----------------------------------------------------------------------------
# The Application Programming Interface

sub new {
    my $class = shift;
    my %hash  = @_;

    croak "No data format specified\n"                      unless($hash{format});
    croak "Unknown data format specified\n"                 unless($hash{format} =~ /^(yaml|json)$/i);
    croak "Must specify a file or data block to parse\n"    unless($hash{data} || $hash{file});
    croak "Cannot access file [$hash{file}]\n"              if(defined $hash{file} && ! -f $hash{file});                    

    my $self = {
        'format'    => uc $hash{'format'},
        'data'      =>    $hash{'data'},
        'file'      =>    $hash{'file'},
        'objects'   =>    $hash{'objects'},
    };
    bless $self, $class;

    if($self->{objects}) {
        eval "use CPAN::Testers::WWW::Reports::Report";
    }

    my $parser = 'CPAN::Testers::WWW::Reports::Parser::' . $self->{'format'};
    eval "use $parser";
    croak "Cannot access $self->{'format'} parser, have you installed the necessary support modules?\n"
        if($@);

    $self->{parser} = $parser->new();
    $self->{parser}->register( file => $self->{file}, data => $self->{data} );
    $self->{current} = {};

    return $self;
}

sub DESTROY {
    my $self = shift;
}

sub filter {
    my $self = shift;

    if(@_) {
        $self->{all} = $_[0] =~ /^ALL$/i ? shift : 0;
        $self->{fields}{$_} = 1 for(grep {$valid_fields{$_}} @_);

    # if no arguments, reset to default
    } else {
        $self->{all} = 1;
        $self->{fields} = {};
    }
}

# full data set methods

sub reports {
    my $self = shift;

    $self->filter(@_)  if(@_);

#use Data::Dumper;
#print STDERR (Dumper($self->{fields}));

    my $data = $self->{parser}->raw_data();
    return $data    unless(defined $self->{fields});

    no strict 'refs';

    for my $report (@$data) {
        $self->{current} = $report;
        for my $field (keys %{ $self->{fields} }) {
            #print STDERR "field=$field\n";
            eval { $report->{$field} = $self->$field(); };
        }

        next    if($self->{all});

        for my $key (keys %$report) {
            delete $report->{$key}  unless($self->{fields}{$key});
        }
    }

    return $data;
}


# iterate through data set

sub report {
    my $self = shift;
    
    unless($self->{loaded}) {
        $self->{reports} = $self->{parser}->raw_data();
        $self->{loaded} = 1;
    }

    return  unless(scalar(@{ $self->{reports} }));

    $self->{current} = shift @{ $self->{reports} };
    my %report = map {$_ => $self->{current}{$_}} keys %{$self->{current}};

    if(scalar(keys %{ $self->{fields} })) {
        no strict 'refs';

        for my $field (keys %{ $self->{fields} }) {
            eval { $report{$field} = $self->$field(); };
        }

        unless($self->{all}) {
            for my $key (keys %report) {
                delete $report{$key}  unless($self->{fields}{$key});
            }
        }
    }

    if($self->{objects}) {
        my $rep = CPAN::Testers::WWW::Reports::Report->new(\%report);
        return $rep;
    }

    return \%report;
}

sub reload {
    my $self = shift;
    $self->{loaded} = 0;
}


# transpose legacy field names to current field names

sub guid         { my $self = shift; return $self->{current}->{guid}         }
sub id           { my $self = shift; return $self->{current}->{id}           }
sub distribution { my $self = shift; return $self->{current}->{distribution} }
sub dist         { my $self = shift; return $self->{current}->{distribution} }
sub distname     { my $self = shift; return $self->{current}->{distribution} }
sub version      { my $self = shift; return $self->{current}->{version}      }
sub distversion  { my $self = shift; return $self->{current}->{distversion}  }
sub perl         { my $self = shift; return $self->{current}->{perl}         }

sub state        { my $self = shift; return $self->{current}->{state}        }
sub status       { my $self = shift; return $self->{current}->{status}       }
sub grade        { my $self = shift; return $self->{current}->{status}       }
sub action       { my $self = shift; return $self->{current}->{status}       }

sub osname       { my $self = shift; return $self->{current}->{osname}       }
sub ostext       { my $self = shift; return $self->{current}->{ostext}       }
sub osvers       { my $self = shift; return $self->{current}->{osvers}       }
sub platform     { my $self = shift; return $self->{current}->{platform}     }
sub archname     { my $self = shift; return $self->{current}->{platform}     }

sub url          { my $self = shift; return $WEB . ($self->{current}->{guid} || $self->{current}->{id}) }

sub csspatch     { my $self = shift; return $self->{current}->{csspatch}     }
sub cssperl      { my $self = shift; return $self->{current}->{cssperl}      }


q{ another hope, another dream, another truth ... installed by the machine };

__END__

=head1 NAME

CPAN::Testers::WWW::Reports::Parser - CPAN Testers reports data parser

=head1 SYNOPSIS

The parser can be used in two different ways, either by accessing each report
as a hashref (each field having a key/value pair entry) or via an object.

=head2 The hashref access API:

  use CPAN::Testers::WWW::Reports::Parser;

  my $obj = CPAN::Testers::WWW::Reports::Parser->new(
        format => 'YAML',   # or 'JSON'
        file   => $file     # or data => $data
  );

  # iterator, filtering field names
  $obj->filter(@fields);
  $obj->filter('ALL', @fields);
  while( my $data = $obj->report() ) {
      # automatically populates the returned hash with the fields required.
      # removes any field values not requested, unless the first value in the 
      # list is the string 'ALL'.
  }

  $obj->filter();   # reset to default original hash

  # note that filter() will also affect the reports() method.

  # full array of hashes
  my $data = $obj->reports();              # array of original hashes
  my $data = $obj->reports(@fields);       # array of amended hashes
  my $data = $obj->reports('ALL',@fields); # array of original + amended hashes

=head2 The object access API:

  use CPAN::Testers::WWW::Reports::Parser;

  # if 'objects' was set, then $obj->report() will return
  # CPAN::Testers::WWW::Reports::Report objects instead of a hashref

  my $obj = CPAN::Testers::WWW::Reports::Parser->new(
        format  => 'YAML',   # or 'JSON'
        file    => $file     # or data => $data
        objects => 1,        # Optional, works with $obj->report()
  );

  # iterator, accessing aternate field names
  while( my $data = $obj->report() ) {
      my $dist = $obj->distribution(); # or $obj->dist(), or $obj->distname()
      ...

      # note that the object is used to reference the methods retrieving
      # the individual field names, as the $data variable is a hashref to a
      # hash of a single report.
  }

=head1 DESCRIPTION

This distribution is used to extract the data from either a JSON or a YAML file
containing metadata regarding reports submitted by CPAN Testers, and available 
from the CPAN Testers website.

=head1 INTERFACE

=head2 The Constructor

=over

=item * new

Instatiates the object CPAN::Testers::WWW::Reports::Parser:

  my $obj = CPAN::Testers::WWW::Reports::Parser->new(
    format  => 'YAML',  # or 'JSON'
    file    => $file    # or data => $data
    objects => 1        # optional, uses hash API if absent
  );

=back

=head2 Report Methods

=over

=item * filter

Adds filtering to the report, if you require a different set of field names
than exist in the default report. Add 'ALL' as the first entry to retain the
default field names, and merely extend the data set.

To reset filtering, simply call filter() with no arguments.

=item * reports

Returns the full data set as an array reference to a set of hashes. Can take
arguments as per filter(), or will used any previously set filter() state.

=item * report

Returns a single report data hash. Use filter() to set what field names you
require, otherwise the default data hash is returned.

=item * reload

The report method cycles round the current data set. If you wish to repeat the
cycle, call reload to reset to the beginning of the data set.

=back

=head2 Field methods

=over

=item * id

Returns the current Report NNTP ID. Note that Metabase reports will always
return a zero value.

=item * guid

Returns the current Report GUID. This is the full Metabase GUID.

=item * distribution

=item * dist

=item * distname

Variations of the distribution name.

=item * version

Distribution version.

=item * distversion

Distribution name and version.

=item * perl

Version of perl used to test.

=item * state

=item * status

=item * grade

=item * action

Variations on the grade of the report. Note that 'state' represents the lower
case version, while the others are upper case.

=item * osname

String extracted representing the Operating System name.

=item * ostext

Normalised version of the Operating System name, where known, as occasionally
the name may not correctly reflect a print friendly version of the name, or 
even the actual name.

=item * osvers

Operating System version, if known.

=item * platform

=item * archname

The architecture name of the Operating System installed, as this usually
gives more information about the setup of the smoke box, such as whether the
OS is 64-bit or not.

=item * url

The current path to an online version of the individual report.

=item * csspatch

Primarily used for web, provides a quick indicator as to whether this release
was tested with a patched version of perl. Possible values are:

  pat - patched
  unp - unpatched

=item * cssperl

Primarily used for web, provides a quick indicator as to whether this release
was tested with a development version of perl. Possible values are:

  rel - official release
  dev - development release (i.e. 5.7.*, 5.9.* or 5.11.*)

=back

Please note that this distribution aims to aid backwards compatibility regards
the contents of the reports data. If the data ever needs to change, then
upgrading to the latest release of this distribution, should enable you to
continue using older, depreciated field names within your code.

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

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2014 Barbie <barbie@cpan.org>

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
