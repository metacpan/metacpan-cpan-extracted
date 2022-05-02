package App::org2wp;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Perinci::Object qw(envresmulti);
use POSIX qw(strftime);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-01'; # DATE
our $DIST = 'App-org2wp'; # DIST
our $VERSION = '0.012'; # VERSION

our %SPEC;

sub _fmt_timestamp_org {
    my $time = shift;

    strftime("%Y-%m-%d %a %H:%M", localtime($time));
}

$SPEC{'org2wp'} = {
    v => 1.1,
    summary => 'Publish Org document (or heading) to WordPress as blog post',
    description => <<'_',

This is originally a quick hack because I couldn't make
[org2blog](https://github.com/punchagan/org2blog) on my Emacs installation to
work after some update. `org2wp` uses the same format as `org2blog`, but instead
of being an Emacs package, it is a CLI script written in Perl.

First, create `~/org2wp.conf` containing the API credentials, e.g.:

    proxy=https://YOURBLOGNAME.wordpress.com/xmlrpc.php
    username=YOURUSERNAME
    password=YOURPASSWORD

Note that `proxy` is the endpoint URL of your WordPress instance's XML-RPC
server, which can be hosted on `wordpress.com` or on other server, including
your own. It has nothing to do with HTTP/HTTPS proxy; the term "proxy" is used
by the <pm:XMLRPC::Lite> and <pm:SOAP::Lite> Perl libraries and `org2wp` simply
uses the same terminology.

You can also put multiple credentials in the configuration file using profile
sections, e.g.:

    [profile=blog1]
    proxy=https://YOURBLOG1NAME.wordpress.com/xmlrpc.php
    username=YOURUSERNAME
    password=YOURPASSWORD

    [profile=blog2]
    proxy=https://YOURBLOG2NAME.wordpress.com/xmlrpc.php
    username=YOURUSERNAME
    password=YOURPASSWORD

and specify which profile you want using command-line option e.g.
`--config-profile blog1`.

### Document mode

You can use the whole Org document file as a blog post (document mode) or a
single heading as a blog post (heading mode). The default is document mode. To
create a blog post, write your Org document (e.g. in `post1.org`) using this
format:

    #+TITLE: Blog post title
    #+CATEGORY: cat1, cat2
    #+TAGS: tag1,tag2,tag3

    Text of your post ...
    ...

then:

    % org2wp post1.org

this will create a draft post. To publish directly:

    % org2wp --publish post1.org

Note that this will also modify your Org file and insert this setting line at
the top:

    #+POSTID: 1234
    #+POSTTIME: [2020-09-16 Wed 11:51]

where 1234 is the post ID retrieved from the server when creating the post, and
post time will be set to the current local time.

After the post is created, you can update using the same command:

    % org2wp post1.org

You can use `--publish` to publish the post, or `--no-publish` to revert it to
draft.

To set more attributes:

    % org2wp post1.org --comment-status open \
        --extra-attr ping_status=closed --extra-attr sticky=1

Another example, to schedule a post in the future:

    % org2wp post1.org --schedule 20301225T00:00:00

### Heading mode

In heading mode, each heading will become a separate blog post. To enable this
mode, specify `--post-heading-level` (`-l`) to 1 (or 2, or 3, ...). This will
cause a level-1 (or 2, or 3, ...) heading to be assumed as an individual blog
post. For example, suppose you have `blog.org` with this content:

    * Post A                  :tag1:tag2:tag3:
    :PROPERTIES:
    :CATEGORY: cat1, cat2, cat3
    :END:

    Some text...

    ** a heading of post A
    more text ...
    ** another heading of post A
    even more text ...

    * Post B                  :tag2:tag4:
    Some text ...

with this command:

    % org2wp blog.org -l 1

there will be two blog posts to be posted because there are two level-1
headings: `Post A` and `Post B`. Post A contains level-2 headings which will
become headings of the blog post. Headline tags will become blog post tags, and
to specify categories you use the property `CATEGORY` in the `PROPERTIES`
drawer.

If, for example, you specify `-l 2` instead of `-l 1` then the level-2 headings
will become blog posts.

In heading mode, you can use several options to select only certain headlines
which contain (or don't contain) specified tags.

### FAQ

#### What if I want to set HTTP/HTTPS proxy?

You can set the environment variable `HTTP_proxy` (and `HTTP_proxy_user` and
`HTTP_proxy_pass` additionally). See the <pm:SOAP::Lite> documentation for more
details, which uses <pm:LWP::UserAgent> underneath.

_
    args => {
        proxy => {
            schema => 'str*', # XXX url
            req => 1,
            description => <<'_',

Example: `https://YOURBLOGNAME.wordpress.com/xmlrpc.php`.

Note that `proxy` is the endpoint URL of your WordPress instance's XML-RPC
server, which can be hosted on `wordpress.com` or on other server, including
your own. It has nothing to do with HTTP/HTTPS proxy; the term "proxy" is used
by the <pm:XMLRPC::Lite> and <pm:SOAP::Lite> Perl libraries and `org2wp` simply
uses the same terminology.

_
            tags => ['credential'],
        },
        username => {
            schema => 'str*',
            req => 1,
            tags => ['credential'],
        },
        password => {
            schema => 'str*',
            req => 1,
            tags => ['credential'],
        },

        filename => {
            summary => 'Path to Org document to publish',
            schema => 'filename*',
            req => 1,
            pos => 0,
            cmdline_aliases => {f=>{}},
        },

        post_heading_level => {
            summary => 'Specify which heading level to be regarded as an individula blog post',
            schema => 'posint*',
            cmdline_aliases => {l=>{}},
            description => <<'_',

If specified, this will enable *heading mode* instead of the default *document
mode*. In the document mode, the whole Org document file is regarded as a single
blog post. In the *heading mode*, a heading of certain level will be regarded as
a single blog post.

_
            tags => ['category:heading-mode'],
        },
        include_heading_tags => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'include_heading_tag',
            summary => 'Only include heading that has all specified tag(s)',
            schema => ['array*', of=>'str*'],
            tags => ['category:heading-mode'],
        },
        exclude_heading_tags => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'exclude_heading_tag',
            summary => 'Exclude heading that has any of the specified tag(s)',
            schema => ['array*', of=>'str*'],
            tags => ['category:heading-mode'],
        },

        publish => {
            summary => 'Whether to publish post or make it a draft',
            schema => 'bool*',
            description => <<'_',

Equivalent to `--extra-attr post_status=published`, while `--no-publish` is
equivalent to `--extra-attr post_status=draft`.

_
        },
        schedule => {
            summary => 'Schedule post to be published sometime in the future',
            schema => 'date*',
            description => <<'_',

Equivalent to `--publish --extra-attr post_date=DATE`. Note that WordPress
accepts date in the `YYYYMMDD"T"HH:MM:SS` format, but you specify this option in
regular ISO8601 format. Also note that time is in your chosen local timezone
setting.

_
        },
        post_password => {
            summary => 'Set password for posts',
            schema => 'str*',
        },
        comment_status => {
            summary => 'Whether to allow comments (open) or not (closed)',
            schema => ['str*', in=>['open','closed']],
            default => 'closed',
        },
        extra_attrs => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'extra_attr',
            summary => 'Set extra post attributes, e.g. ping_status, post_format, etc',
            schema => ['hash*', of=>'str*'],
        },
    },
    args_rels => {
        choose_one => [qw/publish schedule/],
    },
    features => {
        dry_run => 1,
    },
    links => [
        {url=>'prog:pod2wp'},
        {url=>'prog:html2wp'},
        {url=>'prog:wp-xmlrpc'},
    ],
};
sub org2wp {
    my %args = @_;

    my $dry_run = $args{-dry_run};

    my $filename = $args{filename};
    (-f $filename) or return [404, "No such file '$filename'"];

    require File::Slurper;
    my $file_content = File::Slurper::read_text($filename);

    my $post_heading_level = $args{post_heading_level};
    my $mode = 'document';
    if (defined $post_heading_level) {
        $mode = 'heading';
    }

    # 1. collect the posts information: for each post: the org source, its
    # title, existing post ID (if available), as well as all categories and tags
    # we want to use.

    my @posts_srcs;   # ("org1", "org2", ...)
    my @posts_htmls;  # ("html1", "html2", ...)
    my @posts_titles; # ("title1", "title2", ...)
    my @orig_posts_ids;# (101,     undef,   ...)
    my @new_posts_ids;
    my @posts_tags;   # ([tag1_for_post1,tag2_for_post1], [tag1_for_post2,...], ...)
    my @posts_cats;   # ([cat1_for_post1,cat2_for_post1], [cat1_for_post2,...], ...)
    my @posts_times;  # ("[2020-09-17 Thu 01:55]", ...)
    my @posts_headlines; # ($headline_obj1, ...) # only for heading mode

  L1_COLLECT_POSTS_INFORMATION: {
        require Org::To::HTML::WordPress;
        if ($mode eq 'heading') {
            require Org::Parser;
            my $org_parser = Org::Parser->new;
            my $org_doc   = $org_parser->parse($file_content, {ignore_unknown_settings=>1});

            my @posts_headlines0 = $org_doc->find(
                sub {
                    my $el = shift;
                    $el->isa("Org::Element::Headline") && $el->level == $post_heading_level;
                });
            for my $headline (@posts_headlines0) {
                push @posts_headlines, $headline;
                push @posts_srcs, $headline->children_as_string;
                push @posts_titles, $headline->title->as_string;

                # find the first properties drawer
                my ($properties_drawer) = $headline->find(
                    sub {
                        my $el = shift;
                        $el->isa("Org::Element::Drawer") && $el->name eq 'PROPERTIES';
                    });
                my $properties = $properties_drawer ? $properties_drawer->properties : {};

                push @orig_posts_ids, $properties->{POSTID};

                push @posts_tags, [$headline->get_tags];

                push @posts_cats, [split /\s*,\s*/, ($properties->{CATEGORY} // $properties->{CATEGORIES} // '')];

                my $exclude_reason;
              FILTER_POST: {
                    my $post_tags = $posts_tags[-1];
                    if (defined $args{include_heading_tags} && @{ $args{include_heading_tags} }) {
                        for my $tag (@{ $args{include_heading_tags} }) {
                            unless (grep { $_ eq $tag } @$post_tags) {
                                $exclude_reason = "Does not contain tag '$tag' (specified in include_heading_tags)";
                                last FILTER_POST;
                            }
                        }
                    }
                    if (defined $args{exclude_heading_tags} && @{ $args{exclude_heading_tags} }) {
                        for my $tag (@{ $args{exclude_heading_tags} }) {
                            if (grep { $_ eq $tag } @$post_tags) {
                                $exclude_reason = "Contains tag '$tag' (specified in exclude_heading_tags)";
                                last FILTER_POST;
                            }
                        }
                    }
                } # FILTER_POST

                if ($exclude_reason) {
                    pop @posts_headlines;
                    pop @posts_srcs;
                    log_info "Excluded blog post in heading, title=%s, ID=%d, tags=%s, cats=%s (reason=%s)",
                        pop(@posts_titles),
                        pop(@orig_posts_ids),
                        pop(@posts_tags),
                        pop(@posts_cats),
                        $exclude_reason;
                } else {
                    log_info "Found blog post[%d] in heading, title=%s, ID=%d, tags=%s, cats=%s",
                        scalar(@posts_srcs),
                        $posts_titles[-1],
                        $orig_posts_ids[-1],
                        $posts_tags[-1],
                        $posts_cats[-1];
                }

            }
        } else {
            push @posts_srcs, $file_content;

            my $title;
            if ($file_content =~ /^#\+TITLE:\s*(.+)/m) {
                $title = $1;
                log_trace("Extracted title from Org document: %s", $title);
            } else {
                $title = "(No title)";
            }
            push @posts_titles, $title;

            my $post_tags;
            if ($file_content =~ /^#\+TAGS?:\s*(.+)/m) {
                $post_tags = [split /\s*,\s*/, $1];
                log_trace("Extracted tags from Org document: %s", $post_tags);
            } else {
                $post_tags = [];
            }
            push @posts_tags, $post_tags;

            my $post_cats;
            if ($file_content =~ /^#\+CATEGOR(?:Y|IES):\s*(.+)/m) {
                $post_cats = [split /\s*,\s*/, $1];
                log_trace("Extracted categories from Org document: %s", $post_cats);
            } else {
                $post_cats = [];
            }
            push @posts_cats, $post_cats;

            my $post_id;
            if ($file_content =~ /^#\+POSTID:\s*(\d+)/m) {
                $post_id = $1;
                log_trace("Org document already has post ID: %s", $post_id);
            }
            push @orig_posts_ids, $post_id;
        }
    } # L1_COLLECT_POSTS_INFORMATION

    # 2. convert the org sources to htmls

  L2_CONVERT_ORG_TO_HTML:
    for my $post_idx (0 .. $#posts_srcs) {
        log_info("Converting Org%s to HTML ...",
                 $mode eq 'heading' ? "[$post_idx]" : '');
        my $res = Org::To::HTML::WordPress::org_to_html_wordpress(
            source_str => $posts_srcs[$post_idx],
            naked => 1,
            ignore_unknown_settings => 1,
        );
        return [500, "Can't convert Org[$post_idx] to HTML: $res->[0] - $res->[1]"]
            if $res->[0] != 200;
        push @posts_htmls, $res->[2];
    } # L2_CONVERT_ORG_TO_HTML

    require XMLRPC::Lite;
    my $call;

    # 3. create categories if necessary

    my $cat_ids = {};
    L3_CREATE_CATEGORIES: {
        log_info("[api] Listing all known categories ...");
        $call = XMLRPC::Lite->proxy($args{proxy})->call(
            'wp.getTerms',
            1, # blog id, set to 1
            $args{username},
            $args{password},
            'category',
        );
        return [$call->fault->{faultCode}, "Can't list categories: ".$call->fault->{faultString}]
            if $call->fault && $call->fault->{faultCode};
        my $all_known_cats = $call->result;
        for my $cat (map { @$_ } @posts_cats) {
            if (my ($cat_detail) = grep { $_->{name} eq $cat } @$all_known_cats) {
                $cat_ids->{$cat} = $cat_detail->{term_id};
                log_trace("Category %s already exists with ID %d, will not be recreating",
                          $cat, $cat_detail->{term_id});
                next;
            }
            if ($dry_run) {
                log_info("[DRY-RUN] [api] Creating category %s ...", $cat);
                next;
            }
            log_info("[api] Creating category %s ...", $cat);
            $call = XMLRPC::Lite->proxy($args{proxy})->call(
                'wp.newTerm',
                1, # blog id, set to 1
                $args{username},
                $args{password},
                {taxonomy=>"category", name=>$cat},
             );
            return [$call->fault->{faultCode}, "Can't create category '$cat': ".$call->fault->{faultString}]
                if $call->fault && $call->fault->{faultCode};
            push @$all_known_cats, { name=>$cat, term_id=>$call->result };
            $cat_ids->{$cat} = $call->result;
        }
    } # L3_CREATE_CATEGORIES

    # 4. create tags if necessary

    my $tag_ids = {};
    L4_CREATE_TAGS: {
        log_info("[api] Listing all known tags ...");
        $call = XMLRPC::Lite->proxy($args{proxy})->call(
            'wp.getTerms',
            1, # blog id, set to 1
            $args{username},
            $args{password},
            'post_tag',
        );
        return [$call->fault->{faultCode}, "Can't list tags: ".$call->fault->{faultString}]
            if $call->fault && $call->fault->{faultCode};
        my $all_known_tags = $call->result;
        for my $tag (map { @$_ } @posts_tags) {
            if (my ($tag_detail) = grep { $_->{name} eq $tag } @$all_known_tags) {
                $tag_ids->{$tag} = $tag_detail->{term_id};
                log_trace("Tag %s already exists with ID %d, will not be recreating",
                          $tag, $tag_detail->{term_id});
                next;
            }
            if ($dry_run) {
                log_info("(DRY_RUN) [api] Creating tag %s ...", $tag);
                next;
            }
            log_info("[api] Creating tag %s ...", $tag);
            $call = XMLRPC::Lite->proxy($args{proxy})->call(
                'wp.newTerm',
                1, # blog id, set to 1
                $args{username},
                $args{password},
                {taxonomy=>"post_tag", name=>$tag},
             );
            return [$call->fault->{faultCode}, "Can't create tag '$tag': ".$call->fault->{faultString}]
                if $call->fault && $call->fault->{faultCode};
            push @$all_known_tags, { name=>$tag, term_id=>$call->result };
            $tag_ids->{$tag} = $call->result;
        }
    } # L4_CREATE_TAGS

    # 5. create or edit the posts

    my $envres = envresmulti();
  L5_CREATE_OR_EDIT_POSTS:
    for my $post_idx (0..$#posts_srcs) {
        my $post_html  = $posts_htmls [$post_idx];
        my $post_title = $posts_titles[$post_idx];
        my $post_id    = $orig_posts_ids[$post_idx];
        my $post_tags  = $posts_tags  [$post_idx];
        my $post_cats  = $posts_cats  [$post_idx];

        my $meth;
        my @xmlrpc_args = (
            1, # blog id, set to 1
            $args{username},
            $args{password},
        );
        my $content;

        my $publish = $args{publish};
        my $schedule = defined($args{schedule}) ?
            strftime("%Y%m%dT%H:%M:%S", localtime($args{schedule})) : undef;
        $publish = 1 if $schedule;

        if ($post_id) {
            $meth = 'wp.editPost';
            $content = {
                (post_status => $publish ? 'publish' : 'draft') x !!(defined $publish),
                (post_date => $schedule) x !!(defined $schedule),
                post_title => $post_title,
                post_content => $post_html,
                (post_password => $args{post_password}) x !!(defined $args{post_password}),
                terms => {
                    category => [map {$cat_ids->{$_}} @$post_cats],
                    post_tag => [map {$tag_ids->{$_}} @$post_tags],
                },
                comment_status => $args{comment_status},
                %{ $args{extra_attrs} // {} },
            };
            push @xmlrpc_args, $post_id, $content;
        } else {
            $meth = 'wp.newPost';
            $content = {
                post_status => $publish ? 'publish' : 'draft',
                (post_date => $schedule) x !!(defined $schedule),
                post_title => $post_title,
                post_content => $post_html,
                (post_password => $args{post_password}) x !!(defined $args{post_password}),
                terms => {
                    category => [map {$cat_ids->{$_}} @$post_cats],
                    post_tag => [map {$tag_ids->{$_}} @$post_tags],
                },
                comment_status => $args{comment_status},
                %{ $args{extra_attrs} // {} },
            };
            push @xmlrpc_args, $content;
        }
        if ($dry_run) {
            log_info("(DRY_RUN) [api] Create/edit post, content: %s", $content);
            $posts_times[$post_idx] = _fmt_timestamp_org(time());
            $new_posts_ids[$post_idx] = 9_999_000 + $post_idx;
            next L5_CREATE_OR_EDIT_POSTS;
        }

        log_info("[api] Creating/editing post[$post_idx] ...");
        log_trace("[api] xmlrpc method=%s, args=%s", $meth, \@xmlrpc_args);
        $call = XMLRPC::Lite->proxy($args{proxy})->call($meth, @xmlrpc_args);
        return [$call->fault->{faultCode}, "Can't create/edit post: ".$call->fault->{faultString}]
            if $call->fault && $call->fault->{faultCode};

        $posts_times[$post_idx] = _fmt_timestamp_org(time());
        $new_posts_ids[$post_idx] //= $call->result;
    } # L5_CREATE_OR_EDIT_POSTS

    # 6. insert #+POSTID/:POSTID: and #+POSTTIME/:POSTTIME: to Org
    # document/heading

  L6_INSERT_POST_IDS: {
        my $do_update_file;
        if ($mode eq 'heading') {
            for my $post_idx (0..$#posts_srcs) {
                my $post_headline = $posts_headlines[$post_idx];
                my ($properties_drawer) = $post_headline->find(
                    sub {
                        my $el = shift;
                        $el->isa("Org::Element::Drawer") && $el->name eq 'PROPERTIES';
                    });
                if ($properties_drawer) {
                    # XXX need to enhance Org::Parser API, no API to add/modify/delete properties
                    my $raw_content = $properties_drawer->children_as_string;
                    log_info("Inserting/updating :POSTTIME: to post[%d] ...", $post_idx);
                    $raw_content =~ s/^:POSTTIME:.*/:POSTTIME: $posts_times[$post_idx]/m
                        or $raw_content =~ s/^/:POSTTIME: $posts_times[$post_idx]\n/;
                    log_info("Inserting/updating :POSTID: to post[%d] ...", $post_idx);
                    $raw_content =~ s/^:POSTID:.*/:POSTID: $orig_posts_ids[$post_idx]/m
                        or $raw_content =~ s/^/:POSTID: $new_posts_ids[$post_idx]\n/;
                    $properties_drawer->children([]);
                    $properties_drawer->document->_add_text($raw_content, $properties_drawer, 2);
                    $properties_drawer->_parse_properties($raw_content);
                } else {
                    require Org::Element::Drawer;
                    require Org::Element::Text;
                    # XXX need to fix Org::Parser API, this is ugly
                    my $raw_content = "";
                    log_info("Inserting :POSTTIME: & :POSTID: to post[%d] ...", $post_idx);
                    $raw_content .= ":POSTID: ".($orig_posts_ids[$post_idx] // $new_posts_ids[$post_idx])."\n";
                    $raw_content .= ":POSTTIME: $posts_times[$post_idx]\n";
                    $properties_drawer = Org::Element::Drawer->new(
                        document => $post_headline->document,
                        parent => $post_headline,
                        name => 'PROPERTIES',
                        pass => 2,
                    );
                    $post_headline->document->_add_text($raw_content, $properties_drawer, 2);
                    $properties_drawer->_parse_properties($raw_content);
                    my $nl = Org::Element::Text->new(
                        document => $post_headline->document,
                        parent => $post_headline,
                        text => "\n",
                    );
                    unshift @{ $post_headline->children }, $properties_drawer, $nl;
                }
            } # for post
            if (@posts_headlines) {
                $file_content = $posts_headlines[0]->document->as_string;
                $do_update_file++;
            }
        } else {
            $do_update_file++;

            log_info("Inserting/updating #+POSTTIME ...", $filename);
            $file_content =~ s/^#\+POSTTIME:.*/#+POSTTIME: $posts_times[0]/m or
                $file_content =~ s/^/#+POSTTIME: $posts_times[0]\n/;

            my $orig_post_id = $orig_posts_ids[0];
            unless ($orig_post_id) {
                my $new_post_id = $call->result;
                log_info("Inserting #+POSTID (%d) ...", $new_post_id);
                $file_content =~ s/^/#+POSTID: $new_post_id\n/;
            }
        }

        if (!$do_update_file) {
            log_info("Not updating %s because there are no changes", $filename);
        } else {
            log_trace("Updated file content: <<<%s>>>", $file_content);
            if ($dry_run) {
                log_info("[DRY-RUN] Writing %s", $filename);
            } else {
                log_info("Updating file %s ...", $filename);
                File::Slurper::write_text($filename, $file_content);
            }
        }
    } # L6_INSERT_POST_IDS

    [$dry_run ? 304:200, "OK"];
}

1;
# ABSTRACT: Publish Org document (or heading) to WordPress as blog post

__END__

=pod

=encoding UTF-8

=head1 NAME

App::org2wp - Publish Org document (or heading) to WordPress as blog post

=head1 VERSION

This document describes version 0.012 of App::org2wp (from Perl distribution App-org2wp), released on 2022-05-01.

=head1 FUNCTIONS


=head2 org2wp

Usage:

 org2wp(%args) -> [$status_code, $reason, $payload, \%result_meta]

Publish Org document (or heading) to WordPress as blog post.

This is originally a quick hack because I couldn't make
LL<https://github.com/punchagan/org2blog> on my Emacs installation to
work after some update. C<org2wp> uses the same format as C<org2blog>, but instead
of being an Emacs package, it is a CLI script written in Perl.

First, create C<~/org2wp.conf> containing the API credentials, e.g.:

 proxy=https://YOURBLOGNAME.wordpress.com/xmlrpc.php
 username=YOURUSERNAME
 password=YOURPASSWORD

Note that C<proxy> is the endpoint URL of your WordPress instance's XML-RPC
server, which can be hosted on C<wordpress.com> or on other server, including
your own. It has nothing to do with HTTP/HTTPS proxy; the term "proxy" is used
by the L<XMLRPC::Lite> and L<SOAP::Lite> Perl libraries and C<org2wp> simply
uses the same terminology.

You can also put multiple credentials in the configuration file using profile
sections, e.g.:

 [profile=blog1]
 proxy=https://YOURBLOG1NAME.wordpress.com/xmlrpc.php
 username=YOURUSERNAME
 password=YOURPASSWORD
 
 [profile=blog2]
 proxy=https://YOURBLOG2NAME.wordpress.com/xmlrpc.php
 username=YOURUSERNAME
 password=YOURPASSWORD

and specify which profile you want using command-line option e.g.
C<--config-profile blog1>.

=head3 Document mode

You can use the whole Org document file as a blog post (document mode) or a
single heading as a blog post (heading mode). The default is document mode. To
create a blog post, write your Org document (e.g. in C<post1.org>) using this
format:

 #+TITLE: Blog post title
 #+CATEGORY: cat1, cat2
 #+TAGS: tag1,tag2,tag3
 
 Text of your post ...
 ...

then:

 % org2wp post1.org

this will create a draft post. To publish directly:

 % org2wp --publish post1.org

Note that this will also modify your Org file and insert this setting line at
the top:

 #+POSTID: 1234
 #+POSTTIME: [2020-09-16 Wed 11:51]

where 1234 is the post ID retrieved from the server when creating the post, and
post time will be set to the current local time.

After the post is created, you can update using the same command:

 % org2wp post1.org

You can use C<--publish> to publish the post, or C<--no-publish> to revert it to
draft.

To set more attributes:

 % org2wp post1.org --comment-status open \
     --extra-attr ping_status=closed --extra-attr sticky=1

Another example, to schedule a post in the future:

 % org2wp post1.org --schedule 20301225T00:00:00

=head3 Heading mode

In heading mode, each heading will become a separate blog post. To enable this
mode, specify C<--post-heading-level> (C<-l>) to 1 (or 2, or 3, ...). This will
cause a level-1 (or 2, or 3, ...) heading to be assumed as an individual blog
post. For example, suppose you have C<blog.org> with this content:

 * Post A                  :tag1:tag2:tag3:
 :PROPERTIES:
 :CATEGORY: cat1, cat2, cat3
 :END:
 
 Some text...
 
 ** a heading of post A
 more text ...
 ** another heading of post A
 even more text ...
 
 * Post B                  :tag2:tag4:
 Some text ...

with this command:

 % org2wp blog.org -l 1

there will be two blog posts to be posted because there are two level-1
headings: C<Post A> and C<Post B>. Post A contains level-2 headings which will
become headings of the blog post. Headline tags will become blog post tags, and
to specify categories you use the property C<CATEGORY> in the C<PROPERTIES>
drawer.

If, for example, you specify C<-l 2> instead of C<-l 1> then the level-2 headings
will become blog posts.

In heading mode, you can use several options to select only certain headlines
which contain (or don't contain) specified tags.

=head3 FAQ

=head4 What if I want to set HTTP/HTTPS proxy?

You can set the environment variable C<HTTP_proxy> (and C<HTTP_proxy_user> and
C<HTTP_proxy_pass> additionally). See the L<SOAP::Lite> documentation for more
details, which uses L<LWP::UserAgent> underneath.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<comment_status> => I<str> (default: "closed")

Whether to allow comments (open) or not (closed).

=item * B<exclude_heading_tags> => I<array[str]>

Exclude heading that has any of the specified tag(s).

=item * B<extra_attrs> => I<hash>

Set extra post attributes, e.g. ping_status, post_format, etc.

=item * B<filename>* => I<filename>

Path to Org document to publish.

=item * B<include_heading_tags> => I<array[str]>

Only include heading that has all specified tag(s).

=item * B<password>* => I<str>

=item * B<post_heading_level> => I<posint>

Specify which heading level to be regarded as an individula blog post.

If specified, this will enable I<heading mode> instead of the default I<document
mode>. In the document mode, the whole Org document file is regarded as a single
blog post. In the I<heading mode>, a heading of certain level will be regarded as
a single blog post.

=item * B<post_password> => I<str>

Set password for posts.

=item * B<proxy>* => I<str>

Example: CL<https://YOURBLOGNAME.wordpress.com/xmlrpc.php>.

Note that C<proxy> is the endpoint URL of your WordPress instance's XML-RPC
server, which can be hosted on C<wordpress.com> or on other server, including
your own. It has nothing to do with HTTP/HTTPS proxy; the term "proxy" is used
by the L<XMLRPC::Lite> and L<SOAP::Lite> Perl libraries and C<org2wp> simply
uses the same terminology.

=item * B<publish> => I<bool>

Whether to publish post or make it a draft.

Equivalent to C<--extra-attr post_status=published>, while C<--no-publish> is
equivalent to C<--extra-attr post_status=draft>.

=item * B<schedule> => I<date>

Schedule post to be published sometime in the future.

Equivalent to C<--publish --extra-attr post_date=DATE>. Note that WordPress
accepts date in the C<YYYYMMDD"T"HH:MM:SS> format, but you specify this option in
regular ISO8601 format. Also note that time is in your chosen local timezone
setting.

=item * B<username>* => I<str>


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-org2wp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-org2wp>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020, 2019, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-org2wp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
