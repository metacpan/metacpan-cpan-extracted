use 5.010;
use strict;
use warnings;

package App::MP4Meta::Source::Data::Base;
{
  $App::MP4Meta::Source::Data::Base::VERSION = '1.153340';
}

# ABSTRACT: Base class for metadata.

use Object::Tiny qw(
  cover
  genre
  overview
  title
  year
);

sub merge {
    my ( $self, $to_merge ) = @_;

    while ( my ( $key, $value ) = each(%$to_merge) ) {
        $self->{$key} = $value unless $self->{$key};
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MP4Meta::Source::Data::Base - Base class for metadata.

=head1 VERSION

version 1.153340

=head1 SYNOPSIS

  my $episode = App::MP4Meta::Source::Data::Base->new(%data);

=head1 ATTRIBUTES

=head2 cover

Path to cover imaage.

=head2 genre

Genre.

=head2 overview

Overview or description.

=head2 title

Title.

=head2 year

Year.

=head1 METHODS

=head2 merge ($to_merge)

Merges $to_merge in $self, without overwriting $self.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
