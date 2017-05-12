package AI::Categorizer::Document;

use strict;
use Class::Container;
use base qw(Class::Container);

use Params::Validate qw(:types);
use AI::Categorizer::ObjectSet;
use AI::Categorizer::FeatureVector;

__PACKAGE__->valid_params
  (
   name       => {
		  type => SCALAR, 
		 },
   categories => {
		  type => ARRAYREF,
		  default => [],
		  callbacks => { 'all are Category objects' => 
				 sub { ! grep !UNIVERSAL::isa($_, 'AI::Categorizer::Category'), @{$_[0]} },
			       },
		  public => 0,
		 },
   stopwords => {
		 type => ARRAYREF|HASHREF,
		 default => {},
		},
   content   => {
		 type => HASHREF|SCALAR,
		 default => undef,
		},
   parse => {
	     type => SCALAR,
	     optional => 1,
	    },
   parse_handle => {
		    type => HANDLE,
		    optional => 1,
		   },
   features => {
		isa => 'AI::Categorizer::FeatureVector',
		optional => 1,
	       },
   content_weights => {
		       type => HASHREF,
		       default => {},
		      },
   front_bias => {
		  type => SCALAR,
		  default => 0,
		  },
   use_features => {
		    type => HASHREF|UNDEF,
		    default => undef,
		   },
   stemming => {
		type => SCALAR|UNDEF,
		optional => 1,
	       },
   stopword_behavior => {
			 type => SCALAR,
			 default => "stem",
			},
  );

__PACKAGE__->contained_objects
  (
   features => { delayed => 1,
		 class => 'AI::Categorizer::FeatureVector' },
  );

### Constructors

my $NAME = 'a';

sub new {
  my $pkg = shift;
  my $self = $pkg->SUPER::new(name => $NAME++,  # Use a default name
			      @_);

  # Get efficient internal data structures
  $self->{categories} = new AI::Categorizer::ObjectSet( @{$self->{categories}} );

  $self->_fix_stopwords;
  
  # A few different ways for the caller to initialize the content
  if (exists $self->{parse}) {
    $self->parse(content => delete $self->{parse});
    
  } elsif (exists $self->{parse_handle}) {
    $self->parse_handle(handle => delete $self->{parse_handle});
    
  } elsif (defined $self->{content}) {
    # Allow a simple string as the content
    $self->{content} = { body => $self->{content} } unless ref $self->{content};
  }
  
  $self->finish if $self->{content};
  return $self;
}

sub _fix_stopwords {
  my $self = shift;
  
  # Convert to hash
  $self->{stopwords} = { map {($_ => 1)} @{ $self->{stopwords} } }
    if UNIVERSAL::isa($self->{stopwords}, 'ARRAY');
  
  my $s = $self->{stopwords};

  # May need to perform stemming on the stopwords
  return unless keys %$s; # No point in doing anything if there are no stopwords
  return unless $self->{stopword_behavior} eq 'stem';
  return if !defined($self->{stemming}) or $self->{stemming} eq 'none';
  return if $s->{___stemmed};
  
  my @keys = keys %$s;
  %$s = ();
  $self->stem_words(\@keys);
  $s->{$_} = 1 foreach @keys;
  
  # This flag is attached to the stopword structure itself so that
  # other documents will notice it.
  $s->{___stemmed} = 1;
}

sub finish {
  my $self = shift;
  $self->create_feature_vector;
  
  # Now we're done with all the content stuff
  delete @{$self}{'content', 'content_weights', 'stopwords', 'use_features'};
}


# Parse a document format - a virtual method
sub parse;

sub parse_handle {
  my ($self, %args) = @_;
  my $fh = $args{handle} or die "No 'handle' argument given to parse_handle()";
  return $self->parse( content => join '', <$fh> );
}

### Accessors

sub name { $_[0]->{name} }
sub stopword_behavior { $_[0]->{stopword_behavior} }

sub features {
  my $self = shift;
  if (@_) {
    $self->{features} = shift;
  }
  return $self->{features};
}

sub categories {
  my $c = $_[0]->{categories};
  return wantarray ? $c->members : $c->size;
}


### Workers

