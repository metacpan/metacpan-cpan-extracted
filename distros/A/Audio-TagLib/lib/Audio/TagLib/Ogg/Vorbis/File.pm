package Audio::TagLib::Ogg::Vorbis::File;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

use base qw(Audio::TagLib::Ogg::File);

BEGIN{
=pod
    no strict 'refs';    ## no critic (ProhibitNoStrict)
    unless (grep {/^new$/ } keys %__PACKAGE__::) {
        *Audio::TagLib::Ogg::Vorbis::File:: = *Audio::TagLib::Vorbis::File:: ;
    }
=cut
    $DB::single = 2;
    my $new = grep { $_ eq 'new' }  keys %__PACKAGE__::;
    if ( not $new ) {
        *Audio::TagLib::Ogg::Vorbis::File:: = *Audio::TagLib::Vorbis::File:: ;
    }
}

1;

__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::Ogg::Vorbis::File - An implementation of Ogg::File with Vorbis
specific methods 

=head1 SYNOPSIS

  use Audio::TagLib::Ogg::Vorbis::File;
  
  my $i = Audio::TagLib::Ogg::Vorbis::File->new("sample vorblis file.ogg");
  print $i->tag()->comment()->toCString(), "\n"; # got comment

=head1 DESCRIPTION

This is the central class in the Ogg Vorbis metadata processing
collection of classes. It's built upon Ogg::File which handles
processing of the Ogg logical bitstream and breaking it down into
pages which are handled by the codec implementations, in this case
Vorbis specifically. 

=over

=item I<new(PV $file, BOOL $readProperties = TRUE, PV $propertiesStyle
= "Average")>

Contructs a Vorbis file from $file. If $readProperties is true the
file's audio properties will also be read using $propertiesStyle. If
false, $propertiesStyle is ignored.

=item I<DESTROY()>

Destroys this instance of the File.

=item I<L<Ogg::XiphComment|Audio::TagLib::Ogg::XiphComment> tag()>

Returns the XiphComment for this file. XiphComment implements the tag
interface, so this serves as the reimplementation of
Audio::TagLib::File::tag(). 

=item I<L<Properties|Audio::TagLib::Ogg::Vorbis::Properties>
audioProperties()>

Returns the Vorbis::Properties for this file. If no audio properties
were read then this will return undef.

=item I<BOOL save()>

Saves the File.

=back

=head2 EXPORT

None by default.



=head1 SEE ALSO

L<Audio::TagLib|Audio::TagLib> L<Ogg::File|Audio::TagLib::Ogg::File>

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
