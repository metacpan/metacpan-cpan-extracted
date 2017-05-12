package Beagle::Web;
use Beagle;
use Beagle::Util;
use Beagle::Handle;
use Beagle::Web::Request;
use Beagle::I18N;
use I18N::LangTags;
use I18N::LangTags::Detect;
use Data::Page;
use URI::QueryParam;

my %feed;

sub feed {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';

    my $bh   = handle();
    my $name = $bh->name;
    return $feed{$name} if $feed{$name};

    my $backend = $bh->backend;
    my $info    = $bh->info;
    my $entries = $bh->entries;

    require XML::FeedPP;
    my $feed = XML::FeedPP::RSS->new( link => $info->url );
    $feed->copyright( $info->copyright );
    $feed->title( $info->title );
    $feed->description( $info->body );
    $feed->pubDate( $entries->[0]->created ) if @$entries;
    $feed->image( $info->avatar, $info->title, $info->url, $info->body, 80,
        80 );
    $feed->set( 'category' => from_array( $info->tags ) );

    my $limit = $ENV{BEAGLE_FEED_LIMIT} || $info->feed_limit() || 20;
    if ( scalar @$entries > $limit ) {
        $entries = [ @{$entries}[ 0 .. $limit - 1 ] ];
    }

    for my $entry (@$entries) {
        my $item = $feed->add_item();
        $item->link( $info->url . "/entry/" . $entry->id );
        $item->guid( $item->link );
        if ( $entry->can('title') ) {
            $item->title( $entry->title );
        }
        elsif ( $entry->can('summary') ) {
            $item->title( $entry->summary(30) );
        }
        else {
            $item->title( $entry->type );
        }

        $item->description(
              $entry->can('body_html')
            ? $entry->body_html
            : $entry->body
        );

        $item->pubDate( $entry->created );
        $item->author( $entry->author
              || $info->name . ' (' . $info->email . ')' );
        my $category = $entry->type,;
        if ( $entry->can('tags') ) {
            $category = join ', ', $category, $entry->type,
              from_array( $entry->tags );
        }
        $item->category($category);
    }

    $feed->normalize();
    return $feed{$name} = $feed;
}

sub update_feed {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $bh = shift;
    delete $feed{ $bh->name };
    feed($bh);
}

my %archives;
my %tags;

use Storable 'dclone';

sub archives {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $bh   = shift;
    my $name = $bh->name;
    return dclone( $archives{$name} ) if $archives{$name};

    my $archives = {};
    for my $entry ( @{ $bh->entries } ) {
        push @{ $archives->{ $entry->created_year }{ $entry->created_month } },
          $entry;
    }

    $archives{$name} = $archives;
    return dclone($archives);
}

sub update_archives {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $bh = shift;
    delete $archives{ $bh->name };
    archives($bh);
}

sub tags {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $bh   = shift;
    my $name = $bh->name;

    return dclone( $tags{$name} ) if $tags{$name};

    my $tags = {};
    for my $entry ( @{ $bh->entries } ) {
        if ( $entry->can('tags') ) {
            for my $tag ( @{ $entry->tags } ) {
                push @{ $tags->{$tag} }, $entry;
            }
        }
        push @{ $tags->{ $entry->type } }, $entry;
    }
    $tags{$name} = $tags;
    return dclone($tags);
}

sub update_tags {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $bh = shift;
    delete $tags{ $bh->name };
    tags($bh);
}

sub field_list {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $entry = shift;
    my @list  = (
        body  => { type => 'textarea', },
    );

    my $type = $entry->type;
    if ( $type ne 'info' ) {
        push @list, author => { type => 'text', };
    }

    if ( $type ne 'comment' ) {
        push @list, tags => { type => 'text', };
    }

    if ( $type ne 'entry' ) {
        my $names = $entry->extra_meta_fields;
        for my $name (@$names) {
            my $attr  = $entry->meta->get_attribute($name);
            my $const = $attr->type_constraint;
            if ($const) {
                if ( $const->can('values') ) {
                    push @list, $name => {
                        type    => 'select',
                        options => [
                            map { { label => $_, value => $_ } } $const->values,
                        ],
                    };
                    next;
                }
                elsif ( "$const" eq 'Bool' ) {
                    push @list, $name => { type => 'boolean', };
                    next;
                }
                elsif ( "$const" eq 'BeagleLayout' ) {
                    push @list, $name => {
                        type    => 'select',
                        options => [
                            map { { label => $_, value => $_ } } qw/blog plain/,
                        ],
                    };
                    next;
                }
                elsif ( "$const" eq 'BeagleTheme' ) {
                    push @list, $name => {
                        type    => 'select',
                        options => [
                            map { { label => $_, value => $_ } }
                              qw/orange blue dark/,
                        ],
                    };
                    next;
                }
            }
            push @list, $name => { type => 'text', };
        }
    }

    push @list, format => {
        type    => 'select',
        options => [
            map { { label => $_, value => $_ } }
              qw/plain wiki markdown pod html/
        ],
    };
    push @list, draft => { type => 'boolean', } unless $type eq 'info';

    @list = _fill_values( $entry, @list );
    return wantarray ? @list : \@list;
}

