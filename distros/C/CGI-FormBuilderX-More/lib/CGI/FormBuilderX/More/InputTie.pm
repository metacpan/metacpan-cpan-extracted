package CGI::FormBuilderX::More::InputTie;

use strict;
use warnings;

use Carp::Clan qw/^CGI::FormBuilderX::More::/;

=head1 SYNOPSIS 

    use CGI::FormBuilderX::More;
    use CGI::FormBuilderX::More::InputTie;

    my $form = CGI::FormBuilderX::More->new( ... );
    my %hash;
    tie %hash, $form; # %hash is now tied to the input of $form

    if (exists $hash{username}) {
        ...
    }

    $hash{password} = "12345"

=head1 METHODS

=head2 TIEHASH($form)

    my %hash;
    tie %hash, $form;

    # %hash is now tied to $form input
    
=cut

sub TIEHASH {
    my $self = bless {}, shift;
    my $form = shift;
    $self->{form} = $form;
    return $self;
}

=head2 STORE($key, $value)

    $hash{$key} = $value

    sub {
        return $form->input_store($key, $value)
    }

=cut

sub STORE {
    my $self = shift;
    my ($key, $value) = @_;
    return $self->{form}->input_store($key => $value);
}

=head2 FETCH($key)

    $value = $hash{$key};

    sub {
        return $form->input_fetch($key)
    }

=cut

sub FETCH {
    my $self = shift;
    my ($key) = @_;
    return $self->{form}->input_fetch($key);
}

=head2 EXISTS($key)

    exists $hash{$key};

    sub {
        return ! $form->missing($key)
    }

=cut

sub EXISTS {
    my $self = shift;
    my ($key) = @_;
    return ! $self->{form}->missing($key);
}

=head2 SCALAR

    sub {
        return scalar $form->{params}->param
    }

=cut

sub SCALAR {
    my $self = shift;
    return scalar $self->{form}->{params}->param;
}

=head2 FIRSTKEY

N/A

=cut

sub FIRSTKEY {
    croak __PACKAGE__ . "::FIRSTKEY is invalid"
}

=head2 NEXTKEY

N/A

=cut

sub NEXTKEY {
    croak __PACKAGE__ . "::NEXTKEY is invalid"
}

=head2 DELETE

N/A

=cut

sub DELETE {
    croak __PACKAGE__ . "::DELETE is invalid"
}

=head2 CLEAR

N/A

=cut

sub CLEAR {
    croak __PACKAGE__ . "::CLEAR is invalid"
}

1;
