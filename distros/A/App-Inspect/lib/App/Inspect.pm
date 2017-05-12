package App::Inspect;
use strict;
use warnings;

our $VERSION = "0.002";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Inspect - Command line tool for inspecting installed modules

=head1 DESCRIPTION

Provides the 'inspect' command which takes module names as arguments. It will
print out the name of the module, the installed version, and where it was
loaded from.

=head1 USAGE

    $ inspect Moose Fake::Module Test::More Scalar::Util

Output:

    Moose        2.1604   is installed at /path/to/Moose.pm
    Fake::Module --       is not installed
    Test::More   1.001014 is installed at /path/to/Test/More.pm
    Scalar::Util 1.41     is installed at /path/to/Scalar/Util.pm
    No::Ver      --       is installed at /path/to/No/Ver.pm

The output will be in color, which cannot be shown in POD.

=head1 SOURCE

The source code repository for App-Inspect can be found at
F<http://github.com/exodist/App-Inspect/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt> and Dreamhost.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
