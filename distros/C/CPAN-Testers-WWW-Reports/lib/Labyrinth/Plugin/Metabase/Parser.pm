package Labyrinth::Plugin::Metabase::Parser;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '3.60';

=head1 NAME

Labyrinth::Plugin::Metabase::Parser - Plugin to parse Metabase Report pages.

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

use CPAN::Testers::Common::Article;
use Data::FlexSerializer;

#----------------------------------------------------------------------------
# Variables

my $serializer = Data::FlexSerializer->new( detect_compression => 1 );

#----------------------------------------------------------------------------
# Public Interface Functions

=head1 METHODS

=head2 Public Interface Methods

=over 4

=item View

View a specific report.

=back

=cut

sub View {
    if($cgiparams{id} =~ /^\d+$/) {
        _parse_nntp_report();
    } elsif($cgiparams{id} =~ /^[-\w]+$/) {
        _parse_guid_report();
    } else {
        $tvars{errcode} = 'NEXT';
        $tvars{command} = 'cpan-distunk';
    }

    if($cgiparams{raw}) {
        $tvars{article}{raw} = $cgiparams{raw};
        $tvars{realm} = 'popup';
    }
}

#----------------------------------------------------------------------------
# Private Interface Functions

sub _parse_nntp_report {
    my @rows = $dbi->GetQuery('hash','GetArticle',$cgiparams{id});
    unless(@rows) {
        $tvars{article}{id} = $cgiparams{id};
        return;
    }

    $tvars{article} = $rows[0];
    ($tvars{article}{head},$tvars{article}{body}) = split(/\n\n/,$rows[0]->{article},2);

    my $object = CPAN::Testers::Common::Article->new($rows[0]->{article});
    return  unless($object);

    $tvars{article}{body}    = $object->body;
    $tvars{article}{subject} = $object->subject;
    $tvars{article}{from}    = $object->from;
    $tvars{article}{from}    =~ s/\@.*//;
    $tvars{article}{post}    = $object->postdate;
    $tvars{article}{date}    = $object->date;

    return      if($tvars{article}{subject} =~ /Re:/i);
    return      unless($tvars{article}{subject} =~ /(CPAN|FAIL|PASS|NA|UNKNOWN)\s+/i);

    my $state = lc $1;

    if($state eq 'cpan') {
        if($object->parse_upload()) {
            $tvars{article}{dist}    = $object->distribution;
            $tvars{article}{version} = $object->version;
            $tvars{article}{author}  = $object->author;
            $tvars{article}{letter}  = substr($tvars{article}{dist},0,1);
        }
    } else {
        if($object->parse_report()) {
            $tvars{article}{dist}    = $object->distribution;
            $tvars{article}{version} = $object->version;
            $tvars{article}{author}  = $object->from;
            $tvars{article}{letter}  = substr($tvars{article}{dist},0,1);
        }
    }
}

sub _parse_guid_report {
    my @rows = $dbi->GetQuery('hash','GetMetabaseByGUID',$cgiparams{id});
    return  unless(@rows);

    $tvars{article}{data} = $serializer->deserialize($rows[0]->{report});

    my $object = Labyrinth::Plugin::Metabase::Parser->new($tvars{article}{data});

    $tvars{article}{subject} = $object->subject;
    $tvars{article}{from}    = $object->from;
    $tvars{article}{from}    =~ s/\@.*//;
    $tvars{article}{post}    = $object->postdate;
    $tvars{article}{date}    = $object->date;

    $tvars{article}{dist}    = $object->distribution;
    $tvars{article}{version} = $object->version;
    $tvars{article}{author}  = $object->from;
    $tvars{article}{letter}  = substr($tvars{article}{dist},0,1);
}

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2010-2017 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
