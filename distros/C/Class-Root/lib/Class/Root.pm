package Class::Root;

use 5.006000;
use warnings;
use strict;

=head1 NAME

Class::Root - framework for writing perl OO modules

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

my $ROOT_CLASS = __PACKAGE__;

package declare;

sub import {
    shift;
    goto &Class::Root::LOCAL::declare;
}

sub new {
    my $class = shift;
    my $self = { @_ };
    bless $self, $class;
}

$INC{"declare.pm"} = 1;

package Class::Root::LOCAL;

use strict;
use warnings;

use English;
use Carp;
$Carp::Verbose = 0;

use Data::Dumper;

use Filter::Util::Call;

my @flags;
BEGIN {
    *::CT_CHECKS = sub(){1} unless defined(&::CT_CHECKS);
    *::RT_CHECKS = sub(){1} unless defined(&::RT_CHECKS);
    *::LOCAL_SUBS = sub(){1} unless defined(&::LOCAL_SUBS);

    @flags = qw( AF MF CF PRIV PROT RO OVER VIRT SETOPTS );
    
    my $i = 0;
    
    foreach (@flags) {
	my $n = $i++;
	no strict 'refs';
	*$_ = sub(){ 1<<$n };
    }
}

sub flags2hr {
    my $flags = shift;
    my $hr;
    foreach (@flags) {
	no strict 'refs';
	$hr->{$_} = $flags & &$_ ? 1 : 0;
    }
    return $hr;
}

# here we save class attributes for all classes
my $class_data = {};

# hash of all subs ( methods and attributes )
my $subs = {};

# class schema hash 
my $schema = {};

sub init_schema {
    my $class = shift;
    
    $schema->{$class} = {   
	NUMBER_OF_PARENTS => 0,
	HAVE_CLASS_ATTR_VALUES => 0,
	HAVE_INSTANCE_ATTR_VALUES => 0,
        INSTANCE_ATTR_VALUES => {},
	CLASS_ATTR_VALUES => {},
        PROT_EXPORT => [],
	LOCAL_SUBS => {},
	SUBS => {},
	CT_OPTS => {
	    VERBOSE_SOURCE_CODE_CHANGES => 0,
	    DEFINE_LOCAL_SUBS => 0,
	    VERBOSE => 0,
	},
    }
}

init_schema($ROOT_CLASS);

my @export_local = qw( declare attribute class_attribute attributes method class_method overwrite override private protected virtual readonly setopts setoptions setval setvalue );

sub prefix {
    my $str = shift;
    
    $str =~ s/:/_/g;
    return $str."__";
};

my $ROOT_CLASS_PREFIX = prefix($ROOT_CLASS);

my %s2f = (
    '_' => PRIV,
    ':' => CF,
    '?' => RO,
    '*' => PROT,
    '!' => OVER,
    '~' => VIRT,
);

sub method_name_ok {
    local $_ = shift;
    /^[_:?*!~]*[a-zA-Z]\w*$/;
}

sub sflags2flags {
    my $sflags = shift;
    
    my $flags = 0;
    foreach ( unpack('A1' x length($sflags), $sflags) ) {
        $flags |= $s2f{$_};
    }
    return $flags;
}

sub c2cl {
    my $class = shift;
    return $class."::LOCAL";
}

sub cl2c {
    my $str = shift;
    $str =~ s/::LOCAL$//;
    return $str;
}

sub vmesg {
    my $class = shift;
    my $mesg = shift;
    
    my $verbose = $schema->{$class}->{CT_OPTS}->{VERBOSE};
    print STDERR $mesg if $verbose;
}

sub declare {

    my $caller_local = caller();
    my $caller = cl2c($caller_local);
    
    my @args = ();

    #print Dumper( \@_ );
    
    foreach ( @_ ) {
        if ( /^([+-])(.*)/ ) {
	    my $v = ( $1 eq '+' ) ? 1 : 0;
	    my $k = $2;
	    my $old_v = $schema->{$caller}->{CT_OPTS}->{$k};
	    $schema->{$caller}->{CT_OPTS}->{$k} = $v;
	
	    if ( $k eq 'DEFINE_LOCAL_SUBS' and $v and !$old_v ) {
	        define_local_subs($caller_local, $caller, $caller);
	    }

	} else {
	    push @args, $_;
	}
    }	

    @_ = @args;

    my $i = 0;
    while ( @_ ) {
    
        my $name_str = shift;
	my $hr = shift;
	
	unless ( defined $hr ) {
	    $hr = "declare"->new( FLAGS => AF, OPTS => {} );   
	}

	unless ( ref($hr) eq "declare" ) {
	    $hr = "declare"->new( FLAGS => AF, OPTS => { value => $hr } ); 
	}
	
	if ( ::CT_CHECKS ) {
	    $i += 2;
	    croak "declare: syntax error - wrong argument in position $i\n" unless ref($hr) eq "declare";
	}
	
	unless ( $name_str =~ /([:_?*!~]*)([a-zA-Z]\w*)$/ ) {
	    croak "Wrong format for method name -->$name_str<--\n";
	}

	my $flags = sflags2flags($1);
        my $pub_name = $2;

        $flags |= $hr->{FLAGS};

	#attribute flag is set by default
	$flags |= AF unless $flags & MF;
	
        my $priv_name = prefix($caller) . $pub_name;

        my $opts = $hr->{OPTS};

	my $name = $pub_name;
	my $key = $pub_name;
	my $sub;
	my $tied_sub;
	
	if ( $flags & AF ) {

	    my $oro = $opts->{readonly};
	    if ( defined $oro ) {
		$flags |= RO if $oro; 
		$flags = $flags | RO ^ RO unless $oro;
	    }
	}
	
	# remove PRIV flag for RO attrs
	my $ro_flags = $flags | PRIV ^ PRIV;

	# remove PROT flag for RO attrs
	$ro_flags = $ro_flags | PROT ^ PROT;

	# force PRIV flag fo priv part of RO and PROT 
	$flags |= PRIV if $flags & (RO|PROT);
	
        if ( $flags & PRIV ) {
	    $name = $priv_name;
	    $key = $priv_name;
        }
	
	# set options for existing method
	if ( $flags & SETOPTS ) {
	    setopts_only( CLASS => $caller, NAME => $name, OPTS => $opts );
	    next;
	}
	
	if ( exists $opts->{value} ) {
	    my $key = $flags & CF ? "CLASS" : "INSTANCE";
	    $schema->{$caller}->{$key."_ATTR_VALUES"}->{$name} = $opts->{value};
	    $schema->{$caller}->{"HAVE_".$key."_ATTR_VALUES"} = 1;
	}

	$sub = $hr->{SUB} if $flags & MF;
	
	if ( $flags & AF ) {
	    ( $sub, $tied_sub ) = create_accessor( NAME => $name, KEY => $key, FLAGS => $flags );
	}
	make_method( CLASS => $caller, NAME => $name,  FLAGS => $flags, SUB => $sub, TIED_SUB => $tied_sub );

	if ( ::RT_CHECKS ) {
	    if ( exists $opts->{check_value} ) {
		$schema->{$caller}->{SUBS}->{$name}->{TIED} = 1;
		$schema->{$caller}->{SUBS}->{$name}->{CHECK_VALUE} = $opts->{check_value};
	    }
	}
	
	if ( $flags & RO ) {
	    ( my $ro_sub ) = create_accessor( NAME => $pub_name, KEY => $priv_name, FLAGS => $ro_flags );
	    make_method( CLASS => $caller, NAME => $pub_name,  FLAGS => $ro_flags, SUB => $ro_sub, TIED_SUB => $tied_sub );
	}    
    }
};

