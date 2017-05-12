package Bigtop::Backend::Control::Gantry;
use strict; use warnings;

# I apologize to all developers for littering the top of this file with POD.
# If I don't the first POD that perldoc shows is the POD template for generated
# code.  Try vim folding.

=head1 NAME

Bigtop::Backend::Control::Gantry - controller generator for the Gantry framework

=head1 SYNOPSIS

Build a file like this called my.bigtop:

    config {
        base_dir `/home/username`;
        Control Gantry {}
    }
    app App::Name {
        controller SomeController {}
    }

Then run this command:

    bigtop my.bigtop Control

=head1 DESCRIPTION

When your bigtop config includes Control Gantry, this module will be
loaded by Bigtop::Parser when bigtop is run with all or Control
in its build list.

This module builds files in the lib subdirectory of base_dir/App-Name.
(But you can change name by supplying app_dir, as explained in
Bigtop::Parser's pod.)

There will generally be two files for each controller you define.  One
will have the name you give it with the app name in front.  For the SYNOPSIS
example, that file will be called

    /home/username/App-Name/lib/App/Name/SomeController.pm

I call this file the stub.  It won't have much useful code in it, though
it might have method stubs depending on what's in its controller block.

The other file will have generated code in it.  As such it will go in the
GEN subdirectory of the directory where the stub lives.  In the example,
the name will be:

    /home/username/App-Name/lib/App/Name/GEN/SomeController.pm

During the intial build, both of these files will be made.  Subsequently,
the stub will not be regenerated (unless you delete it), but the GEN file
will be.  To prevent regeneration you may either put no_gen in the
Control Gantry block of the config, like this:

    config {
        ...
        Control Gantry { no_gen 1; }
    }

or you may mark the controller itself:

    controller SomeController {
        no_gen 1;
    }

=head2 controller KEYWORDS

Each controller has the form

    controller name is type {
        keyword arg, list;
        method name is type {
            keyword arg, list;
        }
    }

For a list of the keywords you can include in the controller block see the pod
for Bigtop::Control.  For a list of the keywords you can include in the
method block, see below (and note that most of these vary by the method's
type).

The controller phrase 'is type' is optional and defaults to 'is stub' which
has no effect.  The supported types are:

=over 4

=item AutoCRUD

This simply adds Gantry::Plugins::AutoCRUD to your uses list (it
will create the list if you don't have one).  Do not manually put
Gantry::Plugins::AutoCRUD in the uses list if you use type AutoCRUD, or
it will have two use statements.

=item CRUD

This adds Gantry::Plugins::CRUD to your uses list (it will create the list
if you don't have one).  As with AutoCRUD, don't manually put
Gantry::Plugins::CRUD in your uses list if you set the type to CRUD.

In addition to modifying your uses list, this type will make extra code.
Each time it sees a method of type AutoCRUD_form, it will make the following
things (suppose the AutoCRUD_form method is called my_crud_form):

=over 4

=item form method

This method will be suitable for use as the form named parameter to the
Gantry::Plugins::CRUD constructor.

You get this whether you set the controller type to CRUD or not.

=item constructed crud object

    my $my_crud = Gantry::Plugins::CRUD->new(
        add_action    => \&my_crud_add,
        edit_action   => \&my_crud_edit,
        delete_action => \&my_crud_delete,
        form          => \&my_crud_form,
        redirect      => \&my_crud_redirect,
        text_descr    => 'your text_description here',
    );

=item redirect method

Replicates the default behavior of always sending the user back to
$self->location on successful save or cancel.

=item do_* methods

A set of methods for add, edit, and delete which Gantry's handler will call.
These are stubs.  Example:

    #-------------------------------------------------
    # $self->do_add( )
    #-------------------------------------------------
    sub do_add {
        my $self = shift;

        $crud->add( $self, { data => \@_ } );
    }

Note that you should do something better with the data.  This method
leaves you having to fish through an array in the action method, and
therefore makes it harder for code readers to find out what is in the data.

=item action methods

A set of methods corresponding to do_add, do_edit, and do_delete which
are specified during the construction of the crud object.  Example:

    #-------------------------------------------------
    # $self->my_crud_add( $id )
    #-------------------------------------------------
    sub my_crud_add {
        my ( $self, $params, $data ) = @_;

        my $row = $YOUR_CONTROLLED_TABLE->create( $param );
        $row->dbi_commit();
    }

Note that the new object creation code a Class::DBI style API can be
called against the model alias of the table this controller controls.
That won't work if you are controlling multiple tables.  The same
holds for the edit and delete methods.

=back

Note that all generated names are based on the name of the form method.
The name is made with a brain dead regex which simply strips _form from
that name.

=back

=head2 method KEYWORDS

Most of the method keywords depend on the method's type.  This one doesn't:

=over 4

=item extra_args

Make this a comma separated list of arguments your method should expect.
Example:

    extra_args   `$cust_id`, `@params`;

Note that there is almost no magic here.  These will simply be added
to the method's opening comment and argument capturing code.  So
if the above example appeared in a handler method, the stub would look
roughly like this:

    #--------------------------------------------------
    # $self->method_name( $cust_id, @params )
    #--------------------------------------------------
    sub method_name {
        my ( $self, $cust_id, @params ) = @_;
    }

=back

=head1 SUPPORTED METHOD TYPES

Note Well:  Gantry's handlers must be called do_*.  The leading do_
will not be magically supplied.  Type it yourself.

Each method must have a type.  This backend supports the following types
(where support may vary depending on the type):

=over 4

=item stub

Generates an empty method body.  (But it handles arguments, see
extra_args above.)

=item main_listing

Generates a method, which you should probably name do_main, which produces
a listing of all the items in a table sorted by the columns in the table's
foreign_display.

You may include the following keys in the method block:

=over 4

=item rows

An integer number of rows to display on each page of main listing output.
There is no default.  If you omit this, you get all the rows, which is
painful if there are very many.

You must be using DBIx::Class for this to be effective.

=item cols

This is the list of columns that should appear in the listing.
More than 5 or 6 will likely look funny.  Use the field names from
the table you are controlling.

=item col_labels

This optional list allows you to specify labels for the columns instead
of using the label specfied in the field block of the controlled table.
Each list element is either a simple string which becomes the label
or a pair in which the key is the label and the value is a url (or code
which builds one) which becomes the href of an html link.  Example:

    col_labels   `Better Text`,
                 Label => `$self->location() . '/exotic/locaiton'`;

Note that for pairs, you may use any valid Perl in the link text.  Enclose
it in backquotes.  It will not be modified, mind your own quotes.

=item extra_args

See above.

=item header_options

These are the options that will appear at the end of the column label
stripe at the top of the output table.  Typically this is just:

    header_options Add;

But you can expand on that in a couple of ways.  You can have other
options:

    header_options AddBuyer, AddSeller;

These will translate into href links in the html page as

    current_base_uri/addbuyer
    current_base_uri/addseller

(In Gantry this means you should have do_addbuyer and do_addseller
methods in the same .pm file where the main_listing lives.)

You can also control the generated url:

    header_options AddUser => `$self->exotic_location() . "/strange_add"`;

Put valid Perl inside the backquotes.  It will NOT be changed in any way.
You must ensure that the code will work in the final app.  In this case
that likely means that exotic_location should return a uri which is
mentioned in a Location block in httpd.conf.  Further, the module
set as the handler for that location must have a method called
do_strange_add.

=item html_template

The name of the Template Toolkit file to use as the view for this page.
By default this is results.tt for main_listing methods and main.tt for
base_link methods.

=item row_options

These yield href links at the end of each row in the output table.
Typical example:

    row_options Edit, Delete;

These work just like header_options with one exception.  The url has
the id of the row appended at the end.

If you say

    row_options Edit => `$url`;

You must make sure that the url is exactly correct (including appending
'/$id' to it).  Supplied values will be taken literally.

=item title

The browser window title for this page.

=back

=item AutoCRUD_form

Generates a method, usually called _form, which Gantry::Plugins::AutoCRUD
calls from its do_add and do_edit methods.

You may include the following keys in the method block:

=over 4

=item all_fields_but

A comma separated list of fields that should not appear on the form.
Typical example:

    all_fields_but id;

=item extra_args

See above.  Note that for the extra_args to be available, they must
be passed from the AutoCRUD calling method.

=item extra_keys

List key/value pairs you want to appear in the hash returned by the method.
Example:

    extra_keys
        legend     => `$self->path_info =~ /edit/i ? 'Edit' : 'Add'`,
        javascript => `$self->calendar_month_js( 'customer' )`;

The javascript entry is exactly correct for a form named customer
using Gantry::Plugins::Calendar.

Note that whatever you put inside the backquotes appears EXACTLY as is
in the generated output.  Nothing will be done to it, not even quote
escaping.

=item fields

A comma separated list of the fields to include on the form.  The
names must match fields of table you are controlling.
Example:

    fields first_name, last_name, street, city, state, zip;

Note that all_fields_but is usually easier, but directly using fields
allows you to change the order in which the entry widgets appear.

=item form_name

The name of the html form.  This is important if you are using javascript
which needs to refer to the form (for example if you are using
Gantry::Plugins::Calendar).

=back

=item CRUD_form

Takes the same keywords as AutoCRUD_form but makes a form method suitable
for use with Gantry::Plugins::CRUD.  Note that due to the callback scheme
used in that module, the name you give the generated method is entirely up
to you.  Note that the method is generated in the stub and therefore must
be included during initial building to avoid gymnastics (like renaming the
stub, genning, renaming the regened stub, moving the form method from that
file back into the real stub...).

=back

=head1 METHODS

To keep podcoverage tests happy.

=over 4

=item backend_block_keywords

Tells tentmaker that I understand these config section backend block keywords:

    no_gen
    dbix
    full_use
    template

=item what_do_you_make

Tells tentmaker what this module makes.  Summary: Gantry controller modules.

=item gen_Control

Called by Bigtop::Parser to get me to do my thing.

=item build_config_lists

What I call on the various AST packages to do my thing.

=item build_init_sub

What I call on the various AST packages to do my thing.

=item setup_template

Called by Bigtop::Parser so the user can substitute an alternate template
for the hard coded one here.

=back

=head1 AUTHOR

Phil Crow <crow.phil@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 IGNORE the REST

After this paragraph, you will likely see other POD.  It belongs to
the generated modules.  I just couldn't figure out how to hide it.

=cut

use Bigtop::Backend::Control;
use File::Spec;
use Inline;
use Bigtop;

#-----------------------------------------------------------------
#   Register keywords in the grammar
#-----------------------------------------------------------------

BEGIN {
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'controller',
            qw(
                plugins
                autocrud_helper
            )
        )
    );

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'method',
            qw(
                extra_args
                order_by
                rows
                paged_conf
                cols
                col_labels
                pseudo_cols
                header_options
                header_option_perms
                authed_methods
                permissions
                literal
                livesearch
                row_options
                row_option_perms
                title
                html_template
                limit_by
                where_terms
                all_fields_but
                fields
                extra_keys
                form_name
                expects
                returns
            )
        )
    );

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'field',
            qw(
                label
                searchable
                pseudo_value
                unique_name
                html_form_type
                html_form_optional
                html_form_constraint
                html_form_default_value
                html_form_cols
                html_form_rows
                html_form_display_size
                html_form_hint
                html_form_class
                html_form_options
                html_form_foreign
                html_form_onchange
                html_form_fieldset
                date_select_text
                html_form_raw_html
            )
        )
    );
}

#-----------------------------------------------------------------
#   The Default Template
#-----------------------------------------------------------------

our $template_is_setup = 0;
our $default_template_text = <<'EO_TT_blocks';
[% BLOCK hashref %]
    return {
[% IF authed_methods.keys.0 %]
        authed_methods => [
[% FOREACH k IN authed_methods.keys %]
        { action => '[% k %]',  group => '[% authed_methods.$k %]' },
[% END %]
        ],
[% END %]
[% IF permissions.size >= 1 %]
        permissions => {
            bits  => '[% permissions.0 %]',
            group => '[% permissions.1 %]'
        },
[% END %]
[% IF literals.0 %]

[% FOREACH literal IN literals %]
    [% literal %],
[% END %]
[% END %]
    };
[% END %]

[% BLOCK base_module %]
package [% app_name %];

use strict;
use warnings;

our $VERSION = '0.01';

use base '[% gen_package_name %]';

[% FOREACH module IN external_modules %]
use [% module %];
[% END %]
[% child_output %]


[%- IF class_accessors -%]
[% class_accessors %]
[%- END -%]

[% IF init_sub %]
#-----------------------------------------------------------------
# $self->init( $r )
#-----------------------------------------------------------------
# This method inherited from [% gen_package_name +%]
[% END %]
[% IF config_accessor_comments %]
[% config_accessor_comments %]
[% END %]

1;

[% pod %]
[% END %]

[% BLOCK gen_base_module %]
# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package [% gen_package_name %];

use strict;
use warnings;

