package App::wmiirc::Screenshot;
{
  $App::wmiirc::Screenshot::VERSION = '1.000';
}
use App::wmiirc::Plugin;
with 'App::wmiirc::Role::Action';

sub _screenshot {
  my($window) = @_;
  system sprintf config("commands", "screenshot",
    'import -window %s ~/$(date +screenshot-%%Y-%%m-%%d-%%H-%%M-%%S.png)'),
    $window;
}

sub action_screenshot {
  _screenshot("root");
}

sub action_screenshot_active {
  my $window_id = hex wmiir "/client/sel/ctl";
  _screenshot($window_id);
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Screenshot

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

