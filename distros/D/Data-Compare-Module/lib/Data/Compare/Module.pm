package Data::Compare::Module;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.03';

use List::Compare;

sub compare {
    my @args = @_;
    my $self;
    my ($module_a_name, $module_b_name);
    if (ref $args[0] eq 'Data::Compare::Module') {
        $self = shift @args;
    }
    ($module_a_name, $module_b_name) = @args;
    if (!defined $module_a_name or !defined $module_b_name) {
        ($module_a_name, $module_b_name) = ($self->{mod_a}, $self->{mod_b});
    }
    no strict 'refs';
    my $module_a_space = \%{$module_a_name . "::"};
    my $module_b_space = \%{$module_b_name . "::"};
    use strict 'refs';
    my @keys_a = keys %$module_a_space;
    my @keys_b = keys %$module_b_space;
    my $c = List::Compare->new(\@keys_a, \@keys_b);
    my @only_a = $c->get_Lonly;
    my @only_b = $c->get_Ronly;

    return (\@only_a, \@only_b);
}

sub new {
    my $class = shift;
    my @args = @_;
    if (@args != 0 and @args != 2) {
        die "the constructor must receive 0 or 2 arguments";
    }
    my $self = {};
    if (@args == 2) {
        ($self->{mod_a}, $self->{mod_b}) = @args;
    }
    bless $self, $class;
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Compare::Module - compare perl module namespaces

=head1 SYNOPSIS

    use Data::Compare::Module;
    
    my ($only_a, $only_b) = Data::Compare::Module::compare("Module::A", "Module::B");
    
    ### Objective manner
    my $c = Data::Compare::Module->new;
    my ($only_a, $only_b) = $c->compare('Module::A', 'Module::B');
    
    my $c = Data::Compare::Module->new('Module::A', 'Module::B');
    my ($only_a, $only_b) = $c->compare;

=head1 DESCRIPTION

Data::Compare::Module is to compare two modules' namespaces.

=head1 AUTHOR

Tomoya KABE E<lt>limitusus@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Tomoya KABE

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
