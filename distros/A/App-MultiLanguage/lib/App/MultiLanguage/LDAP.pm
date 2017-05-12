#
# Copyright (c) 2008-2009 Pan Yu (xiaocong@vip.163.com). 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package App::MultiLanguage::LDAP;

use 5.006;
use strict;
use vars qw($VERSION @ISA);

$VERSION = '0.02';
@ISA     	= qw(App::MultiLanguage);

use Carp;
use Net::LDAP;
use App::MultiLanguage;


sub new {
	my $class = shift;
	my $type = ref($class) || $class;
	my $arg_ref = { @_ };
	
    my $self = bless {}, $type;
    
    if ($arg_ref->{host} =~ /(?:.+):(?:\d+)/) {
    	$self->{_ldap_server} = $arg_ref->{host};
    }else{
    	$self->{_ldap_server} .= (defined $arg_ref->{port})? ":$arg_ref->{port}":':389';
    }
	$self->{_ldap_base} = $arg_ref->{base};
	$self->{_ldap_user} = $arg_ref->{user} if (defined $arg_ref->{user});
	$self->{_ldap_pass} = $arg_ref->{password} if (defined $arg_ref->{password});
    
    eval { $self->_connect; };
    return undef if($@);
    
	$self;
}

sub parse {
	my $self = shift;
	
	$self->{search_args} = \@_;
	$self->_search;
	
	$self->SUPER::parse();
}

sub _connect {
	my $self = shift;
	
	my $ldap = Net::LDAP->new ($self->{_ldap_server}, port => $self->{_ldap_port})
			or croak "$!";
	$self->{handler} = $ldap;
	
	$self->_bind if (defined $self->{_ldap_user} && defined $self->{_ldap_pass} );
}

sub _bind {
	my $self = shift;
	
	my $result = $self->{handler}->bind($self->{_ldap_user}, 
		password => $self->{_ldap_pass},
		port     => $self->{_ldap_port} );
	croak "$!" if $result->code;
}

sub _search {
	my $self = shift;
	
	my $search_args = join ')(cn=', @{$self->{search_args}};
	my @attrs = ("cn", "en", $self->{language});
	my %search = ( base => $self->{_ldap_base},
				   scope => 'one',
				   filter => "(|(cn=$search_args))",	# (|(cn=categories)(cn=buy))
				   attrs => \@attrs );

	my $msg = $self->{handler}->search ( %search );
		croak $msg->error() if $msg->code();
	
	my %entries;
	foreach my $entry ($msg->entries()) {
		my $key = $entry->get_value('cn');
		$entries{$key} = $entry->get_value($self->{language}) || $entry->get_value('en');	# get the language you want. The default language is en.
	}
	$self->{result} = \%entries;
}


1;

__END__

=head1 NAME

App::MultiLanguage::LDAP - Multi-language support for applications

=head1 SYNOPSIS

  use App::MultiLanguage::LDAP;
  
  # two arguments 'host' and 'base' are required to make an instant connnection
  $object = new App::MultiLanguage::LDAP( host => '127.0.0.1',
                                          base => 'ou=language,dc=example,dc=com' );
  
  # set the display language expected in application
  $object->language('zh-cn');
  
  %words = $object->parse('categories','buy');
  
  # to access data
  $words{'categories'}
  $words{'buy'}, 

=head1 DESCRIPTION

The module B<App::MultiLanguage> provides the multi-language support for applications.
All language data will be stored at a LDAP server accessed by B<App::MultiLanguage::LDAP> 
or other sources. For more detail information about LDAP data structure, view readme of 
B<App::MultiLanguage::LDAP>.

=head1 METHODS

Following is the overview of all the available methods accessible via App::MultiLanguage::LDAP object.

=head2 new( host => '127.0.0.1', base => 'ou=language,dc=example,dc=com' )

Returns a new object or undef on failure. Can accept up to five arguments which are,
host - may be a host name or an IP number. TCP port may be specified after the host name followed by a colon (such as localhost:10389). The default TCP port for LDAP is 389.
port - Port to connect to on the remote server. May be overridden by HOST, for example, 127.0.0.1:389
user - It is a DN used for authentication.
password - Bind LDAP server with the given password.
base - The DN that is the base object entry relative to which the search is to be performed.
There is no scope option can be specified, default one is 'one'.

    $object = new App::MultiLanguage::LDAP( 
    	host => '127.0.0.1',
    	port => '389',
    	user => 'cn=manager,dc=example,dc=com',
    	password => 'secret',
    	base => 'ou=language,dc=example,dc=com'
    );

=head2 language()

Set the display language expected in application. There are twenty-six languages can be passed as this argument.

  # Catalan (ca) - Croatian (hr) - Czech (cs) - Danish (da) - Dutch (nl)
  # English (en) - Esperanto (eo) - Estonian (et) - French (fr) - German (de)
  # Greek-Modern (el) - Hebrew (he) - Italian (it) - Japanese (ja)
  # Korean (ko) - Luxembourgeois* (ltz) - Norwegian Nynorsk (nn)
  # Norwegian (no) - Polish (pl) - Portugese (pt)
  # Brazilian Portuguese (pt-br) - Russian (ru) - Swedish (sv)
  # Simplified Chinese (zh-cn) - Spanish (es) - Traditional Chinese (zh-tw)

If there is no corresponding language in database, English will be used as default one.

    $object->language('zh-cn');

=head2 parse();

The function 'parse' will return a hash. The keys would be the id you provided and the values would be the corresponding words or sentances you expected.
Here is a quick example:

    @array = ('continue_shopping','categories','buy','landscape');
    $words = $object->parse(@array);

    # to access expecting language
    $words->{'categories'}

=head1 EXAMPLES
	
	There is a tested LDAP schema file (language.schema) in source file package located at data/ directory.

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
