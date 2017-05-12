package Catalyst::Authentication::Store::UserXML::User;

use strict;
use warnings;

our $VERSION = '0.03';

use Moose;
use Path::Class;
use XML::LibXML;
use Authen::Passphrase;
use Authen::Passphrase::BlowfishCrypt;
use Path::Class 0.26 'file';

extends 'Catalyst::Authentication::User';

has 'xml_filename' => (is=>'ro', isa=>'Path::Class::File', required => 1);
has 'xml' => (is=>'ro', isa=>'XML::LibXML::Document', lazy => 1, builder => '_build_xml');

use overload '""' => sub { shift->username }, fallback => 1;

my $OUR_NS = 'http://search.cpan.org/perldoc?Catalyst%3A%3AAuthentication%3A%3AStore%3A%3AUserXML';

sub _build_xml {
    my $self = shift;
    my $xml_file = $self->xml_filename;

    return XML::LibXML->load_xml(
        location => $xml_file
    );
}

sub get_node {
    my ($self, $element_name) = @_;
    my $dom = $self->xml->documentElement;

    my $xc = XML::LibXML::XPathContext->new($dom);
    $xc->registerNs('userxml', $OUR_NS);
    my ($node) = $xc->findnodes('//userxml:'.$element_name);

    return $node;
}

sub get_node_text {
    my ($self, $element_name) = @_;

    my $node = $self->get_node($element_name);
    return undef unless $node;
    return $node->textContent;
}

*id = *username;
sub username      { return $_[0]->get_node_text('username'); }
sub password_hash { return $_[0]->get_node_text('password'); }
sub status        { return $_[0]->get_node_text('status') // 'active'; }

sub supported_features {
	return {
        password => {
            self_check => 1,
		},
        session => 1,
        roles => 1,
	};
}

sub check_password {
	my ( $self, $secret ) = @_;

    return 0 unless $self->status eq 'active';

    my $password_hash = $self->password_hash;
    my $ppr = eval { Authen::Passphrase->from_rfc2307($password_hash) };
    unless ($ppr) {
        warn $@;
        return;
    }
    return $ppr->match($secret);
}

sub set_password {
	my ( $self, $secret ) = @_;
    my $password_el = $self->get_node('password');

    my $ppr = Authen::Passphrase::BlowfishCrypt->new(
        cost        => 8,
        salt_random => 1,
        passphrase  => $secret,
    );
    $password_el->removeChildNodes();
    $password_el->appendText($ppr->as_rfc2307);
    $self->store;
}

sub set_status {
	my ( $self, $status ) = @_;
    my $status_el = $self->get_node('status');
    if (!$status_el) {
        my $user_el = $self->get_node('password')->parentNode;
        $user_el->appendText(' 'x4);
        $status_el = $user_el->addNewChild($OUR_NS, 'status');
        $user_el->appendText("\n");
    }

    $status_el->removeChildNodes();
    $status_el->appendText($status);

    $self->store;
}

sub roles {
	my $self = shift;

    my $node = $self->get_node('roles');
    return () unless $node;

    my @roles;
    my $xc = XML::LibXML::XPathContext->new($node);
    $xc->registerNs('userxml', 'http://search.cpan.org/perldoc?Catalyst%3A%3AAuthentication%3A%3AStore%3A%3AUserXML');
    foreach my $role_node ($xc->findnodes('//userxml:role')) {
        push(@roles, $role_node->textContent)
    }

    return @roles;
}

sub for_session {
    my $self = shift;
    return $self->username;
}

sub store {
    my $self = shift;
    file($self->xml_filename)->spew($self->xml->toString)
}

1;


__END__

=head1 SYNOPSIS

    my $user = Catalyst::Authentication::Store::UserXML::User->new({
        xml_filename => $file
    });
    say $user->username;
    die unless $user->check_password('secret');

=head1 EXAMPLE

    <!-- userxml-folder/some-username -->
    <user>
        <username>some-username</username>
        <password>{CLEARTEXT}secret</password>
    </user>

=head1 SEE ALSO

L<Authen::Passphrase>

=cut
