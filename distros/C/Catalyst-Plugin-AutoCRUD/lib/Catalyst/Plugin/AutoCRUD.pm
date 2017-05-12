package Catalyst::Plugin::AutoCRUD;
{
  $Catalyst::Plugin::AutoCRUD::VERSION = '2.200002';
}

use strict;
use warnings;

use MRO::Compat;
use Devel::InnerPackage qw/list_packages/;

our $this_package = __PACKAGE__; # so it can be used in hash keys
our $VERSION ||= '0.00031412';

sub setup_components {
    my $class = shift;
    $class->next::method(@_);

    # these are the boilerplate Catalyst components for AutoCRUD
    my @packages = qw(
        Controller::Root
        Controller::Static
        Controller::AJAX
        Controller::DisplayEngine::ExtJS2
        Controller::DisplayEngine::Skinny
        Model::StorageEngine::DBIC
        View::JSON
        View::TT
    );

    # will auto-load other models, so this one is not -required-
    if (exists $class->config->{'Model::AutoCRUD::DBIC'}) {
        push @packages, 'Model::DBIC';
        my $p = 'Model::AutoCRUD::DBIC';

        # on the fly schema engineering
        if (!exists $class->config->{$p}->{schema_class}) {
            require DBIx::Class::Schema::Loader;
            die "Must have DBIx::Class::Schema::Loader version > 0.04005"
                if eval "$DBIx::Class::Schema::Loader::VERSION" <= 0.04005;

            DBIx::Class::Schema::Loader::make_schema_at(
                'AutoCRUD::Loader::Schema', {naming => 'current'},
                $class->config->{$p}->{connect_info},
            );

            eval q{
                package # hide from the PAUSE
                    AutoCRUD::Loader::Schema;
                use base 'DBIx::Class::Schema';
                AutoCRUD::Loader::Schema->load_classes();
                1;
            };
            $INC{'AutoCRUD/Loader/Schema.pm'} = 'loaded';

            $class->config->{$p}->{schema_class} = 'AutoCRUD::Loader::Schema';
        }
    }

    # bodge the config for chained PathPart so the user can use our basepath
    # shortcut in their config, which is less verbose than Cat's alternative
    (my $config_key = $this_package) =~ s/^Catalyst:://;
    if (exists $class->config->{$config_key}
        and exists $class->config->{$config_key}->{basepath}) {
        $class->config->{'Controller::AutoCRUD::Root'}->{action}->{base}->{PathPart}
            = $class->config->{$config_key}->{basepath};
    }

    # any additional backends requested
    if (exists $class->config->{$config_key}->{backends}) {
        my @backends = ref $class->config->{$config_key}->{backends} eq ref ''
            ? $class->config->{$config_key}->{backends}
            : @{ $class->config->{$config_key}->{backends} };

        # they will be componentized below
        push @packages, map {'Model::StorageEngine::' . $_} @backends;

        # this so that they can be forwarded to in the controller
        my %m = map {('Model::AutoCRUD::StorageEngine::' . $_) => 1} @backends;
        ++$m{'Model::AutoCRUD::StorageEngine::DBIC'};
        $class->config->{$config_key}->{backends} = [ keys %m ];
    }
    else {
        $class->config->{$config_key}->{backends} =
            [ 'Model::AutoCRUD::StorageEngine::DBIC' ];
    }

    foreach my $orig (@packages) {
        (my $p = $orig) =~ s/::/::AutoCRUD::/;
        my $comp = "${class}::${p}";

        # require will shortcircuit and return true if the component is
        # already loaded
        unless (eval "package $class; require $comp;") {

            # make a component on the fly in the App namespace
            eval qq(
                package $comp;
                use base qw/${this_package}::${orig}/;
                1;
            );
            die $@ if $@;

            # inject entry to %INC so Perl knows this component is loaded
            # this is just for politeness and does not aid Catalyst
            (my $file = "$comp.pm") =~ s{::}{/}g;
            $INC{$file} = 'loaded';

            #  add newly created components to catalyst
            #  must set up component and -then- call list_packages on it
            $class->components->{$comp} = $class->setup_component($comp);
            for my $m (list_packages($comp)) {
                $class->components->{$m} = $class->setup_component($m);
            }
        }
    }

    return 1;
}

