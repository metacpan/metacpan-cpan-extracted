package App::ErrorCalculator;

use strict;
use warnings;

our $VERSION = '1.02';

use Math::Symbolic ();
use Math::SymbolicX::Error;
use Math::SymbolicX::NoSimplification;
use Spreadsheet::Read ();

use Number::WithError;
use Glib qw/TRUE FALSE/;
use Gtk2 '-init';
use Gtk2::Ex::Dialogs ( destroy_with_parent => TRUE,
                         modal => TRUE,
                         no_separator => FALSE );

sub _delete_event
{
	# If you return FALSE in the "delete_event" signal handler,
	# GTK will emit the "destroy" signal. Returning TRUE means
	# you don't want the window to be destroyed.
	# This is useful for popping up 'are you sure you want to quit?'
	# type dialogs.
	#print "delete event occurred\n";

	# Change TRUE to FALSE and the main window will be destroyed with
	# a "delete_event".
	return FALSE;
}

my $window = Gtk2::Window->new('toplevel');
$window->set_border_width(10);

# When the window is given the "delete_event" signal (this is given
# by the window manager, usually by the "close" option, or on the
# titlebar), we ask it to call the delete_event () functio
# as defined above. No data is passed to the callback function.
$window->signal_connect(delete_event => \&_delete_event);

# Here we connect the "destroy" event to a signal handler.
# This event occurs when we call Gtk2::Widget::destroy on the window,
# or if we return FALSE in the "delete_event" callback. Perl supports
# anonymous subs, so we can use one of them for one line callbacks.
$window->signal_connect(destroy => sub { Gtk2->main_quit; });

my $table = Gtk2::Table->new(5, 4, FALSE);
$window->add($table);

# Labels
my $l = Gtk2::Label->new('Function:');
$table->attach_defaults(
	$l, 0, 1, # left/right
	1, 2, # top/bottom
);
$l->show;
$l = Gtk2::Label->new('Input:');
$table->attach_defaults(
	$l, 0, 1, # left/right
	2, 3, # top/bottom
);
$l->show;
$l = Gtk2::Label->new('Output:');
$table->attach_defaults(
	$l,	0, 1, # left/right
	3, 4, # top/bottom
);
$l->show;

# feedback labels
my $funclabel = Gtk2::Label->new('Valid Function  ');
$table->attach_defaults(
	$funclabel, 3, 4, # left/right
	1, 2, # top/bottom
);
$funclabel->show;
my $inlabel = Gtk2::Label->new('Invalid Data File');
$table->attach_defaults(
	$inlabel, 3, 4, # left/right
	2, 3, # top/bottom
);
$inlabel->show;
my $outlabel = Gtk2::Label->new('Invalid Output File');
$table->attach_defaults(
	$outlabel, 3, 4, # left/right
	3, 4, # top/bottom
);
$outlabel->show;

# Entries
my $funcentry = Gtk2::Entry->new;
$table->attach_defaults(
	$funcentry,	1, 2, # left/right
	1, 2, # top/bottom
);
$funcentry->signal_connect(
	activate => \&_validate_func,
);
$funcentry->signal_connect(
	changed  => \&_validate_func,
);
$funcentry->set_text('f = a * x^2');
$funcentry->show;

my $inentry = Gtk2::Entry->new;
$table->attach_defaults(
	$inentry,	1, 2, # left/right
	2, 3, # top/bottom
);
$inentry->signal_connect(
	activate => \&_read_file,
);
$inentry->show;

my $outentry = Gtk2::Entry->new;
$table->attach_defaults(
	$outentry,	1, 2, # left/right
	3, 4, # top/bottom
);
$outentry->show;

# buttons
my $valbutton = Gtk2::Button->new('Validate');
$table->attach_defaults(
	$valbutton,	2, 3, # left/right
	1, 2, # top/bottom
);
$valbutton->signal_connect(	clicked => \&_validate_func );
$valbutton->show;

