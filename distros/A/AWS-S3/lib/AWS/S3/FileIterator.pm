package AWS::S3::FileIterator;

use strict;
use warnings 'all';
use Carp 'confess';
use AWS::S3::Owner;
use AWS::S3::File;

sub new {
  my ($class, %args) = @_;

  my $s = bless {
    data        => [ ],
    page_number => 0,
    idx         => 0,
    %args,
  }, $class;
  $s->_init;
  return $s;
}

sub _init {
    my ( $s ) = @_;

    foreach ( qw( bucket page_size page_number ) ) {
        confess "Required argument '$_' was not provided"
          unless $s->{$_};
    }    # end foreach()

    $s->{page_number}--;
    $s->{marker}               = '' unless defined( $s->{marker} );
    $s->{__fetched_first_page} = 0;
    $s->{data}                 = [];
    $s->{pattern} ||= qr(.*);
}    # end _init()

sub marker    { shift->{marker} }
sub pattern   { shift->{pattern} }
sub bucket    { shift->{bucket} }
sub page_size { shift->{page_size} }
sub prefix    { shift->{prefix} }

sub has_prev {
    my $s = shift;

    return $s->page_number > 1;
}    # end has_prev()

sub has_next { shift->{has_next} }

sub next {
  my $s = shift;

  if( exists( $s->{data}->[ $s->{idx} ] ) ) {
    return $s->{data}->[ $s->{idx}++ ];
  } else {
    # End of the current resultset, see if we can get another page of records:
    if( my $page = $s->next_page ) {
      $s->{data} = $page;
      $s->{idx} = 0;
      return $s->{data}->[ $s->{idx}++ ];
    } else {
      # No more pages, no more data:
      return;
    }
  }
}

sub reset {
  my $s = shift;
  $s->{idx} = 0;
}


sub page_number {
    my $s = shift;
    @_ ? $s->{page_number} = $_[0] - 1 : $s->{page_number};
}    # end page_number()

# S3 returns files 100 at a time.  If we want more or less than 100, we can't
# just fetch the next page over and over - that would be inefficient and likely
# to cause errors.

# If the page size is 5 and page number is 2, then we:
#   - fetch 100 items
#   - store them
#   - iterate internally until we get to 'page 2'
#   - return the result.
# If the page size is 105 and page number is 1, then we:
#   - fetch 100 items
#   - fetch the next 100 items
#   - return the first 105 items, keeping the remaining 95 items
#   - on page '2', fetch the next 100 items and return 105 items, saving 90 items.
# If the page size is 105 and page number is 3, then we:
#   - fetch items until our internal 'start' marker is 316-420
#   - return items 316-420
sub next_page {
    my $s = shift;

    # Advance to page X before proceding:
    if ( ( !$s->{__fetched_first_page}++ ) && $s->page_number ) {

        # Advance to $s->page_number
        my $start_page = $s->page_number;
        my $to_discard = $start_page * $s->page_size;
        my $discarded  = 0;
        while ( 1 ) {
            my $item = $s->_next
              or last;
            $discarded++ if $item->{key} =~ $s->pattern;
            last if $discarded > $to_discard;
        }    # end while()
    }    # end if()

    my @chunk = ();
    while ( my $item = $s->_next() ) {
        next unless $item->{key} =~ $s->pattern;
        push @chunk, $item;
        last if @chunk == $s->page_size;
    }    # end while()

    my @out = map {
        my $owner = AWS::S3::Owner->new( %{ $_->{owner} } );
        delete $_->{owner};
        AWS::S3::File->new( %$_, owner => $owner );
    } @chunk;

    $s->{page_number}++;

    return unless @out;
    wantarray ? @out : \@out;
}    # end next_page()

sub _next {
    my $s = shift;

    if ( my $item = shift( @{ $s->{data} } ) ) {
        return $item;
    } else {
        if ( my @chunk = $s->_fetch() ) {
            push @{ $s->{data} }, @chunk;
            return shift( @{ $s->{data} } );
        } else {
            return;
        }    # end if()
    }    # end if()
}    # end _next()

sub _fetch {
    my ( $s ) = @_;

    my $path   = $s->{bucket}->name . '/';
    my %params = ();
    $params{marker} = $s->{marker} if $s->{marker};
    $params{prefix} = $s->{prefix} if $s->{prefix};
    $params{max_keys} = 1000;
    $params{delimiter} = $s->{delimiter} if $s->{delimiter};

    my $type     = 'ListBucket';
    my $request  = $s->{bucket}->s3->request( $type, %params, bucket => $s->{bucket}->name );
    my $response = $request->request();

    $s->{has_next} = ( $response->xpc->findvalue( '//s3:IsTruncated' ) || '' ) eq 'true' ? 1 : 0;

    my @files = ();
    foreach my $node ( $response->xpc->findnodes( '//s3:Contents' ) ) {
        my ( $owner_node ) = $response->xpc->findnodes( './/s3:Owner', $node );
        my $owner = {
            id           => $response->xpc->findvalue( './/s3:ID',          $owner_node ),
            display_name => $response->xpc->findvalue( './/s3:DisplayName', $owner_node )
        };
        my $etag = $response->xpc->findvalue( './/s3:ETag', $node );
        push @files,
          {
            bucket => $s->{bucket},
            key          => $response->xpc->findvalue( './/s3:Key',          $node ),
            lastmodified => $response->xpc->findvalue( './/s3:LastModified', $node ),
            etag         => $response->xpc->findvalue( './/s3:ETag',         $node ),
            size         => $response->xpc->findvalue( './/s3:Size',         $node ),
            owner        => $owner,
          };
    }    # end foreach()

    if ( @files ) {
        $s->{marker} = $files[-1]->{key};
    }    # end if()

    return unless defined wantarray;
    @files ? return @files : return;
}    # end _fetch()

1;

__END__

=pod

=head1 NAME

AWS::S3::FileIterator - Easily access and iterate through your S3 files.

=head1 SYNOPSIS

  # Iterate through all ".txt" files, 100 at a time:
  my $iter = $bucket->files(
    # Required params:
    page_size   => 100,
    page_number => 1,
    # Optional params:
    pattern     => qr(\.txt$),
    prefix      => 'notes',
  );
  
  while( my @files = $iter->next_page )
  {
    warn $iter->page_number, "\n";
    foreach my $file ( @files )
    {
      print "\t", $file->key, "\n";
    }# end foreach()
  }# end while()


=head1 DESCRIPTION

AWS::S3::FileIterator provides a means of I<iterating> through your S3 files.

If you only have a few files it might seem odd to require an iterator, but if you
have thousands (or millions) of files, the iterator will save you a lot of effort.

=head1 PUBLIC PROPERTIES

=head2 has_prev

Boolean - read-only

=head2 has_next

Boolean - read-only

=head2 page_number

Integer - read-write

=head2 marker

String - read-only

Used internally to tell Amazon S3 where the last request for a listing of files left off.

=head2 pattern

Regexp - read-only

If supplied to the constructor, only files which match the pattern will be returned.

=head2 prefix

String - read-only

If supplied to the constructor, only files which begin with the indicated prefix will be returned.

=head1 PUBLIC METHODS

=head2 next_page()

Returns the next page of results as an array in list context or arrayref in scalar context.

Increments C<page_number> by one.

=head1 SEE ALSO

L<The Amazon S3 API Documentation|http://docs.amazonwebservices.com/AmazonS3/latest/API/>

L<AWS::S3>

L<AWS::S3::Bucket>

L<AWS::S3::File>

L<AWS::S3::Owner>

L<Iterator::Paged> - on which this class is built.

=cut

