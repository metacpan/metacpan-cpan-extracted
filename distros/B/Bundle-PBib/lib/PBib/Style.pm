# --*-Perl-*--
# $Id: Style.pm 10 2004-11-02 22:14:09Z tandler $
#

package PBib::Style;
use strict;
use warnings;
#use English;

# for debug:
#use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 10 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
#use YYYY;
#use vars qw(@ISA);
#@ISA = qw(YYYY);

# used modules
use Carp;

# module variables
#use vars qw(mmmm);

#
#
# constructor
#
#

sub new {
#   'class' => style class to use
#   'style' => if no class is given, try to map the 'style' to a class name
	my $self = shift;
	my %args = @_;
#  foreach my $arg qw/XXX/ {
#    print STDERR "argument $arg missing in call to new $class\n"
#	unless exists $args{$arg};
#  }
	my $class = ref($self) || $self;
	$class = $class->findStyleClass(%args);
	my $new = bless \%args, $class;
	return $new;
}

sub findStyleClass {
	my $baseclass = shift;
	my %args = @_;
	my $class = $args{'class'};
	my $style = $args{'style'};
	#print "base=$baseclass, class=$class, style=$style\n";
	if( ! defined $class && defined $style ) {
		$class = ucfirst($style);
	}
	if( defined $class ) {
		unless( $class =~ /::/ ) {
			$class = "${baseclass}::$class";
		}
	} else {
		$class = $baseclass;
	}

	if( defined $class ) {
		#print ("use $class; \$${class}::VERSION\n");
		my $version = eval("use $class; \$${class}::VERSION");
		unless( defined $version ) {
			croak "Failed to open module $class\n";
		}
		unless( $class->isa($baseclass) ) {
			croak "Module $class is no subclass of $baseclass\n";
		}
		print STDERR "using $class version $version\n" if $args{'verbose'};
	}
	return $class;
}


#
#
# access methods
#
#

sub setConverter { my ($self, $conv) = @_; $self->{'converter'} = $conv; }
sub converter { my $self = shift; return $self->{'converter'}; }

sub refStyle { my $self = shift;
  my $refStyle = $self->converter()->refStyle();
  $refStyle->setRefID($self->refID());
  return $refStyle;
}
sub labelStyle { my $self = shift;
  my $labelStyle = $self->converter()->labelStyle();
  $labelStyle->setRefID($self->refID());
  return $labelStyle;
}
sub bibStyle { my $self = shift;
  my $bibStyle = $self->converter()->bibStyle();
  $bibStyle->setRefID($self->refID());
  return $bibStyle;
}
sub itemStyle { my $self = shift;
  my $itemStyle = $self->converter()->itemStyle();
  $itemStyle->setRefID($self->refID());
  return $itemStyle;
}

# options should be overwritten by subclasses to return correct option hash
sub options { my $self = shift; return $self->converter()->refOptions(); }
sub option { my ($self, $opt) = @_; return $self->options()->{$opt}; }

sub fieldOptions { my $self = shift; return $self->{'fieldOptions'} || {}; }
sub fieldOption { my ($self, $opt, $options) = @_;
  return ($options && $options->{$opt}) ||
  		 $self->fieldOptions()->{$opt} ||
  	     $self->option($opt);
}

sub inDoc { my $self = shift; return $self->converter()->inDoc(); }
sub outDoc { my $self = shift; return $self->converter()->outDoc(); }

sub logMessage { my $self = shift; return $self->converter()->logMessage(@_); }
sub traceMessage { my $self = shift; return $self->converter()->traceMessage(@_); }
sub warn { my $self = shift; return $self->converter()->warn(@_); }

sub setRefID { my ($self, $refID) = @_; $self->{'refID'} = $refID; }
sub refID { my $self = shift; return $self->{'refID'}; }



sub entries { my $self = shift; return $self->converter()->entries($self->refID()); }
sub entry { my ($self, $entry, $check) = @_;
  return $self->converter()->entry($self->refID(), $entry, $check);
}
sub entryExists { my ($self, $entry) = @_;
  return $self->converter()->entryExists($self->refID(), $entry);
}
sub entryNotEmpty { my ($self, $entry) = @_;
  return $self->converter()->entryNotEmpty($self->refID(), $entry);
}



#
#
# methods
#
#

sub text {
#
# return the replacement text
# the refField is unquoted (i.e. the standard char set),
#
  my ($self) = @_;
  croak "abstract method PBib::Style::text called on class " . ref($self);
}


#
# options
#

sub parseFieldOptions {
  my ($self, $optionString) = @_;
  my @optionArgs = split(/\s*:\s*/, $optionString);
  my %options = map( ($self->parseFieldOption($_)), @optionArgs);
  return \%options;
}
sub parseFieldOption {
  my ($self, $optionString) = @_;
  # trim string
  $optionString =~ s/^\s+//;
  $optionString =~ s/\s+$//;
#print "<$optionString>\n";
  my $name = $optionString;
  my $value = 1; # option turned on
  if( $name =~ s/\s*=\s*(.*)$// ) {
    $value = $1;
  }
#print "(option <$name> => <$value>) ";
  return ($name => $value);
}



1;

#
# $Log: Style.pm,v $
# Revision 1.4  2003/06/12 22:02:20  tandler
# support for logMessage() and warn()
#
# Revision 1.3  2003/01/14 11:07:38  ptandler
# new config, allow to select style class
#
# Revision 1.2  2002/08/08 08:20:59  Diss
# - parsing of options moved here
#
# Revision 1.1  2002/03/27 10:00:51  Diss
# new module structure, not yet included in LitRefs/LitUI (R2)
#
# Revision 1.2  2002/03/22 17:31:01  Diss
# small changes
#
# Revision 1.1  2002/03/18 11:15:50  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#