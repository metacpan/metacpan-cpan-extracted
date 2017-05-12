package Buzznet::Buzzword;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Buzznet::Buzzword ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

#require XSLoader;
#XSLoader::load('Buzznet::Buzzword', $VERSION);

# Preloaded methods go here.

sub new 
{
  my ($package,@refs) = @_;
  my $inst = {@refs};
  $inst->{"error"} = undef;
  return bless($inst,$package);
}

sub keyword
{
  my $self = shift;
  return $self->{"keyword"};
}

sub title
{
  my $self = shift;
  return $self->{"title"};
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
=head1 NAME

Buzznet::Buzzword - Buzznet API Buzzword Object

=head1 SYNOPSIS

  use Buzznet::Buzzword;

=head1 DESCRIPTION

This class is mainly used by Buzznet::API to encapsulate the Buzzword attributes

=head1 METHODS

=over 4

=item keyword

Returns the keyword for this Buzzword

=item title

Returns the title for this Buzzword

=back

=head1 SEE ALSO

Check out http://www.buzznet.com/developers for the latest tools and
libraries available for all languages and platforms. The complete XML-RPC Buzznet API can be found at http://www.buzznet.com/developers/apidocs/.

Buzznet::Entry
Buzznet::Gallery
Buzznet::Comment
Buzznet::Profile
Buzznet::API

=head1 AUTHOR

Kevin Woolery, E<lt>kevin@buzznet.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Kevin Woolery

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
