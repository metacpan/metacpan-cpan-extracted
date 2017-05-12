package AddressBook::DB::Text;

=head1 NAME

AddressBook::DB::Text - Backend for AddressBook to print entries in a simple text format

=head1 SYNOPSIS

  use AddressBook;
  $a = AddressBook->new(source => "Text",filename=>"/tmp/abook.text");
  $a->write($entry);

=head1 DESCRIPTION

AddressBook::DB::Text currently supports only the sequential write method.  

=cut

use strict;
use AddressBook;
use Carp;
use File::Basename;
use IO::File;

use vars qw($VERSION @ISA);

@ISA = qw(AddressBook);

$VERSION = '0.13';

=head2 new

  $a = AddressBook->new(source => "Text");
  $a = AddressBook->new(source => "Text",filename => "/tmp/abook.text");

If no filename parameter is specified in the constructor, or in the configuration
file, STDOUT is used.

=cut

sub new {
  my $class = shift;
  my $self = {};
  bless ($self,$class);
  my %args = @_;
  foreach (keys %args) {
    $self->{$_} = $args{$_};
  }
  if (defined $self->{filename}) {
    $self->{fh} = IO::File->new($self->{filename},O_RDWR | O_CREAT)
	|| croak "Couldn't open `" . $self->{filename} . "': $@";
  } else {
    $self->{fh} = *STDOUT;
  }
  return $self;
}

sub DESTROY {$_[0]->fh->close}

sub truncate {
  my $self = shift;
  my $class = ref $self || croak "Not a method call.";
  $self->{fh}->truncate(0);
}

sub write {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my $entry = shift;

  $self->{fh}->seek(0,2); # jump to the end of the file
  $self->{mode} = "w";
  my $attr = $entry->get(db=>$self->{db_name});
  my @ar;
  while(defined(my $k = each %{$attr})) {
    my $data = join(", ", @{$attr->{$k}->{value}});
    $ar[$attr->{$k}->{meta}->{order}] = 
	$k . ": $data\n" if $data ne '';
  }
  foreach (0..$#ar) {
    print {$self->{fh}} $ar[$_] if defined $ar[$_];
  }
  print {$self->{fh}} "\n";
}

1;
__END__

=head1 AUTHOR

Mark A. Hershberger, <mah@everybody.org>
David L. Leigh, <dleigh@sameasiteverwas.net>

=head1 SEE ALSO

L<AddressBook>,
L<AddressBook::Config>,
L<AddressBook::Entry>.

=cut
