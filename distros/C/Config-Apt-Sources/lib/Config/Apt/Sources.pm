package Config::Apt::Sources;

use warnings;
use strict;

use Carp;
use UNIVERSAL qw( isa );
use Config::Apt::SourceEntry;
=head1 NAME

Config::Apt::Sources - Parse and manipulate apt sources

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    use Config::Apt::Sources;

    my $srcs = Config::Apt::Sources->new();
    $srcs->parse_stream(do { local $/; <> });

    my @sources = $srcs->get_sources();
    $sources[0]->set_uri("http://ftp.us.debian.org/debian/");
    $srcs->set_sources(@sources);
    print $srcs->to_string();

=head1 FUNCTIONS

=head2 new

The Config::Apt::Sources constructor takes no arguments.

=cut

sub new {
  my ($class_name) = @_;
  my ($self) = { 'sources' => [ ] };

  bless($self, $class_name);
  return $self;
}

=head2 parse_stream

Parses the given string argument as the contents of an apt sources.list file.

    $srcs->parse_stream(do { local $/; <FILE> });

=cut

sub parse_stream {
  my $self = shift;
  my @lines = split("\n",shift);

  my @line;
  my @sources;
  for my $line (@lines) {
    next if $line =~ /(^\s*#|^$)/; # skip comments and blank lines
    chomp $line;
    push @sources,new Config::Apt::SourceEntry($line);
  }
  $self->{'sources'} = [ @sources ];
  return 1;
}

=head2 to_string

Returns the sources.list as a string.  Takes no arguments.

    my $newsrcs = $srcs->to_string;

=cut

sub to_string {
  my $self = shift;
  my $ret = "";
  for (@{ $self->{'sources'} }) {
    $ret .= $_->to_string() . "\n";
  }
  return $ret;
}

=head2 get_sources

Returns an array of Config::Apt::SourceEntry objects.  Takes no arguments.

  my @sources = $srcs->get_sources();

=cut

sub get_sources {
  my $self = shift;
  return map { new Config::Apt::SourceEntry($_->to_string()) } @{$self->{'sources'}};
}

=head2 set_sources

Reads an array of Config::Apt::SourceEntry objects.  returns undef if
any element is not a Config::Apt::SourceEntry object.  Otherwise,
returns 1.

  $srcs->set_sources(@sources);

=cut

sub set_sources {
  my $self = shift;
  my @sources;

  foreach (@_) {
    unless (isa($_, 'Config::Apt::SourceEntry')) {
      carp "arguments must be Config::Apt::SourceEntry objects";
      return undef;
    }
    push @sources,$_;
  }
  $self->{'sources'} = [ @sources ];

  return 1;
}


=head1 AUTHOR

Ian Kilgore, C<< <iank at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-config-apt-sources at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Apt-Sources>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Apt::Sources

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-Apt-Sources>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-Apt-Sources>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Apt-Sources>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-Apt-Sources>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Ian Kilgore, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Config::Apt::Sources
