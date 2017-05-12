#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Helper - Base class for command-line script functionality
#
#  DESCRIPTION
#  Base class module that implements a constructor and provides helper
#  script functionality for writing template output to a file.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Helper;

use strict;
use warnings;
use base 'Apache2::WebApp::Base';
use Params::Validate qw( :all );

use Apache2::WebApp::AppConfig;
use Apache2::WebApp::Template;

our $VERSION = 0.06;
our $AUTOLOAD;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# new()
#
# Constructor method used to return new helper object.

sub new {
    my $class = shift;
    return bless({
        CONFIG   => Apache2::WebApp::AppConfig->new,
        TEMPLATE => Apache2::WebApp::Template->new,
        VARS     => {},
    }, $class);
}

#----------------------------------------------------------------------------+
# set_vars(\%vars)
#
# Set the template object attributes.

sub set_vars {
    my ($self, $vars)
      = validate_pos(@_,
          { type => OBJECT  },
          { type => HASHREF }
      );

    @{ $self->{VARS} }{keys %$vars} = values %$vars;
}

#----------------------------------------------------------------------------+
# write_file( $file, $output )
#
# Write the template output to a file.

sub write_file {
    my ($self, $file, $output)
      = validate_pos(@_,
          { type => OBJECT },
          { type => SCALAR },
          { type => SCALAR }
      );

    $self->{TEMPLATE}->process($file, $self->{VARS}, $output)
      or $self->error(
          "@{[ $self->{TEMPLATE}->error() ]} at $file"
        );

    print "created file $output\n" if ( $self->{VERBOSE} );
}

#----------------------------------------------------------------------------+
# get_source_path()
#
# Returns the path to the /webapp-toolkit source directory.

sub get_source_path {
    my $self
      = validate_pos(@_,
          { type => OBJECT }
      );

    my ($package, $filename, $line) = caller;
    $filename =~ s/^(.*)\/lib\/.*$/$1/;
    return $filename . '/share/webapp-toolkit';
}

#----------------------------------------------------------------------------+
# error($mesg)
#
# Print errors/exceptions to STDOUT and exit.

sub error {
    my ($self, $mesg)
      = validate_pos(@_,
          { type => OBJECT },
          { type => SCALAR }
      );

    print "$mesg\n";
    exit;
}

#----------------------------------------------------------------------------+
# AUTOLOAD()
#
# Provides pseudo-methods for read-only access to various internal methods.

sub AUTOLOAD {
    my $self = shift;
    my $method;
    ($method = $AUTOLOAD) =~ s/.*:://;
    return if ($method eq 'DESTROY');
    return $self->{ uc($method) };
}

1;

__END__

=head1 NAME

Apache2::WebApp::Helper - Base class for command-line script functionality

=head1 SYNOPSIS

  use Apache2::WebApp::Helper;

  my $obj = Apache2::WebApp::Helper->new;

=head1 DESCRIPTION

Base class module that implements a constructor and provides helper script
functionality for writing template output to a file.

=head1 OBJECT METHODS

=head2 set_vars

Set the template object attributes.

  $obj->set_vars(\%vars);

=head2 write_file

Write the template output to a file.

  $obj->write_file($file, $output);

=head2 get_source_path

Returns the path to the /webapp-toolkit source directory.

  $self->get_source_path();

=head2 error

Print errors/exceptions to STDOUT and exit.

  $self->error($mesg);

=head1 EXAMPLES

=head2 Template to file processing

=head3 SCRIPT 

  use Apache2::WebApp::Helper;

  my $obj = Apache2::WebApp::Helper->new;

  $obj->set_vars(
      {
          foo => 'bar',
          baz => qw( bucket1 bucket2 bucket3 ),
          qux => qw{
                     key1 => 'value1',
                     key2 => 'value2',
                     ...
                  },
          ...
       }
    );

  # program continues...

  $obj->write_file('/path/to/infile.tt','/path/to/outfile.txt');

=head3 TEMPLATE

  [% foo %]

  [% FOREACH bucket = bar %]
      [% bucket %]
  [% END %]

  [% qux.key1 %]
  [% qux.key2 %]

=head1 SEE ALSO

L<Apache2::WebApp>, L<Apache2::WebApp::AppConfig>, L<Apache2::WebApp::Template>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
