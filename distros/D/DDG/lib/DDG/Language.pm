package DDG::Language;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: A language, can be empty [TODO]
$DDG::Language::VERSION = '1016';
use Moo;

my @language_attributes = qw(
  flagicon
  flag_url
  name_in_local
  rtl
  locale
  nplurals
  name_in_english
);

  # 'en_US' => {
  #              'flagicon' => 'us',
  #              'flag_url' => 'https://duckduckgo.com/f2/us.png',
  #              'name_in_local' => 'English of United States',
  #              -'translation_count' => 24,
  #              -'percent' => '24',
  #              'rtl' => 0,
  #              'locale' => 'en_US',
  #              'nplurals' => 2,
  #              'name_in_english' => 'English of United States'
  #            },

has $_ => (
	is => 'ro',
	default => sub { '' }
) for (@language_attributes);

use overload '""' => sub {
  my $self = shift;
  return $self->locale;
}, fallback => 1;

1;

__END__

=pod

=head1 NAME

DDG::Language - A language, can be empty [TODO]

=head1 VERSION

version 1016

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