# we subvert the pretty print error screen for dumpmeta
sub dump_these {
    my $c = shift;

    my $params = {
            map {$_ => $c->stash->{$_}}
                grep {ref $c->stash->{$_} eq ''}
                grep {$_ =~ m/^cpac_/}
                     keys %{$c->stash},
    };

    # strip the SQLT objects
    my $meta = undef;
    if (exists $c->stash->{cpac}->{m}) {
        $meta = scalar $c->stash->{cpac}->{m}->extra;
        foreach my $t (values %{$c->stash->{cpac}->{m}->t}) {
            $meta->{t}->{$t->name} = scalar $t->extra;
            foreach my $f (values %{$t->f}) {
                $meta->{t}->{$t->name}->{f}->{$f->name} = scalar $f->extra;
            }
        }
    }

    if ($c->stash->{dumpmeta}) {
        return (
            [ 'CPAC Parameters (cpac_*)' => $params ],
            [ 'Global Configuration (g)' => $c->stash->{cpac}->{g} ],
            [ 'Site Configuration (c)' => $c->stash->{cpac}->{c} ],
            [ 'Storage Metadata (m)' => $meta ],
            [ 'Response' => $c->response ], # only to pacify log_request
        );
    }
    else { $c->next::method(@_) }
}

# monkey patch Catalyst::View::JSON until it is fixed, or users will get scared
# by the warning currently emitted by Catalyst

use Catalyst::View::JSON;
my $json_new = _get_subref('new', 'Catalyst::View::JSON');
{
    no warnings 'redefine';
    *Catalyst::View::JSON::new = sub {
        delete $_[2]->{catalyst_component_name};
        goto $json_new;
    };
}

sub _get_subref {
    my $sub = shift;
    my $pkg = shift || scalar caller(0);

    my $symtbl = \%{main::};
    foreach my $part(split /::/, $pkg) {
        $symtbl = $symtbl->{"${part}::"};
    }

    return eval{ \&{ $symtbl->{$sub} } };
}

1;

# ABSTRACT: Instant AJAX web front-end for DBIx::Class


__END__
=pod

=head1 NAME

Catalyst::Plugin::AutoCRUD - Instant AJAX web front-end for DBIx::Class

=head1 VERSION

version 2.200002

=head1 STATUS

B<Important Notice>

This distribution is no longer under active maintenance.  The status of
AutoCRUD is now "pull-request" only, meaning there will only be updates when
the author receives a patch or pull request (via Github).

You are recommended to take a look at the excellent L<RapidApp> distributiuon
and in particular the L<rdbic.pl> script which can do the same thing as
AutoCRUD (only better, and maintained).

=head1 PURPOSE

You have a database, and wish to have a basic web interface supporting Create,
Retrieve, Update, Delete and Search, with little effort. This module is able
to create such interfaces on the fly. They are a bit whizzy and all Web
2.0-ish.

=over 4

=item *

See the demo at: L<http://demo.autocrud.pl/>

=back

=head1 SYNOPSIS

If you already have a L<Catalyst> app with L<DBIx::Class> models configured:

 use Catalyst qw(AutoCRUD); # <-- add the plugin name here in MyApp.pm

Now load your app in a web browser, but add C</autocrud> to the URL path.

Alternatively, to connect to an external database if you have the DBIX::Class
schema available, use the C<ConfigLoader> plugin with the following config:

 <Model::AutoCRUD::DBIC>
     schema_class   My::Database::Schema
     connect_info   dbi:Pg:dbname=mydbname;host=mydbhost.example.com;
     connect_info   username
     connect_info   password
     <connect_info>
         AutoCommit   1
     </connect_info>
 </Model::AutoCRUD::DBIC>

If you don't have the DBIx::Class schema available, just omit the
C<schema_class> option (and have L<DBIx::Class::Schema::Loader> installed).

=head1 DESCRIPTION

This module contains an application which will automatically construct a web
interface for a database on the fly. The web interface supports Create,
Retrieve, Update, Delete and Search operations.

