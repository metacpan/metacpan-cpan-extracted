package App::wmiirc::Backlight;
{
  $App::wmiirc::Backlight::VERSION = '1.000';
}
use App::wmiirc::Plugin;
with 'App::wmiirc::Role::Key';

# So on my vaio the down works here, but up doesn't(?!), I've hacked it into the
# acpi stuff instead -- urgh. Serves me right for buying proprietary Sony stuff
# I guess.

sub key_backlight_down(XF86MonBrightnessDown) {
  system qw(xbacklight -steps 1 -time 0 -dec 10);
}

sub key_backlight_up(XF86MonBrightnessUp) {
  system qw(xbacklight -steps 1 -time 0 -inc 10);
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Backlight

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

