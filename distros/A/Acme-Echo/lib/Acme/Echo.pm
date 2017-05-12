package Acme::Echo;

use warnings;
use strict;

our $VERSION = '0.02';

use Filter::Simple;
use PPI;
our %modes;
our $line_fmt = "%s\n";
our $src_fmt = "==>\n%s\n<==\n";
our $fh = *STDOUT;
sub import {
  my $pkg = shift;
  while ( $_ = shift @_ ){
    if( /^before|after|lines$/ ){
	$modes{ lc $_ } = undef;
    }elsif( $_ eq 'line_fmt' ){
	$line_fmt = shift;
    }elsif( $_ eq 'src_fmt' ){
	$src_fmt = shift;
    }elsif( $_ eq 'fh' ){
	$fh = shift;
    }else{
	die "bad parameter '$_' to Acme::Echo";
    }
  }
}
FILTER {
  my $src = $_;
  my $print = 'print $Acme::Echo::fh';
  $_ = exists $modes{lines}
	?
	  do {
	    my $s = "";
	    my $d = PPI::Document->new(\$src);
	    foreach my $node ( @{ $d->find('PPI::Statement') } ){
		next unless $node->parent == $d;
		if( $node->class eq 'PPI::Statement::Compound' ){
		  $s .= "$print q{COMPOUND STATEMENTS NOT SUPPORTED IN lines MODE\n};\n" . $node->content;
		}elsif( $node->class eq 'PPI::Statement::Sub' ){
		  $s .= "$print q{SUB STATEMENTS NOT SUPPORTED IN lines MODE\n};\n" . $node->content;
		}else{
		  $s .= sprintf "$print q{$line_fmt}; %s\n", $node->content, $node->content;
		}
	    }
	    $s;
	  }
	: $src ;
  my $block = sprintf "\n;$print q{$src_fmt};\n", $src;
  $_ =      $block . $_ if exists $modes{before};
  $_ = $_ . $block      if exists $modes{after};
};
1;
__END__

=pod

=head1 NAME

Acme::Echo - Display perl statements before, after, and/or during execution

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

	use Acme::Echo qw/lines/;
	print "hello world\n";
	print "blah\n";
	no Acme::Echo;
	print "foo\n";

	my $srclog;
	BEGIN{ open $srclog, '>', "srclog.txt" or die; }
	use Acme::Echo 'after', src_fmt=>"This code was just executed==>\n%s\n<==\n", fh=>$srclog;
	...

=head1 IMPORT PARAMETERS

One or more of before/after/lines may be specified.  At least one shoud be specified (pointless otherwise). The others are optional.

=over 2

=item before

Print out the entire code source before execution.

=item after

Print out the entire code source after execution.

=item lines

Print out each line of source right before its execution (note Limitations below).

=item line_fmt

The I<sprintf> format used for printing lines in I<lines> mode. Defaults to "%s\n".

=item src_fmt

The I<sprintf> format used for printing the whole source in I<before>/I<after> modes. Defaults to "==>\n%s\n<==\n".

=item fh

A filehandle to print to.  Defaults to *STDOUT.

=back

=head1 BUGS & LIMITATIONS

=over 2

=item *

The I<lines> mode doesn't currently support compound or sub statements.

=back

=head1 TODO

=over 2

=item *

line numbering for the blocks for I<before> and I<after> modes

=item *

More thorough test suite, including code that uses loops, subs, if/else ladders, closures, etc.

=item *

make the PPI loading dynamic; and make PPI an optional prereq (And SKIP in tests); So that can use I<before> and I<after> modes w/o having PPI installed.

=back

=head1 AUTHOR

David Westbrook (davidrw), C<< <dwestbrook at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-echo at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Echo>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I'm also available by email or via '/msg davidrw' on L<http://perlmonks.org>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Echo

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Echo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Echo>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Echo>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Echo>

=back

=head1 ACKNOWLEDGEMENTS

Samy_rio for his post (L<http://perlmonks.org/?node_id=568087>) that inspired this.

=head1 COPYRIGHT & LICENSE

Copyright 2006 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

