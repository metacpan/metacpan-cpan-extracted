package Class::MethodVars;
use warnings;
use strict;

use NEXT;

our $VERSION = '1.'.qw $Rev: 133 $[1];

our %Configs; # Needs to be accessible to Class::Framework
my %OptionsMap = (
	'^args'=>'hatargs',
	'hatargs'=>'hatargs',
	'varargs'=>'varargs',
	'^fields'=>'hatfields',
	'hatfields'=>'hatfields',
	'varfields'=>'varfields',
	'^this'=>'hatthis',
	'hatthis'=>'hatthis',
	'varthis'=>'varthis',
	'subthis'=>'subthis',
	'^class'=>'hatclass',
	'hatclass'=>'hatclass',
	'varclass'=>'varclass',
	'subclass'=>'subclass',

	'debug'=>'debug',
);
my %DefaultOptions = (
	hatargs=>1,
	hatfields=>1,
	subthis=>1,
	subclass=>1,
	# No varthis and varclass because that causes an implicit use vars which is bad for a default.
);

sub __DefaultConfigs() {
	return {
		fieldhatprefix=>"",
		fieldvarprefix=>"",
		class=>"__CLASS__",
		this=>"this",
		fields=>[],
		rwfields=>[],
		rofields=>[],
		wofields=>[],
		hiddenfields=>[],
		options=>{ %DefaultOptions }
	};
}

sub import {
	shift; # You should NEVER be @ISA = "Class::MethodVars"
	my $package = caller;
	if ($Configs{$package}) {
		require Carp;
		Carp::croak "Double import into this package!";
	}
	my $Config = $Configs{$package}||=__DefaultConfigs;
	my $cpos = 0;
	while (@_) {
		my $cmd = shift;
		$cpos++;
		if ($cpos == 1 and ref($cmd)) {
			push(@{$Config->{rwfields}},@$cmd);
		} elsif ($cmd eq '-this') {
			$Config->{this} = shift;
		} elsif ($cmd eq '-class') {
			$Config->{class} = shift;
		} elsif ($cpos == 1 and not $cmd=~/^[\+-]/) {
			push(@{$Config->{rwfields}},$cmd);
			while (@_ and not $_[0]=~/^-/) {
				push(@{$Config->{rwfields}},shift);
			}
		} elsif ($cmd eq '-fields' or $cmd eq '-field') {
			if (@_ and ref($_[0])) {
				push(@{$Config->{rwfields}},@{shift()});
			} else {
				while (@_ and not $_[0]=~/^-/) {
					push(@{$Config->{rwfields}},shift);
				}
			}
		} elsif ($cmd =~ /^-(r[wo]|wo|hidden)fields?$/) {
			my $fieldtype = lc $1."fields";
			if (@_ and ref($_[0])) {
				push(@{$Config->{$fieldtype}},@{shift()});
			} else {
				while (@_ and not $_[0]=~/^-/) {
					push(@{$Config->{$fieldtype}},shift);
				}
			}
		} elsif ($cmd eq '-fieldvarprefix') {
			$Config->{fieldvarprefix} = shift;
		} elsif ($cmd eq '-fieldhatprefix') {
			$Config->{fieldhatprefix} = shift;
		} elsif ($cmd=~/^([+-])(.*)$/ and $OptionsMap{$2}) {
			my ($toggle,$option) = ($1,$2);
			if ($toggle eq '-' and @_ and $_[0]=~/^(?:[10]|ON|OFF|TRUE|FALSE)$/i) { # 'it's okay - you would have -fields if expecting field names...
				$toggle = shift;
			}
			$toggle = grep { lc($toggle) eq lc($_) } qw( - 1 ON TRUE );
			$Config->{options}->{$option} = $toggle;
		} else {
			require Carp;
			local $Carp::CarpLevel = 1;
			Carp::croak "I don't know what to do with \"$cmd\"";
		}
	}
	$Config->{fields} = [ Class::MethodVars::_Private::unique(@{$Config->{rwfields}},@{$Config->{rofields}},@{$Config->{wofields}},@{$Config->{hiddenfields}}) ];
	#FIXME: I should probably whine if people use the same field name for a -rofield as a -wofield (for example).
	my @bad_field_names = grep { not /\A\w+\z/ } @{$Config->{fields}};
	if (@bad_field_names) {
		require Carp;
		if (eval { require Lingua::EN::Inflect; 1 }) {
			Carp::croak Lingua::EN::Inflect::inflect("Invalid field PL(name,".@bad_field_names."): ").join(", ",@bad_field_names);
		} else {
			local $" = ", ";
			Carp::croak "Invalid field name(s): @bad_field_names";
		}
	}
	$Config->{allfields} = [ Class::MethodVars::_Private::findBaseFields($package) ]; # This will pull in self and base fields.
	$Config->{options}->{subthis} = 0 if $Config->{this}=~/^\$?_$/;
	$Config->{options}->{subclass} = 0 if $Config->{class}=~/^\$?_$/;
	eval 'unshift @'.$package.'::ISA,q('.__PACKAGE__.'::_ATTRS)';
	eval 'package '.$package.'; sub '.$Config->{this}.'();' if $Config->{options}->{subthis};
	eval 'package '.$package.'; sub '.$Config->{class}.'();' if $Config->{options}->{subclass};
	my @varnames;
	push(@varnames,$Config->{this}) if $Config->{options}->{varthis};
	push(@varnames,$Config->{class}) if $Config->{options}->{varclass};
	push(@varnames,map { $Config->{fieldvarprefix}.$_ } @{$Config->{fields}}) if $Config->{options}->{varfields};
	# Can't do varargs, because I don't know what the args will be in advance!
	eval 'package '.$package.'; use vars qw('.join(" ",map { s{^(?![\%\$\@])}{\$}; $_ } @varnames).');' if @varnames;
	1;
}

