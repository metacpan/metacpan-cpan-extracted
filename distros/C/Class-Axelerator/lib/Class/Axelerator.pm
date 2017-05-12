#
# $Id: Axelerator.pm,v 0.2 2009/02/15 02:25:03 dankogai Exp dankogai $
#
package Class::Axelerator;
use warnings;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.2 $ =~ /(\d+)/g;
use Filter::Simple;
our $DEBUG = 0;

FILTER_ONLY code => sub {
    s{
	 ->                       # arrow operator
	 ([A-Za-z_][0-9A-Za-z_]+) # method name
	 (\(?)                    # explicitly invoked?
 }{
     $2 ?  "->$1$2" # leave it alone
	 :  "->{$1}" # make it a simple hash deref
     }msegx;
    warn $_ if $DEBUG;
    $_;
};

1; # End of Class::Axelerator

__END__
=head1 NAME

Class::Axelerator - Evade OO taxes

=head1 VERSION

$Id: Axelerator.pm,v 0.2 2009/02/15 02:25:03 dankogai Exp dankogai $

=head1 SYNOPSIS

  my $obj = Klass->new(name => 'anon');
  use Class::Axelerator;
  $obj->name eq 'anon' or die;   # $obj->{name} ...
  $obj->name() eq 'anon' or die; # $obj->name() ...; no change
  $obj->pass = 'ymous';          # $obj->{pass} = ....
  no Class::Axelerator;

=head1 DESCRIPTION

Perl's object orientation (POO as follows) is powerful, flexible and
... expensive.  Since all methods are implemented as function calls,
even simple accessors are 2-4 times more costly than non OO approach.
Simply put,

  my $attr = $obj->attr;

is 2-4x costlier than

  my $attr = $obj->{attr};

This module I<axelerates> the code by replacing all occurance of C<<
->whatever >> with C<< ->{whatever} >>, while C<< ->whatever() >>
remains intact.

Since the blessed hash reference is the de-facto POO standard, this
accelerates most cases.  This is true for L<Class::Accessor> and its
friends and even L<Moose> and its family.

Whenever you want to call the method, just append C<()>.

It is recommended that you end the section to axelerate with C<< no
Class::Axelerator >>.  This module is B<NOT LEXICAL> and its effect
spans till the end of source without it.

=head1 BENCHMARK

Here is a result of simple benchmark on my MacBook Pro.  See t/benchmark.pl.

=over 2

=item Accessor

                 Rate     normal axelerated
  normal     1035642/s         --       -78%
  axelerated 4797439/s       363%         --

=item Mutator

                  Rate     normal axelerated
  normal      920425/s         --       -80%
  axelerated 4691781/s       410%         --

=item Lvalue Mutator

                  Rate     normal axelerated
  normal     1281574/s         --       -72%
  axelerated 4637948/s       262%         --

=back

=head1 Axelerate?

It comes naturally since this module accelerates accessors/mutators by
axing encapslulation.

=head1 EXPORT

None.  This is a source filter module.

=head1 AUTHOR

Dan Kogai, C<< <dankogai at dan.co.jp> >>

=head1 BUGS

Tax evasion is considered felony in most countries and territories :)

Even in the Programming Republic of Perl, it is considered a bad practice.

Please report any bugs or feature requests to C<bug-class-axelerator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Axelerator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Axelerator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Axelerator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-Axelerator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-Axelerator>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-Axelerator/>

=back

=head1 ACKNOWLEDGEMENTS

Proof of concept L<http://blog.livedoor.jp/dankogai/archives/51077786.html>


=head1 COPYRIGHT & LICENSE

Copyright 2009 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