my $inbutton = Gtk2::Button->new('Select File');
$table->attach_defaults(
	$inbutton,	2, 3, # left/right
	2, 3, # top/bottom
);
$inbutton->signal_connect(
	clicked => sub {
		_run_fileselection(
			'Select input file', $inentry,
			sub {
				_read_file();
			},
		);
	},
);
$inbutton->show;

my $outbutton = Gtk2::Button->new('Select File');
$table->attach_defaults(
	$outbutton,	2, 3, # left/right
	3, 4, # top/bottom
);
$outbutton->signal_connect(
	clicked => sub {
		my $t = $outentry->get_text;
		_run_fileselection(
			'Select output file', $outentry,
			sub {
				my $text = shift;
				if ( -e $text ) {
					my $r = ask Gtk2::Ex::Dialogs::Question( "File exists. Overwrite?" );
					$outentry->set_text($t), return if not $r;
					$outlabel->set_text('Valid Output File  ');
				}
				else {
					$outlabel->set_text('Valid Output File  ');
				}
			}
		);
   	},
);
$outbutton->show;

my $runbutton = Gtk2::Button->new('Run Calculation');
$table->attach_defaults(
	$runbutton,	0, 4, # left/right
	4, 5, # top/bottom
);
$runbutton->signal_connect(	clicked => \&_run_calculation );
$runbutton->show;

$table->set_col_spacings(10);
$table->set_row_spacings(10);

$table->show;

sub run {
	$window->show;
	Gtk2->main;
}

sub _run_fileselection {
	my $title = shift;
	my $entry = shift;
	my $callback = shift;
	my $fsel = Gtk2::FileSelection->new($title);
	$fsel->set_filename($entry->get_text);
	$fsel->ok_button->signal_connect(
		"clicked",
		sub {
			$entry->set_text($fsel->get_filename);
			$callback->($fsel->get_filename) if defined $callback;
			$fsel->destroy
		},
		$fsel
	);
	$fsel->cancel_button->signal_connect(
		"clicked",
		sub { $fsel->destroy },
		$fsel
	);
	$fsel->show;

}

sub _parse_function {
	my $f = shift;
	my ($name, $body) = split /\s*=\s*/, $f, 2;
	return() if (not defined $name or $name =~ /^\s*$/ or not defined $body);
	my $nobj;
	eval { $nobj = Math::Symbolic::Variable->new($name) };
	return() if not defined $nobj or not defined $nobj->name or $@;
	my $func;
	eval { $func = $Math::Symbolic::Parser->parse($body) };
	return() if not defined $func or $@;
	my $var = $nobj->name;
	# function must not be recursive
	return() if grep {$var eq $_} $func->signature;
	$func = $func->apply_derivatives()->simplify();
	return($nobj, $func);
}

my ($name, $body);
sub _validate_func {
	my $f = $funcentry->get_text;
	($name, $body) = _parse_function($f);
	if (not defined $name) {
		$funclabel->set_text('Invalid Function');
	}
	else {
		$funclabel->set_text('Valid Function  ');
	}
	
}

my $data;
sub _read_file {
	my $file = $inentry->get_text();
	if (not -e $file) {
		$inlabel->set_text('Invalid Data File');
		$data = undef;
	}
	my $ref = Spreadsheet::Read::ReadData($file);
	if (not defined $ref) {
		$inlabel->set_text('Invalid Data File');
		$data = undef;
	}
	else {
		$inlabel->set_text('Valid Data File  ');
		$data = $ref;
	}
}

