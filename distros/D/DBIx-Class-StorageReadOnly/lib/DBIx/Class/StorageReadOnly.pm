package DBIx::Class::StorageReadOnly;
use strict;
use warnings;
use base 'DBIx::Class';
use Carp::Clan qw/^DBIx::Class/;

our $VERSION = '0.05';
use DBIx::Class::Storage::DBI;

{
    package DBIx::Class::Storage::DBI;
    no warnings 'redefine';
    no strict 'refs'; ## no critic
    for my $method (qw/insert update delete/) {
        my $code_org = DBIx::Class::Storage::DBI->can($method);
        *{"DBIx\::Class\::Storage\::DBI\::$method"} = sub {
            my $self = shift;
            if ($self->_search_readonly_info) {
                croak("This connection is read only. Can't $method.");
            }
            return $self->$code_org(@_);
        };
    }

    sub _search_readonly_info {
        my $self = shift;
        for my $info ( @{$self->connect_info} ) {
            if (ref $info eq 'HASH' ) {
                return 1 if $info->{read_only} == 1;
            }
        }
        return;
    }
}
1;
__END__

=head1 NAME

DBIx::Class::StorageReadOnly - Can't insert and update and delete for DBIC

=head1 SYNOPSIS

    __PACKAGE__->load_components(qw/
        StorageReadOnly
        PK::Auto
        Core
    /);
    
    # create connection and set readonly info
    @connection_info = (
        'dbi:mysql:test',
        'foo',
        'bar',
        {read_only => 1},
    );
    my $schema = $schema_class->connect(@connection_info);
    
    my $user = $schema->resultset('User')->search({name => 'nomaneko'});
    $user->update({name => 'gikoneko'}); # die. Can't update.

=head1 DESCRIPTION

If you try to write it in read only DB, the exception is generated. 

=head1 METHOD

=head2 insert

=head2 update 

=head2 delete 

=head2 _search_readonly_info

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Atsushi Kobayashi  C<< <atsushi __at__ mobilefactory.jp> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Atsushi Kobayashi C<< <atsushi __at__ mobilefactory.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

