#
# Copyright (c) 2008-2009 Pan Yu (xiaocong@vip.163.com). 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package App::MultiLanguage;

use 5.006;
use strict;
use vars qw($VERSION);

$VERSION = '0.02';


sub language {
	my $self = shift;
	my $language = shift;
    
	$self->{language} = $language;
}

sub parse {
	my $self = shift;
	
	return $self->{result};
}


1;

__END__

=head1 NAME

App::MultiLanguage - Multi-language support for applications

=head1 SYNOPSIS

  use App::MultiLanguage::LDAP;
  
  # two arguments 'host' and 'base' are required to make an instant connnection
  $object = new App::MultiLanguage::LDAP( host => '127.0.0.1',
                                          base => 'ou=language,dc=example,dc=com' );
  
  # set the display language expected in application
  $object->language('zh-cn');
  
  $words = $object->parse('categories','buy');
  
  # to access data
  $words->{'categories'}
  $words->{'buy'}

=head1 DESCRIPTION

The module B<App::MultiLanguage> provides the multi-language support for applications.
All language data will be stored at a LDAP server accessed by B<App::MultiLanguage::LDAP> 
or other sources. For more detail information about LDAP data structure, view readme of 
B<App::MultiLanguage::LDAP>.

=head1 ACKNOWLEDGEMENTS

A special thanks to Larry Wall <larry@wall.org> for convincing me that
no development could be made to the Perl community without everyone's contribution.
I am also very conscious of the patience bestowed upon me by my wife, Fu Na, who is always 
there to listen when I need to talk and laugh when I need a smile. Thank you.

=head1 AUTHOR

Pan Yu <xiaocong@vip.163.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2009 by Pan Yu. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
