
package Config::Constants::XML;

use strict;
use warnings;

our $VERSION = '0.02';

use base 'Config::Constants::Perl';

use Config::Constants::XML::SAX::Handler;
use XML::SAX::ParserFactory;

sub _init {
    my ($self, $file) = @_;
    (-e $file && -f $file)
        || die "Bad config file '$file' either it doesn't exist or it's not a file";    
    my $handler = Config::Constants::XML::SAX::Handler->new();
    my $p = XML::SAX::ParserFactory->parser(Handler => $handler);
    $p->parse_uri($file);
    $self->{_config} = $handler->config();
}

1;

__END__

=head1 NAME

Config::Constants::XML - Configuration loader for Config::Constants

=head1 SYNOPSIS
  
  use Config::Constants::XML;

=head1 DESCRIPTION

This module reads and parses XML files as configuration files that look like this:

  <config>
      <module name='Foo::Bar'>
          <constant name='BAZ' value='the coolest module ever' />
      </module>
  </config>  
  
It is also possible to do more complex constant value types, like this:

  <config>
      <module name='Foo::Bar2'>
            <constant name='BAZ' type='ARRAY'>
              [ 1, 2, 3 ]
            </constant>
      </module>
      <module name='Bar::Baz2'>
          <constant name='FOO' type='HASH'>
              { test => 'this', out => 10 }
          </constant>
          <constant name='BAR' type='My::Object'>
              My::Object->new()
          </constant>        
      </module>
  </config>
  
The C<type> parameter much match the value returned after C<eval>-ing the text.

You can also include other configurations into the current one like this:

  <config> 
      <include path='conf/base_conf.xml' />
      <module name='Foo::Bar'>
          <constant name='BAZ' value='the coolest module ever' />
      </module>
  </config>  

The configurations are processed in order, so in this example, anything set in F<conf/base_conf.xml> will be shadowed by anything set in the current xml.

=head1 METHODS

=over 4

=item B<new ($file)>

This takes the file, loads, parses and stores the resulting configuration.

=item B<modules>

This will return an array of modules in this configuration.

=item B<constants ($module_name)>

Given a C<$module_name>, this will return an array of hash references for each constant specified.

=back

=head1 TO DO

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, see the L<Config::Constants> module for more information.

=head1 SEE ALSO

=over 4

=item L<XML::SAX>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