[% IF full_use_statement %]
use Gantry qw{[% IF engine +%]
    -Engine=[% engine %][% END %][% IF template_engine +%]
    -TemplateEngine=[% template_engine %][% END +%]
[% IF plugins %]    -PluginNamespace=[% app_name +%]
    [% plugins +%]
[% END %]
};
[% ELSE %]
use Gantry[% IF template_engine %] qw{ -TemplateEngine=[% template_engine %] }[% END %];
[% END %]

use JSON;
use Gantry::Utils::TablePerms;

our @ISA = qw( Gantry );

[% FOREACH module IN external_modules %]
use [% module %];
[% END %]

[% IF dbix %]
use [% base_model %];
sub schema_base_class { return '[% base_model %]'; }
use Gantry::Plugins::DBIxClassConn qw( get_schema );
[% END %]

#-----------------------------------------------------------------
# $self->namespace() or [% app_name %]->namespace()
#-----------------------------------------------------------------
sub namespace {
    return '[% app_name %]';
}

[% init_sub %]

[% config_accessors %]
[% IF child_output %]
[% child_output %]
[% ELSE %]
#-----------------------------------------------------------------
# $self->do_main( )
#-----------------------------------------------------------------
sub do_main {
    my ( $self ) = @_;

    $self->stash->view->template( 'main.tt' );
    $self->stash->view->title( '[% dist_name %]' );

    $self->stash->view->data( { pages => $self->site_links() } );
} # END do_main

#-----------------------------------------------------------------
# $self->site_links( )
#-----------------------------------------------------------------
sub site_links {
    my $self = shift;

    return [
[% FOREACH page IN pages %]
[% IF page.link.match( '^/' ) %]
        { link => '[% page.link %]', label => '[% page.label %]' },
[% ELSE %]
        { link => $self->app_rootp() . '/[% page.link %]', label => '[% page.label %]' },
[% END %]
[% END %]
    ];
} # END site_links
[% END %]

1;

[% gen_pod +%]
[% END %]

[% BLOCK test_file %]
use strict;
use warnings;

use Test::More tests => [% module_count %];

[% FOREACH module IN modules %]
use_ok( '[% module %]' );
[% END %]
[% END %]

[% BLOCK pod_test %]
use Test::More;

eval "use Test::Pod 1.14";
plan skip_all => 'Test::Pod 1.14 required' if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

all_pod_files_ok();
[% END %]

[% BLOCK pod_cover_test %]
use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

all_pod_coverage_ok();
[% END %]

[% BLOCK run_test %]
use strict;
use warnings;

use Test::More tests => [% num_tests %];

use [% app_name %] qw{
    -Engine=CGI
    -TemplateEngine=[% template_engine || TT +%]
[% IF plugins %]    -PluginNamespace=[% app_name +%]
    [% plugins +%]
[% END %]
};

use Gantry::Server;
use Gantry::Engine::CGI;

# these tests must contain valid template paths to the core gantry templates
# and any application specific templates

my $cgi = Gantry::Engine::CGI->new( {
    config => {
[% FOREACH var_pair IN configs %]
        [% var_pair.0 %] => '[% var_pair.1 %]',
[% END %]
    },
    locations => {
[% FOREACH location IN locations %]
        '[% location.0 %]' => '[% location.1 %]',
[% END %]
    },
} );

my @tests = qw(
[% FOREACH location IN locations %]
    [% location.0 +%]
[% END %]
);

my $server = Gantry::Server->new();
$server->set_engine_object( $cgi );

SKIP: {

    eval {
        require DBD::SQLite;
    };
    skip 'DBD::SQLite is required for run tests.', [% num_tests %] if ( $@ );

    unless ( -f 'app.db' ) {
        skip 'app.db sqlite database required for run tests.', [% num_tests %];
    }

    foreach my $location ( @tests ) {
        my( $status, $page ) = $server->handle_request_test( $location );
        ok( $status eq '200',
                "expected 200, received $status for $location" );

        if ( $status ne '200' ) {
            print STDERR $page . "\n\n";
        }
    }

}
[% END %]

[% BLOCK controller_block %]
package [% package_name %];

use strict;
use warnings;

[% IF sub_modules %]
our $VERSION = '0.01';

[% END %]
use base '[% inherit_from %]';
[% FOREACH module IN sub_modules %]
[% IF loop.first %]

[% END %]
use [% module %];
[% END %]
[% child_output %]

[% class_accessors %]

1;

[% pod %]
[% END %]

[% BLOCK pod %]
=head1 NAME

[% IF sub_module %]
[% package_name %] - A controller in the [% app_name %] application
[% ELSE %]
[% package_name %] - the base module of this web app
[% END %]

=head1 SYNOPSIS

This package is meant to be used in a stand alone server/CGI script or the
Perl block of an httpd.conf file.

Stand Alone Server or CGI script:

    use [% package_name %];

    my $cgi = Gantry::Engine::CGI->new( {
        config => {
            #...
        },
        locations => {
[% IF sub_module %]
            '/someurl' => '[% package_name %]',
[% ELSE %]
            '/' => '[% package_name %]',
[% END %]
            #...
        },
    } );

httpd.conf:

    <Perl>
        # ...
        use [% package_name %];
    </Perl>
[% IF sub_module %]

    <Location /someurl>
        SetHandler  perl-script
        PerlHandler [% package_name +%]
    </Location>
[% END %]

If all went well, one of these was correctly written during app generation.

=head1 DESCRIPTION

This module was originally generated by Bigtop.  But feel free to edit it.
You might even want to describe the table this module controls here.

[% IF sub_module %]
=head1 METHODS
[% ELSIF gen_package_name AND NOT sub_modules %]
=head1 METHODS (inherited from [% gen_package_name %])
[% ELSE %]
=head1 METHODS
[% END %]

=over 4

[% FOREACH method IN methods %]
=item [% method %]


[% END %]

=back

[% IF gen_package_name AND mixins %]

=head1 METHODS INHERITED FROM [% gen_package_name +%]

=over 4

[% FOREACH mixin IN mixins %]
=item [% mixin %]


[% END %]

=back

[% END -%]

=head1 [% other_module_text +%]

[% FOREACH used_module IN used_modules %]
    [% used_module +%]
[% END %]
[% FOREACH see_also IN sub_modules %]
    [% see_also +%]
[% END %]

=head1 AUTHOR

[% FOREACH author IN authors %]
[% author.0 %][% IF author.1 %], E<lt>[% author.1 %]E<gt>[% END +%]

[% END %]
[%- IF contact_us %]
=head1 CONTACT US

[% contact_us +%]

[% END -%]
=head1 COPYRIGHT AND LICENSE

Copyright (C) [% year %] [% copyright_holder %]


[% IF license_text %]
[% license_text %]

[% ELSE %]
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.
[% END %]

=cut
[% END %]

[% BLOCK gen_pod %]
=head1 NAME

[% gen_package_name %] - generated support module for [% package_name +%]

=head1 SYNOPSIS

In [% package_name %]:

    use base '[% gen_package_name %]';

=head1 DESCRIPTION

This module was generated by Bigtop (and IS subject to regeneration) to
provide methods in support of the whole [% package_name +%]
application.

[% package_name %] should inherit from this module.

=head1 METHODS

=over 4

[% FOREACH method IN methods %]
=item [% method +%]

[% END %]

=back

=head1 AUTHOR

[% FOREACH author IN authors %]
[% author.0 %][% IF author.1 %], E<lt>[% author.1 %]E<gt>[% END +%]

[% END %]
[%- IF contact_us %]
=head1 CONTACT US

[% contact_us +%]

[% END -%]
=head1 COPYRIGHT AND LICENSE

Copyright (C) [% year %] [% copyright_holder %]


[% IF license_text %]
[% license_text %]

[% ELSE %]
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.
[% END %]

=cut
[% END %]

[% BLOCK gen_controller_pod %]
=head1 NAME

[% gen_package_name %] - generated support module for [% package_name +%]

=head1 SYNOPSIS

In [% package_name %]:

    use base '[% gen_package_name %]';

=head1 DESCRIPTION

This module was generated by bigtop and IS subject to regeneration.
Use it in [% package_name %] to provide the methods below.
Feel free to override them.

=head1 METHODS

=over 4

[% FOREACH method IN gen_methods %]
=item [% method +%]

[% END %]

=back

=head1 AUTHOR

Generated by bigtop and subject to regeneration.

=cut
[% END %]

[% BLOCK gen_controller_block %]
# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package [% gen_package_name %];

use strict;
use warnings;

[% IF wsdl %]
use [% app_name %] qw(
    -PluginNamespace=[% package_name +%]
    SOAP::[% soap_style +%]
);

our @ISA = qw( [% app_name %] );
[% ELSIF plugins %]
use [% app_name %] qw{
    -PluginNamespace=[% package_name +%]
    [% plugins +%]
};

our @ISA = qw( [% app_name %] );

use JSON;
use Gantry::Utils::TablePerms;
[% ELSE %]
use base '[% app_name %]';
use JSON;
use Gantry::Utils::TablePerms;
[% END %]

[% child_output %]
[% IF wsdl %][% wsdl %][% END %]
[% IF init_sub %]

[% init_sub %]
[% END %]
[% IF config_accessors %]
[% config_accessors %]
[% END %]
[% IF plugins %]

#-----------------------------------------------------------------
# $self->namespace() or Apps::Checkbook->namespace()
#-----------------------------------------------------------------
sub namespace {
    return '[% package_name %]';
}
[% END %]

1;

[% gen_pod %]

[% END %]

[% BLOCK use_stub %]
use [% module -%]
[%- IF imports -%] qw(
    [% imports.join("\n    ") %]

);

[%- ELSE -%];
[% END %]
[% END %]

[% BLOCK explicit_use_stub %]
use [% module %][% IF import_list %] [% import_list %][% END %];
[% END %]

[% BLOCK export_array %]
our @EXPORT = qw(
[% FOREACH exported_sub IN exported_subs %]
    [% exported_sub +%]
[% END %]
);
[% END %]

[% BLOCK dbix_uses %]
[% use_my_model %]
use [% base_model %];
sub schema_base_class { return '[% base_model %]'; }
use Gantry::Plugins::DBIxClassConn qw( get_schema );
[% END %]

[% BLOCK get_orm_helper %]
#-----------------------------------------------------------------
# get_orm_helper( )
#-----------------------------------------------------------------
sub get_orm_helper {
    return '[% helper %]';
}

[% END %]

[% BLOCK class_access %]
#-----------------------------------------------------------------
# get_model_name( )
#-----------------------------------------------------------------
sub get_model_name {
    return $[% model_alias %];
}

[% END %]

[% BLOCK text_description %]
#-----------------------------------------------------------------
# text_descr( )
#-----------------------------------------------------------------
sub text_descr     {
    return '[% description %]';
}
[% END %]

[% BLOCK controller_method +%]
#-----------------------------------------------------------------
# $self->[% method_name %]( [% child_output.doc_args.join( ', ' ) %] )
#-----------------------------------------------------------------
# This method inherited from [% gen_package_name %]

[% END %]

[% BLOCK gen_controller_method +%]
#-----------------------------------------------------------------
# $self->[% method_name %]( [% child_output.doc_args.join( ', ' ) %] )
#-----------------------------------------------------------------
sub [% method_name %] {
[% child_output.body %]
} # END [% method_name %]

[% END %]

[% BLOCK init_method_body %]
[% arg_capture %]

    # process SUPER's init code
    $self->SUPER::init( $r );

[% FOREACH config IN configs %]
    $self->set_[% config %]( $self->fish_config( '[% config %]' ) || '' );
[% END %]
[% END %]

[% BLOCK config_accessors %]
[% FOREACH config IN configs %]
#-----------------------------------------------------------------
# $self->set_[% config %]( $new_value )
#-----------------------------------------------------------------
sub set_[% config %] {
    my ( $self, $value ) = @_;

    $self->{ __[% config %]__ } = $value;
}

#-----------------------------------------------------------------
# $self->[% config %](  )
#-----------------------------------------------------------------
sub [% config %] {
    my $self = shift;

    return $self->{ __[% config %]__ };
}

[% END %]
[% END %]

[% BLOCK arg_capture %]
[% FOREACH arg IN args %]
    my [% arg %] = shift;
[% END %]
[% END %]

[% BLOCK arg_capture_st_nick_style %]
    my ( [% args.join( ', ' ) %] ) = @_;
[% END %]

[% BLOCK self_setup %]
    $self->stash->view->template( '[% template %]' );
    $self->stash->view->title( '[% title %]' );
[% IF with_real_loc %]

    my $real_location = $self->location() || '';
    if ( $real_location ) {
        $real_location =~ s{/+$}{};
        $real_location .= '/';
    }
[% END %]
[% END %]

[% BLOCK main_links %]
    $self->stash->view->data( { pages => $self->site_links() } );
[% END %]

[% BLOCK site_links %]
    return [
[% FOREACH page IN pages %]
        { link => [% page.link %], label => '[% page.label %]' },
[% END %]
    ];
[% END %]

[% BLOCK main_heading %]
[% IF limit_by %]
    my $header_option_suffix = ( $[% limit_by %] ) ? "/$[% limit_by %]" : '';

