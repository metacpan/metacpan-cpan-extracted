package Catmandu::Store::AlephX;
=head1 NAME

Catmandu::Store::AlephX - A Catmandu AlephX service implemented as Catmandu::Store

=head1 SYNOPSIS

 use Catmandu::Store::AlephX;

 my $store = Catmandu::Store::AlephX->new(url => 'http://aleph.ugent.be/X' , username => 'XXX' , password => 'XXX');

 $store->bag('usm01')->each(sub {
 });

=cut
use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(:is :check);
use Catmandu::AlephX;
use Moo;

our $VERSION = "1.071";

with 'Catmandu::Store';

has url => (is => 'ro', required => 1);
has username => ( is => 'ro' );
has password => ( is => 'ro' );
has skip_deleted => ( is => 'ro' , default => sub { 0 } );

has alephx => (
  is       => 'ro',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build_alephx',
);
around default_bag => sub {
  'usm01';
};

sub _build_alephx {
  my $self = $_[0];
  my %args = (url => $self->url());
  if(is_string($self->username) && is_string($self->password)){
    $args{default_args} = {
      user_name => $self->username,
      user_password => $self->password
    };
  }
  Catmandu::AlephX->new(%args);
}


package Catmandu::Store::AlephX::Bag;
use Catmandu::Sane;
use Moo;
use Catmandu::AlephX;
use Catmandu::Util qw(:check :is);
use Catmandu::Hits;
use Clone qw(clone);
use Carp qw(confess);

with 'Catmandu::Bag';
with 'Catmandu::Searchable';

#override automatic id generation from Catmandu::Bag
before add => sub {
  check_catmandu_marc($_[1]);
  $_[1] = clone($_[1]);
  if(is_string($_[1]->{_id})){
    $_[1]->{_id} =~ /^\d{9}$/o or confess("invalid _id ".$_[1]->{_id});
  }else{
    $_[1]->{_id} = Catmandu::AlephX->format_doc_num(0);
  }
};

sub check_catmandu_marc {
    my $r = $_[0];
    check_hash_ref($r);
    check_array_ref($r->{record});
    check_array_ref($_) for @{ $r->{record} };
}

sub check_deleted {
    my $r = $_[0];
    return 1 unless defined $r;
    for (@{$r->{record}}) {
        return 1 if ($_->[0] eq 'DEL');
    }
    return 0;
}

=head1 METHODS

=head2 get($id)

Retrieves a record from the Aleph database. Requires a record identifier. Returns a Catmandu MARC record
when found and undef on failure.

=cut
sub get {
  my($self,$id)=@_;
  my $alephx = $self->store->alephx;

  my $find_doc = $alephx->find_doc(
    format => 'marc',
    doc_num => $id,
    base => $self->name,
    #override user_name to disable user check
    user_name => ""
  );

  return undef unless($find_doc->is_success);

  my $doc = $find_doc->record->metadata->data;

  return undef if $self->store->skip_deleted && check_deleted($doc);

  return $doc;
}


=head2 add($catmandu_marc)

Adds or updates a record to the Aleph database. Requires a Catmandu type MARC record and a _id field
containing the Aleph record number. This method with throw an error when an add cant be executed.

=head3 example

  #add new record. WARNING: Aleph will ignore the 001 field,
  my $new_record = eval {
    $bag->add({
    record =>  [
      [
        'FMT',
        '',
        '',
        '_',
        'SE'
      ],
      [
        'LDR',
        '',
        '',
        '_',
        '00000cas^^2200385^a^4500'
      ],
      [
        '001',
        '',
        '',
        '_',
        '000000444'
      ],
      [
        '005',
        '',
        '',
        '_',
        '20140212095615.0'
      ]
      ..
    ]
  });

  };
  if ($@) {
    die "add failed $@";
  }

  say "new record:".$record->{_id};

=cut
sub add {
  my($self,$data)=@_;

  my $alephx = $self->store->alephx;

  #insert/update
  my $update_doc = $alephx->update_doc(
    library => $self->name,
    doc_action => 'UPDATE',
    doc_number => $data->{_id},
    marc => $data
  );

  #_id not given: new record explicitely requested
  if(int($data->{_id}) == 0){
    if($update_doc->errors()->[-1] =~ /Document: (\d{9}) was updated successfully/i){
      $data->{_id} = $1;
    }else{
      confess($update_doc->errors()->[-1]);
    }
  }
  #_id given: update when exists, insert when not
  else{

    #error given, can have several reasons: real error or just warnings + success message
    unless($update_doc->is_success){

      #document does not exist (yet)
      if($update_doc->errors()->[-1] =~ /Doc number given does not exist/i){

        #'If you want to insert a new document, then the doc_number you supply should be all zeroes'
        my $new_doc_num = Catmandu::AlephX->format_doc_num(0);

        #last error should be 'Document: 000050105 was updated successfully.'
        $update_doc = $alephx->update_doc(
          library => $self->name,
          doc_action => 'UPDATE',
          doc_number => $new_doc_num,
          marc => $data
        );

        if($update_doc->errors()->[-1] =~ /Document: (\d{9}) was updated successfully/i){

          $data->{_id} = $1;

        }else{

          confess $update_doc->errors()->[-1];

        }

      }
      #update ok
      elsif($update_doc->errors()->[-1] =~ /updated successfully/i){

        #all ok

      }
      #other severe errors (permissions, format..)
      else{

        confess $update_doc->errors()->[-1];

      }

    }
    #no errors given: strange
    else{
      #when does this happen?
      confess "how did you end up here?";
    }

  }
  #record is ALWAYS changed by Aleph, so fetch it again
  $self->get($data->{_id});

}

