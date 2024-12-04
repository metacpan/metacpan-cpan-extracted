use warnings;
use 5.020;
use experimental qw( signatures );
use stable qw( postderef );

package Data::Section::Writer 0.01 {

  # ABSTRACT: Write __DATA__ section files for Data::Section, Data::Section::Simple or Mojo::Loader::data_section


  use Path::Tiny ();
  use Carp ();
  use Class::Tiny qw( perl_filename _files );
  use Ref::Util qw( is_blessed_ref );
  use MIME::Base64 qw(encode_base64);

  sub BUILD ($self, $) {

    # use the callers filename if not provided.
    unless(defined $self->perl_filename) {
      my(undef, $fn) = caller 2;
      $self->perl_filename($fn);
    }

    # upgrade to Path::Tiny if it is not already
    unless(is_blessed_ref $self->perl_filename && $self->isa('Path::Tiny')) {
      $self->perl_filename(Path::Tiny->new($self->perl_filename));
    }

    $self->_files({});

  }


  sub add_file ($self, $filename, $content, $encoding=undef) {
    Carp::croak("Unknown encoding $encoding") if defined $encoding && $encoding ne 'base64';
    $self->_files->{"$filename"} = [ $content, $encoding ];
    return $self;
  }

  sub _render_file ($self, $filename, $data) {
    my $text = "@@ $filename";
    $text .= " (" . $data->[1] . ")" if defined $data->[1];
    $text .= "\n";
    if(defined $data->[1] && $data->[1] eq 'base64') {
      $text .= encode_base64($data->[0]);
    } else {
      $text .= $data->[0];
    }
    chomp $text;
    return $text;
  }


  sub render_section ($self) {
    my $files = $self->_files;
    return "__DATA__\n" unless %$files;
    return join("\n",
      "__DATA__",
      (map { $self->_render_file($_, $files->{$_}) } sort keys $files->%*),
      ''
    );
  }


  sub update_file ($self) {
    my $perl;

    if(-f $self->perl_filename) {
      $perl = $self->perl_filename->slurp_utf8;

      if($perl =~ /^__DATA__/) {
        $perl = '';
      } else {
        # read the file in, removing __DATA__ and everything after that
        # if there is no __DATA__ section then leave unchanged.
        $perl =~ s/(?<=\n)__DATA__.*//s;

        # Add a new line at the end if it doesn't already exist.
        $perl .= "\n" unless $perl =~ /\n\z/s;
      }

    } else {
      $perl = '';
    }

    # re-write the perl with the
    $self->perl_filename->spew_utf8(
      $perl . $self->render_section,
    );

    return $self;
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Section::Writer - Write __DATA__ section files for Data::Section, Data::Section::Simple or Mojo::Loader::data_section

=head1 VERSION

version 0.01

=head1 SYNOPSIS

This code:

 use strict;
 use warnings;
 use Data::Section::Writer;
 use Path::Tiny qw( path );
 
 Data::Section::Writer
   ->new( perl_filename => "foo.pl" )
   ->add_file( "hello.txt", "hello world" )
   ->add_file( "a.out", path("a.out")->slurp_raw, 'base64' )
   ->update_file;

Will add this to the bottom of C<foo.pl>

 __DATA__
 @@ a.out (base64)
 f0VMRgIBAQAAAAAAAAAAAAMAPgABAAAAQBAAAAAAAABAAAAAAAAAAGA2AAAAAAAAAAAAAEAAOAAN
 AEAAHQAcAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAA2AIAAAAAAADYAgAAAAAAAAgA
 AAAAAAAAAwAAAAQAAAAYAwAAAAAAABgDAAAAAAAAGAMAAAAAAAAcAAAAAAAAABwAAAAAAAAAAQAA
 ...
 @@ hello.txt
 hello world

(binary file truncated for readability)

=head1 DESCRIPTION

This class is an interface for updating the C<__DATA__> section of your Perl module or script programmatically
for it to work with one of the many modules that allows for multiple files in a C<__DATA__> section, such as
L<Data::Section>, L<Data::Section::Simple> or L<Mojo::Loader>.

L<Data::Section> uses a different header format by default, but you can still use this module with it
if you set C<header_re> to C<qr/^@@ (.*)$/>.

=head1 ATTRIBUTES

=head2 perl_filename

The name of the Perl source file.  If not provided then the source for the caller will be used. 

=head1 METHODS

=head2 add_file

 $writer->add_file($text_filename, $content);
 $writer->add_file($binary_filename, $content, 'base64');

Add a file.  Binary files can be encoded using C<base64>.  Such binaries files are
only supported by L<Mojo::Loader> at the moment.

=head2 render_section

 my $perl = $writer->render_section;

Returns the C<__DATA__> section.

=head2 update_file

 $writer->update_file;

Update the existing Perl source file, OR create a new Perl source file with just the C<__DATA__> section.

=head1 CAVEATS

Added text files will get an added trailing new line if they do not already have
them.  This is a requirement of the format used by the data section modules.

For binary files (base64 encoded) the content returned by L<Mojo::Loader> should
be identical.

Not tested, and probably not working for Windows formatted text files, though
patches for this are welcome.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
