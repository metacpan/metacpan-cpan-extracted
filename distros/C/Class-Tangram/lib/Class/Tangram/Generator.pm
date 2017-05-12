package Class::Tangram::Generator;

use strict 'vars', 'subs';
use Set::Object qw(reftype refaddr blessed);
use Carp;
use Class::Tangram::Generator::Stub;

use IO::Handle;

use vars qw($VERSION $singleton $stub);
$VERSION = 0.02;

BEGIN {
    no warnings;
}

# to re-define at run-time, use:
#   *{Class::Tangram::Generator::DEBUG}=sub{1}
use constant DEBUG => 0;

sub debug_out {
    print STDERR __PACKAGE__."[$$]: @_\n";
}

$stub = $INC{'Class/Tangram/Generator/Stub.pm'};

sub DESTROY {
    my $self = shift;
    @INC = grep { defined and 
		      (!ref($_) or refaddr($_) ne refaddr($self)) }
	@INC;
}

sub new {

    my ($class, $self) = (shift, undef);

    unless ( ref $class ) {

        # build a new Class::Tangram::Generator
        $self = {};
        $self->{_schema} = shift or croak "Must supply schema!";

        # find out what base class they want to use:
        $self->{_base} = $self->{_schema}->{Base} ||
            shift(@_) || 'Class::Tangram';

	eval "require $self->{_base}";
	croak $@ if $@;

        # now extract the schema itself:
        $self->{_schema} = ($self->{_schema}->{classes} ||
			    $self->{_schema}->{Schema}->{classes} || {}
			   ) if reftype $self->{_schema} eq "HASH";

        # convert arrayref into a hashref if necessary:
        $self->{_schema} = { @{$self->{_schema}} }
            if ref $self->{_schema} eq "ARRAY";

	# create load-on-demand new() constructors
	#for my $class (grep {!ref} @{ $self->{_schema} }) {
	while (my $class = each %{ $self->{_schema} }) {
	    (DEBUG>1) && debug_out("Setting up generator for $class");
	    my $ref = "${class}::new";
	    *{ $ref } = sub {
		shift;
		(DEBUG) && do {
		    my ($pkg,$file,$line)=caller();
		    debug_out("tripped $class->new() ($pkg"
			      ." [$file:$line])");
		};
		undef *{ $class };   # avoid warnings
		$self->load_class($class);
		unless (blessed $_ and $_->isa(__PACKAGE__)) {
		    unshift @_, $self, $class;
		    #my $coderef = $self->can("new");
		    goto \&new;
		}
	    } unless defined &{ $ref };
	    *{ $ref } = \42;
	}

        # hash to list already handled classes
        $self->{_done} = {};

        bless $self, $class;

	unshift @INC, $self;
	$singleton = $self;

        return $self;

    } else {

        # setup and build a new $class object.
        ($self, $class) = ($class, shift);

        unless ($class) {
            croak "Must supply a classname or schema!";
        }

        # make a new C::T::Gen with new schema
        if(ref $class eq 'HASH') {
            return __PACKAGE__->new($class, @_);
        }

        exists $self->{_schema}->{$class} or croak "Unknown class: $class";
        $self->load_class($class) unless $self->{_done}->{$class};

	my $coderef = $class->can("new");
        unshift @_, $class;
	goto $coderef;
    }
}

