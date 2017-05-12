package Dancer::Plugin::Captcha::SecurityImage;
use strict;
use warnings;

our $VERSION = '0.10';

use Carp;
use Dancer ':syntax';
use Dancer::Plugin;
use GD::SecurityImage;

my $conf = plugin_setting;

my $session_engine;

register create_captcha => sub (;$$) {
    my $init = pop || {};
    $init->{$_} ||= $conf->{$_} || {} for qw(new out);
    $init->{$_} ||= $conf->{$_} || [] for qw(create particle);
    my $captcha_id = @_ ? shift : 'default';
    
    $session_engine ||= engine 'session'
        or croak __PACKAGE__ . " error: there is no session engine configured. "
            . "You need a session engine to be able to use this plugin";
    
    my $captcha = GD::SecurityImage->new(%{$init->{new}});
    $captcha->random($init->{random});
    $captcha->create(@{$init->{create}});
    $captcha->particle(@{$init->{particle}});
    my ($image_data, $mime_type, $random_number) = $captcha->out(%{$init->{out}});
    
    _captcha_data($captcha_id, 'string' => $random_number);
    
    header 'Pragma' => 'no-cache';
    header 'Cache-Control' => 'no-cache';
    content_type $mime_type;
    return $image_data;
};

register validate_captcha => sub ($;$) {
    my $user_input = pop;
    my $captcha_id = @_ ? shift : 'default';
    
    my $string = _captcha_data($captcha_id, 'string');
    return $user_input && $string && $user_input eq $string;
};

register clear_captcha => sub (;$) {
    my $captcha_id = shift || 'default';
    _captcha_data($captcha_id, 'string' => undef);
};

sub _captcha_data {
    my ($captcha_id, $key, $val) = @_;
    my $session_data = session('captcha') || {};
    $session_data->{$captcha_id} ||= {};
    if ($val) {
        $session_data->{$captcha_id}{$key} = $val;
        session 'captcha' => $session_data;
    }
    return $session_data->{$captcha_id}{$key};
}

register_plugin;

1;
__END__

=pod

=head1 NAME

Dancer::Plugin::Captcha::SecurityImage - generate and verify GD::SecurityImage 
captchas from Dancer

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Captcha::SecurityImage;
    
    session 'simple';
    
    get '/captcha' => sub {
        create_captcha {
            new => {
                width    => 80,
                height   => 30,
                lines    => 10,
                gd_font  => 'giant',
            },
            create     => [ normal => 'rect' ],
            particle   => [ 100 ],
            out        => { force => 'jpeg' },
            random     => $your_random_string,
        };
    };
    
    post '/verify' => sub {
        my $p = request->params;
        
        if (!validate_captcha $p->{captcha}) {
            return "wrong code";
        }
        clear_captcha;
    };

=head1 ABSTRACT

This plugin lets you use L<GD::SecurityImage> in your L<Dancer> application to create
and verify captcha codes. It stores captcha data in your session, so you have to 
enable a session engine for Dancer.

=head1 EXPORTED FUNCTIONS

=head2 create_captcha

This function expects a hashref containing options that will be passed to the 
L<GD::SecurityImage> constructor and methods.

=head2 validate_captcha

This function expects the value that your user entered in the form. It will check 
it against the real code stored in the Dancer session and return true if they match.

=head2 clear_captcha

This function will remove the captcha value from your session data so that it won't
match again.

=head1 CONFIGURATION

Any option passed to the L<create_captcha> function, except for C<random>, can also 
be put in your config file:

    plugins:
      SecurityImage:
        new:
          width: 80
          height: 30
          lines: 10
          gd_font: giant

=head1 SEE ALSO

=over 4

=item L<Dancer>

=item L<GD::SecurityImage>

=back

=head1 BUGS

Please report any bugs to the web interface at 
L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Dancer-Plugin-Captcha-SecurityImage>.
The author will be happy to read your feedback.

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alessandro Ranellucci.

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
