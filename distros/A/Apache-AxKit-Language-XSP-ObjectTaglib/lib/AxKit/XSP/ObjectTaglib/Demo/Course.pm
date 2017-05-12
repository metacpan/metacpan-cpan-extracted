# $Id: /local/CPAN/Apache-AxKit-Language-XSP-ObjectTaglib/lib/AxKit/XSP/ObjectTaglib/Demo/Course.pm 1508 2005-03-10T02:56:40.581331Z claco  $
package AxKit::XSP::ObjectTaglib::Demo::Course;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $attr = shift || {};
    my $self = bless $attr, $class;

    return $self;
};

sub name {
    return shift->{name};
};

sub code {
    return shift->{code};
};

sub summary {
    return shift->{summary};
};

sub description {
    return shift->{description};
};

sub prerequisites {
    my @prerequisites;

    require AxKit::XSP::ObjectTaglib::Demo::Prerequisite;
    push @prerequisites, AxKit::XSP::ObjectTaglib::Demo::Prerequisite->new({
        name => 'Prerequisite 1 for ' . shift->{name},
        code => 'p123'
    });

    return @prerequisites;
};

sub presentations {
    my @presentations;

    require AxKit::XSP::ObjectTaglib::Demo::Presentation;
    push @presentations, AxKit::XSP::ObjectTaglib::Demo::Presentation->new({
        size => shift->{code}
    });

    return @presentations;
};

sub resources {
    my @resources;

    require AxKit::XSP::ObjectTaglib::Demo::Resource;
    push @resources, AxKit::XSP::ObjectTaglib::Demo::Resource->new({
        name => 'Resource ' . shift->{code}
    });

    return @resources;
};

1;
__END__

=head1 NAME

AxKit::XSP::ObjectTaglib::Demo::Course - A mock course object

=head1 SYNOPSIS

    use AxKit::XSP::ObjectTaglib::Demo::Course;
    use strict;
    use warnings;

    my $course = AxKit::XSP::ObjectTaglib::Demo::Course->new();
    print $course->name;

=head1 DESCRIPTION

This module represents a generic Course object returned by
C<AxKit::XSP::ObjectTaglib::Demo::Courses-E<gt>load> for use within
the C<AxKit::XSP::ObjectTaglib::Demo> Taglib.

=head1 METHODS

=head2 new( [\%attr] )

Returns a new C<AxKit::XSP::ObjectTaglib::Demo::Course> object. You can
also pass in an optional hashref to be blessed into the new object.

    my $course = AxKit::XSP::ObjectTaglib::Demo::Course->new({
        name => 'Course 100: Easy Course',
        code => 100
    });

=head2 name

Returns the name of the given C<AxKit::XSP::ObjectTaglib::Demo::Course>
object.

    print $course->name;

=head2 code

Returns the course code of the given C<AxKit::XSP::ObjectTaglib::Demo::Course>
object.

    print $course->code;

=head2 summary

Returns the summary description of the given
C<AxKit::XSP::ObjectTaglib::Demo::Course> object.

    print $course->summary;

=head2 description

Returns the description of the given
C<AxKit::XSP::ObjectTaglib::Demo::Course> object.

    print $course->description;

=head2 prerequisites

Returns an array of prerequisite objects of the given
C<AxKit::XSP::ObjectTaglib::Demo::Course> object.

    my @prerequisites = $course->prerequisites;
    for (@preequisites) {
        print $_->name;
        print $_->code;
    };

See L<AxKit::XSP::ObjectTaglib::Demo::Prerequisite> for more information about
the objects returned.

=head2 presentations

Returns an array of presentation objects of the given
C<AxKit::XSP::ObjectTaglib::Demo::Course> object.

    my @presentations = $course->presentations;
    for (@presentations) {
        print $_->name;
        print $_->calculatedSize;
    };

See L<AxKit::XSP::ObjectTaglib::Demo::Presentation> for more information about
the objects returned.

=head2 resources

Returns an array of resource objects of the given
C<AxKit::XSP::ObjectTaglib::Demo::Course> object.

    my @resources = $course->resources;
    for (@resources) {
        print $_->name;
    };

See L<AxKit::XSP::ObjectTaglib::Demo::Resource> for more information about
the objects returned.

=head1 SEE ALSO

L<AxKit::XSP::ObjectTaglib::Demo>,
L<Apache::AxKit::Language::XSP::ObjectTaglib>,
L<AxKit::XSP::ObjectTaglib::Demo::Courses>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
