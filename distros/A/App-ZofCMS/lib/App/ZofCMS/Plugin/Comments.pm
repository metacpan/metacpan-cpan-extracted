package App::ZofCMS::Plugin::Comments;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use DBI;
use URI;
use HTML::Template;
use HTML::Entities;
use Storable (qw/lock_store lock_retrieve/);

sub new { return bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    my $plug_conf = {
        %{ $config->conf->{comments_plugin}    || {} },
        %{ delete $template->{comments_plugin} || {} },
    };

    return
        unless keys %$plug_conf;

    return
        unless $plug_conf->{dsn};

    my %no_pages = map { $_ => 1 } @{ $plug_conf->{no_pages} || [] };

    return
        if exists $no_pages{ $query->{dir} . $query->{page} };

    return
        if $plug_conf->{page} eq $query->{dir} . $query->{page}
            and not exists $query->{zofcms_comments_page};

    $plug_conf->{comments_page} = exists $query->{zofcms_comments_page}
                                ? $query->{zofcms_comments_page}
                                : $query->{dir} . $query->{page};

    $plug_conf = $self->_fill_defaults( $plug_conf );
    $plug_conf->{remote_host} = $config->cgi->remote_host();

    my $dbh = DBI->connect_cached(
        @$plug_conf{ qw/dsn user pass opts/ }
    ) or die "Failed to connect";

    if ( $query->{zofcms_comments_approve}
        or $query->{zofcms_comments_deny} ) {
        $self->_moderate_comment( $dbh, $plug_conf, $query );
    }

    my $html_template = $self->_prepare_html_template(
        $plug_conf->{comments_page},
        $plug_conf->{page},
        $query,
    );

    if ( defined $query->{zofcms_comments_username}
        and $query->{zofcms_comments_username} eq 'your user name'
    ) {
        $self->_enter_comment( $dbh, $plug_conf, $html_template, $query );
    }

     @{ $template->{t} }{ qw/zofcms_comments zofcms_comments_form/ }
     = (
         $self->_fetch_comments( $dbh, $plug_conf, $query ),
         $html_template->output,
     );

    eval {
        $dbh->commit;
        $dbh->disconnect;
    };

    return 1;
}

sub _moderate_comment {
    my ( $self, $dbh, $plug_conf, $query ) = @_;

    return
        unless exists $query->{zofcms_comment_id};

    my $comments = $dbh->selectall_arrayref(
        "SELECT * FROM $plug_conf->{mod_table} WHERE id = ?;",
        undef,
        $query->{zofcms_comment_id}
    );

    unless ( @$comments ) {
        $self->_print_moderation("No such comment found");
    }

    if ( exists $query->{zofcms_comments_approve} ) {
        $dbh->do(
            "INSERT INTO $plug_conf->{table} VALUES(?, ?, ?, ?, ?, ?);",
            undef,
            @{ shift @$comments },
        );
    }

    if ( $plug_conf->{mod_out_time} ) {
        $dbh->do(
            "DELETE FROM $plug_conf->{mod_table} WHERE time < ?;",
            undef,
            time() - $plug_conf->{mod_out_time},
        );
    }

    $dbh->do(
        "DELETE FROM $plug_conf->{mod_table} WHERE id = ?;",
        undef,
        $query->{zofcms_comment_id},
    );

    $self->_print_moderation("Comment was successfuly denied")
        if exists $query->{zofcms_comments_deny};

    $self->_print_moderation("Comment was successfuly approved");
}

sub _print_moderation {
    my ( $self, $message ) = @_;
    print "Content-type: text/plain\n\n";
    print "$message\n";
    exit;
}

sub _fetch_comments {
    my ( $self, $dbh, $plug_conf, $query ) = @_;
    my $data = $dbh->selectall_arrayref(
        "SELECT * FROM $plug_conf->{table} WHERE page = ?;",
        undef,
        $query->{dir} . $query->{page},
    );

    my $comment_number = 0;
    @$data = sort { $b->[5] <=> $a->[5] }
        map {
            push @$_, $comment_number++; $_
        } @$data;

    if ( $plug_conf->{sort} ) {
        @$data = reverse @$data;
    }

    my @comments_loop = map +{
        name            => $_->[0],
        date            => scalar(localtime($_->[5])),
        comment         => do { my $x = encode_entities($_->[2]); $x =~ s/\n/<br>/g; $x },
        comment_number  => $_->[-1],
    }, @$data;

    my $html_template = HTML::Template->new_scalar_ref(
        \ $self->_comments_template
    );

    $html_template->param( comments => \@comments_loop );

    return $html_template->output;
}

