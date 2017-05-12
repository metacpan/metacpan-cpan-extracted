# Data::Report::Plugin::Csv.pm -- CSV plugin for Data::Report
# RCS Info        : $Id: Csv.pm,v 1.9 2008/08/18 09:51:23 jv Exp $
# Author          : Johan Vromans
# Created On      : Thu Jan  5 18:47:37 2006
# Last Modified By: Johan Vromans
# Last Modified On: Mon Aug 18 11:45:48 2008
# Update Count    : 119
# Status          : Unknown, Use with caution!

package Data::Report::Plugin::Csv;

use strict;
use warnings;
use base qw(Data::Report::Base);

################ API ################

my $csv_implementation = 0;

sub start {
    my ($self, @args) = @_;
    $self->SUPER::start(@args);
    $self->set_separator(",") unless $self->get_separator;
    $self->_select_csv_method unless $csv_implementation;
    return;
}

sub finish {
    my ($self) = @_;
    $self->SUPER::finish();
}

sub add {
    my ($self, $data) = @_;

    my $style = delete($data->{_style});

    my $sep = $self->get_separator;

    $self->SUPER::add($data);

    return unless %$data;

    if ( $style and my $t = $self->_getstyle($style) ) {
	return if $t->{ignore};
    }

    $self->_checkhdr;

    my $line;

    $line = $self->_csv
      ( map {
	  $data->{$_->{name}} || ""
        }
	grep {
	    my $t = $self->_getstyle($style, $_->{name});
	    ! $t->{ignore};
	}
	@{$self->_get_fields}
      );
    $self->_print($line, "\n");
}

sub set_separator { $_[0]->{sep} = $_[1] }
sub get_separator { $_[0]->{sep} || "," }

################ Pseudo-Internal (used by Base class) ################

sub _std_heading {
    my ($self) = @_;
    my $sep = $self->get_separator;


    $self->_print($self->_csv
		  (map {
		       $_->{title}
		   }
		   grep {
		       my $t = $self->_getstyle("_head", $_->{name});
		       ! $t->{ignore};
		   }
		   @{$self->_get_fields}),
		  "\n");
}

################ Internal (used if no alternatives) ################

sub _csv_internal {
    join(shift->get_separator,
	 map {
	     # Quotes must be doubled.
	     s/"/""/g;
	     # Always quote (compatible with Text::CSV)
	     $_ = '"' . $_ . '"';
	     $_;
	 } @_);
}

sub _set_csv_method {
    my ($self, $class) = @_;
    no warnings qw(redefine);

    if ( $class && $class->isa("Text::CSV_XS") ) {

	# Use always_quote to be compatible with Text::CSV.
	# Use binary to deal with non-ASCII text.
	$csv_implementation = Text::CSV_XS->new
	  ({ sep_char => $self->get_separator,
	     always_quote => 1,
	     binary => 1,
	   });

	# Assign the method.
	*_csv = sub {
	    shift;
	    $csv_implementation->combine(@_);
	    $csv_implementation->string;
	};
	warn("# CSV plugin uses Text::CSV_XS $Text::CSV_XS::VERSION\n")
	  if $ENV{AUTOMATED_TESTING};
    }
    elsif ( $class && $class->isa("Text::CSV") ) {

	# With modern Text::CSV, it will use Text::CSV_XS if possible.
	# So this gotta be Text::CSV_PP...

	$csv_implementation = Text::CSV->new
	  ({ always_quote => 1,
	     binary => 1,
	   });

	# Assign the method.
	*_csv = sub {
	    shift;
	    $csv_implementation->combine(@_);
	    $csv_implementation->string;
	};
	warn("# CSV plugin uses Text::CSV $Text::CSV::VERSION, PP version $Text::CSV_PP::VERSION\n")
	  if $ENV{AUTOMATED_TESTING};
    }
    else {
	# Use our internal method.
	*_csv = \&_csv_internal;
	$csv_implementation = "Data::Report::Plugin::Csv::_csv_internal";
	warn("# CSV plugin uses built-in CSV packer\n")
	  if $ENV{AUTOMATED_TESTING};
    }

    return $csv_implementation;
}

sub _select_csv_method {
    my $self = shift;

    $csv_implementation = 0;
    eval {
	require Text::CSV_XS;
	$self->_set_csv_method(Text::CSV_XS::);
    };
    return $csv_implementation if $csv_implementation;

    if ( $self->get_separator eq "," ) {
      eval {
        require Text::CSV;
	$self->_set_csv_method(Text::CSV::);
      };
    }
    return $csv_implementation if $csv_implementation;

    # Use our internal method.
    $self->_set_csv_method();

    return $csv_implementation;
}

1;
