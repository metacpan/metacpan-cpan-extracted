#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::AppConfig - AppConfig extension for parsing config files
#
#  DESCRIPTION
#  A module for accessing application configuration settings.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::AppConfig;

use strict;
use warnings;
use base 'Apache2::WebApp::Base';
use AppConfig qw( :argcount );
use Params::Validate qw( :all );

our $VERSION = 0.01;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# parse($file)
#
# Return the configuration name/value pairs as a reference to a hash.

sub parse {
    my ($self, $file)
      = validate_pos(@_,
          { type => OBJECT },
          { type => SCALAR }
      );

    my $config;

    eval {
        $config = AppConfig->new(
            {
                CREATE => 1,
                GLOBAL => {
                    ARGCOUNT => ARGCOUNT_ONE,
                },
            }
          );
        $config->file($file);
      };

    if ($@) {
        $self->error("Failed to parse config '$file'");
    }

    return $config->{FILE}->{STATE}->{VARIABLE};
}

1;

__END__

=head1 NAME

Apache2::WebApp::AppConfig - AppConfig extension for parsing config files

=head1 SYNOPSIS

  $c->config->parse('/path/to/file.cfg');

  print $c->config->{$key}, "\n";    # key = value format

=head1 DESCRIPTION

A module for accessing application configuration settings.

=head1 OBJECT METHODS

=head2 parse

Return the configuration name/value pairs as a reference to a hash.

  $c->config->parse($config);

=head1 FILE FORMAT

=head2 STANDARD

  # this is a comment
  foo = bar               # bar is the value of 'foo'
  url = index.html#hello  # 'hello' is treated as a comment

=head2 BLOCKED

  [block1]
  foo = bar               # bar is the value of 'block1_foo'

  [block2]
  foo = baz               # baz is the value of 'block2_foo' 

=head1 SEE ALSO

L<Apache2::WebApp>, L<AppConfig>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> - L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