sub Method {
	my ($package, $symbol, $referent, $attr, $data, $stage) = @_;
	no warnings 'redefine';
	no strict 'refs';
	if (0 and defined($symbol) and *{$symbol}{NAME} eq 'ANON') {
	#   ^--- DISABLED!
		# Darn, need to find a better symbol. (Probably :Method is not on the first prototype...)
		#XXX: This doesn't work. Even $referent points to the wrong thing :(
		#	Can't figure out true name, can't figure out true reference = can't put Humpty Dumpty back together again :(
		($symbol) = eval 'grep { *{$_}{NAME} ne "ANON" } grep { *{$_}{CODE} and *{$_}{CODE} eq $referent } values %'.$package.'::';
	}
	if (not defined($symbol) or *{$symbol}{NAME} eq 'ANON') {
		require Carp;
		local $Carp::CarpLevel = 3;
		if ($^S) {
			Carp::croak "Unable to identify the name of subroutine at $referent. You appear to be calling this inside an eval. This is a known bug - please \"use\" this module at the start of your application.\n";
		} else {
			Carp::croak "Unable to identify the name of subroutine at $referent. Please ensure :Method is on the first prototype.\n";
		}
		# Don't try and apply the magic to a closure, this attribute is not set up for it.
	}
	my ($self,@args);
	my $Config = $Configs{$package}||__DefaultConfigs;
	$data = "." unless defined $data;
	if (ref $data) {
		($self,@args) = @$data;
	} else {
		($self,@args) = split(/[,\s]+/,$data);
	}
	$self = $Config->{this} if $self eq '.';
	$self=~s{^\$}{};
	if ($self eq "_") {
		$self = "";
		$self.= 'local $_ = (ref($_[0]) and UNIVERSAL::isa($_[0],q('.$package.')))?shift:$_; my $me = $_;' if $Config->{options}->{varthis};
		$self.= 'my $me = shift;' unless $Config->{options}->{varthis};
		$self.= 'local ${^__} = $me;' if $Config->{options}->{hatthis};
		$self.= 'local $_ = (ref($_[0]) and UNIVERSAL::isa($_[0],q('.$package.')))?shift:$_; my $me = $_;' unless $self;
	} else {
		my $selfname = $self;
		$self = 'my $me = shift;';
		$self.='local *'.$package.'::'.$selfname.' = sub { $me };' if $Config->{options}->{subthis};
		$self.='local ${^_'.$selfname.'} = $me;' if $Config->{options}->{hatthis};
		$self.='local *'.$package.'::'.$selfname.' = \$me;' if $Config->{options}->{varthis};
		#$self = 'my $me = $_[0]; local *'.$package.'::'.$self.' = sub { $me }; local ${^_'.$self.'} = $_[0]; local *'.$package.'::'.$self.' = \shift;'
	}
	if (0) { # This is all too late. Needed to do it in BEGIN if I was going to do it at all.
		my @varargs = @args;
		eval 'package '.$package.'; use vars qw('.join(" ",grep { $_ ne "_" } map { s{^(?![\%\$\@])}{\$}; $_ } @varargs).');' if @varargs;
	}
	for (@args) {
		my $aname = $_;
		if ($aname=~/^\@(\w+)$/ and $aname eq $args[-1]) {
			$aname = $1;
			$_ = ''; # This alters @args!
			$_.= 'local @{^_'.$aname.'} = @_;' if $Config->{options}->{hatargs};
			$_.= 'my @args = @_; local *'.$package.'::'.$aname.' = \@args;' if $Config->{options}->{varargs};
			next;
		}
		if ($aname=~/^\%(\w+)$/ and $aname eq $args[-1]) {
			$aname = $1;
			$_ = ''; # This alters @args!
			$_.= 'local %{^_'.$aname.'} = @_;' if $Config->{options}->{hatargs};
			$_.= 'my %args = @_; local *'.$package.'::'.$aname.' = \%args;' if $Config->{options}->{varargs};
			next;
		}
		$aname=~s{^\$}{}; # Allow, but ignore leading dollar sigal.
		unless ($aname=~/^\w+$/) {
			require Carp;
			local $Carp::CarpLevel = 1;
			Carp::croak "Bad argument name: $aname (@args)";
		}
		$_ = ''; # This alters @args!
		if ($aname eq '_') {
			$_.='local $_ = $_[0];';
		} else {
			$_.='local ${^_'.$aname.'} = $_[0];' if $Config->{options}->{hatargs};
			$_.='local *'.$package.'::'.$aname.' = \$_[0];' if $Config->{options}->{varargs};
		}
		$_.='shift;';
	}
	my @fields = @{$Config->{allfields}};
	for (@fields) {
		my $fname = $_;
		$_ = "";
		$_.='local *{^_'.$Config->{fieldhatprefix}.$fname.'} = \$me->{q('.$fname.')};' if $Config->{options}->{hatfields};
		$_.='local *'.$package.'::'.$Config->{fieldvarprefix}.$fname.' = \$me->{q('.$fname.')};' if $Config->{options}->{varfields};
	}
	my $proto = prototype $referent;
	if (defined $proto) {
		$proto = "($proto)";
	} else {
		$proto = "";
	}
	if ($Config->{options}->{debug}) {
		my $subdecl = "sub ".$package."::".(*{$symbol}{NAME}).$proto." {\n\t$self\n\t@fields\n\t@args\n\t\$referent->(\@_)\n};\n";
		$subdecl=~s{;(?!\n)\s*}{;\n\t}gs;
		warn $subdecl;
	}
	local $@;
	my $subdecl = "package $package; sub $proto {
		$self
		@fields
		@args
		\$referent->(\@_)
	};";
	#*{$symbol} = eval $subdecl;
	#die $@."\n$subdecl" if $@;
	my $subref = eval $subdecl;
	die "Failure to create sub: ".$@."\n$subdecl" if $@;
	my ($sympkg,$symname) = (*{$symbol}{PACKAGE},*{$symbol}{NAME});
