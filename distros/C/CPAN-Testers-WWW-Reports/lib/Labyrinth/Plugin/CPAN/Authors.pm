package Labyrinth::Plugin::CPAN::Authors;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '3.57';

=head1 NAME

Labyrinth::Plugin::CPAN::Authors - Plugin to handle Author pages.

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

=item Status

Generate the status report

=item Basic

Provides basic components for pages. 

Currently creates a list of all known perl versions and operating systems.

=item List

List authors for a given letter.

=item Reports

List reports for authors dists.

=back

=cut

sub Status {
    my @rows = $dbi->GetQuery('hash','StatusRequest');
    $tvars{status} = $rows[0]	if(@rows);

    my @max = $dbi->GetQuery('array','MaxStatReport');
    if(@max) {
        my @rep = $dbi->GetQuery('hash','GetStatReport',$max[0]->[0]);
        if(@rep) {
            my @date = $rep[0]->{fulldate} =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})/;
            $rep[0]->{date} = sprintf "%04d-%02d-%02d %02d:%02d:00", @date;
            $tvars{report} = $rep[0];
        }
    }
}

sub Basic {
    my $cpan = Labyrinth::Plugin::CPAN->new();
    $cpan->Configure();

    $tvars{perlvers}    = $cpan->mklist_perls;
    $tvars{osnames}     = $cpan->osnames;
}

sub List {
    ($tvars{letter}) = ($cgiparams{name} =~ /^([A-Z])/i);
    $tvars{letter} = uc $tvars{letter};
    return  unless($tvars{letter});

    my @rows = $dbi->GetQuery('hash','GetAuthors',"$tvars{letter}%");
    my @authors = map {$_->{author}} @rows;
    $tvars{list} = \@authors  if(@authors);
}

sub Reports {
    my $cpan = Labyrinth::Plugin::CPAN->new();
    $cpan->Configure();

    $tvars{author} = $cgiparams{name};
    $tvars{letter} = substr($cgiparams{name},0,1);

    # does author exist?
    my @rows = $dbi->GetQuery('hash','FindAuthor',$cgiparams{name});
    unless(@rows) {
        $tvars{errcode} = 'NEXT';
        $tvars{command} = 'cpan-authunk';
        return;
    }

    # get author summary
    my @summary = $dbi->GetQuery('hash','GetAuthorSummary',$cgiparams{name});
    unless(@summary) {
        #unless($settings{crawler}) {
            $dbi->DoQuery('PushAuthor',$cgiparams{name});
            $tvars{update} = 1;
        #}
        $tvars{perlvers}    = $cpan->mklist_perls;
        $tvars{osnames}     = $cpan->osnames;
        return;
    }

    # if existing page requests, add another to improve rebuild time
    @rows = $dbi->GetQuery('array','GetAuthorRequests',$cgiparams{name});
    if(@rows && $rows[0]->[0] > 0) {
        #unless($settings{crawler}) {
            $dbi->DoQuery('PushAuthor',$cgiparams{name});
            $tvars{update} = 1;
        #}
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

  Copyright (C) 2008-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
