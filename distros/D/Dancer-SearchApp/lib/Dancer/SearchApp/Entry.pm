package Dancer::SearchApp::Entry;
use strict;
use Moo;

use vars qw($VERSION $es $server);
$VERSION = '0.06';

=head1 NAME

Dancer::SearchApp::Entry - a search index entry

=head1 SYNOPSIS

  my $entry = Dancer::SearchApp::Entry->new({
      url => 'http://www.example.com/',
      title => 'An Example',
      content => '<html>...</html>',
      language => 'en',
      mime_type => 'text/html',
      author => 'A. U. Thor',
  });

This is a aonvenience package to hold the information on an entry in the index.
This should basically match whatever you have in the index, like an ORM
or a glorified hash.

=head1 METHODS

=head2 C<< ->url >>

=head2 C<< ->id >>

=head2 C<< ->mime_type >>

=head2 C<< ->author >>

=head2 C<< ->creation_date >>

=head2 C<< ->content >>

=head2 C<< ->title >>

=head2 C<< ->folder >>

=head2 C<< ->language >>

=cut

# Canonical URL
has url => (
    is => 'ro',
    #isa => 'Str',
);

{
no warnings 'once';
*id = \*url;
}

has mime_type => (
    is => 'ro',
    #isa => 'Str',
);

has author => (
    is => 'ro',
    #isa => 'Str',
);

has creation_date => (
    is => 'ro',
    #isa => 'Str',
);

has content => (
    is => 'ro',
    #isa => 'Str', # HTML-String
);

has title => (
    is => 'ro',
    #isa => 'Str',
);

has folder => (
    is => 'ro',
    #isa => 'Str',
);

has language => (
    is => 'ro',
    #isa => 'Str', # 'de', not (yet) de-DE
);

=head2 C<< ->from_es >>

Parses the elements as returned from Elasticsearch.

=cut

sub from_es {
    my( $class, $result ) = @_;
    my %args = %{ $result->{_source} };
    if( $args{ "Content-Type" } ) {
        $args{ mime_type } = delete $args{ "Content-Type" };
    };
    my $self = $class->new( %args );
    $self
}

=head2 C<< ->basic_mime_type >>

  if( 'text/plain' eq $item->basic_mime_type ) {
      print "<pre>" . $item->content . "</pre>"
  }

Converts

  text/plain; encoding=Latin-1

to

  text/plain

=cut

sub basic_mime_type {
    my( $self ) = @_;
    my $mt = $self->mime_type;
    
    $mt =~ s!;.*!!;
    
    $mt
}

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/dancer-searchapp>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 TALKS

I've given a talk about this module at Perl conferences:

L<German Perl Workshop 2016, German|http://corion.net/talks/dancer-searchapp/dancer-searchapp.html>

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dancer-SearchApp>
or via mail to L<dancer-searchapp-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2014-2016 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
