package API::DirectAdmin::DNS;

use Modern::Perl '2010';
use Carp;

use base 'API::DirectAdmin::Component';

our $VERSION = 0.06;

# Return zone dump
# params: domain
sub dumpzone {
    my ($self, $params ) = @_;
    
    my %add_params = (
	noparse => 1,
    );
    
    my %params = (%$params, %add_params);
    
    my $zone = $self->directadmin->query(
        params         => \%params,
        command        => 'CMD_API_DNS_CONTROL',
        allowed_fields => 'domain noparse',
    );

    return _parse_zone($zone, $params->{domain}. '.', '') unless ref $zone eq 'HASH';
    return $zone;
}

# Add records A, MX, CNAME, NS, PTR, TXT, AAAA
# params: domain, type, name, value
sub add_record {
    my ($self, $params ) = @_;

    my %add_params = (
	action => 'add',
    );
    
    my %params = (%$params, %add_params);

    return $self->directadmin->query(
        params         => \%params,
        command        => 'CMD_API_DNS_CONTROL',
	method	       => 'POST',
        allowed_fields => "type name action value domain",
    );
}

# Remove records A, MX, CNAME, NS, PTR, TXT, AAAA, SRV
# params: domain, type, name, value
sub remove_record {
    my ($self, $params ) = @_;
    
    my %add_params = (
	action => 'select',
	lc $params->{type} . 'recs0' => "name=$params->{name}&value=$params->{value}",
    );
    
    delete $params->{type};
    
    my %params = (%$params, %add_params);

    return $self->directadmin->query(
        params         => \%params,
        command        => 'CMD_API_DNS_CONTROL',
	method	       => 'POST',
	allowed_fields => 'domain 
			   action 
			   name 
			   value 
			   arecs0 
			   mxrecs0 
			   txtrecs0 
			   aaaarecs0 
			   nsrecs0 
			   cnamerecs0 
			   srvrecs0 
			   ptrrecs0',
    );
}

# Special parser for zone dump
# Cropped code from Parse::DNS::Zone
sub _parse_zone {
    my ($zonetext, $origin) = @_;
    
    my $mrow;
    my $prev;
    my %zone;

    my $zentry = qr/^
	    (\S+)\s+ # name
	    (
		    (?: (?: IN | CH | HS ) \s+ \d+ \s+ ) |
		    (?: \d+ \s+ (?: IN | CH | HS ) \s+ ) |
		    (?: (?: IN | CH | HS ) \s+ ) |
		    (?: \d+ \s+ ) |
	    )? # <ttl> <class> or <class> <ttl>
	    (\S+)\s+ # type
	    (.*) # rdata
    $/ix;

    foreach ( split /\n+/, $zonetext ) {

	    chomp;
	    s/;.*$//;
	    next if /^\s*$/;
	    s/\s+/ /g;
	    
	    s/^\@ /$origin /g;
	    s/ \@ / $origin /g;
	    s/ \@$/ $origin/g;

	    # handles mutlirow entries, with ()
	    if($mrow) {
		    $mrow.=$_;
		    
		    next if(! /\)/); 

		    # End of multirow 
		    $mrow=~s/[\(\)]//g;
		    $mrow=~s/\n//mg;
		    $mrow=~s/\s+/ /g;
		    $mrow .= "\n";	

		    $_ = $mrow;
		    undef $mrow;
	    } elsif(/^.*\([^\)]*$/) {
		    # Start of multirow
		    $mrow.=$_;
		    next;
	    }

	    if(/^ /) {
		    s/^/$prev/;
	    }

	    $origin = $1, next if(/^\$ORIGIN ([\w\-\.]+)\s*$/i);

	    my($name,$ttlclass,$type,$rdata) = /$zentry/;

	    my($ttl, $class);
	    if(defined $ttlclass) {
		    ($ttl) = $ttlclass=~/(\d+)/o;
		    ($class) = $ttlclass=~/(CH|IN|HS)/io;

		    $ttlclass=~s/\d+//;
		    $ttlclass=~s/(?:CH|IN|HS)//;
		    $ttlclass=~s/\s//g;
		    if($ttlclass) {
			    next;
		    }
	    }

	    $ttl = defined $ttl ? $ttl : 14400;

	    next if (!$name || !$type || !$rdata);

	    $prev=$name;
	    $name.=".$origin" if $name ne $origin && $name !~ /\.$/;

	    if($type =~ /^(?:cname|afsdb|mx|ns)$/i and 
	       $rdata ne $origin and $rdata !~ /\.$/) {
		    $rdata.=".$origin";
	    }

	    push(@{$zone{lc $name}{lc $type}{rdata}}, $rdata);
	    push(@{$zone{lc $name}{lc $type}{ttl}}, $ttl);
	    push(@{$zone{lc $name}{lc $type}{class}}, $class);
    }

    return \%zone;
}

1;