sub setopts_only {
    my %args = ( @_ );

    my $class = $args{CLASS};
    my $name = $args{NAME};
    my $opts = $args{OPTS};
    	    
    my $mhr = $schema->{$class}->{SUBS}->{$name};
    
    if ( ::CT_CHECKS ) {

	croak "Can't set options for undefined attribute $name" unless defined $mhr;
    
	croak "Can't set options for readonly attribute $name" if $mhr->{FLAGS} & RO;
            
	croak "Can't set options for method" if $mhr->{FLAGS} & MF;

    }
	    
    my $value = $opts->{value};

    if ( defined $value ) {
	my $key = $mhr->{FLAGS} & CF ? "CLASS" : "INSTANCE";
	$schema->{$class}->{$key."_ATTR_VALUES"}->{$name} = $value;
	$schema->{$class}->{"HAVE_".$key."_ATTR_VALUES"} = 1;
    }
	    
    if ( ::RT_CHECKS ) {
	if ( defined $opts->{check_value} ) {
	    $schema->{$class}->{SUBS}->{$name}->{TIED} = 1;
    	    $schema->{$class}->{SUBS}->{$name}->{CHECK_VALUE} = $opts->{check_value};
	}
    }

}

sub gen_sub {

    my $name = shift;
    my $flag = shift;

    my $setopts = ( $name =~ /^setopt(ion)?s$/ or $name =~ /^setval(ue)?$/ );

    my $sub = sub { 

	#print "$name: ", Dumper(\@_);
    
        my @ret = ();
        my $hr = "declare"->new( FLAGS => 0, OPTS => {} );

	if ( @_ ) {
	    
	    my $arg0 = shift;
	
	    if ( $setopts ) {

		my $val = $arg0;
		my $val_pos = 1;
		
		if ( @_ ) {
		    
		    if ( method_name_ok($arg0) ) {
			push @ret, $arg0;
			$hr->{FLAGS} = SETOPTS;
		    
			$val = shift;
			$val_pos = 2;
		    }
		    #croak "function \"$name\": couldn't have more then 2 arguments" if @_;
		}

		if ( $name =~ /^setopt(ion)?s$/ ) {
		    
		    croak "function \"$name\": argument at position $val_pos is not an options hr" unless ref($val) eq "HASH"; 
		    my %known_options = (
			value => 1,
			check_value => 1
		    );
		    
		    foreach my $key ( keys %$val ) {
			croak "function \"$name\": unknown option $key" unless exists $known_options{$key};	
		    }
		    
		    $hr->{OPTS} = $val;
		
		} else {
	
		    $hr->{OPTS} = { value => $val };
		}

		    
	    } else {

		if ( ref($arg0) eq "declare" ) {
		    $hr = $arg0
	    
		} elsif ( ref($arg0) eq "HASH" ) {

		    croak "function \"$name\": arg0 could be a method name or other declare subfunction\n"; 
		} else {
		
		    croak "function \"$name\": wrong format of method name arg0\n" unless method_name_ok($arg0); 
		
		    push @ret, $arg0;

		    if ( @_ ) {
			my $arg1 = shift;
		    
			#croak "function \"$name\": couldn't have more then 2 arguments" if @_;
    
			if ( ref($arg1) eq "declare" ) {
			    $hr = $arg1;   
    		    
			} else {
    			
    			    $hr->{OPTS} = { value => $arg1 };
    			}
    		    }
		}
	    }
	}

	unless ( $setopts ) {
	    my $flags = $hr->{FLAGS};
	    $flags |= $flag;	
	    $flags = $flags | SETOPTS ^ SETOPTS;
	    $hr->{FLAGS} = $flags;;
	}
    
	push @ret, $hr, @_;
            
        return @ret;
    };

    no strict 'refs';
    *$name = $sub;
};

my %declare_subs = (
    attribute => AF,
    class_attribute => CF|AF,
    protected => PROT,
    private => PRIV,
    virtual => VIRT,
    overwrite => OVER,
    override => OVER,
    readonly => RO,
    setopts => SETOPTS,
    setoptions => SETOPTS,
    setval => SETOPTS,
    setvalue => SETOPTS,
);

while ( my ($k, $v ) = each %declare_subs ) {
    gen_sub($k, $v);
}

sub method(;&) {
    #print "method: ", Dumper(\@_);
    my $sub = shift;
    return "declare"->new( FLAGS => MF,  SUB => $sub, OPTS => {} );
};

sub class_method(;&) {
    #print "class_method: ", Dumper(\@_);
    my $sub = shift;
    return "declare"->new( FLAGS => CF|MF, SUB => $sub, OPTS => {} );
};


sub attributes {

    my @ret = ();

    foreach ( @_ ) {
        foreach my $line ( split /\n/, $_ ) {
            
            $line =~ s/(^|\s)#.*//;
            
            foreach my $str ( split /\s+/, $line ) {
            
		next unless $str;
		
		unless ( $str =~ /^([_:?*]*)([a-zA-Z]\w*)$/ ) {
		    croak "Wrong attribute format for -->$str<--\n";
		}

                my $flags_str = $1;
                my $name = $2;
		
		my $flags = AF | sflags2flags($flags_str);

                push @ret, $name, "declare"->new( FLAGS => $flags, OPTS => {} );
            }
        }
    }

    return @ret;
};

if ( ::CT_CHECKS ) {

    *update_schema = sub {

	my $o = shift;
	my $n = !$o;

	my $hr = { @_ };

	my $name = delete $hr->{NAME};
	my $class = delete $hr->{CLASS};

	my $cschema = $schema->{$class};
	my $csubs = $cschema->{SUBS};
    
	unless ( exists $csubs->{$name} ) {
	    $csubs->{$name} = $hr;
	    return "";
	}
	
	my $hr2 = $csubs->{$name};
	
	my $ohr = $o ? $hr : $hr2;
	my $nhr = $o ? $hr2 : $hr;
	
	my $oflags = $ohr->{FLAGS};
	my $oparent = $ohr->{PARENT};
	my $osub = $ohr->{SUB};
	
	my $nflags = $nhr->{FLAGS};
	my $nparent = $nhr->{PARENT};
	my $nsub = $nhr->{SUB};

	my $ocf = $oflags & CF;
	my $ncf = $nflags & CF;

	my $overstr = $class eq $nparent ? " (defined in class \"$class\")" : " (defined in base class \"$nparent\")"; 
	
	if ( $ncf != $ocf ) {
		
	    my $type_str1 = $ncf ? "instance method" : "class method";
	    my $type_str2 = $ocf ? "instance method" : "class method";

	    return "$type_str1 \"$name\"$overstr also defined as $type_str2 \"$name\" in base class \"$oparent\""; 
	}
	
	# same method in 2 base classes
	if ( ($class ne $nparent) and ($oparent ne $nparent) ) {
	    unless ( $name =~ /^(init|class_init|DESTROY)$/ ) {
		return "Method \"$name\"$overstr also defined in base class \"$oparent\""; 
	    }
	}

	# overwriting of nonvirtual method from base class
	if ( ($class eq $nparent) and !($nflags & OVER) and !($oflags & VIRT) ) {
	    return "Method \"$name\"$overstr also defined in base class \"$oparent\""; 
	} 
	
	if ( $nflags & AF and $nflags & OVER ) {
	    return "attributes couldn't be overwritten";
	}

	return "" if ( $osub eq $nsub );
	
	$csubs->{$name} = $nhr;
	return "";
	
    };
}

