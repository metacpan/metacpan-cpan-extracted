package Labyrinth::Plugin::CPAN::Distros;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '3.59';

=head1 NAME

Labyrinth::Plugin::CPAN::Distros - Plugin to handle Distribution pages.

=cut

#----------------------------------------------------------------------------
# Libraries

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::Plugin::CPAN;
use Labyrinth::Variables;
use Labyrinth::Writer;

use JSON::XS;

#----------------------------------------------------------------------------
# Public Interface Functions

=head1 METHODS

=head2 Public Interface Methods

=over 4

=item List

List distributions for a given letter.

=item Reports

List reports for a distribution.

=back

=cut

sub List {
    ($tvars{letter}) = ($cgiparams{name} =~ /^([A-Z])/i);
    $tvars{letter} = uc $tvars{letter};
    return  unless($tvars{letter});

    my @rows = $dbi->GetQuery('hash','GetDistros',"$tvars{letter}%");
    my @dists = map {$_->{dist}} @rows;
    $tvars{list} = \@dists  if(@dists);
}

sub Reports {
    my $cpan = Labyrinth::Plugin::CPAN->new();
    $cpan->Configure();

    my $symlinks = $cpan->symlinks();
    $cgiparams{name} = $symlinks->{$cgiparams{name}}  if($symlinks->{$cgiparams{name}});

    $tvars{distribution} = $cgiparams{name};
    $tvars{letter} = substr($cgiparams{name},0,1);

    # does author exist?
    my @rows = $dbi->GetQuery('hash','FindDistro',{dist => $cgiparams{name}});
    unless(@rows) {
        $tvars{errcode} = 'NEXT';
        $tvars{command} = 'cpan-distunk';
        return;
    }

    # get author summary
    my @summary = $dbi->GetQuery('hash','GetDistroSummary',$cgiparams{name});
    unless(@summary) {
        unless($settings{crawler}) {
            $dbi->DoQuery('PushDistro',$cgiparams{name});
            $tvars{update} = 1;
        }
        $tvars{perlvers}    = $cpan->mklist_perls;
        $tvars{osnames}     = $cpan->osnames;
        return;
    }

    # if existing page requests, add another to improve rebuild time
    @rows = $dbi->GetQuery('array','GetDistroRequests',$cgiparams{name});
    if(@rows && $rows[0]->[0] > 0) {
        unless($settings{crawler}) {
            $dbi->DoQuery('PushDistro',$cgiparams{name});
            $tvars{update} = 1;
        }
    }

    # decode from JSON string
    my $parms = decode_json($summary[0]->{dataset});
    for my $key (keys %$parms) { $tvars{$key} = $parms->{$key}; }
    $tvars{processed} = formatDate(8,$parms->{processed}) if($parms->{processed});
}

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2008-2017 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
