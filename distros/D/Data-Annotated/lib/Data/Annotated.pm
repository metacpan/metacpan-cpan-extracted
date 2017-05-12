package Data::Annotated;
use Data::Path;

use warnings;
use strict;

=head1 NAME

Data::Annotated - Data structure Annotation module

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.2';

my $callbacks = {
                key_does_not_exist => sub {},
                index_does_not_exist => sub {},
                retrieve_index_from_non_array => sub {},
                retrieve_key_from_non_hash => sub {},
                };

=head1 SYNOPSIS

    use Data::Annotated;

    my $da = Data::Annotated->new();
    
    $da->annotate('/foo/bar[2]/baz', {desc => 'this is an interesting field'});
    $da->annotate('/some/other/path', {test => 1, runthis => sub { print 'I was one'; } });
   
    my $struct = {some => {other => {path => 1}}}; 
    my @annotations = $da->cat_annotation();
    
    # this will print out "I was one';
    $annotations[0]{runthis}->() if $struct->{some}{other}{path} == $annotations[0]{test};

=head1 METHODS

=head2 new()

instantiate a new Data::Annotated object;

=cut

sub new {
    return bless {}, shift;
}

=head2 annotate($path, \%annotation);

Annotate a piece of a data structure. The path is an XPath like path like L<Data::Path>
uses. The annotation can be any scalar value. Possible uses are String for descriptive
text. Or a reference to a more complex data structure.

=cut

sub annotate {
    my ($self, $path, $anno) = @_;
    croak('Not a valid path: '.$path) unless $self->_validate_path($path); 
    $self->{$path} = $anno;
}

=head2 cat_annotation($data)

spit out the annotations for a data structure. Returns the annotations that apply
for the passed in data structures. Does not return an annotation if the data doesn't 
contain the data location it is matched to.

=cut

sub cat_annotation {
    my ($self, $data) = @_;
    my $dp = Data::Path->new($data, $callbacks);
    my @paths = grep { $dp->get($_) } keys(%$self);
    return map { $self->get_annotation($_) } @paths;
}

=head2 get_annotation($path);

retrieves an annotation keyed by the path in the data structure.

=cut

sub get_annotation {
    my ($self, $path) = @_;
    return {path => $_, %{$self->{$path}}} if $self->_validate_path($path);
    carp('Invalid Path requested: '. $path);
}

=head1 INTERNAL METHODS

=head2 _validate_path($path)

validates a L<Data::Path> path for validity.

=cut

sub _validate_path {
    my ($self, $path) = @_;
    return 1 if $path =~ qr/^\/.*[^\/]$/;
    return;
}



=head1 TODO

Should Data::Annotate wrap data? or stay a collection of annotations?
    
Make Data::Annotate return the data from a requested path.
my $info = $da->get($path, $data) basically just a wrapper around L<Data::Path> get()

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jeremy Wall, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Jeremy Wall, C<< <jeremy at marzhillstudios.com> >>

=cut

1;
