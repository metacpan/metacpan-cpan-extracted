package MyApp::Config;

use Config::Singleton -setup => {
  filename => 'myapp.yaml',
  template => {
    hostname => 'localhost',
    username => undef,
    charset  => 'ISO-8859-1',
    clothes  => [ qw(top pants flipflops) ],
  },
};

=head1 SETTINGS

=over 4

=item * hostname

the hostname to connect to for MyApp

=item * username

the username to login with

=item * charset

the charset for MyApp

=back 

=cut

1;
