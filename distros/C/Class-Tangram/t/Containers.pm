#
#  Test objects for 04-containers.t
#

package Object;
use base qw(Class::Tangram);
our $fields =
    {
     string => [ qw(description) ],
     # a standard, unordered, many to many relationship.  See Person
     # for the other half
     ref => {
	     owner => {
		       class => "Person",
		       companion => "posessions",
		      },
	    },
    };

##Class::Tangram::import_schema(__PACKAGE__);

package Idea;
use base qw(Class::Tangram);
our $fields =
    {
     string => [ qw(content) ],

     set => {
	     # these two relationships allow for an ordered tree
	     # structure, although they are different types
	     basises => {
			 class => "Idea",
			 companion => "colloraries",
			},
	    },

     array => {
	       colloraries => {
			       class => "Idea",
			       companion => "basises",
			      },
	      },
    };

sub is_true {
    my $self = shift;

    my $am_true = $self->isa("Truth");
    for my $basis ($self->basises) {
	if ($basis->isa("Truth")) {
	    $am_true = 1;
	} elsif ($basis->isa("Knowledge")) {
	    $am_true = 1;
	} elsif ($basis->isa("Belief")) {
	    $am_true = $basis->is_true;
	}
	last unless $am_true;
    }
    if ($am_true) {
	Class::Tangram::import_schema("Knowledge");
	bless $self, "Knowledge";
    }

    return $am_true;
}

sub get_content {
    my $self = shift;
    return "Idea: ".$self->SUPER::get_content;
}

#Class::Tangram::import_schema(__PACKAGE__);

package Belief;
use base qw(Idea);
our $fields =
    {
     set => {
	     perpetrators => {
			      class => "Person",
			      companion => "preachings",
			     },
	    },

     ref => {
	     ideator => {
			 class => "Person",
			 companion => "beliefs",
			},
	    },
    };

#Class::Tangram::import_schema(__PACKAGE__);

sub get_content {
    my $self = shift;
    return "Belief: ".$self->SUPER::get_content;
}

package Truth;
use base qw(Idea);
our $fields =
    {
     string => [ qw(reason) ],  # no more accurate container type for
                                # fundamental truths unfortunately
    };

sub set_reason {
    my $self = shift;
    return $self->SUPER::set_reason("TRUTH: ".shift);
}

sub get_content {
    my $self = shift;
    return "Truth: ".$self->SUPER::get_content;
}

#Class::Tangram::import_schema(__PACKAGE__);

package Knowledge;
use base qw(Belief Truth);

our $fields =
    {
     ( $ENV{TEST_WARNINGS} ? (string => [ qw(reason) ])
       : () ),
    };

sub get_content {
    my $self = shift;
    return "Knowledge: ".$self->SUPER::get_content;
}

#Class::Tangram::import_schema(__PACKAGE__);

package Person;
use base qw(Class::Tangram);
our $fields =
    {
     string => [ qw(name) ],
     int => [ qw(is_enlightened) ],
     set => {
	     posessions => {
			    class => "Object",
			    companion => "owner",
			   },

	     preachings => {
			    class => "Belief",
			    companion => "perpetrators",
			   },
	     beliefs => {
			 class => "Belief",
			 companion => "perpetrators",
			 aggreg => 1,
			},
	     closed_to => { class => "Idea" },
	    },

     array => {
	       children => {
			    class => "Person",
			    companion => "parents",
			   },

	       parents => {
			   class => "Person",
			   companion => "children",
			   max_size => 2,
			  },
	      },

     hash => {
	      knowledge => {
			    class => "Knowledge",
			   },
	      },
    };

sub hear {
    my $self = shift;

    my $idea = shift;

    if ($self->is_enlightened) {
	if ($idea->is_true) {
	    $self->knowledge_insert($idea);
	}
    } else {
	if ($idea->isa("Belief") && $idea->perpetrators_size > 2
	    && ($idea->basises * $self->closed_to)->size == 0) {
	    $self->beliefs_insert($idea);
	} else {
	    $self->closed_to_insert($idea);
	}
    }

}

sub enlighten {
    my $self = shift;

    $self->posessions_clear();

    my $seen = Set::Object->new();

    while ($self->beliefs_size or $self->closed_to_size) {
	for my $belief ($self->beliefs, $self->closed_to) {
	    $seen->insert($belief);
	    $self->beliefs_remove($belief);
	    $self->closed_to_remove($belief);

	    if ($belief->is_true) {
		$self->knowledge_insert($belief);
	    } else {
		$self->beliefs_insert(grep { !$seen->includes($_) }
				      $belief->get_basises);
	    }
	}
    }

    #    $self->introspect while ($self != UNIVERSAL::Truth);
    $self->set_is_enlightened(1);
}

sub set_is_enlightened {
    my $self = shift;
    my $value = shift;
    $self->SUPER::set_is_enlightened($value + 41);

    return $value;
}

#Class::Tangram::import_schema(__PACKAGE__);

1;
