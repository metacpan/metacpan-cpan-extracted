package Bing::Search::Result;
use Moose;

with 'Bing::Search::Role::Types::UrlType';

has 'data' => ( 
   is => 'rw',
   builder => '_populate'
#   trigger => \&_populate
);

sub _populate { 
   # nothing here but us chickens
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Result - Base class for Results

=head1 DESCRIPTION

See the specific Result objects for what methods
are available.

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.
