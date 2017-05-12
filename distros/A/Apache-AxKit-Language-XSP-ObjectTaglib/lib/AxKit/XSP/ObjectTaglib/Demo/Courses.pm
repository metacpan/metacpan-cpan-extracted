# $Id: /local/CPAN/Apache-AxKit-Language-XSP-ObjectTaglib/lib/AxKit/XSP/ObjectTaglib/Demo/Courses.pm 1508 2005-03-10T02:56:40.581331Z claco  $
package AxKit::XSP::ObjectTaglib::Demo::Courses;
use strict;
use warnings;

sub load {
    my @courses;

    require AxKit::XSP::ObjectTaglib::Demo::Course;
    push @courses, AxKit::XSP::ObjectTaglib::Demo::Course->new({
        name => 'Course 1',
        code => 'c123',
        summary => '<p>Course 1 Summary</p>',
        description => '<p>Descrption</p>'
    });

    push @courses, AxKit::XSP::ObjectTaglib::Demo::Course->new({
        name => 'Course 2',
        code => 'c234',
        summary => '<p>Course 2 Summary</p>',
        description => '<p>Descrption</p>'
    });

    push @courses, AxKit::XSP::ObjectTaglib::Demo::Course->new({
        name => 'Course 3',
        code => 'c345',
        summary => '<p>Course 3 Summary</p>',
        description => '<p>Descrption</p>'
    });

    return (@courses);
};

1;
__END__

=head1 NAME

AxKit::XSP::ObjectTaglib::Demo::Courses - A mock course collection object

=head1 SYNOPSIS

    use AxKit::XSP::ObjectTaglib::Demo::Courses;
    use strict;
    use warnings;

    my @courses = AxKit::XSP::ObjectTaglib::Demo::Courses->load;
    for (@courses) {
        print $_->name;
    };

=head1 DESCRIPTION

This module represents a generic Courses object that loads a set of
C<AxKit::XSP::ObjectTaglib::Demo::Course> object for use within
the C<AxKit::XSP::ObjectTaglib::Demo> Taglib.

=head1 METHODS

=head2 load

Returns an array of C<AxKit::XSP::ObjectTaglib::Demo::Course> objects.

    my @courses = AxKit::XSP::ObjectTaglib::Demo::Courses->load;
    for (@courses) {
        print $_->name;
    };

=head1 SEE ALSO

L<AxKit::XSP::ObjectTaglib::Demo>,
L<Apache::AxKit::Language::XSP::ObjectTaglib>,
L<AxKit::XSP::ObjectTaglib::Demo::Course>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
