package Audio::TagLib::Vorbis::Properties;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

use base qw(Audio::TagLib::AudioProperties);

BEGIN{
=pod
    no strict 'refs';    ## no critic (ProhibitNoStrict)
    unless (grep {/^new$/ } keys %__PACKAGE__::) {
        *Audio::TagLib::Vorbis::Properties:: = *Audio::TagLib::Ogg::Vorbis::Properties:: ;
    }
=cut
    my $new = grep { $_ eq 'new' }  keys %__PACKAGE__::;
    if ( not $new ) {
        *Audio::TagLib::Vorbis::Properties:: = *Audio::TagLib::Ogg::Vorbis::Properties:: ;
    }
}

1;
__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::Vorbis::Properties  - An implementation of audio property
reading for Ogg Vorbis 

=head1 SYNOPSIS

  use Audio::TagLib::Vorbis::Properties;
  
  my $f = Audio::TagLib::Vorbis::File->("sample ogg file.ogg");
  my $i = $f->audioProperties();
  print $i->channels(), "\n"; # normally got 2

=head1 DESCRIPTION

This reads the data from an Ogg Vorbis stream found in the
AudioProperties API.

=over

=item I<new(L<File|Audio::TagLib::Vorbis::File> $file, PV $style =
"Average")> 

Create an instance of Vorbis::Properties with the data read from the
 Vorbis::File $file.

=item I<DESTROY()>

Destroys this VorbisProperties instance.

=item I<IV length()>

=item I<IV bitrate()>

=item I<IV sampleRate()>

=item I<IV channels()>

see L<AudioProperties|Audio::TagLib::AudioProperties>

=item I<IV vorbisVersion()>

Returns the Vorbis version, currently "0" (as specified by the spec).

=item I<IV bitrateMaximum()>

Returns the maximum bitrate as read from the Vorbis identification
 header. 

=item I<IV bitrateNominal()>

Returns the nominal bitrate as read from the Vorbis identification
header. 

=item I<IV bitrateMinimum()>

Returns the minimum bitrate as read from the Vorbis identification
 header. 

=back

=head2 EXPORT

None by default.



=head1 SEE ALSO

L<Audio::TagLib|Audio::TagLib> L<AudioProperties|Audio::TagLib::AudioProperties>

=head1 AUTHOR

Dongxu Ma, E<lt>dongxu@cpan.orgE<gt>

=head1 MAINTAINER

Geoffrey Leach GLEACH@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2010 by Dongxu Ma

Copyright (C) 2011 - 2013 Geoffrey Leach

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
