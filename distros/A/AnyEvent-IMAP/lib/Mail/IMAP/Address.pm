package Mail::IMAP::Address;
use strict;
use warnings;
use utf8;

use Encode ();

use constant {
    NAME           => 0,
    AT_DOMAIN_LIST => 1,
    MAILBOX        => 2,
    HOST           => 3,
};

sub new {
    my ($class, $address) = @_;
    bless $address, $class;
}

use overload q("") => \&as_string;

sub _decode {
    my ($str) = @_;
    if ( defined($str) ) {
        eval { $str = Encode::decode( 'MIME-Header', $str ); };
    }
    return $str;
}

sub name           { _decode( $_[0]->[NAME] ) }
sub at_domain_list { _decode( $_[0]->[AT_DOMAIN_LIST] ) }
sub mailbox        { _decode( $_[0]->[MAILBOX] ) }
sub host           { _decode( $_[0]->[HOST] ) }

sub email {
    my ($self) = @_;
    return $self->mailbox . '@' . $self->host;
}

sub as_string {
    my $self = shift;
    if ($self->name) {
        return sprintf("%s <%s>", $self->name, $self->email);
    } else {
        return $self->email;
    }
}

1;