# files for which we already have a filter 
my %filter_line = ();

# already seen classes
my %import_done = ();

my $base_init_done_key = "_BASE_INIT_DONE";
my $base_destroy_done_key = "_BASE_DESTROY_DONE";
my $attr_init_done_key = "_ATTR_INIT_DONE";

declare import => class_method {
    my $parent = shift;
    
    my $isa_arg = "";
    if ( @_ and $_[0] eq "isa" ) {
	$isa_arg = shift;
    }

    my ( $caller, $caller_file, $caller_line ) = caller();
    my $caller_local = c2cl($caller);

    unless ( exists  $schema->{$caller} ) {
        init_schema($caller);
    }

    my $cschema = $schema->{$caller};
    my $copts = $cschema->{CT_OPTS};
    
    my @args = ();
    foreach ( @_ ) {
	if ( /^([+-])(.*)/ ) {
	    my $v = ( $1 eq '+' ) ? 1 : 0;
	    $copts->{$2} = $v;
	} else {
	    push @args, $_;
	};
    }
    
    unless ( $isa_arg ) {
	
        if ( $copts->{DEFINE_LOCAL_SUBS} ) {
	    define_local_subs($caller, $parent);
	}
    
	if ( my $local_import = $caller_local->can("import") ) {
	    local @_ = ( $parent, @args );
	    goto $local_import;
	} else {
	    return;
	}
    }
    
    my $filter_prefix = prefix($caller);

	$filter_line{$caller_file} = $caller_line+1;

	filter_add( 
	    sub {
		my $status;
            
		if ( ( $status = filter_read() ) > 0 ) {
		    
		    my $line = $filter_line{$caller_file}++;
		    
		    if ( /^\s*package\s+([\w:]+)\s*;/ ) {
			filter_del() unless ( $1 eq $caller_local );
		    }

		    # $class_foo->_PrivMethod will be translated in $class_foo->Class__Foo__PrivMethod
		    my $sav_line = "$_";
		    my $changed = 0;

		    if ( $filter_prefix ) {
			s/((-\>\s*)_(?=[A-Za-z]))/$2$filter_prefix/g and $changed=1 ;
		    }

		    # $obj->__Some_Method will be translated in $obj->_Some_Method
		    s/(-\>\s*_)_/$1/g and $changed=1;
		    
		    if ( ::CT_CHECKS ) {

			my $verbose_sf = $copts->{VERBOSE_SOURCE_CODE_FILTER};
			my $verbose = $copts->{VERBOSE};

			if ( $changed and ($verbose or $verbose_sf) ) {
			    print STDERR "Changing source file \"$caller_file\", line $line:\nfrom..> ${sav_line}to....> $_"; 
			}
		    }
		}

		$status;
	    }
	);

    # @ISA

    my $caller_isa = $caller."::ISA";

    if ( ::CT_CHECKS ) {
	vmesg($caller,"push $parent to \@$caller_isa\n");
    }

    { no strict 'refs';
	push @$caller_isa, $parent;
    }

    $cschema->{NUMBER_OF_PARENTS}++;
    
    # this should be done only once for each class
    unless ( $import_done{$caller} ) {
	
	$import_done{$caller} = 1;
	
	$class_data->{$caller} = {
	    $base_init_done_key => {},
	    $attr_init_done_key => {},
	};

	( my $inc_key = $caller ) =~ s{::}{/}g;
	$inc_key .= '.pm';
	$INC{$inc_key} = 1;

	# export declare and subfunctions in caller's "LOCAL" package
	foreach my $f ( @export_local ) {
	    my $caller_f = $caller_local."::".$f;

	    if ( ::CT_CHECKS ) {
		vmesg($caller,"Defining sub $caller_f\n");
	    }

	    no strict 'refs';
	    *$caller_f = *$f;
	}

	my $class_initialize = $caller_local."::class_initialize";

	if ( ::CT_CHECKS ) {
	    vmesg($caller,"Defining sub \"$class_initialize\"\n");
	}
	
	my $generic_class_init_method = sub {
	    my $class = shift;
	    $class->base_class_init( "CALLER=$caller", @_ );
	};

	my $caller_class_init = $caller."::class_init";

	{ no strict 'refs';
	    *$class_initialize = sub {
		
		unless ( defined(&$caller_class_init) ) {
		    if ( @_ or $cschema->{NUMBER_OF_PARENTS} > 1 or $cschema->{HAVE_CLASS_ATTR_VALUES} ) {
			if ( ::CT_CHECKS ) {
			    vmesg($caller,"Defining sub \"$caller_class_init\" with generic code\n");
			}

			*$caller_class_init = $generic_class_init_method;
		    }
		}
		
		$caller->class_init( @_ ) 
	    };
	}
	
	my $class_verify = $caller_local."::class_verify";

	if ( ::CT_CHECKS ) {
	    vmesg($caller,"Defining sub \"$class_verify\"\n");
	}
	
	my $generic_init_method = sub {
	    my $self = shift;
	    $self->base_init( "CALLER=$caller", @_ );
	};

	my $caller_init = $caller."::init";
	
	my $generic_destroy_method = sub {
	    my $self = shift;
	    $self->base_destroy( "CALLER=$caller" );
	};

	my $caller_destroy = $caller."::DESTROY";
	
	{ no strict 'refs';
	    *$class_verify = sub { 
	    
		unless ( defined(&$caller_init) ) {
		    if ( $cschema->{NUMBER_OF_PARENTS} > 1 or $cschema->{HAVE_INSTANCE_ATTR_VALUES} ) {
			if ( ::CT_CHECKS ) {
			    vmesg($caller,"Defining sub \"$caller_init\" with generic code\n");
			}

			*$caller_init = $generic_init_method;
		    }
		}

		unless ( defined(&$caller_destroy) ) {
		    if ( $cschema->{NUMBER_OF_PARENTS} > 1 ) {
			if ( ::CT_CHECKS ) {
			    vmesg($caller,"Defining sub \"$caller_destroy\" with generic code\n");
			}

			*$caller_destroy = $generic_destroy_method;
		    }
		}
		
		$caller->class_schema_check( @_ )
	    };
	}
    }
    
    my $caller_prot_export = $cschema->{PROT_EXPORT};

    my $caller_prefix = prefix($caller);

    my $pschema = $schema->{$parent};
    my $parent_prot_export = $pschema->{PROT_EXPORT};
    my $parent_prefix = prefix($parent);
    
    foreach my $prot_m ( @$parent_prot_export ) {

	push @$caller_prot_export, $prot_m;
	my $caller_prot_m = $caller_prefix.$prot_m;
        my $parent_prot_m = $parent_prefix.$prot_m;
            
        my $caller_mname = $caller."::$caller_prot_m";
        my $parent_mname = $parent."::$parent_prot_m";

	if ( ::CT_CHECKS ) {
	    vmesg($caller,"Defining sub $caller_mname as alias to $parent_mname\n");
	    my $pmhr = $pschema->{SUBS}->{$parent_prot_m};
	    my $err = update_schema( 1, CLASS => $caller, NAME => $caller_prot_m, SUB => $pmhr->{SUB}, PARENT => $parent, FLAGS => $pmhr->{FLAGS} );
            croak "Schema error for class \"$caller\": $err\n" if $err;
	}

	if ( ::LOCAL_SUBS ) {
	    my $pmhr = $pschema->{LOCAL_SUBS}->{$parent_prot_m};
	    $cschema->{LOCAL_SUBS}->{$caller_prot_m}->{SUB} = $pmhr->{SUB};
	    $cschema->{LOCAL_SUBS}->{$caller_prot_m}->{FLAGS} = $pmhr->{FLAGS};
	}

	no strict 'refs';
	*$caller_mname = *$parent_mname;

    }
    
    if ( ::CT_CHECKS ) {
        while ( my($m, $mhr) = each %{ $pschema->{SUBS} } ) {
	    my $sub = $mhr->{SUB};
	    my $parent = $mhr->{PARENT};
	    my $flags = $mhr->{FLAGS};
            my $err = update_schema( 1, CLASS => $caller, NAME => $m, SUB => $sub, PARENT => $parent, FLAGS => $flags );
            croak "Schema error: $err\n" if $err;
        }
    }

    if ( ::LOCAL_SUBS ) {
	while ( my($m, $mhr) = each %{ $pschema->{LOCAL_SUBS} } ) {
	    my $flags = $mhr->{FLAGS};
	    next if ( $flags & PRIV or exists $cschema->{LOCAL_SUBS}->{$m} );
	    $cschema->{LOCAL_SUBS}->{$m}->{SUB} = $mhr->{SUB};
	    $cschema->{LOCAL_SUBS}->{$m}->{FLAGS} = $flags;
	}
    }
};