sub _fill_values {
    my $entry  = shift;
    my @fields = @_;
    my @filled;
    while (@fields) {
        my $name = shift @fields;
        my $opt  = shift @fields;
        $opt->{default} = $entry->serialize_field($name);

        if ( $name eq 'author' && !$opt->{default} ) {
            $opt->{default} = current_user();
        }
        push @filled, $name, $opt;
    }
    return @filled;
}

use Plack::Builder;

sub app {
    require Beagle::Web::Router;

    builder {
        for my $root ( system_roots() ) {
            enable 'Static',
              path         => sub { s!^/system/!! },
              root         => $root,
              pass_through => 1;
        }

        \&handle_request;
    }
}

my ( $bh, %updated, %bh, $name, $names, $prefix, $static, $router, %xslate );
$prefix = '/';
my ( %css, %js );
my $req;

sub template_exists {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $name = shift;
    return unless defined $name;
    $name .= '.tx' unless $name =~ /\.tx$/;
    my @roots = (
        map( { catdir( $_, $bh->info->layout ), } web_template_roots() ),
        map( { catdir( $_, 'base' ), } web_template_roots() )
    );
    my @parts = split /\//, $name;
    for my $root (@roots) {
        return 1 if -e encode( locale_fs => catfile( $root, @parts ) );
    }
    return;
}

sub system_file_exists {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $name = shift;
    return unless defined $name;
    my @roots = system_roots();
    my @parts = split /\//, $name;
    for my $root (@roots) {
        return 1 if -e encode( locale_fs => catfile( $root, @parts ) );
    }
    return;
}

use Text::Xslate;

sub xslate {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $n = shift   || $name;
    my $b = $bh{$n} || $bh;
    return $xslate{$n} if $xslate{$n};
    return $xslate{$n} = Text::Xslate->new(
        path => [
            map( { catdir( $_, $b->info->layout ) } web_template_roots() ),
            map( { catdir( $_, 'base' ) } web_template_roots() ),
        ],
        cache_dir   => catdir( File::Spec->tmpdir, 'beagle_web_cache' ),
        cache       => 1,
        input_layer => ':utf8',
        function    => {
            substr => sub {
                my ( $content, $number ) = @_;
                $number ||= 40;
                utf8::decode($content);
                if ( length $content > $number ) {
                    $content = substr( $content, 0, $number - 4 ) . '...';
                }
                utf8::encode($content);
                return $content;
            },
            length => sub {
                return length shift;
            },
            size => sub {
                my $value = shift;
                return 0 unless $value;
                return 1 unless ref $value;
                if ( ref $value eq 'ARRAY' ) {
                    return scalar @$value;
                }
                elsif ( ref $value eq 'HASH' ) {
                    my $size = 0;
                    for ( keys %$value ) {
                        if ( ref $value->{$_} && ref $value->{$_} eq 'ARRAY' ) {
                            $size += @{ $value->{$_} };
                        }
                        else {
                            $size += 1;
                        }
                    }
                    return $size;
                }
                return;
            },
            split_id => sub {
                join '/', split_id(shift);
            },
            email_name => sub {
                require Email::Address;
                my $value = shift;
                my (@addr) = Email::Address->parse($value);
                if (@addr) {
                    join ', ', map { $_->name } @addr;
                }
                else {
                    return $value;
                }
            },
            match => sub {
                my $value = shift;
                my $regex = shift;
                return unless defined $value && defined $regex;
                return $value =~ qr/$regex/;
            },
            grep => sub {
                my $values = shift;
                my $regex  = shift;
                return unless defined $values && defined $regex;

                my $flag;
                if (@_) {
                    $flag = $_[0];
                }
                else {
                    $flag = 1;
                }

                return [ grep { /$regex/ ? $flag : 0 } @$values ];
            },
            _ => sub {
                my $handle = i18n_handle();
                $handle->maketext(@_);
            },
            template_exists    => sub { template_exists(@_) },
            system_file_exists => sub { system_file_exists(@_) },
            canonicalize_name  => sub {
                my $name = shift;
                return unless defined $name;
                $name =~ s!_! !;
                return $name;
            },
            lc => sub {
                return lc shift;
            },
            uc => sub {
                return uc shift;
            },
            ucfirst => sub {
                return ucfirst shift;
            },
        },
    );
}

