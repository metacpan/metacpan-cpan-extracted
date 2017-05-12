#!/usr/local/bin/perl -wc

=head1 NAME

VisSection - handler to manipulate sections in VisRep.pl.

=head1 SYNOPSIS

	use Data::Reporter::VisSection;

	$section = new Data::Reporter::VisSection();
	$section->configure(Name => 'mydetail',
			Lines => ('line 1', 'line 2', 'line 3'),
			Code => "print 'this is the detail section\n';",
			Size => 3,
			Break_field => 0,
			Width => 20,
			Only_code => 0);
	my $name = $section->name();
	my $size = $section->size();
	my $break_field = $section->break_field();
	my @lines = $section->lines();
	my $code = $section->code();
	my $only_code = $section->only_code();
	$section->append("print 'this is the last line of code\n');
	$section->insert("print 'this is the first line of code\n'");

	open OUT, "out.txt";
	$section->generate(\*OUT);

=head1 DESCRIPTION

=item new();

Creates a new section handler

=item $section->configure(option => value)

=over 4

valid options are:

=item 

Name			Section name

=item 

Lines		array of Lines to be printed in this section

=item

Code			Code to execute before printing the data section

=item

Size			Number of lines in the section

=item

Break_field	Field number in which the break applies

=item

Width		Numbers of columns in section

=item

Only_code		Indicator for a no-lines section

=back

=item $section->name()

Returns the section's name

=item $section->size()

Returns the section's size

=item $section->break_field()

Returns the section's break_field

=item $section->lines()

Returns an array with the section`s lines

=item $section->code()

Returns the section's Code

=item $section->only_code()

Returns the only_code indicator

=item $section->generate(\*OUT)

Print perl code in OUT handler. This code is the section's information

=head1 NOTES

A section is a part of a report. For example the header section, 
the title section, etc. Each section has two parts:

=over 4

=item Code part

This contains perl code, which is executed before printing the data lines of
the section. This is useful because you can prepare the data to print in the 
report or acumulate totals. The special variable @field, is used to print
data in lines.

=item Lines part

Here are the lines to print. The lines are printed using the RepFormat module, 
there are special fields in printing the lines:

=item @Fn

This field generates code to print $field[n]

=item @Pn

This field generates code to print $report->page(n). page is a special feature
from Reporter module

=item @Tn

This field generates code to print $report->time(n). time is a special feature
from Reporter module

=item @Dn

This field generates code to print $report->date(n). date is a special feature
from Reporter module

=cut

package Data::Reporter::VisSection;
use Carp;
use strict;

sub new(%) {
	my $class = shift;
	my $self={};
	bless $self, $class;
	$self->_initialize();
	if (@_ > 0) {
		my %param = @_;
		$self->_getparam(%param);
	}
	$self;
}

sub _initialize() {
	my $self = shift;
	my @lines = ();
	$self->{NAME} = "";
	$self->{LINES} = \@lines;
	$self->{CODE} = "";
	$self->{SIZE}= 0;
	$self->{BREAK_FIELD}=0;
	$self->{WIDTH} = 0;
	$self->{ONLY_CODE} = 0;
}

sub _getparam(%){
	my $self=shift;
	my %param = @_;
	foreach my $key (keys %param) {
		if ($key eq "Name") {
			$self->{NAME} = $param{$key};
		} elsif ($key eq "Lines") {
			$self->{LINES} = $param{$key};
		} elsif ($key eq "Code") {
			$self->{CODE} = $param{$key};
		} elsif ($key eq "Size") {
			$self->_resize($param{$key});
		} elsif ($key eq "Break_field") {
			$self->{BREAK_FIELD} = $param{$key};
		} elsif ($key eq "Width") {
			$self->{WIDTH} = $param{$key};
		} elsif ($key eq "Only_code") {
			$self->{ONLY_CODE} = $param{$key};
		} else {
			croak "Parameter $key invalid (Name, Lines, Code, ".
								"Size, Break_field, Width, Only_code)";
		}
	}
}

sub configure(%) {
	my $self = shift;
	$self->_getparam(@_);
}

sub name($) {
	my $self = shift;
	$self->{NAME};
}

sub size($) {
	my $self = shift;
	$self->{SIZE};
}

sub break_field($) {
	my $self = shift;
	$self->{BREAK_FIELD};
}

sub lines($) {
	my $self = shift;
	my @lines = @{$self->{LINES}};
	@lines;
}

sub _resize($$) {
	my $self = shift;
	my $newsize = shift;
	my $size = $self->{SIZE};
	my $cont;

	if ($size < $newsize) {
		for ($cont = $size; $cont < $newsize; $cont++) {
			push @{$self->{LINES}}, "";
		}
	} elsif ($size < $newsize) {
		for ($cont = $size; $cont > $newsize; $cont--) {
			pop @{$self->{LINES}};
		}
	}
	$self->{SIZE} = $newsize;
}

sub insert($$) {
	my $self = shift;
	my $ntext= shift;
	$self->{CODE} = $ntext.$self->{CODE};
}

sub append($$) {
	my $self = shift;
	my $ntext= shift;
	$self->{CODE} .= $ntext;
}

sub code($) {
	my $self = shift;
	$self->{CODE};
}

sub only_code($) {
	my $self = shift;
	$self->{ONLY_CODE};
}

sub _special_field($$) {
	my $self=shift;
	my $field = shift;

	if ($field =~ /F(\d+)/) {
		$field = "\$field[$1]";
	} elsif($field =~ /P(\d)/) {
		$field = "\"PAG : \".\$report->page($1)";
	} elsif($field =~ /T(\d)/) {
		$field = "\$report->time($1)";
	} elsif($field =~ /D(\d)/) {
		$field = "\$report->date($1)";
	}
	return $field;
}

sub generate($$) {
	my $self = shift;
	my $file = shift;

	print $file "\n#SECTION: $self->{NAME} $self->{BREAK_FIELD}\n";
	my @code_lines = split(/\n/, $self->{CODE});
	my $rows = scalar @code_lines;
	my $cont;
	for($cont = $rows-1; $cont >= 0; $cont--) {
		last if ($code_lines[$cont] ne "");
		pop @code_lines;
	}
	$self->{CODE} = join("\n", @code_lines);

	if ($self->{ONLY_CODE}) {
		print $file "#CODE AREA\n";
		print $file "$self->{CODE}\n";
		print $file "#END\n";
		return;
	}
	print $file "sub $self->{NAME}(\$\$\$\$) { \n";
	print $file "\tmy (\$report, \$sheet, \$rep_actline, \$rep_lastline)".
				" = \@_;\n";
	print $file "\tmy \@field=();\n";
	print $file "#CODE AREA\n";
	print $file "$self->{CODE}\n";
	print $file "#OUTPUT AREA\n";

	for ($cont = 0; $cont < $self->{SIZE}; $cont++) {
		my $line = $self->{LINES}->[$cont];
		my %fields = ();
		chomp($line);
		print $file "#ORIG LINE $line\n";
		$line = substr($line, 0, $self->{WIDTH})
										if (length($line) > $self->{WIDTH});
		my $ind = 0;
		my $len = length($line);
		while ($line ne "") {
			if ($line =~ /(^\s+)(.*)/) {
				my $spaces = $1;
				$line = $2;
				$ind += length($spaces);
			} elsif ($line =~ /^\@([^\s]+)(.*)/) {
				my $field = $1;
				$line = $2;
				$fields{$ind} = $self->_special_field($field);
				$ind += length($field)+1;
			} elsif ($line =~ /(^[^\@]+)(\@*.*)/) {
				my $text = $1;
				$line = $2;
				$fields{$ind} = "\"$text\"";
				my $indant=$ind;
				$ind += length($text);
				$fields{$indant} =~ s/\s+$//;
			}
		}
		foreach my $key (keys %fields) {
			print $file "\t\$sheet->MVPrint($key, $cont,$fields{$key});\n";
		}
	}
	print $file "}\n";
	print $file "#END\n";
}

1;
