use 5.008;
use strict;
use warnings;

package Attribute::Benchmark;

use Attribute::Handlers ();
use Benchmark ();

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

my %cmp  = ();
my $iter = -3;
END { Benchmark::cmpthese($iter, \%cmp) if keys %cmp };

sub import
{
	shift;
	$iter = $_[0] if @_;
	strict->import;
	warnings->import(FATAL => 'all');
}

sub UNIVERSAL::Benchmark :ATTR()
{
	(my $name = $_[4] ? $_[4][0] : substr(*{$_[1]}, 1))
		=~ s/\Amain:://;
	$cmp{$name} = $_[2];
}

1;

__END__

=pod

=encoding utf-8

=for stopwords peasy squeezy benchmarking

=head1 NAME

Attribute::Benchmark - dead easy benchmarking

=head1 SYNOPSIS

   #!/usr/bin/env perl
   
   use Attribute::Benchmark;
   
   sub foo :Benchmark
   {
      1 for 0..10;
   }
   
   sub bar1 :Benchmark(bar)
   {
      1 for 0..1000;
   }

That's all folks!

=head1 DESCRIPTION

B<Attribute::Benchmark> provides a C<:Benchmark> attribute for subs.
Just import it into a script, write the subs you wish to compare, and
add the C<:Benchmark> attribute to each. Then run your script.

No need to C<use strict> or C<use warnings> - Attribute::Benchmark
does that for you.

By default Attribute::Benchmark uses C<< cmpthese(-3, \%subs) >> but
the iteration count can be changed in the import statement:

   use Attribute::Benchmark (100);

Don't forget the parentheses; otherwise Perl will assume you want
version 100.0 of Attribute::Benchmark!

Attribute::Benchmark will use the name of the sub as the label for the
benchmark results (e.g. "foo" above). But you can provide an explicit
label for a result like:

   sub bar1 :Benchmark(bar)

Easy, peasy, lemon squeezy.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Attribute-Benchmark>.

=head1 SEE ALSO

L<Benchmark>.

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

