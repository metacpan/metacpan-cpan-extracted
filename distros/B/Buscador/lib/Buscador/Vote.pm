package Buscador::Vote;


package Email::Store::Mail;
use strict;
use Email::Store::Vote;

sub vote :Exported {
    my ($self, $r, $mail) = @_;
    my $vote = Email::Store::Vote->create({ mail=>$mail->id });


    my $loc = Buscador->config->{uri_base}; 

    $loc =~ s!/+$!!;
    $loc .= "/mail/view/".$mail->id;

    $r->{template} = "view";
    $r->location($loc);

}

sub popular :Exported {
    my ($self, $r) = @_;

    my $pager = Email::Store::Mail->do_pager($r);
    $r->{objects} = [$pager->search_popular  ];


}

__PACKAGE__->set_sql( popular => qq{
    SELECT mail.message_id, count(vote.mail) AS votes 
    FROM mail, vote
    WHERE mail.message_id = vote.mail
    GROUP BY vote.mail 
    ORDER BY votes DESC
});

1;
