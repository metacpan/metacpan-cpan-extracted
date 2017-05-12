package App::ZofCMS::Plugin::YouTube;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use DBI;
use HTML::Template;
use HTML::Entities;
use LWP::UserAgent;
use base 'App::ZofCMS::Plugin::Base';

sub _key { 'plug_youtube' }

sub _defaults {
    return (
        #dsn            => "DBI:mysql:database=test;host=localhost",
        user            => '',
        pass            => '',
        opt             => { RaiseError => 1, AutoCommit => 1 },
        t_name          => 'plug_youtube',
        table           => 'videos',
        create_table    => 0,
        h_level         => 3,
        size            => 1,
        no_form         => 0,
        no_list         => 0,
        allow_edit      => 0,
        ua_args => [
            agent   => 'Opera 9.2',
            timeout => 30,
        ],
#         filter          => {
#             title       => qr/Foo/,
#             description => qr/Bar/,
#             link        => qr/234fd343/,
#         },
    );
}

sub _do {
    my ( $self, $conf, $template, $query ) = @_;

    return if
        $conf->{no_form}
        and $conf->{no_list};

    if ( not ref $conf->{size} ) {
        my @sizes = (
            [ 320, 265 ],
            [ 425, 344 ],
            [ 480, 385 ],
            [ 640, 505 ],
        );
        if ( not defined $conf->{size} or $conf->{size} > $#sizes ) {
            $conf->{size} = [ 320, 262 ];
        }
        else {
            $conf->{size} = $sizes[ $conf->{size} ];
        }
    }

    if ( $conf->{create_table} ) {
        my $dbh = DBI->connect_cached(
            @$conf{ qw/dsn user pass opt/ },
        );

        $dbh->do(
            "CREATE TABLE $conf->{table} (
                title       TEXT,
                link        TEXT,
                description TEXT,
                embed       TEXT,
                time        VARCHAR(10),
                id          TEXT
            );",
        );
    }

    my %t_names = (
        form    => "$conf->{t_name}_form",
        list    => "$conf->{t_name}_list",
    );

    $conf->{no_form}
        or $template->{t}{ $t_names{form} } = $self->_process_add_form( $conf, $query );

    if ( $query->{plug_youtube_vid_edit_action} and $conf->{allow_edit} ) {
        $query->{plug_youtube_vid_edit_action} eq 'Delete'
            and $self->_delete_video( $conf, $query->{plug_youtube_vid_edit_id} );
    }

    $conf->{no_list}
        or $template->{t}{ $t_names{list} } = $self->_get_video_list( $conf, $query );
}

sub _delete_video {
    my ( $self, $conf, $id ) = @_;

    my $dbh = DBI->connect_cached(
        @$conf{ qw/dsn user pass opt/ },
    );

    $dbh->do(
        "DELETE FROM $conf->{table} WHERE id = ?;",
        undef,
        $id,
    );
}

