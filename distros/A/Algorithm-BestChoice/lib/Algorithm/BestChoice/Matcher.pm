package Algorithm::BestChoice::Matcher;

sub parse {
    my $class = shift;
    my $matcher = shift;

    return Algorithm::BestChoice::Matcher::Always->new unless defined $matcher;

    $matcher = qr/^\Q$matcher\E$/ unless ref $matcher;

    if (ref $matcher eq 'Regexp') {
        return Algorithm::BestChoice::Matcher::Regexp->new( regexp => $matcher );
    }
    elsif (ref $matcher eq 'CODE') {
        return Algorithm::BestChoice::Matcher::Code->new( code => $matcher );
    }

    die "Don't understand matcher $matcher";
}

use Moose;

# TODO Make this a role?

sub match {
    die "Unspecific matcher can't match";
}

package Algorithm::BestChoice::Matcher::Always;

use Moose;

extends qw/Algorithm::BestChoice::Matcher/;

sub match { 1 }

1;

package Algorithm::BestChoice::Matcher::Regexp;

use Moose;

extends qw/Algorithm::BestChoice::Matcher/;

has regexp => qw/is ro required 1 isa RegexpRef/;

sub match {
    my $self = shift;
    my $key = shift;

    return 0 unless defined $key;
    return $key =~ $self->regexp;
}

package Algorithm::BestChoice::Matcher::Code;

use Moose;

extends qw/Algorithm::BestChoice::Matcher/;

has code => qw/is ro required 1 isa CodeRef/;

sub match {
    my $self = shift;
    my $key = shift;

    return $self->code( $key );
}

1;
