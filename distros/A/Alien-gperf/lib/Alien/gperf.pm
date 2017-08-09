use strict;
use warnings;
package Alien::gperf;

# ABSTRACT: Perl distribution for GNU gperf
our $VERSION = '0.005'; # VERSION

use parent 'Alien::Base';

=pod

=encoding utf8

=head1 NAME

Alien::gperf - Perl distribution for GNU gperf

=head1 USAGE

    use Alien::gperf;
    use Env qw( @PATH );

    unshift @PATH, Alien::gperf->bin_dir;
    system gperf, '--version';

=head1 DESCRIPTION
    
GNU gperf is a perfect hash function generator. For a given list of strings, it produces a hash function and hash table, in form of C or C++ code, for looking up a value depending on the input string. The hash function is perfect, which means that the hash table has no collisions, and the hash table lookup needs a single string comparison only.

=cut

1;
__END__


=head1 GIT REPOSITORY

L<http://github.com/athreef/Alien-gperf>

=head1 SEE ALSO

L<GNU gperf|https://www.gnu.org/software/gperf/>

L<Alien>


=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
