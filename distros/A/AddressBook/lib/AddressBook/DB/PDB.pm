package AddressBook::DB::PDB;

=head1 NAME

AddressBook::DB::PDB - Backend for AddressBook to use PDB (PalmOS) Databases.

=head1 SYNOPSIS

  use AddressBook;
  $a = AddressBook->new(source => "PDB",port=>"/dev/pilot");
  $b = AddressBook->new(source => "PDB",pdb=>$pdb);
  $c = AddressBook->new(source => "PDB",dlp=>$dlp);

=head1 DESCRIPTION

The PDA::Pilot library module is required in order to use this package.
PDA::Pilot is available as part of the pilot-link distribution, which is
available at http://www.gnu-designs.com/pilot-link

AddressBook::DB::PDB supports sequential backend database methods.
AddressBook::DB::PDB behavior can be modified using the following options:

=over 4

=item key_fields

A list of PDB field names (not cannonical names) which can be used to uniquely
identify a database record.  Ideally the "id" field of PDB records would be used here,
but currently it is not.  "Name,First name" is recommended.

=item phone_display

A perl statment which, when eval'd, returns a comma-delimited list of "phone labels".
Valid phone labels are: Work,Home,Fax,Other,E-Mail,Main,Pager,Mobile.  The result of 
the eval'd phone_display will be used to determine which phone label is default shown 
in the PalmOS address list.  The first label in the comma-delimited list is used unless
the record has no value for that label, in which case the second label is used unless
it also has no value, in which case the third is used, and so on....

In the phone_display string, other attributes may be referenced as "$<attr>".

For example, if you want the priority of default phone lables to be "Work,Home,E-Mail"
for all records in the "Business" category, and the priority to be "Home,Work,E-Mail"
for all records in all other categories, you could use the following:

  phone_display = "($category eq 'Business') 
                   ? 'Work,Home,E-Mail' 
                   : 'Home,Work,E-Mail'"

=item intra_attr_sep_char

The character to use when joining multi-valued fields.  The default is ' & '.

=back

Any of these options can be specified in the constructor, or in the configuration file.

=cut

use strict;
use PDA::Pilot;
use AddressBook;
use Carp;
use Date::Manip;
use vars qw($VERSION @ISA);

$VERSION = '0.13';

@ISA = qw(AddressBook);

=head2 new

  $a = AddressBook->new(source => "PDB");
  $a = AddressBook->new(source => "PDB",
                        port => "/dev/pilot");

If a "pdb" parameter is supplied, it will be used as a reference to an already
created PDA::Pilot::DLP::DBPtr object.  Otherwise, if a "port" is supplied,
the user will be prompted to press the hotsync button to establish the connection.

=cut

sub new {
  my $class = shift;
  my $self = {};
  bless ($self,$class);
  my %args = @_;
  foreach (keys %args) {
    $self->{$_} = $args{$_};
  }
  if (! $self->{pdb}) {
    if (! $self->{dlp}) {
      my $socket = PDA::Pilot::openPort($self->{port});
      print "Now press the HotSync button\n";
      $self->{dlp} = PDA::Pilot::accept($socket);
    } 
    $self->{pdb} = $self->{dlp}->open("AddressDB");
  }
  if (! $self->{pdb}) {
    croak "Error: No port, dlp, or pdb specified";
  }
  $self->reset;
  unless (defined $self->{intra_attr_sep_char}) {
    $self->{intra_attr_sep_char} = ' & ';
  }
  return $self;

#   croak("PDB file backends are not currently implemented");  
#   if (-e $self->{file}) {
#     $self->{pdb} = PDA::Pilot::File::open($self->{file};
#   } else {
#      croak("File: ".$self->file." does not exist");
#      my $info;
#      $info->{name}="AddressDB";
#      $info->{type}="DATA";
#      $self->{pdb} = PDA::Pilot::File::create($self->{file},$info);
#   }

}

sub reset {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  $self->{index} = 0;
  $self->_read_appinfo;
  #$self->_remove_deleted_records;
}

sub read {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my %reverse_category_hash = reverse %{$self->{category_hash}};
  my ($i,%attr,$found);
  if ($self->{index} < $self->{pdb}->getRecords) {
    my $record = PDA::Pilot::Address::Unpack($self->{pdb}->getRecord($self->{index}++));
    if ($record->{deleted}) {
      $self->{pdb}->deleteRecord($record->{id});
      return ($self->read);
    }
    my %labels = %{$self->_insert_phone_labels($record->{phoneLabel})};
    for ($i=0;$i<=$#{$record->{entry}};$i++) {
      if (defined $record->{entry}->[$i]) {
	@{$attr{$labels{$i}}} = split /$self->{intra_attr_sep_char}/ ,$record->{entry}->[$i];
      }
    }
    my $entry = AddressBook::Entry->new(config=>$self->{config},
				        db=>$self->{db_name},
				        attr=>\%attr);
    $entry->add(db=>$self->{db_name},
		attr=>{category=>$reverse_category_hash{$record->{category}}});
    if ($record->{modified}) {$entry->{timestamp} = ParseDate("Today")}
    else {$entry->{timestamp} = 0}
    return $entry;
  } else {
    return undef;
  }
}

sub _insert_phone_labels {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my ($phoneLayout) = @_;
  my $i;
  my %labels = reverse %{$self->{field_labels}};
  my %phone_labels = reverse %{$self->{phone_labels}};
  for ($i=0;$i<=4;$i++) {
    $labels{$i+3} = $phone_labels{$phoneLayout->[$i]};
  }
  return \%labels;
}

