package Backup::Omni::Base;

our $VERSION = '0.01';
our $EXCEPTION = 'Backup::Omni::Exception';

use Backup::Omni::Exception;
use Params::Validate ':all';

use Backup::Omni::Class
  base     => 'Backup::Omni Badger::Base',
  version  => $VERSION,
  messages => {
      noresults => 'unable to find any results for %s',
      nosession => 'no session data found for %s on %s',
      baddate   => 'unable to perform date parsing, reason: %s',
      badtemp   => 'bad temporary session id',
      badparams => 'invalid parameters passed from %s at line %s',
      invparams => 'invalid paramters passed, reason: %s',      
      nosubmit  => 'unable to submit a restore for %s',
  },
  vars => {
      PARAMS => {}
  }   
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub config {
    my ($class, $p) = @_;

    return $class->{config}->{$p};

}

sub validation_exception {
    my $param = shift;
    my $class = shift;

    my $x = index($param, $class);
    my $y = index($param, ' ', $x);
    my $method;

    if ($y > 0) {

        my $l = $y - $x;
        $method = substr($param, $x, $l);

    } else {

        $method = substr($param, $x);

    }

    chomp($method);
    $method =~ s/::/./g;
    $method = lc($method) . '.invparams';

    $class->throw_msg($method, 'invparams', $param);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $self = shift;

    my $params = $self->class->hash_vars('PARAMS');
    my %p = validate(@_, $params);
 
    $self->{config} = \%p;
 
    no strict "refs";               # to register new methods in package
    no warnings;                    # turn off warnings

    while (my ($key, $value) = each(%p)) {

        $key =~ s/^-//;
        $self->{$key} = $value;

        *$key = sub {
            my $self = shift;
            return $self->{$key};
        };

    }

    return $self;

}

1;

__END__

=head1 NAME

Backup::Omni::Base - The base class for Backup::Omni

=head1 SYNOPSIS

 use Backup::Omni::Class
     version => '0.01',
     base    => 'Backup::Omni::Base'
 ;

=head1 DESCRIPTION

This module defines a base class for Backup::Omni and inherits from
Badger::Base. 

=head1 METHODS

=head2 new

Various arguments, based on the package variable PARAMS. This allows for
parameter validation and the ability to override base parameters from
inherited classes.

=head2 config($item)

This method will return an item from the internal class config. Which is 
usually the parameters passed to new() before any manipulation of those
parameters.

=over 4

=item B<$item>

The item you want to return,

=back

=head2 validation_exception($params, $class)

This method is used by Params::Validate to display it's failure  message.

=over 4

=item B<$params>

The parameter that caused the exception.

=item B<$class>

The class that it happened in.

=back

=head1 SEE ALSO

 Backup::Omni::Class
 Backup::Omni::Utils
 Backup::Omni::Constants
 Backup::Omni::Exception
 Backup::Omni::Restore::Filesystem::Single
 Backup::Omni::Session::Filesystem
 Backup::Omni::Session::Messages
 Backup::Omni::Session::Monitor
 Backup::Omni::Session::Results

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by WSIPC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
