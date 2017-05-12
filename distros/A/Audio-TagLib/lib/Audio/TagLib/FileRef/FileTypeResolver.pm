package Audio::TagLib::FileRef::FileTypeResolver;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

1;

__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::FileRef::FileTypeResolver -  A class for pluggable file type resolution.

=head1 DESCRIPTION

This class is used to add extend Audio::TagLib's very basic file name based
file type resolution.

This can be accomplished with:

  package Audio::TagLib::FileRef::MyFileTypeResolver;

  our @ISA = qw(Audio::TagLib::FileRef::FileTypeResolver);

  sub createFile() {
      my $package  = shift;
      my $filename = shift;
      if(&someCheckForAnMP3File($filename)) {
          my $file = Audio::TagLib::MPEG::File->new($filename);
          # skip DESTROY() in Perl level
          $file->_setReadOnly();
          return $file;
      }
      return undef;
  }
  
  package main;
  
  Audio::TagLib::FileRef->addFileTypeResolver(
      Audio::TagLib::FileRef::MyFileTypeResolver->new());

Naturally a less contrived example would be slightly more
 complex. This can be used to plug in mime-type detection systems or
 to add new file types to Audio::TagLib.

=over

=item I<L<File|Audio::TagLib::File> createFile(PV $fileName, BOOL
$readAudioProperties = TRUE, L<PV|Audio::TagLib::AudioProperties>
$audioPropertiesStyle = "Average")> [pure virtual]

This method must be overriden to provide an additional file type
resolver. If the resolver is able to determine the file type it should
return a valid File object; if not it should return undef.

B<NOTE> The created file is then owned by the FileRef and should not
be deleted. Deletion will happen automatically when the FileRef passes
out of scope.

=back

=head2 EXPORT

None by default.



=head1 SEE ALSO

L<Audio::TagLib|Audio::TagLib>

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
