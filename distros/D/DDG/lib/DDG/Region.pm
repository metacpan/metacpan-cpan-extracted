package DDG::Region;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: A region, can be empty [TODO]
$DDG::Region::VERSION = '1018';
use Moo;

my @region_attributes = qw();

has $_ => (
  is => 'ro',
  default => sub { '' }
) for (@region_attributes);

1;

__END__

=pod

=head1 NAME

DDG::Region - A region, can be empty [TODO]

=head1 VERSION

version 1018

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
