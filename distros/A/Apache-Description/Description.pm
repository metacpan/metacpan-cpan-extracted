package Apache::Description;

use 5.008;
use strict;
use warnings;
use IO::File;
use Carp;

our $VERSION = '0.5';

my ($filename, $fh, @prev);
my $regexp = <<'END_RE';
^AddDescription
             \s+
                  ("?)                # quote ?
                    (([^"\\]|\\")+)   # description
                    \s*
                   \1                  # quote ?
             \s+

                   ("?)               # quote ?
                     (([^"\\]|\\")+)        # filename
                     \s*
                    \4                 # quote ?
$ # end of regexp
END_RE

sub new {
  my $self = shift;

  ## you can give a filename in argument
  $filename = shift;
  $self->parse  if  defined $filename;

  return bless {}, $self;
}

## this subroutine checks the filename
sub parse {
  my $self = shift;

  ## have we already open a file ?
  if ( defined $fh ) {
    carp "$filename is already in use\n";

  } else {
    $filename = $filename ? $filename : shift;

    if ( (not defined $filename) or (not -e $filename) ) {
      croak "invalid filename : $filename";
    }

    $self->open();
  }
}

## just open the file .htaccess
sub open {
  $fh = IO::File->new($filename, "r+");

  if ( not defined $fh) {
    croak "impossible to open $filename in read-write : $!";
  }
}

## add a description
sub add($$){
  my ($self, $file, $desc) = @_;

  print $fh qq/AddDescription "$desc" "$file"\n/;
}


## remove an entry
## this operation is "expensive" : two files are created, and I
## need to parse the whole file.
## if there are more than one directive for the file wanted, they are
## both deleted.
sub remove($) {
  my ($self, $wanted) = @_;
  my $fd;

  $fh->setpos(0);
  $fd = IO::File->new(">/tmp/htaccess.$$");
  
  croak "no file descriptor available : $!" unless (defined $fh or not defined $fd);

  while ( <$fh> ) {
    chomp if defined;

    if ( m/$regexp/xio ) {

      if ($5 ne $wanted)
        { print $fd "$_\n" }

    } else {
      print $fd "$_\n";
    }
  }

  croak "no file descriptor available : $!" if (not defined $fh or not defined $fd);
  
  rename "/tmp/htaccess.$$", $filename
    or croak "rename(htaccess.$$,$filename) : $!";
}

## this function can return an array, or a scalar
## according to the context of the next description.
##
## @ array = ($filename, $description)
##
## $ scal  = qq/$filename:$description/
##
sub next {
  my @data;

  croak "no file descriptor available" unless defined $fh;

  while ( <$fh> ) {
    chomp if defined;

    next unless m/$regexp/xio;
    @data = ($5, $2);

    ## storing the last directive
    @prev = @data;
    last;
  }

   return wantarray ? @data : join ':',@data;
}

## return the previous directive.
## it's the same format than next()
sub prev {
  return wantarray ? @prev : join ':',@prev;
}

## returns all descriptions in a hash reference
##
sub getall {
  my $self = shift;
  my (%hash, $desc);

  croak "no file descriptor available" unless defined $fh;

  while ( my ($f, $d) = $self->next() ) {
    last if not defined $f;

    $hash{"$f"} = $d;
  }

  return \%hash;
}

sub get($) {
  my $self   = shift;
  my $wanted = shift;
  my $ret    = undef;

  croak "no file descriptor available" unless defined $fh;

  while ( my ($f, $d) = $self->next() ) {
    last if not defined $f;

    if ( $f eq $wanted) {
      $ret = $d;
      last;
    }
  }

  return $ret;
}

sub rename {
  print qq/Not implemented yet\n/;
}

sub ispresent($) {
  my $self = shift;
  my $file = shift;

  return $self->get($file) ? 1 : 0;
}


1;

__END__

=head1 NAME

  Apache::Description - Managing of descriptions in .htaccess

=head1 SYNOPSIS

=head2 List every files/descriptions

  use Apache::Description;

  my $d = Apache::Description->new(".htaccess");

  while ( my ($file, $desc) = $d->next )
    {
      ## is it the last element ?
      last unless $file;

      print "$file : $desc";
    }

=head2 Or for the same task :

  use Apache::Description;

  my $d = Apache::Description->new(".htaccess");
  print while $d->next;

=head2 Check for the presence of a file

  use Apache::Description;

  my $d = Apache::Description->new(".htaccess");
  if ( $d->ispresent("foo.txt") )
     { print "found\n" }
  else
     { print "not found\n" }

=head2 add a description

  use Apache::Description;

  my $d = Apache::Description->new(".htaccess");
  $d->add("foo.txt", "bar bar");

=head2 remove the description of foo.txt

  use Apache::Description;

  my $d = Apache::Description->new(".htaccess");
  $d->remove("foo.txt");

=head2 get the description of foo.txt

  use Apache::Description;

  my $d = Apache::Description->new(".htaccess");
  my $href = $d->get("foo.txt");

=head2 get all filename/description in a hash

  use Apache::Description;

  my $d = Apache::Description->new(".htaccess");
  my $href = $d->getall;

  ## you can access to the description of foo.txt now :
  print qq/foo.txt : $href->{"foo.txt"}\n/;

=head1 ABSTRACT

 Manage descriptions available in .htaccess with directives like this :
  AddDescription "my description" "my_filename.txt"

=head1 DESCRIPTION

This module give you access to the B<AddDescription> directives in an object
oriented way. Thus, you can B<add>, B<remove> or read descriptions.

=head1 CONSTRUCTORS

=over

=item B<new>

If an argument is given to the constructor, it will represent the filename of the
I<.htaccess> and the method B<parse> will be called.

=back

=head1 METHODS

=over

=item B<parse>( [$filename] )

This function accepts an argument

=item B<next>

Returns a couple filename/description.

This method can return an array, or a scalar according to the context
of the caller.

@array = ($filename, $description)

$scal  = qq/$filename:$description/

=item B<prev>

Returns the previous description in the same format thant B<next()> method.

=item B<add>( file, description )

Add to the .htaccess a directive AddDescription

=item B<remove>( file )

Remove a directive from the .htaccess

=item B<getall>

Returns a reference to a hash of all descriptions where the keys are the filenames.

=item B<get>( file )

This method returns the description of the file given in argument.

=item B<ispresent>( $file )

Returns B<1> if $file have a description, B<0> otherwise.

=back

=head1 EXPORT

None by default.

=head1 SEE ALSO

http://www.madchat.org/ - Website with more than 2000 AddDescription directives.

http://httpd.apache.org/

=head1 AUTHOR

Nicolas Bareil, E<lt>nbareil+cpan@mouarf.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Nicolas Bareil

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