sub define_local_subs {
    my $caller = shift;
    my $class = shift;
    my $default_class = shift;
    
    croak "Can't define local subs with disabled LOCAL_SUBS\n" unless ::LOCAL_SUBS;
    
    my $clsubs = $schema->{$class}->{LOCAL_SUBS};
	    
    while ( my($f, $mhr) = each %$clsubs ) {

	my $flags = $mhr->{FLAGS};
	
	my $priv = $flags & PRIV;

	next if ( $caller ne $class and $priv );
	    
	my $sub = $mhr->{SUB};
	my $prototype = prototype( $sub );
	if ( defined $prototype and $prototype eq "" ) {
	    $f = "_$f" if $priv;
	    if ( $priv ) {
		my $prefix = prefix($caller);
		$f =~ s/^$prefix/_/;
	    }
	    my $caller_f = $caller."::".$f;

	    my $lfsub = $sub;
		
	    my $def = "";	
	    if ( defined $default_class and $flags & CF ) {
		my $ro = $flags & RO;

		if ($flags & RO and !$priv) {
		    
		    $lfsub = sub {
			local $_ = shift || $default_class; 
			&$sub;
		    };

		} else {

		    $lfsub = sub():lvalue {
			local $_ = shift || $default_class; 
			&$sub; 
		    };    
		}
		
		if ( ::CT_CHECKS ) {
		    $def = "D:$default_class"; 
		}
	    }
	    
	    no strict 'refs';

	    if ( defined &$caller_f ) {
		croak "Function \"$f\" already defined in package \"$caller\"\n" unless \&$caller_f eq $lfsub;
	    } else {

		if (::CT_CHECKS ) {
		    vmesg($caller,"Defining local sub $caller_f $def\n");
		}
	    
		*$caller_f = $lfsub;
	    }
	}
    }
}

sub make_method {

    my %args = ( @_ );
    
    my $class = $args{CLASS};
    my $name = $args{NAME};
    my $flags = $args{FLAGS};
    my $sub = $args{SUB};
    my $tied_sub = $args{TIED_SUB};
    
    my $virt = $flags & VIRT;

    if ( ::CT_CHECKS ) {

	unless ( $name =~ /^[a-zA-Z]\w*$/ ) {
	    croak "Wrong method name: -->$name<--. Supported method names should match ".'/^[a-zA-Z]\w*$/'."\n";
	}

	if ( !$virt and !defined( $sub ) ) {
	    croak "class $class: implementation subroutine should be defined for non-virtual method \"$name\"\n";
	}

	if ( $virt and defined( $sub ) ) {
	    croak "class $class: no implementation subroutine should be defined for virtual method \"$name\"\n";
	}

	my $over = $flags & OVER;
	my $cschema = $schema->{$class};
	my $csubs = $cschema->{SUBS};

	my $code;
	if ( !$over and $code = $class->can($name) ) {
	    unless( $csubs->{$name}->{FLAGS} & VIRT ) {
		my $bc = defined $csubs->{$name} ? $csubs->{$name}->{PARENT} : "???";

		my $mname = $name;
		if ( $csubs->{$name}->{FLAGS} & PRIV ) {
		    my $prefix = prefix($class);
		    $mname =~ s/^$prefix/_/;
		}
		croak "class \"$class\": method \"$mname\" already defined in base class \"$bc\"\n";
	    }
	}

	if ( $over and !$class->can($name) ) {
	    croak "class \"$class\": method $name not defined, can not overwrite\n";
	}
    }
    
    if ( $virt ) {
	$sub = sub {
	    my ($package, $filename, $line ) = caller(1);
	    croak "call of virtual method \"$name\" defined in class \"$class\" from package \"$package\", file \"$filename\", line \"$line\"\n"; 
	};
    }

    if ( $flags & PROT ) {
        my $prefix = prefix($class);
        $name =~ /^$prefix(.*)/;
        push @{ $schema->{$class}->{PROT_EXPORT} }, $1;
    }
    
    my $method_name = $class."::".$name;

    unless ( exists $subs->{$sub} ) {
	$subs->{$sub} = {
	    NAME => $name,
	    SUB => $sub,
	    TIED_SUB => $tied_sub,
	}
    }
    
    if ( ::CT_CHECKS ) { 
	my $err = update_schema( 0, CLASS => $class, PARENT => $class, NAME => $name, SUB => $sub, FLAGS => $flags ); 
        croak "Schema error in class \"$class\": $err\n" if $err;
    };

    if ( ::LOCAL_SUBS ) {
	my $cschema = $schema->{$class};
	$cschema->{LOCAL_SUBS}->{$name}->{SUB} = $sub;
	$cschema->{LOCAL_SUBS}->{$name}->{FLAGS} = $flags;
    }

    if ( ::CT_CHECKS ) {
        vmesg($class,"Defining sub $method_name\n");
    }
    
    { 
	no strict 'refs';
        if ( $name eq "class_init" or $name eq "init" or $name eq "DESTROY" ) {
	    no warnings;
	    *$method_name = $sub;
	} else {
	    *$method_name = $sub;
	}
    }

    if ( ::LOCAL_SUBS ) {
	
	if ( $schema->{$class}->{CT_OPTS}->{DEFINE_LOCAL_SUBS} ) {
	    my $local_func_name = $class."::LOCAL::".$name;
	
	    my $cf = $flags & CF;
	    my $ro = $flags & RO;
	    my $priv = $flags & PRIV;
	
	    if ( $priv ) {
		my $prefix = prefix($class);
		$name =~ /^$prefix(.*)/;
		$local_func_name = $class."::LOCAL::_$1";
	    }

	    my $prototype = prototype( $sub );
	    if ( defined $prototype and $prototype eq "" ) {

		my $lfsub = $sub;
		
		my $def = "";
		if ( $cf ) {
	    
		    $lfsub = ($ro and !$priv) ? sub{local $_=shift||$class; &$sub} : sub():lvalue{local $_=shift||$class; &$sub };    

		    $def = "D:$class";
		}
		
		if ( ::CT_CHECKS ) {
		    vmesg($class,"Defining local sub $local_func_name\n");
		}
		
		no strict 'refs';
		*$local_func_name = $lfsub;
	    }
	}
    }
};