#	eval '*{$symbol} = $subref; 1' or warn "Assigning symbol: $@"; # I don't know why this doesn't work any more.
	eval '$'.$sympkg.'::{$symname} = $subref' or die "Failed to assign symbol *{$symbol}{PACKAGE}::*{$symbol}{NAME}: $@";
}

sub ClassMethod {
	my ($package, $symbol, $referent, $attr, $data, $stage) = @_;
	no warnings 'redefine';
	no strict 'refs';
	if (0 and defined($symbol) and *{$symbol}{NAME} eq 'ANON') {
	#   ^--- DISABLED!
		# Darn, need to find a better symbol. (Probably :Method is not on the first prototype...)
		#XXX: This doesn't work. Even $referent points to the wrong thing :(
		#	Can't figure out true name, can't figure out true reference = can't put Humpty Dumpty back together again :(
		($symbol) = eval 'grep { *{$_}{NAME} ne "ANON" } grep { *{$_}{CODE} and *{$_}{CODE} eq $referent } values %'.$package.'::';
	}
	if (not defined($symbol) or *{$symbol}{NAME} eq 'ANON') {
		require Carp;
		local $Carp::CarpLevel = 3;
		if ($^S) {
			Carp::croak "Unable to identify the name of subroutine at $referent. You appear to be calling this inside an eval. This is a known bug - please \"use\" this module at the start of your application.\n";
		} else {
			Carp::croak "Unable to identify the name of subroutine at $referent. Please ensure :Method is on the first prototype.\n";
		}
		# Don't try and apply the magic to a closure, this attribute is not set up for it.
	}
	my ($class,@args);
	my $Config = $Configs{$package}||__DefaultConfigs;
	$data = "." unless defined $data;
	if (ref $data) {
		($class,@args) = @$data;
	} else {
		($class,@args) = split(/[,\s]+/,$data);
	}
	$class = $Config->{class} if $class eq '.';
	my $self = $Config->{this};
	$class=~s{^\$}{};
	$self=~s{^\$}{};
	if ($self eq "_") {
		$self = "";
		$self.= 'local $_ = (ref($_[0]) and UNIVERSAL::isa($_[0],q('.$package.')))?shift:$_; my $me = $_;' if $Config->{options}->{varthis};
		$self.= 'my $me = shift;' unless $Config->{options}->{varthis};
		$self.= 'local ${^__} = $me;' if $Config->{options}->{hatthis};
		$self.= 'local $_ = (ref($_[0]) and UNIVERSAL::isa($_[0],q('.$package.')))?shift:$_; my $me = $_;' unless $self;
	} else {
		my $selfname = $self;
		$self = 'my $me = shift;';
		$self.='local *'.$package.'::'.$selfname.' = sub { $me };' if $Config->{options}->{subthis};
		$self.='local ${^_'.$selfname.'} = $me;' if $Config->{options}->{hatthis};
		$self.='local *'.$package.'::'.$selfname.' = \$me;' if $Config->{options}->{varthis};
		#$self = 'my $me = $_[0]; local *'.$package.'::'.$self.' = sub { $me }; local ${^_'.$self.'} = $_[0]; local *'.$package.'::'.$self.' = \shift;'
	}
	if ($class eq "_") {
		$class = "";
		$class.= 'local $_ = ref($me)||$me;' if $Config->{options}->{varthis};
		$class.= 'local ${^__} = $me;' if $Config->{options}->{hatthis};
		$class.= 'local $_ = ref($me)||$me;' unless $class;
	} else {
		my $classname = $class;
		$class = 'my $class = ref($me)||$me;';
		$class.='local *'.$package.'::'.$classname.' = sub { $class };' if $Config->{options}->{subclass};
		$class.='local ${^_'.$classname.'} = $class;' if $Config->{options}->{hatclass};
		$class.='local *'.$package.'::'.$classname.' = \$class;' if $Config->{options}->{varclass};
	}
	for (@args) {
		my $aname = $_;
		if ($aname=~/^\@(\w+)$/ and $aname eq $args[-1]) {
			$aname = $1;
			$_ = '';
			$_.= 'local @{^_'.$aname.'} = @_;' if $Config->{options}->{hatargs};
			$_.= 'my @args = @_; local *'.$package.'::'.$aname.' = \@args;' if $Config->{options}->{varargs};
			next;
		}
		if ($aname=~/^\%(\w+)$/ and $aname eq $args[-1]) {
			$aname = $1;
			$_ = '';
			$_.= 'local %{^_'.$aname.'} = @_;' if $Config->{options}->{hatargs};
			$_.= 'my %args = @_; local *'.$package.'::'.$aname.' = \%args;' if $Config->{options}->{varargs};
			next;
		}
		$aname=~s{^\$}{}; # Allow, but ignore leading dollar sigal.
		unless ($aname=~/^\w+$/) {
			require Carp;
			local $Carp::CarpLevel = 1;
			Carp::croak "Bad argument name: $aname (@args)";
		}
		$_ = ''; # This alters @args!
		if ($aname eq '_') {
			$_.='local $_ = $_[0];';
		} else {
			$_.='local ${^_'.$aname.'} = $_[0];' if $Config->{options}->{hatargs};
			$_.='local *'.$package.'::'.$aname.' = \$_[0];' if $Config->{options}->{varargs};
		}
		$_.='shift;';
	}
#	Class methods don't get fields (you have the {this} variable).
#	my @fields = @{$Config->{fields}};
#	for (@fields) {
#		my $fname = $_;
#		$_ = "";
#		$_.='local ${^_'.$fname.'} = $me->{q('.$fname.')};' if $Config->{options}->{hatfields};
#		$_.='local *'.$package.'::'.$fname.' = \$me->{q('.$fname.')};' if $Config->{options}->{varfields};
#	}
	my $proto = prototype $referent;
	if (defined $proto) {
		$proto = "($proto)";
	} else {
		$proto = "";
	}
	if ($Config->{options}->{debug}) {
		my $subdecl = "sub ".$package."::".(*{$symbol}{NAME}).$proto." {\n\t$self\n\t$class\n\t@args\n\t\$referent->(\@_)\n};\n";
		$subdecl=~s{;(?!\n)\s*}{;\n\t}gs;
		warn $subdecl;
	}
	local $@;
	my $subdecl = "package $package; sub $proto {
		$self
		$class
		@args
		\$referent->(\@_)
	};";
	my $subref = eval $subdecl;
	die "Failure to create sub: ".$@."\n$subdecl" if $@;
	my ($sympkg,$symname) = (*{$symbol}{PACKAGE},*{$symbol}{NAME});
