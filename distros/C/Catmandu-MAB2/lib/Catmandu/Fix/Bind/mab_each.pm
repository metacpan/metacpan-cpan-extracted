package Catmandu::Fix::Bind::mab_each;

our $VERSION = '0.21';

use Moo;
use Catmandu::Util;

with 'Catmandu::Fix::Bind', 'Catmandu::Fix::Bind::Group';

has done => (is => 'ro');

sub unit {
    my ($self,$data) = @_;
    $self->{done} = 0;
    $data;
}

sub bind {
    my ($self,$mvar,$code) = @_;

    return $mvar if $self->done;

    my $rows = $mvar->{record} // [];

    my @new = ();

    for my $row (@{$rows}) {

        $mvar->{record} = [$row];

        my $fixed = $code->($mvar);

        push @new , @{$fixed->{record}} if defined($fixed) && exists $fixed->{record};
    }

    $mvar->{record} = \@new if exists $mvar->{record};

    $self->{done} = 1;

    $mvar;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catmandu::Fix::Bind::mab_each - a binder that loops over MAB2 fields

=head1 SYNOPSIS

    # Only add field 331 to the title when field 412 matches 'Heise'
    do mab_each()
        if mab_match("412","Heise")
            mab_map("331",title)
        end
    end

    # Delete all the 700 subject fields
    do mab_each()
        if mab_match("700",".*")
            reject()
        end
    end

=head1 DESCRIPTION

The mab_each binder will iterate over each individual MAB2 field and 
execute the fixes only in context over each individual field.

If a MAB2 record contains:

    705    $a775.05$c775
    705    $a702.08$c702

then the fix

    do mab_each()
        mab_map("705a",subject.$append)
    end

will have the same effect as

    mab_map("705a",subject.$append)

because C<mab_map> by default loops over all repeated MAB2 fields. But the 
C<mab_each> bind has the advantage to process fields in context. E.g. to 
only map fields where the subfield $c doesn't contain '702' you 
can write:

    do mab_each()
        unless mab_match("705","702")
            mab_map("705",subject.$append)
        end
    end

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=head1 AUTHOR

Johann Rolschewski <jorol@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Johann Rolschewski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
