=head1 NAME

Bio::Polloc::Rule::tandemrepeat - A rule of type tandemrepeat

=head1 DESCRIPTION

This rule is similar to Bio::Polloc::Rule::repeat, but employes TRF (Benson 1999, NAR 27(2):573-580)
for the repeats calculation.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Rule::tandemrepeat;
use base qw(Bio::Polloc::RuleI);
use strict;
use Bio::Polloc::Polloc::IO;
use Bio::Polloc::LocusI;
use Bio::SeqIO;
# For TRF:
use File::Spec;
use File::Basename;
use Cwd;
use Config;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=head2 new

Generic initialization method.

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 execute

This is where magic happens.  Translates the parameters of the object into a call to
B<TRF>, and scans the sequence for repeats.

=head3 Arguments

The sequence (C<-seq>) as a L<Bio::Seq> or a L<Bio::SeqIO> object.

=head3 Returns

An array reference populated with L<Bio::Polloc::Locus::tandemrepeat> objects.

=cut

sub execute {
   my($self,@args) = @_;
   my($seq) = $self->_rearrange([qw(SEQ)], @args);
   
   $self->throw("You must provide a sequence to evaluate the rule", $seq) unless $seq;
   $self->throw("You must provide an object as sequence", $seq)
   		unless UNIVERSAL::can($seq,'isa');
   
   # For Bio::SeqIO objects
   if($seq->isa('Bio::SeqIO')){
      my @feats = ();
      while(my $s = $seq->next_seq){
         push(@feats, @{$self->execute(-seq=>$s)})
      }
      return wantarray ? @feats : \@feats;
   }
   
   $self->throw("Illegal class of sequence '".ref($seq)."'", $seq) unless $seq->isa('Bio::Seq');

   # Include safe_value parameters
   # MINSIZE MAXSIZE MINPERIOD MAXPERIOD EXP MATCH MISMATCH INDELS MINSCORE MAXSCORE PM PI
   my %c_v = (
      "minsize" => 0,	"maxsize" => 1e20,
      "minperiod" => 0,	"maxperiod" => 500,
      "exp" => 0,
      "match" => 2,	"mismatch"=> 3,	"indels" => 5,
      "minscore" => 50,	"maxscore" => 0,
      "minsim" => 0,	"maxsim" => 100,
      "pm" => 80,	"pi" => 20
   );
   for my $k ( keys %c_v){
      my $p = $self->_search_value($k);
      $c_v{$k} = $p if defined $p; # override defaults
   }

   # Create the IO master
   my $io = Bio::Polloc::Polloc::IO->new();

   # Search for TRF
   $self->source('trf'); # For GFF
   my $trf = $self->_executable(defined $self->ruleset ? $self->ruleset->value("path") : undef)
   	or $self->throw("Could not find the trf binary");
   
   # Next line is because of the horrible practice of creating files at CWD out
   # of thin air (with no possibility to define another way!)
   $trf = File::Spec->rel2abs($trf) unless File::Spec->file_name_is_absolute($trf);
   
   # Write the sequence
   my($seq_fh, $seq_file) = $io->tempfile;
   close $seq_fh;
   my $seqO = Bio::SeqIO->new(-file=>">$seq_file", -format=>'Fasta');
   $seqO->write_seq($seq);
   
   # Run it
   my @run = ($trf);
   push @run, $seq_file;
   push @run, $c_v{'match'}, $c_v{'mismatch'}, $c_v{'indels'};
   push @run, $c_v{'pm'}, $c_v{'pi'}, $c_v{'minscore'}, $c_v{'maxperiod'};
   push @run, "-h"; #<- Simplifies output, and produces one file instead of tons!
   push @run, "2>&1";
   push @run, "|";
   my $cwd = cwd();
   # Finger crossed
   my $tmpdir = Bio::Polloc::Polloc::IO->tempdir();
   chdir $tmpdir or $self->throw("I can not move myself to the temporal directory: $!", $tmpdir);
   $self->debug("Hello from ".cwd());
   $self->debug("Running: ".join(" ",@run)." [CWD: ".cwd()."]");
   my $run = Bio::Polloc::Polloc::IO->new(-file=>join(" ",@run));
   my $runout = '';
   while($run->_readline){$runout.=$_ if defined $_} # Do nothing, this is truly unuseful output, just save it in case of errors (for debugging)
   $run->close();
   # Finger crossed (yes, again)
   chdir $cwd or $self->throw("I can not move myself to the original directory: $!", $cwd);
   $self->debug("Hello from ".cwd());
   
   # Try to locate the output (belive it or not)...
   my $outfile = Bio::Polloc::Polloc::IO->catfile($tmpdir, basename($seq_file) . "." .
   		$c_v{'match'} . "." . $c_v{'mismatch'} . "." . $c_v{'indels'} . "." .
		$c_v{'pm'} . "." . $c_v{'pi'} . "." . $c_v{'minscore'} . "." .
		$c_v{'maxperiod'} . ".dat");
   $self->throw("Impossible to locate the output file of TRF: '$outfile', (".join(" ", @run).") showing full output", $runout) unless -e $outfile;
   
   # And finally parse it
   my $ontable = 0;
   my @feats = ();
   $run = Bio::Polloc::Polloc::IO->new(-file=>$outfile);
   while(my $line = $run->_readline){
      if($line =~ m/^Parameters:\s/){
         $ontable = 1;
      }elsif($ontable){
	 chomp $line;
	 next if $line =~ /^\s*$/;
	 #from to period-size copy-number consensus-size percent-matches percent-indels score A T C G entropy consensus sequence
	 #269 316 18 2.6 19 56 3 51 8 45 35 10 1.68 GTCGCGGCCACGTGCACCC GTCGCGTCCACGTGCGCCCGAGCCGGC...
	 my @v = split /\s+/, $line;
	 $#v==14 or $self->throw("Unexpected line $.",$line,"Bio::Polloc::Polloc::ParsingException");
	 # MINSIZE MAXSIZE MINPERIOD MAXPERIOD EXP MATCH MISMATCH INDELS MINSCORE MAXSCORE
	 $self->debug("Checking additional parameters");
	 next if length($v[14]) > $c_v{'maxsize'} or length($v[14]) < $c_v{'minsize'};
	 next if $v[2] > $c_v{'maxperiod'} or $v[2] < $c_v{'minperiod'};
	 next if $v[3] < $c_v{'exp'};
	 next if $v[7] < $c_v{'minscore'};
	 next if $c_v{'maxscore'} and $v[7] > $c_v{'maxscore'};
	 next if $v[5] < $c_v{'minsim'} or $v[5] > $c_v{'maxsim'};
	 $self->debug("Cool!");
	 
	 my $id = $self->_next_child_id;
	 push @feats, Bio::Polloc::LocusI->new(
	 		-type=>'repeat', # Be careful, usually $self->type
			-rule=>$self, -seq=>$seq,
			-from=>$v[0]+0, -to=>$v[1]+0, -strand=>"+",
			-name=>$self->name,
			-id=>(defined $id ? $id : ""),
			-period=>$v[2]+0, -exponent=>$v[3]+0,
			-consensus=>$v[13],
			-error=>100-$v[5],
			-score=>$v[7],
			-repeats=>$v[14]);
      }
   }
   $run->close();
   unlink $outfile;
   rmdir $tmpdir;
   return wantarray ? @feats : \@feats;
}

