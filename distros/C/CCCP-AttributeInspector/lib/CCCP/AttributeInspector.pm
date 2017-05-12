package CCCP::AttributeInspector;

use strict;
use warnings;

our $VERSION = '0.01';

# singleton
my $pm = undef;

sub __pm_new {
    $pm ? $pm : ($pm = bless({},__PACKAGE__));
}

sub __internal_resolv {
    my ($obj,$class) = @_;
    
    return if exists $obj->{'__internal_resolv'}->{$class};
    
    no strict 'refs';
        $obj->{'__all_methods'}->{$class} = [grep {defined &{"${class}::$_"}} keys %{sprintf('%s::',$class)}];
        map {
            if (exists $obj->{$class}->{\&{"${class}::$_"}}) {
                $obj->{$class}->{$_} = delete $obj->{$class}->{\&{"${class}::$_"}}; 
            }
        } @{$obj->{'__all_methods'}->{$class}};            
    use strict 'refs';
    
    $obj->{'__internal_resolv'}->{$class}++;
        
    return;
}

sub all_methods {
    my ($class) = @_;
    
    return unless $class;    
    $class = ref $class if ref $class;
      
    my $obj = __PACKAGE__->__pm_new();
    
    return wantarray() ? () : [] unless exists $obj->{$class};
    
    $obj->__internal_resolv($class); 
    
    return wantarray() ? @{$obj->{'__all_methods'}->{$class}} : $obj->{'__all_methods'}->{$class};
}

sub att_methods {
    my ($class,$att_list) = @_;
    
    return unless $class;    
    $class = ref $class if ref $class;
      
    my $obj = __PACKAGE__->__pm_new();
    
    return wantarray() ? () : [] unless exists $obj->{$class};
    
    $obj->__internal_resolv($class); 
    
    unless ($att_list) {    
        return wantarray() ? keys %{$obj->{$class}} : [keys %{$obj->{$class}}];
    } elsif (ref $att_list eq 'HASH') {
        my @ret = grep {
            my $meth = $_;
            my $good = 1;
            foreach (keys %$att_list) {
                unless (exists $obj->{$class}->{$meth}->{$_} and $obj->{$class}->{$meth}->{$_} eq $att_list->{$_}) {
                    $good = 0;
                    last; 
                };
            };
            $good;
        } keys %{$obj->{$class}};
        return wantarray() ? @ret : [@ret];
    } elsif (ref $att_list eq 'ARRAY') {
        my @ret = grep {
            my $meth = $_;
            my $good = 1;
            foreach (@$att_list) {
                unless (exists $obj->{$class}->{$meth}->{$_}) {
                    $good = 0;
                    last; 
                };
            };
            $good;
        } keys %{$obj->{$class}};
        return wantarray() ? @ret : [@ret];
    };
}

sub get_attributes {
    my ($class,$method) = @_;
    
    return {} unless ($class and $method and not ref $method);
    $class = ref $class if ref $class;
    
    my $obj = __PACKAGE__->__pm_new();
    return {} unless (exists $obj->{$class});  
    
    $obj->__internal_resolv($class);
    
    return exists $obj->{$class}->{$method} ? $obj->{$class}->{$method} : {}; 
}

sub packages {
    my $obj = __PACKAGE__->__pm_new();
    return wantarray() ? keys %$obj : [keys %$obj];
}

sub MODIFY_CODE_ATTRIBUTES {
    my ($class, $code, @attrs) = @_;
    return () unless @attrs;
    
    my $obj = __PACKAGE__->__pm_new();
    
    foreach (@attrs) {
        /(\w+)\((['"]?)/;        
        my $quote = $2 || '';        
        my ($attr_name,$undef,$attr_value) = $_ =~ /(\w+)(\($quote(.*)$quote\))?/;        
        $obj->{$class}->{$code}->{$attr_name} = $attr_value || '';
    };
        
    return ();
}


1;
__END__

=encoding utf-8

=head1 NAME

B<CCCP::AttributeInspector> - show list methods and attributes from package

=head1 SYNOPSIS

	package Bar;
	use base qw[CCCP::AttributeInspector];
	sub new {}
	sub bar_method1 :Chain :CustomBar('any_custom') {}
	sub bar_method2 :CustomBar :AbsPath('/some/abs/path') {}
	1;
    
    # ------------------
    
	package Foo;
	use base qw[CCCP::AttributeInspector];
	sub new {}
	sub foo_method1 :Local :Custom('any_custom') {}
	sub foo_method2 :Private :Custom('some_attribute') {}
	1;    
    
    # ------------------
    
    package SomeDispatcher;
    use Foo;
    use Bar;
    
    my @methods = Foo->all_methods();
	#  'foo_method1'
	#  'foo_method2'
	#  'new'

	@methods = Foo->att_methods();
	#  'foo_method1'
	#  'foo_method2'    
    
	@methods = Bar->all_methods()
	#  'bar_method2'
	#  'bar_method1'
	#  'new'
    
    @methods = Bar->att_methods()
	#  'bar_method2'
	#  'bar_method1'
    
	@methods = Bar->att_methods(['Chain','CustomBar'])
    #  'bar_method1'
    
	@methods =  Bar->att_methods(['CustomBar'])
	#  'bar_method2'
    #  'bar_method1'   
    
	@methods =  Bar->att_methods({'AbsPath' => '/some/abs/path'})
	#  'bar_method2'
    
	my $att_list =  Bar->get_attributes('bar_method2')
	#  HASH(0xf126f0)
	#   'AbsPath' => '/some/abs/path'
	#   'CustomBar' => ''    

=head1 DESCRIPTION

Attributes is a perfect technology for defined context on your methods. 
This is be very comfortable for implementation any dispatcher or logic controller. 

=head2 METHODS

=head3 all_methods

Return all methods from package (except any base-package methods).

Return array or array reference depend on call-context. 

=head3 att_methods($param)

If $param is false (or not defined), method return all name methods who have any attributes.
If $param is array reference with list attributes name, method return all name methods who have this attributes.
If $param is hash reference with attributes name and attributes value, method return all name methods who have such attributes.

Return array or array reference depend on call-context.

=head3 get_attributes($name_method)

Return hash freference with attributes and their value.

=head3 packages

Return list package name who have CCCP::AttributeInspector as base class.

=head1 AUTHOR

Ivan Sivirinov

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
