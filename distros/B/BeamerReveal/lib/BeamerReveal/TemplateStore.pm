# -*- cperl -*-
# ABSTRACT: TemplateStore


package BeamerReveal::TemplateStore;
our $VERSION = '20260120.1958'; # VERSION

use parent 'Exporter';
use Carp;

use BeamerReveal::Log;

my $store = undef;


sub new {
  my $class = shift;
  
  $class = (ref $class ? ref $class : $class );
  my $self = {};
  bless $self, $class;
}



sub fetch {
  my $self = shift;
  my ( $library, $fileName ) = @_;

  my $key = $library . '/' . $fileName; 
  $store->{$key} = _readTemplate( $library, $fileName ) unless( exists $store->{$key} );
  return $store->{$key};
}


sub stampTemplate {
  my ( $string, $hash ) = @_;
  
  while( my ( $stamp, $value ) = each %$hash ) {
    if ( defined( $value ) ) {
      $string =~ s/---${stamp}---/$value/g;
    }
    else {
      my $lcstamp = lc( $stamp );
      $string =~ s/(?:${lcstamp}\s*[:=]\s*)?"?-*-${stamp}-*-"?//g;
    }
  }
  return $string;
}


sub _readTemplate {
  my ( $library, $fileName ) = @_;

  my $home = $^O eq 'MSWin32' ? $ENV{'userprofile'} : $ENV{'HOME'};
  my $configDir = $ENV{'BEAMERREVEAL_CONFIG'}
    // "$home/.config/BeamerReveal";
  my $templateFileName = "$configDir/templates/$library/$fileName";
  $templateFileName = File::ShareDir::dist_dir( 'BeamerReveal' ) . "/templates/$library/$fileName"
    if ( ! -r $templateFileName );
  
  my $templateFile = IO::File->new();
  $templateFile->open( "<$templateFileName" )
    or $BeamerReveal::Log::logger->fatal( "Error: installation incomplete - cannot find the template file '$fileName'" );
  my $content = do { local $/; <$templateFile> };
  return $content;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BeamerReveal::TemplateStore - TemplateStore

=head1 VERSION

version 20260120.1958

=head1 SYNOPSIS

This class delivers a store object from which you can retrieve templates
(HTML and TeX). The store resides in the share/templates directory of your
BeamerReveal package installation.
Underneath, there is only one store, but multiple objects can access it.

=head1 METHODS

=head2 new()

  $store = BeamerReveal::TemplateStore->new()

creates a store object C<$store> to query for templates.

=head2 fetch()

  $t = fetch( $library, $fileName )

This method will fetch a template from the store. Templates are cached in the store, so they only need to be read from disk once.

=over 4

=item . C<$library>

'html' or 'tex'. This will determine in which subfolder  of the share/templates/ your template will be
searched  for.

=item . C<$fileName>

name of the template to fetch

=item . C<$t>

template that has been fetched from the store

=back

=head2 stampTemplate()

  $s = stampTemplate( $string, $hash )

This method will replace the C<---KEY---> stamps in C<$string> with VALUE, based on the (KEY,VALUE) pairs of the C<%$hash>.

=over 4

=item . C<$string>

string to replace the stamps in.

=item . C<$hash>

reference to a hash containing the (KEY,VALUE) pairs relating a stamp to its actual value.

=item . C<$s>

string in which the replacements took place

=back

=head2 $t = _readTemplate( $library, $fileName )

This method will actually read a template from the disk. Don't use this method directly. Always use the C<fetch()> function.

=over 4

=item . C<$library>

'html' or 'tex'. This will determine in which subfolder of the share/templates/ your template will be
searched for.

=item . C<$fileName>

name of the template to read

=item . C<$t>

template that has been read from disk

=back

=head1 AUTHOR

Walter Daems <wdaems@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Walter Daems.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 CONTRIBUTOR

=for stopwords Paul Levrie

Paul Levrie

=cut
