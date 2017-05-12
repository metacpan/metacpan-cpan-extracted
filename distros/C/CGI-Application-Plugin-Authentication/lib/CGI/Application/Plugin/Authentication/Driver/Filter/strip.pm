package CGI::Application::Plugin::Authentication::Driver::Filter::strip;
$CGI::Application::Plugin::Authentication::Driver::Filter::strip::VERSION = '0.21';
use strict;
use warnings;

sub check {
    return ( _strip( $_[2] ) eq $_[3] ) ? 1 : 0;
}

sub filter {
    return _strip( $_[2] );
}

sub _strip {
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

1;
__END__


=head1 NAME

CGI::Application::Plugin::Authentication::Driver::Filter::strip - Filter that strips whitespace from the beginning and end of the string

=head1 METHODS


=head2 filter ( undef, $string )

This strips whitespace from the beginning and end of the string and returns the result

 my $filtered = $class->filter(undef, "  foobar\t\n"); # 'foobar'


=head2 check ( undef, $string, $compare )

This will lowercase the string and compare it against the comparison string
and return true or false.

 if ($class->check(undef, "  foobar\t\n", 'foobar')) {
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
