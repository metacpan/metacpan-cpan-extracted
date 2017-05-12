# ABSTRACT: Dancer::Plugin::Authorize Credentials base class and guide!

package Dancer::Plugin::Authorize::Credentials;
BEGIN {
  $Dancer::Plugin::Authorize::Credentials::VERSION = '1.110720';
}

use strict;
use warnings;

use Dancer qw/:syntax/;


sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    return $self;
}

sub credentials {
    my $self = shift;
    if (@_) {
        return session 'user' => @_;
    }
    else {
        return session('user');
    }
}

sub errors {
    my ($self, @errors) = @_;
    my $user = session('user');
    push @{$user->{error}}, @errors; 
    #return session 'user' => $user;
    session 'user' => $user;
    return @errors;
}

1;
__END__
=pod

=head1 NAME

Dancer::Plugin::Authorize::Credentials - Dancer::Plugin::Authorize Credentials base class and guide!

=head1 VERSION

version 1.110720

=head1 SYNOPSIS

    package Dancer::Plugin::Authorize::Credentials::MyAuthorizationClass;
    use base 'Dancer::Plugin::Authorize::Credentials';
    
    # every authentication class must have an authorize routine
    sub authorize {
        my ($self, $options, @arguments) = @_;
        my ($login, $password) = @arguments;
        ...
    }
    
    1;

=head1 DESCRIPTION

The Dancer::Plugin::Authorize::Credentials class should be used as a base class in
your custom credentials/authorization classes. When used as a base class, this
class provides instantiation and simple error handling for your authorization classes. 

=head1 AUTHOR

  Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