#	eval '*{$symbol} = $subref; 1' or warn "Assigning symbol: $@"; # I don't know why this doesn't work any more.
	eval '$'.$sympkg.'::{$symname} = $subref' or die "Failed to assign symbol *{$symbol}{PACKAGE}::*{$symbol}{NAME}: $@";
#	*{$symbol} = eval "package $package; sub $proto {
#		$self
#		$class
#		@args
#		\$referent->(\@_)
#	};";
}

our %Methods;
our %ClassMethods;
our %symcache;

sub findsym($$) {
	my ($pkg,$ref) = @_;
	return $symcache{$pkg,$ref} if $symcache{$pkg,$ref} and *{$symcache{$pkg,$ref}}{CODE} eq $ref;
	no strict 'refs';
	for (values %{$pkg."::"}) {
		return $symcache{$pkg,$ref} = $_ if *{$_}{CODE} and *{$_}{CODE} eq $ref;
	}
	return undef; # Don't cache incase there is a better way to get it later.
}

sub make_methods($);
sub make_methods($) {
	my $pkg = shift;
	# My call line looks like this to maintain Attribute::Handlers compatibility.
	# unfortunately I cannot use Attribute::Handlers because it fails to trigger
	# if you do "eval 'use mypkg;'" and it can't find the symbols.
	#my ($package, $symbol, $referent, $attr, $data, $stage);
	my @oa = $pkg->NEXT::ELSEWHERE::ancestors;
	1 while @oa and shift(@oa) ne $pkg;
	1 while @oa and shift(@oa) ne "Class::MethodVars::_ATTRS";
	my $next;
	if (@oa) {
		make_methods(shift(@oa));
	}
	for my $data (@{$ClassMethods{$pkg}||[]}) {
		my ($package,$ref,$args) = @$data;
		my $sym = findsym($package,$ref);
		ClassMethod($package,$sym,$ref,"ClassMethod",$args,"import");
	}
	for my $data (@{$Methods{$pkg}||[]}) {
		my ($package,$ref,$args) = @$data;
		my $sym = findsym($package,$ref);
		Method($package,$sym,$ref,"ClassMethod",$args,"import");
	}
	delete $ClassMethods{$pkg};
	delete $Methods{$pkg};
}

