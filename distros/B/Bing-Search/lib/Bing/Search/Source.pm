package Bing::Search::Source;
use Moose;

has 'params' => ( is => 'rw', isa => 'HashRef' );
has 'source_name' => ( is => 'rw', isa => 'Str', lazy_build => 1 );

sub build_request { 
   my $self = shift;
   my $params = $self->params;
   # anchor!  params should be a nice hashref now.
   return $params;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Source - Base class for Sources.

=head1 SYNOPSIS

 my $source = Bing::Search::Source::Web->new();

 $search->add_source( $source );

=head1 DESCRIPTION

For details on what specific sources exist, see the documentation
for the source in question.

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.