sub _get_video_list {
    my ( $self, $conf, $query ) = @_;

    my $t = HTML::Template->new_scalar_ref( \ _list_template() );

    my $dbh = DBI->connect_cached(
        @$conf{ qw/dsn user pass opt/ },
    );

    my $vids = $dbh->selectall_arrayref(
        "SELECT * FROM $conf->{table};",
        { Slice => {} },
    );

    $vids ||= [];

    @$vids = sort { $b->{time} <=> $a->{time} } @$vids;

    for ( @$vids ) {
        $_->{time} = localtime $_->{time};
        encode_entities $_->{description};
        $_->{description} =~ s/\n/<br>/g;

        $_->{embed}
        =~ s|(width=")\d+("\s+height=")\d+"|$1$conf->{size}[0]$2$conf->{size}[1]"|g;
    }

    if ( $conf->{filter} ) {
        if ( defined $conf->{filter}{title} ) {
            @$vids = grep $_ =~ /$conf->{filter}{title}/, @$vids;
        }
        if ( defined $conf->{filter}{description} ) {
            @$vids = grep $_ =~ /$conf->{filter}{description}/, @$vids;
        }
        if ( defined $conf->{filter}{link} ) {
            @$vids = grep $_ =~ /$conf->{filter}{link}/, @$vids;
        }
    }

    if ( @$vids ) {
        my @loop = map +{
            ( $_%2 ? ( alt_class => 1 ) : () ),
            h_level => $conf->{h_level},
            link    => $vids->[$_]{link},
            title   => $vids->[$_]{title},
            time    => $vids->[$_]{time},
            embed   => $vids->[$_]{embed},
            description => $vids->[$_]{description},
            id      => $vids->[$_]{id},
            page    => $query->{page},
            dir     => $query->{dir},
            ( $conf->{allow_edit} ? ( edit => 1 ) : () ),
        }, 0.. $#$vids;

        $t->param(
            has_vids => 1,
            vids    => \@loop,
        );

    }

    return $t->output;
}

sub _process_add_form {
    my ( $self, $conf, $query ) = @_;

    my $t = HTML::Template->new_scalar_ref( \ _form_template() );

    if ( defined $query->{plug_youtube_vid_edit_action}
        and $conf->{allow_edit}
        and $query->{plug_youtube_vid_edit_action} eq 'Edit'
    ) {
        my $dbh = DBI->connect_cached(
            @$conf{ qw/dsn user pass opt/ },
        );

        my $vids = $dbh->selectall_arrayref(
            "SELECT * FROM $conf->{table} WHERE id = ?",
            { Slice => {} },
            $query->{plug_youtube_vid_edit_id},
        );

        if ( @$vids ) {
            $dbh->do(
                "DELETE FROM $conf->{table} WHERE id = ?",
                undef,
                $query->{plug_youtube_vid_edit_id},
            );
            @$query{ qw/plug_youtube_title plug_youtube_link plug_youtube_description/ }
            = @{ $vids->[0] }{ qw/title link description/ };
        }
    }

    $t->param(
        map +( $_ => $query->{$_} ), qw/
                page
                dir
                plug_youtube_title
                plug_youtube_link
                plug_youtube_description
            /
    );

    if ( $query->{plug_youtube_submit}
        and $self->_check_add_form( $query, $t )
    ) {
        my $uri = $query->{plug_youtube_link};
        $uri = "http://$uri"
            unless $uri =~ m{^http://}i;

        my $ua = LWP::UserAgent->new( @{ $conf->{ua_args} || [] } );
        my $response = $ua->get( $uri );

        if ( not $response->is_success ) {
            $t->param( error => $response->status_line );
        }
        else {
            my ( $code ) = $response->content =~ /
                <input\s+id="embed_code"\s+name="embed_code"\s+type="text"\s+value='
                (&lt;object[^']+)
            /xi
                or $t->param( error => 'Server Error' )
                and return $t->output;

            decode_entities $code;

            my $dbh = DBI->connect_cached(
                @$conf{ qw/dsn user pass opt/ },
            );

            $dbh->do(
                "INSERT INTO $conf->{table} VALUES(?, ?, ?, ?, ?, ?);",
                undef,
                @$query{ qw/
                    plug_youtube_title
                    plug_youtube_link
                    plug_youtube_description
                /},
                $code,
                time(),
                do { my $id = rand() . time() . rand(); $id =~ tr/.//d; $id },
            );

            $t->param( form_ok => 1 );
        }
    }

    return $t->output;
}

sub _check_add_form {
    my ( $self, $query, $t ) = @_;

    my $error;
    unless ( defined $query->{plug_youtube_title}
        and length $query->{plug_youtube_title}
    ) {
        $error = q|Missing 'Title' parameter|;
    }

    unless ( defined $query->{plug_youtube_link}
        and length $query->{plug_youtube_link}
    ) {
        $error = q|Missing 'Link' parameter|;
    }

    unless ( $query->{plug_youtube_link} =~ /youtube[.]com/ ) {
        $error = q|Incorrect YouTube link|;
    }

    unless ( defined $query->{description} ) {
        $query->{description} = '';
    }

    if ( defined $error ) {
        $t->param( error => $error );
        return;
    }
    return 1;
}

sub _form_template {
    return <<'END_HTML_TEMPLATE_CODE';
<tmpl_if name="form_ok">
    <p>Video was successfully added.</p>
    <p><a href="/index.pl?page=<tmpl_var escape='html' name='page'>&dir=<tmpl_var escape='html' name='dir'>">Add another video</a></p>
<tmpl_else>
    <form action="" method="POST" id="plug_youtube_form">
    <div>
        <tmpl_if name="error"><p class="error"><tmpl_var escape='html' name='error'></tmpl_if>
        <input type="hidden" name="page" value="<tmpl_var escape='html' name='page'>">
        <input type="hidden" name="dir" value="<tmpl_var escape='html' name='dir'>">
        <ul>
            <li>
                <label for="plug_youtube_title">Title: </label
                ><input type="text" id="plug_youtube_title" name="plug_youtube_title" value="<tmpl_var escape='html' name='plug_youtube_title'>">
            </li>
            <li>
                <label for="plug_youtube_link">Link: </label
                ><input type="text" id="plug_youtube_link" name="plug_youtube_link" value="<tmpl_var escape='html' name='plug_youtube_link'>">
            </li>
            <li>
                <label for="plug_youtube_description">Description: </label
                ><textarea id="plug_youtube_description" name="plug_youtube_description" cols="60" rows="10"><tmpl_var escape='html' name='plug_youtube_description'></textarea>
            </li>
        </ul>
        <input type="submit" name="plug_youtube_submit" value="Add">
    </div>
    </form>
</tmpl_if>
END_HTML_TEMPLATE_CODE

}

sub _list_template {
    return <<'END_HTML_TEMPLATE_CODE';
<tmpl_if name='has_vids'>
    <ul id="plug_youtube_list">
        <tmpl_loop name='vids'>
        <li<tmpl_if name='alt_class'> class="alt"</tmpl_if>>
            <h<tmpl_var name='h_level'>><a href="<tmpl_var escape='html' name='link'>"><tmpl_var escape='html' name='title'></a></h<tmpl_var name='h_level'>>
            <p class="plug_youtube_time">Posted on: <tmpl_var name='time'></p>
            <div class="plug_youtube_video"><tmpl_var name='embed'></div>
            <p class="plug_youtube_description"><tmpl_var name='description'></p>
            <tmpl_if name='edit'>
                <form action="" method="POST">
                <div>
                    <input type="hidden" name="plug_youtube_vid_edit_id" value="<tmpl_var escape='html' name='id'>">
                    <input type="hidden" name="page" value="<tmpl_var escape='html' name='page'>">
                    <input type="hidden" name="dir" value="<tmpl_var escape='html' name='dir'>">
                    <input type="submit" class="input_submit submit_button_edit" name="plug_youtube_vid_edit_action" value="Edit">
                    <input type="submit" class="input_submit submit_button_delete" name="plug_youtube_vid_edit_action" value="Delete">
                </div>
                </form>
            </tmpl_if>
        </li>
        </tmpl_loop>
    </ul>
<tmpl_else>
    <p class="plug_youtube_no_vids">Currently there are no videos.</p>
</tmpl_if>
END_HTML_TEMPLATE_CODE
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::YouTube - CRUD-type plugin to manage YouTube videos

=head1 SYNOPSIS

In your Main Config File or ZofCMS Template template:

    plugins => [ qw/YouTube/, ],

    plug_youtube => {
        dsn            => "DBI:mysql:database=test;host=localhost", # everything below is pretty much optional
        user            => '',
        pass            => '',
        opt             => { RaiseError => 1, AutoCommit => 1 },
        t_name          => 'plug_youtube',
        table           => 'videos',
        create_table    => 0,
        h_level         => 3,
        size            => 1,
        no_form         => 0,
        no_list         => 0,
        allow_edit      => 0,
        ua_args => [
            agent   => 'Opera 9.2',
            timeout => 30,
        ],
        filter          => {
            title       => qr/Foo/,
            description => qr/Bar/,
            link        => qr/234fd343/,
        },
    },

In your L<HTML::Template> template:

    <h2>Post new video</h2>
    <tmpl_var name='plug_youtube_form'>

    <h2>Existing Videos</h2>
    <tmpl_var name='plug_youtube_list'>

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS>. It provides means to have a CRUD-like (Create, Read,
Update, Delete) interface for managing YouTube videos. The plugin provides a form where a
user can enter the title of the video, its YouTube URI and a description. That form is stored
in a SQL database by the plugin and can be displayed as a list.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and
L<App::ZofCMS::Template>

=head1

When C<create_table> option is turned on (see below) the plugin will create the following
table where C<table_name> is derived from C<table> argument in C<plug_youtube> (see below).

    CREATE TABLE table_name (
        title       TEXT,
        link        TEXT,
        description TEXT,
        embed       TEXT,
        time        VARCHAR(10),
        id          TEXT
    );

=head1 MAIN CONFIG FILE AND ZofCMS TEMPLATE FIRST-LEVEL KEYS

=head2 C<plugins>

    plugins => [ qw/YouTube/ ],

Without saying it, you need to add the plugin in the list of plugins to execute.

=head2 C<plug_youtube>

    plug_youtube => {
        dsn            => "DBI:mysql:database=test;host=localhost", # everything below is pretty much optional
        user            => '',
        pass            => '',
        opt             => { RaiseError => 1, AutoCommit => 1 },
        t_name          => 'plug_youtube',
        table           => 'videos',
        create_table    => 0,
        h_level         => 3,
        size            => 1,
        no_form         => 0,
        no_list         => 0,
        allow_edit      => 0,
        ua_args => [
            agent   => 'Opera 9.2',
            timeout => 30,
        ],
        filter          => {
            title       => qr/Foo/,
            description => qr/Bar/,
            link        => qr/234fd343/,
        },
    },

    plug_youtube => sub {
        my ( $t, $q, $config ) = @_;
        return {
            dsn => "DBI:mysql:database=test;host=localhost",
        }
    },

The plugin takes its config via C<plug_youtube> first-level key that takes a hashref
or a subref as a value and can be specified in
either Main Config File or ZofCMS Template or both. or a subref as a value. If subref is specified,
its return value will be assigned to C<plug_youtube> as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Tempalate hashref, query parameters hashref and
L<App::ZofCMS::Config> object.
If a certain key (does NOT apply to subrefs) in that hashref is set
in both, Main Config File and ZofCMS Template, the value for that key that is set in
ZofCMS Template will take precendence. The possible keys/values are as follows (virtually
all are optional and have default values):

=head3 C<dsn>

    dsn => "DBI:mysql:database=test;host=localhost",

B<Mandatory>. Takes a scalar as a value which must contain a valid
"$data_source" as explained in L<DBI>'s C<connect_cached()> method (which
plugin currently uses).

=head3 C<user>

    user => '',

B<Optional>. Takes a string as a value that specifies the user name to use when authorizing
with the database. B<Defaults to:> empty string

=head3 C<pass>

    pass => '',

B<Optional>. Takes a string as a value that specifies the password to use when authorizing
with the database. B<Defaults to:> empty string

=head3 C<opt>

    opt => { RaiseError => 1, AutoCommit => 1 },

B<Optional>. Takes a hashref as a value, this hashref contains additional L<DBI>
parameters to pass to C<connect_cached()> L<DBI>'s method. B<Defaults to:>
C<< { RaiseError => 1, AutoCommit => 1 } >>

=head3 C<table>

    table => 'videos',

B<Optional>. Takes a string as a value, specifies the name of the SQL table in which to
store information about videos. B<Defaults to:> C<videos>

=head3 C<create_table>

    create_table => 0,

B<Optional>. When set to a true value, the plugin will automatically create needed SQL table,
you can create it manually if you wish, see its format in C<USED SQL TABLE FORMAT> section
above. Generally you'd set this to a true value only once, at the start, and then you'd remove
it because there is no "IF EXISTS" checks. B<Defaults to:> C<0>

=head3 C<t_name>

    t_name => 'plug_youtube',

B<Optional>. Takes a string as a value. This string will be
used as a "base name" for two keys that plugin generates in C<{t}> special key.
The keys are C<plug_youtube_list> and C<plug_youtube_form> (providing C<t_name> is set to
default) and are explained below in C<HTML::Template VARIABLES> section below. B<Defaults to:>
C<plug_youtube>

=head3 C<h_level>

    h_level => 3,

B<Optional>. When generating a list of YouTube videos, plugin will use HTML C<< <h?> >>
elements (see C<GENERATED HTML CODE> section below).
The C<h_level> takes an integer between 1 and 6 and that value specifies what
C<< <h?> >> level to generate. B<Defaults to:> C<3> (generate C<< <h3> >> elements)

=head3 C<size>

    size => 1,
    # or
    size => [ 300, 200 ],

B<Optional>. Takes either an integer from 0 to 3 or an arrayref with two elements that are
positive intergers as a value. When the value is an arrayref the first element is treated
as the value of C<width=""> attribute and the second element is treated as the value for
C<height=""> attribute. These two control the size of the video. You can also use
integers from 0 to 3 to specify a "prefabricated" size (sort'f like a shortcut). The relation
between the integers and the sizes they represent is shown below. B<Defaults to:> C<1> (
size 425x344)

    0 => [ 320, 265 ],
    1 => [ 425, 344 ],
    2 => [ 480, 385 ],
    3 => [ 640, 505 ],

=head3 C<no_form>

    no_form => 0,

B<Optional>. Plugin generates an HTML form to input videos into the database, besides that,
it also B<processes> that form and makes sure everything is right. When C<no_form> is
set to a true value, the plugin will B<NOT> generate the form and most importantly it will
B<NOT> process anything; so if you are making your own form for input, make sure to leave
C<no_form> as false. B<Defaults to:> C<0>s

=head3 C<no_list>

    no_list => 0,

B<Optional>. Plugin automatically fetches all the available videos from the database and
prepares an HTML list to present them. When C<no_list> is set to a true value, plugin
will not generate any lists. B<Defaults to:> C<0>

=head3 C<allow_edit>

    allow_edit => 0,

B<Optional>. Applies only when both C<no_form> and C<no_list> are set to false values.
Takes either true or false values. When set to a true value, plugin will add C<Edit> and
C<Delete> buttons under every video with which the user will be able to (duh!) edit and
delete videos. B<Defaults to:> C<0>

B<Note:> the "edit" is not that smart in this plugin, what actually
happens is the video is deleted and its information is filled in the "entry" form. If the
user never hits "Add" button on the form, the video will be lost; let me know if this
creates a problem for you.

=head3 C<filter>

    filter => {
        title       => qr/Foo/,
        description => qr/Bar/,
        link        => qr/234fd343/,
    },

B<Optional>. You can set a filter when displaying the list of videos. The C<filter>
argument takes a hashref as a value. All keys take a regex (C<qr//>) as a value. The field
referenced by the key B<must match> the regex in order for the video to be put in the list
of videos. B<By default> is not specified. You can specify either 1 or all 3 keys. Possible
keys and what they reference are as follows:

=head4 C<title>

    filter => {
        title => qr/Foo/,
    },

B<Optional>. The C<title> key's regex matches the titles of the videos.

=head4 C<description>

    filter => {
        description => qr/Bar/,
    },

B<Optional>. The C<description> key's regex matches the descriptions of the videos.

=head4 C<link>

    filter => {
        link => qr/234fd343/,
    },

B<Optional>. The C<link> key's regex matches the links of the videos.

=head3 C<ua_args>

    ua_args => [
        agent   => 'Opera 9.2',
        timeout => 30,
    ],

B<Optional>. Under the hood plugin uses L<LWP::UserAgent> to access YouTube for fetching
the "embed" code for the videos. The C<ua_args> takes an arrayref as a value. This
arrayref will be directly derefrenced into L<LWP::UserAgent>'s constructor (C<new()> method).
See L<LWP::UserAgent> for possible options. B<Defaults to:>
C<< [ agent => 'Opera 9.2', timeout => 30, ] >>

=head1 HTML::Template VARIABLES

The plugin generates two keys in C<{t}> ZofCMS Template special key, thus making them
available for use in your L<HTML::Template> templates. Assuming C<t_name> is left at its
default value the following are the names of those two keys:

=head2 C<plug_youtube_form>

    <tmpl_var name='plug_youtube_form'>

This variable will contain HTML form generated by the plugin, the form also includes display
of errors.

=head2 C<plug_youtube_list>

    <tmpl_var name='plug_youtube_list'>

This variable will contain the list of videos generated by the plugin.

=head1 GENERATED HTML CODE

=head2 form

    <form action="" method="POST" id="plug_youtube_form">

    <div>
        <p class="error">Incorrect YouTube link
        <input type="hidden" name="page" value="videos">
        <input type="hidden" name="dir" value="/admin/">
        <ul>
            <li>
                <label for="plug_youtube_title">Title: </label
                ><input type="text" id="plug_youtube_title" name="plug_youtube_title" value="xxx">
            </li>
            <li>

                <label for="plug_youtube_link">Link: </label
                ><input type="text" id="plug_youtube_link" name="plug_youtube_link" value="">
            </li>
            <li>
                <label for="plug_youtube_description">Description: </label
                ><textarea id="plug_youtube_description" name="plug_youtube_description" cols="60" rows="10"></textarea>
            </li>
        </ul>
        <input type="submit" name="plug_youtube_submit" value="Add">
    </div>
    </form>

=head2 list

B<Note:> the C<< <form> >> will not be there if C<allow_edit> option is set to a false
value.

    <ul id="plug_youtube_list">
        <li>
            <h3><a href="http://www.youtube.com/watch?v=RvcaNIwtkfI">Some club</a></h3>
            <p class="plug_youtube_time">Posted on: Wed Dec 10 21:14:01 2008</p>
            <div class="plug_youtube_video"><object width="200" height="165"><param name="movie" value="http://www.youtube.com/v/RvcaNIwtkfI&hl=en&fs=1"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/RvcaNIwtkfI&hl=en&fs=1" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="200" height="165"></embed></object></div>
            <p class="plug_youtube_description">Description</p>
                <form action="" method="POST">
                <div>
                    <input type="hidden" name="plug_youtube_vid_edit_id" value="03716801501150291228961641000660045686842636">
                    <input type="hidden" name="page" value="videos">
                    <input type="hidden" name="dir" value="/admin/">
                    <input type="submit" class="submit_button_edit" name="plug_youtube_vid_edit_action" value="Edit">
                    <input type="submit" class="submit_button_delete" name="plug_youtube_vid_edit_action" value="Delete">
                </div>
                </form>
        </li>
        <li class="alt">
            <h3><a href="http://www.youtube.com/watch?v=RvcaNIwtkfI">Some club</a></h3>
            <p class="plug_youtube_time">Posted on: Wed Dec 10 21:13:30 2008</p>
            <div class="plug_youtube_video"><object width="200" height="165"><param name="movie" value="http://www.youtube.com/v/RvcaNIwtkfI&hl=en&fs=1"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/RvcaNIwtkfI&hl=en&fs=1" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="200" height="165"></embed></object></div>
            <p class="plug_youtube_description">Description</p>
                <form action="" method="POST">
                <div>
                    <input type="hidden" name="plug_youtube_vid_edit_id" value="051156628115950712289616100613964522347914">
                    <input type="hidden" name="page" value="videos">
                    <input type="hidden" name="dir" value="/admin/">
                    <input type="submit" class="submit_button_edit" name="plug_youtube_vid_edit_action" value="Edit">
                    <input type="submit" class="submit_button_delete" name="plug_youtube_vid_edit_action" value="Delete">
                </div>
                </form>
        </li>
    </ul>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut