# $Id: /local/CPAN/Apache-AxKit-Language-XSP-ObjectTaglib/lib/AxKit/XSP/ObjectTaglib/Demo.pm 1508 2005-03-10T02:56:40.581331Z claco  $
package AxKit::XSP::ObjectTaglib::Demo;
use strict;
use warnings;
use base 'Apache::AxKit::Language::XSP::ObjectTaglib';
use vars qw($NS @specification);

$NS = 'http://today.icantfocus.com/CPAN/AxKit/XSP/ObjectTaglib/Demo';

@specification = (
    {
        tag     =>  'name',
        context =>  'resources',
        target  =>  'resource'
    }, {
        tag         =>  'resources',
        target      =>  'course',
        type        =>  'loop',
        iterator    =>  'resource'
    }, {
        tag     =>  'courses',
        type    =>  'special',
        start   =>  \&start_courses,
        end     =>  \&end_courses
    }, {
        tag     =>  'name',
        target  =>  'course'
    }, {
        tag     =>  'code',
        target  =>  'course'
    }, {
        tag     =>  'description',
        target  =>  'course',
        type    =>  'as_xml'
    }, {
        tag     =>  'summary',
        target  =>  'course',
        type    =>  'as_xml'
    }, {
        tag         =>  'presentations',
        target      =>  'course',
        type        =>  'loop',
        iterator    =>  'presentation'
    }, {
        tag     =>  'size',
        key     =>  'calculateSize',
        target  =>  'presentation',
        notnull =>  1
    }, {
        tag         =>  'prerequisites',
        target      =>  'course',
        type        =>  'loop',
        iterator    =>  'course'
    }
);

sub start_courses {
    my ($e, $tag, %attr) = @_;

    $e->manage_text(0);

    my $out = '
        use AxKit::XSP::ObjectTaglib::Demo::Courses;

        my @_xsp_axkit_xsp_objecttaglib_demo_courses =
            AxKit::XSP::ObjectTaglib::Demo::Courses->load;

        for my $_xsp_axkit_xsp_objecttaglib_demo_course
            (@_xsp_axkit_xsp_objecttaglib_demo_courses) {

    ';

    return $out;
};

sub end_courses {
    my ($e, $tag, %attr) = @_;

    $e->manage_text(0);

    my $out = '
        };
    ';

    return $out;
};

1;
__END__

=head1 NAME

AxKit::XSP::ObjectTaglib::Demo - A demo taglib using ObjectTaglib

=head1 SYNOPSIS

    #httpd.conf
    AxAddXSPTaglib AxKit::XSP::ObjectTaglib::Demo

    #XSP page
    <?xml version="1.0" encoding="UTF-8"?>
    <xsp:page xmlns:xsp="http://apache.org/xsp/core/v1"
    xmlns:demo="http://today.icantfocus.com/CPAN/AxKit/XSP/ObjectTaglib/Demo"
    >
      <body>
        <demo:courses>
          <course>
            <name><demo:name/></name>
            <code><demo:code/></code>
            <summary><demo:summary/></summary>
            <description><demo:description/></description>

              <demo:prerequisites>
                <prerequisite>
                 <name><demo:name/></name>
                 <code><demo:code/></code>
                </prerequisite>
              </demo:prerequisites>

              <demo:presentations>
                <presentation>
                  <size><demo:size/></size>
                </presentation>
              </demo:presentations>

              <demo:resources>
                <resource><demo:name/></resource>
              </demo:resources>

          </course>
        </demo:courses>
      </body>
    </xsp:page>

=head1 DESCRIPTION

This taglib demonstrates how to use the ObjectTaglib to map XSP tags to a set of
object oriented classes based on the original examples in
L<Apache::AxKit::Language::XSP::ObjectTaglib>.

=head1 METHODS

=head2 start_courses

When the topmost <demo:courses> start tag is encountered, the C<start_course>
method  is called. The most common implementations would probably use the
start/end methods to load and map the topmost tags to the root objects being
used. After that, the relationships in C<@specification> will be used to
generate the necessary code.

Let's break it down. First, we declare the sub and catch the XSP SAX model, the
tag, and the attributes passed from within the <demo:courses> tag:

    sub start_courses {
      my ($e, $tag, %attr) = @_;

Next, let's turn off the XSP text output managing for a moment. I don't know
why, but it had to be done to work. :-)

      $e->manage_text(0);

Now we'll create a new variable containing the code to insert into the XSP
innards. First we'll load the Courses module:

      my $out = '
        use AxKit::XSP::ObjectTaglib::Demo::Courses;

Now we'll create an array and load all of the Course objects into it:

      my @_xsp_axkit_xsp_objecttaglib_demo_courses =
        AxKit::XSP::ObjectTaglib::Demo::Courses->load;

Take a closer look at the variable name:
C<@_xsp_axkit_xsp_objecttaglib_demo_courses>. ObjectTaglib expects certain
variable names when it builds it's code for looping and calls methods on objects
using the method and objects names specified in C<@specification>.
C<axkit_xsp_objecttaglib_demo> is a safe version of the current taglib name
C<AxKit::XSP::ObjectTaglib::Demo>. C<courses>  is the root courses object
declared within the C<@specification> as:

    tag    => 'courses',
    type   => 'special',
    start  => \&start_courses,
    end    => \&end_courses

If we declared a C<count> tag with a C<target> of C<courses>

    tag    => 'count',
    target => 'courses'

C<target> is appended to the base variable name, and it's method C<count> is
called. That looks something like this
C<$_xsp_axkit_xsp_objecttaglib_demo_courses-E<gt>count>.

But I digress, back to our program. Next, we setup a looping mechanism wrapped
around all of our other tags:

      for my $_xsp_axkit_xsp_objecttaglib_demo_course
        (@_xsp_axkit_xsp_objecttaglib_demo_courses) {

      ';

We left of the second half of that loop closure. We'll add that when
C<end_courses> is called after everything else is processed.

      return $out;
    };

=head2 end_courses

When </demo:courses> is encountered, C<end_courses> is called. There isn't
anything too exciting here. Like before, we declare the sub and catch the tag
info:

    sub end_courses {
      my ($e, $tag, %attr) = @_;

Again, we'll turn of text management just because.

      $e->manage_text(0);

Lastly, we'll write out the main courses loop closure and return it.

      my $out = '
        };
      ';

      return $out;
    };

=head1 SEE ALSO

L<Apache::AxKit::Language::XSP::ObjectTaglib>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
