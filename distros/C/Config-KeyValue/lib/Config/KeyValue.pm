package Config::KeyValue;

use warnings;
use strict;
use Carp qw(croak);

=head1 NAME

Config::KeyValue - Module for reading simple "KEY=VALUE" formatted configuration files.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Config::KeyValue;

    # Instantiate
    my $cfg = Config::KeyValue->new();

    # Parse file, returning found key-value pairs
    my $parsed_config = $cfg->load_file('/path/to/your/config/file');

    # Fetch a specific key
    print $cfg->get('SOME_CONFIGURATON_KEY'), "\n";

    # Fetch a specific key with leading-and-trailing quotes removed
    print $cfg->get_tidy('SOME_CONFIGURATON_KEY'), "\n";

=head1 FUNCTIONS

=head2 new()

Constructor.

=cut

sub new {
  my $self = {};
  $self->{CONFIG} = {}; # Start with an empty hash of configuration key-values
  bless($self);
  return $self;
}


=head2 get(key)

Get configuration value for I<key>.  Returns an empty string if I<key> is not defined.

=cut

sub get {
  my ($self, $key) = @_;
  return $self->{CONFIG}{ $key } || '';
}

=head2 get_tidy(key)

Get configuration value for I<key>, stripping leading and trailing matching quote characters
(e.g. I<'>, I<">).  Returns an empty string if I<key> is not defined.

=cut

sub get_tidy {
  my ($self, $key) = @_;
  my $value = $self->{CONFIG}{ $key } || '';
  $value =~ s/^'(.+)'$/$1/; # Trim matched single quotes
  $value =~ s/^"(.+)"$/$1/; # Trim matched double quotes
  return $value;
}

=head2 load_file(file_name)

Read configuration information from I<file_name>.  Returns hashref of configuration key=value
pairs.

=cut

sub load_file {
  my ($self, $file_name) = @_;

  my $cfg = {}; 
  open(my $fh, '<', $file_name) or croak("could not open file for reading: '$file_name'");
  while (my $l=<$fh>) {
    next if ($l =~ /^#/);
    if ($l =~ /^(\S+)=(.+)$/) {
      my ($k, $v) = ($1, $2);
      $v =~ s/\s*#.*$//; # remove trailing whitespace and comment
      $cfg->{ $k } = $v;
    }
  }
  close($fh) or croak("could not close file: '$file_name'");
  $self->{CONFIG} = $cfg; # replace the current CONFIG hashref
  return $cfg; # return what we extracted from configuration file
}


=head1 AUTHOR

blair christensen, C<< <blair.christensen at gmail.com> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-config-keyvalue at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-KeyValue>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::KeyValue


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-KeyValue>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-KeyValue>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-KeyValue>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-KeyValue/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 blair christensen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Config::KeyValue