sub init {
    require Beagle::Web::Router;
    $router = Beagle::Web::Router->router;
    for my $plugin ( plugins() ) {
        my $m = $plugin . '::Web::Router';
        if ( load_optional_class($m) ) {
            my $r = $m->router;
            if ($r) {
                unshift @{ $router->{routes} }, @{ $r->{routes} }
                  if $r->{routes};
            }
        }
    }

    my $all = roots();
    if ( web_all() ) {
        $names = [ sort keys %$all ];
    }
    elsif ( web_names() ) {
        $names = [ web_names() ];
    }

    my $root = current_root('not die');
    if ( !$root ) {
        $names = [ sort keys %$all ];
    }

    $names = [ grep { $all->{$_} } @$names ] if $names;

    if ($names) {
        if ( @$names == 1 ) {
            $bh = Beagle::Handle->new(
                drafts => web_admin(),
                name   => $names->[0],
            );
            $bh{ $names->[0] } = $bh;
            undef $names;
        }
        else {
            for my $n (@$names) {
                $bh{$n} = Beagle::Handle->new(
                    drafts => web_admin(),
                    root   => $all->{$n}{local},
                );
                if ( $root && $root eq $all->{$n}{local} ) {
                    $bh   = $bh{$n};
                }
                $router->connect(
                    "/$n",
                    {
                        code => sub {
                            change_handle( name => $n );
                            redirect('/');
                        },
                    }
                );
            }
            $bh ||= ( values %bh )[0];
        }

        $name = $bh->name;
    }
    else {
        $bh = Beagle::Handle->new(
            drafts => web_admin(),
            root   => $root,
        );
        $name = $bh->name;
        $bh{$name} = $bh;
    }

    for my $plugin ( plugins() ) {
        my $name;
        if ( $plugin->can('name') ) {
            $name = $plugin->name;
        }

        unless ($name) {
            $name = $plugin;
            $name =~ s!^Beagle::Plugin::!!;
            $name =~ s!::!-!g;
        }

        $name = lc $name;

        for my $layout ( 'base',
            uniq( grep { defined } map { $_->info->layout } values %bh ) )
        {

            if (
                -e catfile(
                    share_root($plugin), 'public',
                    $name,               'css',
                    $layout,             'main.css'
                )
              )
            {
                push @{ $css{$layout} }, join '/', $name, 'css', $layout,
                  'main.css';
            }

            if (
                -e catfile(
                    share_root($plugin), 'public',
                    $name,               'js',
                    $layout,             'main.js'
                )
              )
            {
                push @{ $js{$layout} }, join '/', $name, 'js', $layout,
                  'main.js';
            }
        }
    }
}

sub i18n_handle {
    my @lang = I18N::LangTags::implicate_supers(
        I18N::LangTags::Detect->http_accept_langs(
            $req->header('Accept-Language')
        )
    );
    unshift @lang, $bh->info->language if $bh->info->language;
    return Beagle::I18N->get_handle(@lang);
}

sub change_handle {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my %vars = @_;
    if ( $vars{handle} ) {
        $bh        = $vars{handle};
        $name      = $bh->name;
        $bh{$name} = $bh;
    }
    elsif ( $vars{name} ) {
        my $n = $vars{name};
        $bh   = $bh{$n};
        $name = $n;
    }
    else {
        return;
    }

    return $Beagle::Util::ROOT = $bh->root;
}

sub process_fields {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my ( $entry, $params ) = @_;

    my %fields = Beagle::Web->field_list($entry);
    for my $field ( keys %$params ) {
        next unless $entry->can($field) && $fields{$field};
        my $new = $params->{$field};
        if ( $field eq 'body' ) {
            $new = $entry->parse_body($new);
        }

        my $old = $entry->serialize_field($field);

        if ( "$new" ne "$old" ) {
            $entry->$field( $entry->parse_field( $field, $new ) );
        }
    }
    return 1;
}

sub delete_attachments {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my ( $entry, @names ) = @_;
    for my $name (@names) {
        next unless defined $name;
        my $att = Beagle::Model::Attachment->new(
            name      => $name,
            parent_id => $entry->id,
        );
        $bh->delete_attachment($att);
    }
}

sub add_attachments {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my ( $entry, @attachments ) = @_;
    for my $upload (@attachments) {
        next unless $upload;

        my $basename = decode_utf8 $upload->filename;
        $basename =~ s!\\!/!g;
        $basename =~ s!.*/!!;

        my $att = Beagle::Model::Attachment->new(
            name         => $basename,
            content_file => $upload->tempname,
            parent_id    => $entry->id,
        );
        $bh->create_attachment( $att,
                message => 'added attachment '
              . $basename
              . ' for entry '
              . $entry->id );
    }
}

sub handle  { $bh }
sub request { $req }