sub _enter_comment {
    my ( $self, $dbh, $plug_conf, $html_template, $query ) = @_;

    return
        unless $self->_is_valid_form( $plug_conf, $html_template, $query );

#'CREATE TABLE comments (name VARCHAR(100), email VARCHAR(200), comment TEXT, page VARCHAR(100), remote_host TEXT, time VARCHAR(11));';

    if ( $plug_conf->{flood_num} ) {
        my $user_comments = $dbh->selectall_arrayref(
            "SELECT * FROM $plug_conf->{table} WHERE remote_host = ? AND time > ?;",
            undef,
            $plug_conf->{remote_host},
            time() - $plug_conf->{flood_time},
        );
        if ( @$user_comments >= $plug_conf->{flood_num} ) {
            $html_template->param(
                success => 0,
                error => 'Sorry, but due to abuse the number of posts'
                         . ' is limited. Please try again shortly'
            );
            return;
        }
    }

    my @dbi_insert_args = (
        @$query{ qw/
                zofcms_comments_name
                zofcms_comments_email
                zofcms_comments_comment
            /
        },
        $plug_conf->{comments_page},
        $plug_conf->{remote_host},
        time(),
    );

    if ( $plug_conf->{moderate} ) {
        my $mod_id = rand() . time() . rand();
        $dbh->do(
            "INSERT INTO $plug_conf->{mod_table} VALUES(?, ?, ?, ?, ?, ?, ?);",
            undef,
            @dbi_insert_args,
            $mod_id,
        );

        $self->_send_mod_email( $plug_conf, @dbi_insert_args, $mod_id );
    }
    else {
        my $r = $dbh->do(
            "INSERT INTO $plug_conf->{table} VALUES(?, ?, ?, ?, ?, ?);",
            undef,
            @dbi_insert_args,
        );
        $self->_send_comment_entered_email( $plug_conf, @dbi_insert_args )
            if $plug_conf->{send_entered};
    }
}

sub _send_mod_email {
    my ( $self, $plug_conf, @data ) = @_;

    my %data;
    @data{ qw/name email comment page host time id/ } = @data;

    my $approve_uri = URI->new( $plug_conf->{uri} );

    my @query = $approve_uri->query_form;
    push @query, zofcms_comment_id => $data{id};

    my $deny_uri = $approve_uri->clone;
    $approve_uri->query_form( @query, zofcms_comments_approve => 1 );
    $deny_uri->query_form( @query, zofcms_comments_deny => 1 );

    my $body_template = HTML::Template->new_scalar_ref(
        \ $self->_get_mail_template
    );

    $body_template->param(
        mod         => 1,
        approve     => $approve_uri->as_string,
        deny        => $deny_uri->as_string,
        time        => scalar(localtime $data{time}),
        map +( $_ => $data{ $_ } ),
            qw/page host email name comment/,
    );

    $self->_send_mail( $plug_conf, $body_template->output );
}

sub _send_comment_entered_email {
    my ( $self, $plug_conf, @data ) = @_;

    my %data;
    @data{ qw/name email comment page host time/ } = @data;


    my $body_template = HTML::Template->new_scalar_ref(
        \ $self->_get_mail_template
    );

    $data{time} = localtime $data{time};
    $body_template->param( %data );

    $self->_send_mail( $plug_conf, $body_template->output );

    return;
}

sub _send_mail {
    my ( $self, $plug_conf, $body ) = @_;
    require Mail::Send;

    my $email = Mail::Send->new;
    $email->subject( $plug_conf->{subject} );

    my $to = ref $plug_conf->{email_to}
           ? $plug_conf->{email_to}
           : [ $plug_conf->{email_to} ];

    $email->to( @$to );

    my $fh;
    if ( $plug_conf->{mailer} ) {
        $Mail::Mailer::testfile::config{outfile} = 'mailer.testfile';
        $fh = $email->open( $plug_conf->{mailer} );
    }
    else {
        $fh = $email->open;
    }

     print $fh $body;
     $fh->close;

    return;
}

