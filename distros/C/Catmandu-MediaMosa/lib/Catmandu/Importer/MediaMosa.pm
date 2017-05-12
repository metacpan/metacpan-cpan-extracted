package Catmandu::Importer::MediaMosa;
use Catmandu::Sane;
use Catmandu::MediaMosa;
use Moo;

our $VERSION = '0.279';

with 'Catmandu::Importer';

has base_url  => (is => 'ro' , required => 1);
has user      => (is => 'ro' , required => 1);
has password  => (is => 'ro' , required => 1);
has mm => (is => 'ro' , init_arg => undef , lazy => 1 , builder => '_build_mm');

sub _build_mm {
  my ($self) = @_;
  Catmandu::MediaMosa->new(base_url => $self->base_url , user => $self->user , password => $self->password);
} 

sub generator {
  my ($self) = @_;
  
  sub {
    state $offset = 0;
    state $res    = [];
    
    if (@{$res} == 0) {
      my $vpcore = $self->mm->asset_list({ offset => $offset  , limit => 10 });
      return undef unless defined $vpcore;
      my $hits  = $vpcore->header->item_count_total;
      my $count = $vpcore->header->item_count;
      $res = $vpcore->items->to_array;
      $offset += $count;
    }
    
    my $asset = shift @{$res};
    return undef unless $asset; 
    $self->mm->asset($asset)->items->first
  }
}

=head1 NAME

Catmandu::Importer::MediaMosa - Package that imports MediaMosa asset information into your application

=head1 SYNOPSIS

    use Catmandu::Importer::MediaMosa;

    my $importer = Catmandu::Importer::MediaMosa->new(base_url => '...' , user => '...' , password => '...' );

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 METHODS

=head2 new(query => '...')

Create a new MediaMosa importer using a query as input.

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::MediaMosa methods are not idempotent: MediaMosa feeds can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=head1 AUTHOR

Patrick Hochstenbach C<< Patrick Hochstenbach at UGent be >>

=cut

1;