The interface is not written to static files on your system, and uses AJAX to
act upon the database without reloading your web page (much like other
Web 2.0 applications, for example Google Mail).

Almost all the information required by the plugin is retrieved from the
L<DBIx::Class> ORM frontend to your database, which it is expected that you
have already set up (although see L</USAGE>, below). This means that any
change in database schema ought to be reflected immediately in the web
interface after a page refresh.

=head1 USAGE

=head2 Read Me First

=over 4

=item *

If you get stuck, read the
L<Troubleshooting|Catalyst::Plugin::AutoCRUD::Manual::Troubleshooting> documentation.

=item *

L<DBIx::Class> users should read
L<DBIx::Class Tips|Catalyst::Plugin::AutoCRUD::Manual::DBICTips>.

=item *

This plugin provides no user-based access authentication or authorization.
Please take care when deploying, and consider who will have access.  It is
possible to restrict the add/update/delete operations on data.  See L</TIPS
AND TRICKS> for other suggestions.

=back

=head2 Scenario 1: Plugin to an existing Catalyst App

This mode is for when you have written your Catalyst application, but the
Views are catering for the users and as an admin you'd like a more direct,
secondary web interface to the database.

 package AutoCRUDUser;
 use Catalyst qw(AutoCRUD);
 
 __PACKAGE__->setup;
 1;

Adding C<Catalyst::Plugin::AutoCRUD> as a plugin to your Catalyst application,
as above, causes it to scan your existing Models. If any of them are built
using L<Catalyst::Model::DBIC::Schema>, they are automatically loaded.

This mode of operation works even if you have more than one database. You will
be offered a Home screen to select the database, and then another menu to
select the table within that.

Remember that the pages available from this plugin will be located under the
C</autocrud> path of your application. Use the C<basepath> option if you want
to override this.

=head2 Scenario 2: Frontend for an existing C<DBIx::Class::Schema> based class

In this mode, C<Catalyst::Plugin::AutoCRUD> is running standalone, in a sense
as the Catalyst application itself. Your main application file looks almost
the same as in Scenario 1, except you'll need the C<ConfigLoader> plugin:

 package AutoCRUDUser;
 use Catalyst qw(ConfigLoader AutoCRUD);
 
 __PACKAGE__->setup;
 1;

For the configuration, you need to tell AutoCRUD which package contains the
C<DBIx::Class> schema, and also provide database connection parameters.

 <Model::AutoCRUD::DBIC>
     schema_class   My::Database::Schema
     connect_info   dbi:Pg:dbname=mydbname;host=mydbhost.example.com;
     connect_info   username
     connect_info   password
     <connect_info>
         AutoCommit   1
     </connect_info>
 </Model::AutoCRUD::DBIC>

The C<Model::AutoCRUD::DBIC> section must look (and be named) exactly like that
above, except you should of course change the C<schema_class> value and the
values within C<connect_info>.

Remember that the pages available from this plugin will be located under the
C</autocrud> path if your application. Use the C<basepath> option if you want
to override this.

=head3 C<DBIx::Class> setup

You will of course need the C<DBIx::Class> schema to be created and installed
on your system. The recommended way to do this quickly is to use the excellent
L<DBIx::Class::Schema::Loader> module which connects to your database and
writes C<DBIx::Class> Perl modules for it.

Pick a suitable namespace for your schema, which is not related to this
application. For example C<DBIC::Database::Foo::Schema> for the C<Foo>
database (in the configuration example above we used C<My::Database::Schema>).
Then use the following command-line incantation:

 perl -MDBIx::Class::Schema::Loader=make_schema_at,dump_to_dir:. -e \
     'make_schema_at("DBIC::Database::Foo::Schema", { debug => 1, naming => 'current' }, \
     ["dbi:Pg:dbname=foodb;host=mydbhost.example.com","user","pass" ])'

This will create a directory (such as C<DBIC>) which you need to move into
your Perl Include path (one of the paths shown at the end of C<perl -V>).

=head2 Scenario 3: Lazy loading a C<DBIx::Class> schema

If you're in such a hurry that you can't create the C<DBIx::Class> schema, as
shown in the previous section, then C<Catalyst::Plugin::AutoCRUD> is able to
do this on the fly, but it will slow the application's startup just a little.