=head2 stringify_value

Produces a string with the value of the rule.

=cut

sub stringify_value {
   my ($self,@args) = @_;
   my $out = "";
   for my $k (keys %{$self->value}){
      $out.= "$k=>".(defined $self->value->{$k} ? $self->value->{$k} : "")." ";
   }
   return $out;
}

=head2 value

=head3 Arguments

Value (I<str> or I<hashref> or I<arrayref>).  The supported keys are:

=over

=item -minsize I<int>

Minimum size of the repeat

=item -maxsize I<int>

Maximum size of the repeat

=item -minperiod I<float>

Minimum period of the repeat

=item -maxperiod I<float>

Maximum period of the repeat

=item -exp I<float>

Minimum exponent (number of repeats)

=item -match I<int>

Matching weight

=item -mismatch I<int>

Mismatching penalty

=item -indels I<int>

Indel penalty

=item -minscore I<float>

Minimum score

=item -maxscore I<float>

Maximum score

=item -minsim I<float>

Minimum similarity percent

=item -maxsim I<float>

Maximum similarity percent

=item -pm I<float>

Match probability

=item -pi I<float>

Indel probability

=back

=head3 Return

Value (I<hashref> or C<undef>).

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _parameters

=cut

sub _parameters { return [qw(MINSIZE MAXSIZE MINPERIOD MAXPERIOD EXP MATCH MISMATCH INDELS MINSCORE MAXSCORE MINSIM MAXSIM PM PI)] }

=head2 _executable

Attempts to find the TRF executable.

=cut

sub _executable {
   my($self, $path) = @_;
   my $exe;
   my $bin;
   my $name = 'trf';
   my $io = "Bio::Polloc::Polloc::IO";
   $self->debug("Searching the $name binary for $^O");
   # Note the darwin support.  This is because darwin is unable to execute
   # the linux binary (despite its origin)
   $bin=$^O =~ /(macos|darwin)/i ? "$name.macosx.bin" :
   	$^O =~ /mswin/i ? "$name.exe" :
	$Config{'archname64'} ? "$name.linux64.bin" :
	"$name.linux32.bin";
   my @pre = ('');
   unshift @pre, $path if $path;
   for my $p (@pre) {
      # Try first WITH version, to avoid v3 series
      for my $v ((404, 403, 402, 401, 400, '')){
         for my $e (('', '.bin', '.exe')){
	    for my $n (($bin, $name)){
	       $exe = $io->exists_exe($p . $n . $v . $e);
	       return $exe if $exe;
	    }
	 }
      }
   }
   # Other awful naming systems can be used by this package, but here we stop!
}

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   $self->type('tandemrepeat');
}

1;
