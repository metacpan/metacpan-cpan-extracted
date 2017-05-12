package CatalystX::CMS;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use MRO::Compat;
use mro 'c3';
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(qw( model_name view_name strict_html ));

our $VERSION = '0.011';

my $DEBUG = 0;

use XML::Simple;
use XML::LibXML;
$XML::Simple::PREFERRED_PARSER = 'XML::LibXML::SAX';

=head1 NAME

CatalystX::CMS - drop-in content management system

=head1 SYNOPSIS

 package MyApp;
 
 # ...
 
 MyApp->config(
    cms => {
        model_name             => 'CMS',
        view_name              => 'CMS',
        actionclass_per_action => 0,
        use_editor             => 1,
        use_layout             => 1,
        editor                 => {
            height => '300',
            width  => '550',
        },
        default_type    => 'html',
        default_flavour => 'default',
        lock_period     => 3600,
        root => {
            r  => [
                MyApp->path_to('root')
            ],
            rw => [
                '/path/to/svn/workdir'
            ]
        }
                
    }
 );
 
 MyApp->setup;

 # elsewhere, in a controller
 
 package MyApp::Controller::Foo;
 use strict;
 use base qw( CatalystX::CMS::Controller );
 
 sub bar : Local {
    # ...
 }
 
 1;

=head1 DESCRIPTION

CatalystX::CMS is a drop-in content management system that allows
you to manage your Catalyst app templates via a web-based editor.
 
=head1 METHODS

Only new or overridden method are documented here.

=cut

=head2 PUT( I<c>, I<controller>, I<cmspage> )

Calls do_action().

=cut

sub PUT {
    my ( $self, $c, $controller, $cmspage ) = @_;
    $self->do_action( $c, $controller, $cmspage );
}

=head2 POST( I<c>, I<controller>, I<cmspage> )

Calls create().

=cut

sub POST {
    my ( $self, $c, $controller, $cmspage ) = @_;
    $self->create( $c, $controller, $cmspage );
}

=head2 GET( I<c>, I<controller>, I<cmspage> )

Calls the method named in the stash() in I<c> under the key B<cms_mode>.
B<cms_mode> is typically set by CatalystX::CMS::Action->execute().

=cut

sub GET {
    my ( $self, $c, $controller, $cmspage ) = @_;
    my $method = $c->stash->{cms_mode}
        or croak("no cxcms action specified");
    $self->$method( $c, $controller, $cmspage );
}

=head2 DELETE( I<c>, I<controller>, I<cmspage> )

Calls delete().

=cut

sub DELETE {
    my ( $self, $c, $controller, $cmspage ) = @_;
    $self->delete( $c, $controller, $cmspage );
}

=head2 unlock

 TODO
 
=cut

sub unlock {

}

=head2 get_user( I<c> )

Returns a username to associate with the lock on a file.

If I<c> has a C<user> method (as if using Catalyst::Plugin::Authentication),
calls the user->id method chain.

Otherwise, returns anonymous.

=cut

sub get_user {
    my ( $self, $c ) = @_;
    my $user
        = ( $c->can('user') && defined $c->user )
        ? $c->user->id
        : 'anonymous';
    $c->log->debug("CMS user = $user") if $c->debug;
    return $user;
}

=head2 history( I<c>, I<controller>, I<cmspage> )

Available as a B<cms_mode> method.

Display svn history of I<cmspage>.

=cut

sub history {
    my ( $self, $c, $controller, $cmspage ) = @_;

    if ( my $log = $cmspage->log( ['--xml'] ) ) {

        my %res;
        $res{history}
            = XMLin( join( '', @$log ), ForceArray => [qw( logentry )] )
            ->{logentry};
        $res{template} = 'cms/svn/history.tt';

        return \%res;

    }
    else {
        croak( "could not get svn log for " . $cmspage->url );
    }
}

=head2 diff( I<c>, I<controller>, I<cmspage> )

Available as a B<cms_mode> method.

Display svn diff of I<cmspage>. 
If the C<rev> request param is present, the difference between
that value and the previous revision is used.

=cut

sub diff {
    my ( $self, $c, $controller, $cmspage ) = @_;

    my $rev = $c->req->params->{rev};

    if ($rev) {
        if ( $rev =~ m/\D/ ) {
            croak("bad changeset value $rev");
            return;
        }

        my $start = $rev - 1;

        $cmspage->diff( ["-r$start:$rev"] )
            or croak("could not diff for $start:$rev");
    }
    else {
        $cmspage->diff or croak("could not diff $cmspage");
    }

    my %res;
    $res{diff}     = $cmspage->stdout;
    $res{template} = 'cms/svn/diff.tt';
    return \%res;
}

=head2 blame( I<c>, I<controller>, I<cmspage> )

Available as a B<cms_mode> method.

