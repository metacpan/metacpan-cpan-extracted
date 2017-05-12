package DMTF::CIM::WSMan;

use warnings;
use strict;
use URI;
use URI::Escape;
require URI::_server;
use DMTF::WSMan;
use DMTF::CIM;
use DMTF::CIM::Instance;
use XML::Twig;
use DateTime::Duration;
use MIME::Base64;
use Carp;

use version;
our $VERSION = qv('0.09');

our @ISA=qw(DMTF::CIM);

# Custom URI types
{
	package URI::wsman_Owbem;
	our @ISA=qw(URI::_server);
	sub default_port { 0 }
	sub canonical
	{
		my $self = shift;
		my $other = $self->SUPER::canonical;

		my $slash_path = defined($other->authority) &&
			!length($other->path) && !defined($other->query);

		if ($slash_path) {
			$other = $other->clone if $other == $self;
			$other->path("/");
		}

		my $path=URI::Escape::uri_escape(URI::Escape::uri_unescape($other->path),'?#');
		if($path=~/([^:]*):([^.]*).(.*)$/) {
			my ($ns, $class, $selectors)=($1,$2,$3);

			my @selectors=split(/(?<=[^=\\]"),/, $selectors);
			my $newselectors=join(",", sort @selectors);
			if($newselectors ne $selectors) {
				$other = $other->clone if $other == $self;
				$path=URI::Escape::uri_escape("$ns:$class.".$newselectors,'?#');
				$other->path($path);
			}
		}
		if($path ne $other->path) {
			$other = $other->clone if $other == $self;
			$other->path($path);
		}

		$other;
	}
	sub path
	{
		my $self = shift;
		$$self =~ m,^((?:[^:/?\#]+:)?(?://[^/?\#]*)?)([^?\#]*)(.*)$,s or die;

		if (@_) {
			$$self = $1;
			my $rest = $3;
			my $new_path = shift;
			$new_path = "" unless defined $new_path;
			$new_path = URI::Escape::uri_escape($new_path,'?#');
			utf8::downgrade($new_path);
			URI::_generic::_check_path($new_path, $$self);
			$$self .= $new_path . $rest;
		}
		$2;
	}
	sub namespace {
		my $self = shift;
		my $path=$self->path;
		
		if($path=~/([^:]*)(?::[^.]*)?(?:\..*)?$/) {
			return $1;
		}
		return;
	}
	sub class {
		my $self = shift;
		my $path=$self->path;
		
		if($path=~/(?:[^:]*):([^.]*)(?:\..*)?$/) {
			return $1;
		}
		return;
	}
}
{
	package URI::wsman_Owbems;
	our @ISA=qw(URI::wsman_Owbem);
	sub default_port { 0 }
	sub secure { 1 }
}

# Module implementation here
sub new
{
	my $class=shift;
	my $self=DMTF::CIM::new($class);
	$self->{CURRENTURI}=URI->new('/interop');
	$self->{AUTHORITIES}={};
	$self->{TWIG}=XML::Twig->new(
		keep_spaces=>1,
		map_xmlns=>{
			'http://www.w3.org/2003/05/soap-envelope'=>'s',
			'http://schemas.xmlsoap.org/ws/2004/08/addressing'=>'a',
			'http://schemas.xmlsoap.org/ws/2004/09/enumeration'=>'n',
			'http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd'=>'w',
			'http://schemas.dmtf.org/wbem/wsman/1/cimbinding.xsd'=>'b',
			'http://schemas.dmtf.org/wbem/wscim/1/common'=>'c',
			'http://www.w3.org/2001/XMLSchema-instance'=>'x',
			'http://schemas.xmlsoap.org/ws/2004/09/transfer'=>'t',
		},
		elt_accessors=>[
			's:Body',
		],
	);
	$self->{QUIRKS}={
		'association_object_wrong'=>0,
		'incorrect_string_octetstring'=>0
	};
	bless($self, $self->{CLASS});
	return($self);
}

###############
# Generic Ops #
###############
sub GetInstance
{
	my $self=shift;
	my %args=@_;
	$args{uri}=$args{InstancePath} if(defined $args{InstancePath});
	$args{ico}=$args{IncludeClassOrigin} if(defined $args{IncludeClassOrigin});
	$args{ico}=0 if(!defined $args{ico});
	$args{iq}=$args{IncludeQualifiers} if(defined $args{IncludeQualifiers});
	$args{iq}=0 if(!defined $args{iq});
	$args{props}=$args{IncludedProperties} if(defined $args{IncludedProperties});

	if($args{ico}) {
		carp("WS-Management does not implement IncludeClassOrigin support");
		return;
	}
	if($args{iq}) {
		carp("WS-Management does not implement IncludeQualifiers support");
		return;
	}

	$self->current_uri($args{uri});
	my $epr=$self->current_epr;
	my $wsman=$self->current_wsman;
	if(!defined $epr || !defined $wsman) {
		return;
	}

	my $xmlstr=$wsman->get(epr=>$epr);
	if(!defined $xmlstr) {
		return;
	}
	my $xml=$self->{TWIG}->parse($xmlstr);
	return if(!defined $xml);
	if($self->_checkfault($xml->root)) {
		return;
	}
	my $instance=$xml->root->first_child('s:Body')->first_child;
	if(!defined $instance) {
		carp("No instance nor fault returned!");
		return;
	}
	my $ret=$self->_parse_instance($instance);
	$ret->uri($self->current_uri->canonical);
	return $ret;
}

sub DeleteInstance
{
	my $self=shift;
	my %args=@_;
	$args{uri}=$args{InstancePath} if(defined $args{InstancePath});
	$args{ico}=$args{IncludeClassOrigin} if(defined $args{IncludeClassOrigin});
	$args{ico}=0 if(!defined $args{ico});
	$args{iq}=$args{IncludeQualifiers} if(defined $args{IncludeQualifiers});
	$args{iq}=0 if(!defined $args{iq});

	if($args{ico}) {
		carp("WS-Management does not implement IncludeClassOrigin support");
		return;
	}
	if($args{iq}) {
		carp("WS-Management does not implement IncludeQualifiers support");
		return;
	}

	$self->current_uri($args{uri});
	my $epr=$self->current_epr;
	my $wsman=$self->current_wsman;
	if(!defined $epr || !defined $wsman) {
		return;
	}

	my $xmlstr=$wsman->delete(epr=>$epr);
	if(!defined $xmlstr) {
		return;
	}
	my $xml=$self->{TWIG}->parse($xmlstr);
	return if(!defined $xml);
	if($self->_checkfault($xml->root)) {
		return;
	}
	return 1;
}

sub ModifyInstance
{
	my $self=shift;
	my %args=@_;
	$args{uri}=$args{InstancePath} if(defined $args{InstancePath});
	$args{object}=$args{ModifiedInstance} if(defined $args{ModifiedInstance});
	$args{ico}=$args{IncludeClassOrigin} if(defined $args{IncludeClassOrigin});
	$args{ico}=0 if(!defined $args{ico});
	$args{iq}=$args{IncludeQualifiers} if(defined $args{IncludeQualifiers});
	$args{iq}=0 if(!defined $args{iq});
	$args{props}=$args{IncludedProperties} if(defined $args{IncludedProperties});

	if($args{ico}) {
		carp("WS-Management does not implement IncludeClassOrigin support");
		return;
	}
	if($args{iq}) {
		carp("WS-Management does not implement IncludeQualifiers support");
		return;
	}
	if(!defined $args{object}) {
		carp("No ModifiedInstance (object) specified");
		return;
	}
	$args{uri}=$args{object}->uri;

	$self->current_uri($args{uri});
	my $epr=$self->current_epr;
	my $wsman=$self->current_wsman;
	if(!defined $epr || !defined $wsman) {
		return;
	}

	my $body=$self->_instance_to_XML($args{object});
	return unless defined $body;
	my $xmlstr=$wsman->put(epr=>$epr,body=>$body);
	if(!defined $xmlstr) {
		return;
	}
	my $xml=$self->{TWIG}->parse($xmlstr);
	return if(!defined $xml);
	if($self->_checkfault($xml->root)) {
		return;
	}
	my $instance=$xml->root->first_child('s:Body')->first_child;
	if(!defined $instance) {
		carp("No instance nor fault returned!");
		return;
	}
	my $ret=$self->_parse_instance($instance);
	$ret->uri($self->current_uri->canonical);
	return $ret;
}

sub CreateInstance
{
	my $self=shift;
	my %args=@_;
	$args{uri}=$args{ClassPath} if(defined $args{ClassPath});
	$args{object}=$args{NewInstance} if(defined $args{NewInstance});
	$args{ico}=$args{IncludeClassOrigin} if(defined $args{IncludeClassOrigin});
	$args{ico}=0 if(!defined $args{ico});
	$args{iq}=$args{IncludeQualifiers} if(defined $args{IncludeQualifiers});
	$args{iq}=0 if(!defined $args{iq});

	if($args{ico}) {
		carp("WS-Management does not implement IncludeClassOrigin support");
		return;
	}
	if($args{iq}) {
		carp("WS-Management does not implement IncludeQualifiers support");
		return;
	}
	if(!defined $args{object}) {
		carp("No new instance (object) specified");
		return;
	}
	$args{uri}=$args{object}->uri;

	$self->current_uri($args{uri});
	my $epr=$self->current_epr;
	foreach my $key (keys %{$epr->{SelectorSet}}) {
		delete $epr->{SelectorSet}{$key} unless $key eq '__cimnamespace';
	}
	my $wsman=$self->current_wsman;
	if(!defined $epr || !defined $wsman) {
		return;
	}

	my $body=$self->_instance_to_XML($args{object});
	return unless defined $body;
	my $xmlstr=$wsman->create(epr=>$epr,body=>$body);
	if(!defined $xmlstr) {
		return;
	}
	my $xml=$self->{TWIG}->parse($xmlstr);
	return if(!defined $xml);
	if($self->_checkfault($xml->root)) {
		return;
	}
	my $ref=$xml->root->first_child('s:Body')->first_child('t:ResourceCreated');
	if(!defined $ref) {
		carp("No instance nor EPR returned!");
		return;
	}
	my $ret=URI->new($self->_parse_reference($ref));
	if(defiend $ret->class) {
		$self->class_tag_alias($ret->class, lc($ret->class));
	}
	return $ret->canonical;
}

sub GetClassInstancesWithPath
{
	my $self=shift;
	return $self->_get_instances('class','instanceswithpath', @_);
}

sub GetClassInstancePaths
{
	my $self=shift;
	return $self->_get_instances('class','paths', @_);
}

sub GetReferencingInstancesWithPath
{
	my $self=shift;
	return $self->_get_instances('association','instanceswithpath', @_);
}

sub GetReferencingInstancePaths
{
	my $self=shift;
	return $self->_get_instances('association','paths', @_);
}

sub GetAssociatedInstancesWithPath
{
	my $self=shift;
	return $self->_get_instances('associated','instanceswithpath', @_);
}

sub GetAssociatedInstancePaths
{
	my $self=shift;
	return $self->_get_instances('associated','paths', @_);
}

sub InvokeMethod
{
	my $self=shift;
	my %args=@_;
	my $faking=0;

	$args{uri}=$args{InstancePath} if(defined $args{InstancePath});
	$args{method}=$args{MethodName} if(defined $args{MethodName});
	$args{params}=$args{InParmValues} if(defined $args{InParmValues});
	$args{ico}=$args{IncludeClassOrigin} if(defined $args{IncludeClassOrigin});
	$args{ico}=0 if(!defined $args{ico});
	$args{iq}=$args{IncludeQualifiers} if(defined $args{IncludeQualifiers});
	$args{iq}=0 if(!defined $args{iq});

	if($args{ico}) {
		carp("WS-Management does not implement IncludeClassOrigin support");
		return;
	}
	if($args{iq}) {
		carp("WS-Management does not implement IncludeQualifiers support");
		return;
	}
	if(!defined $args{method}) {
		carp("No method argument passed to InvokeMethod()");
		return;
	}
	$self->current_uri($args{uri});
	my $epr=$self->current_epr;
	my $wsman=$self->current_wsman;
	if(!defined $epr || !defined $wsman) {
		return;
	}

	my $classname;
	if($epr->{ResourceURI} =~ /([^\/]*)$/) {
		$classname=$1;
	}
	else {
		carp "Unable to extract class from $epr->{ResourceURI}";
		return;
	}

	# We need the model to invoke methods... no half-assing this one.
	my $model;
	$model=$self->{MODEL}{indications}{lc($classname)} if defined $self->{MODEL}{indications}{lc($classname)};
	$model=$self->{MODEL}{associations}{lc($classname)} if defined $self->{MODEL}{associations}{lc($classname)};
	$model=$self->{MODEL}{classes}{lc($classname)} if defined $self->{MODEL}{classes}{lc($classname)};
	if(!defined $model) {
		if(defined $self->GetClass) {
			my $class=$self->GetClass($classname);
			if(defined $class && $class->{name} eq lc($args{tag})) {
				if($class->{qualifiers}{association}{value} eq 'true') {
					$self->{MODEL}{associations}{lc($class->{name})}=$class;
				}
				elsif($class->{qualifiers}{indication}{value} eq 'true') {
					$self->{MODEL}{indications}{lc($class->{name})}=$class;
				}
				else {
					$self->{MODEL}{classes}{lc($class->{name})}=$class;
				}
				$model=$class;
			}
		}
	}
	# If we don't have a real model, make up one that will work...
	if(!defined $model) {
		$faking=1;
		my $lcm=lc($args{method});
		$model = {
			name=>$classname,
			methods=>{
				$lcm=>{
					type=>'string',
					name=>$args{method},
					parameters=>{}
				}
			}
		};
		foreach my $param (keys %{$args{params}}) {
			$model->{methods}{$lcm}{parameters}{lc($param)}{type}='string';
			$model->{methods}{$lcm}{parameters}{lc($param)}{name}=$param;
			if(ref($args{params}->{$param}) eq 'ARRAY') {
				$model->{methods}{$lcm}{parameters}{lc($param)}{array}='';
			}
		}
	}

	my $body=$self->_params_to_XML($model, $args{method}, $args{params});
	return unless defined $body;

	my $xmlstr=$wsman->invoke(epr=>$epr, method=>$args{method}, body=>$body);
	if(!defined $xmlstr) {
		return;
	}
	my $xml=$self->{TWIG}->parse($xmlstr);
	return if(!defined $xml);
	if($self->_checkfault($xml->root)) {
		return;
	}

	my $outparams;
	for($outparams=$xml->root->first_child('s:Body')->first_child; defined $outparams; $outparams=$outparams->next_sibling) {
		if($outparams->local_name eq "$args{method}\_OUTPUT") {
			if($outparams->namespace eq $epr->{ResourceURI}) {
				last;
			}
		}
	}
	if(!defined $outparams) {
		carp("Unable to locate output parameters in response");
		return;
	}
	my $ret={};
	for(my $out=$outparams->first_child; defined $out; $out=$out->next_sibling) {
		next if($out->tag eq '#PCDATA');
		my $outparam=$out->local_name;
		my $paramdef;
		if($outparam eq 'ReturnValue') {
			$paramdef=$model->{methods}{lc($args{method})};
		}
		else {
			if($faking) {
				$model->{methods}{lc($args{method})}{parameters}{lc($outparam)}={
					type=>'string',
				};
			}
			$paramdef=$model->{methods}{lc($args{method})}{parameters}{lc($outparam)};
			if(!defined $paramdef) {
				carp("Included output parameter $outparam is not defined in the mode;");
				return;
			}
		}
		my ($value,$type)=$self->_stringify($out,$paramdef);
		# Special uint8[] octetString handling here.
		if(defined $type && $type eq 'bytes') {
			my @bytes=split(//,$value);
			$ret->{$outparam}=[@bytes];
		}
		else {
			if(defined $type) {
				if($faking) {
					$paramdef->{type}=$type;
				}
				if($type ne $paramdef->{type}) {
					carp("Type mismatch in value of $outparam ($value) $type ne $paramdef->{type}");
					return;
				}
			}
			if($faking) {
				if(defined $ret->{outparam}) {
					$paramdef->{array}='';
					$ret->{$outparam} = [$ret->{$outparam}];
				}
			}
			if(defined $paramdef->{array}) {
				$ret->{$outparam} = [] unless defined $ret->{$outparam};
				push @{$ret->{$outparam}},$value;
			}
			else {
				$ret->{$outparam}=$value;
			}
		}
	}

	return $ret;
}

#####################
# Utility functions #
#####################
sub current_wsman
{
	my $self=shift;

	my $uri=$self->current_uri;
	if(!defined $uri) {
		return;
	}

	if(!defined $uri->host) {
		carp("No host in uri");
		return;
	}

	if(!defined $uri->port) {
		carp("No port in uri");
		return;
	}

	if(!defined $self->{AUTHORITIES}{$uri->host_port}) {
		my %connect_args;
		if(!defined $uri->userinfo) {
			carp("No user info specified for uri");
			return;
		}
		if($uri->scheme =~ /s$/) {
			$connect_args{protocol}='https';
		}
		else {
			$connect_args{protocol}='http';
		}
		if($uri->userinfo =~ /^([^:]*):([^@]*)$/) {
			my ($user,$pass)=($1,$2);
			$connect_args{user}=uri_unescape($user);
			$connect_args{pass}=uri_unescape($pass);
		}
		else {
			carp("Missing password in URI");
			return;
		}
		$connect_args{port}=$uri->port;
		$connect_args{host}=$uri->host;
		$self->{AUTHORITIES}{$uri->host_port}={userinfo=>$uri->userinfo};
		$self->{AUTHORITIES}{$uri->host_port}->{Session}=DMTF::WSMan->new(%connect_args);
	}

	return($self->{AUTHORITIES}{$uri->host_port}->{Session});
}

sub current_uri
{
	my $self=shift;
	my $URI=shift;

	if(!defined $URI) {
		return $self->{CURRENTURI};
	}

	my $newuri=URI->new($URI);
	$self->{CURRENTURI}->scheme($newuri->scheme) if(defined $newuri->scheme);
	if(defined $newuri->authority) {
		$self->{CURRENTURI}->host_port($newuri->host_port) if(defined $newuri->host_port);
		if(defined $newuri->userinfo) {
			my $newinfo=$newuri->userinfo;
			my $oldinfo=$self->{CURRENTURI}->userinfo;
			if($newinfo =~ /^[^:]*:[^@]*$/) {
				$self->{CURRENTURI}->userinfo($newinfo);
			}
			elsif($oldinfo =~ /^[^:]*:([^@]*)$/) {
				$self->{CURRENTURI}->userinfo("$newinfo:$1");
			}
			else {
				$self->{CURRENTURI}->userinfo($newinfo);
			}
		}
		elsif(defined $self->{AUTHORITIES}{$self->{CURRENTURI}->host_port}{userinfo}) {
			$self->{CURRENTURI}->userinfo($self->{AUTHORITIES}{$self->{CURRENTURI}->host_port}{userinfo});
		}
	}
	my ($cnamespace);
	if($self->{CURRENTURI}->path =~ /^(?:\/([^:]*?))?(?::.*)?$/) {
		$cnamespace=$1;
	}
	my ($namespace, $instance, $path);
	if(defined $newuri->path) {
		if(ref($newuri) eq 'URI::_generic') {
			$path=$newuri;
		}
		else {
			$path=$newuri->path;
		}
	}
	if(defined $path) {
		if($path =~ /^\/([^:]*)$/) {	# Starts with a slash, has no colon
			# no class
			$namespace=$1;
		}
		elsif($path =~ /^([^\/].*)$/) { # Doesn't start with a slash
			# no namespace
			$instance=$1;
		}
		elsif($path =~ /^\/([^:]*):(.*)$/) { # Starts with a slash, has colon
			($namespace, $instance)=($1,$2);
		}
		else {
			carp("Impossible path in new URI");
			return;
		}
	}
	$namespace = $cnamespace unless defined $namespace;
	if(defined $instance) {
		$instance=":$instance";
	}
	else {
		$instance='';
	}
	$self->{CURRENTURI}->path("$namespace$instance");
	if($self->{CURRENTURI}->scheme !~ /^(http|wsman\.wbem)s?$/) {
		carp("Unsupported scheme: ".$self->{CURRENTURI}->scheme);
		return;
	}
	return $self->{CURRENTURI};
}

sub current_epr
{
	my $self=shift;
	return $self->URItoEPR($self->current_uri);
}

sub URItoEPR
{
	my $self=shift;
	my $uri=shift;
	my %ret;

	my $scheme=$uri->scheme;
	my $path=$uri->path;
	if($path =~ /^\/(.*?):(.*?)(?:\.(.*))?$/) {
		my ($namespace,$class,$keys)=($1,$2,$3);
		if($class eq '*') {
			$ret{ResourceURI}='http://schemas.dmtf.org/wbem/wscim/1/*';
		}
		else {
			$ret{ResourceURI}="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/$class";
		}
		if(defined $namespace && $namespace ne '') {
			$ret{SelectorSet}{__cimnamespace}=$namespace;
		}
		if(defined $keys && $keys ne '') {
			my @splitkeys=split(/,/,$keys);
			my @keys;
			foreach my $key (@splitkeys) {
				$key=uri_unescape($key);
				if($#keys >= 0) {
					my $last=substr($keys[$#keys], -1);
					if($last eq '"') {
						$last = '' if(substr($keys[$#keys], -2) eq '\"');
					}
					if($last ne '"') {
						$keys[$#keys] .= ",$key";
						next;
					}
				}
				push(@keys,$key);
			}
			foreach my $key (@keys) {
				if($key =~ /^(.*?)="(.*)"$/) {
					my ($key,$value)=($1,$2);
					$value =~ s/\\([\\"])/$1/g;
					if($value =~ m|^wsman.wbems?://[^/]+/[^:]+:[^\.]+\..+|) {
						my $uri=URI->new($value);
						$value=$self->URItoEPR($uri);
					}
					$ret{SelectorSet}{$key}=$value;
				}
			}
		}
	}
	else {
		carp "Unable to extract namespace and class from $path";
		return;
	}
	return {%ret};
}

sub quirks
{
	my $self=shift;
	my $name=shift;
	my $value=shift;

	return sort keys %{$self->{QUIRKS}} unless defined $name;
	return $self->{QUIRKS}{$name} unless defined $value;
	$self->{QUIRKS}{$name}=$value;
}

#####################
# Private Functions #
#####################
sub _get_instances
{
	my $self=shift;
	my $type=shift;
	my $mode=shift;
	my %args=@_;
	if($type eq 'class') {
		$args{uri}=$args{EnumClassPath} if(defined $args{EnumClassPath});
	}
	else {
		$args{uri}=$args{SourceInstancePath} if(defined $args{SourceInstancePath});
	}
	$args{ico}=$args{IncludeClassOrigin} if(defined $args{IncludeClassOrigin});
	$args{ico}=0 if(!defined $args{ico});
	$args{iq}=$args{IncludeQualifiers} if(defined $args{IncludeQualifiers});
	$args{iq}=0 if(!defined $args{iq});
	$args{props}=$args{IncludedProperties} if(defined $args{IncludedProperties});
	$args{via}=$args{AssociationClassName} if(defined $args{AssociationClassName});
	$args{class}=$args{AssociatedClassName} if(defined $args{AssociatedClassName});
	$args{role}=$args{SourceRoleName} if(defined $args{SourceRoleName});
	$args{rrole}=$args{AssociatedRoleName} if(defined $args{AssociatedRoleName});
	$args{esp}=$args{ExcludeSubclassProperties} if(defined $args{ExcludeSubclassProperties});

	if($args{ico}) {
		carp("WS-Management does not implement IncludeClassOrigin support");
		return;
	}
	if($args{iq}) {
		carp("WS-Management does not implement IncludeQualifiers support");
		return;
	}

	my $enum_mode;
	if($mode eq 'paths') {
		$enum_mode='EnumerateEPR';
	}
	else {
		$enum_mode='EnumerateObjectAndEPR';
	}

	$self->current_uri($args{uri});
	my $epr=$self->current_epr;
	my $wsman=$self->current_wsman;
	if(!defined $epr || !defined $wsman) {
		return;
	}

	my $filterstr='';

	my $target_epr;
	if($type eq 'class') {
		$target_epr=$self->current_epr;
	}
	else {
		my $filteroptions='';
		if(defined $args{class}) {
			$filteroptions.="<$wsman->{Context}{xmlns}{cim}{prefix}:ResultClassName>$args{class}</$wsman->{Context}{xmlns}{cim}{prefix}:ResultClassName>";
		}
		if(defined $args{role}) {
			$filteroptions.="<$wsman->{Context}{xmlns}{cim}{prefix}:Role>$args{role}</$wsman->{Context}{xmlns}{cim}{prefix}:Role>";
		}
		if(defined $args{props}) {
			if(ref($args{props})=='ARRAY') {
				foreach my $prop (@{$args{props}}) {
					$filteroptions.="<$wsman->{Context}{xmlns}{cim}{prefix}:IncludeResultProperty>$args{role}</$wsman->{Context}{xmlns}{cim}{prefix}:IncludeResultProperty>";
				}
			}
		}
		if($type eq 'associated') {
			if(defined $args{via}) {
				$filteroptions.="<$wsman->{Context}{xmlns}{cim}{prefix}:AssociationClassName>$args{via}</$wsman->{Context}{xmlns}{cim}{prefix}:AssociationClassName>";
			}
			if(defined $args{rrole}) {
				$filteroptions.="<$wsman->{Context}{xmlns}{cim}{prefix}:ResultRole>$args{role}</$wsman->{Context}{xmlns}{cim}{prefix}:ResultRole>";
			}
			$filterstr=$self->_associationFilter($wsman,'AssociatedInstances',$epr,$filteroptions);
		}
		else {
			$filterstr=$self->_associationFilter($wsman,'AssociationInstances',$epr,$filteroptions);
		}
		my $curi=URI->new($self->current_uri);
		my $cpath=$curi->path;
		$cpath =~ s/:.*$//;
		$cpath .= ':*';
		$curi->path($cpath);
		$target_epr=$self->URItoEPR($curi);
	}

	# TODO: We need to perform additional filtering on the arguments since WS-Management doesn't support them all.
	my $rawxml=$wsman->enumerate(epr=>$target_epr, mode=>$enum_mode, filter=>$filterstr);
	$rawxml=~s/<\?\s*xml.*?\?>[^<]*//;
	my $xml=$self->{TWIG}->parse('<allreplies>'.$rawxml.'</allreplies>');
	if(!defined $xml) {
		carp("Error parsing XML");
		return;
	}
	my $ret=[];
	for(my $reply=$xml->root->first_child('s:Envelope');defined $reply;$reply=$reply->next_sibling) {
		next if (!defined $reply->first_child('s:Body'));
		if($self->_checkfault($reply)) {
			return;
		}
		my $response=$reply->first_child('s:Body')->first_child('n:EnumerateResponse');
		my $items;
		$items=$response->first_child('w:Items') if(defined $response);
		if(!defined $response) {
			$response=$reply->first_child('s:Body')->first_child('n:PullResponse');
			$items=$response->first_child('n:Items') if(defined $response);
		}
		if(!defined $response) {
			carp('Unable to locate response object on response');
			return;
		}
		if(!defined $items) {
			next if($response->local_name eq 'EnumerateResponse');	# The EnumerateResponse may not have an Items in it.
			return @{$ret};
		}
		for(my $item=$items->first_child;defined $item;$item=$item->next_sibling) {
			next if($item->tag eq '#PCDATA');
			if($mode eq 'paths') {
				my $pi=$self->_parse_reference($item);
				push @{$ret},$pi if(defined $pi);
			}
			else {
				my $object;
				for($object=$item->first_child; defined $object;$object=$object->next_sibling) {
					next if($object->tag eq '#PCDATA');
					last;
				}
				if(!defined $object) {
					carp('Item returned with no object');
					return;
				}
				my $obj=$self->_parse_instance($object);
				return if(!defined $obj);
				my $epr=$item->first_child('a:EndpointReference');
				if(!defined $epr) {
					carp('Item returned with no EPR');
					return;
				}
				$obj->uri($self->_parse_reference($epr));
				push @{$ret},$obj;
			}
		}
	}
	return @{$ret};
}

sub _XML_escape
{
	my $val=shift;
	$val=~s/&/&amp;/g;
	$val=~s/</&lt;/g;
	$val=~s/"/&quot;/g;
	$val=~s/'/&apos;/g;
	return $val;
}

sub _instance_to_XML
{
	my $self=shift;
	my $obj=shift;
	my $ret='';
	my $class=$obj->class;
	my $wsman=$self->current_wsman;

	$ret.="<p:$class xmlns:p=\"http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/$class\">";
	foreach my $prop (sort { $a->name cmp $b->name } $obj->defined_properties) {
		my $val;
		if($prop->is_array) {
			$val=[$prop->value];
		}
		else {
			$val=$prop->value;
		}
		my $octetstring=$prop->qualifier('octetstring');
		if(defined $octetstring
				&& $octetstring eq 'true'
				&& $prop->type =~ /(uint8|string)\[\]/) {
			if($1 eq 'string') {
				if(ref($val) eq 'ARRAY') {
					foreach my $value (@$val) {
						my $v=uc(unpack("H*",$value));
						$v = sprintf('0x%08X%s',((length($v)/2)+4),$v) if($self->{QUIRKS}{incorrect_string_octetstring});
						$ret .= "<p:".($prop->name).">$v</p:".($prop->name).">";
					}
				}
				else {
					if($self->{QUIRKS}{incorrect_string_octetstring}) {
						$val = sprintf('0x%08X%s',(length($val)+4),uc(unpack("H*",$val)));
					}
					else {
						$val = uc(unpack("H*",$val));
					}
					$ret .= "<p:".($prop->name).">".$val."</p:".($prop->name).">";
				}
			}
			else {
				my $decoded;
				if(ref($val) eq 'ARRAY') {
					$decoded=join('',@{$val});
				}
				else {
					$decoded=$val;
				}
				$ret .= "<p:".($prop->name).">".encode_base64($decoded)."</p:".($prop->name).">";
			}
		}
		elsif(ref($val) eq 'ARRAY') {
			foreach my $value (@$val) {
				if($prop->is_ref) {
					$value=$wsman->epr_to_xml($self->URItoEPR(URI->new($value)));
				}
				elsif($prop->type eq 'datetime') {
					$value="<$wsman->{Context}{cim}{prefix}:CIM_DateTime>$value</$wsman->{Context}{cim}{prefix}:CIM_DateTime>";
				}
				$ret .= "<p:".($prop->name).">"._XML_escape($value)."</p:".($prop->name).">";
			}
		}
		else {
			if($prop->is_ref) {
				$val=$wsman->epr_to_xml($self->URItoEPR(URI->new($val)));
			}
			elsif($prop->type eq 'datetime') {
				$val="<$wsman->{Context}{cim}{prefix}:CIM_DateTime>$val</$wsman->{Context}{cim}{prefix}:CIM_DateTime>";
			}
			$ret .= "<p:".($prop->name).">"._XML_escape($val)."</p:".($prop->name).">";
		}
	}
	$ret.="</p:$class>";
}

sub _params_to_XML
{
	my $self=shift;
	my $class=shift;	# A class definition from the model
	my $method=shift;
	my $lcm=lc($method);
	my $params=shift;	# Hashref containg scalars and arrayrefs
	my $ret='';
	my $wsman=$self->current_wsman;

	$ret.="<p:$method\_INPUT xmlns:p=\"http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/$class->{name}\">";
	foreach my $param (sort keys %{$params}) {
		my $paramdef=$class->{methods}{$lcm}{parameters}{lc($param)};
		if(!defined $paramdef) {
			carp("Undefined parameter $param passed to $method method of $class->{name}");
			return;
		}
		if(!defined $paramdef->{type}) {
			carp("Unknown type for parameter $paramdef->{name} passed to $method of $class->{name}");
			return;
		}

		my $val=$params->{$param};

		if(ref($val) eq 'ARRAY') {
			foreach my $value (@$val) {
				if($paramdef->{type} eq 'ref') {
					$value=$wsman->epr_to_xml($self->URItoEPR(URI->new($value)));
				}
				elsif($paramdef->{type} eq 'datetime') {
					$value="<$wsman->{Context}{cim}{prefix}:CIM_DateTime>$value</$wsman->{Context}{cim}{prefix}:CIM_DateTime>";
				}
				$ret .= "<p:$paramdef->{name}>$value</p:$paramdef->{name}>";
			}
		}
		else {
			if($paramdef->{type} eq 'ref') {
				$val=$wsman->epr_to_xml($self->URItoEPR(URI->new($val)));
			}
			elsif($paramdef->{type} eq 'datetime') {
				$val="<$wsman->{Context}{cim}{prefix}:CIM_DateTime>$val</$wsman->{Context}{cim}{prefix}:CIM_DateTime>";
			}
			$ret .= "<p:$paramdef->{name}>$val</p:$paramdef->{name}>";
		}
	}
	$ret.="</p:$method\_INPUT>";
}

sub _associationFilter
{
	my $self=shift;
	my $wsman=shift;
	my $filtertag=shift;
	my $epr=shift;
	my $options=shift;
	$options='' if(!defined $options);

	my $selectorset=$wsman->get_selectorset_xml($epr);
	my $eprxml=$wsman->epr_to_xml($epr);
	# Some implementations incorrectly assume the Object tag in the
	# association filter is an EPR so the children would be Address and
	# ReferenceParameters directly instead of it *containg* an EPR which
	# would have the first child be an EndpointReference
	if($self->{QUIRKS}{association_object_wrong}) {
		$eprxml =~ s/^\s*<(?:[^:]*:)?EndpointReference(?:\s.*)?>(.*)<\/(?:[^:]*:)?EndpointReference(?:\s*)>\s*$/$1/s;
	}

	return <<EOF
<$wsman->{Context}{xmlns}{wsman}{prefix}:Filter Dialect="http://schemas.dmtf.org/wbem/wsman/1/cimbinding/associationFilter">
	<$wsman->{Context}{xmlns}{cim}{prefix}:$filtertag>
		<$wsman->{Context}{xmlns}{cim}{prefix}:Object>
EOF
	.$eprxml.<<EOF;
		</$wsman->{Context}{xmlns}{cim}{prefix}:Object>
		$options
	</$wsman->{Context}{xmlns}{cim}{prefix}:$filtertag>
</$wsman->{Context}{xmlns}{wsman}{prefix}:Filter>
EOF
}

sub _stringify
{
	my $self=shift;
	my $twig=shift;
	my $model=shift;
	my $child;

	my $isnull=$twig->att('x:nil');
	if(defined $isnull) {
		if($isnull eq 'true' || $isnull eq '1') {
			return;
		}
		elsif($isnull ne 'false' && $isnull ne '0') {
			carp("Invalid xsi:nil value of $isnull");
		}
	}
	for($child=$twig->first_child; defined $child;$child=$child->next_sibling) {
		next if($child->tag eq '#PCDATA');
		last;
	}
	if(defined $child) {
		my $type=$child->tag;
		if($type eq 'a:EndpointReference') {
			my $ref=$self->_parse_reference($child);
			return wantarray ? ($self->_parse_reference($child),'ref') : $ref;
		}
		elsif($type eq 'a:Address' || $type eq 'a:ReferenceParameters') {
			my $ref=$self->_parse_reference($twig);
			return wantarray ? ($self->_parse_reference($twig),'ref') : $ref;
		}
		elsif($type eq 'c:CIM_DateTime') {
			return wantarray ? ($child->text,'datetime') : $child->text;
		}
		elsif($type eq 'c:Interval') {
			my $val=$child->text;
			$val =~ s/^\s*(.*?)\s*$/$1/;
			if($val =~ /^(-?)P(?:([0-9]+)Y)?(?:([0-9]+)M)?(?:([0-9]+)D)?(?:T(?:([0-9]+)H)?(?:([0-9]+)M)?(?:([0-9]+)(.[0-9]+)?S)?)?$/) {
				my ($neg,$y,$m,$d,$h,$min,$s,$fs)=($1,$2,$3,$4,$5,$6,$7,$8);
				$y=0 unless defined $y;
				$m=0 unless defined $m;
				$d=0 unless defined $d;
				$h=0 unless defined $h;
				$min=0 unless defined $min;
				$s=0 unless defined $s;
				$fs=0 unless defined $fs;
				$fs=substr(sprintf("%0.6f",$fs),1);
				if(defined $neg && $neg eq '-') {
					$y=0-$y;
					$m=0-$m;
					$d=0-$d;
					$h=0-$h;
					$min=0-$min;
					$s=0-$s;
				}
				my $duration=DateTime::Duration->new(
					years=>$y,
					months=>$m,
					days=>$d,
					hours=>$h,
					minutes=>$min,
					seconds=>$s,
				);
				my($dd,$dh,$dm,$ds)=$duration->in_units('days','hours','minutes','seconds');
				my $int=sprintf("%08d%02d%02d%02d%s",$dd,$dh,$dm,$ds,$fs);
				return wantarray ? ($int,'datetime') : $int;
			}
			else {
				carp("Unrecognized interval representation $val");
				return;
			}
		}
		elsif($type eq 'c:Date') {
			my $val=$child->text;
			$val =~ s/^\s*(.*?)\s*$/$1/;
			if($val =~ /^(-?[0-9]{4,})-([0-9]{2})-([0-9]{2})(Z|(?:[-+][0-9]{2}:[0-9]{2}))?$/) {
				my ($y,$m,$d,$tz)=($1,$2,$3,$4);
				if($y < 0) {
					carp("CIM cannot model dates BC ($val)");
					return;
				}
				$tz="+00:00" if $tz eq 'Z';
				if($tz=~/^([-+])([0-9]{2}):([0-9]{2})$/) {
					my ($sign,$hour,$min)=($1,$2,$3);
					$tz=$hour*60+$min;
					$tz=0-$tz if $sign eq '-';
					my $dt=sprintf("%04d%02d%02d******.******%+02d",$y,$m,$d,$tz);
					return wantarray ? ($dt,'datetime') : $dt;
				}
				else {
					carp("Unrecognized timezone $tz");
					return;
				}
			}
			else {
				carp("Unrecognized date representation $val");
				return;
			}
		}
		elsif($type eq 'c:Time') {
			my $val=$child->text;
			$val =~ s/^\s*(.*?)\s*$/$1/;
			if($val =~ /^([0-9]{2}):([0-9]{2}):([0-9]{2})(\.[0-9]+)?(Z|(?:[-+][0-9]{2}:[0-9]{2}))?$/) {
				my ($h,$m,$s,$fs,$tz)=($1,$2,$3,$4,$5);
				$fs=0 unless defined $fs;
				$fs=substr(sprintf("%0.6f",$fs),1);
				$tz="+00:00" if $tz eq 'Z';
				if($tz=~/^([-+])([0-9]{2}):([0-9]{2})$/) {
					my ($sign,$hour,$min)=($1,$2,$3);
					$tz=$hour*60+$min;
					$tz=0-$tz if $sign eq '-';
					my $dt=sprintf("********%02d%02d%02d%s%+02d",$h,$m,$s,$fs,$tz);
					return wantarray ? ($dt,'datetime') : $dt;
				}
				else {
					carp("Unrecognized timezone $tz");
					return;
				}
			}
			else {
				carp("Unrecognized date representation $val");
				return;
			}
		}
		elsif($type eq 'c:Datetime') {
			my $val=$child->text;
			$val =~ s/^\s*(.*?)\s*$/$1/;
			if($val =~ /^(-?[0-9]{4,})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})(\.[0-9]+)?(Z|(?:[-+][0-9]{2}:[0-9]{2}))?$/) {
				my ($y,$m,$d,$h,$min,$s,$fs,$tz)=($1,$2,$3,$4,$5,$6,$7,$8);
				if($y < 0) {
					carp("CIM cannot model dates BC ($val)");
					return;
				}
				$fs=0 unless defined $fs;
				$fs=substr(sprintf("%0.6f",$fs),1);
				$tz="+00:00" if $tz eq 'Z';
				if($tz=~/^([-+])([0-9]{2}):([0-9]{2})$/) {
					my ($sign,$hour,$min)=($1,$2,$3);
					$tz=$hour*60+$min;
					$tz=0-$tz if $sign eq '-';
					my $dt=sprintf("%04d%02d%02d%02d%02d%02d%s%+02d",$y,$m,$d,$h,$min,$s,$fs,$tz);
					return wantarray ? ($dt,'datetime') : $dt;
				}
				else {
					carp("Unrecognized timezone $tz");
					return;
				}
			}
			else {
				carp("Unrecognized date representation $val");
				return;
			}
		}
		else {
			carp("Unhandled data type $type in EPR Selector");
			return;
		}
	}
	else {
		if(defined $model
				&& defined $model->{qualifiers}
				&& defined $model->{qualifiers}{octetstring}
				&& $model->{qualifiers}{octetstring} eq 'true') {
			if(defined $model->{type}
					&& $model->{type} eq 'uint8'
					&& defined $model->{array}) {
				my $decoded=decode_base64($twig->text);
				return wantarray ? ($decoded, 'bytes') : $decoded;
			}
			if(defined $model->{type}
					&& $model->{type} eq 'string'
					&& defined $model->{array}) {
				my $encoded=$twig->text;
				$encoded=~s/([0-9A-Fa-f]{2})/chr(hex($1))/eg;
				if($self->{QUIRKS}{incorrect_string_octetstring}) {
					$encoded =~ s/^0x[0-9a-fA-F]{8}//;
				}
				return $encoded;
			}
		}
		return $twig->text;
	}
}

sub _parse_reference
{
	my $self=shift;
	my $reference=shift;
	my $ns='interop';
	my $authority;
	my $scheme='wsman.wbem';
	my $path;
	my $class;

	my $rp=$reference->first_child('a:ReferenceParameters');
	if(!defined $rp) {
		carp("No reference parameters in EPR");
		return;
	}
	my $ruri=$rp->first_child('w:ResourceURI')->text;
	if(!defined $ruri) {
		carp("Unable to locate ResourceURI in EPR");
		return;
	}
	if($ruri=~/^.*\/([^\/]+)$/) {
		$class=$1;
	}
	if(!defined $class) {
		carp("Unable to parse class from uri $ruri");
	}
	$self->class_tag_alias($class, lc($class));
	my $ss=$reference->first_child('a:ReferenceParameters')->first_child('w:SelectorSet');
	if(defined $ss) {
		my %vals;
		for(my $sel=$ss->first_child('w:Selector');defined $sel;$sel=$sel->next_sibling('w:Selector')) {
			my $name=$sel->att('Name');
			if(!defined $name) {
				carp("Missing selector name in EPR");
				return;
			}
			if($name eq '__cimnamespace') {
				$ns=$sel->text;
			}
			else {
				$vals{$name}=$self->_stringify($sel);
			}
		}
		foreach my $val (sort keys %vals) {
			if(defined $path) {
				$path .= ',';
			}
			else {
				$path .= '.';
			}
			$path .= uri_escape("$val=","?#");
			my $eq=$vals{$val};
			$eq =~ s/\\/\\\\/g;
			$eq =~ s/"/\\"/g;
			$path .= uri_escape("\"$eq\"","?#");
		}
	}
	$path='' unless defined $path;
	$path="$class$path";
	$ns =~ s/^[\/]*(.*?)[\/]*$/$1/;
	$path="$ns:$path";
	my $addr=$reference->first_child('a:Address');
	if(defined $addr && $addr->text ne 'http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous') {
		my $auri=URI->new($addr->text);
		$scheme=$auri->scheme if defined $auri->scheme;
		$scheme=~s/^http(s?)$/wsman.wbem$1/;
		$authority=$auri->authority if defined $auri->authority;
	}
	if(defined $authority) {
		return "$scheme://$authority/$path";
	}
	return "/$path";
}

sub _parse_instance
{
	my $self=shift;
	my $instance=shift;
	my $ret={
		VALUES=>{},
		DATA=>{
			properties=>{},
			references=>{},
		},
	};

	my $ns=$instance->namespace;
	if($ns =~ m|^http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/(.*)$|) {
		$ret->{DATA}{name}=$1;
	}
	my $ci;
	{
		local $SIG{__WARN__}=sub {};
		$ci=$self->instance_of($ret->{DATA}{name});
	}
	for(my $tag=$instance->first_child();defined $tag;$tag=$tag->next_sibling) {
		next if($tag->namespace ne $ns);
		my $prop=$tag->local_name;
		my $propref=$ret->{DATA}{properties}{lc($prop)};
		if(defined $ret->{DATA}{references}{lc($prop)}) {
			if(defined $propref) {
				delete $ret->{DATA}{properties}{lc($prop)};
			}
			$propref=$ret->{DATA}{references}{lc($prop)};
		}
		if(!defined $propref) {
			$ret->{DATA}{properties}{lc($prop)}={};
			$propref=$ret->{DATA}{properties}{lc($prop)};
		}

		if(!defined $ci) {
			if(!defined $propref->{name}) {
				$propref->{name}=$prop;
			}
		}
		if(defined $ret->{VALUES}{$prop}) {
			if(ref($ret->{VALUES}{$prop}) ne 'ARRAY') {
				$propref->{array}='';
				$ret->{VALUES}{$prop}=[$ret->{VALUES}{$prop}];
			}
		}
		elsif(defined $ci) {
			if($ci->property($prop)->is_array) {
				$ret->{VALUES}{$prop}=[];
			}
		}
		my ($value,$type)=$self->_stringify($tag,$propref);
		# Special uint8[] octetString handling here.
		if(defined $type && $type eq 'bytes') {
			my @bytes=split(//,$value);
			$ret->{VALUES}{$prop}=[@bytes];
			$propref->{type}='uint8' unless defined $propref->{type};
			$propref->{array}='' unless defined $propref->{array};
		}
		else {
			if(defined $type) {
				if($type eq 'ref') {
					if(!defined $ci) {
						$ret->{DATA}{qualifiers}{association}{value}='true';
						if(defined $ret->{DATA}{properties}{lc($prop)}) {
							$ret->{DATA}{references}{lc($prop)}={%$propref};
							$propref=$ret->{DATA}{references}{lc($prop)};
							delete $ret->{DATA}{properties}{lc($prop)};
						}
						$propref->{DATA}{references}{lc($prop)}{is_ref}='true';
					}
				}
				$propref->{type}=$type;
			}
			if(ref($ret->{VALUES}{$prop}) eq 'ARRAY') {
				push @{$ret->{VALUES}{$prop}},$value;
			}
			else {
				$ret->{VALUES}{$prop}=$value;
			}
		}
	}

	my $retval;
	if(defined $ci) {
		$retval=DMTF::CIM::Instance->new(parent=>$self, class=>$ci->{DATA}, values=>$ret->{VALUES});
	}
	else {
		$retval=DMTF::CIM::Instance->new(parent=>$self, class=>$ret->{DATA}, values=>$ret->{VALUES});
	}
	return $retval;
}

sub _checkfault
{
	my $self=shift;
	my $xml=shift;

	my $fault=$xml->first_child('s:Body')->first_child('s:Fault');
	if(defined $fault) {
		my $value;
		my $sc_val;
		my $code=$fault->first_child('s:Code');

		if(defined $code) {
			$value=$code->first_child('s:Value')->text;
			if(defined $code->first_child('s:Subcode')
					&& defined $code->first_child('s:Subcode')->first_child('s:Value')) {
				$sc_val=$code->first_child('s:Subcode')->first_child('s:Value')->text;
			}
		}
		my $reason=$fault->first_child('s:Reason')->first_child('s:Text')->text;
		my $detail;
		if(defined $fault->first_child('s:Detail')
				&& defined $fault->first_child('s:Detail')->first_child('w:FaultDetail')) {
			$detail=$fault->first_child('s:Detail')->first_child('w:FaultDetail')->text;
		}

		my $errstr=$value;
		$errstr .= ' (' if(defined $sc_val && $sc_val ne '' && defined $errstr && $errstr ne '');
		$errstr .= "$sc_val" if(defined $sc_val && $sc_val ne '');
		$errstr .= ') ' if(defined $sc_val && $sc_val ne '' && defined $value && $value ne '');
		$errstr .= "\n" if(defined $reason && $reason ne '' && defined $errstr && $errstr ne '');
		$errstr .= "$reason " if(defined $reason && $reason ne '');
		$errstr .= "\n($detail)" if(defined $detail && $detail ne '');
		carp "Fault encountered: $errstr\n";
		return 1;
	}
	return 0;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

DMTF::CIM::WSMan - Provides WSMan CIM binding


=head1 VERSION

This document describes DMTF::CIM::WSMan version 0.09


=head1 SYNOPSIS

  use DMTF::CIM::WSMan;

  my $wsman=DMTF::CIM::WSMan->new();
  $wsman->current_uri( 'wsman.wbem://admin:secret@example.com/interop' );
  my @rps=$wsman->class_uris( '/interop:CIM_RegisteredProfile' );


=head1 DESCRIPTION

This module extends the L<DMTF::CIM> class with L<DMTF::WSMan> mapping and binding.
This implements the generic operations documented for L<DMTF::CIM>.

=head1 INTERFACE 

Refer to L<DMTF::CIM> for the generic operation documentation.

=head2 ADDITIONAL METHODS

=over

=item C<< current_uri( [I<new_uri>] ) >>

Gets or sets the current untyped WBEM URI for resource access.  Supported
schemes are 'wsman.wbem', 'wsman.wbems', 'http', and 'https'.  This is the
preferred way to establish a connection with a specific host using specific
credentials (ie: C<< $wsm->current_uri( 'wsman.wbem://user:pass@example.com:623/' >> )

=item C<< current_wsman >>

Returns the L<DMTF::WSMan> object associated with the current URI

=item C<< current_epr >>

Returns the current EPR object derived from the current URI.

=item C<< URItoEPR( I<uri> ) >>

Converts the L<URI> object into an EPR object for L<DMTF::WSMan>.

=item C<< quirks( [I<name> [,I<value>] ) >>

Lists, reads, or sets quirks.  If neither I<name> or I<value> are specified,
returns a list of all known quirks.  If only name is passed, returns the
value of the named quirk.  If both name and value are passed, sets the
named quirk to I<value>.  Refer to INCOMPATIBILITIES for a list of
quirks.

=back

=head1 DIAGNOSTICS

This class carp()s and returns undef (or empty list) on all errors.


=head1 CONFIGURATION AND ENVIRONMENT

DMTF::CIM::WSMan requires no configuration files or environment variables.


=head1 DEPENDENCIES

=over

=item L<DMTF::WSMan> (available from the same location as this module)

=item L<DMTF::CIM> (available from the same location as this module)

=item L<URI> (available from CPAN)

=item L<URI::Escape> (available from CPAN)

=item L<XML::Twig> (available from CPAN)

=item L<DateTime> (available from CPAN)

=back

=head1 INCOMPATIBILITIES

The Broadcom TruManage implementations 1.52.0.4 and older do not support
the corrected String[] octet string representation and require the
incorrect_string_octetstring quirk to be set to true using
$ws->quirk('incorrect_string_octetstring', 1);

The Microsoft winrm servers up to at least the 3.0 Beta do not support
an EndpointReference in the Object tag of an association querey and
require the association_object_wrong quirk to be set true using
$ws->quirk('association_object_wrong', 1);

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-dmtf-cim-wsman@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Stephen James Hurd  C<< <shurd@broadcom.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Broadcom Corporation C<< <shurd@broadcom.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