sub _run_calculation {
	my $func = $body;

	if (not $funclabel->get_text() eq 'Valid Function  ') {
		new_and_run
		Gtk2::Ex::Dialogs::ErrorMsg( text => "You should give me a valid formula first." );	
		return();
	}
	
	if (not $inlabel->get_text() eq 'Valid Data File  ') {
		new_and_run
		Gtk2::Ex::Dialogs::ErrorMsg( text => "You need to select a valid input data file first." );	
		return();
	}
	
	if (not $outlabel->get_text() eq 'Valid Output File  ') {
		new_and_run
		Gtk2::Ex::Dialogs::ErrorMsg( text => "You need to select a valid output data file first." );	
		return();
	}
	
	my $sym = $name->name;
	my $csv = $data->[1];
	my $cell = $csv->{cell};
	my @vars = $func->signature;
	my %vars = map {($_ => undef)} @vars;

	my %errors;
	
	foreach my $col (1..$csv->{maxcol}) {
		my $name = $cell->[$col][1];
		if ($name =~ /^([a-zA-Z]\w*)_(\d+)$/) {
			# looks like an error
			my $var = $1;
			my $id = $2;
			if (exists $vars{$var}) {
				$errors{$var}[$id] = $col;
			}
			next;
		}
		next if not exists $vars{$name};
		next if defined $vars{$name};
		$vars{$name} = $col;
	}

	my @undefined = grep {not defined $vars{$_}} keys %vars;
	if (@undefined) {
		new_and_run
		Gtk2::Ex::Dialogs::ErrorMsg( text => "The data file does not include columns for the following variables:\n" . join("\n", sort @undefined) );	
		return();
	}

	my $maxrow = 0;
	foreach my $col (values %vars) {
		my $this = @{$cell->[$col]};
		$maxrow = $this if $this > $maxrow;
	}

	$maxrow--;
	
	if ($maxrow < 2) {
		new_and_run
		Gtk2::Ex::Dialogs::ErrorMsg( text => "The data file does not have any data!" );	
		return();
	}

	my $maxerr = 0;
	foreach my $k (keys %errors) {
		$maxerr = @{$errors{$k}} if $maxerr < @{$errors{$k}};
	}
	$maxerr--;
	
	my @out;
	foreach my $i (2..$maxrow) {
		my %v =
			map {
				my $n = $_;
				my $v = $cell->[$vars{$_}][$i]; 
				$v = 0 if not defined $v;
				$v =~ s/,/./g;
				my @e =
					map {s/,/./g}
					map {defined($_) ? $_ : 0}
					map {
						my $col = $errors{$n}[$_];
						defined $col ? $cell->[$col][$i] : 0
					}
					1..$maxerr;
				($n => Number::WithError->new_big($v, @e))
			}
			keys %vars;
		my $value = $body->value(%v);
		$value = Number::WithError->new_big($value) if not ref($value) =~ /^Number::WithError/;
		
		push @out, $value;
	}

	if (open(my $fh, '>', $outentry->get_text())) {
		print $fh '"' . join('", "', $sym, map {$sym.'_'.$_} 1..$maxerr), '"', "\n";
		
		foreach my $row (0..$#out) {
			my $v = shift @out;
			my $num = $v->number;
			my @e = @{$v->error()};
			print $fh '"' . join('", "', $num, @e), '"', "\n";
		}
	}
	else {
		new_and_run
		Gtk2::Ex::Dialogs::ErrorMsg( text => "Could not open output file for writing: $!" );	
		return();
	}
}


1;

__END__

=head1 NAME

App::ErrorCalculator - Calculations with Gaussian Error Propagation

=head1 SYNOPSIS

  # You can use the 'errorcalculator' script instead.
  
  require App::ErrorCalculator;
  App::ErrorCalculator->run();

  # Using the script:
  # errorcalculator

=head1 DESCRIPTION

C<errorcalculator> and its implementing Perl module
C<App::ErrorCalculator> is a Gtk2 tool that lets you do
calculations with automatic error propagation.

Start the script, enter a function into the function entry
field, select an input file, select an output file and hit
the I<Run Calculation> button to have all data in the input
field processed according to the function and written to the
output file.

Functions should consist of a function name followed by an
equals sign and a function body. All identifiers
(both the function name and all variables in the function body)
should start with a letter. They may contain letters, numbers and
underscores.

