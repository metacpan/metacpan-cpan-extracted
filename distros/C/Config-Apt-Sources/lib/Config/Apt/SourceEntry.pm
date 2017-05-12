package Config::Apt::SourceEntry;

use warnings;
use strict;

=head1 NAME

Config::Apt::SourceEntry - Manipulate apt source entries

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';
use Carp;

=head1 SYNOPSIS

    use Config::Apt::SourceEntry;

    my $src = new Config::Apt::SourceEntry;
    $src->from_string("deb http://ftp.us.debian.org/debian/ unstable main");
    ...
    my $src = new Config::Apt::SourceEntry("deb http://ftp.us.debian.org/debian/ unstable main non-free");
    $src->set_uri("http://apt-proxy:9999/");
    print $src->to_string();

=head1 FUNCTIONS

=head2 new

The Config::Apt::SourceEntry constructor has one optional string argument.  If
the optional argument is given, it will be parsed as an apt source.

=cut

sub new {
  my ($class_name) = @_;
  my ($self) = { 'type' => "",
                 'uri'  => "",
                 'dist' => "",
                 'components' => [ ],
               };

  bless($self, $class_name);
  if (@_ > 1) {
    if (!defined(from_string($self,$_[1]))) { $self = undef };
  }
  return $self;

}

=head2 to_string

Returns the string representation of the apt source.  Takes no arguments.

    print $src->to_string();

=cut

sub to_string {
  my $self = shift;
  local $"=' ';
  my $ret = $self->{'type'} . " " . $self->{'uri'} . " " . $self->{'dist'};
  if (@{$self->{'components'}} > 0) {
    $ret .= " " . "@{ $self->{'components'} }";
  }
  return $ret;
}

=head2 from_string

Parses the given string argument as an apt source.

    $src->from_string("deb http://ftp.us.debian.org/debian/ unstable main");

Returns undef on error, otherwise 1.

=cut

sub from_string {
  my ($self,$str) = @_;
  # trim whitespace
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  $str =~ s/\s+/ /g;

  # trim comments
  $str =~ s/#.*$//g;

  my @source = split / /,$str;
  unless (@source >= 3) {
    carp "Invalid source";
    return undef;
  }
  $self->{'type'} = shift @source;
  $self->{'uri'}  = shift @source;
  $self->{'dist'} = shift @source;
  $self->{'components'} = [ @source ];
  return 1;
}

=head2 get_type, get_uri, get_dist, get_components

Returns the type, uri, distribution (strings), or components (array of strings)

=cut

sub get_type { my $self=shift;return $self->{'type'};   }
sub get_uri  { my $self=shift;return $self->{'uri'}; }
sub get_dist { my $self=shift;return $self->{'dist'};   }
sub get_components { my $self=shift;return @{ $self->{'components'} };}

=head2 set_type, set_uri, set_dist, set_components

Sets the type, uri, distribution (strings), or components (array of strings)

=cut

sub set_type { my $self=shift;$self->{'type'} = shift; }
sub set_uri  { my $self=shift;$self->{'uri'}  = shift; }
sub set_dist { my $self=shift;$self->{'dist'} = shift; }
sub set_components { my $self=shift;$self->{'components'} = [ @_ ]; }

=head1 AUTHOR

Ian Kilgore, C<< <iank at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-config-apt-source at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Apt-Source>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Apt::Source

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-Apt-Source>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-Apt-Source>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Apt-Source>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-Apt-Source>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Ian Kilgore, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Config::Apt::Source