Display svn blame of I<cmspage>.

=cut

sub blame {
    my ( $self, $c, $controller, $cmspage ) = @_;
    $cmspage->blame or croak("Can't blame for $cmspage");
    my $buf = $cmspage->stdout;
    my @blame;
    my $oldest_rev = 0;
    for my $line (@$buf) {
        my ( $rev, $who, $txt ) = ( $line =~ m/^\s+(\d+)\s+(\S+)\s+(.+)$/ );

        # TODO $who is always going to be the webserver user
        # so we need to get the log for that rev to correctly report

        next unless $rev;
        $oldest_rev ||= $rev;
        $oldest_rev = $rev if ( $oldest_rev && $oldest_rev > $rev );
        push( @blame, { rev => $rev, who => $who, txt => $txt } );
    }
    my %res;
    $res{blame}      = \@blame;
    $res{oldest_rev} = $oldest_rev;
    $res{template}   = 'cms/svn/blame.tt';
    return \%res;
}

=head2 create( I<c>, I<controller>, I<cmspage> )

Available only via HTTP POST.

Calls create() method on I<cmspage> passing get_user() for lock owner.

Sets redirect uri for edit().

=cut

sub create {
    my ( $self, $c, $controller, $cmspage ) = @_;
    my %res;

    # must be a POST request
    unless ( uc( $c->req->method ) eq 'POST' ) {
        $res{body} = 'Bad HTTP request. Must POST to create a new CMS page.';
        $res{status} = 400;
        return \%res;
    }

    eval { $cmspage->create( $self->get_user($c) ) };
    if ($@) {
        $c->log->error($@);
        $c->error($@);
        return;
    }

    # "pure" REST response would be status 201
    # but we're dealing with browsers so return the 30x redirect URI
    $res{uri} = $c->uri_for( $cmspage->url, { 'cxcms' => 'edit' } );
    return \%res;
}

my %wrappers = map { $_ => 1 } qw( wrapper header footer body );

sub _copy_if_required {
    my ( $self, $c, $controller, $cmspage ) = @_;

    my $file = $cmspage->bare_file;

    $DEBUG and warn "copy_if_required $file";

    $c->log->debug("checking if we should make copy of $file")
        if $c->debug;

    if ( ( exists $wrappers{$file} and !-s $cmspage )
        or $cmspage->copy )
    {

        #carp dump $cmspage;

        # make a local copy to edit
        $c->log->debug("making local copy of $file") if $c->debug;
        my $class   = $cmspage->delegate_class;
        my $view    = $c->view( $self->view_name );
        my $tt_root = $view->cms_template_base;
        my $model   = $c->model( $self->model_name );
        my $orig    = $model->new_object(
            file => $cmspage->file,
            ext  => $cmspage->ext
        );
        $orig->{type}    = $cmspage->type;
        $orig->{flavour} = $cmspage->flavour;

        if ( !-s $cmspage ) {
            $orig = $model->find_page_in_inc( $orig,
                $tt_root->subdir( 'cms', 'wrappers' ) );

            if ( !-s $orig ) {
                croak("no such original file at $orig");
            }

        }
        else {

            # cmspage exists, we just want a local copy to edit

            #carp dump $cmspage;
            $orig->{delegate}    = $cmspage->{delegate};
            $cmspage->{delegate} = $cmspage->delegate_class->new(
                path => Path::Class::file(
                    $c->config->{cms}->{root}->{rw}->[0],
                    $orig->{type},
                    $orig->{flavour},
                    $cmspage->file . $cmspage->ext
                )
            );
            $cmspage->{delegate}->dir->mkpath;

        }

        # make the copy
        $c->log->debug("orig: $orig")    if $c->debug;
        $c->log->debug("copy: $cmspage") if $c->debug;
        my $fh  = $cmspage->delegate->openw;
        my $buf = $orig->slurp;
        print $fh $buf;
        $fh->close;
        $cmspage->delegate->_parse_page($buf);

    }

}

=head2 edit( I<c>, I<controller>, I<cmspage> )

Available as a B<cms_mode> method.

Verifies lock on I<cmspage>, extending it if necessary, and
displays the cms editor template.

=cut

