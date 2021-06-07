# (c) 2003-21 Vlado Keselj https://web.cs.dal.ca/~vlado

package AI::NaiveBayes1;
use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@EXPORT = qw(new);
use vars qw($Version);
$Version = $VERSION = '2.012';

use vars @EXPORT_OK;

# non-exported package globals go here
use vars qw();

sub new {
  my $package = shift;
  return bless {
                attributes => [ ],
		labels     => [ ],
		attvals    => {},
		real_stat  => {},
		numof_instances => 0,
		stat_labels => {},
		stat_attributes => {},
		smoothing => {},
		attribute_type => {},
	       }, $package;
}

sub set_real {
    my ($self, @attr) = @_;
    foreach my $a (@attr) { $self->{attribute_type}{$a} = 'real' }
}

sub import_from_YAML {
    my $package = shift;
    my $yaml = shift;
    my $self = YAML::Load($yaml);
    return bless $self, $package;
}

sub import_from_YAML_file {
    my $package = shift;
    my $yamlf = shift;
    my $self = YAML::LoadFile($yamlf);
    return bless $self, $package;
}

# assume that the last header count means counts
# after optionally removing counts, the last header is label
sub add_table {
    my $self = shift;
    my @atts = (); my $lbl=''; my $cnt = '';
    while (@_) {
	my $table = shift;
	if ($table =~ /^(.*)\n[ \t]*-+\n/) {
	    my $a = $1; $table = $';
	    $a =~ s/^\s+//; $a =~ s/\s+$//;
	    if ($a =~ /\s*\bcount\s*$/) {
		$a=$`; $cnt=1; } else { $cnt='' }
	    @atts = split(/\s+/, $a);
	    $lbl = pop @atts;
	}
	while ($table ne '') {
	    $table =~ /^(.*)\n?/ or die;
	    my $r=$1; $table = $';
	    $r =~ s/^\s+//; $r=~ s/\s+$//;
	    if ($r =~ /^-+$/) { next }
	    my @v = split(/\s+/, $r);
	    die "values (#=$#v): {@v}\natts (#=$#atts): @atts, lbl=$lbl,\n".
                 "count: $cnt\n" unless $#v-($cnt?2:1) == $#atts;
	    my %av=(); my @a = @atts;
	    while (@a) { $av{shift @a} = shift(@v) }
	    $self->add_instances(attributes=>\%av,
				 label=>"$lbl=$v[0]",
				 cases=>($cnt?$v[1]:1) );
	}
    }
} # end of add_table

# Simplified; not generally compatible.
# Assume that the last header is label.  The first row contains
# attribute names.
sub add_csv_file {
    my $self = shift; my $fn = shift; local *F;
    open(F,$fn) or die "Cannot open CSV file `$fn': $!";
    local $_ = <F>; my @atts = (); my $lbl=''; my $cnt = '';
    chomp; @atts = split(/\s*,\s*/, $_); $lbl = pop @atts;
    while (<F>) {
	chomp; my @v = split(/\s*,\s*/, $_);
	die "values (#=$#v): {@v}\natts (#=$#atts): @atts, lbl=$lbl,\n".
	    "count: $cnt\n" unless $#v-($cnt?2:1) == $#atts;
	my %av=(); my @a = @atts;
	while (@a) { $av{shift @a} = shift(@v) }
	$self->add_instances(attributes=>\%av,
			     label=>"$lbl=$v[0]",
			     cases=>($cnt?$v[1]:1) );
    }
    close(F);
} # end of add_csv_file

sub drop_attributes {
    my $self = shift;
    foreach my $a (@_) {
	my @tmp = grep { $a ne $_ } @{ $self->{attributes} };
	$self->{attributes} = \@tmp;
	delete($self->{attvals}{$a});
	delete($self->{stat_attributes}{$a});
	delete($self->{attribute_type}{$a});
	delete($self->{real_stat}{$a});
	delete($self->{smoothing}{$a});
    }
} # end of drop_attributes

sub add_instances {
  my ($self, %params) = @_;
  for ('attributes', 'label', 'cases') {
      die "Missing required '$_' parameter" unless exists $params{$_};
  }

  if (scalar(keys(%{ $self->{stat_attributes} })) == 0) {
      foreach my $a (keys(%{$params{attributes}})) {
	  $self->{stat_attributes}{$a} = {};
	  push @{ $self->{attributes} }, $a;
	  $self->{attvals}{$a} = [ ];
	  $self->{attribute_type}{$a} = 'nominal' unless defined($self->{attribute_type}{$a});
      }
  } else {
      foreach my $a (keys(%{$self->{stat_attributes}}))
      { die "attribute not given in instance: $a"
	    unless exists($params{attributes}{$a}) }
  }

  $self->{numof_instances} += $params{cases};

  push @{ $self->{labels} }, $params{label} unless
      exists $self->{stat_labels}->{$params{label}};

  $self->{stat_labels}{$params{label}} += $params{cases};

  foreach my $a (keys(%{$self->{stat_attributes}})) {
      if ( not exists($params{attributes}{$a}) )
      { die "attribute $a not given" }
      my $attval = $params{attributes}{$a};
      if (not exists($self->{stat_attributes}{$a}{$attval})) {
	  push @{ $self->{attvals}{$a} }, $attval;
	  $self->{stat_attributes}{$a}{$attval} = {};
      }
      $self->{stat_attributes}{$a}{$attval}{$params{label}} += $params{cases};
  }
}

sub add_instance {
    my ($self, %params) = @_; $params{cases} = 1;
    $self->add_instances(%params);
}

sub train {
    my $self = shift;
    my $m = $self->{model} = {};
    
    $m->{labelprob} = {};
    foreach my $label (keys(%{$self->{stat_labels}}))
    { $m->{labelprob}{$label} = $self->{stat_labels}{$label} /
                                $self->{numof_instances} } 

    $m->{condprob} = {};
    $m->{condprobe} = {};
    foreach my $att (keys(%{$self->{stat_attributes}})) {
        next if $self->{attribute_type}{$att} eq 'real';
	$m->{condprob}{$att} = {};
	$m->{condprobe}{$att} = {};
	foreach my $label (keys(%{$self->{stat_labels}})) {
	    my $total = 0; my @attvals = ();
	    foreach my $attval (keys(%{$self->{stat_attributes}{$att}})) {
		next unless
		    exists($self->{stat_attributes}{$att}{$attval}{$label}) and
		    $self->{stat_attributes}{$att}{$attval}{$label} > 0;
		push @attvals, $attval;
		$m->{condprob}{$att}{$attval} = {} unless
		    exists( $m->{condprob}{$att}{$attval} );
		$m->{condprob}{$att}{$attval}{$label} = 
		    $self->{stat_attributes}{$att}{$attval}{$label};
		$m->{condprobe}{$att}{$attval} = {} unless
		    exists( $m->{condprob}{$att}{$attval} );
		$m->{condprobe}{$att}{$attval}{$label} = 
		    $self->{stat_attributes}{$att}{$attval}{$label};
		$total += $m->{condprob}{$att}{$attval}{$label};
	    }
	    if (exists($self->{smoothing}{$att}) and
		$self->{smoothing}{$att} =~ /^unseen count=/) {
		my $uc = $'; $uc = 0.5 if $uc <= 0;
		if(! exists($m->{condprob}{$att}{'*'}) ) {
		    $m->{condprob}{$att}{'*'} = {};
		    $m->{condprobe}{$att}{'*'} = {};
		}
		$m->{condprob}{$att}{'*'}{$label} = $uc;
		$total += $uc;
		if (grep {$_ eq '*'} @attvals) { die }
		push @attvals, '*';
	    }
	    foreach my $attval (@attvals) {
		$m->{condprobe}{$att}{$attval}{$label} =
		    "(= $m->{condprob}{$att}{$attval}{$label} / $total)";
		$m->{condprob}{$att}{$attval}{$label} /= $total;
	    }
	}
    }

    # For real-valued attributes, we use Gaussian distribution
    # let us collect statistics
    foreach my $att (keys(%{$self->{stat_attributes}})) {
        next unless $self->{attribute_type}{$att} eq 'real';
	print STDERR "Smoothing ignored for real attribute $att!\n" if
	    defined($self->{smoothing}{att}) and $self->{smoothing}{att};
        $m->{real_stat}->{$att} = {};
        foreach my $attval (keys %{$self->{stat_attributes}{$att}}){
            foreach my $label (keys %{$self->{stat_attributes}{$att}{$attval}}){
                $m->{real_stat}{$att}{$label}{sum}
                += $attval * $self->{stat_attributes}{$att}{$attval}{$label};

                $m->{real_stat}{$att}{$label}{count}
                += $self->{stat_attributes}{$att}{$attval}{$label};
            }
            foreach my $label (keys %{$self->{stat_attributes}{$att}{$attval}}){
		next if
                !defined($m->{real_stat}{$att}{$label}{count}) ||
		$m->{real_stat}{$att}{$label}{count} == 0;

                $m->{real_stat}{$att}{$label}{mean} =
                    $m->{real_stat}{$att}{$label}{sum} /
                        $m->{real_stat}{$att}{$label}{count};
            }
        }

        # calculate stddev
        foreach my $attval (keys %{$self->{stat_attributes}{$att}}) {
            foreach my $label (keys %{$self->{stat_attributes}{$att}{$attval}}){
                $m->{real_stat}{$att}{$label}{stddev} +=
		    ($attval - $m->{real_stat}{$att}{$label}{mean})**2 *
		    $self->{stat_attributes}{$att}{$attval}{$label};
            }
        }
	foreach my $label (keys %{$m->{real_stat}{$att}}) {
	    $m->{real_stat}{$att}{$label}{stddev} =
		sqrt($m->{real_stat}{$att}{$label}{stddev} /
		     ($m->{real_stat}{$att}{$label}{count}-1)
		     );
	}
    }				# foreach real attribute
}				# end of sub train

sub predict {
  my ($self, %params) = @_;
  my $newattrs = $params{attributes} or die "Missing 'attributes' parameter for predict()";
  my $m = $self->{model};  # For convenience
  
  my %scores;
  my @labels = @{ $self->{labels} };
  $scores{$_} = $m->{labelprob}{$_} foreach (@labels);
  foreach my $att (keys(%{ $newattrs })) {
      if (!defined($self->{attribute_type}{$att})) { die "Unknown attribute: `$att'" }
      next if $self->{attribute_type}{$att} eq 'real';
      die unless exists($self->{stat_attributes}{$att});
      my $attval = $newattrs->{$att};
      die "Unknown value `$attval' for attribute `$att'."
      unless exists($self->{stat_attributes}{$att}{$attval}) or
	  exists($self->{smoothing}{$att});
      foreach my $label (@labels) {
	  if (exists($m->{condprob}{$att}{$attval}) and
	      exists($m->{condprob}{$att}{$attval}{$label}) and
	      $m->{condprob}{$att}{$attval}{$label} > 0 ) {
	      $scores{$label} *=
		  $m->{condprob}{$att}{$attval}{$label};
	  } elsif (exists($self->{smoothing}{$att})) {
	      $scores{$label} *=
                  $m->{condprob}{$att}{'*'}{$label};
	  } else { $scores{$label} = 0 }

      }
  }

  foreach my $att (keys %{$newattrs}){
      next unless $self->{attribute_type}{$att} eq 'real';
      my $sum=0; my %nscores;
      foreach my $label (@labels) {
	  die unless exists $m->{real_stat}{$att}{$label}{mean};
	  $nscores{$label} =
              0.398942280401433 / $m->{real_stat}{$att}{$label}{stddev}*
              exp( -0.5 *
                  ( ( $newattrs->{$att} -
                      $m->{real_stat}{$att}{$label}{mean})
                    / $m->{real_stat}{$att}{$label}{stddev}
                  ) ** 2
		 );
	  $sum += $nscores{$label};
      }
      if ($sum==0) { print STDERR "Ignoring all Gaussian probabilities: all=0!\n" }
      else {
	  foreach my $label (@labels) { $scores{$label} *= $nscores{$label} }
      }
  }

  my $sumPx = 0.0;
  $sumPx += $scores{$_} foreach (keys(%scores));
  $scores{$_} /= $sumPx foreach (keys(%scores));
  return \%scores;
}

sub print_model {
    my $self = shift;
    my $withcounts = '';
    if ($#_>-1 && $_[0] eq 'with counts')
    { shift @_; $withcounts = 1; }
    my $m = $self->{model};
    my @labels = $self->labels;
    my $r;

    # prepare table category P(category)
    my @lines;
    push @lines, 'category ', '-';
    push @lines, "$_ " foreach @labels;
    @lines = _append_lines(@lines);
    @lines = map { $_.='| ' } @lines;
    $lines[1] = substr($lines[1],0,length($lines[1])-2).'+-';
    $lines[0] .= "P(category) ";
    foreach my $i (2..$#lines) {
	my $label = $labels[$i-2];
	$lines[$i] .= $m->{labelprob}{$label} .' ';
	if ($withcounts) {
	    $lines[$i] .= "(= $self->{stat_labels}{$label} / ".
		"$self->{numof_instances} ) ";
	}
    }
    @lines = _append_lines(@lines);

    $r .= join("\n", @lines) . "\n". $lines[1]. "\n\n";

    # prepare conditional tables
    my @attributes = sort $self->attributes;
    foreach my $att (@attributes) {
	@lines = ( "category ", '-' );
	my @lines1 = ( "$att ", '-' );
	my @lines2 = ( "P( $att | category ) ", '-' );
	my @attvals = sort keys(%{ $m->{condprob}{$att} });
	foreach my $label (@labels) {
	    if ( $self->{attribute_type}{$att} ne 'real' ) {
		foreach my $attval (@attvals) {
		    next unless exists($m->{condprob}{$att}{$attval}{$label});
		    push @lines, "$label ";
		    push @lines1, "$attval ";

		    my $line = $m->{condprob}{$att}{$attval}{$label};
		    if ($withcounts)
		    { $line.= ' '.$m->{condprobe}{$att}{$attval}{$label} }
		    $line .= ' ';
		    push @lines2, $line;
		}
	    } else {
		push @lines, "$label ";
		push @lines1, "real ";
		push @lines2, "Gaussian(mean=".
		    $m->{real_stat}{$att}{$label}{mean}.",stddev=".
		    $m->{real_stat}{$att}{$label}{stddev}.") ";
	    }
	    push @lines, '-'; push @lines1, '-'; push @lines2, '-';
	}
	@lines = _append_lines(@lines);
	foreach my $i (0 .. $#lines)
	{ $lines[$i] .= ($lines[$i]=~/-$/?'+-':'| ') . $lines1[$i] }
	@lines = _append_lines(@lines);
	foreach my $i (0 .. $#lines)
	{ $lines[$i] .= ($lines[$i]=~/-$/?'+-':'| ') . $lines2[$i] }
	@lines = _append_lines(@lines);

	$r .= join("\n", @lines). "\n\n";
    }

    return $r;
}

sub _append_lines {
    my @l = @_;
    my $m = 0;
    foreach (@l) { $m = length($_) if length($_) > $m }
    @l = map 
    { while (length($_) < $m) { $_.=substr($_,length($_)-1) }; $_ }
    @l;
    return @l;
}

sub labels {
  my $self = shift;
  return @{ $self->{labels} };
}

sub attributes {
  my $self = shift;
  return keys %{ $self->{stat_attributes} };
}

sub export_to_YAML {
    my $self = shift;
    require YAML;
    return YAML::Dump($self);
}

sub export_to_YAML_file {
    my $self = shift;
    my $file = shift;
    require YAML;
    YAML::DumpFile($file, $self);
}

1;
__END__

=head1 NAME

AI::NaiveBayes1 - Naive Bayes Classification

=head1 SYNOPSIS

  use AI::NaiveBayes1;
  my $nb = AI::NaiveBayes1->new;
  $nb->add_table(
  "Html  Caps  Free  Spam  count
  -------------------------------
     Y     Y     Y     Y    42   
     Y     Y     Y     N    32   
     Y     Y     N     Y    17   
     Y     Y     N     N     7   
     Y     N     Y     Y    32   
     Y     N     Y     N    12   
     Y     N     N     Y    20   
     Y     N     N     N    16   
     N     Y     Y     Y    38   
     N     Y     Y     N    18   
     N     Y     N     Y    16   
     N     Y     N     N    16   
     N     N     Y     Y     2   
     N     N     Y     N     9   
     N     N     N     Y    11   
     N     N     N     N    91   
  -------------------------------
  ");
  $nb->train;
  print "Model:\n" . $nb->print_model;
  print "Model (with counts):\n" . $nb->print_model('with counts');

  $nb = AI::NaiveBayes1->new;
  $nb->add_instances(attributes=>{model=>'H',place=>'B'},
		     label=>'repairs=Y',cases=>30);
  $nb->add_instances(attributes=>{model=>'H',place=>'B'},
		     label=>'repairs=N',cases=>10);
  $nb->add_instances(attributes=>{model=>'H',place=>'N'},
		     label=>'repairs=Y',cases=>18);
  $nb->add_instances(attributes=>{model=>'H',place=>'N'},
		     label=>'repairs=N',cases=>16);
  $nb->add_instances(attributes=>{model=>'T',place=>'B'},
		     label=>'repairs=Y',cases=>22);
  $nb->add_instances(attributes=>{model=>'T',place=>'B'},
		     label=>'repairs=N',cases=>14);
  $nb->add_instances(attributes=>{model=>'T',place=>'N'},
		     label=>'repairs=Y',cases=> 6);
  $nb->add_instances(attributes=>{model=>'T',place=>'N'},
		     label=>'repairs=N',cases=>84);

  $nb->train;

  print "Model:\n" . $nb->print_model;
  
  # Find results for unseen instances
  my $result = $nb->predict
     (attributes => {model=>'T', place=>'N'});

  foreach my $k (keys(%{ $result })) {
      print "for label $k P = " . $result->{$k} . "\n";
  }

  # export the model into a string
  my $string = $nb->export_to_YAML();

  # create the same model from the string
  my $nb1 = AI::NaiveBayes1->import_from_YAML($string);

  # write the model to a file (shorter than model->string->file)
  $nb->export_to_YAML_file('t/tmp1');

  # read the model from a file (shorter than file->string->model)
  my $nb2 = AI::NaiveBayes1->import_from_YAML_file('t/tmp1');

See Examples for more examples.

=head1 DESCRIPTION

This module implements the classic "Naive Bayes" machine learning
algorithm.

=head2 Data Structure

An object contains the following fields:

=over 4

=item C<{attributes}>

List of attribute names.

=item C<{attribute_type}{$a}>

Attribute types - 'real', or not (e.g., 'nominal')

=item C<{labels}>

List of labels.

=item C<{attvals}{$a}>

List of attribute values

=item C<{real_stat}{$a}{$v}{$l}{sum}>

Statistics for real valued attributes; besides 'sum' also: count, mean, stddev

=item C<{numof_instances}>

Number of training instances.

=item C<{stat_labels}{$l}>

Label count in training data.

=item C<{stat_attributes}{$a}>

Statistics for an attribute: C<...{$value}{$label}> = count of
instances.

=item C<{smoothing}{$attribute}>

Attribute smoothing.  No smoothing if does not exist.  Implemented smoothing:

      - /^unseen count=/ followed by number, e.g., 0.5

=back

=head2 Attribute Smoothing

For an attribute A one can specify:

    $nb->{smoothing}{A} = 'unseen count=0.5';

to provide a count for unseen data.  The count is taken into
consideration in training and prediction, when any unseen attribute
values are observed.  Zero probabilities can be prevented in this way.
A count other than 0.5 can be provided, but if it is <=0 it will be
set to 0.5.  The method is similar to add-one smoothing.  A special
attribute value '*' is used for all unseen data. 

=head1 METHODS

=head2 Constructor Methods

=over 4

=item new()

Constructor. Creates a new C<AI::NaiveBayes1> object and returns it.

=item import_from_YAML($string)

Constructor. Creates a new C<AI::NaiveBayes1> object from a string where it is
represented in C<YAML>.  Requires YAML module.

=item import_from_YAML_file($file_name)

Constructor. Creates a new C<AI::NaiveBayes1> object from a file where it is
represented in C<YAML>.  Requires YAML module.

=back

=head2 Non-Constructor Methods

=over 4

=item add_table()

Add instances from a table.  The first row are attributes, followed by
values.  If the name of the last attribute is `count', it is
interpreted as a repetition count and used appropriatelly.  The last
attribute (after optionally removing `count') is the class attribute.
The attributes and values are separated by white space.

=item add_csv_file($filename)

Add instances from a CSV file.  Primitive format implementation (e.g.,
no commas allowed in attribute names or values).

=item drop_attributes(@attributes)

Delete attributes after adding instances.

=item set_real(list_of_attributes)

Delares a list of attributes to be real-valued.  During training,
their conditional probabilities will be modeled with Gaussian (normal)
distributions. 

=item C<add_instance(attributes=E<gt>HASH,label=E<gt>STRING|ARRAY)>

Adds a training instance to the categorizer.

=item C<add_instances(attributes=E<gt>HASH,label=E<gt>STRING|ARRAY,cases=E<gt>NUMBER)>

Adds a number of identical instances to the categorizer.

=item export_to_YAML()

Returns a C<YAML> string representation of an C<AI::NaiveBayes1>
object.  Requires YAML module.

=item C<export_to_YAML_file( $file_name )>

Writes a C<YAML> string representation of an C<AI::NaiveBayes1>
object to a file.  Requires YAML module.

=item C<print_model( OPTIONAL 'with counts' )>

Returns a string, human-friendly representation of the model.
The model is supposed to be trained before calling this method.
One argument 'with counts' can be supplied, in which case explanatory
expressions with counts are printed as well.

=item train()

Calculates the probabilities that will be necessary for categorization
using the C<predict()> method.

=item C<predict( attributes =E<gt> HASH )>

Use this method to predict the label of an unknown instance.  The
attributes should be of the same format as you passed to
C<add_instance()>.  C<predict()> returns a hash reference whose keys
are the names of labels, and whose values are corresponding
probabilities.

=item C<labels>

Returns a list of all the labels the object knows about (in no
particular order), or the number of labels if called in a scalar
context.

=back

=head1 THEORY

Bayes' Theorem is a way of inverting a conditional probability. It
states:

                P(y|x) P(x)
      P(x|y) = -------------
                   P(y)

and so on...

This is a pretty standard algorithm explained in many machine learning
textbooks (e.g., "Data Mining" by Witten and Eibe).

The algorithm relies on estimating P(A|C), where A is an arbitrary
attribute, and C is the class attribute.  If A is not real-valued,
then this conditional probability is estimated using a table of all
possible values for A and C.

If A is real-valued, then the distribution P(A|C) is modeled as a
Gaussian (normal) distribution for each possible value of C=c,  Hence,
for each C=c we collect the mean value (m) and standard deviation (s)
for A during training.  During classification, P(A=a|C=c) is estimated
using Gaussian distribution, i.e., in the following way:

                    1               (a-m)^2
 P(A=a|C=c) = ------------ * exp( - ------- )
              sqrt(2*Pi)*s           2*s^2

this boils down to the following lines of code:

    $scores{$label} *=
    0.398942280401433 / $m->{real_stat}{$att}{$label}{stddev}*
      exp( -0.5 *
           ( ( $newattrs->{$att} -
               $m->{real_stat}{$att}{$label}{mean})
             / $m->{real_stat}{$att}{$label}{stddev}
           ) ** 2
	   );

i.e.,

  P(A=a|C=c) = 0.398942280401433 / s *
    exp( -0.5 * ( ( a-m ) / s ) ** 2 );


=head1 EXAMPLES

Example with a real-valued attribute modeled by a Gaussian
distribution (from Witten I. and Frank E. book "Data Mining" (the WEKA
book), page 86):

 # @relation weather
 # 
 # @attribute outlook {sunny, overcast, rainy}
 # @attribute temperature real
 # @attribute humidity real
 # @attribute windy {TRUE, FALSE}
 # @attribute play {yes, no}
 # 
 # @data
 # sunny,85,85,FALSE,no
 # sunny,80,90,TRUE,no
 # overcast,83,86,FALSE,yes
 # rainy,70,96,FALSE,yes
 # rainy,68,80,FALSE,yes
 # rainy,65,70,TRUE,no
 # overcast,64,65,TRUE,yes
 # sunny,72,95,FALSE,no
 # sunny,69,70,FALSE,yes
 # rainy,75,80,FALSE,yes
 # sunny,75,70,TRUE,yes
 # overcast,72,90,TRUE,yes
 # overcast,81,75,FALSE,yes
 # rainy,71,91,TRUE,no
 
 $nb->set_real('temperature', 'humidity');
 
 $nb->add_instance(attributes=>{outlook=>'sunny',temperature=>85,humidity=>85,windy=>'FALSE'},label=>'play=no');
 $nb->add_instance(attributes=>{outlook=>'sunny',temperature=>80,humidity=>90,windy=>'TRUE'},label=>'play=no');
 $nb->add_instance(attributes=>{outlook=>'overcast',temperature=>83,humidity=>86,windy=>'FALSE'},label=>'play=yes');
 $nb->add_instance(attributes=>{outlook=>'rainy',temperature=>70,humidity=>96,windy=>'FALSE'},label=>'play=yes');
 $nb->add_instance(attributes=>{outlook=>'rainy',temperature=>68,humidity=>80,windy=>'FALSE'},label=>'play=yes');
 $nb->add_instance(attributes=>{outlook=>'rainy',temperature=>65,humidity=>70,windy=>'TRUE'},label=>'play=no');
 $nb->add_instance(attributes=>{outlook=>'overcast',temperature=>64,humidity=>65,windy=>'TRUE'},label=>'play=yes');
 $nb->add_instance(attributes=>{outlook=>'sunny',temperature=>72,humidity=>95,windy=>'FALSE'},label=>'play=no');
 $nb->add_instance(attributes=>{outlook=>'sunny',temperature=>69,humidity=>70,windy=>'FALSE'},label=>'play=yes');
 $nb->add_instance(attributes=>{outlook=>'rainy',temperature=>75,humidity=>80,windy=>'FALSE'},label=>'play=yes');
 $nb->add_instance(attributes=>{outlook=>'sunny',temperature=>75,humidity=>70,windy=>'TRUE'},label=>'play=yes');
 $nb->add_instance(attributes=>{outlook=>'overcast',temperature=>72,humidity=>90,windy=>'TRUE'},label=>'play=yes');
 $nb->add_instance(attributes=>{outlook=>'overcast',temperature=>81,humidity=>75,windy=>'FALSE'},label=>'play=yes');
 $nb->add_instance(attributes=>{outlook=>'rainy',temperature=>71,humidity=>91,windy=>'TRUE'},label=>'play=no');
 
 $nb->train;
 
 my $printedmodel =  "Model:\n" . $nb->print_model;
 my $p = $nb->predict(attributes=>{outlook=>'sunny',temperature=>66,humidity=>90,windy=>'TRUE'});

 YAML::DumpFile('file', $p);
 die unless (abs($p->{'play=no'}  - 0.792) < 0.001);
 die unless(abs($p->{'play=yes'} - 0.208) < 0.001);

=head1 HISTORY

L<Algorithm::NaiveBayes> by Ken Williams was not what I needed so I
wrote this one.  L<Algorithm::NaiveBayes> is oriented towards text
categorization, it includes smoothing, and log probabilities.  This
module is a generic, basic Naive Bayes algorithm.

=head1 THANKS

I would like to thank Daniel Bohmer for documentation corrections,
Yung-chung Lin (cpan:xern) for the implementation of the Gaussian model
for continuous variables, and the following people for bug reports, support,
and comments (in no particular order):

Michael Stevens, Tom Dyson, Dan Von Kohorn, Craig Talbert,
Andrew Brian Clegg,

and CPAN-testers, including: Andreas Koenig, Alexandr Ciornii, jlatour,
Jost.Krieger, tvmaly, Matthew Musgrove, Michael Stevens, Nigel Horne,
Graham Crookham, David Cantrell (dcantrell).

=head1 AUTHOR

Copyright 2003-21 Vlado Keselj L<https://web.cs.dal.ca/~vlado>.
In 2004 Yung-chung Lin provided implementation of the Gaussian model for
continous variables.

This script is provided "as is" without expressed or implied warranty.
This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The module is available on CPAN (L<https://metacpan.org/author/VLADO>), and
L<https://web.cs.dal.ca/~vlado/srcperl/>.  The latter site is
updated more frequently.

=head1 SEE ALSO

L<Algorithm::NaiveBayes>, L<perl>.

=cut
