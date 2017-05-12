package AnnoCPAN::PodParser;

$VERSION = '0.22';

use strict;
use warnings;

use base qw(Pod::Parser);

our @EXPORT_OK   = qw(VERBATIM TEXTBLOCK COMMAND);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 NAME

AnnoCPAN::PodParser - Parse a pod and load the paragraphs into the database

=head1 SYNOPSIS

    sub filter_pod {
        my ($self, $code, $podver) = @_;
        my $fh_in = IO::String->new($code);
        my $parser =  AnnoCPAN::PodParser->new(
            ac_podver  => $podver,
            ac_pos     => 0,
            ac_verbose => $self->verbose,
        );
        $parser->parse_from_filehandle($fh_in);
    }

=head1 DESCRIPTION

This module is used by L<AnnoCPAN::Dist> when loading a new distribution
into the database. It is a subclass of L<Pod::Parser> that overrides
the C<verbatim>, C<command>, and L<textblock> methods and uses them to insert
the almost unparsed POD into the database tables.

=cut

use constant {
    VERBATIM  => 1,
    TEXTBLOCK => 2,
    COMMAND   => 4,
};

sub verbatim {
    my ($self, $text, $line_num, $pod_para) = @_;
    #print "VERBATIM:    $text\n";
    $self->store_section(VERBATIM, $text);
}

sub textblock {
    my ($self, $text, $line_num, $pod_para) = @_;
    #print "TEXTBLOCK:   $text\n";
    $self->store_section(TEXTBLOCK, $text);
}

sub command {
    my ($self, $cmd, $text, $line_num, $pod_para)  = @_;
    #print "COMMAND:     " . $pod_para->raw_text() . "\n";
    $self->store_section(COMMAND, $pod_para->raw_text);
}

sub store_section {
    my ($self, $type, $content) = @_;

    # get rid of nuls so that we can use them safely in PodToHtml
    $content =~ s/\0//g; 

    ++$self->{ac_pos};
    return if ($content =~ /^\s*$/); # skip blank paragraphs

    my $podver = $self->{ac_podver};
    if ($self->{ac_pos} == 1 and $content =~ /^=head1\s+NAME/) {
        $self->{ac_has_title} = 1;
    } elsif ($self->{ac_pos} == 2 and $self->{ac_has_title}) {
        if ($content =~ /^\s*(\S+)[\s-]+(.*)/) {
            ($self->{ac_name}, $self->{ac_desc}) = ($1, $2);
        }
    }

    my $section;
    if ($type == VERBATIM and $self->{ac_last_verbatim}) {
        # append to previous verbatim section
        my $prev = $self->{ac_last_verbatim};
        $prev->content($prev->content . $content);
        $prev->update;
        $section = $prev;
    } else {
        # create new section
        $section = AnnoCPAN::DBI::Section->create({
            podver  => $podver,
            type    => $type,
            content => $content,
            pos     => $self->{ac_pos},
        });
        $self->{ac_last_verbatim} = $type == VERBATIM ? $section : undef;
    }

    $section;
}

sub ac_metadata {
    my ($self) = @_;
    ($self->{ac_name}, $self->{ac_desc});
}

=head1 SEE ALSO

L<AnnoCPAN::DBI>, L<AnnoCPAN::Update>, L<AnnoCPAN::Dist>, L<Pod::Parser>

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut
1;