sub load_class {

    my ($self, $class, $skip_use) = @_;

    exists $self->{_schema}->{$class} or croak "Unknown class: $class";
    unless($self->{_done}->{$class}) {

	(DEBUG) && debug_out("load_class $class");
        no strict 'refs';
	undef *{ $class."::new" };   # avoid warnings

        for my $base (@{$self->{_schema}->{$class}->{bases} || []}) {
            unless ($self->{_done}->{$base}) {
                $self->load_class($base) ;
            }
	    (DEBUG>1) && debug_out("pushing $base on to \@{ ${class}::ISA }");
            push @{"${class}::ISA"}, $base
		unless UNIVERSAL::isa($class, $base);
        }

	if (defined $skip_use) {
	    if ($skip_use) {
		#print STDERR "skip_use is $skip_use\n";
		(DEBUG) && debug_out("loading $class from $skip_use");
		open GEN, "<$skip_use" or die $!;
		my $code = join "", <GEN>;
		close GEN;
		eval $code;
		die $@ if $@;
		(DEBUG) && debug_out
		    ("symbols loaded: "
		     .join (" ", map {
			 (defined &{ $class."::$_" } ? "&" : "")
			.(defined ${ $class."::$_" } ? "\$" : "")
			.(defined @{ $class."::$_" } ? "\@" : "")
			.(defined %{ $class."::$_" } ? "\%" : "")
			    ."$_"
			} keys %{ $class."::" }));
	        (DEBUG) && debug_out
		    ("ISA is now: ".join(" ", @{ $class."::ISA" }));
	    }
	} else {
	    (my $filename = $class) =~ s{::}{/}g;
	    $filename .= ".pm";
	    if ( exists $INC{$filename} ) {
		(DEBUG) && debug_out("not loading $filename - already"
				     ." loaded");
	    } else {
		(DEBUG>1) && debug_out("loading class via `use $class'");
		eval "use $class";
		#warn "Got a warning: $@" if $@;
		croak __PACKAGE__.": auto-include $class failed; $@"
		    if ($@ && $@ !~ /^Can't locate \Q$filename.pm\E/);
		(DEBUG>1 && $@) && debug_out("no module for $class");
	    }
	}

	$self->post_load($class);
    }
}

sub post_load {
    my $self = shift;
    my $class = shift;

    push @{"${class}::ISA"}, $self->{_base};
    ${"${class}::schema"} = $self->{_schema}->{$class}
	unless defined ${"${class}::schema"};

    # import subroutine methods defined in schema, BEFORE
    # Class::Tangram defines accessor methods.
    while ( my ($name, $sub) =
	    each %{ $self->{_schema}->{$class}->{methods} || {} } ) {
	(DEBUG>1)
	    && debug_out("inserting method into ${class}::${name}");
	*{"${class}::${name}"} = $sub
	    unless defined &{"${class}::${name}"}
    }

    &{"$self->{_base}::import_schema"}($class);

    $self->{_done}->{$class}++;
}

sub Class::Tangram::Generator::INC {
    my $self = shift;
    my $fn = shift;

    (my $pkg = $fn) =~ s{/}{::}g;
    $pkg =~ s{.pm$}{};

    (DEBUG>1) && debug_out "saw include for $pkg";

    if ($self->{_schema}->{$pkg}) {

	my $file = "";
	for my $path (@INC) {
	    next if ref $path;
	    if (-f "$path/$fn") {
		$file = "$path/$fn";
		last;
	    }
	}

	$self->load_class($pkg, $file);

	# OK, this is getting into some pretty kooky magic, but
	# essentially GENERATOR_HANDLE returns the file intact, but
	# places a hoook on the end to finish up Class::Tangram

	#print STDERR "Generator: returning dummy to Perl\n";

	open DEVNULL, "<$stub" or die $!;
	return \*DEVNULL;

    } else {
	#print STDERR "Generator: not one of mine, ignoring\n";
	return undef;
    }
}

#BEGIN {
    #${__PACKAGE__."::INC"} = \&FOOINC;
#}

sub READLINE {
    my $self = shift;
    if (wantarray) {
	my @rv;
	my $val;
	while (defined ($val = $self->READLINE)) {
	    push @rv, $val;
	}
	return @rv;
    }

    if (!$self->{fh} && $self->{source}) {
	open GENERATOR_PM, "<$self->{source}" or die $!;
	$self->{source} = IO::Handle->new_from_fd("GENERATOR_PM", "r");
	*GENERATOR_PM = *GENERATOR_PM if 0;
    }

    my $retval;

 AGAIN:
    if (!$self->{state}) {

	# the package

	$self->{state} = "Package";
	$retval = "package $self->{package};\n";

    } elsif ($self->{state} =~ m/Package/ && $self->{fh}) {

	# their code

	my $line = $self->{fh}->getline;
	if ($line =~ m/^__END__/) {
	    $self->{state} = m/postamble/;
	    goto AGAIN;
	}
	if (defined($line)) {
	    $retval = $line;
	} else {
	    $self->{state} = "postamble";
	    goto AGAIN;
	}

    } elsif ($self->{state} =~ m/Package|postamble/) {

	# extra stuff normally done by load_class
	$self->{state} = "END";
	$retval =("\$Class::Tangram::Generator::singleton->post_load"
	       ."('$self->{package}');\n");

    } elsif ($self->{state} =~ m/END/) {

	$self->{fh}->close() if $self->{fh};
	$retval = undef;

    }

    return $retval;
}

sub GETC {
    my $self = shift;
    die "No getc!";
}

sub TIEHANDLE {
    my $class = shift;
    my $package = shift;
    return bless { package => $package }, $class;
}

sub SOURCE {
    my $self = shift;
    $self->{source} = shift;
}

sub READ {
    my $self = shift;
    die "No read!";
}


1;
__END__

=head1 NAME

Class::Tangram::Generator - Generate Class::Tangram-based objects at runtime. 

=head1 SYNOPSIS

  use Class::Tangram::Generator;

  my $schema = { ... }; # a Tangram schema definition hashref,
                        # including all classes
  my $gen = new Class::Tangram::Generator $schema;

  my $orange = $gen->new('Orange');
  $orange->juicyness(10); # $orange is a Class::Tangram-based Orange object

=head1 DESCRIPTION

The purpose of Class::Tangram::Generator is to facilitate the rapid
development of L<Class::Tangram|Class::Tangram>-based objects in the
L<Tangram|Tangram> framework.  Instead of having to write class
modules for all your L<Tangram|Tangram> objects, many of which only
inherit from L<Class::Tangram|Class::Tangram> for accessor and
constraint checking, you use Class::Tangram::Generator to dynamically
instantiate each class as necessary, at runtime.  This also alleviates
the long litany of 'use Orange; use Apple; ... ' statements in all of
your scripts.

=head1 METHODS

=over 4

=item new($schema, [$base]) [ Class method ]

=item new( { Schema => $schema, Base => $base } ) [ Class method ]

Initialize and return a new Class::Tangram::Generator object, using
the L<Tangram> schema hashref provided.  Newly generated objects will
have "Class::Tangram" added to their @ISA variable, unless an
alternative base class is specified in $base (that way you can
subclass L<Class::Tangram|Class::Tangram> and still use
Class::Tangram::Generator).

=item new($classname) [ Object method ]

Obtain a new object of the provided class.  Additional arguments are
passed to L<Class::Tangram|Class::Tangram>'s new function (for
attribute manipulation).  Any errors thrown by
L<Class::Tangram|Class::Tangram> will be propagated by
Class::Tangram::Generator.

