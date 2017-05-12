package Buscador::Decorate;
use strict;

=head1 NAME

Buscador::Decorate - mark a mail body up in HTML

=head1 DESCRIPTION

This provides a method C<format_body> for B<Email::Store::Mail>
which marks up the body of a mail as HTML including making links
clickable, highlighting quotes, and correctly providing links for
names and addresses that we've seen before.


=head1 AUTHOR

Simon Cozens, <simon@cpan.org>

with work from

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2004, Simon Cozens

=cut




package Email::Store::Mail;
use strict;
use Text::Decorator;
use Text::Autoformat;
use HTML::Scrubber;

sub format_body {
    my $mail = shift;

    # NOTE! this needs a lot of work 
    my $ct = $mail->simple->header('Content-Type') || "";

    
    return $mail->body if ($ct =~ m!text/html!i);
    my $html = ($mail->html)[0];
    return $html->scrubbed if $html;


    my $body = $mail->body;
    my $decorator = Text::Decorator->new($body);

    my %seen;
    my @names =
                grep {!$seen{$_->thing}++}
                grep {$_->thing =~ / /}
                grep {$_->score > 6}
                $mail->named_entities(description => "person");

    my @addresses = Email::Store::Entity::Address->retrieve_all;

    unless (defined $html) {
    $decorator->add_filter("Quoted", begin => '<span style="display: block;" class="level%i">',
                                     end   => '</span>') ;


    $decorator->add_filter("URIFind");
    $decorator->add_filter("TTBridge" => "html" => "html_entity");
    }

    $decorator->add_filter("NamedEntity" => @names) if @names;
    $decorator->add_filter("Addresses" => @addresses) if @addresses;

    $decorator->format_as("html");
    
}

package Text::Decorator::Filter::NamedEntity;
$INC{"Text/Decorator/Filter/NamedEntity.pm"}++; # for ->require
use Text::Decorator::Group;
use base 'Text::Decorator::Filter';
use HTML::Entities;

sub filter_node {
    my ($class, $args, $node) = @_;
    my (@entities) = @$args;
    # Prepare it.
    $node->{representations}{html} = $node->format_as("html");
    my $test = join "|", map {quotemeta($_->thing)} @entities;
    my $base = Buscador->config->{uri_base};
    my $img  = Buscador->config->{img_base};
    return $node unless $node->{representations}{html} =~ m{\b($test)\b}ims;
    for my $entity (@entities) {
        my ($name) = Email::Store::Entity::Name->search(name => $entity->thing);
        if ($name) {
            my $nn = encode_entities($name->name);
            my $id = $name->id;
            $node->{representations}{html} =~ s{\b\Q$nn\E\b}
                {<a href='${base}name/view/$id' class='personknown'> <sup><img src='$img/personknown.gif' alt='known person' /> </sup>$nn</a>}gmsi;
#        } elsif ($entity->score >= 20) { # Have to be damned sure
#            my $nn = encode_entities($entity->thing);
#            $node->{representations}{html} =~ s{\b\Q$nn\E\b}
#                {<span class="personunknown"> <sup><img src="$img/personunknown.gif"> </sup>$nn</span>}gims;
        }
    }
    return $node;
}


package Text::Decorator::Filter::Addresses;
$INC{"Text/Decorator/Filter/Addresses.pm"}++; # for ->require
use base 'Text::Decorator::Filter';
use HTML::Entities;
use Email::Find;

sub filter_node {
    my ($class, $args, $node) = @_;

    my %addresses             = map { $_->address => $_ } @$args;

    $node->{representations}{html} = $node->format_as("html");


    my $base = Buscador->config->{uri_base};
    my $img  = Buscador->config->{img_base};

     my $finder = Email::Find->new(
        sub {
            my($email, $orig_email) = @_;
            if ($addresses{$orig_email}) {
                my $add = $addresses{$orig_email};
                my $id  = $add->id;
                return "<a href='${base}address/view/$id' class='personknown'>".
                       " <sup><img src='$img/personknown.gif' alt='known person' /> </sup>$orig_email</a>"
            } else {
                return "<sup><img src='$img/personunknown.gif' alt='known person' /> </sup>$orig_email";
            }
                                       
    });
    $finder->find(\$node->{representations}{html});    



    return $node;

}

1;
