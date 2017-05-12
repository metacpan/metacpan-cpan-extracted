package Catalyst::Plugin::FormValidator::Simple::Messages;
use strict;
use warnings;

use base qw/Catalyst::Plugin::FormValidator::Simple/;
use Catalyst::Exception;
use YAML;

our $VERSION = '0.02';

sub setup {
    my $self = shift;
    $self->NEXT::setup(@_);
    my $setting = $self->config->{validator} || {};
    
    return unless exists $setting->{messages};
    return if ref $setting->{messages} eq 'HASH';
    
    if ( -e $setting->{messages} && -f _ && -r _ ) {
        eval {
            $setting->{messages} = YAML::LoadFile( $setting->{messages} );
        };
        Catalyst::Exception->throw( message => __PACKAGE__ . qq/: $@/ ) if $@;
    }
}

sub form {
    my $c = shift;
    if ($_[0]) {
        my $setting = $c->config->{validator} || {};
        $c->{validator}->set_messages($setting->{messages})             if exists $setting->{messages};
        $c->{validator}->set_message_format($setting->{message_format}) if exists $setting->{message_format};
    }
    $c->NEXT::form(@_);
}

sub set_invalid_form {
    my $c = shift;
    my $setting = $c->config->{validator} || {};
    $c->{validator}->set_messages($setting->{messages})             if exists $setting->{messages};
    $c->{validator}->set_message_format($setting->{message_format}) if exists $setting->{message_format};
    $c->NEXT::set_invalid_form(@_);
}

1;

__END__

=head1 NAME

Catalyst::Plugin::FormValidator::Simple::Messages - FormValidator::Simple can be handled by plural Catalyst application in mod_perl

=head1 SYNOPSIS

 use Catalyst qw/
       :
     FormValidator::Simple::Messages
       :
 /;

=head1 DESCRIPTION

The FormValidator::Simple can be handled by plural Catalyst application in mod_perl.

=head1 AUTHOR

Ittetsu Miyazaki E<lt>ittetsu.miyazaki@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catalyst::Plugin::FormValidator::Simple>

Nihongo Document is Catalyst/Plugin/FormValidator/Simple/Messages/Nihongo.pod

=cut