=back

=head1 DISCUSSION

=head2 Tangram Schema Extensions

To provide custom methods for each class, add subroutine references to
the 'methods' key in the schema:

  Orange => {
    fields => { int => [ qw(juicyness ripeness) ] },
    methods => {
      squeeze => sub {
        my $self = shift;
        $self->juicyness($self->juicyness() - 1);
      },
      eviscerate => sub {
        my $self = shift;
        $self->juicyness(0);
      }
    }
  }

The subroutines will be automatically installed into the class's
namespace.

=head2 Interoperation with existing package files

If a .pm module file corresponding to the requested class can be found
by Perl (looking in the usual places defined by @INC, PERL5LIB, etc.),
it will be loaded before Class::Tangram::Generator has finished
dynamically generating the package.  This means that any schema and/or
methods found in the .pm module file will be overriden by those
specified in the schema given to Class::Tangram::Generator.  For
example, there may be an Orange.pm module file that looks like:

  package Orange;

  sub rehydrate { shift->juicyness(10) }

  1;

This allows the addition of more lengthy subroutines without filling
up the schema with lots of code.  But a "rehydrate" method specified
in the schema would entirely replace this subroutine (and it would not
be available via SUPER).

=head1 EXPORT

Class::Tangram::Generator does not have any methods to export.

=head1 HISTORY

=over 4

=item 0.01

Initial release

=back

=head1 AUTHOR

Aaron J Mackey E<lt>amackey@virginia.eduE<gt>

=head1 SEE ALSO

L<Class::Tangram>, L<Tangram>, L<Class::Object>, L<perl>.

=cut