sub set_prefix {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    $prefix = shift;
}

sub set_static {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    $static = shift;
}

sub default_options {
    my $bh = handle();

    return (
        $bh->list,
        handle      => $bh,
        name        => $name,
        admin       => web_admin(),
        feed        => Beagle::Web->feed($bh),
        archives    => Beagle::Web->archives($bh),
        tags        => Beagle::Web->tags($bh),
        entry_types => entry_types(),
        prefix      => $prefix,
        static      => $static,
        css =>
          [ @{ $css{base} || [] }, @{ $css{ $bh->info->layout } || [] } ],
        js => [ @{ $js{base} || [] }, @{ $js{ $bh->info->layout } || [] } ],
        ( $req->env->{'BEAGLE_NAME'} || $req->header('X-Beagle-Name') )
        ? ()
        : ( names => $names ),
        current_user => current_user(),
    );
}

sub _fill_page_info {
    my $vars  = shift;
    my $field = shift;
    my $limit =
         $vars->{page_limit}
      || $ENV{BEAGLE_PAGE_LIMIT}
      || $bh->info->page_limit
      || 10;
    if ( $vars->{$field} ) {
        $vars->{page} = request()->param('p') || 1;
        my $page =
          Data::Page->new( scalar @{ $vars->{$field} }, $limit, $vars->{page} );
        $vars->{$field} = [ $page->splice( $vars->{$field} ) ];

        # page from user may exceed the range
        $vars->{page} = $page->current_page;

        my $first = $page->first_page;
        my $last  = $page->last_page;

        if ( $first != $last ) {
            my @pages;

            my @before = $first .. $vars->{page} - 1;
            if ( @before > 9 ) {
                push @pages, @before[ $#before - 9 .. $#before ];
                $vars->{first_page} = $first;
            }
            else {
                push @pages, @before;
            }

            push @pages, $vars->{page};

            my @after = $vars->{page} + 1 .. $last;
            if ( @after > 10 ) {
                push @pages, @after[ 0 .. 9 ];
                $vars->{last_page} = $last;
            }
            else {
                push @pages, @after;
            }

            $vars->{pages} = [
                map {
                    my $page = $_;
                    my $uri  = request()->uri;
                    $uri->query_param( p => $page );
                    [ $page, $uri->path_query ];
                  } @pages
            ];

            for my $edge (qw/first_page last_page/) {
                next unless $vars->{$edge};
                my $uri = request()->uri;
                $uri->query_param( p => $vars->{$edge} );
                $vars->{$edge} = [ $vars->{$edge}, $uri->path_query ];
            }
        }
    }
}

sub render {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $template = shift;
    my %vars     = @_;
    _fill_page_info( \%vars, 'entries' ) unless $vars{disable_page};
    return xslate()->render( "$template.tx", { default_options(), %vars } );
}

sub redirect {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $location = shift;
    my $code     = shift;
    $location =~ s!^/?!$prefix! if $location;
    $req->new_response( $code || 302, [ Location => $location || $prefix ] );
}

my $res;
sub response { $res }

sub handle_request {
    shift @_ if @_ && $_[0] eq 'Beagle::Web';
    my $env = shift;
    init() unless $bh;

    $req = Beagle::Web::Request->new($env);

    my $n = $req->env->{'BEAGLE_NAME'} || $req->header('X-Beagle-Name');
    $n = decode_utf8($n) unless Encode::is_utf8($n);

    if ( $names && $n && grep { $n eq $_ } @$names ) {
        $bh   = $bh{$n};
        $name = $n;
    }

    if (   web_admin()
        || !$updated{$name}
        || time - $updated{$name} >= 60 )
    {
        $bh->update;
        update_archives($bh);
        update_tags($bh);
        update_feed($bh);
        $updated{$name} = time;
    }

    require Plack::Response;
    $res = Plack::Response->new;

    if ( my $match = $router->match($env) ) {
        if ( my $method = delete $match->{code} ) {
            my $ret = $method->(%$match);
            if ( ref $ret && $ret->isa('Plack::Response') ) {
                $res = $ret;
                $res->status( 200 ) unless $res->status;
            }
            else {
                if ( $ret ) {
                    $res->body(
                        Encode::is_utf8($ret)
                        ? encode_utf8 $ret
                        : $ret
                    );
                    $res->status( 200 ) unless $res->status;
                }
            }
        }
    }

    $res->status( 404 ) unless $res->status;
    $res->content_type( 'text/html' ) unless $res->content_type;

    $res->finalize;
}

sub prefix { $prefix }

1;

__END__

=head1 NAME

Beagle::Web - web interface of Beagle

=head1 DESCRIPTION

Beagle::Web - web interface of Beagle

=head1 AUTHOR

sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
