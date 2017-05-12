# ABSTRACT: Dancer::Plugin::Authorize access control via the Dancer configuration file!

package Dancer::Plugin::Authorize::Permissions::Config;
BEGIN {
  $Dancer::Plugin::Authorize::Permissions::Config::VERSION = '1.110720';
}

use strict;
use warnings;
use base qw/Dancer::Plugin::Authorize::Permissions/;


sub subject_asa {
    my ($self, $options, @arguments) = @_;
    my $role = shift @arguments;
    my $user = $self->credentials;
    my $settings = $class::settings;
    
    if ($role) {
        if (grep { /$role/ } @{$user->{roles}}) {
            return 1;
        }
    }
    
    return 0;
}


sub subject_can {
    my ($self, $options, @arguments) = @_;
    my ($operation, $action) = @arguments;
    my $settings = $class::settings;
    
    my $user  = $self->credentials;
    my $roles = $options->{control};
    
    foreach my $role ( @{$user->{roles}} ) {
        
        if (defined $roles->{$role}->{permissions}) {
            
            my $permissions = $roles->{$role}->{permissions};
            if (defined $permissions->{$operation}) {
                
                if ($action) {

                    if (defined $permissions->{$operation}->{operations}) {
                        
                        my $operations = $permissions->{$operation}->{operations};
                        if (grep { /$action/ } @{$operations}) {
                            
                            return 1;
                            
                        }
                        
                    }

                }
                else {
                    return 1;
                }
                
            }
            
        }
        
    }
    
    return 0;
}

1;
__END__
=pod

=head1 NAME

Dancer::Plugin::Authorize::Permissions::Config - Dancer::Plugin::Authorize access control via the Dancer configuration file!

=head1 VERSION

version 1.110720

=head1 SYNOPSIS

    plugins:
      Authorize:
        permissions:
          class: Config
          options: 
            control:
              admin:
                permissions:
                  manage accounts:
                    operations:
                      - view
                      - create
                      - update
                      - delete
              user:
                permissions:
                  manage accounts:
                    operations:
                      - view
                      - create
              guests:
                permissions:
                  manage accounts:
                    operations:
                      - view

=head1 DESCRIPTION

Dancer::Plugin::Authorize::Permissions::Config uses your Dancer application
configuration file as role-based access control system. 

=head1 METHODS

=head2 subject_asa

The subject_asa method (found in every permissions class) validates whether a user
has the role defined in the supplied argument.

    return 1 if subject_asa($self, $options, $role);

=head2 subject_can

The subject_can method (found in every permissions class) validates whether a user
is responsible for (or is authorized to operate) a particular operation and can
perform the specified action under that operation.

    return 1 if subject_can($self, $options, $operation, $action);

=head1 AUTHOR

  Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

