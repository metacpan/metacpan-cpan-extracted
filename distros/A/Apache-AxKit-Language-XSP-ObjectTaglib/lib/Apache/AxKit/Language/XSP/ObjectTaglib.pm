# $Id: /local/CPAN/Apache-AxKit-Language-XSP-ObjectTaglib/lib/Apache/AxKit/Language/XSP/ObjectTaglib.pm 1518 2008-03-08T22:17:31.628142Z claco  $
package Apache::AxKit::Language::XSP::ObjectTaglib;
use strict;
use warnings;
use vars qw/@ISA $VERSION @EXPORT/;
use AxKit;
use Apache::AxKit::Language::XSP;
$VERSION = "0.09000";
use Exporter;
@ISA = ('Apache::AxKit::Language::XSP', 'Exporter');

@EXPORT = qw(parse_start parse_end);

my %stacks;

sub parse_char {
    my ($e, $text) = @_;

    $text =~ s/^\s*//;
    $text =~ s/\s*$//;

    return '' unless $text;

    $text =~ s/\|/\\\|/g;
    return ". q|$text|";
};

sub parse_start {
    my ($e, $tag, %attr) = @_;

    AxKit::Debug(5, "ObjectTaglib: parse_start called on tag '$tag'");
    $tag =~ s/-/_/g;
    AxKit::Debug(5, "ObjectTaglib: tag name cleaned to '$tag'");


    my $ns = $e->{Current_Element}->{NamespaceURI};
    AxKit::Debug(5, "ObjectTaglib: current namespace is '$ns'");

    my $where = $Apache::AxKit::Language::XSP::tag_lib{ $ns };
    AxKit::Debug(5, "ObjectTaglib: current taglib is '$where'");

    push @{$stacks{$where}}, $tag;
    my ($safe_where, @specification);
    {
        no strict 'refs'; @specification = @{"${where}::specification"};
        die "No specification found in $where!" unless @specification;
    }

    ($safe_where = lc $where) =~ s/::/_/g;
    AxKit::Debug(5, "ObjectTaglib: taglib cleaned to '$safe_where'");

    if ($AxKit::Cfg->DebugLevel() > 0) {
        for (keys %attr) {
            AxKit::Debug(5, "ObjectTaglib: tag attribute $_=" . $attr{$_});
        };
    };

    s/\|//g for %attr;

    AxKit::Debug(5, 'ObjectTaglib: looping through specification');
    for (@specification) {
        AxKit::Debug(5, "ObjectTaglib: specification item '" . $_->{tag} . "'");
        if ($tag ne $_->{tag}) {
            AxKit::Debug(5,
            "ObjectTaglib: skipping tag specification '$tag'!=" . $_->{tag});
            next;
        };

        if (defined $_->{context} ) {
            AxKit::Debug(5, "ObjectTaglib: context '" . $_->{context} . "'");
            next unless $_->{context} eq $stacks{$where}->[-2];
        }

        if ($_->{type} eq 'special') {
            AxKit::Debug(5, "ObjectTaglib: calling start method '" .
                $_->{start} . "'");
            return $_->{start}->($e, $tag, %attr)
        };

        if ($_->{type} eq "loop") {
            $e->manage_text(0);
            my $iterator = $_->{iterator};
            my $target = $_->{target};
            return <<EOF
for my \$_xsp_${safe_where}_$iterator (\$_xsp_${safe_where}_${target}->$tag) {
EOF
        }
        $e->start_expr($tag) unless $_->{type} eq "as_xml";
        return '';
    }
    die "Unknown start tag $tag\n";
}

sub parse_end {
    my ($e, $tag, %attr) = @_;

    AxKit::Debug(5, "ObjectTaglib: parse_end called on tag '$tag'");
    $tag =~ s/-/_/g;
    AxKit::Debug(5, "ObjectTaglib: tag name cleaned to '$tag'");

    my $where = $AxKit::XSP::TaglibPkg;
    AxKit::Debug(5, "ObjectTaglib: current namespace is '$where'");

    pop @{$stacks{$where}};
    my ($safe_where, @specification);
    { no strict 'refs'; @specification = @{"${where}::specification"}; }

    ($safe_where = lc $where) =~ s/::/_/g;
    AxKit::Debug(5, "ObjectTaglib: taglib cleaned to '$safe_where'");

    if ($AxKit::Cfg->DebugLevel() > 0) {
        for (keys %attr) {
            AxKit::Debug(5, "ObjectTaglib: tag attribute $_=" . $attr{$_});
        };
    };

    for (@specification) {
        next unless $tag eq $_->{tag};
        if (defined $_->{context} ) {
            next unless $_->{context} eq $stacks{$where}->[-1];
        }

        return $_->{end}->($e, $tag, %attr)
            if $_->{type} eq 'special';

        my $target = $_->{target};

        if ($_->{type} eq "loop") {
            $e->manage_text(0);
            return "}";
        } elsif ($_->{type} eq "as_xml") {
            $e->manage_text(0);
            my $util_include_expr = {
                        Name => 'include-expr',
                        NamespaceURI => $AxKit::XSP::Util::NS,
                        Attributes => [],
                    };
            my $xsp_expr = {
                        Name => 'expr',
                        NamespaceURI => $AxKit::XSP::Core::NS,
                        Attributes => [],
                    };
            $e->start_element($util_include_expr);
            $e->start_element($xsp_expr);
            $e->append_to_script(<<EOF);
    '<some-obvious-grouping-tag>'.\$_xsp_${safe_where}_$target->$tag().
    '</some-obvious-grouping-tag>'
EOF
            $e->end_element($xsp_expr);
            $e->end_element($util_include_expr);
            return ''
        }

        $e->append_to_script(
            "(\$_xsp_${safe_where}_$target->" . ($_->{key} || $tag) . "()" .
            ($_->{notnull} && '|| \'<p></p>\'').");"
        );

        $e->end_expr();
        return "";
    }
    die "Unknown end tag $tag\n";
}
1;
__END__

=head1 NAME

Apache::AxKit::Language::XSP::ObjectTaglib - Helper for OO Taglibs

=head1 SYNOPSIS

    package MyTaglib;
    use strict;
    use warnings;
    use base 'Apache::AxKit::Language::XSP::ObjectTaglib';
    use vars qw(@specification);

    @specification = (
        ...
    );

=head1 DESCRIPTION

This is an AxKit tag library helper for easily wrapping object-oriented
classes into XSP tags. The interface to the class is through a
specification which your taglib provides as a package variable. You may
wrap single or multiple classes within the same taglib, iterate over
several objects, and call methods on a given object.

Here is a sample specification:

    @specification = (
      {
        tag     => 'name',
        context => 'resources',
        target  => 'resource'
      }, {
        tag      => 'resources',
        target   => 'course',
        type     => 'loop',
        iterator => 'resource'
      }, {
        tag   => 'courses',
        type  => 'special',
        start => \&start_courses,
        end   => \&end_courses
      }, {
        tag    => 'name',
        target => 'course'
      }, {
        tag    => 'code',
        target => 'course'
      }, {
        tag    => 'description',
        target => 'course',
        type   => 'as_xml'
      }, {
        tag    => 'summary',
        target => 'course',
        type   => 'as_xml'
      }, {
        tag      => 'presentations',
        target   => 'course',
        type     => 'loop',
        iterator => 'presentation'
      }, {
        tag    => 'size',
        key    => 'calculateSize',
        target => 'presentation',
        notnull => 1
      }, {
        tag      => 'prerequisites',
        target   => 'course',
        type     => 'loop',
        iterator => 'course'
      }
    );

This is the specification used in the sample C<AxKit::XSP::ObjectTaglib::Demo>
Taglib so all variable names used in the examples below start with
C<_xsp_axkit_xsp_objecttaglib_demo_>. Here's what this means:

      {
        tag     => 'name',
        context => 'resources',
        target  => 'resource'
      }, {

Define a tag called C<name> which occurs inside of another tag called
C<resources>. (We'll define a top-level C<name> tag for C<courses> later, so
this context-sensitive override has to come first.) When this tag is seen,
the method C<name> will be called on the variable
C<@_xsp_axkit_xsp_objecttaglib_demo_resource>.

      }, {
        tag      => 'resources',
        target   => 'course',
        type     => 'loop',
        iterator => 'resource'
      }, {

Define a tag called C<resources> that will loop through each C<resource>
returned by the method C<resources> on the C<course> object. When combined with
the first defined tag, the code generated looks something like this:

    for $_xsp_axkit_xsp_objecttaglib_demo_resource
      ($_xsp_axkit_xsp_objecttaglib_demo_course->resources) {
      $_xsp_axkit_xsp_objecttaglib_demo_course->name;
    };

Now, on the main looping tag C<courses>.

      }, {
        tag   => 'courses',
        type  => 'special',
        start => \&start_courses,
        end   => \&end_courses
      }, {

C<courses> will be the main entry point for our tag library, and as such
needs to do some special things to set itself up. Hence, it uses a
C<special> type, and provides its own handlers to handle the start and
end tag events. These handlers will be responsible for setting up
C<$_xsp_axkit_xsp_objecttaglib_demo_courses>, used in the following tags, and
looping over the possible courses, setting
C<$_xsp_axkit_xsp_objecttaglib_demo_>course appropriately.

      }, {
        tag    => 'name',
        target => 'course'
      }, {
        tag    => 'code',
        target => 'course'
      }, {
        tag    => 'description',
        target => 'course',
        type   => 'as_xml'
      }, {
        tag    => 'summary',
        target => 'course',
        type   => 'as_xml'
      }, {

When we see the C<name> tag, we call the C<name> method on
each C<$_xsp_axkit_xsp_objecttaglib_demo_course> object within the loop.
Similarly, the C<code> tag calls the C<code> method on the same object.

The C<description> and C<summary> tags call the C<description> and C<summary>
methods on each course object with the loop, this time making sure that the
result is valid XML instead of plain text. (This is because we store the
description in the database as XML, and don't want it escaped before AxKit
throws it onto the page.)

      }, {
        tag      => 'presentations',
        target   => 'course',
        type     => 'loop',
        iterator => 'presentation'
      }, {

Each course object has a C<presentations> method, which is wrapped by the
C<presentations> tag. This method returns a list of objects representing
the presentations of a course; the C<presentations> tag sets up a loop,
with C<$_xsp_axkit_xsp_objecttaglib_demo_presentation> as the iterator. Hence,
inside of a C<presentations> tag, C<< target => "presentation" >> will cause
the method to be called on each presentation object in turn.

      }, {
        tag    => 'size',
        key    => 'calculateSize',
        target => 'presentation',
        notnull => 1
      }, {

Like the course C<name> tag, we'll declare a C<size> tag for the C<presentation>
object.

      }, {
        tag      => 'prerequisites',
        target   => 'course',
        type     => 'loop',
        iterator => 'course'
      }

This is slightly dirty. We want a C<prerequisites> tag to refer to other
course objects, namely, the courses which are required for admission to
the current course. ie:

    <demo:prerequisites>
      <prerequisite>
        <name><demo:name/></name>
        <code><demo:code/></code>
      </prerequisite>
    </demo:prerequisites>

So when we see the C<prerequisites> tag, we call the C<prerequisites>
method on our C<course> target, C<$_xsp_axkit_xsp_coursebooking_course>.
This returns a list of new prerequisite objects, which we loop over.
(C<type => "loop">)

Our loop iterator will be C<$_xsp_axkit_xsp_objecttaglib_demo_course>
itself, so the other tags will work properly on the iterated courses.

Some code is worth a thousand words. The generated perl will look
something like this:

    for my $_xsp_axkit_xsp_objecttaglib_demo_course
        ($_xsp_axkit_xsp_objecttaglib_demo_course->prerequisites) {
        ... $_xsp_axkit_xsp_objecttaglib_demo_course->name ...
    }

Because we want to use the C<name> tag within the prerequisites B<and> the
courses, we chose the slightly dirty method above. We could also have declared a
new tag called C<reqname> and chosen a cleaner iterator like so

      }, {
        tag      => 'prerequisites',
        target   => 'course',
        type     => 'loop',
        iterator => 'prerequisite'
      }, {
        tag      => 'reqname',
        target   => 'prerequisite'
      }

and then use slightly different XSP like this

    <demo:prerequisites>
      <prerequisite>
        <name><demo:reqname/></name>
        <code><demo:code/></code>
      </prerequisite>
    </demo:prerequisites>

Here's another quick example:

    our @specification = (
        { tag => "person", type => "special",
                            start => \&start_person, end => \&end_person },
        { tag => "name", key => "cn", target => 'person'},
        ...
    );

This comes from a wrapper around LDAP. As before, the C<person> tag at
the top level has two subroutines to set up the C<person> target.
(which in this case will be C<$_xsp_axkit_xsp_ldap_person>) When a
C<name> tag is seen inside of the C<person> tag, a method is called on
that target. This time, we use C<key> to say that the method name is
actually C<cn>, rather than C<name>. Hence the following XSP:

    <b:person dn="foo">
       <b:name/>
    </b:person>

generates something like this:

    {
    my $_xsp_axkit_xsp_ldap_person = somehow_get_ldap_object(dn => "foo");

       ...
       $_xsp_axkit_xsp_ldap_person->cn();
       ...
    }

All clear?

=head1 SEE ALSO

L<AxKit::XSP::ObjectTaglib::Demo>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/

=head1 AUTHOR EMERITUS

The original version was created by Simon Cozens.