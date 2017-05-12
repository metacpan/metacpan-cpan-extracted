#line 1
package CGI::Application::Plugin::AutoRunmode;

use strict;
require Exporter;
require CGI::Application;
use Carp;

our $VERSION = '0.15';


our %RUNMODES = ();

# two different versions of this module,
# depending on whether Attribute::Handlers is
# available

my $has_ah;

BEGIN{
	eval 'use Attribute::Handlers; $has_ah=1;';

if ($has_ah){
	$has_ah = eval <<'WITH_AH';

# run this handler twice:
# in CHECK when we have the name, and also in BEGIN
# (because CHECK does not seem to work in mod_perl) 

sub CGI::Application::Runmode :ATTR(CODE,BEGIN,CHECK) {
	my ( $pkg, $glob, $ref, $attr, $data, $phase ) = @_;
	no strict 'refs';
	$RUNMODES{"$ref"} = 1;
	if ($CGI::Application::VERSION >= 4 && $phase eq 'CHECK'){
		# also install the init-hook to register
		# named runmodes 
		my $name = *{$glob}{NAME};
		if ($name ne 'ANON'){
			$pkg->add_callback('init', sub{ 
				$_[0]->run_modes( $name => $ref ) 
					if ($_[0]->can($name)) eq $ref
			} )
		}
	}
}
sub CGI::Application::StartRunmode :ATTR(CODE,BEGIN) {
	my ( $pkg, $glob, $ref, $attr, $data, $phase ) = @_;
	install_start_mode($pkg, $ref);
}
sub CGI::Application::ErrorRunmode :ATTR(CODE,BEGIN) {
	my ( $pkg, $glob, $ref, $attr, $data, $phase ) = @_;
	install_error_mode($pkg, $ref);
}

# the Attribute::Handler version still exports a MODIFY_CODE_ATTRIBUTES
# but only to provide backwards compatibility (case-independent attribute
# names )

sub MODIFY_CODE_ATTRIBUTES{
	my ($pkg, $ref, @attr) = @_;
	foreach (@attr){
		if (uc $_ eq 'RUNMODE'){
			$_ = 'Runmode';
			next;
		}
		if (uc $_ eq 'STARTRUNMODE'){
			$_ = 'StartRunmode';
			next;
		}
		if (uc $_ eq 'ERRORRUNMODE'){
			$_ = 'ErrorRunmode';
			next;
		}
	}
	return $pkg->SUPER::MODIFY_CODE_ATTRIBUTES($ref, @attr);
}

1;
WITH_AH
	warn "failed to load Attribute::Handlers version of CAP:AutoRunmode $@" if $@;
}



unless ($has_ah){
	eval <<'WITHOUT_AH' or die $@;
sub MODIFY_CODE_ATTRIBUTES{
	my ($pkg, $ref, @attr) = @_;
	
	my @unknown;
	foreach (@attr){
		my $u = uc $_;
		$CGI::Application::Plugin::AutoRunmode::RUNMODES{"$ref"} = 1, next
			if $u eq 'RUNMODE';
		if ($u eq 'STARTRUNMODE'){
			install_start_mode($pkg, $ref);
			next;
		}
		if ($u eq 'ERRORRUNMODE'){
			install_error_mode($pkg, $ref);
			next;
		}
		push @unknown, $_;
	}
	return @unknown;
}
1;
WITHOUT_AH
}

}


our @ISA = qw(Exporter);

# always export the attribute handlers
sub import{ 
		__PACKAGE__->export_to_level(1, @_, 'MODIFY_CODE_ATTRIBUTES'); 
		 
		 # if CGI::App > 4 install the hook
		 # (unless cgiapp_prerun requested)
		 if ( @_ < 2 and $CGI::Application::VERSION >= 4 ){
		 		my $caller = scalar(caller);
		 		if (UNIVERSAL::isa($caller, 'CGI::Application')){
		 			$caller->add_callback('prerun', \&cgiapp_prerun);
                }
		 }
		 
		
		 
};

our @EXPORT_OK = qw[
		cgiapp_prerun
		MODIFY_CODE_ATTRIBUTES
	];



our %__illegal_names = qw[ 
	can can
	isa isa
	VERSION VERSION
	AUTOLOAD AUTOLOAD
	new	new
	DESTROY DESTROY
];

