
package CGI::Application::Plugin::Phrasebook;

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use CGI::Application;
use Data::Phrasebook;

our $VERSION = '0.02';

our @EXPORT = qw(
    config_phrasebook
    phrasebook
);

sub import {
    my $pkg  = shift;
    my $call = caller;
    no strict 'refs';
    foreach my $sym (@EXPORT) {
        *{"${call}::$sym"} = \&{$sym};
    }
}

sub config_phrasebook {
    my $self = shift;
    unless (ref($_[0])) {
        $self->{'__PHRASEBOOK'}{'pb'}{'__DEFAULT__'} = Data::Phrasebook->new(@_);
        return;
    }
    foreach my $name (keys %{$_[0]}) {
        $self->{'__PHRASEBOOK'}{'pb'}{$name} = Data::Phrasebook->new(%{$_[0]->{$name}});
    }
}

sub phrasebook {
    my $self = shift;
    return $self->{'__PHRASEBOOK'}{'pb'}{'__DEFAULT__'} unless @_;
    return $self->{'__PHRASEBOOK'}{'pb'}{$_[0]}; 
}

1;

__END__

=pod

=head1 NAME

CGI::Application::Plugin::Phrasebook - A CGI::Application plugin for Data::Phrasebook

=head1 SYNOPSIS
  
  package MyCGIApp;
  
  use base 'CGI::Application';
  use CGI::Application::Plugin::Phrasebook;
  
  sub cgiapp_prerun {
      my $self = shift;
      $self->config_phrasebook(
          class  => 'Plain',
          loader => 'YAML',
          file   => 'conf/my_phrasebook.yml',        
      ); 
      # ... do other stuff here ...
  }
  
  sub some_run_mode {
      my $self = shift;
      # grab the phrasebook instance 
      # and fetch a keyword from it
      return $self->phrasebook->fetch('a_phrasebook_keyword');
  }

=head1 DESCRIPTION

This is a very simple plugin which provides access to an instance 
(or instances) of L<Data::Phrasebook> inside your L<CGI::Application>. 
I could have just stuffed this in with C<param>, but this way is much 
nicer (and easier to type).

=head1 METHODS

=over 4

=item B<config_phrasebook (@phrasebook_args|\%multiple_phrasebooks)>

Given an array of arguments, this configures your L<Data::Phrasebook> 
instance by simply passing any arguments onto C<Data::Phrasebook::new>. 
It then stashes it into the L<CGI::Application> instance.

If given a HASH reference, this will configure multiple 
L<Data::Phrasebook> instances, one for each hash key. Here is an 
example, of how that would be used.

  package MyCGIApp;
  
  use base 'CGI::Application';
  use CGI::Application::Plugin::Phrasebook;
  
  sub cgiapp_prerun {
      my $self = shift;
      $self->config_phrasebook({
          my_yaml_phrasebook => { 
              class  => 'Plain',
              loader => 'YAML',
              file   => 'conf/my_phrasebook.yml',        
          },
          my_txt_phrasebook => {
              class  => 'Plain',
              loader => 'Text',
              file   => 'conf/my_phrasebook.txt',            
          }
      }); 
      # ... do other stuff here ...
  }
  
  sub some_run_mode {
      my $self = shift;
      return $self->phrasebook('my_yaml_phrasebook')->fetch('a_phrasebook_keyword');
  }
  
  sub some_other_run_mode {
      my $self = shift;
      return $self->phrasebook('my_txt_phrasebook')->fetch('a_phrasebook_keyword');
  }
  
You can also assign one of the hash keys to the string C<__DEFAULT__>, 
and it will be used as the default phrasebook. But this behavior is 
optional. 

=item B<phrasebook (?$phrasebook_name)>

This will return the L<Data::Phrasebook> instance, or C<undef> if one 
has not yet been configured. 

If the plugin has been configured with multiple phrasebooks, you can 
specify the particular C<$phrasebook_name>, if one is not specified, 
it will attempt to use the phrasebook called C<__DEFAULT__>. If the 
phrasebook is not found, C<undef> is returned.

=back

=head1 SEE ALSO

=over 4

=item L<Data::Phrasebook>

=item L<http://www.perl.com/pub/a/2002/10/22/phrasebook.html>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut