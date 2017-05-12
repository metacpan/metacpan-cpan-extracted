package Data::Validate::WithYAML::Plugin::Phone;

use warnings;
use strict; 

use Carp;

# ABSTRACT: Plugin to check Phone numbers (basic check)

our $VERSION = '0.04';


sub check {
    my ($class, $value) = @_;
    
    croak "no value to check" unless defined $value;
    
    my $return = 0;
    $value =~ s/\s//g;
    if( $value =~ m{\A (?: \+ | 00? ) [1-9]{2,6} \s*? [/-]? \s*? [0-9]{4,12} \z}x ){
        $return = 1;
    }
    
    return $return;
}

1;

__END__

=pod

=head1 NAME

Data::Validate::WithYAML::Plugin::Phone - Plugin to check Phone numbers (basic check)

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use Data::Validate::WithYAML::Plugin::Phone;

    my $foo = Data::Validate::WithYAML::Plugin::Phone->check( '+49 123 456789' );
    ...
    
    # use the plugin via Data::Validate::WithYAML
    
    use Data::Validate::WithYAML;
    
    my $phone     = '+49 123 456789';
    my $validator = Data::Validate::WithYAML->new( 'test.yml' );
    print "yes" if $validator->check( 'phone', $phone );

test.yml

  ---
  step1:
      phone:
          plugin: Phone
          type: required

=head1 SUBROUTINES

=head2 check

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
