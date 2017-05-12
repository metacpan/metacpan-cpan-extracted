package Audio::Opusfile::Tags;
# Don't load this module directly, load Audio::Opusfile instead

use 5.014000;
use strict;
use warnings;
use subs qw/query query_count/;

our $VERSION = '0.005001';

sub query_all {
	my ($tags, $tag) = @_;
	my $count = $tags->query_count($tag);
	map { $tags->query($tag, $_ - 1) } 1 .. $count
}

1;
__END__

=encoding utf-8

=head1 NAME

Audio::Opusfile::Tags - The tags of an Ogg Opus file

=head1 SYNOPSIS

  use Audio::Opusfile;
  my $of = Audio::Opusfile->new_from_file('file.opus');
  my $tags = $of->tags;
  say $tags->query("COMPOSER"); # Composer 1
  say $tags->query_count("COMPOSER"); # 3
  say join ", ", $tags->query_all("COMPOSER");
  # Composer 1, Composer 2, Composer 3

=head1 DESCRIPTION

This module represents the tags of an Ogg Opus file. See the
documentation of L<Audio::Opusfile> for more information.

=head1 METHODS

=over

=item $tags->B<query_count>(I<$tag>)

Returns the number of values of a tag.

=item $tags->B<query>(I<$tag>[, I<$index>])

Returns the I<$index>th value of a tag. If I<$index> is not provided,
the first value is returned.

=item $tags->B<query_all>(I<$tag>)

Returns a list of all values of a tag, in order.

=back

=head1 SEE ALSO

L<Audio::Opusfile>,
L<http://opus-codec.org/>,
L<http://opus-codec.org/docs/opusfile_api-0.7/index.html>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
