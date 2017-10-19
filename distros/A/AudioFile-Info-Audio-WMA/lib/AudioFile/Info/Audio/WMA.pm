=head1 NAME

AudioFile::Info::Audio::WMA - Perl extension to get info from WMA files.

=head1 DESCRIPTION

This is a plugin for AudioFile::Info which uses Audio::WMMA to get
data about WMA files.

See L<AudioFile::Info> for more details.

=cut

package AudioFile::Info::Audio::WMA;

use 5.006;

use strict;
use warnings;
use Carp;

use Audio::WMA;

our $VERSION = 0.11;

my %data = (
	artist => 'ALBUMARTIST',
	title  => 'TITLE',
	album  => 'ALBUMTITLE',
	track  => 'TRACKNUMBER',
	year   => 'YEAR',
	genre  => 'GENRE',
);

sub new {
	my ($class, $file) = @_;

	my $wma  = Audio::WMA->new($file);
	bless { obj => $wma->tags }, $class;
}

sub DESTROY {}

sub AUTOLOAD {
	my $self = shift;

	our $AUTOLOAD;

	my ($pkg, $sub) = $AUTOLOAD =~ /(.+)::(\w+)/;

	carp "Invalid attribute $sub" unless exists $data{$sub};

	return $self->{obj}->{$data{$sub}};
}


1;
__END__

=head1 METHODS

=head2 new

Creates a new object of class AudioFile::Info::Audio::WMA. Usually called
by AudioFile::Info::new.

=head1 AUTHOR

Markus Holzer, E<lt>holli.holzer@googlemail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Markus Holzer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


