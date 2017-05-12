package CGI::Builder::TT2;

$VERSION = 0.03;

use strict;
use Scalar::Util;
use Template;

use Devel::Peek;

$Carp::Internal{ Template }++;
$Carp::Internal{+__PACKAGE__}++;

my $print_code;
BEGIN {
    $print_code = sub {
        shift()->CGI::Builder::TT2::_::tt_print( @_ )
    }
}


use Class::groups(
    { name    => 'tt_new_args' ,
      default => sub { 
          { INCLUDE_PATH => [ $_[0]->page_path ] }
      }
    } ,
);

use Class::props(
    { name    => 'tt' ,
      default => sub { shift()->tt_new( @_ ) }
    } ,
);

use Object::groups(
    { name    => 'tt_vars' ,
    } ,
);

use Object::props(
    { name    => 'tt_lookups_package' ,
      default => sub {
          ref( $_[0] ) . '::Lookups'
      }
    } ,
    { name    => 'tt_template' ,
      default => sub {
          $_[0]->page_name . $_[0]->page_suffix 
      }
    } ,
    { name    => 'page_suffix' ,
      default => '.tt2'
    } ,
    { name    => 'page_content' ,
      default => sub { $print_code },
    }
);

# Template->new takes a hashref as sole arg, force scalar context
sub tt_new { Template->new( scalar($_[0]->tt_new_args) ) }


sub CGI::Builder::TT2::_::tt_print
{
    my $s = shift;
    
    Scalar::Util::weaken( $s );
    $s->tt_vars( CBF => sub { return $s } );

    { 
		# Inspect the symbol table of the Lookups package, store refs
		# in tt_vars for TT to use.
        no strict;
        my $href = $s->tt_lookups_package() . '::';

        foreach my $symbol ( keys %$href ) {
            
            local *glob = $href->{ $symbol };

            $s->tt_vars( $symbol => defined $glob ? $glob 
                                  : defined @glob ? \@glob 
                                  : defined %glob ? \%glob
                                  : defined &glob ? \&glob
                                  :                 undef );
        }
    }

    foreach my $symbol ( keys %{ scalar $s->tt_vars() } ) {
        next unless ref( $s->tt_vars( $symbol ) ) eq 'CODE';
        $s->tt_vars( $symbol => 
            CGI::Builder::TT2::_::make_wrapper( $s->tt_vars( $symbol ), $s )
        )
    }

	# process() prints to STDOUT. Could pass a scalar to collect
	# output, but that would eat memory.
    my $ok = $s->tt->process( $s->tt_template(), scalar $s->tt_vars());
}


sub CGI::Builder::TT2::_::make_wrapper
{
    my $code       = shift;
    my $app_object = shift;

	# Stop memory leak by weakening enclosed references
	Scalar::Util::weaken($app_object);

    return sub {
        unshift @_, $app_object;
        goto &{ $code };
    }
}


sub page_content_check
{
    my $s = shift;

	# Template uses a search path to find templates, and can use different
	# providers to get templates from a DB or the web, so a -f test might not
	# be valid here. The tt->context->template method loads the template or
	# throws an exception if loading fails.
    if ($s->page_content eq $print_code) {
		eval { $s->tt->context->template($s->tt_template) };
		return !$@;
    }
    else {
        return length $s->page_content;
    }
}


1;

__END__

=head1 NAME

CGI::Builder::TT2 - CGI::Builder and Template Toolkit 2 integration

=head1 VERSION 0.02

=head1 INSTALLATION

=over

=item Prerequisites

    CGI::Builder    >= 1.12
    Template        >= 2.0

=item CPAN

    perl -MCPAN -e 'install CGI::Builder::TT2'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install


=back

=head1 SYNOPSIS

    # just include it in your build
    
    use CGI::Builder
    qw| CGI::Builder::TT2
      |;

=head1 DESCRIPTION

This module transparently integrates C<CGI::Builder> and C<Template> in
a very handy, powerful and flexible framework that can save you a lot of
coding, time and resources.

With this module, you don't need to produce the C<page_content> within
your page handlers anymore (unless you want to); you don't even need to
manage a template system yourself (unless you want to).

If you use a template system on your own (i.e. not integrated in a CBF
extension), you will have to write all this code explicitly:

=over

=item *

create a page handler for each page as usual

=item *

create a new template object and assign a new template file

=item *

find the runtime values and assign them to the template object

=item *

run the template process and set the C<page_content> to the produced
output

=back

You can save all that by just including this module in your build,
because it implements an internal transparent and automatic template
system that even without your explicit intervention is capable of
finding the correct template and the correct runtime values to fill it,
and generates the page_content automagically. With this module you can
even eliminate the page handlers that are just setting the page_content,
because the page is automatically sent by the template system.

