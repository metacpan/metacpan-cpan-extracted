package Class::Accessor::Tiny;
our $VERSION = '0.10';
sub new{ return bless {}, $_[0] };
sub import{
    my $self = shift;
    my $caller = caller;
    for my $name ( @_ ){
        if ( $name eq 'new' ){
            *{  $caller . "::new" } = \&new;
        }
        else {
            my $setter  = sub { $_[0]->{$name} = $_[1],$_[0] };
            my $gettter = sub { $_[0]->{$name} };
            *{ $caller . "::get_$name" } = $gettter;
            *{ $caller . "::set_$name" } = $setter;
        }
    }
}
1;
__END__
=head1 NAME

Class::Accessor::Tiny - Perl Tiny Accessors for PBP

=head1 SYNOPSIS

    package MyClass;
    use Class::Accessor::Tiny qw(new); # generate simplest new method
    use Class::Accessor::Tiny qw(attr1 attr2); # generate simplest new method

    # ...
    my $obj = CLASS->new();
    $obj->set_attr1( "attr1 value" );
    print $obj->get_attr1;

=head1 DESCRIPTION

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. G. Grishaev Anatoliy, E<lt>grian@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by A. G. Grishaev Anatoliy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
