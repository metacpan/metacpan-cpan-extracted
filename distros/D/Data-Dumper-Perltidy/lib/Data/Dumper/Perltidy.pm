package Data::Dumper::Perltidy;

###############################################################################
#
# Data::Dumper::Perltidy - Dump and pretty print Perl data structures.
#
# Copyright 2009-2012, John McNamara.
#
# perltidy with standard settings.
#
# Documentation after __END__
#

use strict;
use warnings;

use Exporter;
use Data::Dumper ();
use Perl::Tidy;

our $VERSION = '0.03';
our @EXPORT  = ('Dumper');
our @ISA     = qw(Exporter);
our $ARGV    = '-npro -cab=1';


###############################################################################
#
# Dumper()
#
# Overridden version of Data::Dumper::Dumper() with perltidy formatting.
#
sub Dumper {

    my $tidied;
    my $dumper = Data::Dumper::Dumper(@_);

    perltidy( argv => $ARGV, source => \$dumper, destination => \$tidied );

    return $tidied;
}

1;

__END__

=pod

=head1 NAME

Data::Dumper::Perltidy - Dump and pretty print Perl data structures.

=head1 SYNOPSIS

To use C<Data::Dumper::Perltidy::Dumper()> to stringify and pretty print a Perl data structure:

    use Data::Dumper::Perltidy;

    ...

    print Dumper $some_data_structure;

=head1 DESCRIPTION

C<Data::Dumper::Perltidy> encapsulates both C<Data::Dumper> and C<Perl::Tidy> to provide a function that stringifies a Perl data structure in a pretty printed format. See the documentation for  L<Data::Dumper> and L<Perl::Tidy> for further information.

Data::Dumper can be used for, among other things, stringifying complex Perl data structures into a format that is suitable for printing and debugging.

Perl::Tidy can be used to pretty print Perl code in a consistent and configurable manner.

Data::Dumper also provides a certain level of pretty printing via the C<$Data::Dumper::Indent> variable but it isn't quite as nice as the Perl::Tidy output.

Let's look at an example to see how this module can be used. Say you have a complex data structure that you wish to inspect. You can use the C<Data::Dumper::Perltidy::Dumper()> function as follows (note that the syntax is the same as Data::Dumper):

    #!/usr/bin/perl -w

    use strict;
    use Data::Dumper::Perltidy;

    my $data = [{ title => 'This is a test header' },{ data_range =>
               [ 0, 0, 3, 9 ] },{ format     => 'bold' }];

    print Dumper $data;

This would print out:

    $VAR1 = [
        { 'title'      => 'This is a test header' },
        { 'data_range' => [ 0, 0, 3, 9 ] },
        { 'format'     => 'bold' }
    ];

By comparison the standard C<Data::Dumper::Dumper()> output would be:

    $VAR1 = [
              {
                'title' => 'This is a test header'
              },
              {
                'data_range' => [
                                  0,
                                  0,
                                  3,
                                  9
                                ]
              },
              {
                'format' => 'bold'
              }
            ];

Which isn't too bad but if you are used to Perl::Tidy and the L<perltidy> utility you may prefer the C<Data::Dumper::Perltidy::Dumper()> output.

=head1 FUNCTIONS

=head2 Dumper()

The C<Dumper()> function takes a list of perl structures and returns a stringified and pretty printed form of the values in the list. The values will be named C<$VARn> in the output, where C<n> is a numeric suffix.

You can modify the Perl::Tidy output by passing arguments via the C<$Data::Dumper::Perltidy::ARGV> configuration variable:

    $Data::Dumper::Perltidy::ARGV = '-nst -mbl=2 -pt=0 -nola';

See the L<Perl::Tidy> docs for more information on the available arguments. By default C<Data::Dumper::Perltidy> uses the argument C<-npro> to ignore any local C<.perltidyrc> configuration file.

The Data::Dumper C<$Data::Dumper::> configuration variables can also be used to influence the output where applicable. For further information see the L<Data::Dumper> documentation.

Note: unlike C<Data::Dumper::Dumper()> this function doesn't currently return a list of strings in a list context.

=head1 RATIONALE

I frequently found myself copying the output of C<Data::Dumper::Dumper()> into an editor so that I could run C<perltidy> on it. This module scratches that itch.

=head1 LIMITATIONS

This module doesn't attempt to implement all, or even most, of the functionality of C<Data::Dumper>.

=head1 AUTHOR

John McNamara C<< <jmcnamara@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jmcnamara/data-dumper-perltidy/issues> on Github.

=head1 ACKNOWLEDGEMENTS

The authors and maintainers of C<Data::Dumper> and C<Perl::Tidy>.

=head1 SEE ALSO

L<Data::Dump>

L<Data::Printer>, which also has a full list of alternatives.

=head1 COPYRIGHT & LICENSE

Copyright 2009-2012 John McNamara, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