=head2 Example

There's an extended example in the directory C<example/> of the module
distribution. Anyway, here a snippet to get the general idea: 

    package WebApp;
    use CGI::Builder qw/ CGI::Builder::TT2 /;
    
    sub PH_index
    {
        my $self = shift;
    
        $self->tt_vars( environment => \%ENV );
    }

Here's the template:

    <html>
    <head>
        <meta http-equiv=content-type content="text/html;charset=iso-8859-1">
        <title>A random example :)</title>
    </head>
    <body>
        <table>
        [% FOREACH k IN environment.keys %]
        <tr>
            <td>[% k %]</td>
            <td>[% environment.$k %]</td>
        </tr>
        [% END %]
        </table>
    </body>
    </html>

This is just one of the styles you can adopt with CGI::Builder::TT2.
Read further. 

=head2 How it works

This module implements a default value for the C<page_content> property:
a CODE reference that produces and print the page content by using an
internal C<Template> object.

Since the C<page_content> property is set to its own default value
before the page handler is called, the page handler can completely (and
usually should) avoid to produce any output.

    sub PH_myPage
    {
      ... do_something_useful ...
      ... no_need_to_set_page_content ...
      ... returned_value_will_be_ignored ...
    }

This module just calls the page handler related with the C<page_name>,
but it does not expect any returned value from it.

The output will be generated internally by the merger of the template
file and the runtime values that are looked up from the
C<FooBar::Lookup> package ('FooBar' is not literal, but stands for your
application namespace plus the '::Lookups' string).

In simplest cases you can also avoid to create the page handler for
certain pages: by default the template with the same page name will be
used to produce the output.

This does not mean that you cannot do things otherwise when you need to.
Just create a page handler and add there all the properties you want, or
set those you want to override:

   sub PH_mySpecialPage
   {
     my $s = shift ;
     $s->tt_vars( 
        special_key          => 'that' ,
        another_special_keys => 'this'
     ) ;
     $s->tt_template = '/that/special/template.tt2' ;
   }

Since the page handler adds values to the C<tt_vars> properties group,
and sets the C<tt_template> property, the application will add those
values to the (possibly empty) template variables set, and the template
system will print with a specific template and not with the default
'mySpecialPage.tt2'.

If some page handler needs to produce the output on its own (completely
bypassing the template system) it can do so by setting the
C<page_content> property as usual (i.e. with the page content or with a
reference to it)

   sub PH_mySpecialPage
   {
     my $s = shift ;
      ... do_something_useful ...
     # will bypass the template system
     $s->page_content  = 'something';
     $s->page_content .= 'something more';
   }

For the 'mySpecialPage' page, the application will not use the template
system at all, because the C<page_content> property was set to the
output.

B<Note>: For former CGI::Application users: the returned value of any
page handler will be ALWAYS ignored, so set explicitly the
C<page_content> property when needed.

=head2 Lookups

These features mimics the mechanisms implemented in CGI::Builder::Magic,
to provide another way to pass variables to the templates. A way that
CGI::Builder users could be familiar with.

=head3 *::Lookups package

This is a special package that your application should define to allow
the object to auto-magically look up the run time values.

The name of this package is contained in the L<"tt_lookups_package">
property.  The default value for this property is 'FooBar::Lookup' where
'FooBar' is not literal, but stands for your CBB namespace plus the
'::Lookups' string, so if you define a CBB package as 'WebApp' you
should define a 'WebApp::Lookups' package too (or set the
C<tt_lookup_package> property with the name of the package you will use
as the lookup).

In this package you should define all the variables and subs needed to
supply any runtime value that will be substituted in place of the
matching label or block in any template.

The lookup is confined to the C<*::Lookups> package on purpose. It would
be simpler to use the same CBB package, but this would extend the lookup
to all the properties, methods and handlers of your CBB and this might
cause conflict and security holes. So, by just adding one line to your
CBB, (e.g. 'package FooBar::Lookups;') you can separate your CBB from
the lookup-allowed part of it.

B<Note>: Obviously you can also put the C<*::Lookup> package in its own
'.pm' file, thus making it simply loadable from different CBBs.

=head2 The Template syntax

This module implements a C<Template> object, so the used C<tags> are the
default Template tags e.g.:

    [% FOREACH item IN array %]
      [% item %]
    [% END %]

Please, read L<Template::Manual>.

=head2 How to organize your CBB

=over

=item 1

Set all the actions common to all pages in the C<OH_init()> handler (as
usual)

=item 2

Prepare a template for each page addressed by your application

=item 3

Set the variables or the subs in the C<*::Lookups> package that will be
available to the internal C<Template> object (that could be picked up by
one or more templates processing)

=item 4

Define just the page handlers that needs to do something special

=item 5