The application file and configuration are very similar to those in Scenario
two, above, except that you omit the C<schema_class> configuration option
because you want AutoCRUD to generate that on the fly (rather than reading an
existing one from disk).

 package AutoCRUDUser;
 use Catalyst qw(ConfigLoader AutoCRUD);
 
 __PACKAGE__->setup;
 1;

 <Model::AutoCRUD::DBIC>
     connect_info   dbi:Pg:dbname=mydbname;host=mydbhost.example.com;
     connect_info   username
     connect_info   password
     <connect_info>
         AutoCommit   1
     </connect_info>
 </Model::AutoCRUD::DBIC>

When AutoCRUD loads it will connect to the database and use the
L<DBIx::Class::Schema::Loader> module to reverse engineer its schema. To work
properly you'll need the very latest version of that module (at least 0.05,
or the most recent development release from CPAN).

The other drawback to this scenario (other than the slower operation) is that
you have no ability to customize how foreign, related records are shown.  A
related record will simply be represented as something approximating the name
of the foreign table, the names of the primary keys, and associated values
(e.g. C<id(5)>).

=head1 TIPS AND TRICKS

=head2 Displaying Unicode

It is essential that you load the L<Catalyst::Plugin::Unicode::Encoding>
plugin to ensure proper decoding/encoding of incoming request parameters and
the outgoing body response respectively. This is done in your C<MyApp.pm>:

 use Catalyst qw/ -Debug ConfigLoader Unicode::Encoding AutoCRUD /;

Additionally, when connecting to the database, add a flag to the connection
parameters, specific to your database engine, that enables Unicode. See the
following link for more details:

=over 4

=item *

L<https://metacpan.org/module/DBIx::Class::Manual::Cookbook#Using-Unicode>

=back

=head2 Representing related records

When the web interface wants to display a column which references another
table, you can make things look much better by adding a custom render method
to your C<DBIx::Class> Result Classes (i.e. the class files for each table).

First, the plugin will look for a method called C<display_name> and use that.
Here is an example which could be added to your Result Class files below the
line which reads C<DO NOT MODIFY THIS OR ANYTHING ABOVE>, and in this case
returns the data from the C<title> column:

 sub display_name {
     my $self = shift;
     return $self->title || '';
 }

Failing the existence of a C<display_name> method, the plugin attempts to
stringify the row object. Using stringification is not recommended, although
some people like it. Here is an example of a stringification handler:

 use overload '""' => sub {
     my $self = shift;
     return $self->title || '';
 }, fallback => 1;

If all else fails the plugin prints the best hint it can to describe the
foreign row. This is something approximating the name of the foreign table,
the names of the primary keys, and associated values. It's better than
stringifying the object the way Perl does, anyway.

=head2 Textfields and Textareas

When the plugin creates a web form for adding or editing, it has to choose
whether to show a Textfield or Textarea for text-type fields. If you have set
a C<size> option in add_columns() within the Schema, and this is less than or
equal to 40, a Textfield is used. Otherwise, if the C<size> option is larger
than 40 or not set, then an auto-expanding, scrollable Textarea is used.

=head2 Column names with spaces

