package DBIx::Class::Stash;
use strict;
use warnings;
use base 'DBIx::Class';
our $VERSION = '0.07';

__PACKAGE__->mk_classdata('_dbic_stash' => {});

sub stash :lvalue {
    my ($self, ) = @_;
    $self->{_dbic_stash} ||= __PACKAGE__->_dbic_stash;
}

{ # set stash method for DBIx::Class::ResultSet and DBIx::Class::Schema
    no strict 'refs'; ## no critic
    *{"DBIx\::Class\::ResultSet\::stash"} = \&stash;
    *{"DBIx\::Class\::Schema\::stash"} = \&stash;
}

1;
__END__

=head1 NAME

DBIx::Class::Stash - stash for DBIC

=head1 SYNOPSIS

    package Proj::Schema::User;
    __PACKAGE__->load_components(qw/Stash .../);
    
    sub insert {
        my $self = shift;
        my $user = $self->next::method(@_);
        $user->create_related('profile',{ zip1 => $self->stash->{zip1} });
        return $user;
    }

    in your script:
    my $user_rs = $self->model('User')
    $user_rs->stash->{zip1} = $zip1;
    $user_rs->create({ name => 'nekokak' });
    
    or 
    
    $self->model->stash->{zip1} = $zip1;
    my $user = $self->model('User')->create({ name => 'nekokak' });

=head1 DESCRIPTION

stash method for DBIC.

=head1 METHOD

=head2 stash

data stash.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Atsushi Kobayashi  C<< <atsushi __at__ mobilefactory.jp> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Atsushi Kobayashi C<< <atsushi __at__ mobilefactory.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

