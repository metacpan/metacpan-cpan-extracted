use 5.010;
use strict;
use warnings;

package App::MP4Meta::Source::Data::TVEpisode;
{
  $App::MP4Meta::Source::Data::TVEpisode::VERSION = '1.153340';
}

# ABSTRACT: Contains data for a TV Episode.

use App::MP4Meta::Source::Data::Base;
our @ISA = 'App::MP4Meta::Source::Data::Base';

use Object::Tiny qw(
  show_title
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MP4Meta::Source::Data::TVEpisode - Contains data for a TV Episode.

=head1 VERSION

version 1.153340

=head1 SYNOPSIS

  my $episode = App::MP4Meta::Source::Data::TVEpisode->new(%data);

=head1 ATTRIBUTES

=head2 show_title

Title of the show.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
