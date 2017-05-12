#!/usr/bin/env perl

# PODNAME: bagit.pl
# ABSTRACT: commandline interface to the Archive::BagIt library

use strict;
use warnings;

use Archive::BagIt::App;

Archive::BagIt::App->new_with_command->run;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

bagit.pl - commandline interface to the Archive::BagIt library

=head1 VERSION

version 0.049

=head1 NAME

bagit.pl - a command that lets you check your bags

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt::App/>.

=head1 SOURCE

The development version is on github at L<http://github.com/rjeschmi/Archive-BagIt-App>
and may be cloned from L<git://github.com/rjeschmi/Archive-BagIt-App.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/rjeschmi/Archive-BagIt-App/issues>.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Rob Schmidt and William Wueppelmann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
