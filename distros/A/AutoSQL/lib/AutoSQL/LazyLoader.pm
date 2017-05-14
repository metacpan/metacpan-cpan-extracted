package AutoSQL::LazyLoader;
use strict;
use AutoCode::AccessorMaker;
our @ISA=qw(AutoCode::AccessorMaker);

use AutoCode::SymbolTableUtils;

sub import {
    my ($class, @args)=@_;
    my $self=$class->new;
    my $caller=ref(caller)||caller;
    my %args=@args;
    if (exists $args{'$'}){
        my $scalar_accessors=$args{'$'};
        foreach(@$scalar_accessors){
            $self->make_scalar_loader($_, $caller);
        }
    }
}

sub make_scalar_loader {
    my $self=shift;
    my ($accessor, $pkg, $typeglob, $slot) = $self->__accessor_to_glob(@_);
    no strict 'refs';
    *$typeglob=sub{
        my $self=shift;
        return $self->{$slot}=shift if @_;
        
        $self->{"_load_$accessor"} unless(defined $self->{$slot});
        return $self->{$slot};
    };
    *{"$pkg\::_load_$accessor"}=sub{
        my $self=shift;
        $self->throw("Must be of AutoSQL::DBObject") 
            unless $self->isa('AutoSQL::DBObject');

        my $dbid = $self->dbid;
        my $adaptor = $self->adaptor;
        my $method="only_fetch_$accessor\_by_dbid";
        my $val = $adaptor->$method ($dbid);
        $self->{$slot}= $val;
        return $val;
    };
    
}


1;

__END__

=pod

=head1 NAME

AutoSQL::LazyLoader

=head1 SYNOPSIS

    package A::DBObject;
    our @ISA=qw(AutoSQL::Object);
    use AutoSQL::Object;
    use AutoSQL::LazyLoader('$' => [qw(seq)]);



=head1 DESCRIPTION

Like AutoCode::AccessorMaker, the module generates the methods in the Perl's
symbol table during compile or run-time.



=head1 AUTHOR

Juguang Xiao, juguang at tll.org.sg

=head1 COPYRIGHT

This module is a free software.
You may copy or redistribute it under the same terms as Perl itself.

=cut