my $ties = {};

if ( ::RT_CHECKS ) {
    
    *Class::Root::tiescalar::TIESCALAR = sub {
	my $class = shift;
	my $scalar = undef;
	return (bless \$scalar, $class);
    };

    *Class::Root::tiescalar::FETCH = sub {
	my $self = shift;
    
	my $hr = $ties->{$self}->{hr};
	my $key = $ties->{$self}->{key};
	return $hr->{$key}; 
    };

    *Class::Root::tiescalar::STORE = sub {
	my $self = shift;
	    
	my $val = shift;
	    
	my $hr = $ties->{$self}->{hr};
	my $key = $ties->{$self}->{key};
	my $class = $ties->{$self}->{class};
	my $name = $ties->{$self}->{subname};

	my $chk_sub = sub {
	    my $sub = shift;
	    
	    local $_ = $val;
	    my $err = &$sub;
	    croak "check_value error for attr ", $name, " : $err" if $err;
	};

	my $rec_check;
	$rec_check = sub {
	    my $class = shift;
	    my $sub = $schema->{$class}->{SUBS}->{$name}->{CHECK_VALUE};
	    &$chk_sub($sub) if defined $sub;

	    my @class_isa;
	    { no strict 'refs';
		@class_isa = @{$class."::ISA"};
	    }

	    foreach my $parent ( @class_isa ) {
		$rec_check->($parent);
	    }
	};

	$rec_check->($class);
	
	$hr->{$key} = $val;
    };
}

my $accessors = {};

sub create_accessor {

    my %args = ( 
	@_,
    );

    my $name = $args{NAME};
    my $key = $args{KEY};
    my $flags = $args{FLAGS};

    my $cf = $flags & CF;
    my $ro = $flags & RO;
    my $priv = $flags & PRIV;

    
    my $akey = "$name/$key/$cf/$ro";
    my $sub = $accessors->{$akey};
    my $tied_sub;
    
    if ( $ro and !$priv ) {
	
	$sub or $sub = sub () {
	    my $self = shift || $_;
	    my $class = ref($self) || $self;
	    
	    if ( @_ ) {
		my $err = $cf ?
		    "class \"$class\": couldn't set read only class attribute \"$name\"\n"
		  :
		    "instance of \"$class\": couldn't set read only attribute \"$name\"\n"
		;	
		croak $err if @_;
	    }
	    
	    my $data = $cf ? $class_data->{$class} : $self;

	    return $data->{$key};
	}
	    
    } else {
    
	$sub or $sub = sub () : lvalue {
	
	    my $self = shift || $_;
	    my $class = ref($self) || $self;

	    if ( ::RT_CHECKS ) { 
	        if ( $schema->{$class}->{SUBS}->{$name}->{TIED} ) {
		    unshift @_, $self;
		    goto $subs->{$sub}->{TIED_SUB};
		}
	    };
        
	    my $data = $cf ? $class_data->{$class} : $self;

	    $data->{$key} = shift if @_;
            
	    $data->{$key};
	};

    	if ( ::RT_CHECKS ) {
	    my $tref = tie my $tie, "Class::Root::tiescalar";
	    
	    $ties->{$tref} = {
		key => $key,
    		subname => $name,
    	    };

	    $tied_sub = sub () : lvalue {
		my $self = shift || $_;
		my $class = ref($self) || $self;
		
		$ties->{$tref}->{class} = $class;
		$ties->{$tref}->{hr} = $cf ? $class_data->{$class} : $self;
	    
		if ( @_ ) {
		    $tie = shift
		}

		$tie;
    	    };
	}
    }

    $accessors->{$akey} = $sub;
    return( $sub, $tied_sub );
}

declare new => class_method {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};
    $self->{$attr_init_done_key} = {};
    $self->{$base_init_done_key} = {};

    bless($self, $class);

    if ( ::RT_CHECKS ) {
	
	my $key = 0;
	foreach ( @_ ) {
	    $key ^= 1;
	    if ( $key and /^_/ ) {
		croak "constructor new: couldn't set private attribute \"$_\"\n";
	    }
	}
    }

    $self->init( @_ );

    return $self;
};

my $root_init = sub {
    my $self = shift;
    my $class = ref($self);
    
    my %args = ( @_ );

    while ( my($k,$v) = each %args ) {
        my $method = $k;
        unless ( $self->{$attr_init_done_key}->{$method} ) { 
            $self->{$attr_init_done_key}->{$method} = 1;
	    if ( ::RT_CHECKS ) {
		eval { $self->$method($v) };
		croak "Error calling method \"$method\" for instance of class \"$class\": $EVAL_ERROR\n" if $EVAL_ERROR;
	    } else {
		$self->$method($v);
	    }
	}
    }
};

declare init => method { goto $root_init };

declare base_init => method {
    my $self = shift;
    
    my $caller;
    if ( @_ and $_[0] =~ /^CALLER=(.*)/ ) {
        shift;
        $caller = $1;
    }

    unless ( defined $caller ) {
	$caller = caller();
	$caller =~ s/::LOCAL$//;
    }

    $self->{$base_init_done_key}->{$caller} = 1;

    my %attr_values = %{ $schema->{$caller}->{INSTANCE_ATTR_VALUES} };
    my @args = ( %attr_values );
    
    my $key = 0;
    my $prefix = prefix($caller);

    foreach ( @_ ) {
        my $attr = $_;
	
	$key ^= 1;
	$attr =~ s/^_/$prefix/ if $key;

        push @args, $attr;
    }
    
    my @caller_isa;
    
    { no strict 'refs';
        @caller_isa = @{ $caller."::ISA" };
    }
    
    my $not_seen_parents = 0;
    for my $parent ( @caller_isa ) {
	
        next if $self->{$base_init_done_key}->{$parent};

        if ( my $code = $parent->can("init") ) {
            $not_seen_parents++;
            $self->$code( @args );
        }
    }

    unless ( $not_seen_parents ) {
        $self->$root_init(@args);
    }
};

declare base_destroy => method {
    my $self = shift;
    
    my $caller;
    if ( @_ and $_[0] =~ /^CALLER=(.*)/ ) {
        $caller = $1;
    }

    unless ( defined $caller ) {
	$caller = caller();
	$caller =~ s/::LOCAL$//;
    }

    $self->{$base_destroy_done_key}->{$caller} = 1;
    
    my @caller_isa;
    
    { no strict 'refs';
        @caller_isa = @{ $caller."::ISA" };
    }
    
    for my $parent ( @caller_isa ) {
	
        next if $self->{$base_destroy_done_key}->{$parent};

        if ( my $code = $parent->can("DESTROY") ) {
            $self->$code;
        }
    }

};

my $root_class_init = sub {
    my $class = shift;
    
    my $cdata = $class_data->{$class};

    my %args = ( @_ );

    while ( my($k,$v) = each %args ) {
        my $method = $k;
        unless ( $cdata->{$attr_init_done_key}->{$method} ) { 
            $cdata->{$attr_init_done_key}->{$method} = 1;
	    if ( ::RT_CHECKS ) {
		eval { $class->$method($v) };
		croak "Error calling method \"$method\" for \"$class\": $EVAL_ERROR\n" if $EVAL_ERROR;
	    } else {
		$class->$method($v);
	    }
        }
    }
};

declare class_init => class_method { goto $root_class_init };

