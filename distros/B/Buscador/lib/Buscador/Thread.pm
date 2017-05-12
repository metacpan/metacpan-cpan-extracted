package Buscador::Thread;
use strict;

=head1 NAME

Buscador::Thread - provide some thread views for Buscador

=head1 DESCRIPTION

This provides two different thread views for Buscador - traditional 
'JWZ' style view, a rather funky looking 'lurker' style and a thread
arc style cribbed from the IBM ReMail research project. They can be 
accessed using 


    ${base}/mail/thread/<id>
    ${base}/mail/lurker/<id>
    ${base}/mail/arc/<id>

where C<id> can be the message-id of any message in the thread. neat, huh?


=head1 SEE ALSO

JWZ style message threading
http://www.jwz.org/doc/threading.html

Lurker style
http://lurker.sourceforge.net

ReMail Arc style
http://www.research.ibm.com/remail/

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright (c) 2004, Simon Wistow

=cut



package Mail::Thread; # Fscking hack!

no warnings 'redefine';

sub _get_hdr {

    my ($class, $msg, $hdr) = @_;
    $msg->simple->header($hdr) || '';
}

package Email::Store::Thread::Arc::Link;
use base qw(Mail::Thread::Arc);


sub make_link {
    my ($self,$message) = @_;

    # check to see if we actually have this on the system
    # if not, return undef
    my $id  = $message->messageid;
    my $m   = Email::Store::Mail->retrieve($id);
    return undef unless $m && $m->message;
    my $url = Buscador->config->{uri_base}; $url =~ s!/+$!!;
    return "$url/mail/view/$id";
}

package Email::Store::Mail;
use strict;
use Mail::Thread::Chronological;
use Apache;

sub arc :Exported {
    my ($self,$r)  = @_;
    my $mail       = $r->objects->[0];
    my $root       = $mail->container->root;
    my $arc        = Email::Store::Thread::Arc::Link->new;
    while (1) {
        last if $root->message->date;
        my @children = $root->children;
        last if (@children>1);
        $root = $children[0];
    }
    my $svg = $arc->selected_message( undef )->render( $root);

    
    $r->{content_type} = 'image/svg+xml';
    $r->{output}       = $svg->xmlify;
}



sub lurker :Exported {
   my ($self,$r)  = @_;
   my $mail       = $r->objects->[0];
   my $root       = $mail->container->root;

    while (1) {
        last if $root->message->date;
        my @children = $root->children;
        last if (@children>1);
        $root = $children[0];
    }

   my $lurker     = Mail::Thread::Chronological->new;
   my @root       = $lurker->arrange( $root );


   $r->{template_args}{root} = \@root;

}

sub thread :Exported {
    my ($self,$r)  = @_;
   my $mail       = $r->objects->[0];
   my $root       = $mail->container->root;

    while (1) {
        last if $root->message->date;
        my @children = $root->children;
        last if (@children>1);
        $root = $children[0];
    }

   $r->{template_args}{thread} = $root;
}


sub thread_as_html {
    my $mail = shift;
    my $cont = $mail->container;
    my $orig = $cont;
    my %crumbs;
    # We can't use ->root here, because we want to keep track of the
    # breadcrumbs, and this way is more efficient.
    while (1) {
        $crumbs{$cont}++;
        if ($cont->parent) { $cont = $cont->parent } else { last }
    }
    while (1) {
        last if $cont->message->date;
        my @children = $cont->children;
        last if (@children>1);
        $cont = $children[0];
    }
    my $html = "<ul class=\"mktree\">\n";
    my $add_me;
    my $base = Buscador->config->{uri_base};
    $add_me = sub {
        my $c = shift;
        $html .= "<li ".(exists $crumbs{$c} && "class=\"liOpen\"").">";

        # Bypass has-a because we might not really have it!
        my $mess = Email::Store::Mail->retrieve($c->message->id);
        if (!$mess) { $html .= "<i>message not available</i>" }
        elsif ($c == $orig) { $html .= "<b> this message </b>" }
        else {
            $html .= qq{<a href="${base}mail/view/}.$mess->id.q{">}.
        $mess->subject."</a>\n";
        $html .= "<br />&nbsp;&nbsp<small>".eval {$mess->addressings(role =>"From")->first->name->name}."</small>\n";
        }

        if ($c->children) {
            $html .="<ul>\n";
            $add_me->($_) for $c->children;
            $html .= "</ul>\n";
        }
        $html .= "</li>\n";
    };
    $add_me->($cont);
    $html .="</ul>";
    return $html;
}

1;