sub edit {
    my ( $self, $c, $controller, $cmspage ) = @_;

    # can't edit a file we haven't yet created
    # unless it is one of our own CMS/tt/cms/wrappers/* files
    $self->_copy_if_required( $c, $controller, $cmspage );

    unless ( -s $cmspage ) {
        croak( $cmspage->file . " does not exist" );
    }

    # lock the file immediately so no one else can edit it.
    # only the current user can unlock it, either by saving
    # changes or by explicitly calling the cancel url.

    # could be a redirect from create() so check that owner == $user
    my $user = $self->get_user($c);
    if ( $cmspage->locked ) {

        # how old is the lock?
        my $lock_period = $c->config->{cms}->{lock_period} || 3600;
        if ( ( $cmspage->lock_time + $lock_period ) < time() ) {
            $c->log->debug("lock expired on $cmspage");
            $cmspage->lock($user);
        }
        elsif ( $cmspage->lock_owner ne $user ) {
            croak( "$cmspage is already locked by " . $cmspage->lock_owner );
        }
        else {

            # extend the lock every time we hit this url
            if ( $cmspage->unlock && $cmspage->lock($user) ) {
                $c->log->debug("$cmspage lock re-acquired by $user");
            }
            else {
                croak("failed to re-acquire $cmspage lock for $user");
            }
        }
    }
    else {
        $cmspage->lock($user);
    }

    $DEBUG and warn "svn update $cmspage";

    # make sure we're working on the latest copy,
    # in case the repository is non-local and we're
    # behind a load balancer (for example)
    #$cmspage->up;    # **not** ->update

    my %res;
    $res{template} = 'cms/yui/editor.tt';
    return \%res;
}

sub _filter_text {
    my ( $self, $text_ref ) = @_;

    # return number of s/// changes to $$text_ref
    my $n = 0;

    $n += $$text_ref =~ s/<code class="tt">//g;
    $n += $$text_ref =~ s/<\/code>//g;
    $n += $$text_ref =~ s/<br>/\n/g;

    # pesky Win32 line-endings
    $n += $$text_ref =~ s/\r\n/\n/g;

    return $n;
}

sub _get_attrs {
    my ( $self, $c, $cmspage ) = @_;

    for my $key ( sort keys %{ $cmspage->attrs } ) {
        if ( defined $c->req->params->{$key} ) {
            $cmspage->attrs->{$key} = $c->req->params->{$key};
        }
    }

    # new ad hoc attrs
    for my $new_attrs_name ( grep {m/^new_attr_name_\d+$/} $c->req->param ) {
        my ($id) = ( $new_attrs_name =~ m/_(\d+)$/ );
        my $key = $c->req->params->{$new_attrs_name} or next;
        my $val = $c->req->params->{ 'new_attr_val_' . $id } || '';
        $key =~ s/\W/_/g;
        next if $key eq 'attrs_name';    # generic name
        $cmspage->attrs->{$key} = $val;
    }

    # some minimal attrs required.
    $cmspage->attrs->{owner} ||= $self->get_user($c);
    $cmspage->attrs->{title} ||= 'no title';
}

=head2 do_action( I<c>, I<controller>, I<cmspage> )

Called by PUT(). Calls B<cms_mode> like GET() does,
but checks lock on I<cmspage> first.

do_action() is typically called for save()ing a I<cmspage>.

=cut

sub do_action {
    my ( $self, $c, $controller, $cmspage ) = @_;

    my $text = $c->req->params->{text};
    if ( !defined $text ) {
        croak('text param required');
    }
    my $action = $c->stash->{cms_mode} || 'save';
    my $user = $self->get_user($c);

    # is this file locked by this user?
    if ( !$cmspage->locked ) {
        croak( $cmspage->url . " is not locked for editing." );
    }

    if ( $cmspage->lock_owner ne $user ) {
        croak( $cmspage->url . " is not locked by $user." );
    }

    # YUI editor adds HTML <br> to represent \n
    # so filter those and any others.
    my $filter += $self->_filter_text( \$text );

    $self->_get_attrs( $c, $cmspage );
    $cmspage->content($text);

    $c->log->debug("Action = $action") if $c->debug;
    if ( $self->can($action) ) {
        return $self->$action( $c, $controller, $cmspage );
    }
    else {
        croak("Bad action: $action");
    }

}

=head2 cancel( I<c>, I<controller>, I<cmspage> )

Available as a B<cms_mode> method.

Reverts any local changes to I<cmspage> and unlocks the page.

If I<cmspage> has never been committed to the svn repository,
the file will be removed.

=cut

sub cancel {
    my ( $self, $c, $controller, $cmspage ) = @_;

    my $stat = $cmspage->status;

    # if file has local mods (or flagged for addition)
    # then remove/revert it and update.
    if ( $stat ne '?' ) {
        if ( $stat eq 'A' ) {
            unless ( $cmspage->revert ) {
                croak("Could not revert $cmspage");
                return 0;
            }

            # TODO should page be removed too?

        }
        elsif ( $stat eq 'M' ) {
            unless ( $cmspage->remove ) {
                croak("Could not remove modified $cmspage");
                return 0;
            }

            unless ( $cmspage->up ) {
                croak("Count not svn update $cmspage");
                return 0;
            }
        }
    }
    else {

        # if svn knows nothing about the file, just remove it
        unless ( $cmspage->remove ) {
            croak("Could not remove $cmspage");
            return 0;
        }
    }

    # unlock the page
    $cmspage->unlock;

    # show the original
    my %res;
    $res{uri} = $c->uri_for( $cmspage->url );
    return \%res;
}

