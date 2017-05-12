package Class::LazyLoad::Functions;

use Class::LazyLoad;

{
    my %is_exportable = map { $_ => undef } qw(
        lazyload
        unlazyload
        lazyload_one
        init_lazyloads
    );

    sub import
    {
        shift;
        my $pkg = (caller)[0];

        foreach (grep exists $is_exportable{$_}, @_)
        {
            local $^W = 0;
            *{ $pkg . "::" . $_ } = \&{ 'Class::LazyLoad::' . $_ };
        }
    }
}

1;

__END__

=head1 NAME

Class::LazyLoad::Functions - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of our tests, see the C<CODE COVERAGE> section of L<Class::LazyLoad> for more information.

=head1 AUTHORS

Rob Kinyon, E<lt>rob.kinyon@gmail.comE<gt>
Stevan Little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 Rob Kinyon and Stevan Little

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
