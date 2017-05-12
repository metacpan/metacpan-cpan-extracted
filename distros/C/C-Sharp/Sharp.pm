package C::Sharp;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use C::Sharp ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

C::Sharp - Parser and Lexer for C# Programming Language

=head1 SYNOPSIS

  use C::Sharp;
  use C::Sharp::Tokener;
  use C::Sharp::Parser;

=head1 DESCRIPTION

This module distribution contains (or will contain, when it's finished)
a tokeniser, parser and, hopefully, compiler for C#. C# is Microsoft's
new programming language for its .NET endeavour. It bears more than a
passing resemblence to Java. Like Java, it's relatively easy to
implement the basics of it but the power is in the runtime. 

Implementing C# in Perl is the first step to making Perl the preferred
.NET Common Language Runtime for Open Source Programmers. See also,
however, the Mono project at Ximian.com.

=head1 AUTHOR

Simon Cozens, simon@cpan.org

=head1 SEE ALSO

L<perl>.

=cut
