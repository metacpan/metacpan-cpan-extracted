use 5.014;    # /r modifier
use strict;
use warnings;

package expand_author_list;

# ABSTRACT: Expand a DATA section into a CPAN Authors list

# AUTHORITY

use HTTP::Tiny;
use Parse::CPAN::Whois;
use Acme::CPANAuthors::Factory;
use JSON::MaybeXS 1.001000;
use Path::Tiny qw(path);
use HTML::Entities;
use Math::Random::MT;

sub tempdir { return state $tempdir = Path::Tiny->tempdir() }
sub http    { return state $http    = HTTP::Tiny->new() }
sub json    { return state $json    = JSON::MaybeXS->new( utf8 => 0 ) }

sub rng {
  return state $rng = Math::Random::MT->new( map { unpack 'L', $_ } q[Kent], q[ is ], q[a du], q[ll b], q[oy  ] );
}

sub dolog { *STDERR->print("[32m$_[0][0m\n") }

sub mirror_whois {
  my ($filename) = @_;
  my $out = tempdir()->child($filename);
  dolog("Fetching $filename to $out");
  my $response = http()->mirror( 'http://www.cpan.org/authors/' . $filename, $out );
  die "failed to fetch $filename: $response->{status} $response->{reason}\n"
    if not $response->{success} and $response->{status} ne '304';
  return "$out";
}

sub get_gravatar_url {
  my ($authorid) = @_;
  dolog("Resolving Gravatar for $authorid");
  my $request = http()->get( 'http://api.metacpan.org/v0/author/' . $authorid ) // {};
  my $content = $request->{content}                                             // {};
  my $json    = json()->decode($content);
  my $url     = $json->{gravatar_url};
  $url =~ s/s=\K130/80/g;
  return $url;
}

sub extract_data {
  state $result_cache = {};
  my ( $category, $source_file ) = @_;
  return $result_cache->{$category} if exists $result_cache->{$category};

  my $author_data = Parse::CPAN::Whois->new( mirror_whois('00whois.xml') );

  my $author_hash = {};
  my @authors;

  for my $id ( path($source_file)->lines_raw( { chomp => 1 } ) ) {
    dolog("$category / $id");
    my $name = $author_data->author($id)->name;
    $author_hash->{$id} = $name;
    push @authors,
      {
      id     => $id,
      name   => $name,
      avatar => get_gravatar_url($id),
      };
  }
  my $author_db = Acme::CPANAuthors::Factory->create( $category . '_temp' => $author_hash );
  for my $author (@authors) {
    $author->{dists} = $author_db->distributions( $author->{id} ) // 0;
  }

  return ( $result_cache->{$category} = [ sort { $b->{dists} <=> $a->{dists} || $a->{id} cmp $b->{id} } @authors ] );
}

sub authors_to_code {
  my (%config) = ref $_[0] ? %{ $_[0] } : @_;

  my $plugin         = $config{plugin};
  my $plugin_name    = $config{plugin_name} // ref $config{plugin};
  my $plugin_version = $config{plugin_version} // $plugin_name->VERSION;
  my $category       = $config{category};

  my $authors     = '';
  my $avatar_urls = '';

  for my $author ( @{ $config{data} } ) {
    $authors     .= "    $author->{id} => '$author->{name}',\n";
    $avatar_urls .= "    $author->{id} => '$author->{avatar}',\n";
  }

  my @display_authors = map { $config{data}->[ rng->irand() % scalar @{ $config{data} } ] } 1;

  return <<"EOF";
# Code inserted by inc/expand_author_list#authors_to_code
# by $plugin_name $plugin_version
## no critic (ValuesAndExpressions::RestrictLongStrings)
my \%authors  = (
$authors);

my \%avatar_urls = (
$avatar_urls);

## use critic

=method authors

  my \$scalar_ref = Acme::CPANAuthors::${category}\->authors;
  my \%hash       = Acme::CPANAuthors::${category}\->authors;

=cut

sub authors { return ( wantarray ? \%authors : \\\%authors ) }

=method category

  my \$scalar = Acme::CPANAuthors::${category}\->category;

=cut

sub category { return '$category' }

=method avatar_url

  my \$url = Acme::CPANAuthors::${category}\->avatar_url('$display_authors[0]->{id}');

=cut

sub avatar_url {
  my ( \$id ) = \@_;
  return \$avatar_urls{\$id};
}

# end generated code
EOF

}