The plugin will handle most tricky names, but you should remember to pass some
required extra quoting hints to DBIx::Class when it makes a connection to your
database:

 # most databases:
 { quote_char => q{`}, name_sep => q{.} }
  
 # SQL Server:
 { quote_char => [qw/[ ]/], name_sep => q{.} }

For more information see the L<DBIx::Class::Storage::DBI> manual page or ask
on the DBIx::Class mail list.

=head2 Database IO filters

Buried within one of the modules in this application are some filters which
are applied to data of certain types as it enters or leaves the database. If
you find a particular data type is not being rendered correctly, please drop
the author a line at the email address below, explaining what you'd like to
see instead.

=head2 Relocating AutoCRUD to another URL path

If you want to use this application as a plugin with another Catalyst system,
it should work fine, but you probably want to serve pages under a different
path on your web site. To that end, the plugin by default places its pages
under a path part of C<...E<sol>autocrudE<sol>>. You can change this by adding
the following option to your configuration file:

 <Plugin::AutoCRUD>
    basepath admin
 </Plugin::AutoCRUD>

In the above example, the path C<...E<sol>adminE<sol>> will contain the AutoCRUD
application, and all generated links in AutoCRUD will also make use of that path.
Remember this is added to the C<base> of your Cataylst application which,
depending on your web server configuration, might also have a leading path.

To have the links based at the root of your application (which was the default
behaviour of C<CatalystX::ListFramework::Builder>, set this variable to an
empty string in your configuration:

 <Plugin::AutoCRUD>
    basepath ""
 </Plugin::AutoCRUD>

=head2 Using your own ExtJS libraries

The plugin will use copies of the ExtJS libraries hosted in the CacheFly
content delivery network out there on the Internet. Under some circumstances
you'll want to use your own hosted copy, for instance if you are serving HTTPS
(because browsers will warn about mixed HTTP and HTTPS content).

In which case, you'll need to download the ExtJS Javascript Library (version
2.2+ recommended), from this web page:
L<http://www.sencha.com/products/extjs/download/>.

Install it to your web server in a location that it is able to serve as static
content. Make a note of the path used in a URL to retrieve this content, as it
will be needed in the application configuration file, like so:

 <Plugin::AutoCRUD>
    extjs2  /static/javascript/extjs-2
 </Plugin::AutoCRUD>

Use the C<extjs2> option as shown above to specify the URL path to the
libraries. This will be used in the templates in some way like this:

 <script type="text/javascript" src="[% c.config.extjs2 %]/ext-all.js" />

=head2 Changing the HTML Character Set

The default HTML C<charset> used by this module is C<utf-8>. If you wish to override
this, then set the C<html_charset> parameter, as below:

 <Plugin::AutoCRUD>
    html_charset  iso-8859-1
 </Plugin::AutoCRUD>

=head2 Simple read-only non-JavaScript Frontend

All table views will default to the full-featured ExtJS based frontend. If you
would prefer to see a simple read-only non-JavaScript interface, then append
C</browse> to your URL.

This simpler frontend uses HTTP GET only, supports paging and sorting, and
will obey any column filtering and renaming as set in your L</"SITES CONFIGURATION"> file.

=head2 Overriding built-in Templates

The whole site is built from Perl Template Toolkit templates, and it is
possible to override these shipped templates with your own files. This goes
for both general files (CSS, top-level TT wrapper) as well as the site files
mentioned in the next section.

To add these override paths, include the following directive in your
configuration file:

 <Plugin::AutoCRUD>
    tt_path /path/to/my/local/templates
 </Plugin::AutoCRUD>

This C<tt_path> directive can be included multiple times to set a list of
override paths, which will be processed in the order given.

Within the specified directory you should mirror the file structure where the
overridden templates have come from, including the frontend name. For example:

 extjs2
 extjs2/wrapper
 extjs2/wrapper/footer.tt
 skinny
 skinny/wrapper
 skinny/wrapper/footer.tt

If you want to override any of the CSS used in the app, copy the C<head.tt>
template from whichever C<site> you are using, edit, and install in a local
C<tt_path> set with this directive.

=head2 Reconfiguring Embedded Plugins

Embedded plugins such as L<Catalyst::View:TT>, L<Catalyst::View::JSON>, etc,
can be reconfigured in your C<myapp.yml> file using a simple naming
convention. Remove the leading "Catalyst", and insert "AutoCRUD" after the
first namespace component. For example:

 View::AutoCRUD::TT:
   ENCODING: utf-8

Note that this does not affect your own App's usage of the same plugins, only
the AutoCRUD plugin's instances are reconfigured.

=head1 SITES CONFIGURATION

It's possible to have multiple views of the source data, tailored in various
ways. For example you might choose to hide some tables, or columns within
tables, rename headings of columns, or disable updates or deletes.

This is all achieved through the C<sites> configuration. Altering the default
site simply allows for control of column naming, hiding, etc. Creating a new
site allows you to present alternate configurations of the same source data.

=head2 Altering the Default Site

When using this plugin out of the box you're already running within the
default site, which unsurprisingly is called C<default>. To override settings
in this, create the following configuration stub, and fill it in with any of
the options listed below:

 <Plugin::AutoCRUD>
    <sites>
        <default>
            # override settings here
        </default>
    </sites>
 </Plugin::AutoCRUD>

=head2 Configuration Options for Sites

In general, when you apply a setting to something at a higher level (say, a
database), it I<percolates> down to the child sections (i.e. the tables). For
example, setting C<delete_allowed no> on a database will prevent records from
any table within that from being deleted.

Some of the options are I<global> for a site, others apply to the database or
table within it. To specify an option for one or the other, use the database
and table names I<as they appear in the URL path>:

 <Plugin::AutoCRUD>
    <sites>
        <default>
            # global settings for the site, here
            <mydb>
                # override settings here
                <sometable>
                    # and/or override settings here
                </sometable
            </mydb>
        </default>
    </sites>
 </Plugin::AutoCRUD>

=head3 Options

=over 4

=item update_allowed [ yes* | no ]

This can be applied to either a database or a table; if applied to a database it
percolates to all the tables, unless the table has a different setting.

The default is to allow updates to be made to existing records. Set this to a
value of C<no> to prevent this operation from being permitted.  Widgets will
also be removed from the user interface so as not to confuse users.

 <Plugin::AutoCRUD>
    <sites>
        <default>
            update_allowed no
        </default>
    </sites>
 </Plugin::AutoCRUD>

=item create_allowed [ yes* | no ]

This can be applied to either a database or a table; if applied to a database it
percolates to all the tables, unless the table has a different setting.

The default is to allow new records to be created. Set this to a value of
C<no> to prevent this operation from being allowed.  Widgets will also be
removed from the user interface so as not to confuse users.

 <Plugin::AutoCRUD>
    <sites>
        <default>
            create_allowed no
        </default>
    </sites>
 </Plugin::AutoCRUD>

=item delete_allowed [ yes* | no ]

This can be applied to either a database or a table; if applied to a database it
percolates to all the tables, unless the table has a different setting.

The default is to allow deletions of records in the tables. Set this to a
value of C<no> to prevent deletions from being allowed. Widgets will also be
removed from the user interface so as not to confuse users.

 <Plugin::AutoCRUD>
    <sites>
        <default>
            delete_allowed no
        </default>
    </sites>
 </Plugin::AutoCRUD>

=item columns \@column_names

This option achieves two purposes. First, you can re-order the set of columns
as they are displayed to the user. Second, by omitting columns from this list
you can hide them from the main table views.

Provide a list of the column names (as the data source knows them) to this
setting. This option must appear at the table level of your site config
hierarchy. In C<Config::General> format, this would look something like:

 <Plugin::AutoCRUD>
    <sites>
        <default>
            <mydb>
                <thetable>
                    columns  id
                    columns  title
                    columns  length
                </thetable>
            </mydb>
        </default>
    </sites>
 </Plugin::AutoCRUD>

Any columns existing in the table, but not mentioned there, will not be
displayed in the main table. They'll still appear in the record edit form, as
some fields are required by the database schema so cannot be hidden. Columns
will be displayed in the same order that you list them in the configuration.

=item headings { col => title, ... }

You can alter the title given to any column in the user interface, by
providing a hash mapping of column names (as the data source knows them) to
titles you wish displayed to the user. This option must appear at the table
level of your site config hierarchy. In C<Config::General> format, this would
look something like:

 <Plugin::AutoCRUD>
    <sites>
        <default>
            <mydb>
                <thetable>
                    <headings>
                        id      Key
                        title   Name
                        length  Time
                    </headings>
                </thetable>
            </mydb>
        </default>
    </sites>
 </Plugin::AutoCRUD>

Any columns not included in the hash mapping will use the default title (i.e.
what the plugin works out for itself). To hide a column from view, use the
C<columns> option, described above.

=item hidden [ yes | no* ]

If you don't want a database to be offered to the user, or likewise a particular
table, then set this option to C<yes>. By default, all databases and tables are
shown in the user interface.

 <Plugin::AutoCRUD>
    <sites>
        <default>
            <mydb>
                <secrettable>
                    hidden yes
                </secrettable>
            </mydb>
        </default>
    </sites>
 </Plugin::AutoCRUD>

This can be applied to either a database or table; if applied to a database it
overrides all child tables, B<even if> a table has a different setting.

=item frontend [ extjs2 | skinny | ... ]

With this option you can swap out the set of templates used to generate the
web front-end, and completely change its look and feel.

Currently you have two choices: either C<extjs2> which is the default and
provides the standard full-featured ExtJS2 frontend, or C<skinny> which is a
read-only non-JavaScript alternative supporting listing, paging and sorting
only.

Set the frontend in your site config at its top level. Note that you cannot
set the frontend on a per-database or per-table basis, only per-site:

 <Plugin::AutoCRUD>
    <sites>
        <default>
            frontend skinny
        </default>
    </sites>
 </Plugin::AutoCRUD>

Be aware that setting the frontend to C<skinny> does B<not> restrict create or
update access to your database via the AJAX API. For that, you still should
set the C<*_allowed> options listed above, as required.

=back

=head2 Creating a New Site

You can create a new site by adding it to the C<sites> section of your
configuration:

 <Plugin::AutoCRUD>
    <sites>
        <mysite>
            # local settings here
        </mysite>
    </sites>
 </Plugin::AutoCRUD>

You'll notice that a non-default site is active because the path in your URLs
changes to a more RPC-like verbose form, mentioning the site, database and
table:

 from this:
 .../autocrud/mydb/thetable    # (i.e. site == default)
  
 to this:
 .../autocrud/site/mysite/schema/mydb/source/thetable

So let's say you've created a dumbed down site for your users which is
read-only (i.e. C<update_allowed no> and C<delete_allowed no>), and called the
site C<simplesite> in your configuration. You need to give the following URL
to users:

  .../autocrud/site/simplesite

You could also then place an access control on this path part in your web
server (e.g. Apache) which is different from the default site itself.

=head1 INSTANT DEMO APPLICATIONS

=head2 Automagic Loading

If you want to run an instant demo of this module, with minimal configuration,
then a simple application for that is shipped with this distribution. For this
to work, you must have:

=over 4

=item *

The very latest version of L<DBIx::Class::Schema::Loader> installed on your
system (at least 0.05, or the most recent release from CPAN).

=item *

SQLite3 and the accompanying DBD module, if you want to use the shipped demo
database.

=back

Go to the C<examples/sql/> directory of this distribution and run the
C<bootstrap_sqlite.pl> perl script. This will create an SQLite file.

Now change to the C<examples/demo/> directory and start the demo application
like so:

 demo> perl ./server.pl

Visit C<http://localhost:3000> in your browser as instructed at the end of
the output from this command.

To use your own database rather than the SQLite demo, edit
C<examples/demo/demo.conf> so that it contains the correct C<dsn>, username,
and password for your database. Upon restarting the application you should see
your own data source instead.

=head2 Row Display Names

An alternate application exists which demonstrates use of the C<display_name>
method on a L<DBIx::Class> Row, to give row entries "friendly names". Follow
all the instructions above but instead run the following server script:

 demo> perl ./server_with_display_name.pl

=head2 Other Features

Finally, the kitchen sink of other features supported by this module are
demonstrated in a separate application. This contains many tables, each of
which highlights one or more aspects of a relational database backend being
rendered in AutoCRUD.

Follow all the instructions above, but instead run the following server
script:

 demo> perl ./server_other_features.pl

=head1 TROUBLESHOOTING

See L<Catalyst::Plugin::AutoCRUD::Manual::Troubleshooting>.

=head1 LIMITATIONS

See L<Catalyst::Plugin::AutoCRUD::Manual::Limitations>.

=head1 SEE ALSO

L<CatalystX::CRUD> and L<CatalystX::CRUD:YUI> are two distributions which
allow you to create something similar but with full customization, and the
ability to add more features. So, you trade effort for flexibility and power.

=head1 ACKNOWLEDGEMENTS

Without the initial work on C<CatalystX::ListFramework> by Andrew Payne and
Peter Edwards this package would not exist. If you are looking for something
like this module but without the dependency on Javascript, please do check
out L<CatalystX::ListFramework>.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

