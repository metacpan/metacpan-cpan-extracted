package Catmandu::Importer::AlephX;
use Catmandu::Sane;
use Catmandu::Util qw(:check :is);
use Moo;
use Catmandu::AlephX;
use Data::Dumper;

with 'Catmandu::Importer';

our $VERSION = '0.02';

has url     => (is => 'ro', required => 1);
has base    => (is => 'ro', required => 1);
has query   => (is => 'ro' );
has skip_deleted => (is => 'ro', default => sub { 0 });
has include_items => (is => 'ro',required => 0,lazy => 1,default => sub { 1; });
has limit => (
  is => 'ro',
  isa => sub { check_natural($_[0]); },
  lazy => 1,
  default => sub { 20; }
);
has alephx   => (is => 'ro', init_arg => undef , lazy => 1 , builder => '_build_alephx');

sub _build_alephx {
  Catmandu::AlephX->new(url => $_[0]->url);
}

sub _fetch_items {
  my ($self, $doc_number) = @_;
  my $item_data = $self->alephx->item_data(base => $self->base, doc_number => $doc_number);
  
  return [] unless $item_data->is_success;
  return $item_data->items;
}

sub check_deleted {
    my $r = $_[0];
    return 1 unless defined $r;
    for (@{$r->{record}}) {
        return 1 if ($_->[0] eq 'DEL');
    }
    return 0;
}

sub generator {
  my $self = $_[0];

  #generator, based on a query (limited)
  if(is_string($self->query)){

    return sub {
      my $find = $self->alephx->find(request => $self->query , base => $self->base);

      return unless $find->is_success;

      state $buffer = [];
      state $set_number = $find->set_number;
      state $no_records = int($find->no_records);
      state $no_entries = int($find->no_entries);

      #warning: no_records is the number of records found, but only no_entries are stored in the set.
      #         a call to 'present' with set_number higher than no_entries has no use.
     
      state $offset = 1;
      state $limit = $self->limit;

      return if $no_entries == 0 || $offset > $no_entries;

      unless(@$buffer){

        my $set_entry;
        {
          my $start = Catmandu::AlephX->format_doc_num($offset);
          my $l = $offset + $limit - 1;
          my $end = Catmandu::AlephX->format_doc_num($l > $no_entries ? $no_entries : $l);
          $set_entry = "$start-$end";        
        }
        
        my $present = $self->alephx->present(set_number => $set_number , set_entry => $set_entry);
        return unless $present->is_success;

        for my $record(@{ $present->records() }){

          my $items = [];
          if($self->include_items){
            $items = $self->_fetch_items($record->{doc_number});
          }
          #do NOT use $record->metadata->data->{_id}, for that uses the field '001' that can be empty
          push @$buffer,{ record => $record->metadata->data->{record} , items => $items, _id => $record->{doc_number} };

        }

        $offset += $limit;

      }

      shift(@$buffer);
    };

  }
  #generator that tries to fetch all records
  else{

    return sub {

      state $count = 1;
      state $alephx = $self->alephx;
   
      my $doc;

      do { 
        my $doc_num = Catmandu::AlephX->format_doc_num($count++);
        my $find_doc = $alephx->find_doc(base => $self->base,doc_num => $doc_num);
      
        return unless $find_doc->is_success;

        my $items = [];
      
        if($self->include_items){
            $items = $self->_fetch_items($doc_num);
        }

        $doc = {
            record => $find_doc->record->metadata->data->{record},
            items => $items,
            #do NOT use $record->metadata->data->{_id}, for that uses the field '001' that can be empty
            _id => $doc_num
        };
      } while ($self->skip_deleted && check_deleted($doc) == 1);
    
      return $doc;
    };
  }
}

=head1 NAME

Catmandu::Importer::AlephX - Package that imports metadata records from the AlephX service

=head1 SYNOPSIS

    use Catmandu::Importer::AlephX;

    my $importer = Catmandu::Importer::AlephX->new(
                        url => 'http://ram19:8995/X' ,
                        query => 'WRD=(art)' ,
                        base => 'usm01' ,
                        );

    my $n = $importer->each(sub {
        my $r = $_[0];
        # ...
        say Dumper($r->{record});
        say Dumper($r->{items});
    });

=head1 METHODS

=head2 new(url => '...' , base => '...' , query => '...')

Create a new AlephX importer. Required parameters are the url baseUrl of the AlephX service, an Aleph 'base' catalog name and a 'query'.

=head3 common parameters

    url             base url of alephx service (e.g. "http://ram19:8995/X")
    include_items   0|1. When set to '1', the items of every bibliographical record  are retrieved
    
=head3 alephx parameters

    base    name of catalog in Aleph where you want to search    
    query   the query of course

=head3 output

  {
    record => [
      [
        'FMT',
        '',
        '',
        '_',
        'MX'
      ],
      [
        'LDR',
        '',
        '',
        '_',
        '01236npca^22001937|^4500'
      ]
      ..
    ],
    items => [
      {
        'sub-library' => 'WID',
        'chronological-k' => '',
        'chronological-i' => '',
        'library' => 'USM50',
        'collection' => 'HD',
        'call-no-1' => '$$2ZHCL$$hH 810.80.20',
        'chronological-j' => '',
        'requested' => 'N',
        'expected' => 'N',
        'barcode' => 'HWM4M4',
        'description' => '',
        'note' => '',
        'item-status' => '01',
        'rec-key' => '000048762000010',
        'enumeration-a' => '',
        'call-no-2' => '',
        'enumeration-b' => '',
        'enumeration-c' => '',
        'on-hold' => 'N'
      }
    ]

  }

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::AlephX methods are not idempotent: Twitter feeds can only be read once.

=head1 AUTHOR

Patrick Hochstenbach C<< patrick dot hochstenbach at ugent dot be >>

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
