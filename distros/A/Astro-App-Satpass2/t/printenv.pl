use 5.008;

# use strict;
# use warnings;

my @names = @ARGV;
@names or @names = sort keys %ENV;

my $exit = 0;

foreach my $var ( @names ) {
    if ( defined $ENV{$var} ) {
	print "$var=$ENV{$var}\n";
    } else {
	$exit++;
    }
}

exit $exit;

__END__

=head1 TITLE

printenv.pl - Print environment variables

=head1 SYNOPSIS

 printenv.pl
 printenv.pl PATH

=head1 OPTIONS

None.

=head1 DETAILS

This Perl script mimics (more or less) the Unix C<printenv> command,
which prints the names and values of environment variables. You can
specify the names of the environment variables you want printed; if you
specify none, all are printed.

Unlike C<printenv> you can specify multiple names. Names that are not
defined will not be printed, and the exit status is the number of
undefined names.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
