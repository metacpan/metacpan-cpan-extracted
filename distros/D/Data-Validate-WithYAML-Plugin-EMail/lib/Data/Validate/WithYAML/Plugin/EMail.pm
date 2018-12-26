package Data::Validate::WithYAML::Plugin::EMail;

use warnings;
use strict; 

use Carp;
use Regexp::Common qw[Email::Address];

# ABSTRACT: Plugin for Data::Validate::WithYAML to check email addresses

our $VERSION = '0.04';

sub check {
    my ($class, $value) = @_;

    croak "no value to check" unless defined $value;

    my $return = 0;
    if( $value =~ /($RE{Email}{Address})/ ){
        $return = 1;
    }

    return $return;
}


1; # End of Data::Validate::WithYAML::Plugin::EMail

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Validate::WithYAML::Plugin::EMail - Plugin for Data::Validate::WithYAML to check email addresses

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use Data::Validate::WithYAML::Plugin::EMail;

    my $foo = Data::Validate::WithYAML::Plugin::EMail->check( 'test@exampl.com' );
    ...
    
    # use the plugin via Data::Validate::WithYAML
    
    use Data::Validate::WithYAML;
    
    my $email     = 'test@exampl.com';
    my $validator = Data::Validate::WithYAML->new( 'test.yml' );
    print "yes" if $validator->check( 'email', $email );

test.yml

  ---
  step1:
      email:
          plugin: EMail
          type: required

=head1 SUBROUTINES

=head2 check

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
