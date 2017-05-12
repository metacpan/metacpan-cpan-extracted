package AnnoCPAN::Dump;

$VERSION = '0.22';

use strict;
use warnings;
use AnnoCPAN::Config;
use AnnoCPAN::DBI;
use XML::SAX;
use Template;

=head1 NAME

AnnoCPAN::Dump - Read and write AnnoCPAN XML dumps

=head1 SYNOPSIS

    use AnnoCPAN::Dump;

    my $file = 'note_dump.xml';
    AnnoCPAN::Dump->write_dump($file);
    AnnoCPAN::Dump->read_dump($file);

=head1 DESCRIPTION

This module reads and writes AnnoCPAN XML dumps.

=cut

sub read_dump {
    my ($self, $file, %opts) = @_;
    my $parser = XML::SAX::ParserFactory->parser(
        Handler => AnnoCPAN::Dump::SAX->new);
    $parser->{ac_verbose} = $opts{verbose};
    $parser->parse_uri($file);
}

sub write_dump {
    my ($self, $file) = @_;
    my $tt  = Template->new(
        INCLUDE_PATH => AnnoCPAN::Config->option('template_path'),
    );
    my @notes = AnnoCPAN::DBI::Note->retrieve_all;
    $tt->process('note_dump.xml', { notes => \@notes }, $file);
}

package AnnoCPAN::Dump::SAX;

use base qw(XML::SAX::Base);

sub start_element {
    my ($self, $el) = @_;
    my ($atts) = $el->{Attributes};
    if ($el->{Name} eq 'note') {
        my ($user) = AnnoCPAN::DBI::User->retrieve(
            username => $atts->{'{}author'}{Value}
        );
        unless ($user) {
            warn "user '$atts->{'{}author'}{Value}' not found\n"
                if $self->{ac_verbose};
        }
        $self->{ac_note} = AnnoCPAN::DBI::Note->simple_create({
            time => $atts->{'{}time'}{Value},
            user => $user,
        });
    } elsif ($el->{Name} eq 'notepos') {
        my ($distver)  = AnnoCPAN::DBI::DistVer->search(
            path => $atts->{'{}distver'}{Value},
        );
        my ($podver)  = AnnoCPAN::DBI::PodVer->search(
            path    => $atts->{'{}path'}{Value},
            distver => $distver,
        );
        my ($section) = AnnoCPAN::DBI::Section->search(
            podver => $podver,
            pos    => $atts->{'{}pos'}{Value},
        );
        return unless $section;

        my $status  = $atts->{'{}status'}{Value};
        my $note    = $self->{ac_note};
        AnnoCPAN::DBI::NotePos->create({
            note    => $note,
            score   => $atts->{'{}score'}{Value},
            status  => $status,
            section => $section,
        });
        if ($status == AnnoCPAN::DBI::Note::ORIGINAL) {
            $note->section($section);
        }

    } elsif ($el->{Name} eq 'content') {
        $self->{ac_content_chars} = '';
    }
}

sub characters {
    my ($self, $el) = @_;
    $self->{ac_content_chars} .= "$el->{Data}" if defined $self->{ac_content_chars};
}

sub end_element {
    my ($self, $el) = @_;
    my $note = $self->{ac_note};
    if ($el->{Name} eq 'note') {
        my ($np) = $note->notepos;
        if ($np) {
            $note->pod($np->section->podver->pod);
            $note->update; # includes flush
        } else {
            warn "Note without notepos!\n";
            $note->delete;
        }
    } elsif ($el->{Name} eq 'content') {
        $note->note($self->{ac_content_chars});
        $self->{ac_content_chars} = undef;
    }
}

=head1 SEE ALSO

L<AnnoCPAN::DBI>, L<AnnoCPAN::Update>

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

1;