sub _is_valid_form {
    my ( $self, $plug_conf, $html_template, $query ) = @_;

    my @form_fields = qw/
        zofcms_comments_name
        zofcms_comments_email
        zofcms_comments_comment
    /;

    for ( @form_fields ) {
        $query->{$_} = ''
            unless defined $query->{$_};
    }

    my ( $name, $email, $comment ) = @$query{ @form_fields };

    if ( $plug_conf->{must_name} and not length $name ) {
        $html_template->param( error => 'Missing <em>Name</em> field' );
        return;
    }

    if ( $plug_conf->{must_email} and not length $email ) {
        $html_template->param( error => 'Missing <em>E-mail</em> field' );
        return;
    }

    if ( $plug_conf->{must_comment} and not length $comment ) {
        $html_template->param( error => 'Missing <em>Comment</em> field' );
        return;
    }

    if ( length( $name ) > $plug_conf->{name_max} ) {
        $html_template->param(
            error => 'Parameter <em>Name</em> cannot exceed '
                     . $plug_conf->{name_max} . ' characters in length'
        );
        return;
    }

    if ( length( $email ) > $plug_conf->{email_max} ) {
        $html_template->param(
            error => 'Parameter <em>E-mail</em> cannot exceed '
                     . $plug_conf->{email_max} . ' characters in length'
        );
        return;
    }

    if ( length( $comment ) > $plug_conf->{comment_max} ) {
        $html_template->param(
            error => 'Parameter <em>Comment</em> cannot exceed '
                     . $plug_conf->{comment_max} . ' characters in length'
        );
        return;
    }

    for ( $name, $email, $comment ) {
        $_ = 'N/A'
            unless length;
    }

    $html_template->param( success => 1 );

    @$query{ @form_fields } = ( $name, $email, $comment );

    return 1;
}

sub _prepare_html_template {
    my ( $self, $comments_page, $page, $query ) = @_;
    my $html_template = HTML::Template->new_scalar_ref(
        \ $self->_form_template
    );

    $html_template->param(
        name          => $query->{zofcms_comments_name},
        email         => $query->{zofcms_comments_email},
        comment       => $query->{zofcms_comments_comment},
        page          => $page,
        comments_page => $comments_page,
        back_to_comments_page => $query->{zofcms_comments_page},
    );

    return $html_template;
}

sub _fill_defaults {
    my ( $self, $plug_conf ) = @_;
    $plug_conf = {
        'sort'          => 0,
        table           => 'comments',
        mod_table       => 'mod_comments',
        page            => '/comments',
        must_name       => 0,
        must_email      => 0,
        must_comment    => 1,
        name_max        => 100,
        email_max       => 200,
        comment_max     => 10000,
        moderate        => 1,
        send_entered    => 1,
        subject         => 'ZofCMS Comments',
        flood_num       => 2,
        flood_time      => 180,
        mod_out_time    => 1209600,
        opts            => { RaiseError => 1, AutoCommit => 1 },

        %$plug_conf,
    };
}

sub _comments_template {
    return <<'END_TEMPLATE';
<ul class="zofcms_comments">
<tmpl_loop name="comments">
    <li id="zofcms_comment_<tmpl_var name="comment_number">">
        <p class="zofcms_comments_name"><a href="#zofcms_comment_<tmpl_var name="comment_number">"><tmpl_var escape="html" name="name"></a></p>
        <p class="zofcms_comments_date"><tmpl_var escape="html" name="date"></p>
        <p class="zofcms_comments_comment"><tmpl_var name="comment"></p>
    </li>
</tmpl_loop>
</ul>
END_TEMPLATE
}

