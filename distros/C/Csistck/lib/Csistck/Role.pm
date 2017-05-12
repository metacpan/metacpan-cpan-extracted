package Csistck::Role;

use strict;
use warnings;
use 5.010;

use Csistck;


sub new {
    my $class = shift;
    my %args = @_;
    my $args = \%args;

    my $self = {};
    $self->{tests} = [];
    bless($self, $class);

    # We won't add keys that overlap with required keys, 
    # drop silently for now. Set up tests after
    $self->defaults();
    foreach my $key (keys (%{$args})) {
        $self->{$key} = $args->{$key}
          unless ($key =~ /^tests$/);
    }
    $self->tests();

    return $self;
}

# For overriding
sub defaults { return; };
sub tests { return; };

# Add test to object
sub add {
    my $self = shift;
    my @tests = @_;
    push(@{$self->{tests}}, @tests);
}

# Return tests
sub get_tests {
    my $self = shift;
    return $self->{tests};
}

1;
__END__

=head1 NAME

Csistck::Role - Cistck base class for role inheritance

=head1 SYNOPSIS
    
    package Service::Base;

    use base 'Csistck::Role';
    
    sub defaults {
        my $self = shift;
        $self->{some_arg} = 42;
        $self->{config} = '/etc/service.conf';
    }

    sub tests {
        my $self = shift;
        $self->add([
            template(".files/test.tt", "/tmp/test", { service => $self }),
            permission("/tmp/test*", mode => '0777', uid => 100, gid => 100)
        ]);
    }
    
    1;

Create a new instance of the class to add the checks to a host definition:

    host 'example.com' =>
        noop(0),
        Service::Base->new(
            some_arg => 84
        ),
        noop(1);


=head1 DESCRIPTION

This class is the base class for defining custom roles with input arguments.

=head1 METHODS

=head2 defaults()

Override this method on the child class to set argument defaults. Do not 
define methods here, as default arguments are processed before input 
arguments.

=head2 tests()

Override the method on the child class to create tests on the role.

=head1 AUTHOR

Anthony Johnson, E<lt>aj@ohess.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 Anthony Johnson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,