sub cgiapp_prerun{
	my ($self, $rm) = @_;	
	my %rmodes = ($self->run_modes());
	# If prerun_mode has been set, use it!
	my $prerun_mode = $self->prerun_mode();
	if (length($prerun_mode)) {
		$rm = $prerun_mode;
	}
	return unless defined $rm;
	
	unless (exists $rmodes{$rm}){
		# security check / untaint : disallow non-word characters 
		if ($rm =~ /^(\w+)$/){
			$rm = $1;
			# check :Runmodes
			$self->run_modes( $rm => $rm), return
				if is_attribute_auto_runmode($self, $rm);
		
			# check delegate
			my $sub = is_delegate_auto_runmode($self, $rm);
			$self->run_modes( $rm => $sub) if $sub;
			
		}
	}
}



sub install_start_mode{
	my ($pkg, $ref) = @_;
	
	no strict 'refs';
	die "StartRunmode for package $pkg is already installed\n"
		if defined *{"${pkg}::start_mode"};
	
	my $memory;
	
	#if (ref $ref eq 'GLOB') {
	#	$memory = *{$ref}{NAME};
	#	$ref = *{$ref}{CODE};
	#}
	
	$RUNMODES{"$ref"} = 1;
	
	*{"${pkg}::start_mode"} = sub{
				 return if @_ > 1;
				 return $memory if $memory;
				 return $memory = _find_name_of_sub_in_pkg($ref, $pkg);
			};
	
	
}


sub install_error_mode{
	my ($pkg, $ref) = @_;
	
	no strict 'refs';
	die "ErrorRunmode for package $pkg is already installed\n"
		if defined *{"${pkg}::error_mode"};
	
	my $memory;
	
	#if (ref $ref eq 'GLOB') {
	#	$memory = *{$ref}{NAME};
	#	$ref = *{$ref}{CODE};
	#}
	
	$RUNMODES{"$ref"} = 1;
	
	*{"${pkg}::error_mode"} = sub{
				 return if @_ > 1;
				 return $memory if $memory;
				 return $memory = _find_name_of_sub_in_pkg($ref, $pkg);
			};
	
	
}





# code for this inspired by Devel::Symdump
sub _find_name_of_sub_in_pkg{
	my ($ref, $pkg) = @_;
	no strict 'refs';
	#return *{$ref}{NAME} if ref $ref eq 'GLOB';
	while (my ($key,$val) = each(%{*{"$pkg\::"}})) {
			local(*ENTRY) = $val;
			if (defined $val && defined *ENTRY{CODE}) {
				next unless *ENTRY{CODE} eq $ref;
				# rewind "each"
				my $a = scalar keys %{*{"$pkg\::"}};
				return $key;
			}
		}

	die "failed to find name for StartRunmode code ref $ref in package $pkg\n";
}

sub is_attribute_auto_runmode{
	my($app, $rm) = @_;
	my $sub = $app->can($rm);
	return unless $sub;
	return $sub if $RUNMODES{"$sub"};
	# also check the GLOB
	#if ($has_ah){
	#	no strict 'refs';
	#	my $pkg = ref $app;
	#	warn "${pkg}::${rm}";
	#	use Data::Dumper;
	#	warn Dumper \%RUNMODES;
	#	return $sub if $RUNMODES{*{"${pkg}::${rm}"}};
	#}
	return undef;
}

sub is_delegate_auto_runmode{
	my($app, $rm) = @_;
	my $delegate = $app->param('::Plugin::AutoRunmode::delegate');
	return unless $delegate;
	return if exists $__illegal_names{$rm};
	
	
	my @delegates = ref($delegate) eq 'ARRAY' ? @$delegate
                                               : ($delegate);

    foreach my $delegate (@delegates) {
		my $sub = $delegate->can($rm);
		next unless $sub;
		
		# construct a closure, as we need a second
		# parameter (the delegate)
		my $closure = sub { $sub->($_[0], $delegate); };
		return $closure;
    } 
	
}

sub is_auto_runmode{
	return is_attribute_auto_runmode(@_) || is_delegate_auto_runmode(@_);
}



1;
__END__

#line 579