sub _form_template {
    return <<'END_TEMPLATE';
<tmpl_if name="success"><p class="success">Your comment was successfuly added.</p>
<p>Feel free to go back to the <a href="/index.pl?page=<tmpl_var name="back_to_comments_page" escape="html">">original page</a>.</p>
<tmpl_else>
<tmpl_if name="error"><p class="error"><tmpl_var name="error"></p></tmpl_if>
<form class="zofcms_comments" action="" method="POST">
<fieldset>
    <legend>Create new comment</legend>
    <input type="hidden" name="zofcms_comments_page" value="<tmpl_var name="comments_page" escape="html">">
    <input type="hidden" name="zofcms_comments_username" value="your user name">
    <input type="hidden" name="page" value="<tmpl_var escape="html"name="page">">
    <ul>
        <li>
            <label for="zofcms_comments_name">Name: </label
            ><input type="text" name="zofcms_comments_name"
            id="zofcms_comments_name" value="<tmpl_var escape="html" name="name">">
        </li>
        <li>
            <label for="zofcms_comments_email">E-mail: </label
            ><input type="text" name="zofcms_comments_email"
            id="zofcms_comments_email" value="<tmpl_var escape="html" name="email">">
        </li>
        <li>
            <label for="zofcms_comments_comment">Comment: </label
            ><textarea name="zofcms_comments_comment"
            id="zofcms_comments_comment" cols="40" rows="10"><tmpl_var name="comment" escape="html"></textarea>
        </li>
    </ul>
    <input id="zofcms_comments_submit" type="submit" value="Post">
</fieldset>
</form>
</tmpl_if>
END_TEMPLATE
}