=head2 validate( I<c>, I<controller>, I<cmspage> )

Called by save() to verify that I<cmspage> has correct
TT syntax.

If C<strict_html> mode is set and the type() of I<cmspage> is C<html>
XML::LibXML is used to verify that I<cmspage> parses correctly.

=cut

sub validate {
    my ( $self, $c, $controller, $cmspage ) = @_;

    # attempt to render the file to test TT syntax
    my $view = $c->view( $self->view_name );
    my $buf  = $cmspage->content;
    $c->stash( cmspage => $cmspage );

    # turn off debugging statement since we pass scalar ref instead
    # of file name
    $c->log->debug("Validating content of $cmspage") if $c->debug;
    $c->log->disable('debug');
    my $out = $view->render( $c, \$buf );
    $c->log->enable('debug');

    #$c->log->debug("test render returned: $out") if $c->debug;

    if ( UNIVERSAL::isa( $out, 'Template::Exception' ) ) {
        $c->error("Failed to render $cmspage");
        $c->error("Template error: $out");
        return;
    }

    # optional: attempt to parse the file with an HTML parser
    if ( $cmspage->type eq 'html' && $self->strict_html ) {
        my $parser = XML::LibXML->new();
        eval { $parser->parse_html_string( $out, { recover => 1 } ); };
        if ($@) {
            $c->error("strict HTML mode failed: $@");
            return;
        }
    }

    return 1;
}

=head2 save( I<c>, I<controller>, I<cmspage> )

Available as a B<cms_mode> method.

Typically called by do_action() via PUT().

=cut

sub save {
    my ( $self, $c, $controller, $cmspage ) = @_;

    return unless $self->validate( $c, $controller, $cmspage );

    my $user = $self->get_user($c);
    my $stat = $cmspage->save("edit by $user");
    my $url  = $cmspage->url;

    my %res;
    if ( $stat && $stat > 0 ) {
        $c->log->debug("save returned $stat") if $c->debug;
        $res{message} = "Committed $url as change $stat";
    }
    else {
        $c->log->debug("save stat $stat indicates no change to $cmspage")
            if $c->debug;
        $res{message} = "No changes made to $url";
    }

    # TODO what if $url is a wrapper part?
    $res{uri} = $c->uri_for($url);
    return \%res;
}

=head2 preview( I<c>, I<controller>, I<cmspage> )

Available as a B<cms_mode> method.

Like save() but with no commit() and preserves lock

=cut

sub preview {
    my ( $self, $c, $controller, $cmspage ) = @_;

    return unless $self->validate( $c, $controller, $cmspage );

    # force write since we own lock and want to keep it.
    $cmspage->update(1);

    return { template => $cmspage };

}

=head2 delete( I<c>, I<controller>, I<cmspage> )

Available as a B<cms_mode> method.

Called by DELETE(). Removes lock on I<cmspage> and 
deletes the file from the local workspace B<and from the svn
repository>. See also cancel().

=cut

sub delete {
    my ( $self, $c, $controller, $cmspage ) = @_;

    if ( $cmspage->locked ) {
        $cmspage->unlock or croak("can't unlock $cmspage");
    }

    my $user = $self->get_user($c);
    my $stat = $cmspage->status;
    if ($stat) {

        # if the page has local mods, then remove working copy,
        # svn update, and then svn delete

        if ( $stat eq 'M' ) {
            unless ( $cmspage->remove ) {
                croak("Could not remove modified $cmspage");
            }

            unless ( $cmspage->up ) {
                croak("Could not svn update $cmspage");
            }

            unless ( $cmspage->delete ) {
                croak("Could not svn delete $cmspage");
            }

            unless ( $cmspage->commit("deleted by $user") ) {
                croak("Could not commit delete of $cmspage");
            }
        }

        # if the page is new, revert it and then remove
        if ( $stat eq 'A' ) {
            unless ( $cmspage->revert ) {
                croak("Could not revert $cmspage");
                return 0;
            }

            unless ( $cmspage->remove ) {
                croak("Could not remove $cmspage");
                return 0;
            }
        }

        # if svn knows nothing about the file, just remove it
        if ( $stat eq '?' ) {
            unless ( $cmspage->remove ) {
                croak("Could not remove $cmspage");
                return 0;
            }
        }
    }
    else {

        # no local mods. svn delete it.
        unless ( $cmspage->delete ) {
            croak("Count not svn delete $cmspage");
            return 0;
        }

        unless ( $cmspage->commit("deleted by $user") ) {
            croak("Could not commit delete of $cmspage");
            return 0;
        }
    }

    my %res;
    $res{message} = $cmspage->url . " deleted";
    return \%res;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-cms@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

