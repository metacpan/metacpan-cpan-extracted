package Class::Variable;
use 5.008;
use strict; use warnings FATAL => 'all'; 
use Exporter 'import';
use Carp;
use Scalar::Util 'weaken';

our $VERSION = '1.002'; # <== update version in pod

our @EXPORT;

my $NS = {};

push @EXPORT, 'public';
sub public($;)
{
    my @names = @_;
    my $package = (caller)[0];
    foreach my $name (@names)
    {
        no strict 'refs';
        *{$package.'::'.$name } = get_public_variable($package, $name);
    }
}

push @EXPORT, 'protected';
sub protected($;)
{
    my @names = @_;
    my $package = (caller)[0];
    foreach my $name (@names)
    {
        no strict 'refs';
        *{$package.'::'.$name } = get_protected_variable($package, $name);
    }
}

push @EXPORT, 'private';
sub private($;)
{
    my @names = @_;
    my $package = (caller)[0];
    foreach my $name (@names)
    {
        no strict 'refs';
        *{$package.'::'.$name } = get_private_variable($package, $name);
    }
}

sub get_public_variable($$)
{
    my( $package, $name ) = @_;
    
    return sub: lvalue
    {
        my $self = shift;
        if( 
            not exists $NS->{$self}
            or not defined $NS->{$self}->{' self'} 
        )
        {
            $NS->{$self} = {
                ' self' => $self
            };
            weaken $NS->{$self}->{' self'};
        }
        
        $NS->{$self}->{$name};
    };
}

sub get_protected_variable($$)
{
    my( $package, $name ) = @_;
    
    return sub: lvalue
    {
        my $self = shift;
        if( 
            not exists $NS->{$self}
            or not defined $NS->{$self}->{' self'} 
        )
        {
            $NS->{$self} = {
                ' self' => $self
            };
            weaken $NS->{$self}->{' self'};
        }
        
        croak sprintf(
            "Access violation: protected variable %s of %s available only to class or subclasses, but not %s."
            , $name || 'undefined'
            , $package || 'undefined'
            , caller()  || 'undefined' ) if not caller()->isa($package);
            
        $NS->{$self}->{$name};
    };
}

sub get_private_variable($$)
{
    my( $package, $name ) = @_;
    
    return sub: lvalue
    {
        my $self = shift;
        if( 
            not exists $NS->{$self}
            or not defined $NS->{$self}->{' self'} 
        )
        {
            $NS->{$self} = {
                ' self' => $self
            };
            weaken $NS->{$self}->{' self'};
        }
        
        croak sprintf(
            "Access violation: private variable %s of %s available only to class itself, not %s."
            , $name || 'undefined'
            , $package || 'undefined'
            , caller()  || 'undefined' ) if caller() ne $package;
            
        $NS->{$self}->{$name};
    };
}


1;
__END__
=head1 NAME

Class::Variable - Perl implementation of class variables with access restrictions.

=head1 VERSION

Version 1.002

=head1 SYNOPSIS

This module allows You to create class members with access restrictions, using intuitive syntax:

    package Foo;
    use Class::Variable;
    
    public      'var1', 'var2';   # these variables available everywhere 
    protected   'var3', 'var4';   # these variables available only in objects of Foo class or subclasses
    private     'var5', 'var6';   # these variables available only in objects of Foo class 
    
meanwhile somewhere else ...
    
    use Foo;
    
    my $foo = Foo->new();
    
    $foo->var1 = "Public var content";      # works fine
    $foo->var3 = "Protected var content";   # croaks, protected
    $foo->var5 = "Private var content";     # croaks, private
    
All generated class variables are actually lvalue methods and can be inherited by subclasses.
    
=head1 DESCRIPTION

Module exports three methods, required to define variables: C<public>, C<protected> and C<private>.

Internally, there is a namespace variable in C<Class::Variable> package, which is not available from the outside and contains all data per object, using weak references to avoid duplicated references (not sure if it's possible). 

Generated class variables are lvalue subs with access control in them.

Don't forget, that data from generated variables is not encapsulated in object and can't be serialized.

=head1 BENCHMARKS

Here is a comparision of direct acces to hash elements and access to generated variables:

    1. Direct write    :  1 wallclock secs ( 0.58 usr +  0.00 sys =  0.58 CPU) @ 17331022.53/s (n=10000000)
    2. Direct read     :  1 wallclock secs ( 0.56 usr +  0.00 sys =  0.56 CPU) @ 17793594.31/s (n=10000000)
    3. Public write    : 11 wallclock secs (10.36 usr +  0.00 sys = 10.36 CPU) @ 965437.34/s (n=10000000)
    4. Public read     : 10 wallclock secs (10.37 usr +  0.00 sys = 10.37 CPU) @ 963948.33/s (n=10000000)
    5. Protected write : 15 wallclock secs (14.21 usr +  0.00 sys = 14.21 CPU) @ 703630.73/s (n=10000000)
    6. Protected read  : 14 wallclock secs (14.13 usr +  0.00 sys = 14.13 CPU) @ 707513.80/s (n=10000000)
    7. Private write   : 12 wallclock secs (11.31 usr +  0.00 sys = 11.31 CPU) @ 884173.30/s (n=10000000)
    8. Private read    : 11 wallclock secs (11.23 usr +  0.00 sys = 11.23 CPU) @ 890313.39/s (n=10000000)

We can see, that public variables works 18 times slower, than direct access, protected variables are 25 times slower, than direct acces and private variables are 20 times slower, than direct access.
    
=head1 BUGS AND IMPROVEMENTS

If you found any bug and/or want to make some improvement, feel free to participate in the project on GitHub: L<https://github.com/hurricup/Class-Variable>

=head1 LICENSE

This module is published under the terms of the MIT license, which basically means "Do with it whatever you want". For more information, see the LICENSE file that should be enclosed with this distributions. A copy of the license is (at the time of writing) also available at L<http://www.opensource.org/licenses/mit-license.php>.

=head1 SEE ALSO

=over

=item * Main project repository and bugtracker: L<https://github.com/hurricup/Class-Variable>

=item * Testing results: L<http://www.cpantesters.org/distro/C/Class-Variable.html>
        
=item * AnnoCPAN, Annotated CPAN documentation: L<http://annocpan.org/dist/Class-Variable>

=item * CPAN Ratings: L<http://cpanratings.perl.org/d/Class-Variable>

=item * See also: L<Class::Property>, L<Class::Accessor::Lazy>. 

=back

=head1 AUTHOR

Copyright (C) 2015 by Alexandr Evstigneev (L<hurricup@evstigneev.com|mailto:hurricup@evstigneev.com>)

=cut
