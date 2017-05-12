package Buscador::Addressing;
use strict;

=head1 NAME

Buscador::Addressing - A Buscador plugin to deal with presentin entities

=head1 DESCRIPTION

Email::Store has the concept of Entities. An Entity can have multiple
names and multiple email addressess. This pluign allows you to do


    ${base}/entity/view/<id>
    ${base}/entity/view/<name>
    ${base}/entity/view/<email>


    ${base}/name/view/<id>
    ${base}/name/view/<name>

    ${base}/address/view/<id>
    ${base}/address/view/<email>

to get various relevant information.


=head1 SEE ALSO

"What is a person?"
http://blog.simon-cozens.org/bryar.cgi/id_6744?comments=1

=head1 AUTHOR(S)

Simon Cozens, <simon@cpan.org>

with additional work from

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright (c) 2004, Simon Cozens

=cut



package Email::Store::Mail;

__PACKAGE__->set_sql(mentioned_entity => qq{
    SELECT DISTINCT mail.message_id 
    FROM named_entity, mail, mail_date
    WHERE
        description = ?
    AND mail.message_id = mail_date.mail
    AND thing = ?
    AND mail.message_id = named_entity.mail
    ORDER BY mail_date.date DESC
});


# This is an evil hack
Email::Store::Entity::Name->set_sql(most_common => qq{
    SELECT name id, count(*) total
        FROM addressing
    WHERE entity = ?
    GROUP BY name
    ORDER BY total
    LIMIT 1
});


Email::Store::Entity::Address->set_sql(most_common => qq{
    SELECT address id, count(*) total
        FROM addressing
    WHERE entity = ?
    GROUP BY address
    ORDER BY total
    LIMIT 1
});

my $sorted = qq{
    SELECT addressing.id
    FROM addressing, mail_date
    WHERE %s = ?
     AND addressing.mail = mail_date.mail
    ORDER BY mail_date.date DESC
};

Email::Store::Addressing->set_sql(name_sorted => sprintf($sorted, "name"));
Email::Store::Addressing->set_sql(entity_sorted => sprintf($sorted, "entity"));
Email::Store::Addressing->set_sql(address_sorted => sprintf($sorted, "address"));

# TODO
# the whole gumpf to retrieve the id if it's not a number
# should be stuck somewhere as a subroutine

package Email::Store::Entity::Name;
use Email::Store::Entity;

sub view :Exported {
    my ($class, $r, $name) = @_;
    my $pager = Email::Store::Addressing->do_pager($r);

     my $id    = $r->args->[0] || $name->id || 0;

     if ($id !~ /^\d+$/) {
        my ($tmp) = __PACKAGE__->search_like( name => $id );
        $id = 0;
        if (defined $tmp) { 
            $id   = $tmp->id;
            $name = $tmp;
        }
     }


    $r->{template_args}{name} = $name;
    $r->{template_args}{sorted_addressings} =
        [ $pager->search_name_sorted($name->id) ];
}

sub mentioned_mails {
    my $self = shift;
    my %mails;
    return unless $self->name;
    for ($self->addressings) {
        $mails{$_->mail->id} = {
            mail => $_->mail,
            role => $_->role
        }
    }
    my @ment = 
        grep {!exists $mails{$_->id}}
    Email::Store::Mail->search_mentioned_entity("person", $self->name);
    #for (@ment) {
    #    $mails{$_->id} ||= {
    #        mail => $_,
    #        role => "mentioned"
    #    }
    #}
    #sort {$b->{mail}->date cmp $a->{mail}->date} values %mails;
}



package Email::Store::Entity::Address;
sub view :Exported {
    my ($class, $r, $self) = @_;
    my $pager = Email::Store::Addressing->do_pager($r);

     my $id    = $r->args->[0] || $self->id || 0;

     if ($id !~ /^\d+$/) {
        my ($tmp) = __PACKAGE__->search( address => $id );
        $id = 0;
        if (defined $tmp) { 
            $id   = $tmp->id;
            $self = $tmp;
        }
     }



    $r->{template_args}{address} = $self;
    $r->{template_args}{sorted_addressings} =
        [$pager->search_address_sorted($self->id) ];
}

package Email::Store::Entity;
sub view :Exported {
    my ($class, $r, $self) = @_;
    my $pager = Email::Store::Addressing->do_pager($r);
    
    my $id    = $r->args->[0] || $self->id || 0;


    goto END if $id =~ /^\d+$/;    


    my $field  = 'name'; 
    my $method = 'search_like';

    if ($id =~ /@/) {
        $field  = 'address';
        $method = 'search';
    }

    my $class =  "Email::Store::Entity::".ucfirst($field);

    my ($obj) =  $class->$method( $field => $id );
    goto END unless $obj;
    my $tmp   =  $obj->addressings()->first->entity;

    $id = 0;
    if (defined $tmp) {
        $id   = $tmp->id;
        $self = $tmp;
    }

    END:
    $r->{template_args}{entity} = $self;
    $r->{template_args}{sorted_addressings} =
        [$pager->search_entity_sorted($id)];
}

sub most_common_name { Email::Store::Entity::Name->search_most_common(shift->id)->first }
sub most_common_address { Email::Store::Entity::Address->search_most_common(shift->id)->first }


package Email::Store::Addressing;
use Class::DBI::Pager;
sub do_pager {
    my ($self, $r) = @_;
    if ( my $rows = $r->config->{rows_per_page}) {
        return $r->{template_args}{pager} = $self->pager($rows, $r->query->{page});
    } else { return $self }
}


1;
