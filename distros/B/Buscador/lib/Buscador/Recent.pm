package Buscador::Recent;
use strict;


=head1 NAME

Buscador::Recent - provide a list of recent mails for the system and lists

=head1 DESCRIPTION

This allows you to do


    ${base}/mail/recent/

which is also the default if there's no path parsed, e.g

    ${base}

and also

    ${base}/list/recent/<id>

=head1 AUTHOR

Simon Cozens, <simon@cpan.org>

with work from

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2004, Simon Cozens

=cut


sub parse_path_order { 1 }

sub parse_path {
    my ($self, $buscador) = @_;

    $buscador->{path} ||= "/mail/recent";
}


package Email::Store::Mail;
use strict;

sub recent :Exported {
    my ($self, $r) = @_;
    $self = $self->do_pager($r);
    $r->{template_args}{mails} = [ $self->search_recent ];
}


__PACKAGE__->set_sql(recent_posts => qq{
    SELECT mail.message_id
    FROM list_post, mail_date, mail
    WHERE
         list_post.list = ?
     AND mail.message_id = list_post.mail
     AND mail.message_id = mail_date.mail
    ORDER BY mail_date.date DESC
});

__PACKAGE__->set_sql(recent => qq{
    SELECT mail.message_id
    FROM mail_date, mail
    WHERE mail.message_id = mail_date.mail
    ORDER BY mail_date.date DESC
});


package Email::Store::List;

sub view :Exported {
    my ($self, $r, $tmp) = @_;
    my $pager = Email::Store::Mail->do_pager($r);
        
    my $id    = $r->args->[0] || $tmp->id || 0;


    if ($id !~ /^\d+$/) {
        my ($list) = __PACKAGE__->search_like( name => $id );
        $id = 0;
        if (defined $list) {
            $id   = $list->id;
            $self = $list; 
            $r->{template_args}{list}    = $self;

        }
    }

    $r->{template_args}{recent} = [ $pager->search_recent_posts($id) ];

}



1;
