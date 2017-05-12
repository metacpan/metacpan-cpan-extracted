#!/usr/local/bin/perl

=head1 NAME

Class::Structured - provides a more structured class system for Perl

=head1 DESCRIPTION

Specifically, this function provides for variables with access specifiers
that will inherit properly, for constructors, and for abstract functions.

Abstract functions may be used on their own with no performance penalty.

Constructors and access specified variables each imply the use of the other -
and will incur a semi-significant performance penalty.

Also, note that when using all of the features it can cause problems to define
an AUTOLOAD function - so please don't.

=head1 HISTORY

=over 2

=item *

02/04/02 - Robby Walker - released - version 0.1

=item *

12/10/01 - Robby Walker - added private variable support, tested - version 0.003

=item *

12/06/01 - Robby Walker - adding abstract listing, checking and constructors - version 0.002

=item *

12/05/01 - Robby Walker - created the file, wrote abstract support - version 0.001

=back

=head1 METHODS

=over 4

=cut
#----------------------------------------------------------

package Class::Structured;

# MODULE METADATA
our $VERSION = 0.1;
our @ISA = qw(Exporter);

our @EXPORT = ();
our @EXPORT_OK = qw(declare_abstract implementation constructor default_constructor define_variables);
our %EXPORT_TAGS = (
						all => [qw(declare_abstract implementation constructor default_constructor define_variables)]
				   );

# PRAGMATIC DEPENDENCIES
use strict "vars";
use strict "subs";
use warnings;

# OUTSIDE DEPENDENCIES
use Carp;
use Set::Scalar;

# ========================================================================
#                                 METHODS
# ========================================================================

# ------------------------------------------------------------------------
#  Methods for abstract functions
# ------------------------------------------------------------------------

=item declare_abstract

Declares an abstract function in the current package.

=cut
sub declare_abstract {
	my $function_name = pop; # get last param as function name
	my $package = caller;

	# update the abstract list (keep it as a weird name so we don't have a collision with a real variable name)
	my $list_name = $package.'::'.'!structured!.abstracts';

	${ $list_name } = Set::Scalar->new() unless defined ${ $list_name };
	${ $list_name }->insert( $function_name );

	# declare the function
	*{ $package.'::'.$function_name } =
		sub {
			croak "$function_name in class $package is declared abstract, and cannot be called";
		 };
}

=item list_abstracts

Provides a list of all the abstracts left by a package for subclasses to implement.

=cut
sub list_abstracts {
	my $package = shift;

	# create a set to list all abstracts
	my $plist_name = $package.'::!structured!.abstracts';
	my $list;

	# add all locally declared abstracts - as definites
	if ( defined ${ $plist_name } ) {
		$list = ${ $plist_name }->clone;
	} else {
		$list = Set::Scalar->new;
	}

	# get a set for each parent class's abstracts
	my %parents;
	my $parent;
	my @parents = @{ $package.'::ISA' };
	foreach $parent ( @parents ) {
		my @abstracts = list_abstracts($parent);

		if ( @abstracts + 0 ) {
			$parents{$parent} = Set::Scalar->new(@abstracts);
		}
	}

	# this variable holds a list of functions we know to be implemented (i.e. not abstract)
	my $notlist = Set::Scalar->new;

	# now, step over each parent, adding abstracts when no other parent implements that function
	# note that this code makes no allowance for AUTOLOAD, which is why we state earlier that this
	# Perl feature should be avoided when using Class::Structured
	foreach $parent (keys %parents) {
		my $function;
		my @abstracts = $parents{$parent}->members;

		foreach $function (@abstracts) {
			# skip this if we already know the function to be abstract or implemented
			next if ($list->member($function) || $notlist->member($function));

			my $can;
			if ( defined *{ $package.'::'.$function }{CODE} ) {
				# does this package override it?
				$can = 1;
			} else {
				# does one of this package's parents override it
				my $other;
				$can = 0;
				foreach $other (@parents) {
					next if ($other eq $parent);

					# if the parent can run the function, and not just because it
					# declares it abstract, mark the function as implemented
					if ( !((exists $parents{$other}) && ($parents{$other}->member($function)))
						 && $other->can( $function ) )
					{
						$can = 1;
						last;
					}
				}
			}

			# add to the appropriate list
			($can ? $notlist : $list)->insert( $function );
		}
	}

	my @members = $list->members;
	return @members;
}

=item check_abstracts

When instantiating a class, make sure that it has declared all the necessary abstracts

=cut
sub check_abstracts {
	my $package = shift;

	# if we have no abstracts, we are OK
	return ! ( list_abstracts($package) + 0 );
}