{
	no warnings 'void'; # "Too late to run INIT block"
	INIT {
		make_methods($_) for keys %ClassMethods;
		make_methods($_) for keys %Methods;
	};
}

package Class::MethodVars::_ATTRS;
use warnings;
use strict;

use NEXT; # Need this incase they used to inherit from someone else.

sub import {
	my ($spkg,@args) = @_;
	my $tpkg = caller;
	if ($spkg eq __PACKAGE__) {
		require Carp;
		Carp::croak "Don't do that.";
	}
	Class::MethodVars::make_methods($spkg);
	my @oa = $_[0]->NEXT::ELSEWHERE::ancestors;
	1 while @oa and shift(@oa) ne $tpkg;
	1 while @oa and shift(@oa) ne __PACKAGE__;
	my $next;
	if (@oa and $next = $oa[0]->can("import")) {
		goto &$next;
	}
}

sub MODIFY_CODE_ATTRIBUTES {
	my ($pkg,$ref,@attrs) = @_;

# I want to write this:
#	my @oldattrs = @attrs;
#	unless (eval q{ @attrs = $pkg->NEXT::DISTINCT::ACTUAL::MODIFY_CODE_ATTRIBUTES($ref,@attrs); 1 }) {
#		@attrs = @oldattrs;
#	}
# But "(eval)" can't call NEXT...MODIFY_CODE_ATTRIBUTES! So:
	my @oa = $_[0]->NEXT::ELSEWHERE::ancestors;
	1 while @oa and shift(@oa) ne caller;
	1 while @oa and shift(@oa) ne __PACKAGE__;
	my $next;
	if (@oa and $next = $oa[0]->can("import")) {
		@attrs = $pkg->$next($ref,@attrs);
	}
# End whinge

	my @bad_attrs;
	my @good_attrs;
	for (@attrs) {
		if (/\A(?:Class)?Method(?:\(.*)?\z/) {
			push(@good_attrs,$_);
		} else {
			push(@bad_attrs,$_);
		}
	}
	if (@good_attrs > 1) {
		require Carp;
		Carp::croak q{Please only use one of :Method or :ClassMethod for each method};
	} elsif (@good_attrs) {
		my $args;
		$args = [split(/[\s,]/,$1)] if $good_attrs[0]=~/\((.*)\)\s*\z/;
		if ($good_attrs[0]=~/\AClassMethod/) {
			$ClassMethods{$pkg}||=[];
			push(@{$ClassMethods{$pkg}},[ $pkg,$ref,$args ]);
		} else {
			$Methods{$pkg}||=[];
			push(@{$Methods{$pkg}},[ $pkg,$ref,$args ]);
		}
	}
	return @bad_attrs;	
}

package Class::MethodVars::_Private;
use warnings;
use strict;

sub unique(@) {
	my %u = map { $_=>$_ } @_;
	return values %u;
}

sub retrFields($) {
	my $pkg = shift;
	return () unless $Class::MethodVars::Configs{$pkg};
	return () unless $Class::MethodVars::Configs{$pkg}->{fields};
	return @{$Class::MethodVars::Configs{$pkg}->{fields}};
}

sub findBaseFields($);
sub findBaseFields($) {
	my $pkg = shift;
	my @isa = eval '@'.$pkg.'::ISA';
	my @fields;
	for my $bpkg (@isa) {
		push(@fields,findBaseFields($bpkg));
	}
	return unique @fields,retrFields $pkg;
}

1;

__END__

=head1 NAME

Class::MethodVars - Implicit access to the class instance variable and fields variables for methods

=head1 DESCRIPTION

Using this module will allow you to mark subs as "ClassMethod"s and "Method"s. The former will get the current class name in
whatever is indicated by the -*class options ("__CLASS__" by default), both will get the current object in whatever is indicated
by the -*this options ("this" by default). The "Method"s will also get fields mapped into ${^_*} (where "*" is the field name).
The object MUST be a hash reference (or something that does a good impression of one), fields should be valid symbol names (ie match /^[_a-zA-Z]\w*$/).

=head1 SYNOPSIS

  use Class::MethodVars qw( field1 myotherfield );

  sub new :ClassMethod {
    return bless({@_},__CLASS__);
  }

  sub dual_fields :Method {
    @_ = @{shift()} if @_ == 1;
    if (@_) {
      ${^_field1} = shift;
      ${^_myotherfield} = shift;
    }
    return [ this->{field1},this->{myotherfield} ];
  }

=head1 FIELDS AND OPTIONS

Fields and Options are defined on the use line in the following fashion:

  use Class::MethodVars @fieldlist,@optionlist;

Either @fieldlist or @optionlist may be empty (in which case the separating comma may be dropped too).

Fields can also be specified via one of the -*fields options. @fieldlist can also be expressed as an array reference (eg [@fieldlist]).

=head1 OPTIONS WITH PARAMETERS

In the options below, "hatvar" refers to a variable named "${^_*}" with "*" replace with the name of the "hatvar" variable.
These are variables which are global in scope (like "$_") and excluded from "use strict" requirements (like "$_") and are explicitly
listed as being safe to use in programs (see L<perlvar>). Note that the reserved "${^_}" will never get used because an empty field name
is invalid.

=over 4

=item -this=>"name"

Set the variable/constant/hatvar name for accessing the current object.

Default is "this".

=item -class=>"name"

Set the variable/constant/hatvar name for accessing the current class name.

Default is "__CLASS__"

=item -rwfields=>@list or -rwfield=>@list or -rwfields=>[@list] or -rwfield=>[@list] -fields=>@list or -field=>@list or -fields=>[@list] or -field=>[@list]

Set the list of read+write field names for the class. Each instance of the option will be merged
with previous versions. Duplicate field names will be ignored. If using Class::Framework, accessors will be generated with ->mk_accessors for these fields

Default is no fields.

=item -rofields=>@list or -rofield=>@list or -rofields=>[@list] or -rofield=>[@list]

Set the list of read only field names for the class. Each instance of the option will be merged
with previous versions. Duplicate field names will be ignored. If using Class::Framework, accessors will be generated with ->mk_ro_accessors for these fields

Default is no fields.

=item -wofields=>@list or -wofield=>@list or -wofields=>[@list] or -wofield=>[@list]

Set the list of write only field names for the class. Each instance of the option will be merged
with previous versions. Duplicate field names will be ignored. If using Class::Framework, accessors will be generated with ->mk_wo_accessors for these fields

Default is no fields.

=item -hiddenfields=>@list or -hiddenfield=>@list or -hiddenfields=>[@list] or -hiddenfield=>[@list]

Set the list of hidden field names for the class. Each instance of the option will be merged
with previous versions. Duplicate field names will be ignored. No accessor methods will be created for these fields if using Class::Framework, however variables will be (subject to -varfields and -hatfields).

Default is no fields.

=item -fieldvarprefix=>"prefix"

Set the prefix to prepend to variables for field named. Requires -varfields. For example -fieldvarprefix=>"this_" would
create "$this_myfield" for a field called "myfield".

Default is "". (no prefix).

=item -fieldhatprefix=>"prefix"

Set the prefix to prepend to the hatvar ("${^_*}") style variables. Requires -hatfields. Given a prefix of "f", a field "stuff" would
get a variable "${^_fstuff}".

Default is "". (no prefix).

=back

=head1 BOOLEAN OPTIONS

All the options are described below as "-option", but they can be formed as:

  -option
  -option=>1
  -option=>"ON"
  -option=>"TRUE"
    All set the option ON.

  +option
  -option=>0
  -option=>"OFF"
  -option=>"FALSE"
    All set the option OFF.

=over 4

=item '-^args' or '-hatargs' 

Form ${^_*} variables for arguments. (See L</:Method()> or L</:ClassMethod()> below).

Default is ON.

=item '-varargs'

Create variables of the appropriate name for arguments (See L</:Method()> or L</:ClassMethod()>).
NOTE: You may have difficulty using these variables with "use strict 'vars';" as they are not automatically added into "use vars ...".
Simply predeclare them with "our $..." or "use vars ..." in the package. (Or if you feel invulnerable "no strict 'vars'").

Default is OFF.

=item '-^fields' or '-hatfields'

Create ${^_*} variables for fields. (Replacing "*" in each case with the field name). These variables will "write-through" to the actual fields
such that ${^_field} = 7; this->{field} == 7 is true. This means you should be able to use the ${^_*} form fields anywhere you would use the this->{*} form.

Default is ON.

=item '-varfields'

Create variables of the appropriate name for fields. These variables "write-through" as above. A field this->{myfield} would be available in $myfield.
These variables will be entered into "use vars ..." for your package, and so should work under "use strict 'vars'".

Default is OFF.

=item '-^this' or '-hatthis'

Create a variable ${^_this} (changing "this" for whatever -this is set to) that is the current object.

Default is OFF.

=item '-varthis'

Create a variable like "$this" (changing "this" for whatever -this is set to) that is the current object.

Default is OFF unless -this=>"_". (See L</"_" for -this and -class> below)

=item '-subthis'

Create a subroutine / constant called "this" (or whatever -this is set to).

Default is ON unless -this=>"_". (See L</"_" for -this and -class> below)

=item '-^class' or '-hatclass'

Create a ${^___CLASS__} variable (note *3* leading "_"! changing "__CLASS__" (2 leading "_"!) for whatever -class is set to) that is the current class. :ClassMethod only!

Default is OFF.

=item '-varclass'

Create a variable like "$__CLASS__" (changing "__CLASS__" for whatever -class is set to). :ClassMethod only!

Default is OFF unless -class=>"_". (See L</"_" for -this and -class> below)

=item '-subclass'

Create a subroutine / constant called "__CLASS__" (or whatever -class is set to).

Default is ON unless -class=>"_". (See L</"_" for -this and -class> below)

=item '-debug'

If present, displays the wrapper subroutines as they are created. You probably don't want to do this unless
you are sure that Class::MethodVars is doing something wrong.

Default is OFF.

=back

=head1 "_" for -this and -class

If -this is set to "_", then '$_' will be used as the variable for that this, and -subthis will be disabled ("_" is a magic file handle and
cannot be a subroutine). Also if the first parameter is not a member of this class, then $_ is assumed to already hold the object.
This allows method calls to the same class to skip the $_-> prefix. However watch your prototypes which should not include the "$" for the object
variable. Because the default settings would assign nothing for "_" they are overridden to assign to "$_" unless -hatthis is set.

The same things apply for -class=>"_". If both -this and -class are set to "_", then "$_" will be the class name in a :ClassMethod, and the object in :Method.

=head1 :Method()

This has 2 main forms:

  sub mymethod :Method { ... }
and
  sub mymethod :Method(this argnames) { ... }

The first form simply marks "mymethod" as a method and ensures that configured items are available.

The second form allows you to redefine the -this option and define the names of ordered arguments. The values in the parentheses are a space
or comma separated list of barewords. The first word is used to redefine the -this option and may be "." (a single dot) to indicate no change
from the "use" line. Subsequent words define names of positional parameters. The last parameter name may start with a "@" or "%" sigil to mop up @_.
If there are no parameter names or the last one is not an array or hash name then the remainder of @_ will be untouched.

Note that if there is a conflict of name between an argument and and field, the argument will win.

=head1 :ClassMethod()

This is the same as :Method(), except that in the second form the first name changes the -class option not the -this option.

=head1 EXAMPLES

See L<Class::Framework> for examples.

=head1 SEE ALSO

L<Class::Framework> - Combines this module with L<fields> and L<Class::Accessor>, adding a default new() :ClassMethod to fill out a class.

=head1 COPYRIGHT

Copyright 2006 Timothy Hinchcliffe.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. That means either (a) the GNU General Public License or (b) the Artistic License.

=cut
