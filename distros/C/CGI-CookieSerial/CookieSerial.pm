# MODINFO module CGI::CookieSerial a wrapper for creating serialized cookies with Data::Serializer and CGI::Cookie
package CGI::CookieSerial;

# MODINFO dependency module 5.006
use 5.006;
# MODINFO dependency module warnings
use warnings;
# MODINFO dependency module CGI::Cookie
use CGI::Cookie;
# MODINFO dependency module Data::Serializer
use Data::Serializer;

# MODINFO version 0.06
our $VERSION = '0.06';

# MODINFO constructor new create a new CookieSerial object
sub new {
        my $class = shift;
        $class = ref($class) if ref($class);
	my $self = bless {}, $class;
	my %flags = @_;

	# cookie vars
	$self->{name} = $flags{-name} || '';
	$self->{data} = $flags{-data} || '';
        $self->{path} = $flags{-path} || '/';
        $self->{domain} = $flags{-domain};
        $self->{secure} = $flags{-secure};
        $self->{expires} = $flags{-expires};

	$self->{noserialize} = $flags{-noserialize} || 0;

	if ( ! $self->{noserialize} ) {	
		# serial vars
		$self->{serializer} = $flags{-serializer};
		$self->{digester} = $flags{-digester};
		$self->{cipher} = $flags{-cipher};
		$self->{secret} = $flags{-secret} || 'Sd35wsyJJ6l9zaPxkaeAQUZE3yoCDA83P9ZilFyuYefb+pVJ+qiKZKCp7JqBXpYz';
		$self->{portable} = $flags{-portable};
		$self->{compress} = $flags{-compress} || 1;
		$self->{debug} = '';
		$self->{serializer_token} = $flags{-serializer_token};

        	$self->{capncrunch} = Data::Serializer->new(			# yes, I know it's not a cookie cereal... it's just so good...
			serializer => $self->{serializer},
			digester => $self->{digester},
        	        cipher => $self->{cipher},
        	        secret => $self->{secret},
        	        compress => $self->{compress},
			serializer_token => $self->{serializer_token},
        	);
	}
        return $self;
}

# MODINFO method burn
sub burn {
        my $self = shift;
	$self->{data} ||= shift || '';
	if ( ! $self->{noserialize} ) {
		$self->{data} = $self->{capncrunch}->freeze($self->{data});
	} 

        # make into cookie form
        my $cookie = CGI::Cookie->new(
                -name => $self->{name},
                -value => $self->{data},
                -path => $self->{path},
                -domain => $self->{domain},
                -secure => $self->{secure},
                -expires => $self->{expires},
        );

        # print header
        print "Set-Cookie: $cookie\n";
}

# MODINFO method cool
sub cool {
        my $self = shift;

        # fetch cookie
        my %cookies = fetch CGI::Cookie;
	$self->{data} ||= '';
	$self->{debug} = "\$self->{data} = $self->{data}<br>".
		"\$self->{name} = $self->{name}<br>";
        my $data = $cookies{$self->{name}}->value() if $self->{data};

        # deserialize the data
        my $soggy = ( $self->{noserialize} ) ? $data : $self->{capncrunch}->thaw($data);

        return $soggy;
}

# MODINFO method eat
sub eat {
        my $self = shift;
        my $cookie_name = shift;

        print $self->cool($cookie_name);
}

1;
__END__

=head1 NAME

CGI::CookieSerial - a wrapper for creating a CGI serial cookie or cookies with any serialized perl data stuctures 

=head1 SYNOPSIS

Setting a cookie with data:

 use strict;
 use CGI;
 use CGI::CookieSerial;

 my $cgi = new CGI;
 my $pbscookie = new CGI::CookieSerial(  
  	-name => 'ticklemeelmo', 
 );

 my @data = (
	{
 		'to' => 'di',
		'froo' => 'ti',
 		actor => 'Steve Martin',
		food => 3.14,
	},
	'apple',
	24,
 );

 $pbscookie->burn(\@data);
 print $cgi->header({  
	-type => 'text/html', 
 });

Retrieving a cookie with data:

 use strict;
 use Data::Dumper;
 use CGI;
 use CGI::CookieSerial;

 my $cgi = new CGI;
 my $pbscookie = new CGI::CookieSerial(  
	-name => 'ticklemeelmo', 
 );

 my @data = @{$pbscookie->cool()};

 print $cgi->header({  -type => 'text/html', });

 print "<html><body><pre>Data check:<br>";
 print Dumper(@data)."<br>";
 print "$data[2]<br>";
 print "$data[0]{actor}";
 print "</body></html>"; 

Retrieving a regular cookie:

 use strict;
 use Data::Dumper;
 use CGI;
 use CGI::CookieSerial;

 my $cgi = new CGI;
 my $pbscookie = new CGI::CookieSerial(
        -name => 'tv.station',
        -noserialize => 1,   
 );

 my $station_call_letters = $pbscookie->cool();

 print $cgi->header({  -type => 'text/html', });

 print "<html><body><pre>";
 print "Call letters: $station_call_letters";
 print "</body></html>";


=head1 ABSTRACT

Although deceptively similar to the workings of CGI::Cookie, this module
operates a little differently. By design, it is very simple to use. In
essence, one need only instantiate a new object and name the cookie,
create the data, and burn the cookie. Retrieval is just as simple.

=head1 DESCRIPTION

This module is simpler to use than other cookie modules, but other than that, there isn't much difference. 

=head1 METHONDS

=head2 new()

In addition to the CGI::Cookie->new() parameters, the constructor also takes the same parameters as Data::Serializer->new(). There is one new parameter, -noserialize, which is a boolean that enables one to turn off the serializing function and fetch regular cookies. These give the following list of parameters:

 -name
 -value 
 -expires
 -domain
 -path 
 -secure 

and
 
 -noserialize

and

 -serializer
 -digester
 -cipher
 -secret
 -portable
 -compress
 -serializer_token

=head2 burn()

This method takes a parameter that is a reference to the data you want to store in the cookie. It serializes it and then sends the header. Only call this method when you are ready to set the cookie header.

=head2 cool()

This method returns the value of the cookie, either a stings or a reference (depending on what you stored).

=head2 eat()

This method simply prints the value of the cookie. There's really not a great deal of use for this method, despite the name, unless you are debugging.

=head1 TODO

=over 4

=item 

Implement this with inheritance

=item

Not require that data be a reference, and have the module intelligently check and then Do The Right Thing

=back

=head1 SEE ALSO

L<CGI>, L<CGI::Cookie>, L<Data::Serializer>

=head1 AUTHOR

Duncan McGreggor, E<lt>oubiwann at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Duncan McGreggor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