The function body may contain any number of constants, variables,
operators, functions and parenthesis.
The exact syntax can be obtained by reading
the manual page for L<Math::Symbolic::Parser>. Arithmetic
operators (C<+ - * / ^>) are supported. The caret indicates
exponentiation. Trigonometric, inverse
trigonometric and hyperbolic functions are implemented
(C<sin cos tan cot asin acos atan acot sinh cosh asinh acoth>).
C<log> indicates a natural logarithm.

Additionally, you may include derivatives in the formula which
will be evaluated (analytically) for you. The syntax for this is:
C<partial_derivative(a * x + b, x)>. (Would evaluate to C<a>.)

In order to allow for errors in constants, the program uses the
L<Math::SymbolicX::Error> parser extension: use the
C<error(1 +/- 0.2)> function to include constants with
associated uncertainties in your formulas.

The input files may be of any format recognized by the
L<Spreadsheet::Read> module. That means: Excel sheets,
OpenOffice (1.0) spreadsheets, CSV (comma separated values)
text files, etc.

The program reads tabular data from the spreadsheet file.
It expects each column to contain the data for one variable
in the formula.

  a,   b,   c
  1,   2,   3
  4,   5,   6
  7,   8,   9

This would assign C<1> to the variable C<a>, C<2> to C<b>
and C<3> to C<c> and then evaluate the formula with those
values. The result would be written to the first data line
of the output file. Then, the data in the next row will be
used and so on. If a column is missing data, it is assumed
to be zero.

Since this is about errors, you can declare any number of
errors to the numbers as demonstrated below:

  a,    a_1,  a_2,  b,    b_1
  1,    0.2,  0.1,  2,    0.3
  4,    0.3,  0.3,  5,    0.6
  7,    0.4,  0,1,  8,    0.9

Apart from dropping C<c> for brevity, this example input
adds columns for the errors of C<a> and C<b>. C<a>
has two errors: C<a_1> and C<a_2>. C<b> only has one
error C<b_1> which corresponds to the error C<a_1>.
When calculating, C<a> will be used as C<1 +/- 0.2 +/- 0.1>
in the first calculation and C<b> as C<2 +/- 0.3 +/- 0>.
The error propagation is implemented using
L<Number::WithError> so that's where you go for details.

The output file will be a CSV file similar to the input examples
above.

=head1 EXAMPLES

=head2 Sample input file

  "a", "a_1", "a_2", "x", "x_1", "x_2"
  1,   "0.1", "1.1", 10,  "0.1", "1.1"
  2,   "0.2", "1.2", 11,  "0.2", "1.2"
  3,   "0.3", "1.3", 12,  "0.3", "1.3"
  4,   "0.4", "1.4", 13,  "0.4", "1.4"
  5,   "0.5", "1.5", 14,  "0.5", "1.5"

=head2 Example function

  f = a * x^2

=head2 Example output file

  "f",       "f_1",     "f_2"
  "1.0e+02", "1.0e+02", "1.0e+02"
  "2.4e+02", "1.3e+02", "1.3e+02"
  "4.3e+02", "1.6e+02", "1.6e+02"
  "6.8e+02", "2.0e+02", "2.0e+02"
  "9.8e+02", "2.4e+02", "2.4e+02"

=head1 SUBROUTINES

=head2 run

Just load the module with C<require App::ErrorCalculator> and then run

  App::ErrorCalculator->run;

=head1 SEE ALSO

New versions of this module can be found on http://steffen-mueller.net or CPAN.

L<Math::Symbolic> implements the formula parser, compiler and evaluator.
(See also L<Math::Symbolic::Parser> and L<Math::Symbolic::Compiler>.)

L<Number::WithError> does the actual error propagation.

L<Gtk2> offers the GUI.

=head1 AUTHOR

Steffen Mueller, E<lt>particles-module at steffen-mueller dot net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
