package CGI::Application::Plugin::Authentication::Driver::Filter::uc;
$CGI::Application::Plugin::Authentication::Driver::Filter::uc::VERSION = '0.24';
use strict;
use warnings;

sub check {
    return ( uc $_[2] eq $_[3] ) ? 1 : 0;
}

sub filter {
    return uc $_[2];
}

1;
__END__


=head1 NAME

CGI::Application::Plugin::Authentication::Driver::Filter::uc - Uppercase Filter

=head1 METHODS


=head2 filter ( undef, $string )

This simply uppercases the string and returns it

 my $filtered = $class->filter(undef, 'foobar'); # FOOBAR


=head2 check ( undef, $string, $compare )

This will uppercase the string and compare it against the comparison string
and return true or false.

 if ($class->check(undef, 'foobar', 'FOOBAR')) {
     # they match
 }


=head1 SEE ALSO

L<CGI::Application::Plugin::Authentication::Driver>, perl(1)


=head1 AUTHOR

Cees Hek <ceeshek@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
