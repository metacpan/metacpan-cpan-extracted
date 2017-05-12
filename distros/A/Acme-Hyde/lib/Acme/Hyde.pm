package Acme::Hyde;

use warnings;
use strict;
use POSIX;

use base qw/Exporter/;
our @EXPORT = qw/to_hyde from_hyde/;
our $VERSION = 0.04;

sub to_hyde {
    my $cm = shift;
    my $hyde = sprintf("%.2f",$cm/156);
    return $hyde;
}

sub from_hyde {
    my $hyde = shift;
    my $cm = ceil($hyde*156);
    return $cm;
}

1;
__END__

=head1 NAME

Acme::Hyde - Hyde Calculator

=head1 SYNOPSIS

    use Acme::Hyde;
    to_hyde(180); # => 1.15
    from_hyde(1.15); # => 180

=head1 DESCRIPTION

Hyde Calculator

=head1 BUGS AND LIMITATIONS


=head1 SEE ALSO

http://kumaniki.blog76.fc2.com/blog-entry-161.html

=head1 AUTHOR

Tetsunari Nozaki C<< <nozzzzz __at__ gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Tetsunari Nozaki C<< <nozzzzz __at__ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms of Perl itself. See L<perlartistic>.
