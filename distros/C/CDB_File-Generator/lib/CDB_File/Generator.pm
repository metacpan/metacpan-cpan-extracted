package CDB_File::Generator;
$REVISION=q$Revision: 1.13 $ ;
use vars qw($VERSION);
$VERSION='0.030';

=head1 NAME

CDB_File::Generator - generate massive sorted CDB files simply.

=head1 SYNOPSIS

  use CDB_File::Generator;
  $gen = new CDB::Generator "my.cdb";
  $gen->("Fred", "Martha");
  $gen->("Fred", "Olivia");
  $gen->("Fred", "Jenny");
  $gen->("Roger", "Joe");
  $gen->("Roger", "Jenny");
  $gen = undef;
  use CDB_File;


=head1 DESCRIPTION

This is a class which makes generating sorted large (much bigger than
memory, but the speed will depend on the efficiency of your sort
command.  If you haven't got one, for example, it won't work at all.)
CDB files on the fly very easy

=cut

#this lets us have lots of unique temporary files.

use Carp;
use IO::File;
use strict;

BEGIN {
  my $tempfile_no=0;
  sub next_tmp_file () { $tempfile_no++ };
}

=head1 METHODS

=head2 Generator::new $cdbfile [$cdbmaketemp [{$tmpname [$sorttmpname] | $tmpdir}]]

The new function creates a generator for a given filename, optionally
specifying where it sould put it's temporary files.  

=cut

my $deftemp="/tmp/cdb_generator_tmp.$$.";

sub new ($$@) {
  my $class=shift;
  my $self = bless {}, $class;
  my $cdbfilename = shift;
  $self->{"cdbfile"} = $cdbfilename;
  $self->{"tmpoutfile"} = $deftemp . next_tmp_file();
  $self->{"tmpsortfile"} = $deftemp . next_tmp_file();
  my $tmpmake = $cdbfilename;
  $tmpmake =~ s/.cdb$/.tmp/ or $tmpmake = $tmpmake . ".tmp";
  Carp::croak "file $tmpmake for cdb temfile exists" if -e $tmpmake;
  $self->{"tmpmakefile"} = $tmpmake;
  my $fh = new IO::File $self->{"tmpoutfile"}, '>' 
    or die "couldn't create output file";
  $self->{"fh"} = $fh;
  $self->{"added"} = 0;
  return $self;
}

=head2 $gen->add($key, $value)

Adds a value to the CDB being created 

=cut

sub add ($$$) {
  my ($self, $key, $value) = @_;
  my $fh = $self->{"fh"};

  #change newlines so sort can sort everything as lines.
  #change tabs so we can use them as a separator
  $key =~ s,\\,\\\\,g; #now we have all \s in even numbered groups
  $key =~ s,\n,\\n,g; #an odd \ followed by a newline is a nl
  $key =~ s,\t,\\t,g; #an odd \ followed by a tab is a nl
  $value =~ s,\\,\\\\,g;   #....
  $value =~ s,\n,\\n,g;
  $value =~ s,\t,\\t,g; # ....

  print $fh $key, "\t", $value, "\n";

  $self->{"added"} ++;
}

=head2 $gen->DESTROY

This is not normally called by the user, but rather by the completion
of the cdbfile being writen out and that block of the program being
exited or by the program completing.  When it us run, it calls the
finish method which ends the CDB creation.  See below.

=cut

sub DESTROY ($) {
  my $self=shift;
  $self->{"added"} && $self->finish() unless $self->{"abort"};
  foreach my $del ( "tmpoutfile", "tmpsortfile", "tmpmakefile") {
      unlink $self->{$del};
  }
}

=head2 finish

Finish ends of the cdb creation.  First it closes the output temporary
file, then it sorts it to another file and finally it calls C<cdbmake>
to complete the creation job.

In the current implementation this uses C<sort -u> and deletes repeats of
the same key with the same value.

In order to increase database portability, by default all sorting is
done in the 'C' locale, even if the current program is working in
another locale.  This is "the right thing" in many cases.  Where you
are dealing with real word keys it won't be the right thing.  In this case, use the locale function to set the locale.

=cut

sub locale ($) {
  my $self=shift;
  my $locale=shift;
  $self->{locale}=$locale;
}

sub finish ($) {
  my $self=shift;
  close $self->{"fh"};

  {
    local $ENV{LC_ALL};
    if ($self->{locale}) {
      $ENV{LC_ALL}=$self->{locale};
    } else {
      $ENV{LC_ALL}='C';
    }
    system 'sort' , '-u', '-o' ,$self->{"tmpsortfile"} , $self->{"tmpoutfile"};
  }

  my $fh = new IO::File $self->{"tmpsortfile"}
    or die "couldn't open sorted output file";

  my $cdbmakeout = new IO::File ( '|cdbmake ' .  $self->{"cdbfile"} 
				  . ' ' .   $self->{"tmpmakefile"} );

  while (<$fh>) {
    my ($key, $value) = m/^(.*)\t(.*)$/;

    #the \G s allow for multiple new lines in a row
    #odd numbered slash with t is tab
    $key =~ s,((?:\G|^|[^\\])(?:\\\\)*)\\t,$1\t,g; 
    #odd numbered slash with t is tab
    $key =~ s,((?:\G|^|[^\\])(?:\\\\)*)\\n,$1\n,g; 
    #pairs of slashes match a single slash
    $key =~ s,\\\\,\\,g; 

    #same for value....
    $value =~ s,((?:\G|^|[^\\])(?:\\\\)*)\\t,$1\t,g; 
    $value =~ s,((?:\G|^|[^\\])(?:\\\\)*)\\n,$1\n,g; 
    $value =~ s,\\\\,\\,g;                        

    print $cdbmakeout &gen_cdb_input($key, $value);
  }
  print $cdbmakeout "\n";
  $cdbmakeout->close;
  $fh->close;

#  $self->{"abort"} = 1;
  #FIXME return codes etc..
  unlink $self->{"tmpsortfile"} , $self->{"tmpoutfile"}
  or warn "trouble deleting temp files "
    . $self->{"tmpsortfile"} . $self->{"tmpoutfile"};
  $self->{"added"} = 0;
}

=head2 $gen->abort

If you decide not to create the CDB file you were creating, you have
to call this method.  Otherwise, it will be created as your program
exits (or possibly earlier)

=cut

sub abort ($) {
  shift->{"abort"} = 1
}

=head2 gen_cdb_input($key,$value)

This is a little utility function which formats a cdbmake input line.

=cut

sub gen_cdb_input ($$) {
    my $key=shift;
    my $value=shift;

    return "+" . length($key) . "," . length($value) . ":" 
	. $key . "->" . $value . "\n";
}

=head1 BUGS

We use the external programs C<sort> and C<cdbmake>.  These almost
certainly improve our performance on large databases (and those are
all we care about), but they make portability difficult.. Possibly
system independent alternatives should be written and used where
needed.

We should write out to the sort file with some encoding that gets rid
of new lines and then read back, de-coding that to feed it to cdbmake..

=cut

