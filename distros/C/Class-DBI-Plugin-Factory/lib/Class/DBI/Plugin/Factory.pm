package Class::DBI::Plugin::Factory;
use strict;
use vars qw/$VERSION/;

$VERSION = '0.03';

use Class::Inspector;
use UNIVERSAL::require;

sub import {
    my $class = shift;
    my $pkg = caller(0);

    unless( $pkg->isa('Class::DBI') ){
        $class->_croak(qq/This plugin is for CDBI application./);
    }
    $pkg->mk_classdata($_) for qw/type_column _factory_types/;

    no strict 'refs';
    *{$pkg."::set_factory"} = sub {
        my($caller, %args) = @_;

        if ( $args{type_column} ) {
            $caller->type_column( $args{type_column} );
        }

        $caller->_croak(qq/Type column isn't defined./)
            unless $caller->type_column;

        $caller->_factory_types( $args{types} || {} );
        $class->_require_modules($caller);

        $caller->add_trigger( select => sub {
            my $self = shift;
            my $type = $self->type_column;
            unless( $self->can($type) ) {
                $self->_croak(qq/Couldn't call method "$type"./);
            }
            my $subclass = $self->_factory_types->{$self->$type}
                || $self->_factory_types->{'-Base'};
            unless( Class::Inspector->loaded($subclass) ) {
                $self->_croak(qq/Unknown class "$subclass"./);
            }
            bless $self, $subclass;
        } );
    }
}

sub _require_modules {
    my($class, $pkg) = @_;
    while( my($type, $module) = each %{ $pkg->_factory_types } ) {
        $module = join "::", $pkg, $module;
        unless( Class::Inspector->installed($module) ) {
            $class->_croak(qq/"$module" isn't installed./);
        }
        $module->require;
        $class->_croak(qq/Couldn't require "$module", "$@"./) if($@);
        $pkg->_factory_types->{$type} = $module;
    }
}

sub _croak {
    my($self, $msg) = @_;
    require Carp; Carp::croak($msg);
}

1;
__END__

=head1 NAME

Class::DBI::Plugin::Factory - Implementation of "factory pattern"

=head1 SYNOPSIS

require this module in your base CDBI class.

    MyService::DBI;
    use strict;
    use base qw/Class::DBI/;
    use Class::DBI::Plugin::Factory;

    __PACKAGE__->set_db('Main', @datasource);

execute "set_factory" in the class you want to implement "factory pattern".

    MyService::Member;
    use strict;
    use base qw/MyService::DBI/;
    __PACKAGE__->table('member');
    __PACKAGE__->columns(Primary => qw/member_id/);
    __PACKAGE__->columns(Essential => qw/member_type name age/);

    __PACKAGE__->set_factory(
        type_column => 'member_type',
        types => {
            -Base    => 'Basic',
            1        => 'Free',
            2        => 'VIP',
        },
    );
    
    # abstract method
    sub is_free {}
    sub monthly_cost {}

define subclasses. for example, MyService::Member::Basic in this case.

    package MyService::Member::Basic;
    use strict;
    use base qw/MyService::Member/;
    sub is_free { 0 }
    sub monthly_cost { 500 }

define MyService::Member::Free.

    package MyService::Member::Free;
    use strict;
    use base qw/MyService::Member/;
    sub is_free { 1 }
    sub monthly_cost { 0 }

define MyService::Member::VIP.

    package MyService::Member::VIP;
    use strict;
    use base qw/MyService::Member/;
    sub is_free { 0 }
    sub monthly_cost { 250 }

after all setting. you can use them like follow.

    package main;
    use MyService::Member;

    my @members = MyService::Member->retrieve_all;

    foreach my $member ( @members ) {

        print $member->member_type;

        # if member_type is 1, follow line prints '0'.
        # and if member_type is 2, '250' will be printed.

        print $member->monthly_cost;
    }    

=head1 DESCRIPTION

This plugin makes CDBI to implement "factory pattern".

=head1 set_factory

call this method in a package where you want to design as "factory pattern".
and you need to set hashref as a argument of "set_factory".
follow 2 keys are required.

=over 4

=item type_column

According to a value of the column set with this key, this module rebless records.

=item types

hashref which defines a relations between type-parameters and subclasses.
if undefined type-parameter is found, records will be reblessed to the subclass which defined as '-Base'

=head1 SEE ALSO

L<Class::DBI>

=head1 AUTHOR

Basic idea and sample by Yasuhiro Horiuchi.

Plugin's code by Lyo Kato E<lt>kato@lost-season.jpE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

