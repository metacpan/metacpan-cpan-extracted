use strict;
use warnings;
package App::Stopwatch;
$App::Stopwatch::VERSION = '1.2.0';
# ABSTRACT: simple console stopwatch


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Stopwatch - simple console stopwatch

=head1 VERSION

version 1.2.0

=head1 DESCRIPTION

Just a simple stopwatch. Run 'stopwatch' in your console and you will see
changing numbers:

    00:00:00
    00:00:01
    00:00:02
    ...

Use ctrl+c to stop stopwatch.

The max time the stopwatch can handle is 99 hours, 59 minutes and 59 seconds.
After that the stopwatch will stop.

This project uses Semantic Versioning standart for version numbers.
Please visit L<http://semver.org/> to find out all about this great thing.

=head1 SEE ALSO

=over

=item L<App::stopw>

=back

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
