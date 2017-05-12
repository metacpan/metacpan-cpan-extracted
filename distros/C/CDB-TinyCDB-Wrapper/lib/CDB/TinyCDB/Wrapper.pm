package CDB::TinyCDB::Wrapper;

use warnings;
use strict;
use CDB::TinyCDB;

=head1 NAME

CDB::TinyCDB::Wrapper - A wrapper around CDB::TinyCDB to try and make
updating its files a little more transparent

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use CDB::TinyCDB::Wrapper;
    my $db = CDB::TinyCDB::Wrapper->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
  my ($class, $filename) = @_;
  $class = ref($class) || $class;
  my $self = {filename => $filename,
              modified => {}};

  # If the file doesn't exist, dummy an empty file up. We can get away
  # with this because the BayesStore checks for file existence itself
  unless (-f $filename) {
    my $tmp;
    unless ($tmp = CDB::TinyCDB->create ($filename, "$filename.$$")) {
      #warn("Couldn't open $filename: $!");
      return 0;
    }
    $tmp->finish;
  }

  unless ($self->{cdb} = CDB::TinyCDB->load ($filename)) {
    #warn("Couldn't open $filename: $!");
    return 0;
  }

  bless ($self, $class);
  $self;
}

=head2 abandon

Indicates that whatever alterations were made should be thrown away
when the file is closed.

=cut

sub abandon {
  my ($self) = @_;
  $self->{discard}++;
  $self->close;
}

=head2 close

Closes the CDB file, rebuilding the file reflecting any changes that
were made.

=cut

sub close {
  my ($self) = @_;

  # If keys were modified and we want to preserve the changes
  if (CORE::keys %{$self->{modified}} and !$self->{discard}) {
    #warn "Keys were modified\n";
    $self->_reset_each;
    # Start with the existing file
    #warn "Creating new temp file\n";
    my $tmp = CDB::TinyCDB->create ($self->{filename}, "$self->{filename}.$$");
    #warn "Starting loop\n";
    # Iterate over all values that were in the modified list
    while (my ($key, $value) = CORE::each %{$self->{modified}}) {
      # Skip undefined (deleted) values
      next unless defined $value;
      $tmp->put_add ($key, $value);
    }
    # Iterate over all keys, copying appropriate values to the new db
    while (my ($key, $value) = $self->{cdb}->each) {
      $tmp->put_add ($key, $value) unless exists $self->{modified}->{$key};
    }
    # Store our changes
    $tmp->finish;
  }

  delete $self->{cdb};

  return 1;
}

=head2 del

Delete the key from the DB.

=cut

sub del {
  my ($self, $key) = @_;
  $self->{modified}->{$key} = undef;
  return 1;
}

=head2 exists

Checks whether the key exists in the db

=cut

sub exists {
  my ($self, $key) = @_;
  return defined $self->{modified}->{$key} || $self->{cdb}->exists ($key);
}

=head2 each

Iterates through the DB, returning tuples of ($key, $value) each time
it's called.

=cut

{
  my @each = ();
  my $eof = 0;

  sub each {
    my ($self) = @_;
    my @return = ();
    if ($eof) {
      #warn "At the end of the list, resetting\n";
      $eof = 0;
      return ();
    } else {
      unless (@each) {
        #warn "Refilling the list\n";
        @each = sort $self->keys;
        #my $output = Dumper \@each;
        #warn "List is " . substr ($output, 0, 1000);
      }
      if (defined (my $key = shift @each)) {
        #warn "key is $key\n";
        $eof = @each ? 0 : 1;
        #warn "EOF is $eof\n";
        return ($key, exists $self->{modified}->{$key} ? $self->{modified}->{$key} : $self->{cdb}->get ($key));
      } else {
        # If the list is empty the first time through, we'll end up
        # here
        return ();
      }
    }
  }

=head2 _reset_each

Iterates through the DB, returning tuples of ($key, $value) each time
it's called.

=cut

  sub _reset_each {
    @each = ();
    $eof = 0;
  }
}

=head2 get

Retrieves the specified key from the DB.  Returns 'undef' if the key
doesn't exist.

=cut

sub get {
  my ($self, $key) = @_;
  return exists $self->{modified}->{$key} ? $self->{modified}->{$key} : $self->{cdb}->get ($key);
}

=head2 keys

Retrieves the list of keys from the DB.

=cut

sub keys {
  my ($self) = @_;
  # Hold our list of keys
  my %keys;
  # Get the keys on disk
  map {$keys{$_}++} $self->{cdb}->keys;
  # Iterate over the keys in memory
  for my $key (CORE::keys %{$self->{modified}}) {
    # If the key has a value in memory, make sure it's includee
    if (defined $self->{modified}->{$key}) {
      $keys{$key}++
    } else {
      # This has been deleted in memory, delete from list of keys
      delete $keys{$key};
    }
  }
  return CORE::keys %keys;
}

=head2 set

Sets the specified key to the specified value in the DB.

=cut

sub set {
  my ($self, $key, $value) = @_;
  $self->{modified}->{$key} = $value;
}

=head2 DESTROY

Called when the object is deleted or goes out of scope, it closes the
file.  This is just here for compatibility with versions < 0.3---all
new development should explicitly call close, or risk potential issues
if the data doesn't get GC'd immediately.

=cut

sub DESTROY {
  my ($self) = @_;
  $self->close if ($self->{cdb});
}

=head1 AUTHOR

Michael Alan Dorman, C<< <mdorman at ironicdesign.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cdb-tinycdb-overlay at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CDB-TinyCDB-Wrapper>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CDB::TinyCDB::Wrapper

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CDB-TinyCDB-Wrapper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CDB-TinyCDB-Wrapper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CDB-TinyCDB-Wrapper>

=item * Search CPAN

L<http://search.cpan.org/dist/CDB-TinyCDB-Wrapper/>

=back

=head1 ACKNOWLEDGEMENTS

CDB::TinyCDB, without which this module would have no reason to exist

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Michael Alan Dorman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;                              # End of CDB::TinyCDB::Wrapper