sub _get_mail_template {
    return <<'END_MAIL_TEMPLATE';
<tmpl_if name="mod">
Approve: <tmpl_var name="approve">

Deny: <tmpl_var name="deny">

</tmpl_if>
Comment on page: <tmpl_var name="page">
From: <tmpl_var name="name"> [ <tmpl_var name="host"> ]
Time: <tmpl_var name="time">
E-mail: <tmpl_var name="email">
Comment:
<tmpl_var name="comment">
END_MAIL_TEMPLATE
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::Comments - drop-in visitor comments support.

=head1 SYNOPSIS

In your "main config" file:

    comments_plugin => {
        dsn         => "DBI:mysql:database=test;host=localhost",
        user        => 'test',
        pass        => 'test',
        email_to    => [ 'admin@example.com', 'admin2@example.com' ],
    },

In your ZofCMS template:

    plugins => [ qw/Comments/ ],

In your "comments" page L<HTML::Template> template, which we set to be C</comments> by default:

    <tmpl_var name="zofcms_comments_form">

In any page on which you wish to have comments:

    <tmpl_var name="zofcms_comments_form">
    <tmpl_var name="zofcms_comments">

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS>. It provides means to easily add
"visitor comments" to your pages. The plugin offers configurable
flood protection ( $x comments per $y seconds ) as well as ability to
notify you of new comments via e-mail. The "moderation" function is also
implemented, what that means is that you (the admin) would get two links
(via e-mail) following one of them will approve the comment; following the
other will simply delete the comment from the database.

I am an utterly lazy person, thus you may find that not everything you
may want to configure in the plugin is configurable. The plugin is
yet to undergo (at the time of this writing) deployment testing, as in
how flexible it is. If you'd like to see some features added, don't be shy
to drop me a line to C<zoffix@cpan.org>

This documentation assumes you've read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 HOW IT ALL COMES TOGETHER OR "WHAT'S THAT 'comments' PAGE ANYWAY?"

So here is how it works, you have some page where you added the plugin's
functionality. Visitor enters his/hers comment and pressed "Post" button.
The request will be POSTed to a "comments" page and depending on what
the visitor entered he or she will either get an error with ability to
fix it or a "success" message with an ability to go back to the page
on which the comment was created. The reason for this "comments" page is
that I couldn't figure out a simple way to have the comments markup inserted
with simple C<< <tmpl_var> >> and keep any page on which the plugin
was used small enough for the user to see the error message easily.

The "comments" must have <tmpl_var name="zofcms_comments_form"> on
it somewhere for the plugin to work.

=head1 MAIN CONFIG OR ZofCMS TEMPLATES?

If you have a sharp eye, you've noticed that plugin's configuration was
placed into the 'main config file' in the SYNOPSIS. You actually B<don't
have to>
do that and can keep plugin's configuration in your ZofCMS template,
but personally I find it much easier to just drop it into the main config
and enable it on per-page basis by sticking only C<Comments> in the list
of the plugins on ZofCMS templates.

=head1 THE SQL TABLES!

Under the hood the plugin uses L<DBI> to stick data into SQL tables.
Generally speaking you shouldn't have trouble using the plugin with
$database_of_your_choice; however, the plugin was tested only with MySQL
database. B<Before you can use the plugin you need to create one or
two tables in your database>. The columns B<have to> be named those names
and be in that order:

    # comments table
    CREATE TABLE comments (name VARCHAR(100), email VARCHAR(200), comment TEXT, page VARCHAR(100), remote_host TEXT, time VARCHAR(11));

    #moderation table
    CREATE TABLE mod_comments (name VARCHAR(100), email VARCHAR(200), comment TEXT, page VARCHAR(100), remote_host TEXT, time VARCHAR(11), id TEXT);

Now, the note on value types. The C<name>, C<email> and C<comment> is the
data that the comment poster posts. Since the maximum lengths of those
fields are configurable, pick the value types you think fit. The C<page>
column will contain the "page" on which the comment was posted. In other
words, if the comment was posted on
C<http://example.com/?page=/foo/bar/baz>, the C<page> cell will contain
C</foo/bar/baz>. The C<remote_host> is obtained from
L<CGI>'s C<remote_host()> method. The C<time> cell is obtained from
the call to C<time()> and the C<id> in moderation table is generated with
C<< rand() . time() . rand() >> (keep those flames away plz).

=head1 COMMENT MODERATION

When moderation of comments is turned on in the plugin you will get
two links e-mailed when a new comment was submitted. One is "approve"
and another one is "deny". Functions of each are self explanatory. What
happens is that the comment is first placed in the "moderation table". If
you click "approve", the comment is moved into the "comments table". If
the comment is denied by you, it is simply deleted from the
"moderation table". There is a feature that allows all comments that
are older than $x seconds (see C<mod_out_time> argument) to be deleted
from the "moderation table" automatically.

=head1 WHAT? NO CAPTCHA?

You will notice that there is no "captcha"
(L<http://en.wikipedia.org/wiki/Captcha>) thing done with comments form
generated by the plugin. The reason for that is that I hate them... pure
hate. I think the worst captcha I ever came across was this:
L<http://www.zoffix.com/new/captcha-wtf.png>. But most of all, I think
they are plain annoying.

In this plugin I implemented a non-annoying "captcha" mechanizm suggested
by one of the people I know who claimed it works very well. At the time
of this writing I am not yet aware of how "well" it really is. Basically,
the plugin sticks C<< <input type="hidden" name="zofcms_comments_username" value="your user name"> >> in the form. When checking the parameters,
the plugin checks that this hidden input's value matches. If it doesn't,
boot the request. Apparently the technique works much better when the
C<< <input> >> is not of C<type="hidden"> but I am very against "hiding"
something with CSS.

So, time will show, if this technique proves to be a failure, expect
the plugin to have an option to provide a better "captcha" mechanizm. As for
now, this is all you get, although, I am open for good ideas.

=head1 GOODIES IN ZofCMS TEMPLATE/MAIN CONFIG FILE

=head2 C<plugins>

    plugins => [ qw/Comments/ ],

This goes without saying that you'd need to stick 'Comments' into the list
of plugins used in ZofCMS template. As opposed to many other plugins
this plugin will not bail out of the execution right away if
C<comments_plugin> first level key (described below) is not specified in
the template (however it will if you didn't specify C<comments_plugin> in
neither the ZofCMS template nor the main config file).

=head2 C<comments_plugin>

    comments_plugin => {
        # mandatory
        dsn             => "DBI:mysql:database=test;host=localhost",
        page            => '/comments',

        #optional in some cases, no defaults
        email_to        => [ 'admin@test.com', 'admin2@test.com' ],

        #optional, but default not specified
        user            => 'test', # user,
        pass            => 'test', # pass
        opts            => { RaiseError => 1, AutoCommit => 1 },
        uri             => 'http://yoursite.com',
        mailer          => 'testfile',
        no_pages        => [ qw(/foo /bar/beer /baz/beer/meer) ],

        # optional, defaults presented here
        sort            => 0
        table           => 'comments',
        mod_table       => 'mod_comments',
        must_name       => 0,
        must_email      => 0,
        must_comment    => 1,
        name_max        => 100,
        email_max       => 200,
        comment_max     => 10000,
        moderate        => 1,
        send_entered    => 1,
        subject         => 'ZofCMS Comments',
        flood_num       => 2,
        flood_time      => 180,
        mod_out_time    => 1209600,
    }

Whoosh, now that's a list of options! Luckly, most of them have defaults.
I'll go over them in a second. Just want to point out that all these
arguments can be set in the "main config file" same way you'd set them
in ZofCMS template (the first-level C<comments_plugin> key). In fact,
I recommend you set them all in ZofCMS main config file instead of ZofCMS
templates, primarily because you'd
want to have it duplicated at least twice: once on the "comments page"
and once on the page on which you actually want to have visitors' comments
functionality. So here are the possible arguments:

=head3 C<dsn>

    dsn => "DBI:mysql:database=test;host=localhost",

B<Mandatory>. Takes a scalar as a value which must contain a valid
"$data_source" as explained in L<DBI>'s C<connect_cached()> method (which
plugin currently uses).

=head3 C<email_to>

    email_to => [ 'admin@test.com', 'admin2@test.com' ],

B<Mandatory unless> C<moderate> B<and> C<send entered> are set to a
false values. Takes either a scalar or an arrayref as a value.
Specifying a scalar is equivalent to specifying an arrayref with just
that scalar in it. When C<moderate> B<or> C<send_entered> are set
to true values, the e-mail will be sent to each of the addresses
specified in the C<email_to> arrayref.

=head3 C<page>

    page => '/comments',

B<Optional>. This is the "comments page" that I explained in the
C<HOW IT ALL COMES TOGETHER OR "WHAT'S THAT 'comments' PAGE ANYWAY?">
section above. Argument takes a string as a value. That value is what
you'd set the C<page> query parameter in order to get to the "comments
page". B<Make sure> you also prepend the C<dir>. In the example above
the comments page is accessed via
C<http://example.com/index.pl?page=comments&dir=/>. B<Defaults to:>
C</comments>

=head3 C<user>

    user => 'test_db_user',

B<Optional>. Specifies the username to use when connecting to the
SQL database used by the plugin. B<By default> is not specified.

=head3 C<pass>

    pass => 'teh_password',

B<Optional>. Specifies the password to use when connecting to the
SQL database used by the plugin. B<By default> is not specified.

=head3 C<opts>

    opts => { RaiseError => 1, AutoCommit => 1 },

B<Optional>. Takes a hashref as a value.
Specifies additional options to L<DBI>'s C<connect_cached()>
method, see L<DBI>'s documentation for possible keys/values of this
hashref. B<Defaults to:> C<< { RaiseError => 1, AutoCommit => 1 } >>

=head3 C<uri>

    uri => 'http://yoursite.com/index.pl?page=/comments',

B<Optional>. The only place in which this argument is used is for
generating the "Approve" and "Deny" URIs in the e-mail sent to you when
C<moderate> is set to a true value. Basically, here you would give
the plugin a URI to your "comments page" (see C<page> argument above).
If you don't specify this argument, nothing will explode (hopefully) but
you won't be able to "click" the "Approve"/"Deny" URIs.

=head3 C<mailer>

    mailer => 'testfile',

B<Optional>. When either C<moderate> or C<send_entered> arguments are
set to true values, the C<mailer> argument specifies which "mailer" to
use to send e-mails. See documentation for L<Mail::Mailer> for possible
mailers. B<By default> C<mailer> argument is not specified, thus the
"mailers" will be tried until one of them works. When C<mailer> is set
to C<testfile>, the mail file will be located at the same place ZofCMS'
C<index.pl> file is located.

=head3 C<no_pages>

    no_pages => [ qw(/foo /bar/beer /baz/beer/meer) ],

B<Optional>. Takes an arrayref as a value. Each element of that arrayref
B<must> be a C<page> with C<dir> appended to it, even if C<dir> is C</>
(see the "Note on page and dir query parameters" in L<App::ZofCMS::Config>
documentation). Basically, any pages listed here will not be processed
by the plugin even if the plugin is listed in C<plugins> first-level
ZofCMS template key. B<By default> is not set.

=head3 C<sort>

    sort => 0,

B<Optional>. Currently accepts only true or false values.
When set to a true value
the comments on the page will be listed in the "oldest-first" fashion.
When set to a false value the comments will be reversed - "newest-first"
sorting. B<Defaults to:> C<0>.

=head3 C<table>

    table => 'comments',

B<Optional>. Takes a string as a value which must contain the name of
SQL table used for storage of comments. See C<THE SQL TABLES!> section
above for details. B<Defaults to:> C<comments>

=head3 C<mod_table>

    mod_table => 'mod_comments',

B<Optional>. Same as C<table> argument (see above) except this one
specifies the name of "moderation table", i.e. the comments awaiting
moderation will be stored in this SQL table. B<Defaults to:>
C<mod_comments>

=head3 C<must_name>, C<must_email> and C<must_comment>

    must_name    => 0,
    must_email   => 0,
    must_comment => 1,

B<Optional>. The "post comment" form generated by the plugin contains
the C<Name>, C<E-mail> and C<Comment> fields. The
C<must_name>, C<must_email> and C<must_comment> arguments take either
true or false values. When set to a true value, the visitor must fill
the corresponding field in order to post the comment. If field is
spefied as "optional" (by setting a false value) and the visitor doesn't
fill it, it will default to C<N/A>. B<By default> C<must_name> and
C<must_email> are set to false values and C<must_comment> is set to
a true value.

=head3 C<name_max>, C<email_max> and C<comment_max>

    name_max    => 100,
    email_max   => 200,
    comment_max => 10000,

B<Optional>. Same principle as with C<must_*> arguments explained above,
except C<*_max> arguments specify the maximum length of the fields. If
visitor enters more than specified by the corresponding C<*_max> argument,
he or she (hopefully no *it*s) will get an error. B<By default>
C<name_max> is set to C<100>, C<email_max> is set to C<200> and
C<comment_max> is set to C<10000>.

=head3 C<moderate>

    moderate => 1,

B<Optional>. Takes either true or false values. When set to a true value
will enable "moderation" functionality. See C<COMMENT MODERATION>
section above
for details. When set to a false value, comments will appear on the
page right away. B<Note:> when set to a true value e-mail will be
automatically sent to C<email_to> addresses. B<Defaults to:> C<1>

=head3 C<send_entered>

    send_entered => 1,

B<Optional>. Takes either true or false values, regarded only when
C<moderate> argument is set to a false value. When set to a true value
will dispatch an e-mail about a new comment to the addresses set
in C<email_to> argument. B<Defaults to:> C<1>

=head3 C<subject>

    subject => 'ZofCMS Comments',

B<Optional>. Takes a string as a value. Nothing fancy, this will be
the "Subject" of the e-mails sent by the plugin (see C<moderate> and
C<send_entered> arguments). B<Defaults to:> C<'ZofCMS Comments'>

=head3 C<flood_num>

    flood_num => 2,

B<Optional>. Takes a positive integer or zero as a value. Indicates how many
comments a visitor may post in C<flood_time> (see below) amount of time.
Setting this value to C<0> effectively B<disables> flood protection.
B<Defaults to:> C<2>

=head3 C<flood_time>

    flood_time => 180,

B<Optional>. Takes a positive integer as a value. Specifies the time
I<in seconds> during which the visitor may post only C<flood_num> (see
above) comments. B<Defaults to:> C<180>

=head3 C<mod_out_time>

    mod_out_time => 1209600,

B<Optional>. Takes a positive integer or false value as a value. When
set to a positive integer indicates how old (B<in seconds>) the comment
in C<mod_table> must get before it will be automatically removed from
the C<mod_table> (i.e. "denied"). Comments older than C<mod_out_time>
seconds will I<not> actually be deleted until moderation takes place, i.e.
until you approve or deny some comment. Setting this value to C<0>
effectively disables this "auto-delete" feature. B<Defaults to:>
C<1209600> (two weeks)

=head1 EXAMPLES

The C<examples/> directory of this distribution contains main config file
and HTML/ZofCMS templates which were used during testing of this plugin.

=head1 PREREQUISITES

This plugin requires more goodies than any other ZofCMS plugin to the date.
Plugin needs the following modules for happy operation. Plugin was tested
with module versions indicated:

    'DBI'            => 1.602,
    'URI'            => 1.35,
    'HTML::Template' => 2.9,
    'HTML::Entities' => 1.35,
    'Storable'       => 2.18,
    'Mail::Send'     => 2.04,

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