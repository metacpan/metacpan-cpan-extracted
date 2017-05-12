package Amazon::Dash::Button::Device;
$Amazon::Dash::Button::Device::VERSION = '0.11';
use strict;
use warnings;

use Simple::Accessor qw{mac onClick name timeout last_click _fork_for_onClick};

# ABSTRACT: a very simple perl interface to play & interact with an Amazon Dash Button.

=head1 NAME

Amazon::Dash::Button::Device - the button class itself

=head1 VERSION

version 0.11

=head1 DESCRIPTION

Amazon::Dash::Button::Device should be used by Amazon::Dash::Button.

=cut

sub _build_name { ( $_[0]->mac() // '' ) . ' (unknown name)' }
sub _build_last_click        { 0 }
sub _build_timeout           { 5 }
sub _build__fork_for_onClick { 1 }    # by default fork to run the onClick

sub _build_onClick {
    return sub {
        print qq{No onClick action defined for this button: } . $_[0]->name . q{\n};
    };
}

sub _validate_mac {
    my ( $self, $mac ) = @_;

    $mac =~ qr{^[0-9a-f:]+$}i or die "invalid mac address";

    return 1;
}

sub _after_mac {    # always save the mac address as a lowercase one
    my ( $self, $mac ) = @_;
    $self->{mac} = lc($mac);
    $self->{mac} =~ s{:}{}g;

    return 1;
}

sub build {
    my $self = shift;

    # check the mac address
    die "mac address is undefined" unless defined $self->mac();

    return $self;
}

sub debug {
	warn join( ' ', map { $_ // 'undef' } @_ );
}

sub check {
    my ( $self, $mac2check ) = @_;

    return unless defined $mac2check;

    $mac2check =~ s{:}{}g;

    return if $self->mac() ne lc($mac2check);

    debug( "Find Button", $self->name() );
    my $now = time();
    return
      if $self->timeout > 0 && ( $now - $self->last_click ) <= $self->timeout;
    $self->last_click($now);
    debug( "perform onClick for", $self->name() );

    # we want to fork to run the onClick action
    #	we can disable it during unit tests or others
    return
      if $self->_fork_for_onClick()
      && fork();    # TODO protect the fork if it fails ?
     # if you are not forking you want the onClick function to return pretty fast
     #	as a click will generate several packets inside the timeout window
    $self->onClick->();

    exit(0) if $self->_fork_for_onClick();

    return 1;
}

1;
