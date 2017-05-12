# $Id: /local/CPAN/Apache-AxKit-Language-XSP-ObjectTaglib/lib/AxKit/XSP/ObjectTaglib/Demo/Prerequisite.pm 1508 2005-03-10T02:56:40.581331Z claco  $
package AxKit::XSP::ObjectTaglib::Demo::Prerequisite;
use strict;
use warnings;
use base 'AxKit::XSP::ObjectTaglib::Demo::Course';

1;
__END__

=head1 NAME

AxKit::XSP::ObjectTaglib::Demo::Prerequisite - A mock course prerequisite object

=head1 SYNOPSIS

    use AxKit::XSP::ObjectTaglib::Demo::Prerequisite;
    use strict;

    my $prerequisite = AxKit::XSP::ObjectTaglib::Demo::Prerequisite->new();
    print $prerequisite->name;

=head1 DESCRIPTION

This module represents a generic Prerequisite object returned by
C<AxKit::XSP::ObjectTaglib::Demo::Course-E<gt>prerequisites> for use within
the C<AxKit::XSP::ObjectTaglib::Demo> Taglib. A prerequisite object is simply a
course object in a different role. See L<AxKit::XSP::ObjectTaglib::Demo::Course>
for further documentation.

=head1 SEE ALSO

L<AxKit::XSP::ObjectTaglib::Demo>,
L<Apache::AxKit::Language::XSP::ObjectTaglib>,
L<AxKit::XSP::ObjectTaglib::Demo::Course>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