=head2 delete($id)

Deletes a record from the Aleph database. Requires a record identifier. Returns a true value when the
record is deleted.

=cut
sub delete {
  my($self,$id)= @_;

  $id = Catmandu::AlephX->format_doc_num($id);

  my $xml_full_req = <<EOF;
<?xml version="1.0" encoding="UTF-8" ?>
<find-doc><record><metadata><oai_marc><fixfield id="001">$id</fixfield></oai_marc></metadata></record></find-doc>
EOF

  #insert/update
  my $update_doc = $self->store->alephx->update_doc(
    library => $self->name,
    doc_action => 'DELETE',
    doc_number => $id,
    xml_full_req => $xml_full_req
  );

  #last error: 'Document: 000050124 was updated successfully.'
  (scalar(@{ $update_doc->errors() })) && ($update_doc->errors()->[-1] =~ /Document: $id was updated successfully./);
}

=head2 each(callback)

Loops over all records in the Aleph database executing callback for every record.

=cut
sub generator {
  my $self = $_[0];

  #TODO: in some cases, deleted records are really removed from the database
  #      in these cases, it does not make sense to interpret a failing 'find-doc' as the end of the database.
  #      to compete with these 'holes', the size of the hole need to be defined (how big before thinking this is the end)

  sub {
    state $count = 1;
    state $base = $self->name;
    state $alephx = $self->store->alephx;

    my $doc;
    do {
        my $doc_num = Catmandu::AlephX->format_doc_num($count++);
        my $find_doc = $alephx->find_doc(base => $base,doc_num => $doc_num,user_name => "");

        return unless $find_doc->is_success;

        $doc = {
            record => $find_doc->record->metadata->data->{record},
            _id => $doc_num
        };
    } while ($self->store->skip_deleted && check_deleted($doc) == 1);

    return $doc;
  };
}

=head2 search(query => $query, start => 0 , limit => 20);

=cut
#warning: no_entries is the maximum number of entries to be retrieved (always lower or equal to no_records)
#         specifying a set_entry higher than this, has no use, and leads to the error 'There is no entry number: <set_entry> in set number given'
sub search {
  my($self,%args)=@_;

  my $query = delete $args{query};
  my $start = delete $args{start};
  $start = is_natural($start) ? $start : 0;
  my $limit = delete $args{limit};
  $limit = is_natural($limit) ? $limit : 20;

  my $alephx = $self->store->alephx;
  my $find = $alephx->find(
    request => $query,
    base => $self->name,
    user_name => ""
  );

  my @results = ();

  if ($find->is_success) {
        my $no_records = int($find->no_records);
        my $no_entries = int($find->no_entries);

        my $s = Catmandu::AlephX->format_doc_num($start + 1);
        my $l = $start + $limit;
        my $e = Catmandu::AlephX->format_doc_num($l > $no_entries ? $no_entries : $l);
        my $set_entry = "$s-$e";

        my $present = $alephx->present(set_number => $find->set_number,set_entry => $set_entry,format => 'marc',user_name => "");

        @results = map { $_->metadata->data; } @{ $present->records() } if $present->is_success;
  }

  my $total = $find->no_records;
  $total = 0 unless defined $total && $total =~ /\d+/;

  Catmandu::Hits->new({
    limit => $limit,
    start => $start,
    total => int($total),
    hits  => \@results,
  });
}

=head2 searcher()

Not implemented

=cut
sub searcher {
  die("not implemented");
}

=head2 delete_all()

Not implemented

=cut
sub delete_all {
  die("not supported");
}


=head2 delete_by_query()

Not implemented

=cut
sub delete_by_query {
  die("not supported");
}

sub translate_sru_sortkeys {
  die("not supported");
}


sub translate_cql_query {
  die("not supported");
}

=head1 SEE ALSO

L<Catmandu::Store>

=cut

1;