[% END %]
    my @header_options = (
[% FOREACH option IN header_options %]
        {
            text => '[% option.text %]',
            link => [% option.location +%],
            type => '[% option.type %]',
        },
[% END %]
    );

    my $retval = {
        headings       => [
[% FOREACH heading IN headings %]
[% IF heading.simple %]
            [% IF heading.simple.match( "'" ) %]q[[% heading.simple %]][% ELSE %]'[% heading.simple %]'[% END %],
[% ELSIF heading.href %]
            '<a href=' . [% heading.href.link %] . [% IF heading.href.text.match( "'" ) %]q[>[% heading.href.text %]</a>][% ELSE %]'>[% heading.href.text %]</a>'[% END %],
[% END %]
[% END %]
        ],
    };
[% END %]

[% BLOCK main_table %]

    [%- IF livesearch %]
    $retval->{ livesearch } = 1;

    [% END -%]
    my $params = $self->params;

[% IF where_terms.size > 0 %]
    my $search = {
[% FOREACH where_term IN where_terms %]
        [% where_term.col_name %] => [% where_term.value %],
[% END %]
    };
[% ELSE %]
    my $search = {};
[% END %]
    if ( $params->{ search } ) {
        my $form = $self->form();

        my @searches;
        foreach my $field ( @{ $form->{ fields } } ) {
            if ( $field->{ searchable } ) {
                push( @searches,
                    ( $field->{ name } => { 'like', "%$params->{ search }%"  } )
                );
            }
        }

        $search = {
            -or => \@searches
        } if scalar( @searches ) > 0;
    }

    my @row_options = (
[% FOREACH row_option IN row_options %]
        {
            text => '[% row_option.text %]',
[% IF row_option.location %]
            link => [% row_option.location %],
[% END %]
            type => '[% row_option.type %]',
        },
[% END %]
    );

    my $perm_obj = Gantry::Utils::TablePerms->new(
        {
            site           => $self,
            real_location  => $real_location,
            header_options => \@header_options,
            row_options    => \@row_options,
        }
    );

    $retval->{ header_options } = $perm_obj->real_header_options;

    my $limit_to_user_id = $perm_obj->limit_to_user_id;
    $search->{ user_id } = $limit_to_user_id if ( $limit_to_user_id );