sub write {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my $entry = shift;
  $entry->calculate;
  my $record = $self->{pdb}->newRecord;
  my ($field,$i,$j,@phone_display,$phone_display,$phone_display_calc,$phone_target,$value,@phone_attrs);
  $entry->calculate;
  my %labels = %{$self->{field_labels}};
  my $attrs = $entry->get(db=>$self->{db_name});
  my $phone_index = 0;
  foreach $field (keys %{$attrs}) {
    $value = join $self->{intra_attr_sep_char}, @{$attrs->{$field}->{value}};
    if ($field eq "category") {
      if (! exists $self->{category_hash}->{$value}) {
	$self->_add_category($value);
      }
      $record->{category}=$self->{category_hash}->{$value};
    } elsif (exists $self->{phone_labels}->{$field}) {
      push @phone_attrs, $field;
      next; #defer phone field processing until later
    } else {
      $record->{entry}->[$labels{$field}] = $value;
    }
  }
  # now process phone fields
  foreach $field (sort {$attrs->{$a}->{meta}->{order} <=> $attrs->{$b}->{meta}->{order}} @phone_attrs) {
    # for the time being, we will concatenate like phone fields
    $value = join $self->{intra_attr_sep_char}, @{$attrs->{$field}->{value}};
    $record->{phoneLabel}->[$phone_index] = $self->{phone_labels}->{$field};
    $record->{entry}->[$phone_index+3] = $value;
    $phone_index++;
    if ($phone_index == 5) {last}  # there is only room for 5 "phone" fields
  }
  for ($i=0;$i<=keys %labels;$i++) {
    unless ($record->{entry}->[$i]) {$record->{entry}->[$i] = undef}
  }
  ($phone_display_calc = $self->{phone_display}) =~ s/\$([\w-]+)/\$attrs->{$1}->{value}->[0]/g;
  eval qq{ \$phone_display = $phone_display_calc }; warn "Syntax error in phone_display_calc: $@" if $@;
  @phone_display = split ",",$phone_display;
 find_phone: for ($i=0;$i<=$#phone_display;$i++) {
   if ($attrs->{$phone_display[$i]}->{value}->[0]) {
     $phone_target = $self->{phone_labels}->{$phone_display[$i]};
     for ($j=0;$j<=$#{$record->{phoneLabel}};$j++) {
       if ($record->{phoneLabel}->[$j] == $phone_target) {
	 $record->{showPhone} = $j;
	 last find_phone;
       }
      }
   }
 }
  $self->{pdb}->setRecord($record);
  return;
}

sub _add_category {
  my $self = shift;
  my ($new_cat) = @_;
  my $class = ref $self || croak "Not a method call";
  my $appBlock = PDA::Pilot::Address::UnpackAppBlock($self->{pdb}->getAppBlock);
  my @categories = @{$appBlock->{categoryName}};
  my $i;
  for ($i=0;$i<=$#categories;$i++) {
    last if ($categories[$i] eq "");
  }
  $appBlock->{categoryName}->[$i] = $new_cat;
  $self->{pdb}->setAppBlock($appBlock);
  $self->_read_appinfo;
}

sub _read_appinfo {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my $appBlock = PDA::Pilot::Address::UnpackAppBlock($self->{pdb}->getAppBlock);
  $self->{category_hash} = {};
  my @categories = @{$appBlock->{categoryName}};
  my $i;
  for ($i=0;$i<=$#categories;$i++) {
    $self->{category_hash}->{$categories[$i]} = $i;
  }
  my @labels = $appBlock->{label};
  for ($i=0;$i<=$#{$labels[0]};$i++) {
    $self->{field_labels}->{$labels[0][$i]} = $i;
  }
  my @phone_labels = $appBlock->{phoneLabel};
  for ($i=0;$i<=$#{$phone_labels[0]};$i++) {
    $self->{phone_labels}->{$phone_labels[0][$i]} = $i;
  }
}

sub truncate {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  $self->{pdb}->deleteRecords;
  $self->reset;
}

sub _remove_deleted_records {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my ($i,$record);
  for ($i=$self->{pdb}->getRecords-1;$i>=0;$i--) {
    $record = PDA::Pilot::Address::Unpack($self->{pdb}->getRecord($i));
    if ($record->{deleted}) {
      $self->{pdb}->deleteRecord($record->{id});
    }
  }
}

sub write_to_disk {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  $self->pdb->Write($self->{filename});
}

1;
__END__

=head2 Timestamps

For syncronization purposes, all records which have the "modified" flag set are
timestamped with the current time.  All records with have the "modified" flag
unset are timestamped with "0" (very, very old).

=head1 Deleted Records

PDB records which have the "deleted" flag set are removed as part of the initialization
process.  The "archive" flag is ignored. 

=head1 Categories

For convienience, a record's category is treated like any other attribute.  New
categories are created as necessary.  Moving a record to a new category will achieve
the expected result during synchronization.
However, because renaming a category does
not cause affected records to be marked as "modified", category renaming operations will
be lost during synchronization.  

=head1 AUTHOR

David L. Leigh, <dleigh@sameasiteverwas.net>

=head1 SEE ALSO

L<AddressBook>,
L<AddressBook::Config>,
L<AddressBook::Entry>.

PDA::Pilot

=cut