sub authors_to_avatars {
  my (%config) = ref $_[0] ? %{ $_[0] } : @_;

  my $plugin         = $config{plugin};
  my $plugin_name    = $config{plugin_name} // ref $config{plugin};
  my $plugin_version = $config{plugin_version} // $plugin_name->VERSION;

  my @lines;
  for my $author ( @{ $config{data} } ) {
    my $name = encode_entities( $author->{name} );
    my $title = "$author->{id} ($name), $author->{dists} distribution" . ( $author->{dists} != 1 ? 's' : '' );
    push @lines,
        qq{<a href="http://metacpan.org/author/$author->{id}">}
      . q{<span>}
      . q{<img style="margin: 0 5px 5px 0;" width="80" height="80" }
      . qq{src="$author->{avatar}" alt="$author->{id}" title="$title" />}
      . q{</span>} . q{</a>};
  }
  my $content = join( "<!--\n-->", @lines );

  return <<"EOF";
<div style="text-align:center;padding:0px!important;overflow-y:hidden;
margin-left: auto; margin-right: auto; max-width: 430px">
<!-- Data inserted by inc/expand_author_list#authors_to_avatars
 by $plugin_name $plugin_version -->
$content
</div>
EOF

}

sub mbti_type {
  my ($type) = @_;
  return <<"EOF";
  L<< C<$type>|https://en.wikipedia.org/wiki/$type >>
EOF
}

sub mbti_description_text {
  my ($type) = @_;
  my $lctype = lc($type);
  return <<"EOF";
For more details see L<< C<Acme::CPANAuthors::MBTI>|Acme::CPANAuthors::MBTI >>.

=over 4

=item * L<< C<$type> on personalitypage.com|http://personalitypage.com/$type.html >>

=item * L<< C<$type> on typelogic.com|http://typelogic.com/$lctype.html >>

=item * L<< C<$type> on Wikipedia|https://en.wikipedia.org/wiki/$type >>

=back

EOF
}

sub mbti_description {
  my (%config) = ref $_[0] ? %{ $_[0] } : @_;

  my $html        = authors_to_avatars( \%config );
  my $description = mbti_description_text( $config{type} );
  my $link        = mbti_type( $config{type} );

  return <<"EOF";
This class provides a hash of PAUSE ID's and names of authors
who have identified themselves as $link

=begin html

$html

=end html

$description

EOF

}

sub generate_synopsis {
  my (%config) = ref $_[0] ? %{ $_[0] } : @_;

  my $plugin         = $config{plugin};
  my $plugin_name    = $config{plugin_name} // ref $config{plugin};
  my $plugin_version = $config{plugin_version} // $plugin_name->VERSION;
  my @items          = @{ $config{'data'} };
  my @authors        = map { $items[ rng->irand() % scalar @items ] } 1 .. 3;

  return ( <<"EOF" =~ s/^(\S)/    $1/msgr );
use Acme::CPANAuthors;
use Acme::CPANAuthors::$config{category};
# Or just use Acme::CPANAuthors::MBTI

my \$authors  = Acme::CPANAuthors->new('$config{category}');
my \$number   = \$authors->count;
my \@ids      = \$authors->id;
my \@distros  = \$authors->distributions('$authors[0]->{id}');
my \$url      = \$authors->avatar_url('$authors[1]->{id}');
my \$kwalitee = \$authors->kwalitee('$authors[2]->{id}');

my \%authorshash    = Acme::CPANAuthors::$config{category}\->authors;
my \$authorshashref = Acme::CPANAuthors::$config{category}\->authors;
my \$category       = Acme::CPANAuthors::$config{category}\->category;

EOF
}

1;