[% IF dbix AND rows AND limit_by -%]
    my $page    = $params->{ page } || 1;

    if ( $[% limit_by %] ) {
        $search->{ [% limit_by %] } = $[% limit_by %];
    }

    my $schema  = $self->get_schema();
    my $results = $[% model %]->get_listing(
        {
[% IF pseudo_cols.size > 0 %]
            '+select'   => [[% FOREACH pseudo_col IN pseudo_cols %][% pseudo_col.field %][% UNLESS loop.last %] [% END %][% END %]],
            '+as'       => [[% FOREACH pseudo_col IN pseudo_cols %]'[% pseudo_col.alias %]'[% UNLESS loop.last %] [% END %][% END %]],
[% END %]
            schema      => $schema,
            rows        => [% rows %],
            where       => $search,[% IF order_by %][% "\n" %]            order_by    => '[% order_by %]',[% END +%]
        }
    );

    my $rows          = $results->page( $page );
    $retval->{ page } = $rows->pager();

    ROW:
    while ( my $row = $rows->next ) {
[%- ELSIF dbix AND rows -%]
    my $page    = $params->{ page } || 1;

    my $schema  = $self->get_schema();
    my $results = $[% model %]->get_listing(
        {
[% IF pseudo_cols.size > 0 %]
            '+select'   => [[% FOREACH pseudo_col IN pseudo_cols %][% pseudo_col.field %][% UNLESS loop.last %] [% END %][% END %]],
            '+as'       => [[% FOREACH pseudo_col IN pseudo_cols %]'[% pseudo_col.alias %]'[% UNLESS loop.last %] [% END %][% END %]],
[% END %]
            schema      => $schema,
            rows        => [% rows %],
            where       => $search,[% IF order_by %][% "\n" %]            order_by    => '[% order_by %]',[% END +%]
        }
    );

    my $rows          = $results->page( $page );
    $retval->{ page } = $rows->pager();

    ROW:
    while ( my $row = $rows->next ) {
[%- ELSIF dbix AND limit_by -%]
    if ( $[% limit_by %] ) {
        $search->{ [% limit_by %] } = $[% limit_by %];
    }

    my $schema = $self->get_schema();
    my @rows   = $[% model %]->get_listing(
        {
[% IF pseudo_cols.size > 0 %]
            '+select'   => [[% FOREACH pseudo_col IN pseudo_cols %][% pseudo_col.field %][% UNLESS loop.last %] [% END %][% END %]],
            '+as'       => [[% FOREACH pseudo_col IN pseudo_cols %]'[% pseudo_col.alias %]'[% UNLESS loop.last %] [% END %][% END %]],
[% END %]
            schema      => $schema,
            where       => $search,[% IF order_by %][% "\n" %]            order_by    => '[% order_by %]',[% END +%]
        }
    );

    ROW:
    foreach my $row ( @rows ) {
[%- ELSIF dbix -%]
    my $schema = $self->get_schema();
    my @rows   = $[% model %]->get_listing(
        {
[% IF pseudo_cols.size > 0 %]
            '+select'   => [[% FOREACH pseudo_col IN pseudo_cols %][% pseudo_col.field %][% UNLESS loop.last %] [% END %][% END %]],
            '+as'       => [[% FOREACH pseudo_col IN pseudo_cols %]'[% pseudo_col.alias %]'[% UNLESS loop.last %] [% END %][% END %]],
[% END %]
            schema      => $schema,
            where       => $search,[% IF order_by %][% "\n" %]            order_by    => '[% order_by %]',[% END +%]
        }
    );

    ROW:
    foreach my $row ( @rows ) {
[%- ELSE -%]
    my @rows = $[% model %]->get_listing([% IF order_by %] { order_by => '[% order_by %]', } [% END %]);

    ROW:
    foreach my $row ( @rows ) {
[%- END -%]

        last ROW if $perm_obj->hide_all_data;

        my $id = $row->id;
[% FOREACH foreigner IN foreigners %]
        my $[% foreigner %] = ( $row->[% foreigner %] )
                ? $row->[% foreigner %]->foreign_display()
                : '';
[% END %]

        push(
            @{ $retval->{rows} }, {
                orm_row => $row,
                data => [
[% FOREACH data_col IN data_cols %]
                    [% data_col %],
[% END %]
                ],
                options => $perm_obj->real_row_options( $row ),
            }
        );
    }

    if ( $params->{ json } ) {
        $self->template_disable( 1 );

        my $obj = {
            headings        => $retval->{ headings },
            header_options  => $retval->{ header_options },
            rows            => $retval->{ rows },
        };

        my $json = to_json( $obj, { allow_blessed => 1 } );
        return( $json );
    }

    $self->stash->view->data( $retval );
[% END %]

[% BLOCK form_body %]
[% arg_capture %]
[%- IF dbix -%]
    my $selections = $[% model %]->get_form_selections(
        {
            schema          => $self->get_schema(),
[% IF refers_to.size > 0 %]
            foreign_tables  => {
[% FOREACH rt_table IN refers_to %]
                '[% rt_table %]' => 1,
[% END %]
            }
[% END -%]
        }
    );

[%- ELSE -%]
    my $selections = $[% model %]->get_form_selections();

[%- END -%]

    return {
[% IF form_name %]        name       => '[% form_name %]',
[% END -%]
[% IF raw_row %]        row        => $row,
[% ELSE %]        row        => $data->{row},
[% END -%]
[% FOREACH extra_key_name IN extra_keys.keys() %]
        [% extra_key_name %] => [% extra_keys.$extra_key_name %],
[% END %]
        fields     => [
[% FOREACH field IN fields %]
            {
[% FOREACH key = field.keys %]
[% IF key == 'options_string' %]
                options => [% field.$key %],
[% ELSIF key == 'constraint' OR field.$key.match( '^\d+$' ) %]
                [% key %] => [% field.$key %],
[% ELSIF key == 'options' %]
                options => [
[% arg_list = field.$key %]
[% FOREACH pair IN arg_list %]
[% FOREACH pair_key IN pair.keys() %]
                    { label => '[% pair_key %]', value => '[% pair.$pair_key %]' },
[% END %]
[% END %]
                ],
[% ELSE %]
                [% key %] => [% IF field.$key.match( "'" ) %]q[[% field.$key %]][% ELSE %]'[% field.$key %]'[% END %],
[% END %]
[% END %]
            },
[% END %]
        ],
    };
[% END %]

[% BLOCK crud_helpers %]

my $[% crud_name %] = Gantry::Plugins::CRUD->new(
    add_action      => \&[% crud_name %]_add,
    edit_action     => \&[% crud_name %]_edit,
    delete_action   => \&[% crud_name %]_delete,
    form            => __PACKAGE__->can( '[% form_method_name %]' ),
    redirect        => \&[% crud_name %]_redirect,
    text_descr      => '[% text_descr %]',
);

#-----------------------------------------------------------------
# $self->[% crud_name %]_redirect( $data )
# The generated version mimics the default behavior, feel free
# to delete the redirect key from the constructor call for $crud
# and this sub.
#-----------------------------------------------------------------
sub [% crud_name %]_redirect {
    my ( $self, $data ) = @_;
    return $self->location;
}

#-------------------------------------------------
# $self->do_add( )
#-------------------------------------------------
sub do_add {
    my $self = shift;
[% IF with_perms %]

    Gantry::Plugins::CRUD::verify_permission( { site => $self } );
[% END %]

    $[% crud_name %]->add( $self, { data => \@_ } );
}

#-------------------------------------------------
# $self->[% crud_name %]_add( $params, $data )
#-------------------------------------------------
sub [% crud_name %]_add {
    my ( $self, $params, $data ) = @_;

    # make a new row in the $[% model_alias %] table using data from $params
    # remember to add commit if needed

    $[% model_alias %]->gupdate_or_create( $self, $params );
}

#-------------------------------------------------
# $self->do_delete( $doomed_id, $confirm )
#-------------------------------------------------
sub do_delete {
    my ( $self, $doomed_id, $confirm ) = @_;

    my $row = $[% model_alias %]->gfind( $self, $doomed_id );
[% IF with_perms %]

    Gantry::Plugins::CRUD::verify_permission( { site => $self, row => $row } );
[% END %]

    $[% crud_name %]->delete( $self, $confirm, { row => $row } );
}

#-------------------------------------------------
# $self->[% crud_name %]_delete( $data )
#-------------------------------------------------
sub [% crud_name %]_delete {
    my ( $self, $data ) = @_;

    # fish the id (or the actual row) from the data hash
    # delete it
    # remember to add commit if needed

    $data->{ row }->delete;
}

#-------------------------------------------------
# $self->do_edit( $id )
#-------------------------------------------------
sub do_edit {
    my ( $self, $id ) = @_;

    my $row = $[% model_alias %]->gfind( $self, $id );
[% IF with_perms %]

    Gantry::Plugins::CRUD::verify_permission( { site => $self, row => $row } );
[% END %]

    $[% crud_name %]->edit( $self, { row => $row } );
}

#-------------------------------------------------
# $self->[% crud_name %]_edit( $param, $data )
#-------------------------------------------------
sub [% crud_name %]_edit {
    my( $self, $params, $data ) = @_;

    # retrieve the row from the data hash
    # update the row
    # remember to add commit if needed

    $data->{row}->update( $params );
}
[% END %]

[% BLOCK SOAP_gen_method_body %]
    my $self        = shift;
    my $input       = $self->soap_in;
    my $output_data = $self->[% internal_method %]( $input );

    $self->template_disable( 1 );

    return $self->soap_out( $output_data );
[% END %]

[% BLOCK SOAP_stub_method %]
#-----------------------------------------------------------------
# $self->[% internal_method %](  )
#-----------------------------------------------------------------
sub [% internal_method %] {
    my ( $self, $input ) = @_;
} # END [% internal_method %]
[% END %]

[% BLOCK soap_methods %]

#-----------------------------------------------------------------
# $self->namespace(  )
#-----------------------------------------------------------------
sub namespace {
    return '[% stub_module %]';
} # END namespace

#-----------------------------------------------------------------
# $self->get_soap_ops
#-----------------------------------------------------------------
sub get_soap_ops {
    my $self = shift;

    return {
        soap_name      => '[% soap_name %]',
        location       => $self->location,
        namespace_base => '[% namespace_base %]',
        operations     => [
[% FOREACH op IN operations %]
            {
                name => '[% op.name %]',
                expects => [
[% FOREACH param IN op.expects %]
                    { name => '[% param.name %]', type => '[% param.type %]' },
[% END %]
                ],
                returns => [
[% FOREACH param IN op.returns %]
                    { name => '[% param.name %]', type => '[% param.type %]' },
[% END %]
                ],
            },
[% END %]
        ],
    };
} # END get_soap_ops
[% END %]
[% BLOCK soap_doc_advice %]
#-----------------------------------------------------------------
# $self->[% handler_method %](  )
#-----------------------------------------------------------------
sub [% handler_method %] {
[% arg_capture %]

    my $params = $self->params();  # easy way

[% FOREACH expected_param IN soap_params.expects %]
    my $[% expected_param.name %] = $params->{ [% expected_param.name %] };
[% END %]

# hard way:
#    my $xmlobj   = XML::LibXML->new();
#    my $dom      = $xmlobj->parse_string( $self->get_post_body() )
#            or return return_error( "Mal-formed XML request: $!" );
#
[% FOREACH expected_param IN soap_params.expects %]
#    my ( $[% expected_param.name %]_node ) = $dom->getElementsByLocalName( '[% expected_param.name %]' );
#    my $[% expected_param.name %]          = $[% expected_param.name %]_node->textContent;
[% END %]

[% FOREACH returned_param IN soap_params.returns %]
    my $[% returned_param.name %];
[% END %]

    my $time = $self->soap_current_time();

    my $ret_struct = [
        {
            GantrySoapServiceResponse => [
[% FOREACH returned_param IN soap_params.returns %]
                { [% returned_param.name %] => $[% returned_param.name %] },
[% END %]
            ]
        }
    ];

    $self->soap_namespace_set(
        'http://usegantry.org/soapservice'
    );

    return $self->soap_out( $ret_struct, 'internal', 'pretty' );
} # END [% handler_method %]
[% END %]
EO_TT_blocks

#-----------------------------------------------------------------
#   Methods in the B::C::Gantry package
#-----------------------------------------------------------------

sub what_do_you_make {
    return [
        [ 'lib/AppName.pm'       => 'Base module stub [safe to change]'    ],
        [ 'lib/AppName/*.pm'     => 'Controller stubs [safe to change]'    ],
        [ 'lib/AppName/GEN/*.pm' => 'Generated code [please, do not edit]' ],
    ];
}

sub backend_block_keywords {
    return [
        { keyword => 'no_gen',
          label   => 'No Gen',
          descr   => 'Skip everything for this backend',
          type    => 'boolean' },

        { keyword => 'run_test',
          label   => 'Run Tests',
          descr   => 'Makes tests which hit pages via a simple server',
          type    => 'boolean',
          default => 'true' },

        { keyword => 'full_use',
          label   => 'Full Use Statement',
          descr   => 'use Gantry qw( -Engine=... ); [defaults to false]',
          type    => 'boolean',
          default => 'false' },

        { keyword => 'dbix',
          label   => 'For use with DBIx::Class',
          descr   => 'Makes controllers usable with DBIx::Class',
          type    => 'boolean',
          default => 'false' },

        { keyword => 'template',
          label   => 'Alternate Template',
          descr   => 'A custom TT template.',
          type    => 'text' },
    ];
}

sub setup_template {
    my $class         = shift;
    my $template_text = shift || $default_template_text;

    return if ( $template_is_setup );

    Inline->bind(
        TT                  => $template_text,
        POST_CHOMP          => 1,
        TRIM_LEADING_SPACE  => 0,
        TRIM_TRAILING_SPACE => 0,
    );

    $template_is_setup = 1;
}

sub gen_Control {
    my $class       = shift;
    my $build_dir   = shift;
    my $bigtop_tree = shift;

    my $app_name            = $bigtop_tree->get_appname();
    my $lookup              = $bigtop_tree->{application}{lookup};
    my $app_stmnts          = $lookup->{app_statements};
    my $authors             = $bigtop_tree->get_authors();
    my $contact_us          = $bigtop_tree->get_contact_us();
    my @external_modules;
    my $copyright_holder    = $bigtop_tree->get_copyright_holder();
    my $license_text        = $bigtop_tree->get_license_text();
    my $config              = $bigtop_tree->get_config();
    my $config_block        = $config->{Control};

    my $full_use_statement = 0;
    if ( defined $config_block->{full_use} and $config_block->{full_use} ) {
        $full_use_statement = 1;
    }

    @external_modules    = @{ $app_stmnts->{uses} }
            if defined ( $app_stmnts->{uses} );

    my $year                = ( localtime )[5];
    $year                  += 1900;

    my ( $module_dir, @sub_dirs )
                    = Bigtop::make_module_path( $build_dir, $app_name );

    # First, make one controller for each controller block in the bigtop_file
    # collect the names of all the controllers and their models.
    my $sub_modules = $bigtop_tree->walk_postorder(
        'output_controllers',
        {
            module_dir       => $module_dir,
            app_name         => $app_name,
            lookup           => $lookup,
            tree             => $bigtop_tree,
            authors          => $authors,
            contact_us       => $contact_us,
            copyright_holder => $copyright_holder,
            license_text     => $license_text,
            year             => $year,
            sub_modules      => undef,
        },
    );

    # Second, make the main modules.
    my $app_configs     = $bigtop_tree->{application}{lookup}{configs};
    my $config_values   = $bigtop_tree->get_app_configs;
    my $base_controller = $bigtop_tree->walk_postorder( 'base_controller' );

    my ( $all_configs, $accessor_configs )
                          = build_config_lists( $app_configs, $config_values );

    my $config_accessors  =
        Bigtop::Backend::Control::Gantry::config_accessors(
            { configs => $accessor_configs, }
        );

    my @pod_methods = map { $_, "set_$_" } @{ $accessor_configs };

    my $init_sub          = build_init_sub( $accessor_configs );

    # now form nav links
    my $location  = $bigtop_tree->walk_postorder( 'output_location'  )->[0];
    my $nav_links = $bigtop_tree->walk_postorder(
            'output_nav_links', $location
    );

    my @pages;
    foreach my $nav_link ( @{ $nav_links } ) {
        my %nav_pair = @{ $nav_link };
        push @pages, \%nav_pair;
    }

    my( $base_model, $dbix ) = ( '', '' );
    if ( $config_block->{ dbix } ) {
        $base_model = $app_name . '::Model';
        $dbix       = 1;
    }
    
    if ( defined $base_controller->[0] and $base_controller->[0] ) {
        # warn "skipping previously generated modules\n";
        $bigtop_tree->walk_postorder(
            'output_controllers',
            {
                module_dir         => $module_dir,
                app_name           => $app_name,
                lookup             => $lookup,
                tree               => $bigtop_tree,
                authors            => $authors,
                contact_us         => $contact_us,
                copyright_holder   => $copyright_holder,
                license_text       => $license_text,
                year               => $year,
                sub_modules        => $sub_modules,
                full_use_statement => $full_use_statement,
                init_sub           => $init_sub,
                config_accessors   => $config_accessors,
                dbix               => $dbix,
                base_model         => $base_model,
                methods            => \@pod_methods,
                pages              => \@pages,
                %{ $config },
            },
        );
    }
    else { # spoof up a base_controller block, if they don't provide one
        my $base_module_name  = pop @sub_dirs;
        my $base_module_file  = File::Spec->catfile(
                $build_dir, 'lib', @sub_dirs, "$base_module_name.pm"
        );
        my $gen_base_module_name = "GEN$base_module_name";
        my $gen_base_module_file = File::Spec->catfile(
                $build_dir, 'lib', @sub_dirs, "$gen_base_module_name.pm"
        );
        my $gen_package_name = join '::', @sub_dirs, $gen_base_module_name;

        # remember the pod

        unshift @pod_methods, qw( namespace init do_main site_links );

        if ( $config_block->{ dbix } ) {
            unshift @pod_methods, 'schema_base_class';
        }

        my $pod               = Bigtop::Backend::Control::Gantry::pod(
            {
                package_name     => $app_name,
                gen_package_name => $gen_package_name,
                methods          => \@pod_methods,
                other_module_text=> 'SEE ALSO',
                used_modules     => [ 'Gantry',
                                      $gen_package_name,
                                      @{ $sub_modules } ],
                authors          => $authors,
                contact_us       => $contact_us,
                copyright_holder => $copyright_holder,
                license_text     => $license_text,
                sub_module       => 0,
                year             => $year,
            }
        );

        my $base_module_content =
            Bigtop::Backend::Control::Gantry::base_module(
                {
                    dist_name          => $base_module_name,
                    app_name           => $app_name,
                    gen_package_name   => $gen_package_name,
                    external_modules   => \@external_modules,
                    sub_modules        => $sub_modules,
                    init_sub           => $init_sub,
                    config_accessors   => $config_accessors,
                    pod                => $pod,
                    full_use_statement => $full_use_statement,
                    pages              => \@pages,
                    %{ $config },                # Go fish!
                }
            );

        eval {
            no warnings qw( Bigtop );
            Bigtop::write_file(
                $base_module_file, $base_module_content, 'no_overwrite'
            );
        };
        warn $@ if ( $@ );

        my $gen_pod = Bigtop::Backend::Control::Gantry::gen_pod(
            {
                package_name     => $app_name,
                gen_package_name => $gen_package_name,
                methods          => \@pod_methods,
                other_module_text=> 'SEE ALSO',
                used_modules     => [ 'Gantry',
                                      $gen_package_name,
                                      @{ $sub_modules } ],
                authors          => $authors,
                contact_us       => $contact_us,
                copyright_holder => $copyright_holder,
                license_text     => $license_text,
                sub_module       => 0,
                year             => $year,
            }
        );

        my $gen_base_content =
            Bigtop::Backend::Control::Gantry::gen_base_module(
                {
                    dist_name          => $base_module_name,
                    app_name           => $app_name,
                    gen_package_name   => $gen_package_name,
                    external_modules   => \@external_modules,
                    sub_modules        => $sub_modules,
                    init_sub           => $init_sub,
                    config_accessors   => $config_accessors,
                    gen_pod            => $gen_pod,
                    full_use_statement => $full_use_statement,
                    dbix               => $dbix,
                    base_model         => $base_model,
                    pages              => \@pages,
                    %{ $config },                # Go fish!
                }
            );

        eval {
            no warnings qw( Bigtop );
            Bigtop::write_file( $gen_base_module_file, $gen_base_content );
        };
        warn $@ if ( $@ );
    }

    # finally, make the tests
    # start with the use test (compile test for all controllers)
    my $test_dir  = File::Spec->catdir( $build_dir, 't' );
    my $test_file = File::Spec->catfile( $test_dir, '01_use.t' );

    mkdir $test_dir;

    unshift @{ $sub_modules }, $app_name;

    my $module_count = @{ $sub_modules };

    my $test_file_content = Bigtop::Backend::Control::Gantry::test_file(
        {
            modules      => $sub_modules,
            module_count => $module_count,
        }
    );

    eval { Bigtop::write_file( $test_file, $test_file_content ); };
    warn $@ if ( $@ );

    # now make the pod and pod coverage tests
    my $pod_test_file       = File::Spec->catfile( $test_dir, '02_pod.t' );
    my $pod_cover_test_file = File::Spec->catfile(
            $test_dir, '03_podcover.t'
    );

    my $pod_test_content       =
            Bigtop::Backend::Control::Gantry::pod_test( {} );
    my $pod_cover_test_content =
            Bigtop::Backend::Control::Gantry::pod_cover_test( {} );

    eval {
        no warnings qw( Bigtop );
        Bigtop::write_file(
                $pod_test_file, $pod_test_content, 'no overwrite'
        );
    };
    warn $@ if ( $@ );

    eval {
        no warnings qw( Bigtop );
        Bigtop::write_file(
                $pod_cover_test_file, $pod_cover_test_content, 'no overwrite'
        );
    };
    warn $@ if ( $@ );

    # finally, make the run test, unless they asked not to
    if ( not defined $config_block->{ run_test }
            or
         $config_block->{ run_test } )
    {

        # ...first, prepare the configs
        my @configs;
        my $saw_root = 0;

        APP_CONFIG:
        foreach my $var ( sort keys %{ $config_values->{ base } } ) {

            next APP_CONFIG if $var eq 'dbconn';

            my $value = $config_values->{ base }{ $var };
            if ( ref $value ) {
                ( $value ) = keys %{ $value };
            }
            push @configs, [ $var, $value ];

            $saw_root++ if $var eq 'root';
        }
        unshift @configs, [ 'dbconn', 'dbi:SQLite:dbname=app.db' ];
        push @configs, [ 'root', 'html:html/templates' ] unless $saw_root;

        # ...then, the locations
        my $locations = $bigtop_tree->walk_postorder(
                'output_test_locations', $lookup
        );
        my $num_tests = @{ $locations };

        my $run_test_file = File::Spec->catfile( $test_dir, '10_run.t' );
        my $run_test_content = Bigtop::Backend::Control::Gantry::run_test(
            {
                app_name  => $app_name,
                configs   => \@configs,
                locations => $locations,
                num_tests => $num_tests,
                %{ $config }, # fish for template engine name
            }
        );

        eval {
            no warnings qw( Bigtop );
            Bigtop::write_file(
                    $run_test_file, $run_test_content,
            );
        };
        warn $@ if ( $@ );

    }
}

sub build_init_sub {
    my $configs     = shift;

    my $arg_capture =
        Bigtop::Backend::Control::Gantry::arg_capture_st_nick_style(
            { args => [ qw( $self $r ) ] }
        );

    my $body = Bigtop::Backend::Control::Gantry::init_method_body(
        {
            arg_capture => $arg_capture,
            configs     => $configs,
        }
    );

    my $method = Bigtop::Backend::Control::Gantry::gen_controller_method(
        {
            method_name  => 'init',
            child_output => {
                body     => $body,
                doc_args => [ '$r' ],
            },
        }
    );

    $method =~ s/^\s+//;
    $method =~ s/^/#/gm if ( @{ $configs } == 0 ); # no configs, comment it out

    return "$method\n";
}

sub build_config_lists {
    my $app_configs   = shift;
    my $config_values = shift;

    my @accessor_configs;
    my @all_configs;

    SET_VAR:
    foreach my $config ( keys %{ $app_configs } ) {

        if ( defined $config_values ) {
            next SET_VAR unless defined $config_values->{ base }{ $config };
        }

        push @all_configs, $config;

        my $item = $app_configs->{$config}[0];

        if ( ref( $item ) =~ /HASH/ ) {

            my ( $value, $condition ) = %{ $item };

            next SET_VAR if $condition eq 'no_accessor';
        }

        push @accessor_configs, $config;
    }

    return \@all_configs, \@accessor_configs;
}

#-----------------------------------------------------------------
#   Packages named in the grammar
#-----------------------------------------------------------------

package # application
    application;
use strict; use warnings;

sub output_test_locations {
    my $self         = shift;
    my $child_output = shift;
    my $lookup       = shift;

    my $app_name      = $self->get_name();
    my $base_location = '/';

    my @retval;

    # we only skip the test if there is an explicit, true, skip test statement
    my $skip_base_test  = 0;
    my $base_controller = $lookup->{ controllers }{ base_controller };

    if ( defined $base_controller ) {
        my $skip_test  = $base_controller->{ statements }{ skip_test };
        if ( defined $skip_test ) {
            $skip_base_test = $skip_test->[0];
        }
    }

    push @retval, [ $base_location, $app_name ] unless $skip_base_test;

    while ( @{ $child_output } ) {
        my ( $loc_type ) = shift @{ $child_output };

        my $data = shift @{ $child_output };
        my ( $location, $module ) = @{ $data };

        if ( $loc_type eq 'rel_location' ) {
            $location = $base_location . $location;
        }

        $module = $app_name . '::' . $module;

        push @retval, [ $location, $module ];
    }

    return \@retval;
}

package # join_table
    join_table;
use strict; use warnings;

sub output_field_names {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return unless $self->{__NAME__} eq $data->{table_of_interest};

    return $child_output;
}

package # table_block
    table_block;
use strict; use warnings;

sub output_field_names {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return unless $self->{__TYPE__} eq 'tables';

    return unless $self->{__NAME__} eq $data->{table_of_interest};

    return $child_output;
}

package # table_element_block
    table_element_block;
use strict; use warnings;

sub output_field_names {
    my $self = shift;

    return unless $self->{__TYPE__} eq 'field';

    return [ $self->{__NAME__} ];
}

package # controller_block
    controller_block;
use strict; use warnings;

use Bigtop;

my %magical_uses = (
    CRUD     => 'Gantry::Plugins::CRUD',
    AutoCRUD => 'Gantry::Plugins::AutoCRUD',
    stub     => '',
);
my %magical_gen_uses = (
#    SOAP     => 'Gantry::Plugins::SOAP::RPCMP',
);

sub get_package_name {
    my $self = shift;
    my $data = shift;

    return $data->{app_name} . '::' . $self->get_name();
}

sub get_gen_package_name {
    my $self = shift;
    my $data = shift;

    if ( $self->is_base_controller ) {
        my @pieces      = split /::/, $data->{ app_name };
        my $module_name = 'GEN' . pop @pieces;
        return join '::', @pieces, $module_name;
    }
    else {
        return $data->{app_name} . '::GEN::' . $self->get_name();
    }
}

# this on is for walk_postorder use
sub base_controller {
    my $self = shift;

    return [ 1 ] if ( $self->is_base_controller );
}

sub skip_base_controller {
    my $self = shift;

    return unless $self->is_base_controller;

    #warn "I'm the base controller\n";

    return;
}

sub output_extra_use {
    my $self   = shift;
    my $type   = shift;
    my $module = $magical_uses{ $type } || return;

    my $poser  = {
        __ARGS__ => [ $module ]
    };
    bless $poser, 'controller_statement';

    my %extra_use = @{ $poser->uses };

    my $output    = $extra_use{ uses_output };

    return ( $output, $module );
}

sub output_extra_gen_use {
    my $self   = shift;
    my $type   = shift;
    my $module = $magical_gen_uses{ $type } || return;

    my $poser  = {
        __ARGS__ => [ $module ]
    };
    bless $poser, 'controller_statement';

    my %extra_use = @{ $poser->uses };

    my $output    = $extra_use{ uses_output };

    return ( $output, $module );
}

sub output_controllers {
    my $self         = shift;
    shift;
    my $data         = shift;

    if ( $self->is_base_controller ) { # if its the base, we need the subs
        return unless defined $data->{ sub_modules };
    }
    else { # if we have the subs, we don't need them again
        return if     defined $data->{ sub_modules };
    }

    my $model_alias  = $self->walk_postorder( 'get_model_alias' )->[0];

    $data->{ model_alias } = $model_alias;

    my $child_output = $self->walk_postorder( 'output_controller', $data );

    # generate the content of the controller and its GEN module
    my $short_name            = $self->get_name();
    my $package_name          = $self->get_package_name( $data );
    my $gen_package_name      = $self->get_gen_package_name( $data );

    # skip it if we can
    my $statements = $data->{lookup}{controllers}{$short_name}{statements};

    return if ( defined $statements->{no_gen} and $statements->{no_gen}[0] );

    # Begin by inserting magical things based on controller type
    my $controller_type = $self->get_controller_type();
    my ( $extra_use, $extra_module )
            = $self->output_extra_use( $controller_type );

    my ( $gen_extra_use, $gen_extra_module )
            = $self->output_extra_gen_use( $controller_type );

    #############################################
    # Deal with what the children made for us.  #
    #############################################
    my ( $output_str, $class_access, $gen_output_str, $output_hash )
            = _extract_output_from( $child_output );

    my $stub_method_names = $output_hash->{stub_method_name};
    my $gen_method_names  = $output_hash->{gen_method_name};
    my $crud_doc_methods  = $output_hash->{crud_doc_methods};
    my $soap_style        = _extract_soap_style(
                                $output_hash->{ soap_style }
                            );

    # gen_method_names is an array ref of names or undef if there are none

    # build beginning of dependencies section (the base app and the GEN
    # if it has methods)
    my @depend_head = ( $data->{app_name} )
            unless ( $self->is_base_controller );

    push @depend_head, $gen_package_name
            if ( defined $gen_method_names
                    or
                 defined $output_hash->{ extra_stub_method_name }
            );

    unshift @{ $output_hash->{used_modules} }, \@depend_head;

    my $used_modules      = _flatten( $output_hash->{used_modules} );

    if ( $extra_use ) {
        push @{ $used_modules }, $extra_module;
        chomp $extra_use;
        $output_str       = "\n$extra_use" . $output_str;
    }

    if ( $gen_extra_use ) {
        push @{ $used_modules }, $gen_extra_module;
        chomp $gen_extra_use;
        $gen_output_str   = "\n$gen_extra_use" . $gen_output_str;
    }

    # deal with SOAP rpc stubs
    if ( defined $output_hash->{ extra_stub_method_name } ) {
        push @{ $stub_method_names },
             @{ $output_hash->{ extra_stub_method_name } };
    }

    # ... and SOAP wsdl method
    my $wsdl;
    if ( defined $output_hash->{ soap_params } ) {
        $wsdl = Bigtop::Backend::Control::Gantry::soap_methods(
            {
                operations     => $output_hash->{ soap_params },
                soap_name      => $statements->{ soap_name }[0],
                namespace_base => $statements->{ namespace_base }[0],
                stub_module    => $package_name,
            }
        );
        if ( $wsdl ) {
            push @{ $gen_method_names }, qw( namespace get_soap_ops );
        }
    }

    # make doc stubs for standard controller accessor methods
    if ( defined $statements->{controls_table} ) {
        push @{ $stub_method_names }, qw( get_model_name text_descr );
    }

    my $config_block = $data->{ tree }->get_config()->{ Control };
    if ( $config_block->{ dbix } ) {

        push @{ $stub_method_names }, qw( get_orm_helper );

        if ( $self->is_base_controller ) {
            push @{ $gen_method_names  }, qw( schema_base_class );
        }
    }

    # make the gen use statement if it has methods
    my $gen_use_statement;
    if ( defined $gen_method_names ) {
        $gen_use_statement = Bigtop::Backend::Control::Gantry::use_stub(
            { module => $gen_package_name, imports => $gen_method_names }
        );
    }

    my $export_array          = Bigtop::Backend::Control::Gantry::export_array(
            { exported_subs => $gen_method_names }
    );

    my $loc_configs = $data->{lookup}{controllers}{$short_name}{configs};
    my ( $all_configs, $accessor_configs ) =
            Bigtop::Backend::Control::Gantry::build_config_lists(
                $loc_configs
            );

    my $init_sub;
    if ( @{ $accessor_configs } ) {
        $init_sub = Bigtop::Backend::Control::Gantry::build_init_sub(
            $accessor_configs
        );
    }

    my $config_accessors;
    if ( @{ $accessor_configs } ) {
        $config_accessors = Bigtop::Backend::Control::Gantry::config_accessors(
            { configs => $accessor_configs, }
        );
    }

    my $inherit_from;
    my $other_module_text  = 'DEPENDENCIES';

    my @pack_pieces;
    my $base_name;

    if ( $self->is_base_controller ) {
        @pack_pieces       = split /::/, $data->{ app_name };
        $base_name         = pop @pack_pieces;
        $base_name        .= '.pm';

        $inherit_from      = 'Gantry';  # only a default
        $other_module_text = 'SEE ALSO';

        $package_name      = $data->{ app_name };
        $used_modules      = [ 'Gantry' ];
        if ( $gen_method_names ) {
            push @{ $used_modules }, $gen_package_name;
        }
        # now push in any modules from uses statements
    }
    else {
        @pack_pieces  = split /::/, $short_name;
        $base_name    = pop @pack_pieces;
        $base_name   .= '.pm';

        $inherit_from = $data->{ app_name };
    }

    if ( defined $gen_method_names ) {  # in either case, use GEN if available
        $inherit_from = $gen_package_name;
    }

    my $all_gen_methods = $gen_method_names;

    if ( $data->{ init_sub } ) {
        # unshift has side effect of defining array if not defined
        unshift @{ $gen_method_names }, qw( namespace init );

        $all_gen_methods = [
                @{ $gen_method_names },
                @{ $data->{ methods } },
        ];
    }

    if ( defined $crud_doc_methods ) {
        foreach my $method_set ( @{ $crud_doc_methods } ) {
            push @{ $stub_method_names }, @{ $method_set };
        }
    }

    if ( not $self->is_base_controller()
                and
         defined $statements->{plugins} and $statements->{plugins}[0]
    ) {
            push @{ $all_gen_methods }, 'namespace';
    }

    my $pod                 = Bigtop::Backend::Control::Gantry::pod(
        {
            app_name         => $data->{app_name}, 
            accessors        => $accessor_configs,
            package_name     => $package_name,
            methods          => $stub_method_names,
            gen_package_name =>
                ( defined $all_gen_methods ) ? $gen_package_name : undef,
            mixins           => $all_gen_methods,
            other_module_text=> $other_module_text,
            used_modules     => $used_modules,
            authors          => $data->{authors},
            contact_us       => $data->{contact_us},
            copyright_holder => $data->{copyright_holder},
            license_text     => $data->{license_text},
            sub_module       => ( not $self->is_base_controller ),
            sub_modules      => $data->{sub_modules},
            year             => $data->{year},
        }
    );

    my $output;
    my $gen_pod;
    my $gen_output;

    if ( $self->is_base_controller ) {
        $output = Bigtop::Backend::Control::Gantry::base_module(
            {
                package_name      => $package_name,
                gen_package_name  => $inherit_from,
                gen_use_statement => $gen_use_statement,
                child_output      => $output_str,
                class_accessors   => $class_access,
                pod               => $pod,
                config_accessors  => $config_accessors,
                %{ $data },
            }
        );
        $gen_pod =
            Bigtop::Backend::Control::Gantry::gen_pod(
            {
                package_name     => $data->{ app_name },
                gen_package_name => $gen_package_name,
                other_module_text=> 'SEE ALSO',
                used_modules     => [ 'Gantry',
                                      $gen_package_name,
                                      @{ $data->{ sub_modules } } ],
                sub_module       => 0,
                %{ $data },
                methods          => $all_gen_methods,
            }
            # these are in $data: authors, contact_ud, copyright_holder,
            # license_text, year, and app_name
        );
        $gen_output = Bigtop::Backend::Control::Gantry::gen_base_module(
            {
                child_output       => $gen_output_str,
                gen_package_name   => $gen_package_name,
                init_sub           => $init_sub,
                config_accessors   => $config_accessors,
                gen_pod            => $gen_pod,
                %{ $data },                # Go fish!
            }
        );
    }
    else {
        # deal with non-base controller plugins

        my $plugins;
        if ( defined $statements->{plugins} and $statements->{plugins}[0] ) {
            $plugins = join ', ', @{ $statements->{plugins} };
        }

        if ( $plugins ) {
            my $config            = $data->{ tree }->get_config();
            my $app_level_plugins = $config->{ plugins };
            $plugins              = "$app_level_plugins $plugins"
                                        if $app_level_plugins;

            $inherit_from         = $gen_package_name;
        }

        $output = Bigtop::Backend::Control::Gantry::controller_block(
            {
                app_name          => $data->{app_name},
                package_name      => $package_name,
                inherit_from      => $inherit_from,
                gen_use_statement => $gen_use_statement,
                child_output      => $output_str,
                class_accessors   => $class_access,
                pod               => $pod,
                sub_modules       => $data->{sub_modules},
                wsdl              => $wsdl,
                soap_style        => $soap_style,
            }
        );

        $gen_pod =
            Bigtop::Backend::Control::Gantry::gen_controller_pod(
            {
                package_name     => $package_name,
                gen_package_name =>
                    ( defined $all_gen_methods ) ? $gen_package_name : undef,
                gen_methods      => $all_gen_methods,
                sub_module       => 1,
            }
        );

        $gen_output = Bigtop::Backend::Control::Gantry::gen_controller_block(
            {
                app_name         => $data->{app_name},
                gen_package_name => $gen_package_name,
                package_name     => $package_name,
                child_output     => $gen_output_str,
                export_array     => $export_array,
                gen_pod          => $gen_pod,
                wsdl             => $wsdl,
                soap_style       => $soap_style,
                plugins          => $plugins,
                config_accessors => $config_accessors,
                init_sub         => $init_sub,
            }
        );
    }

    my $pm_file;
    my $gen_pm_file;
    my $retval;

    # put the content onto the disk
    if ( $self->is_base_controller ) {

        my $module_dir = $data->{ module_dir };

        # Example: module_dir = t/gantry/play/Apps-Checkbook/lib/Apps/Checkbook
        # we want to strip off the last dir and put our module names there:
        # t/gantry/play/Apps-Checkbook/lib/Apps/Checkbook.pm
        # t/gantry/play/Apps-Checkbook/lib/Apps/GENCheckbook.pm
        my @module_dir_pieces = File::Spec->splitdir( $module_dir );
        pop @module_dir_pieces;
        my $base_module_dir   = File::Spec->catdir( @module_dir_pieces );

        mkdir $base_module_dir;

        $pm_file       = File::Spec->catfile( $base_module_dir, $base_name );
        $gen_pm_file   = File::Spec->catfile(
                $base_module_dir, "GEN$base_name"
        );

        $retval        = [];
    }
    else {

        # ... first make sure the directories exist for this piece
        my $module_home  = File::Spec->catdir( $data->{module_dir} );
        foreach my $subdir ( @pack_pieces ) {
            $module_home = File::Spec->catdir( $module_home, $subdir );
            mkdir $module_home;
        }

        # ... then make sure GEN directories exist (similar plan)
        my $gen_home = File::Spec->catdir( $data->{module_dir}, 'GEN' );

        if ( defined $all_gen_methods ) {
            mkdir $gen_home;

            foreach my $subdir ( @pack_pieces ) {
                $gen_home = File::Spec->catdir( $gen_home, $subdir );
                mkdir $gen_home;
            }
        }

        $pm_file     = File::Spec->catfile( $module_home, $base_name);
        $gen_pm_file = File::Spec->catfile( $gen_home,    $base_name);

        $retval      = [ $package_name ];
    }

    # ... then write them
    eval {
        # Is the stub already present? Then skip it.
        no warnings qw( Bigtop );
        Bigtop::write_file( $pm_file,     $output,    'no overwrite' );
        if ( defined $all_gen_methods ) {
            Bigtop::write_file( $gen_pm_file, $gen_output );
        }
#        else {
#            warn "no gen to write $gen_pm_file\n";
#            warn $gen_output;
#        }
    };
    return if ( $@ );

    # tell postorder walker what we just built
    return $retval;
}

sub _flatten {
    my $input = shift;

    my @output;

    foreach my $element ( @{ $input } ) {
        push @output, @{ $element };
    }

    return \@output;
}

sub _extract_output_from {
    my $child_output = shift;

    my %all_output;

    # extract from the individual child output lists
    foreach my $output_list ( @{ $child_output } ) {
        my $output_hash = { @{ $output_list } };

        foreach my $type ( keys %{ $output_hash } ) {
            next unless defined $output_hash->{ $type };
            push @{ $all_output{ $type } }, $output_hash->{ $type };
        }
    }

    # join the results
    my $empty_string = '';
    my $output       = $empty_string;
    my $class_access = $empty_string;
    my $gen_output   = $empty_string;

    # make sure uses are near the top
    if ( defined $all_output{uses_output} ) {
        $output       .= join $empty_string, @{ $all_output{uses_output}  };
    }

    if ( defined $all_output{uses_gen_output} ) {
        $gen_output   .= join $empty_string, @{ $all_output{uses_gen_output} };
    }

    # then get the rest
    if ( defined $all_output{output} ) {
        $output       .= join $empty_string, @{ $all_output{output}       };
    }

    if ( defined $all_output{gen_output} ) {
        $gen_output   .= join $empty_string, @{ $all_output{gen_output}   };
    }

    if ( defined $all_output{class_access} ) {
        $class_access .= join $empty_string, @{ $all_output{class_access} };
    }

    return (
        $output,
        $class_access,
        $gen_output,
        \%all_output,
    );
}

sub _extract_soap_style {
    my $soap_styles = shift;

    return unless ref $soap_styles eq 'ARRAY';

    my %soap_styles = map { $_ => 1 } @{ $soap_styles };

    if ( keys %soap_styles > 1 ) {
        die "Mixing SOAP styles is not supported by Bigtop.\n";
    }
    else {
        return 'RPC' if defined $soap_styles{ 'SOAP' };
        return 'Doc' if defined $soap_styles{ 'SOAPDoc' };
        return undef;
    }
}

sub output_nav_links {
    my $self          = shift;
    my $child_output  = shift;
    my $base_location = shift || '';

    my %retval        = @{ $child_output };

    if ( defined $retval{ label } and $retval{ label } ) {

        if ( $self->is_base_controller ) {
            push @{ $child_output }, 'link', $base_location;
        }

        return [ $child_output ];
    }
    else {
        return [];
    }
}

sub output_test_locations {
    my $self         = shift;
    my $child_output = shift;
    my $lookup       = shift;

    return if ( $self->is_base_controller );

    my %child_output = @{ $child_output};

    my @keys = keys %{ $self };

    my $controller_statements = $lookup->{ controllers }
                                         { $self->{__NAME__} }
                                         { statements };

    if ( defined $controller_statements->{ skip_test}
                and
         $controller_statements->{ skip_test}
    ) {
        return;
    }

    my @retval;

    # add my name to the data going up
    foreach my $loc_type ( keys %child_output ) {
        push @retval,
            $loc_type => [
                $child_output{ $loc_type } => $self->{ __NAME__ }
            ];
    }

    return \@retval;
}

# controller_statement

package # controller_statement
    controller_statement;
use strict; use warnings;

sub output_controller {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my $keyword      = $self->{__KEYWORD__};

    return unless Bigtop::Backend::Control->is_controller_keyword( $keyword );

    return [ $self->$keyword( $child_output, $data ) ];
}

sub _form_uses {
    my $self = shift;

    my @output;
    my @used_modules;

    foreach my $module ( @{ $self->{__ARGS__} } ) {

        if ( ref( $module ) eq 'HASH' ) {
            my ( $used, $import ) = %{ $module };
            my $use_statement =
                    Bigtop::Backend::Control::Gantry::explicit_use_stub(
                        {
                            module      => $used,
                            import_list => $import,
                        }
                    );
            chomp $use_statement;
            push @output, $use_statement;
            $module = $used;
        }

        else {
            my @exported;
            eval {
                my $module_path = $module;
                $module_path    =~ s{::}{/}g;
                require "$module_path.pm";
            };

            if ( $@ ) {
                push @output, Bigtop::Backend::Control::Gantry::use_stub(
                        { module => $module, }
                );
            }
            else {
                {
                    no strict 'refs';
                    @exported = @{"$module\::EXPORT"};
                }
                if ( @exported ) {
                    push @output, Bigtop::Backend::Control::Gantry::use_stub(
                            { module => $module, imports => \@exported }
                    );
                }
                else {
                    push @output, Bigtop::Backend::Control::Gantry::use_stub(
                            { module => $module }
                    );
                }
            }
        }

        push @used_modules, $module;
    }

    my $output = join "\n", @output;
    $output   .= "\n\n";

    return $output, \@used_modules;
}

sub uses {
    my $self         = shift;

    my ( $output, $used_modules ) = $self->_form_uses();

    return [
        uses_output     => $output,
        uses_gen_output => $output,
        used_modules    => $used_modules,
    ];
}

sub stub_uses {
    my $self         = shift;

    my ( $output, $used_modules ) = $self->_form_uses();

    return [
        uses_output     => $output,
        used_modules    => $used_modules,
    ];
}

sub gen_uses {
    my $self         = shift;

    my ( $output, $used_modules ) = $self->_form_uses();

    return [
        uses_gen_output => $output,
        used_modules    => $used_modules,
    ];
}

sub is_crud {
    my $self = shift;
    my $data = shift;

    my $controller_name  = $self->get_controller_name;
    my $controller_type  = $data->{lookup}
                                  {controllers}
                                  {$controller_name}
                                  {type}
                         || 'stub';

    return ( $controller_type eq 'CRUD' );
}

sub is_dbix_class {
    my $self         = shift;
    my $data         = shift;
    my $config_block = $data->{ tree }->get_config()->{ Control };

    return $config_block->{ dbix };
}

sub get_model_alias {
    my $self = shift;

    return unless $self->{ __KEYWORD__ } eq 'controls_table';

    my $alias = uc $self->{ __ARGS__ }[0];
    $alias    =~ s/\./_/;

    return [ $alias ];
}

sub controls_table {
    my $self             = shift;
    my $child_output     = shift;
    my $data             = shift;
    my $table            = $self->{__ARGS__}[0];

    $table               =~ s/\./_/;

    my $model            = "$data->{app_name}\::Model::$table";

    my $model_alias      = $data->{ model_alias };

    my $output           = Bigtop::Backend::Control::Gantry::use_stub(
        { module => $model, imports => "\$$model_alias" }
    );
    my $gen_output       = $output;

    my $class_access     = '';

    unless ( $self->is_crud( $data ) ) {
        $class_access     = Bigtop::Backend::Control::Gantry::class_access(
            { model_alias => $model_alias }
        );

        if ( $self->is_dbix_class( $data ) ) {
            my $helper = 'Gantry::Plugins::AutoCRUDHelper::DBIxClass';
            my $controller = $self->get_controller_name();

            if ( defined $data->{ tree }
                                { application     }
                                { lookup          }
                                { controllers     }
                                { $controller     }
                                { statements      }
                                { autocrud_helper }
            ) {
                $helper = $data->{tree}
                                 { application     }
                                 { lookup          }
                                 { controllers     }
                                 { $controller     }
                                 { statements      }
                                 { autocrud_helper }
                                 [ 0 ];
            }

            $class_access .=
                Bigtop::Backend::Control::Gantry::get_orm_helper(
                    {
                        helper => $helper,
                    }
                );
        }
    }

    # This use statement goes in both stub and gen output.
    return [
        uses_output     => $output,
        uses_gen_output => $gen_output,
        class_access    => $class_access,
        used_modules    => [ $model ],
    ];
}

sub text_description {
    my $self             = shift;
    my $child_output     = shift;
    my $data             = shift;
    my $description      = $self->{__ARGS__}[0];

    if ( $self->is_crud( $data ) ) {
        return;
    }
    else {
        my $output       = Bigtop::Backend::Control::Gantry::text_description(
            { description => $description }
        );

        return [
            class_access => $output,
        ];
    }
}

sub output_nav_links {
    my $self = shift;

    if ( $self->{__KEYWORD__} eq 'rel_location' ) {
        return [ link => $self->{__ARGS__}->get_first_arg() ]
    }
    elsif ( $self->{__KEYWORD__} eq 'location' ) {
        return [ link => $self->{__ARGS__}->get_first_arg() ]
    }

    if ( $self->{__KEYWORD__} eq 'page_link_label' ) {
        return [ label => $self->{__ARGS__}->get_first_arg() ]
    }

    return [];
}

sub output_test_locations {
    my $self         = shift;

    return unless ( $self->{ __KEYWORD__ } =~ /location/ );

    return [ $self->{ __KEYWORD__ } => $self->{ __ARGS__ }->get_first_arg, ];
}

package # controller_method
    controller_method;
use strict; use warnings;

sub output_controller {
    my $self = shift;
               shift;  # There's no child output, we're in the recursion base.
    my $data = shift;

    my $gen_package_name
            = $self->{__PARENT__}->get_gen_package_name( $data );

    my $base_name = $gen_package_name;
    $base_name    =~ s/.*:://;

    my $method_name  = $self->{__NAME__};
    my $type         = $self->{__TYPE__};
    my $method_body  = $self->{__BODY__};

    my $controller_statements
                     = $data->{lookup}
                              {controllers}
                              {$base_name}
                              {statements};

    my $statements   = $data->{lookup}
                              {controllers}
                              {$base_name}
                              {methods}
                              {$method_name}
                              {statements};

    return if ( $statements->{no_gen} );

    # restart recursion based on method type
    unless ( $method_body->can( "output_$type" ) ) {
        die "Error: bad type '$type' for method '$method_name'\n"
            . "in controller '$base_name'\n";
    }

    my $child_output = $method_body->walk_postorder( "output_$type", $data );

    if ( $child_output ) {
        $child_output = { @{ $child_output } };
    }

    my $stub_method_name;
    if ( $type eq 'stub' ) {
        $stub_method_name = $self->{__NAME__};
    }
    elsif ( defined $child_output->{ stub_method_name } ) {
        $stub_method_name = $child_output->{ stub_method_name };
    }

    my $gen_method_name;
    if ( defined $child_output->{gen_output}
            and
        $child_output->{gen_output}{body} )
    {
        $gen_method_name = $self->{__NAME__};
    }

    my ( $output, $gen_output );

    if ( $child_output->{gen_output} ) {
        $gen_output = Bigtop::Backend::Control::Gantry::gen_controller_method(
            {
                method_name  => $self->{__NAME__},
                child_output => $child_output->{gen_output},
            }
        );
    }

    if ( $child_output->{comment_output} ) {
        $output = Bigtop::Backend::Control::Gantry::controller_method(
            {
                method_name      => $self->{__NAME__},
                child_output     => $child_output->{comment_output},
                gen_package_name => $gen_package_name,
            }
        );
    }

    if ( $child_output->{ extra_comment_methods } ) {
        foreach my $method ( @{ $child_output->{ extra_comment_methods } } ) {
            $output .= Bigtop::Backend::Control::Gantry::controller_method(
                {
                    method_name      => $method,
                    gen_package_name => $gen_package_name,
                }
            );
        }
    }

    if ( $child_output->{stub_output} ) {
        $output .= Bigtop::Backend::Control::Gantry::gen_controller_method(
            {
                method_name  => $self->{__NAME__},
                child_output => $child_output->{stub_output},
            }
        );
    }

    my $extra_stub_method;
    my $crud_doc_methods;

    if ( $child_output->{ extra_for_stub } ) {
        $output .= "\n$child_output->{ extra_for_stub }{ full_sub }\n";
        $extra_stub_method = $child_output->{ extra_for_stub }{ name };
    }

    if ( $child_output->{crud_output} ) {
        my $crud_name    = $self->{__NAME__};
        $crud_name       =~ s/_form//;
        $crud_name     ||= 'crud';

        my $text_descr   = $controller_statements->{text_description}[0];
        my $model_alias  = $data->{model_alias};

        unless ( defined $model_alias and $model_alias ) {
            die "Error: controller $base_name is type CRUD but is missing\n"
                . "    it's controls table statement.\n";
        }

        my $with_perms = $self->{__PARENT__}->walk_postorder(
                'with_perms'
        )->[0];

        my $crud_helpers = Bigtop::Backend::Control::Gantry::crud_helpers(
            {
                form_method_name => $self->{__NAME__},
                crud_name        => $crud_name,
                text_descr       => $text_descr || 'missing text descr',
                model_alias      => $model_alias,
                with_perms       => $with_perms,
            }
        );

        $crud_doc_methods = _crud_doc_methods( $crud_helpers );

        my $form_method =
            Bigtop::Backend::Control::Gantry::gen_controller_method(
                {
                    method_name  => $self->{__NAME__},
                    child_output => $child_output->{crud_output},
                }
            );

        $output      = $crud_helpers;
        $gen_output .= $form_method;

        $output     .= Bigtop::Backend::Control::Gantry::controller_method(
            {
                method_name      => $self->{__NAME__},
                gen_package_name => $gen_package_name,
                child_output     => { doc_args => '$data' },
            }
        );

        $gen_method_name = $self->{__NAME__};
    }

    return [
        [
            gen_output       => $gen_output,
            output           => $output,
            stub_method_name => $stub_method_name,
            gen_method_name  => $gen_method_name,
            extra_stub_method_name => $extra_stub_method,
            soap_params      => $child_output->{ soap_params },
            soap_style       => ( $child_output->{ soap_params } )
                             ? $type
                             : undef,
            crud_doc_methods => $crud_doc_methods,
        ]
    ];
}

sub _crud_doc_methods {
    my $crud_output = shift;

    my @retval      = ( $crud_output =~ /^sub\s+(\S+)/msg );

    return \@retval;
}

package # method_body
    method_body;
use strict; use warnings;

sub get_table_name_for {
    my $self        = shift;
    my $lookup      = shift;
    my $name_of     = shift;

    my $table_name  = $self->get_table_name( $lookup );

    unless ( $table_name ) {
        die "Error: I can't generate main_listing in $name_of->{method} "
            . "of controller $name_of->{controller}.\n"
            . "  The controller did not have a 'controls_table' statement.\n";
    }

    $name_of->{table} = $table_name;
}

sub get_fields_from {
    my $self    = shift;
    my $lookup  = shift;
    my $name_of = shift;

    my $fields = $lookup->{tables}{ $name_of->{table} }{fields};

    unless ( $fields ) {
        die "Error: I can't generate main_listing for $name_of->{method} "
        .   "of controller $name_of->{controller}.\n"
        .   "  I can't seem to find the fields in the table for "
        .   "this controller.\n"
        .   "  I was looking for them in the table named '$name_of->{table}'.\n"
        .   "  Maybe that name is misspelled.\n";
    }

    return $fields;
}

sub get_field_for {
    my $col     = shift;
    my $fields  = shift;
    my $name_of = shift;

    my $field = $fields->{$col};

    # make sure there really is a field
    unless ( $field ) {
        die "Error: I couldn't find a field called '$col' in "
            .   "$name_of->{table}\'s field list.\n"
            .   "  Perhaps you misspelled '$col' in the definition of\n"
            .   "  method $name_of->{method} for controller "
            .   "$name_of->{controller}.\n";
    }

    return $field;
}

sub output_stub {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my $choices      = { @{ $child_output } };

    # set up args
    my ( $arg_capture, @doc_args )
            = _build_arg_capture( @{ $choices->{extra_args} } );

    return [
        stub_output => {
            body     => $arg_capture,
            doc_args => \@doc_args,
        }
     ];
}

sub output_base_links {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my $choices      = { @{ $child_output } };

    # set up args
    my ( $arg_capture, @doc_args )
            = _build_arg_capture( @{ $choices->{extra_args} } );

    my $title         = $choices->{title}[0]          || 'Main Listing';
    my $template      = $choices->{html_template}[0]  || 'main.tt';

    # set self vars for title/template etc.
    my $self_setup = Bigtop::Backend::Control::Gantry::self_setup(
        { title => $title, template => $template }
    );

    my $view_data = Bigtop::Backend::Control::Gantry::main_links(
        { pages => $data->{ pages } }
    );

    return [
        gen_output => {
            body     => "$arg_capture\n$self_setup\n$view_data",
            doc_args => \@doc_args,
        },
        comment_output => {
            doc_args => \@doc_args,
        }
    ];
}

sub output_hashref {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my $choices      = { @{ $child_output } };

    # set up args
    my ( $arg_capture, @doc_args )
            = _build_arg_capture( @{ $choices->{extra_args} } );

        
    my @literals;
    foreach my $literal ( @{ $choices->{literal} } ) {
        push( @literals, $literal );
    }
    
    my %authed_methods;
    if ( $choices->{authed_methods} ) {
        foreach my $pair ( @{ $choices->{authed_methods} } ) {
            my ( $key, $value ) = %{ $pair };
            $authed_methods{ $key } = $value;
        }
    }
    
    my @permissions;
    if ( $choices->{permissions} ) {
        foreach my $pair ( @{ $choices->{permissions} } ) {
            my ( $key, $value );
            
            if ( ref( $pair ) eq 'HASH' ) { ( $key, $value ) = %{ $pair }; }
            else                          {   $key           =    $pair;   }
    
            if ( $key !~ /[crud-]+/ or length( $key ) ne 12 ) {
                die "invalid permission bits, $key ( usage: crudcrudcrud )\n"
                    . "at " . $self->get_controller_name . "\n";
            }

            push( @permissions, $key );
            push( @permissions, $value );
        }
    }
    
    my $config_hashref = Bigtop::Backend::Control::Gantry::hashref(
        {
            authed_methods  => \%authed_methods,
            permissions => \@permissions,
            literals => \@literals,
        }
    );

    return [
        gen_output => {
            body     => "$arg_capture\n$config_hashref",
            doc_args => \@doc_args,
        },
        comment_output => {
            doc_args => \@doc_args,
        },
     ];
}

sub output_links {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my $choices      = { @{ $child_output } };

    # set up args
    my ( $arg_capture, @doc_args )
            = _build_arg_capture( @{ $choices->{extra_args} } );

    my @abs_pages;
    foreach my $page ( @{ $data->{ pages } } ) {
        my $abs_page;

        if ( $page->{ link } =~ m{^/} ) {
            $abs_page = {
                link => qq{'$page->{ link }'},
            },
        }
        else {
            $abs_page = {
                link => qq{\$self->app_rootp() . '/$page->{ link }'},
            };
        }
        $abs_page->{ label } = $page->{ label };
        push @abs_pages, $abs_page;
    }

    my $body = Bigtop::Backend::Control::Gantry::site_links(
        { pages => \@abs_pages }
    );

    return [
        gen_output => {
            body     => "$arg_capture\n$body",
#            body     => "$arg_capture\n$self_setup\n$view_data",
            doc_args => \@doc_args,
        },
        comment_output => {
            doc_args => \@doc_args,
        }
    ];
}

sub output_main_listing {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my $choices      = { @{ $child_output } };
    my @optional_args;

    # see if we are paging
    my $rows = $choices->{ rows }[0] || undef;
    if ( $choices->{ paged_conf }[0] ) {
        $rows = '$self->' . $choices->{ paged_conf }[0];
    }

    # see if we are limiting output rows by foreign key
    my $limit_by = $choices->{ limit_by }[0] || undef;
    if ( defined $limit_by ) {
        push @{ $choices->{ extra_args} }, '$' . $limit_by;
    }

    # set up args
    my ( $arg_capture, @doc_args )
            = _build_arg_capture( @{ $choices->{extra_args} } );

    # provide defaults
    my $title         = $choices->{title}[0]          || 'Main Listing';
    my $template      = $choices->{html_template}[0]  || 'results.tt';

    # set self vars for title/template etc.
    my $self_setup = Bigtop::Backend::Control::Gantry::self_setup(
        { title => $title, template => $template, with_real_loc => 1 }
    );

    # set up headings
    my @col_labels;
    my @cols;
    my @pseudo_cols;
    my @foreigners;
    my %name_of;

    $name_of{method}     = $self->get_method_name();
    $name_of{controller} = $self->get_controller_name();

    $self->get_table_name_for(           $data->{lookup}, \%name_of );

    my $fields = $self->get_fields_from( $data->{lookup}, \%name_of );

    foreach my $col ( @{ $choices->{cols} } ) {
        my $field = get_field_for( $col, $fields, \%name_of );

        # Push column onto pseudo_cols array if it's a requested pseudo column.
        if ($fields->{$col}{pseudo_value}) {
            push @pseudo_cols, { alias => $col, field => $fields->{$col}{pseudo_value}{args}[0] }
        }

        # get the field's label
        my $label;
        if ( defined $choices->{col_labels} and @{ $choices->{col_labels} } ) {
            my $element = shift @{ $choices->{col_labels} };
            if ( ref( $element ) =~ /HASH/ ) {
                my ( $text, $link ) = %{ $element };
                push @col_labels, { href => { text => $text, link => $link } };
            }
            else {
                push @col_labels, { simple => $element };
            }
        }
        else {
            $label = $fields->{$col}{label}{args}[0];
            unless ( $label ) {
                warn "Warning: I couldn't find the label for "
                    . "'$col' in $name_of{table}\'s fields.\n"
                    . "  Using '$col' as the label in method $name_of{method}"
                    . " of\n"
                    . "  controller $name_of{controller}.\n";

                $label = $col;
            }
            push @col_labels, { simple => $label };
        }

        # see if it's foreigner or has a special display method
        if ( defined $fields->{$col}{refers_to} ) {
            push @cols, "\$$col";
            push @foreigners, $col;
        }
        elsif ( defined $fields->{ $col }{ html_form_options } ) {
            push @cols, "\$row->${col}_display()";
        }
        else {
            push @cols, "\$row->$col";
        }
    }

    # Populate pseudo_cols array for any pseudo columns that weren't requested
    # in $choices->{cols}.
    foreach my $pseudo_col ( @{ $choices->{pseudo_cols} } ) {
        push @pseudo_cols, { alias => $pseudo_col, field => $fields->{$pseudo_col}{pseudo_value}{args}[0] }
    }

    # put options in the heading bar
    my $header_options = [];
    if ( $choices->{header_options} ) {
        my $url_suffix = ( defined $limit_by ) ? '$header_option_suffix' : '';

        my $perms;
        if ( $choices->{ header_option_perms } ) {
            $perms = $choices->{ header_option_perms }->one_hash();
        }

        $header_options = _build_options( 
            {
                options    => $choices->{header_options}, 
                url_suffix => $url_suffix,
                perms      => $perms,
            }
        );
    }

    my $heading = Bigtop::Backend::Control::Gantry::main_heading(
        {
            headings       => \@col_labels,
            header_options => $header_options,
            limit_by       => $limit_by,
        }
    );

    my $order_by;
    if ( $choices->{order_by} ) {
        $order_by = $choices->{order_by}[0];
    }

    # generate database retrieval
    my $row_options = [];
    if ( $choices->{row_options} ) {
        my $perms;
        if ( $choices->{ row_option_perms } ) {
            $perms = $choices->{ row_option_perms }->one_hash();
        }
        $row_options = _build_options(
            {
                options     => $choices->{ row_options }, 
                row_options => 1,
                perms       => $perms,
            }
        );
        #, '/$id' );
    }

    my @where_terms;
    if ( $choices->{ where_terms } ) {
        foreach my $where_term ( @{ $choices->{ where_terms } } ) {
            my ( $col_name, $value ) = %{ $where_term };
            push @where_terms, {
                col_name => $col_name,
                value    => $value,
            };
        }
    }

    my $main_table = Bigtop::Backend::Control::Gantry::main_table(
        {
            model           => $data->{model_alias},
            rows            => $rows,
            data_cols       => \@cols,
            pseudo_cols     => \@pseudo_cols,
            row_options     => $row_options,
            dbix            => $self->is_dbix_class( $data ),
            limit_by        => $limit_by,
            foreigners      => \@foreigners,
            livesearch      => $choices->{livesearch}[0],
            order_by        => $order_by,
            where_terms     => \@where_terms,
        }
    );

    # return the result
    # We must call the templates separately,  Inline::TT does not support
    # including one block inside another.  (Since each block is logically
    # a file and you can never call a block in another file with TT.
    # In reality the reason is a bit more subtle.  To call a block, with
    # Inline::TT, you need to call it as a function in the Bigtop::* class.
    # But inside the templates, you cannot call a Perl function without
    # enabling Perl code, which we don't want to do.)
    return [
        gen_output => {
            body     => "$arg_capture\n$self_setup\n$heading\n$main_table",
            doc_args => \@doc_args,
        },
        comment_output => {
            doc_args => \@doc_args,
        }
    ];
} # END output_main_listing

sub is_dbix_class {
    my $self         = shift;
    my $data         = shift;
    my $config_block = $data->{ tree }->get_config()->{ Control };

    return $config_block->{ dbix };
}

sub output_SOAP {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;
    my $choices      = { @{ $child_output } };

    my $extra_comment_methods;
    if ( not defined $data->{ WSDL_COMMENTS } ) {
        $extra_comment_methods = [ qw( namespace get_soap_ops ) ],

        $data->{ WSDL_COMMENTS } = 'done';
    }

    my $handler_method  = $self->get_method_name();
    ( my $internal_method = $handler_method ) =~ s/^do_//;

    my $extra_sub = Bigtop::Backend::Control::Gantry::SOAP_stub_method(
        {
            handler_method  => $handler_method,
            internal_method => $internal_method,
        }
    );

    my $soap_params = _extract_soap_params( $choices, $internal_method );

    return [
        extra_for_stub => {
            name     => $internal_method,
            full_sub => $extra_sub,
        },
        extra_comment_methods => $extra_comment_methods,
        soap_params => $soap_params,
        soap_style  => 'RPC',
    ];
}

sub output_SOAPDoc {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;
    my $choices      = { @{ $child_output } };

    my $extra_comment_methods;
    if ( not defined $data->{ WSDL_COMMENTS } ) {
        $extra_comment_methods = [ qw( namespace get_soap_ops ) ],

        $data->{ WSDL_COMMENTS } = 'done';
    }

    # set up args
    my ( $arg_capture, @doc_args )
            = _build_arg_capture( @{ $choices->{extra_args} } );

    my $handler_method  = $self->get_method_name();
    ( my $internal_method = $handler_method ) =~ s/^do_//;

    my $soap_params = _extract_soap_params( $choices, $internal_method );

    my $body_advice = Bigtop::Backend::Control::Gantry::soap_doc_advice(
        {
            arg_capture    => $arg_capture,
            soap_params    => $soap_params,
            handler_method => $handler_method,
        }
    );

    return [
        soap_style  => 'SOAPDoc',
        extra_for_stub => {
            name     => $handler_method,
            full_sub => $body_advice,
        },
        soap_params => $soap_params,
        extra_comment_methods => $extra_comment_methods,
    ];
}

sub _extract_soap_params {
    my $choices         = shift;
    my $internal_method = shift;

    my %soap_params;
    $soap_params{ name } = $internal_method;

    foreach my $expected ( @{ $choices->{ expects } } ) {
        if ( ref( $expected ) eq 'HASH' ) {
            my ( $name, $type ) = %{ $expected };
            push @{ $soap_params{ expects } },
                  { name => $name, type => $type };
        }
        else {
            push @{ $soap_params{ expects } },
                  { name => $expected, type => 'xsd:string' };
        }
    }

    foreach my $returned ( @{ $choices->{ returns } } ) {
        if ( ref( $returned ) eq 'HASH' ) {
            my ( $name, $type ) = %{ $returned };
            push @{ $soap_params{ returns } },
                  { name => $name, type => $type };
        }
        else {
            push @{ $soap_params{ returns } },
                  { name => $returned, type => 'xsd:string' };
        }
    }

    return \%soap_params;
}

# Given
#   [ Label => url, Label2 => url2, Label_no_url; ]
# Returns
#   [
#       { text => 'Label',       link => 'url'  },
#       { text => 'Label2',      link => 'url2' },
#       { text => 'Plain_Label', link => '$$self{location}/plain_label' },
#   ]
my %crud_type_for = (
    add    => 'create',
    create => 'create',
    view   => 'retrieve',
    edit   => 'update',
    udpate => 'update',
    delete => 'delete',
);
sub _build_options {
    my $opts        = shift;
    my $bigtop_args = $opts->{ options     };
    my $url_suffix  = $opts->{ url_suffix  };
    my $row_options = $opts->{ row_options } || 0;
    my $perms       = $opts->{ perms       } || {};

    my @options;
    foreach my $option ( @{ $bigtop_args } ) {
        my $label;
        my $location;
        my $crud_type;
        my $action;

        if ( ref( $option ) =~ /HASH/ ) {
            ( $label, $location ) = %{ $option };

            if ( $row_options ) { # remove /$id if present
                $location =~ s{ / \$ id (.)? $ }{$1}x;
            }
            $action = _label_to_action( $label );
        }
        else {
            $label     = $option;
            $action = _label_to_action( $label );

            if ( not $row_options ) {
                $location  = '$real_location . "' .
                             $action . $url_suffix . '"';
            }

        }
        $crud_type = $perms->{ $label } || $crud_type_for{ $action };

        if ( $row_options ) {
            $crud_type ||= 'retrieve';
        }
        else {
            $crud_type ||= 'create';
        }

        push @options, {
            text     => $label,
            location => $location,
            type     => $crud_type,
        };
    }

    return \@options;
}

sub _label_to_action {
    my $label  = shift;
    my $action = lc $label;

    $action    =~ s/ /_/g;

    return $action;
}

sub _build_arg_capture {
    my @extras   = @_;

    my @args     = ( '$self', @extras );
    my $arg_capture =
            Bigtop::Backend::Control::Gantry::arg_capture_st_nick_style(
                { args => \@args }
            );

    return ( $arg_capture, @extras );
}

sub _crud_form_outputer {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;
    shift;                      # parent. not needed.
    my $auto_crud    = shift || 0;

    # set up args
    my $choices      = { @{ $child_output } };

    my $default_arg  = ( $auto_crud ) ? '$row' : '$data';

    my ( $arg_capture, @doc_args )
            = _build_arg_capture( $default_arg, @{ $choices->{extra_args} } );

    # get the fields
    my %name_of;
    $name_of{method}     = $self->get_method_name();
    $name_of{controller} = $self->get_controller_name();

    if ( $name_of{method} eq '_form' ) {
        if ( $auto_crud ) {
            warn "form methods should be called form (not _form)\n";
        }
        else {
            warn "form methods should have a name like my_form, "
                .   "not just _form\n";
        }
    }

    $self->get_table_name_for( $data->{lookup}, \%name_of );

    my $fields = $self->get_fields_from( $data->{lookup}, \%name_of );

    unless ( defined $choices->{fields}
                or
             defined $choices->{all_fields_but} )
    {
        die "Error: I can't generate AutoCRUD_form for $name_of{method} "
            .   "of controller $name_of{controller}.\n"
            .   "  No fields (or all_fields_but) were given.\n"; 
    }

    my $requested_fields;

    if ( defined $choices->{all_fields_but} ) {
        $requested_fields = _find_all_fields_but(
            $choices->{all_fields_but},
            $data,
            $name_of{table}
        );
    }
    else {
        $requested_fields = $choices->{fields};
    }

    my @field_lookups;
    my @refers_to;
    foreach my $field_name ( @{ $requested_fields } ) {
        my $field = get_field_for( $field_name, $fields, \%name_of );

        my %clean_field;

        $clean_field{name} = $field_name;

        FIELD_STATEMENT:
        foreach my $key ( keys %{ $field } ) {
            next FIELD_STATEMENT if ( $key eq '__IDENT__' );

            my $clean_key              = $key;
            $clean_key                 =~ s/html_form_//;

            my $clean_value            = $field->{$key}{args}[0];

            # translate foreign key into select list
            if ( $clean_key eq 'refers_to' ) {
                $clean_key   = 'options_string';

                if ( ref( $clean_value ) eq 'HASH' ) {
                    ( $clean_value ) = %{ $clean_value };
                }
                $clean_value =~ s/\./_/; # might have schema prefix
                push( @refers_to, $clean_value );
                $clean_value = '$selections->{' . $clean_value . '}';
            }
            # pull out all pairs
            elsif ( $clean_key eq 'options' ) {
                my @option_pairs;
                foreach my $pair ( @{ $field->{$key}{args} } ) {
                    push @option_pairs, $pair;
                }
                $clean_value           = \@option_pairs;
            }
            else {
                $clean_value           = $field->{$key}{args}[0];
            }

            $clean_field{ $clean_key } = $clean_value;
        }

        push @field_lookups, \%clean_field;
    }

    my %extra_keys;
    if ( $choices->{extra_keys} ) {
        foreach my $pair ( @{ $choices->{extra_keys} } ) {
            my ( $key, $value ) = %{ $pair };
            $extra_keys{ $key } = $value;
        }
    }

    # build body
    my $form_body = Bigtop::Backend::Control::Gantry::form_body(
        {
            model      => $data->{model_alias},
            form_name  => $choices->{form_name}[0],
            fields     => \@field_lookups,
            refers_to  => \@refers_to,
            extra_keys => \%extra_keys,
            raw_row    => $auto_crud,
            dbix       => $self->is_dbix_class( $data ),
        }
    );

    my $output_type = ( $auto_crud ) ? 'gen_output' : 'crud_output';

    return [
        $output_type => {
            body     => "$arg_capture\n$form_body",
            doc_args => \@doc_args,
        },
        comment_output => {
            doc_args => \@doc_args,
        }
    ];
}

sub output_AutoCRUD_form {
    return _crud_form_outputer( @_, 1 );
}

sub output_CRUD_form {
    my ( $self, undef, $data )    = @_;

    return _crud_form_outputer( @_, 0 );
}

sub _find_all_fields_but {
    my $excluded_fields = shift;
    my $data            = shift;
    my $table_name      = shift;

    my $bigtop_tree     = $data->{tree};

    # ask the corresponding table for its fields
    my $fields = $bigtop_tree->walk_postorder(
        'output_field_names', { table_of_interest => $table_name }
    );

    my @retval;

    # now build the return list
    my %exclude_this;
    @exclude_this{ @{ $excluded_fields } } = @{ $excluded_fields };

    foreach my $field ( @{ $fields } ) {
        push @retval, $field unless $exclude_this{ $field };
    }

    return \@retval;
}

package # method_statement
    method_statement;
use strict; use warnings;

sub with_perms {
    my $self = shift;

    return unless $self->{__KEYWORD__} eq 'permissions';

    return [ $self->{__ARGS__} ];
}

sub walker_output {
    my $self = shift;

    return [ $self->{__KEYWORD__} => $self->{__ARGS__} ];
}

sub output_hashref          { goto &walker_output; }

sub output_stub          { goto &walker_output; }

sub output_main_listing  { goto &walker_output; }

sub output_AutoCRUD_form { goto &walker_output; }

sub output_CRUD_form     { goto &walker_output; }

sub output_base_links    { goto &walker_output; }

sub output_links         { goto &walker_output; }

sub output_SOAP          { goto &walker_output; }

sub output_SOAPDoc       { goto &walker_output; }

1;
