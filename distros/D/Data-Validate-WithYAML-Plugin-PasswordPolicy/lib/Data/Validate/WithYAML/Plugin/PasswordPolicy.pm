package Data::Validate::WithYAML::Plugin::PasswordPolicy;

use warnings;
use strict; 

use Carp;

# ABSTRACT: Plugin to check passwords against a policy 

our $VERSION = '0.03';

sub check {
    my ($class, $value, $options) = @_;
    
    return unless defined $value;
    return if $value eq '';

    return 1 if !$options;

    my %policy = %{ $options->{'x-policy'} || {} };
    return 1 if !%policy;

    my $return = 1;

    if ( $policy{length} && $policy{length} =~ /,/ ) {
        my ($min,$max) = $policy{length} =~ /\s*(\d+)\s*,(?:\s*(\d+)\s*)?/;
        my $bool = 1;

        if(defined $min and length $value < $min){
            $bool = 0;
        }

        if(defined $max and length $value > $max){
            $bool = 0;
        }

        $return &= $bool;
    }
    elsif ( $policy{length} ) {
        $return &= ( $policy{length} == length $value );
    }

    return if !$return;

    if ( defined $policy{chars} and !ref $policy{chars} ) {
        $policy{chars} = [ $policy{chars} ];
    }

    CLASS:
    for my $class ( @{ $policy{chars} || [] } ) {
        my $re      = qr/[$class]/;
        my $matches = $value =~ $re ? 1 : 0;
        $return &= $matches;

        last CLASS if !$return;
    }
    
    return if !$return;

    if ( defined $policy{chars_blacklist} and !ref $policy{chars_blacklist} ) {
        $policy{chars_blacklist} = [ $policy{chars_blacklist} ];
    }

    CLASS:
    for my $class ( @{ $policy{chars_blacklist} || [] } ) {
        my $re      = qr/[$class]/;
        my $matches = $value =~ $re ? 0 : 1;
        $return &= $matches;

        last CLASS if !$return;
    }
    
    return if !$return;
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Validate::WithYAML::Plugin::PasswordPolicy - Plugin to check passwords against a policy 

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Data::Validate::WithYAML::Plugin::PasswordPolicy;

    my $foo = Data::Validate::WithYAML::Plugin::PasswordPolicy->check( 'mypassword' );
    ...
    
    # use the plugin via Data::Validate::WithYAML
    
    use Data::Validate::WithYAML;
    
    my $password  = 'mypassword';
    my $validator = Data::Validate::WithYAML->new( 'test.yml' );
    print "yes" if $validator->check( 'password', $password );
  
    # it allows extra params to define the policy
    my $password  = 'mypassword';
    my $validator = Data::Validate::WithYAML->new( 'test.yml' );
    print "yes" if $validator->check( 
        'password',
        $password,
        {
            'x-policy' => { length => '3,', chars => [ 'A-Z', 'def', '$§!', '\d' ] },
        }
    );

test.yml

  ---
  step1:
      password:
          plugin: PasswordPolicy
          type: required

=head1 SUBROUTINES

=head2 check

=head1 POLICY RULES

Those rules are allowed in the policy:

=over 4

=item * length

=item * chars

=item * chars_blacklist

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