declare base_class_init => class_method {
    my $class = shift;
    my $cdata = $class_data->{$class};

    my $caller;
    if ( @_ and $_[0] =~ /^CALLER=(.*)/ ) {
        shift;
        $caller = $1;
    }
    
    unless ( defined $caller ) {
	$caller = caller();
	$caller =~ s/::LOCAL$//;
    }
    
    $cdata->{$base_init_done_key}->{$caller} = 1;

    my %attr_values = %{ $schema->{$caller}->{CLASS_ATTR_VALUES} };
    my @args = ( %attr_values );
    
    my $key = 0;
    my $prefix = prefix($caller);
	
    foreach ( @_ ) {
        my $attr = $_;

	$key ^= 1;	
	$attr =~ s/^_/$prefix/ if $key;

        push @args, $attr;
    }
    
    my @caller_isa;
    
    { no strict 'refs';
        @caller_isa = @{ $caller."::ISA" };
    }
    
    my $not_seen_parents = 0;
    for my $parent ( @caller_isa ) {

        next if $cdata->{$base_init_done_key}->{$parent};

        if ( my $code = $parent->can("class_init") ) {
            $not_seen_parents++;
            $class->$code( @args );
        }
    }

    unless ( $not_seen_parents ) {
        $class->$root_class_init(@args);
    }
    
};

declare class_schema_check => class_method {
    my $class = shift;
    
    return 1 unless ::CT_CHECKS;

    my $err = "";
    while( my($name, $mhr) = each %{ $schema->{$class}->{SUBS} } ) {
	
	#print $name, Dumper($mhr);

	my $flags = $mhr->{FLAGS};
	my $parent = $mhr->{PARENT};
	if ( $flags & VIRT and $parent ne $class ) {
	    $err .= "Virtual method \"$name\" defined in class \"$parent\" not implemented in derived class \"$class\"\n";
	}
    }
    
    if ( $err ) {
	croak $err;
    }

    return 1;
};


