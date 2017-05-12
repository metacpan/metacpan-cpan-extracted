package AutoCode::Root0;
use strict;
our $VERSION='0.01';
our $DEBUG;
our $debug;
sub import {

}

sub new {
    
    my ($class, @args)=@_;
    my $self={};
    bless $self, ref($class)||$class;
    $self->_initialize(@args);
    return $self;
    
}

sub _initialize {
    my ($self, @args)=@_;
    $self->{DEBUG_HINTS_SLOT} = {};
}

sub _rearrange {
    my $dummy = shift;
    my $order = shift;

    return @_ unless (substr($_[0]||'',0,1) eq '-');
    push @_,undef unless $#_ %2;
    my %param;
    while( @_ ) {
        (my $key = shift) =~ tr/a-z\055/A-Z/d; #deletes all dashes!
        $param{$key} = shift;
    }
    map { $_ = uc($_) } @$order; # for bug #1343, but is there perf hit here?
    return @param{@$order};
}

sub _load_module {
    my ($self, $name) = @_;
    my ($module, $load, $m);
    $module = "_<$name.pm";
    return 1 if $main::{$module};

    # untaint operation for safe web-based running (modified after a fix
    # a fix by Lincoln) HL
    if ($name !~ /^([\w:]+)$/) {
        $self->throw("$name is an illegal perl package name");
    }

    $load = "$name.pm";
#    my $io = Bio::Root::IO->new();
    # catfile comes from IO
#    $load = $io->catfile((split(/::/,$load)));
    $load=join('/', split(/::/, $load));
    eval {
        require $load;
    };
    if ( $@ ) {
        die "Failed to load module $name. ".$@."\n";
#        $self->throw("Failed to load module $name. ".$@);
    }
    return 1;
}

our @DEBUG_HINTS=qw(enable verbosity);
use constant DEBUG_HINTS_SLOT => '_DEBUG_HINTS';
sub debug_hints {
    my $self=shift;
    my %hints = %{$self->{DEBUG_HINTS_SLOT}};
    my ($enable, $verbosity)=$self->_rearrange([qw(ENABLE VERBOSITY)], @_);
    defined $enable and $hints{enable}=$enable;
    defined $verbosity and $hints{verbosity}=$verbosity;
#    if(%args){
#        $hints{$_}=$args{$_} if grep /$_/, @DEBUG_HINTS foreach(keys %args);
#    }
    return %hints;
}

sub debug {
    my $self=shift;
#    return unless($self->{DEBUG_HINTS_SLOT}->{enable});
    
    return unless $debug;
    my $pkg=caller;
    print STDERR "In $pkg, @_\n";
}

sub throw {
    my ($self, $string)=@_;
    my $out ="\n". '-'x20 . ' EXCEPTION '. '-'x20 . "\n";
    $out .= "MSG: $string\n";
    $out .= $self->stack_trace_dump .'-'x51 ."\n";
    die $out;
}

sub warn {
    my ($self, $msg)=@_;
    my $out="\n". '-'x20 . ' WARNING '. '-'x20 . "\n";
    $out .= "MSG: $msg\n";
    $out .= '-'x51 ."\n";
    print STDERR $out;
}

sub stack_trace_dump {
    my $self=shift;
    my @stack=$self->stack_trace;
    eval{
        #<< x 3;
        shift @stack;
        shift @stack;shift @stack;
    };
    my $out;
    my ($module, $function, $file, $position);
    map {
        ($module, $function, $file, $position)=@$_;
        $out.= "STACK $function $file:$position\n";
    } @stack;
    return $out;
}

sub stack_trace {
    my $self=shift;
    my $i=0;
    my @out=();
    my $prev=[];
    while(my @call=caller($i++)){
        $prev->[3]=$call[3];
        push(@out, $prev);
        $prev=\@call;
    }
    $prev->[3]='toplevel';
    push @out, $prev;
    return @out;
}

sub _not_implemented_msg {
    my $self=shift;
    my $pkg=ref $self;
    my $method=(caller(1))[3];
    my $msg="Abstract method [$method] is not implemented by package $pkg.\n";
    return $msg;
}

sub throw_not_implemented {
    my $self=shift;
    $self->throw($self->_not_implemented_msg);
}

sub warn_not_implemented {
    my $self=shift;
    $self->warn($self->_not_implemented_msg);
}

1;
