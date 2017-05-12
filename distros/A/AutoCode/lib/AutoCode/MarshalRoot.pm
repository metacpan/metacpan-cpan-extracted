package AutoCode::MarshalRoot;
use strict;
use AutoCode::Root;
our @ISA=qw(AuotCode::Root);

sub import {
    my ($class, $selector)=@_;
    my $caller = caller;
    no strict 'refs';
    push @{"$caller\::ISA"}, __PACKAGE__ ;
    ${"$caller\::marshal_module"}=$caller;
}

sub new {
    my ($caller, @args)=@_;
    my $class=ref($caller)||$caller;
    no strict 'refs';
    my $marshal=${"$class\::marshal_module"};
    my $selector=${"$call\::selector"};
    use strict 'refs';
    if($class =~ /$marshal::(\S+)/){
        my $self=$class->SUPER::new(@args);
        $self->_initialize(@args);
        return $self;
    }else{
        my %params = @args;
        @params{map{lc $_}keys $params}=values %params;
        my $private = $params{$selector}||$params{"-$selector"};
        $private ||= $class->_guess_private(@args);
        $class->throw("Unknown $selector given") unless $private;
        my $private_module="$marshal\::$private";
        return undef unless($class->_load_module($private_module);
        return $private_module->new(@args);
    }
}

1;
__END__

1;