if ( ::CT_CHECKS ) {

    declare class_schema => class_method sub(){

	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $local_caller = caller();
	my $caller = cl2c($local_caller);
	
	$class = $caller unless defined $class;
    
	my $cschema = $schema->{$class};

	my $str = "";
	$str .= "class \"$class\" schema:\n";

	my $csubs = $cschema->{SUBS};
    
	my $class_attributes = "";
	my $attributes = "";
	my $class_methods = "";
	my $methods = "";
	
	foreach my $m ( sort keys %$csubs ) {
	    my $mhr = $csubs->{$m};

	    my $flags = $mhr->{FLAGS};
	    my $parent = $mhr->{PARENT};
	    my $priv = $flags & PRIV;
	    my $prot = $flags & PROT;

	    next if ( $priv and !$prot and $parent ne $class );
    
	    my $mflags = "";
	    if ( $priv and !$prot ) {
		$mflags = "priv";
		my $prefix = prefix($class);
		$m =~ s/^$prefix/_/;
	    }

	    if ( $prot ) {
		$mflags = "prot";
		my $prefix = prefix($class);
		next unless ( $m =~ /^$prefix/ );
		$m =~ s/^$prefix/_/;
	    }

	    if ( $flags & VIRT ) {
		$mflags = "virt";
	    }

	    if ( $flags & RO and !$priv ) {
		$mflags = "ro";
	    }

	    my $r;
	    $r = \$attributes if $flags & AF;
	    $r = \$class_attributes if ( $flags & CF and $flags & AF);
	    $r = \$methods if $flags & MF;
	    $r = \$class_methods if ( $flags & CF and $flags & MF);

	    $$r .= sprintf "%4s%-20s%-10s%s\n", "", $m, $mflags, $parent;
    
	}
    
	$str .= "  class attributes:\n";
	$str .= $class_attributes;
    
	$str .= "  attributes:\n";
	$str .= $attributes;

	$str .= "  class methods:\n";
	$str .= $class_methods;

	$str .= "  methods:\n";
	$str .= $methods;
    
	return $str;
    };

    my $dump = sub {

	my $proto = shift;
	my $o_dump = ref($proto) ? 1 : 0;
	my $class = ref($proto) || $proto;
    
	my $str = $o_dump ? "instance \"$proto\"" : "class \"$class\"";
	$str .= " dump:\n";

	my $self = $o_dump ? $proto : $class;
    
	my $hr = {};

	my $cschema = $schema->{$class};

	my $csubs = $cschema->{SUBS};

	foreach my $m ( keys %$csubs ) {
	    my $mhr = $csubs->{$m};

	    my $flags = $mhr->{FLAGS};
	    my $parent = $mhr->{PARENT};
	    my $priv = $flags & PRIV;
	    my $prot = $flags & PROT;
	    
	    next unless ( $flags & AF );

	    next if ( $o_dump and $flags & CF );
	    next if ( !$o_dump and !($flags & CF) );
	    next if ( $priv|$prot and $parent ne $class );

	    my $nm = $m;
	    if ( $priv|$prot ) {
		my $prefix = prefix($class);

		$nm =~ s/^$prefix/_/;
	    }
	    
	    no strict 'refs';
	    $hr->{$nm} = $self->$m;

	}
    
	local $Data::Dumper::Indent = 1;
	local $Data::Dumper::Sortkeys = 1;
	my $dumper = Dumper( $hr );
	my @lines = split "\n", $dumper;
	my @less_lines = @lines[1..$#lines-1];
    
	$str .= join "\n", @less_lines;
	$str .= "\n" if scalar(@less_lines);
    
	return $str;
    };

    declare instance_dump => method {
	my $self = shift;
	my $class = ref($self);

	return $dump->($self);
    };

    declare class_dump => class_method {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return $dump->($class);
    };

}

1; # End of Class::Root

__END__

=head1 SYNOPSIS

I<Class::Root> provides a compact syntax for creating OO classes in perl. 

I<Class::Root> supports:

=over 4

=item

- I<public>, I<private>, I<protected> and I<virtual> methods  

- I<class> and I<instance> attributes with generated accessor methods

- I<multiple inheritance>

- ...more...

=back

I<Class::Root> restricts developer requiring all methods and attributes to be defined using it's I<declare> statement, but in return I<Class::Root> ensures the correctness of the resulting class schema.
Thus a problem of two base classes having a method with the same name will be detected at compile time.

Some optional checks may be defined to prove attribute values at run time.

Both I<run time> and I<compile time> checks could be disabled for better performance of production code.

B<DESCRIPTION> section below explains how Class::Root works, and what makes it different from other modules with similar purposes available on CPAN.  

    package Foo;

    # Class::Root's import method takes care of @ISA array.
    use Class::Root "isa";
    
    # switch to Foo's "LOCAL" namespace.
    package Foo::LOCAL;

    # now we can import some usefull functions without affecting Foo's inheritable namespace.  
    use Some::Module qw( humpty dumpty );

    # public class atribute with default value
    declare class_attribute favorite_color => 'red';
	
    # private attribute name always begins with "_"
    declare private class_attribute _top_secret => 'QwErTy';

    # declaring a readonly attribute also generates a corresponding 
    # writable private attribute (_population in this case)
    declare readonly class_attribute population => 0;

    my $derived_class_counter = -1;

    # declare class method
    declare get_foo_dcc => class_method {
	my $class = shift;
	return $derived_class_counter;
    }

    # optional class_init method could be used for additional construction code
    declare overwrite class_init => class_method {
	my $class = shift;
	
	# base_class_init method should be called in place of SUPER::class_init
	# it cares of default values and multiple inheritance
	$class->base_class_init( @_ );

	# custom class construction code
	$derived_class_counter++;
    }

    # class constructor should be called once after all class_attributes were declared
    class_initialize( _top_secret => 'AsDfGh', favorite_color => 'magenta' );

    # instance attribute with default value and check_value function
    declare attribute a10 => setopts {
	value => 15,
	check_value => sub {
	    return "should be integer value" unless /^\d+$/;
	    return "10 < a10 < 25" if ( $_ le 10 or 25 le $_ );
	    "";
	},
    };
    
    # attributes accessors can be used with argument or as lvalue
    Foo->favorite_color = 'blue';
    Foo->favorite_color('green');

    # it is possible to declare multiple attributes and methods in single declare statement
    declare
	attribute a1 => 1,
	private attribute _priv_a2 => 2,
	protected attribute _prot_a3 => 3,
	protected readonly attribute prot_ro_a4 => 4,
	m1 => method { $self = shift; return $self->X2 - $self->X1 },
	_pm2 => private method { <method implementation here> },
	vm3 => virtual method;

    # declare 'NAME' generates an instance attribute NAME
    declare 'a1';

    # declare with out arguments just do nothing
    declare;

    # Class::Root provides a constructor "new"
    # customizable "init" method may be used to add additional construction code 

    declare overwrite init => method {
	my $self = shift;
	
	# "base_init" method should be used in place of SUPER::init
	# it cares of multiple inheritance and initial values
	$self->base_init( 
	    _id => $self->_ID_COUNTER++,
	    @_,
	);

	# custom construction code
	$self->_population++;
    };

    # optional instance destructor 
    declare DESTROY => method {
	my $self = shift;

	$self->_population--;

	# base_destroy method calls DESTROY methods from all parent classes 
	# in case of single parent it is equivalent to SUPER::DESTROY

	$self->base_destroy;
    };

    # class_verify checks the class schema last time ( Are all virtual methods implemented? )
    # we use it in the last code line and it returns true value if no errors were found, so
    # we don't need "1;" at the end of our module.    

    class_verify;

Class I<Bar> derives from class I<Foo>:

    package Bar;

    use Foo "isa";
    
    # switch to Bar's LOCAL namespace
    package Bar::LOCAL;

    use strict;
    use warnings;

    our (@ISA, @EXPORT, @EXPORT_OK);

    # we can use the standard Exporter module or define own import function in Bar::LOCAL package 
    use Exporter;
    @ISA = qw(Exporter);
    @EXPORT      = qw( humpty dumpty );       # Symbols to autoexport (:DEFAULT tag)
    @EXPORT_OK   = qw( rikki tikki );       # Symbols to export on request
    
    # change default value fo defined attribute
    declare setvalue favorite_color => "yellow";

    # change default value and check_value function 
    declare setopts a10 => {
	value => 23,
	check_value => sub {
	    return "should be integer value" unless /^\d+$/;
	    return "20 < a10 < 25" if ( $_ le 20 or 25 le $_ );
	    "";
	},
    };
    
    # call class constructor
    class_initialize;
    
    # check class schema
    class_verify;

Our main program use module Bar:

    # we can disable run time and also compile time checks in production code, after we know that it works
    use constant RT_CHECKS => 0;
    use constant CT_CHECKS => 0;

    # with out "isa" argument the import function from Bar::LOCAL package - if any exists - will be called
    use Bar;

    # constructor new defined in Class::Root
    my $bar1 = Bar->new( a1 => 100, a10 => 24 );

See also a working example with multiple inheritance in the B<EXMAPLE> section below. 

=head1 DESCRIPTION

We start writing code for class based on I<Class::Root> with something like this:

    1: package MyClass::Foo;
    2: use Class::Root "isa";
    3: package MyClass::Foo::LOCAL;

Line 1: is usual, here we define a name of our class.

Line 2: compiles I<Class::Root> and invokes Class::Root's I<import> method with argument "isa".
With "isa" argument found, method I<import> adds Class::Root to @MyClass::FOO::ISA array
and imports some functions into MyClass::Foo:LOCAL package. 

=head2 LOCAL NAMESPACE

In line 3: we switch to MyClass::Foo's LOCAL namespace.

The reason for doing that is following. We want to protect Foo's inheritable namespace from getting
dirty. Otherwise if we import some module such as I<Data::Dumper> we get a I<Dumper> method in our class. It is potentially dangerous, sappose that one of Foo's base classes really have a method with the name I<Dumper> and it's code already contains $self->Dumper. Being invoked with instance of Foo, the Dumper function from Data::Dumper will be used, and this is unlikelly to be correct.

Importing modules into LOCAL namespace avoids this problem. And we also get an opportunity to distinguish between methods and functions. We define methods in Foo package and we define functions in Foo::LOCAL package. 

Class::Root itself use this technique. For example I<declare> function defined in Class::Root::LOCAL package will not be inherited by Class::Root's derived classes. 

=head2 declare

=head3 attribute, class_attirbute

=head3 method, class_method

=head3 private

=head3 protected

=head3 readonly

=head3 overwrite, override

=head3 setopts, setoptions

=head3 setval, setvalue

=head2 CLASS CONSTRUCTOR

=head3 class_initialize

=head3 class_init

=head3 base_class_init

=head2 CONSTRUCTOR

=head3 new

=head3 init

=head3 base_init

=head2 DESTRUCTOR

=head3 DESTROY

=head3 base_destroy

=head2 class_verify

=head2 class_schema

=head2 class_dump

=head2 instance_dump

=head2 import

=head1 EXAMPLE
	
		  -----------
		 |Class::Root|
		  -----------
	               |
		       V
		 ------------
		|MyClass::Foo|
	         ------------	
		   /       \
		  V_       _V
         ------------    ------------
	|MyClass::Bar|	|MyClass::Baz|
	 ------------    ------------  
	          \         /
	          _V       V_
                 ------------
	        |MyClass::Hoo|
		 ------------

File MyClass/Foo.pm:

    package MyClass::Foo;

    # MyClass::Foo derives from  Class::Root
    use Class::Root "isa";

    # switch to our "LOCAL" namespace 
    package MyClass::Foo::LOCAL;

    use strict;
    use warnings;

    # declare class attribute with default value
    declare class_attribute cname => "Foo";

    # private attribute names always begin with "_"
    declare private class_attribute _ID => 0;   

    # declaring a readonly attribute also generates a corresponding writable private attribute (_population in this case)
    declare readonly class_attribute population => 0;

    # class constructor should be called after all declarations of class attributes
    # here all class attributes get there default values

    class_initialize;

    # declare instance attribute with default value
    declare attribute foos => "FOOS";

    # declare instance attribute with out default value
    declare favorite_color => attribute;

    # declare readonly instance attribute
    declare id => readonly attribute;

    # and again corresponding private writable attribute "_id" will be generated 

    my $foo_population = 0;

    # declare class method
    declare foo_population => class_method {
	return $foo_population;
    };

    # Class::Root provides a constructor "new"
    # Customizable "init" method may be used to add additional construction code 

    declare overwrite init => method {
	my $self = shift;
	
	# "base_init" method should be used in place of SUPER::init
	# it cares of multiple inheritance and initial values

	$self->base_init( 
	    _id => $self->_ID++,
	    @_,
	);

	# all attribute accessors are lvalue subroutines
	$self->_population++;

	$foo_population++;
    };

    # declare instance destructor 
    declare DESTROY => method {
	my $self = shift;

	$self->_population--;
	$foo_population--;

	# base_destroy method calls DESTROY methods from all parent classes 
	# in case of single parent it is equivalent to SUPER::DESTROY

	$self->base_destroy;
    };

    # class_verify checks the class schema last time ( Are all virtual methods implemented? )
    # we use it in the last code line and it returns true value if no errors were found, so
    # we don't need "1;" at the end of our module.    

    class_verify;
	
File MyClass/Bar.pm:

    package MyClass::Bar;

    # MyClass::Bar derives from MyClass::Foo
    use MyClass::Foo "isa";

    # switch to Bar's "LOCAL" namespace 
    package MyClass::Bar::LOCAL;

    use strict;
    use warnings;

    # change initial value for class attribute "cname" declared in Foo  
    declare setvalue cname => "Bar";

    # call class constructor
    class_initialize;

    # declare instance attribute
    declare attribute bars => "BARS";

    # declare private attribute
    declare _bars_secret => private attribute;

    # declare instance method
    declare get_bars_secret => method {
	my $self = shift;
	return $self->_bars_secret;
    };

    my $bar_population = 0;

    # declare class method
    declare bar_population => class_method {
	return $bar_population;
    };

    declare overwrite init => method {
	my $self = shift;
	$self->base_init( @_ );
	
	$bar_population++;
	
	$self =~ /0x([0-9a-f]+)/;
	$self->_bars_secret = "BAR:$1";
    };

    declare overwrite DESTROY => method {
	my $self = shift;    
	$bar_population--;
	$self->base_destroy;
    };

    class_verify;

Here another class, which derives from MyClass::Foo

File MyClass/Baz.pm:

    package MyClass::Baz;

    # MyClass::Baz also derives from MyClass::Foo
    use MyClass::Foo "isa";

    # switch to Bar's "LOCAL" namespace 
    package MyClass::Baz::LOCAL;

    use strict;
    use warnings;

    # change initial value for class attribute "cname" declared in Foo  
    declare setvalue cname => "Baz";

    # call class constructor
    class_initialize;

    # declare instance attribute
    declare attribute bazs => "BAZS";

    # declare private attribute
    declare _bazs_secret => private attribute;

    # declare instance method
    declare get_bazs_secret => method {
	my $self = shift;
	return $self->_bazs_secret;
    };

    my $baz_population = 0;

    # declare instance method
    declare baz_population => method {
	return $baz_population;
    };

    declare overwrite init => method {
	my $self = shift;
	$self->base_init( @_ );
	
	$baz_population++;
	
	$self->_bazs_secret = "BAZ:" . (int( rand(1000) )+1000);
    };

    declare overwrite DESTROY => method {
	my $self = shift;    
	$baz_population--;
	$self->base_destroy;
    };

    class_verify;

Class MyClass::Hoo derives from both MyClass::Bar and MyClass::Baz

File MyClass/Hoo.pm:

    package MyClass::Hoo;

    use MyClass::Bar 'isa';
    use MyClass::Baz 'isa';

    package MyClass::Hoo::LOCAL;

    use strict;
    use warnings;

    declare setvalue cname => "Hoo";

    class_initialize;

    declare attribute hoos => "HOOS";

    class_verify;

File main.pl:

    #!perl

    use MyClass::Foo;
    use MyClass::Bar;
    use MyClass::Baz;
    use MyClass::Hoo;

    my $foo1 = MyClass::Foo->new(favorite_color => "green");
    my $bar1 = MyClass::Bar->new(favorite_color => "blue");
    my $bar2 = MyClass::Bar->new(favorite_color => "blue2");
    my $baz1 = MyClass::Baz->new(favorite_color => "red");
    my $baz2 = MyClass::Baz->new(favorite_color => "red2");
    my $baz3 = MyClass::Baz->new(favorite_color => "red3");
    my $hoo1 = MyClass::Hoo->new(favorite_color => "white");
    my $hoo2 = MyClass::Hoo->new(favorite_color => "white2");
    my $hoo3 = MyClass::Hoo->new(favorite_color => "white3");
    my $hoo4 = MyClass::Hoo->new(favorite_color => "white4");

    print "foo1->population: ", $foo1->population, "\n";
    print "bar1->population: ", $bar1->population, "\n";
    print "baz1->population: ", $baz1->population, "\n";
    print "hoo1->population: ", $hoo1->population, "\n";

    print "hoo1->foo_population: ", $hoo1->foo_population, "\n";
    print "hoo1->bar_population: ", $hoo1->bar_population, "\n";
    print "hoo1->baz_population: ", $hoo1->baz_population, "\n";
    print "hoo1->get_bars_secret: ", $hoo1->get_bars_secret, "\n";
    print "hoo1->get_bazs_secret: ", $hoo1->get_bazs_secret, "\n";

    print "hoo1->id: ", $hoo1->id, "\n";
    print "hoo2->id: ", $hoo2->id, "\n";
    print "hoo3->id: ", $hoo3->id, "\n";
    print "hoo4->id: ", $hoo4->id, "\n";

    print "hoo3->class_schema:\n", $hoo3->class_schema;
    print "hoo3->class_dump:\n", $hoo3->class_dump;
    print "hoo3->instance_dump:\n", $hoo3->instance_dump;

Here is the output from main.pl:

    foo1->population: 1
    bar1->population: 2
    baz1->population: 3
    hoo1->population: 4
    hoo1->foo_population: 10
    hoo1->bar_population: 6
    hoo1->baz_population: 7
    hoo1->get_bars_secret: BAR:818a1f0
    hoo1->get_bazs_secret: BAZ:1831
    hoo1->id: 0
    hoo2->id: 1
    hoo3->id: 2
    hoo4->id: 3
    hoo3->class_schema:
    class "MyClass::Hoo" schema:
      class attributes:
	cname                         MyClass::Foo
	population          ro        MyClass::Foo
      attributes:
	bars                          MyClass::Bar
	bazs                          MyClass::Baz
	favorite_color                MyClass::Foo
	foos                          MyClass::Foo
	hoos                          MyClass::Hoo
	id                  ro        MyClass::Foo
      class methods:
	bar_population                MyClass::Bar
	base_class_init               Class::Root
	class_dump                    Class::Root
	class_init                    Class::Root
	class_schema                  Class::Root
	class_schema_check            Class::Root
	foo_population                MyClass::Foo
	import                        Class::Root
	new                           Class::Root
      methods:
	DESTROY                       MyClass::Bar
	base_destroy                  Class::Root
	base_init                     Class::Root
	baz_population                MyClass::Baz
	get_bars_secret               MyClass::Bar
	get_bazs_secret               MyClass::Baz
	init                          MyClass::Bar
	instance_dump                 Class::Root
    hoo3->class_dump:
    class "MyClass::Hoo" dump:
      'cname' => 'Hoo',
      'population' => 4
    hoo3->instance_dump:
    instance "MyClass::Hoo=HASH(0x818a3ac)" dump:
      'bars' => 'BARS',
      'bazs' => 'BAZS',
      'favorite_color' => 'white3',
      'foos' => 'FOOS',
      'hoos' => 'HOOS',
      'id' => 2

=head1 SEE ALSO

Several interesting modules included in perl distribution or available on CPAN address similar problems.  

L<fields>, L<Class::Struct>, L<Class::Generate>, L<Class::Contract>, L<Class::Declare>.

=head1 AUTHOR

Evgeny Nifontov, C<< <classroot@nifsa.de> >>

=head1 BUGS

I<Class::Root> is still very young, so it probably has some bugs.

Please report any bugs or feature requests to
C<bug-class-root at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Root>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Root

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-Root>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-Root>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Root>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-Root>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Evgeny Nifontov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
