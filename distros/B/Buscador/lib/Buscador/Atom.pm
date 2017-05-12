package Buscador::Atom;
use strict;

=head1 NAME

Buscador::Atom - a plugin to provide atom feeds for Buscador

=head1 DESCRIPTION

This provides four different Atom feeds for a B<Buscador> system -

Most recent mails in the whole system

=head2 Available through
    
    ${base}/atom.xml

or

    ${base}/mail/atom


=head2 Most recent mails for a list

    ${base}/list/atom/<id>

=head2 Most recent mails for an entity

    ${base}/entity/atom/<id>

=head2 Most recent mails for a thread

    ${base}/mail/thread/atom/<id>

or

    ${base}/mail/thread_atom/<id>

Where C<id> is any message-id from that thread.


=head1 SEE ALSO

http://www.atomenabled.org/

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright (c) 2004, Simon Wistow

=cut


sub parse_path_order { 13 }

sub parse_path {
    my ($self, $buscador) = @_;

    $buscador->{path} =~ s!atom.xml$!mail/atom/!;
    $buscador->{path} =~ s!mail/thread/atom/!mail/thread_atom/!;
}

package Email::Store::Mail;
use Date::Parse qw( str2time );

sub atom :Exported {
    my ($self, $r) = @_;

    my $pager = $self->do_pager($r);
 
    $r->{content_type}         = "application/xml";
    $r->{objects}              = [ $pager->search_recent ];
    $r->{template_args}{link}  = Buscador->config->{uri_base};
    $r->{template_args}{title} = "Recent mails from ".Buscador->config->{uri_base};
    $r->{template}             = "custom/atom";
}

sub extract_time {
    my $self = shift;
    my $container = shift;

    my $date = Mail::Thread->_get_hdr( $container->message, 'date' );
    return str2time( $date );
}


sub thread_atom :Exported {
    my ($self, $r) = @_;

    my $base       = Buscador->config->{uri_base};
    my $mail       = $r->objects->[0];
    my $root       = $mail->container->root;
      
    # get all the mails in this thread
    my @messages;
    $root->iterate_down(
        sub {
            my ($c, $d) = @_;
            push @messages, $c if $c->message;
        } );

    # okay, wander them in date order
    @messages = 
                sort { $self->extract_time( $a ) <=>
                       $self->extract_time( $b ) } @messages;

    my @return;
    my $count = 0;
    for (@messages) {
        my $mess = Email::Store::Mail->retrieve($_->message->id);
        next unless $mess;
        push @return, $mess;
        last if $count++ > Buscador->config->{rows_per_page};
    }

    $base =~ s!/\s*$!!;

    $r->{content_type}         = "application/xml";
    $r->{objects}              = [ @return ];
    $r->{template_args}{link}  = "$base/mail/thread/".$mail->id;
    $r->{template_args}{title} = "Recent mails from $base/mail/thread/".$mail->id;
    $r->{template}             = "atom";
}


package Email::Store::List;

sub atom :Exported {
    my ($self, $r, $list) = @_;

    my $pager = Email::Store::Mail->do_pager($r);

    $r->{content_type}         = "application/xml";
    $r->{template_args}{link}  = Buscador->config->{uri_base}."list/view/".$list->id;
    $r->{template_args}{mails} = [ $pager->search_recent_posts($list->id) ];
    $r->{template_args}{title} = "Recent mails from ".$list->name;
    $r->{template}             = "custom/atom";
}

package Email::Store::Entity; 

sub atom :Exported {
    my ($self, $r, $name) = @_;

    my $pager     = Email::Store::Addressing->do_pager($r);
    my @mails     = $pager->search_name_sorted($name->id);

    $r->{template_args}{mails} = [ map { $_->mail } @mails ];

    # find the first name available to us
    my $person;
    foreach my $mail (@mails) {
        $person = $mail->name->name;
        last if $person && $person !~ /^\s*$/;
    }

    $r->{content_type}         = "application/xml";
    $r->{template_args}{link}  = Buscador->config->{uri_base}."entity/view/".$name->id;
    $r->{template_args}{title} = "Recent mails from $person";
    $r->{template}             = "custom/atom";

}


1;
