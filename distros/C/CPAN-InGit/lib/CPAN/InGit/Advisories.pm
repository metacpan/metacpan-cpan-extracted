package CPAN::InGit::Advisories;
our $VERSION = '0.007'; # VERSION
# ABSTRACT: Look up security advisories (CVEs) that affect a release of a distribution


use Carp;
use Moo;
use JSON::PP;
use Log::Any '$log';
use CPAN::InGit::DistTree;
use version ();
use v5.36;


has data        => ( is => 'ro', required => 1 );
has source_path => ( is => 'ro' );
has fetched     => ( is => 'ro' );
has _compiled   => ( is => 'ro', default => sub { +{} } );


sub new_from_json($class, $bytes, %attrs) {
   my $start= index $bytes, '{';
   $start >= 0 or croak "Missing CPANSA JSON";
   my $data= JSON::PP->new->utf8->decode(substr $bytes, $start);
   ref $data eq 'HASH' or croak "Invalid CPANSA database";
   ref $data->{$_} eq 'ARRAY' or croak "Invalid CPANSA advisory list for '$_'"
      for keys %$data;
   return $class->new(%attrs, data => $data);
}


sub parse_version($class, $str) {
   return undef unless defined $str;
   $str =~ s/\A\s+|\s+\z//g;
   return undef unless $str =~ /\A(?:v?\d+(?:\.\d+)+(?:_\d+)?|v?\d+|\.\d+(?:_\d+)?|\d+\.)\z/;
   $str =~ tr/_//d;
   return eval { version->parse($str) };
}

sub _compile_range($class, $range) {
   return sub { 1 } if $range eq '*';
   my @conditions;
   for (split /,/, $range) {
      my ($op, $ver)= /\A\s*(<=|>=|==|!=|=|<|>)\s*(\S+)\s*\z/
         or die "Unsupported affected-version range '$range'\n";
      my $v= $class->parse_version($ver) // die "Unsupported version '$ver' in range '$range'\n";
      push @conditions, [ $op, $v ];
   }
   @conditions or die "Empty affected-version range\n";
   return sub ($version) {
      for (@conditions) {
         my ($op, $v)= @$_;
         my $cmp= $version <=> $v;
         return 0 unless $op eq '<'? $cmp < 0 : $op eq '<='? $cmp <= 0
                       : $op eq '>'? $cmp > 0 : $op eq '>='? $cmp >= 0
                       : $op eq '!='? $cmp != 0 : $cmp == 0;
      }
      return 1;
   };
}

# Returns [ [ \%public_advisory, \@range_matchers ], ... ] for one distribution
sub _advisories_for($self, $dist_name) {
   return $self->_compiled->{$dist_name} //= do {
      my @list;
      for my $entry (@{ $self->data->{$dist_name} // [] }) {
         next unless ref $entry eq 'HASH';
         my $ranges= $entry->{affected_versions} // $entry->{version_range} // [];
         $ranges= [] unless ref $ranges eq 'ARRAY';
         my (@matchers, $unreadable);
         for my $range (grep defined && !ref, @$ranges) {
            my $matcher= eval { ref($self)->_compile_range($range) };
            if ($matcher) { push @matchers, $matcher }
            else {
               $log->warnf("Advisory for %s: %s", $dist_name, $@ =~ s/\n\z//r);
               $unreadable= 1;
            }
         }
         my %seen;
         my @ids= grep defined && !ref && !$seen{$_}++,
            (ref $entry->{cves} eq 'ARRAY'? @{ $entry->{cves} } : ()),
            @{$entry}{qw( cve_id cpansa_id id )};
         my %advisory= (
            ids               => \@ids,
            affected_versions => [ grep defined && !ref, @$ranges ],
         );
         my @fixed= grep defined && !ref,
            ref $entry->{fixed_versions} eq 'ARRAY'? @{ $entry->{fixed_versions} } : ();
         $advisory{fixed_versions}= \@fixed if @fixed;
         defined $entry->{$_} && !ref $entry->{$_} and $advisory{$_}= $entry->{$_}
            for qw( title severity reported description );
         # A range that can't be understood is treated as matching.  It is better to have a
         # person look at an advisory than to silently report a release as unaffected.
         push @list, [ \%advisory, \@matchers, $unreadable ];
      }
      \@list;
   };
}


sub affecting($self, $dist_name, $version) {
   my $v= ref $version? $version : ref($self)->parse_version($version);
   return () unless defined $v;
   return map $_->[0], grep {
      my ($adv, $matchers, $unreadable)= @$_;
      $unreadable || !@{ $adv->{affected_versions} } || grep $_->($v), @$matchers;
   } @{ $self->_advisories_for($dist_name) };
}


sub affecting_path($self, $author_path) {
   my ($dist_name, $version)= CPAN::InGit::DistTree->parse_release($author_path)
      or return ();
   return $self->affecting($dist_name, $version);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::InGit::Advisories - Look up security advisories (CVEs) that affect a release of a distribution

=head1 SYNOPSIS

  my $advisories= $cpan_repo->load_advisories;   # downloads or re-uses the CPANSA feed
  # or
  my $advisories= CPAN::InGit::Advisories->new_from_json($json_text);

  for ($advisories->affecting_path('A/AU/AUTHOR/Example-1.02.tar.gz')) {
    say join ' ', @{ $_->{ids} }, $_->{severity} // '';
  }

=head1 DESCRIPTION

This is an index of the L<CPAN Security Advisory|https://github.com/CPAN-Security> feed, the
same file which the web interface of L<CPAN::InGit::Server> downloads for its "Check CVEs"
button.  The semantics of the affected-version ranges follow L<Test::CVE>: an advisory
affects a version when I<any> of its ranges match, and a range matches when I<all> of its
comma-separated comparisons match.  An advisory without ranges affects every version.

Advisories apply to releases of a distribution, so versions are always the version of the
distribution file, not the C<$VERSION> of a module in it.

=head1 ATTRIBUTES

=head2 data

The decoded feed: a hashref of C<< { $distribution_name => [ \%advisory, ... ] } >>

=head2 source_path

The path of the file this was loaded from, if any.

=head2 fetched

The epoch time when the feed was last downloaded or confirmed current, if known.

=head1 METHODS

=head2 new_from_json

  my $advisories= CPAN::InGit::Advisories->new_from_json($bytes, %attributes);

Parse the text of the feed.  Some revisions of the feed have a plain-text warning before the
JSON, which is ignored.  Dies if the text is not a feed.

=head2 parse_version

  my $version= CPAN::InGit::Advisories->parse_version('1.02_03');

Return a L<version> object, or C<undef> if the string is not a version.  Underscores are
ignored, so that a development release compares by its digits.

=head2 affecting

  my @advisories= $advisories->affecting($distribution_name, $version);

Return the advisories that affect this version of a distribution, like
C<< ->affecting('Example', '1.02') >>.  Each is a hashref of plain data:

  {
    ids               => [ 'CVE-2025-1234', 'CPANSA-Example-2025-01' ],
    affected_versions => [ '<1.03' ],
    fixed_versions    => [ '>=1.03' ],    # when the feed has it (and likewise below)
    title             => '...',
    severity          => 'high',
    reported          => '2025-01-02',
    description       => '...',
  }

Returns an empty list if the version can't be parsed.

=head2 affecting_path

  my @advisories= $advisories->affecting_path('A/AU/AUTHOR/Example-1.02.tar.gz');

Same as L</affecting>, for the name and version in the file name of a distribution archive.

=head1 VERSION

version 0.007

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad, and IntelliTree Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
