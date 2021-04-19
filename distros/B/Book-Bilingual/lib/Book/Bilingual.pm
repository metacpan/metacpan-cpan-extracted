package Book::Bilingual;
# ABSTRACT: Data structure for a bilingual book
use Mojo::Base -base;
use Carp;

use version; our $VERSION = version->declare('0.003');

has 'chapters';         # ArrayRef of Book::Bilingual::Chapter

sub new { $_[0]->SUPER::new({ chapters => [] }) }
sub chapter_count { ## () :> Int
    my ($self) = @_;

    return scalar @{$self->{chapters}};
}
sub push { ## ($chapter:>Book::Bilingual::Chapter) :> Self
    my ($self, $chapter) = @_;

    croak 'Not a Book::Bilingual::Chapter'
        unless ref($chapter) eq 'Book::Bilingual::Chapter';

    push @{$self->{chapters}}, $chapter;

    return $self;
}

sub chapter_at { ## ($ch_idx :>Int) :> Int
    my ($self, $ch_idx) = @_;
    return $self->{chapters}[$ch_idx];
}

sub chapter_dlineset_count { ## ($ch_idx) :> Int
    my ($self,$ch_idx) = @_;
    return $self->chapters->[$ch_idx]->dlineset_count;
}
sub chapter_dlineset_dline_len { ## ($ch_idx, $dset_idx) :> Int
    my ($self, $ch_idx, $dset_idx) = @_;
    return $self->chapters->[$ch_idx]->dlineset_at($dset_idx)->dline_count;
}

1;

=pod

=encoding utf-8

=head1 NAME

Book::Bilingual - A crappy model for bilingual books

=head1 SYNOPSIS

    use Book::Bilingual::Reader;

    my $file = 't/ff01.mdown';
    my $reader = Book::Bilingual::Reader->new($file);

    print $reader->html();

=head1 DESCRIPTION

L<Book::Bilingual> is a model for bilingual books written in Markdown
format. The L<Book::Bilingual::Reader> module reads the file and
generates HTML.

=head1 METHODS

=head2 chapter_dlineset_count($chapter_idx:>Int) :> Int

Returns the number of dlinesets in the given Chapter.

=head2 num_dline_in_dlineset($chapter_idx:Int, $dlineset_idx:Int) :> Int

Returns the number of dlines in the given Chapter and Dlineset.

=head1 AUTHOR

Hoe Kit CHEW E<lt>hoekit at gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2021 Hoe Kit CHEW

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