sub create_feature_vector {
  my $self = shift;
  my $content = $self->{content};
  my $weights = $self->{content_weights};

  die "'stopword_behavior' must be one of 'stem', 'no_stem', or 'pre_stemmed'"
    unless $self->{stopword_behavior} =~ /^stem|no_stem|pre_stemmed$/;

  $self->{features} = $self->create_delayed_object('features');
  while (my ($name, $data) = each %$content) {
    my $t = $self->tokenize($data);
    $t = $self->_filter_tokens($t) if $self->{stopword_behavior} eq 'no_stem';
    $self->stem_words($t);
    $t = $self->_filter_tokens($t) if $self->{stopword_behavior} =~ /^stem|pre_stemmed$/;
    my $h = $self->vectorize(tokens => $t, weight => exists($weights->{$name}) ? $weights->{$name} : 1 );
    $self->{features}->add($h);
  }
}

sub is_in_category {
  return (ref $_[1]
	  ? $_[0]->{categories}->includes( $_[1] )
	  : $_[0]->{categories}->includes_name( $_[1] ));
    
}

sub tokenize {
  my $self = shift;
  my @tokens;
  while ($_[0] =~ /([-\w]+)/g) {
    my $word = lc $1;
    next unless $word =~ /[a-z]/;
    $word =~ s/^[^a-z]+//;  # Trim leading non-alpha characters (helps with ordinals)
    push @tokens, $word;
  }
  return \@tokens;
}

sub stem_words {
  my ($self, $tokens) = @_;
  return unless $self->{stemming};
  return if $self->{stemming} eq 'none';
  die "Unknown stemming option '$self->{stemming}' - options are 'porter' or 'none'"
    unless $self->{stemming} eq 'porter';
  
  eval {require Lingua::Stem; 1}
    or die "Porter stemming requires the Lingua::Stem module, available from CPAN.\n";

  @$tokens = @{ Lingua::Stem::stem(@$tokens) };
}

sub _filter_tokens {
  my ($self, $tokens_in) = @_;

  if ($self->{use_features}) {
    my $f = $self->{use_features}->as_hash;
    return [ grep  exists($f->{$_}), @$tokens_in ];
  } elsif ($self->{stopwords} and keys %{$self->{stopwords}}) {
    my $s = $self->{stopwords};
    return [ grep !exists($s->{$_}), @$tokens_in ];
  }
  return $tokens_in;
}

sub _weigh_tokens {
  my ($self, $tokens, $weight) = @_;

  my %counts;
  if (my $b = 0+$self->{front_bias}) {
    die "'front_bias' value must be between -1 and 1"
      unless -1 < $b and $b < 1;
    
    my $n = @$tokens;
    my $r = ($b-1)**2 / ($b+1);
    my $mult = $weight * log($r)/($r-1);
    
    my $i = 0;
    foreach my $feature (@$tokens) {
      $counts{$feature} += $mult * $r**($i/$n);
      $i++;
    }
    
  } else {
    foreach my $feature (@$tokens) {
      $counts{$feature} += $weight;
    }
  }

  return \%counts;
}

sub vectorize {
  my ($self, %args) = @_;
  if ($self->{stem_stopwords}) {
    my $s = $self->stem_tokens([keys %{$self->{stopwords}}]);
    $self->{stopwords} = { map {+$_, 1} @$s };
    $args{tokens} = $self->_filter_tokens($args{tokens});
  }
  return $self->_weigh_tokens($args{tokens}, $args{weight});
}

sub read {
  my ($class, %args) = @_;
  my $path = delete $args{path} or die "Must specify 'path' argument to read()";
  
  my $self = $class->new(%args);
  
  open my($fh), "< $path" or die "$path: $!";
  $self->parse_handle(handle => $fh);
  close $fh;
  
  $self->finish;
  return $self;
}

sub dump_features {
  my ($self, %args) = @_;
  my $path = $args{path} or die "No 'path' argument given to dump_features()";
  open my($fh), "> $path" or die "Can't create $path: $!";
  my $f = $self->features->as_hash;
  while (my ($k, $v) = each %$f) {
    print $fh "$k\t$v\n";
  }
}

1;

__END__

=head1 NAME

AI::Categorizer::Document - Embodies a document

