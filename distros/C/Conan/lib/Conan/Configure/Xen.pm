package Conan::Configure::Xen;

use strict;
use Carp;

sub new {
	my $class = shift;

	my $args = {
		basedir	=> '/xen/prod/etc/',
		@_,
	};
	
	# By default the IP isn't outputted, but rather
	# generated in the 'extra' field
	unless( $args->{generators}->{ip} ){
		$args->{generators}->{ip} = sub {
			my $self = shift;
			return sprintf "#ip = '%s'\n", $self->{settings}->{ip};
		};
	}

	unless( $args->{generators}->{netmask} ){
		$args->{generators}->{netmask} = sub {
			my $self = shift;
			return sprintf "#netmask = '%s'\n", $self->{settings}->{netmask};
		};
	}

	unless( $args->{generators}->{gateway} ){
		$args->{generators}->{gateway} = sub {
			my $self = shift;
			return sprintf "#gateway = '%s'\n", $self->{settings}->{gateway};
		};
	}

	unless( $args->{generators}->{extra} ){
		$args->{generators}->{extra} = sub {
			my $self = shift;
			return sprintf "extra = ' ip=%s::%s:%s::eth0:off NFS=%s= %s %s ro clocksource=jiffies'\n",
				$self->{settings}->{ip},
				$self->{settings}->{gateway},
				$self->{settings}->{netmask},
				$self->{settings}->{nfsroot},
				$self->{settings}->{postboot},
				$self->{settings}->{name} || $self->{name};
		};
	}

	bless $args => $class;
}

sub generate {

	my $self = shift;
	my $output = sprintf "# This was generated on %s by %s\n", scalar localtime( time() ), 'Conan::Configure::Xen';
	$output .= "# Please do not manually edit\n";

	for my $key (qw/        
			name
			kernel      
			memory      
			vcpus       
			vif         
			ip          
			netmask     
			gateway     
			on_poweroff 
			on_reboot   
			on_crash    
			extra/){
		if( exists $self->{generators}->{$key} ){
			my $sub = $self->{generators}->{$key};
			$output .= $sub->($self);
		} elsif( defined $self->{settings}->{$key} ){
			if( $key eq 'vif' ){
				# This is the weird one
				$output .= $key . " = [ " . "'$self->{settings}->{$key}'" . " ]\n";
			} else {
				$output .= $key . " = " . "'$self->{settings}->{$key}'" . "\n";
			}
		}
	}

	return $output;

}

sub parse {
	my $self = shift;

	my %hostsettings;

	my @files = glob "$self->{basedir}/*.cfg.tmpl $self->{basedir}/*.cfg";

	s/\/{2,}/\//g for @files;

	croak "Name not defined" unless defined $self->{name};

	# Get the hostconfig files
	my @hostconfig = grep { /$self->{name}/ } @files;

	my $basename = $self->{name};
	$basename =~ s/\d+//g;

	my @baseconfig = grep { /$basename\.cfg/ } @files;

	for( @baseconfig ){
		my %hash2 = $self->parse_template( $_ );
		@hostsettings{keys %hash2} = values %hash2;
	}

	for( @hostconfig ){
		my %hash2 = $self->parse_template( $_ );
		@hostsettings{keys %hash2} = values %hash2;
	}

	$self->{settings} = \%hostsettings;

	# post parse stuff
	if( $self->{settings}->{NFS} ){
		if( $self->{settings}->{version} ){
			$self->{settings}->{NFS} .= "/" . $self->{settings}->{version};
			# Strip duplicate /
			$self->{settings}->{NFS} =~ s,/+,/,g;
		}
		$self->{settings}->{nfsroot} = $self->{settings}->{NFS};
	}

	return $self->{settings};
}

sub host_template {
	my $self = shift;

	my $filename = shift;
}

sub parse_template {
	my $self = shift;

	my $filename = shift;

	my %settings;

	open my $fd, "<$filename";

	if( $fd ){
		my @lines = <$fd>;
		chomp for @lines;
		s/#.*//g for @lines;

		%settings = map { ($1,$2) if /(\S+)\s*=\s*(?:\[\s*)?'(.*?)'/ } grep( ! /^\s*$/, @lines );
		close $fd;
	}

	return %settings;
}	

1;

__END__

=head1 NAME

Conan::Configure::Xen - Used to parse and generate I<Xen> compatible configuration files.

=head1 SYNOPSIS

  use Conan::Configure::Xen;
  
  my $config = Conan::Configure::Xen->new(
          basedir => '/tmp/',
          name => 'foo06',
          settings => {
                  ip => '1.2.3.5',
          },
  );
  
  $config->parse();
  
  print $config->generate();
 

 
=head1 DESCRIPTION

This class is used to pull in configuration templates (both class type, and
image type) to generate I<Xen> style configuration files.

All I<settings> are pulled from the configuration files matching
C<foo.cfg.tmpl> and C<foo\d+.cfg> in that order.  Meaning, the I<settings> data
structure will source the base template file first, then complete the sourcing
with the config file (if any) that matches the hostname provided.

=head1 USAGE

=over 4

=item new

The I<new> method uses C</xen/prod/etc> as its default basedir, and allows an
override to be supplied to the constructor.

  my $args = {
  	basedir	=> '/xen/prod/etc/',
  	@_,
  };

This method also accepts I<generators> to be supplied.  A I<generator> is a
subroutine reference attached to a keyname that is called to provide special
formatting for a given keyname.  The most common case for this is to provide a
hash before the line for certain variables to ensure that the values can be set
within the template config file, but are not expressed in the final output.  

The generators defined within the I<new> method are the C<ip>, C<netmask>,
C<gateway> and C<extra> fields.

An example of a generator being called during instance invocation is:

  my $config = Conan::Configure::Xen->new(
    generators => {
      ip => sub {
        my $self = shift;
        my $output = '';
        $output .= "# I'm the IP generator\n";
        $output .= "ip = '" . $self->{settings}->{ip} . "'" . "\n"
          if( $self->{settings}->{ip} );
        return $output;
      }
    },
  );


=item generate

This method generates a configuration file, outputing a line for each of the
following keys:

C<name>
C<kernel>
C<memory>      
C<vcpus>       
C<vif>        
C<ip>         
C<netmask>    
C<gateway>    
C<on_poweroff>
C<on_reboot>  
C<on_crash>   
C<extra>

B<note>, if a generator exists with the keyname, it is called to express the
output for that keyname rather than the values sourced by the config file and
stored within the C<settings> data structure.

=item parse

This method finds the appropriate configuration files, and executes the
I<parse_template> method on each matching config file.

=item parse_template

This method simply accepts a config filename, and executes the following regex against it: 

C<%settings = map { ($1,$2) if /(\S+)\s*=\s*(?:\[\s*)?'(.*?)'/ } grep( ! /^\s*$/, @lines );>

B<Example>:

=over 6

  # Comments are eliminated
  key = 'value'
  # To accomodate the vif stuff
  key = [ 'value' ]

=back

=back