Use the properties default values, that can save you a lot of time ;-)

=back

=head1 PROPERTY and GROUP ACCESSORS

This module adds some template properties (all those prefixed with
'tt_') to the standard CBF properties. The default of these properties
are usually smart enough to do the right job for you, but you can
fine-tune the behavior of your CBB by setting them to the value you
need.

=head2 tt_vars

This property group accessor allows you to set the variables that will
be available in the template. If one of these variables has the same
name of a variable that's in the lookups package, it will be overridden.
You can pass any type of scalar value to the templates: numbers, strings
and any type of references. Subroutines passed to the template in this
way, when called, will receive a reference to the application object as
their first argument. E.g.:

    package WebApp;
    use CGI::Builder qw/ CGI::Builder::TT2 /;
    
    sub foo
    {
        my $app   = shift;
        my $param = shift;
    
        # $app IS A 'Webapp'
        # $param's value is 'bar'
    }
    
    sub PH_index
    {
        my $self = shift;
    
        $self->tt_vars( my_sub => \&foo );
    }

And this is the corresponding template:

    [% my_sub( 'bar' ) %]

Moreover, every template will receive a reference to the CBF object in
the variable C<CBF>, with no action required to the programmer. 
It should be noted that it's a good software practice to separate
application logic from visualization logic: calling application
methods from the template could drive to situations of coupling
between these two aspects. But we will apply Perl's philosophy,
giving rope to the programmer even if he could hang himself with it

=head2 tt_lookups_package

This property allows you to access and set the name of the package where
the Template object. The default value for this property
is 'FooBar::Lookup' where 'FooBar' is not literal, but stands for your
application namespace plus the '::Lookups' string. (i.e.
'WebApp::Lookup').

=head2 tt_template

This property allows you to access and set the 'template' argument
passed to the Template C<process()> method. Set This property to an
absolute path if you want bypass the C<page_path> property.

=head2 CBF changed property defaults

=head3 CBF page_suffix

This module sets the default of the C<page_suffix> to '.tt2'. You can
override it by just setting another suffix of your choice.

=head3 CBF page_content

This module sets the default of the C<page_content> to a CODE reference
that produces the page content by using an internal Template object (see
also L<"How it works">). If you want to bypass the template system in
any Page Handler, just explicitly set the C<page_content> to the content
you want to send.

=head1 ADVANCED FEATURES

In this section you can find all the most advanced or less used features
that document all the details of this module. In most cases you don't
need to use them, anyway, knowing them will not hurt.

=head2 tt

This property returns the internal C<Template> object.

This is not intended to be used to generate the page output - that is
generated automatically - but it could be useful to generate other
outputs (e.g. messages for sendmail) by using the same template object,
thus preserving the same arguments.

B<Note>: You can change the default arguments of the object by using the
C<tt_new_args> property, or you can completely override the creation of
the internal object by overriding the C<tt_new()> method.

=head2 tt_new()

This method is not intended to be used directly in your CBB. It is used
internally to initialize and return the C<Template> object. You can
override it if you know what you are doing, or you can simply ignore it
;-).

=head2 tt_new_args( arguments )

This property group accessor handles the Template constructor arguments
that are used in the creation of the internal Template object. Use it to
finetune the behavior if you know what are doing.
By default, only one option is set: C<INCLUDE_PATH => [ $_[0]->page_path ]>.

B<Note>: You can completely override the creation of the internal object
by overriding the C<tt_new()> method.

=head1 SUPPORT

Even if this module has not been written by Domizio Demichelis, you can
find support via the mailing list, which I read daily: I'll try to
respond as soon as possible. Moreover, if the question involve
CGI::Builder issues, you could receive a reply from CGI::Builder's
author himself.  The list is used for general support on the use of the
CBF, announcements, bug reports, patches, suggestions for improvements
or new features. The API to the CBF is stable, but if you use the CBF in
a production environment, it's probably a good idea to keep a watch on
the list.

You can join the CBF mailing list at this url:

    http://lists.sourceforge.net/lists/listinfo/cgi-builder-users

=head1 ACKNOWLEDGMENTS

Many thanks to Domizio Demichelis, author of the CGI::Builder framework,
who helped me during the development of this module with prompt
explanations, insightful advices and patience.

=head1 AUTHORS

Stefano Rodighiero, E<lt>larsen@perl.itE<gt> (L<http://larsen.perlmonk.org>)

Vince Veselosky (L<http://control-escape.com>) - Contributed with many ideas,
comments and clever solutions to daunting problems. And the extended example,
too.

=head1 COPYRIGHT

(c) 2004 by Stefano Rodighiero E<lt>larsen@perl.itE<gt>

All Rights Reserved. This module is free software. It may be used,
redistributed and/or modified under the same terms as perl itself.
