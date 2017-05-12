package JAF;

use strict;
our %IMPORTED = ();

sub import {
  my $cl = 0;
  my ($filename, $sub);
  do {
    ($filename, $sub) = (caller($cl))[1,3];
    $cl++;
  } while ( $filename && $sub ne '(eval)');

  if ($filename) {
    return if exists $IMPORTED{$filename};
    $filename =~ s/\.pm$/\//;
    use DirHandle;
    if (my $dh = DirHandle->new( $filename )) {
      foreach my $file ($dh->read) {
        next if $file !~ /\.pm$/;
        require "$filename$file";
      }
    }

    $IMPORTED{$filename} = 1;
  }
}

# set error
################################################################################
sub error () {
  my ($self, $text) = @_;

  push @{$self->{messages}}, ['error', $text] if $text ne '';
}

# set message
################################################################################
sub message () {
  my ($self, $text) = @_;

  push @{$self->{messages}}, ['message', $text] if $text ne '';
}

# get messages
################################################################################
sub messages () {
  my $self = shift();

  my %hash;
  foreach (@{$self->{messages}}) {
    $hash{"$_->[0]:$_->[1]"}++;
  }
  my $new = [map {[(split ':', $_, 2), $hash{$_}]} keys %hash];
  
  $self->{messages} = [];

  return @$new ? $new : undef;
}

################################################################################
sub AUTOLOAD {
  no strict 'refs';
  my $self = shift;
  my $module = our $AUTOLOAD;
  $module =~ s/.*:://;
  return if $module eq 'DESTROY'; 

  my $pkg = ref($self) . '::' . $module;
  $self->{$module} ||= "$pkg"->new({ parent => $self, dbh => $self->{dbh} });
  return $self->{$module};
}

1;