=head1 SYNOPSIS

 use AI::Categorizer::Document;
 
 # Simplest way to create a document:
 my $d = new AI::Categorizer::Document(name => $string,
                                       content => $string);
 
 # Other parameters are accepted:
 my $d = new AI::Categorizer::Document(name => $string,
                                       categories => \@category_objects,
                                       content => { subject => $string,
                                                    body => $string2, ... },
                                       content_weights => { subject => 3,
                                                            body => 1, ... },
                                       stopwords => \%skip_these_words,
                                       stemming => $string,
                                       front_bias => $float,
                                       use_features => $feature_vector,
                                      );
 
 # Specify explicit feature vector:
 my $d = new AI::Categorizer::Document(name => $string);
 $d->features( $feature_vector );
 
 # Now pass the document to a categorization algorithm:
 my $learner = AI::Categorizer::Learner::NaiveBayes->restore_state($path);
 my $hypothesis = $learner->categorize($document);

=head1 DESCRIPTION

The Document class embodies the data in a single document, and
contains methods for turning this data into a FeatureVector.  Usually
documents are plain text, but subclasses of the Document class may
handle any kind of data.

=head1 METHODS

=over 4

=item new(%parameters)

Creates a new Document object.  Document objects are used during
training (for the training documents), testing (for the test
documents), and when categorizing new unseen documents in an
application (for the unseen documents).  However, you'll typically
only call C<new()> in the latter case, since the KnowledgeSet or
Collection classes will create Document objects for you in the former
cases.

The C<new()> method accepts the following parameters:

=over 4

=item name

A string that identifies this document.  Required.

=item content

The raw content of this document.  May be specified as either a string
or as a hash reference, allowing structured document types.

=item content_weights

A hash reference indicating the weights that should be assigned to
features in different sections of a structured document when creating
its feature vector.  The weight is a multiplier of the feature vector
values.  For instance, if a C<subject> section has a weight of 3 and a
C<body> section has a weight of 1, and word counts are used as feature
vector values, then it will be as if all words appearing in the
C<subject> appeared 3 times.

If no weights are specified, all weights are set to 1.

=item front_bias

Allows smooth bias of the weights of words in a document according to
their position.  The value should be a number between -1 and 1.
Positive numbers indicate that words toward the beginning of the
document should have higher weight than words toward the end of the
document.  Negative numbers indicate the opposite.  A bias of 0
indicates that no biasing should be done.

=item categories

A reference to an array of Category objects that this document belongs
to.  Optional.

=item stopwords

A list/hash of features (words) that should be ignored when parsing
document content.  A hash reference is preferred, with the features as
the keys.  If you pass an array reference containing the features, it
will be converted to a hash reference internally.

=item use_features

A Feature Vector specifying the only features that should be
considered when parsing this document.  This is an alternative to
using C<stopwords>.

=item stemming

Indicates the linguistic procedure that should be used to convert
tokens in the document to features.  Possible values are C<none>,
which indicates that the tokens should be used without change, or
C<porter>, indicating that the Porter stemming algorithm should be
applied to each token.  This requires the C<Lingua::Stem> module from
CPAN.

=item stopword_behavior

There are a few ways you might want the stopword list (specified with
the C<stopwords> parameter) to interact with the stemming algorithm
(specified with the C<stemming> parameter).  These options can be
controlled with the C<stopword_behavior> parameter, which can take the
following values:

=over 4

=item no_stem

Match stopwords against non-stemmed document words.  

=item stem

Stem stopwords according to 'stemming' parameter, then match them
against stemmed document words.

=item pre_stemmed

Stopwords are already stemmed, match them against stemmed document
words.

=back

The default value is C<stem>, which seems to produce the best results
in most cases I've tried.  I'm not aware of any studies comparing the
C<no_stem> behavior to the C<stem> behavior in the general case.

This parameter has no effect if there are no stopwords being used, or
if stemming is not being used.  In the latter case, the list of
stopwords will always be matched as-is against the document words.

Note that if the C<stem> option is used, the data structure passed as
the C<stopwords> parameter will be modified in-place to contain the
stemmed versions of the stopwords supplied.

=back

=item read( path =E<gt> $path )

An alternative constructor method which reads a file on disk and
returns a document with that file's contents.

=item parse( content =E<gt> $content )



=item name()

Returns this document's C<name> property as specified when the
document was created.

=item features()

Returns the Feature Vector associated with this document.

=item categories()

In a list context, returns a list of Category objects to which this
document belongs.  In a scalar context, returns the number of such
categories.

=item create_feature_vector()

Creates this document's Feature Vector by parsing its content.  You
won't call this method directly, it's called by C<new()>.

=back



=head1 AUTHOR

Ken Williams <ken@mathforum.org>

=head1 COPYRIGHT

This distribution is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.  These terms apply to
every file in the distribution - if you have questions, please contact
the author.

=cut