# ------------------------------------------------------------------------
#  Constructor related functions
# ------------------------------------------------------------------------

=item constructor

Creates a new constructor.

=cut
sub constructor {
	my $name = shift;

	# load parameters, doing some aerobics to ensure their proper loading
	my $code = pop || sub {};
	my %supers = %{ pop || {} };

	# determine what package we are making a constructor for
	my $package = caller;
	if ( $package eq 'Class::Structured' ) {
		# if our caller is just 'default_constructor', find our true caller
		($package) = caller(1);
	}

	# mark ourself as the default constructor
	my $varname = $package.'::!structured!.default_constructor';
	${ $varname } = $name unless defined ${ $varname };

	# iterate through parent classes, using either the specified
	# constructor or the default constructor
	my $parent;
	my @parents = @{ $package.'::ISA' };
	foreach $parent ( @parents ) {
		# use the specified constructor, if there is one
		next if exists $supers{$parent};

		my $default = ${ $parent.'::!structured!.default_constructor' };
		$supers{$parent} = $default if defined $default;
	}

	# now, define the constructor function
	*{ $package.'::'.$name } =
		sub {
			my $type = shift;
			my $self;

			# figure out how we were called
			if ( ref($type) ) {
				my $reftype = ref($type);
	 			if ( $reftype eq $package ) {
					# called with an instance of our own type
					croak "Cloning is not yet supported by Class::Structured constructors - sorry!";
				} elsif ( $reftype->isa( $package ) ) {
					# called from below in the hierarchy
					$self = $type;
				}
			} else {
				# called as a constructor
				$self = construct( $type );
			}

			# call our parent constructors
			my $parent;
			foreach $parent ( keys %supers ) {
				&{ $parent.'::'.$supers{$parent} }( $self, @_ );
			}

			# call our own constructor
			$code->( $self, @_ ) if $code;

			$self;
		};
}

=item default_constructor

Creates a new constructor, and also marks it as the default.

=cut
sub default_constructor {
	my $package = caller;
	${ $package.'::!structured!.default_constructor' } = $_[0];
	constructor( @_ );
}

=item implementation

Prototyped sub used to generate syntax

=cut
sub implementation (&) {
	$_[0];
}

=item construct

Internal function used to set up a class variable.

=cut
sub construct {
	my $package = shift;

	# check the abstracts
	croak "Class $package has the following undefined abstracts and therefore cannot be created: ".
		   join ", ", list_abstracts( $package ) unless check_abstracts( $package );

	# add the public function, if necessary
	unless ( defined *{ $package.'::public' }{CODE} ) {
		*{ $package.'::public' } =
			sub : lvalue {
				$_[0]->{public}->{$_[1]};
			};
	}

	# bless the reference
	bless {}, $package;
}

# ------------------------------------------------------------------------
#  Private and Public Variable Functions
# ------------------------------------------------------------------------

=item define_variables

=cut
sub define_variables {
	my %params = @_;

	# determine what package we are in
	my $package = caller;

	# iterate over the variables, defining each
	my $var;
	foreach $var ( keys %params ) {
		# make sure the request is for a private variable
		unless ( lc($params{$var}) eq 'private' ) {
			carp "$var defined as unsupported type $params{$var}";
			next;
		}

		# add to the private variable list
		my $list_name = $package.'::!structured!.privates';

		${ $list_name } = Set::Scalar->new() unless defined ${ $list_name };
		${ $list_name }->insert( $var );

		# define the access function
		*{ $package.'::'.$var } =
			sub : lvalue {
				# get our self
				my $self = shift;

				# determine who called us
				my $caller;
				my $i = 0;
				do {
					($caller) = caller($i++);
				} while ($caller eq 'Class::Structured');

				my $list_name = $caller.'::!structured!.privates';
				unless ( ($caller eq $package) ||
				         ( $package->isa( $caller ) && defined($$list_name) && $$list_name->member($var) )) {
					# if the caller is not us our a superclass of us making a legitimate inquiry, die
					croak "Invalid attempt to access variable $var in class $package from $caller";
				}

				$self->{$caller}->{$var};
			};
	}

}

1;

__END__

=pod

=back

=head1 TODO

=over 4

=item *

Allow for parent constructor parameter specification.

=back

=head1 BUGS

Probably some

=head1 AUTHORS AND COPYRIGHT

Written by Robby Walker for Yet Another Perl Journal,
CD-Lab (www.cd-lab.com), and Point Writer (www.pointwriter.com).

All Rights Reserved.

=cut
