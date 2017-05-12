package Data::Remember::Util;
{
  $Data::Remember::Util::VERSION = '0.140490';
}
use strict;
use warnings;

use Carp;
use Sub::Exporter -setup => {
    exports => [ qw( process_que init_brain ) ],
};

# ABSTRACT: common helper utilities


sub process_que {
    my $que = shift;

    my @ques;
    if (ref $que eq 'ARRAY') {
        @ques = @$que;
    }

    elsif (ref $que eq 'HASH') {
        for my $key (sort keys %$que) {
            push @ques, $key, $que->{$key};
        }
    }

    else {
        @ques = ($que);
    }

    for my $que (@ques) {
        return undef unless defined $que;
    }

    return \@ques;
}


sub init_brain {
    my $brain = shift;

    $brain = 'Data::Remember::' . $brain
        unless $brain =~ /::/;

    $brain =~ /^[\w:]+$/ 
        or croak qq{This does not look like a valid brain: $brain};

    Class::Load::load_class($brain)
        or carp qq{The brain $brain may not have loaded correctly: $@};

    my $gray_matter = $brain->new(@_);

    # Duck typing!
    $gray_matter->can('remember')
        or croak qq{Your brain cannot remember facts: $brain};
    $gray_matter->can('recall')
        or croak qq{Your brain cannot recall facts: $brain};
    $gray_matter->can('forget')
        or croak qq{Your brain cannot forget facts: $brain};

    return $gray_matter;
}

1;

__END__

=pod

=head1 NAME

Data::Remember::Util - common helper utilities

=head1 VERSION

version 0.140490

=head1 SYNOPSIS

  use Data::Remember::Util qw( process_que init_brain );

  my $clean_que = process_que($handy_que);
  my $brain = init_brain($name, @args);

=head1 DESCRIPTION

These are some common helper utilities used by L<Data::Remember::Class> and some of the brain implementations. Unless you are building a custom brain, you probably don't need these.

=head1 SUBROUTINES

=head2 process_que

  my $clean_que = process_que($handy_que);

The format defined in L<Data::Remember::Class/QUE> is very flexible. That section describes how all the flexible que formats are mapped into a canonical form. This is utility subroutine that does that clean-up process.

This is performed automatically on behalf of each brain by L<Data::Remember::Class>, so you do not normally need this if you are just implementing the usual brain functions. However, if you have custom methods that require additional features, you may want this helper.

=head2 init_brain

  my $brain = init_brain($module, @args);

This is a helper that checks the arguments given, loads the brain class for
the given module name, constructs a brain, and returns it.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
