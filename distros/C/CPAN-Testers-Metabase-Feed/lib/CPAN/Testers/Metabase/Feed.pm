# 
# This file is part of CPAN-Testers-Metabase-Feed
# 
# This software is Copyright (c) 2010 by David Golden.
# 
# This is free software, licensed under:
# 
#   The Apache License, Version 2.0, January 2004
# 
use 5.008001;
use strict;
use warnings;
use utf8;
use autodie 2.00;

package CPAN::Testers::Metabase::Feed;
BEGIN {
  $CPAN::Testers::Metabase::Feed::VERSION = '0.001';
}
# ABSTRACT: Generate Atom feed for CPAN Testers Reports

use Moose;
use MooseX::Types::ISO8601 qw/ ISO8601DateTimeStr /;

use Data::GUID;
use DateTime;
use DateTime::Format::ISO8601;
use File::Slurp qw/write_file/;
use JSON;
use Metabase::Librarian 0.013; # bug fixes on extraction
use XML::Feed;

use namespace::autoclean;


has 'ct_metabase' => (
  is        => 'ro',
  does      => 'Metabase::Gateway',
  required  => 1,
);


has 'since' => (
  is        => 'ro',
  isa       => ISO8601DateTimeStr,
  lazy      => 1,
  builder   => '_build_since',
);

has '_feed' => (
  is        => 'ro',
  isa       => 'XML::Feed',
  lazy    => 1,
  builder => '_build__feed',
);

sub _build_since {
  my $dt = DateTime->now;
  $dt->subtract( hours => 1 );
  return $dt->iso8601 . "Z";
}

sub _build__feed {
  my $self = shift;
  local $XML::Atom::DefaultVersion = "1.0";

  my $mb = $self->ct_metabase;
  my $librarian = $mb->public_librarian;
  my $json = JSON->new->pretty;
  my $since = $self->since;
  $since =~ s/Z?$/Z/;

  my $guids = $librarian->search(
    'core.type' => 'CPAN-Testers-Fact-TestSummary',
    'core.update_time' => { ">", $since },
    -desc => 'core.update_time',
  );

  my $feed = XML::Feed->new('Atom');
  $feed->title('CPAN Testers 2.0 Recent Submissions');
  $feed->link('http://metabase.cpantesters.org/');
  $feed->self_link('http://metabase.cpantesters.org/tail/recent.xml');
  $feed->modified( DateTime->now() );
  $feed->id( "urn:uuid:" . lc Data::GUID->new->as_string );

  for my $g ( @$guids ) {
    my $fact = $librarian->extract($g);
    if ($fact) {
      my $content = $fact->content;
      my $resource = $fact->resource;
      my $ts = $fact->update_time;
      my $fn = $self->_creator_name( $fact->creator );
      my $df = $resource->dist_file;
      my $gr = $content->{grade};
      my $ar = $content->{archname};
      my $pv = $content->{perl_version};
      my $msg = "[$gr] [$df] [$ar] [perl-$pv]";
      my $data = {
          resource => $fact->resource_metadata,
          content => $fact->content_metadata,
      };
      my $entry = XML::Feed::Entry->new('Atom');
      $entry->id( "metabase:fact:" . $fact->guid );
      $entry->title($msg);
      $entry->author($fn);
      $entry->summary($msg);
      $entry->content($json->encode( $data ));
      $entry->issued(DateTime::Format::ISO8601->parse_datetime( $ts ));
      $entry->modified( $entry->issued );
      $entry->category( $resource->dist_name );
      $feed->add_entry($entry);
    }
  }
  return $feed;
}


sub as_xml {
  my $self = shift;
  return $self->_feed->as_xml;
}


sub save {
  my ($self, $filename) = @_;
  Carp::croak( "No filename argument provided to save()" ) unless $filename;
  return write_file( $filename, { atomic => 1, binmode => ":utf8" }, $self->as_xml );
}

my %creator_fn;
sub _creator_name {
  my ($self, $resource) = @_;
  return $creator_fn{$resource} if exists $creator_fn{$resource};
  my $creator = $self->ct_metabase->public_librarian->extract( $resource->guid );
  my ($fn_fact) = grep { ref $_ eq 'Metabase::User::FullName' } $creator->facts;
    die "Couldn't find FullName for $resource" unless $fn_fact;
  return $creator_fn{$resource} = $fn_fact->content;
}

__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

CPAN::Testers::Metabase::Feed - Generate Atom feed for CPAN Testers Reports

=head1 VERSION

version 0.001

=head1 SYNOPSIS

   use CPAN::Testers::Metabase::Feed;
   use CPAN::Testers::Metabase::AWS;
 
   my $mb = CPAN::Testers::Metabase::AWS->new(
     bucket    => 'myS3bucket',
     namespace => 'prod'
   );
 
   my $feed = CPAN::Testers::Metabase::Feed->new( ct_metabase => $mb );
 
   $feed->save('recent.xml');

=head1 DESCRIPTION

This module creates a 'recent reports' feed from a CPAN Testers Metabase
in Atom format.  Each entry has a title with summary information. The content
is HTML-encoded, but when decoded is just JSON text with report metadata.

=head1 ATTRIBUTES

=head2 ct_metabase (required)

A CPAN::Testers::Metabase subclass that will be used to generate
a feed of recent reports.

=head2 since

An ISO8601 date time string. The feed will contain all reports since the given
date.  It defaults to "now" minus one hour.

=head1 METHODS

=head2 as_xml

  $feed->as_xml;

Returns the feed as a string in XML format.

=head2 save

  $feed->save( $filename );

Saves the feed as XML to the given file.  If the file exists, it is replaced
atomically.

=for Pod::Coverage method_names_here

=head1 SEE ALSO

=over

=item *

L<CPAN::Testers::Metabase>

=back

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut


__END__


