package Data::Dumper::GUI;

use 5.010001;
use strict;
use warnings;

BEGIN {
	$Data::Dumper::GUI::AUTHORITY = 'cpan:TOBYINK';
	$Data::Dumper::GUI::VERSION   = '0.006';
}

use parent qw( Exporter::Tiny Data::Dumper );
our @EXPORT = qw(Dumper);

sub Dump {
	my $class = shift;
	my ($items, $vars) = ref($class) ? ($class->{todump}, $class->{names}) : @_;
	
	require ddGUI::Window;
	my $window = 'ddGUI::Window'->new(
		title  => 'ddGUI',
		items  => $items,
		vars   => $vars,
	);
	$window->execute;
	
	return $class->Data::Dumper::Dump(@_) if defined wantarray;
}

sub Dumper {
	my @items = @_;
	
	require ddGUI::Window;
	my $window = 'ddGUI::Window'->new(
		title  => 'ddGUI',
		items  => \@items,
	);
	$window->execute;
	
	return Data::Dumper::Dumper(@items) if defined wantarray;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Data::Dumper::GUI - just what Data::Dumper needed... a GUI

=head1 SYNOPSIS

   use Data::Dumper::GUI;
   
   print Dumper(@variables);

=head1 DESCRIPTION

Data::Dumper::GUI is a little like L<Data::Dumper>, but as well as printing
out a dump of the variables it is passed, it also shows them in a pretty
GUI (graphical user interface) with a tree view, allowing you to expand and
collapse nodes, etc.

It has special secret sauce support for L<Moose> objects. (And for L<Moo>
objects too, if you make sure Moose is loaded before dumping them.)

=begin HTML

<p><img src="http://buzzword.org.uk/2013/ddGUI-eg1.png"
title="Dumper({ name => 'Foo Bar', list => [1..5] })"
width="644" height="417" alt="" /></p>

=end HTML

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Data-Dumper-GUI>.

=head1 SEE ALSO

L<Data::Dumper>, L<Prima>.

Shortcut: L<ddGUI>.

Internals: L<ddGUI::Window>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

